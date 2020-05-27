function sOutput = geomorphicChange(sShpH,strShpM,sDemParams,sParams)

% Read the modern shapefile
sShpM = findMatchingShapefile(sParams,sShpH,strShpM);

% Find overlapping DEMs
vIdx = findSpatialOverlap(sParams,{sDemParams.boundingBox},sShpH,sShpM);
iNumDems = length(vIdx);

% Return if less than 2 DEMs are found
if iNumDems < 2
    error('Less than 2 overlapping DEMs found for current polygon.')
end

% Sort index by acquisition date
vDate = [sDemParams.acquisitionDate];
[~,vIdxYear] = sort(vDate(vIdx));
vIdx = vIdx(vIdxYear);

% Sort data
sDemParams = sDemParams(vIdx);

% Return if all DEMs have same acquisition date
if all([sDemParams.acquisitionDate]==sDemParams(1).acquisitionDate)
    error('All DEMs have the same acquisition date for current polygon.')
end

% Get coarsest spatial resolution
vRes = [0 0];
for i = 1:iNumDems
    sInfo = geotiffinfo(sDemParams(i).file);
    vRes = max([vRes;sInfo.PixelScale(1:2)']);
end

% Polygon bounding box with buffer around edges
mBoxH = makeBox(sShpH.BoundingBox);
mBoxM = makeBox(sShpM.BoundingBox);
[mBox(:,1),mBox(:,2)] = polybool('union', ...
    mBoxH(:,1),mBoxH(:,2),mBoxM(:,1),mBoxM(:,2));
mBox = makeBox(mBox,sParams.boundingBoxPctBuffer);

% Spatial referencing
vLon = min(mBox(:,1)):vRes(1):max(mBox(:,1));
vLat = max(mBox(:,2)):-vRes(2):min(mBox(:,2));
[mLon,mLat] = meshgrid(vLon,vLat);

% Make spatial referencing structure
sR = georasterref;
sR.Lonlim = [vLon(1) vLon(end)] + [-vRes(1) vRes(1)]/2;
sR.Latlim = [vLat(end) vLat(1)] + [-vRes(2) vRes(2)]/2;
sR.RasterSize = size(mLon);
sR.ColumnsStartFrom = 'north';
sR.RowsStartFrom = 'west';

% Compute pixel areas
mA = pixelAreas(mLon,mLat);

% Make polygon masks
lPolyH = polygons2grid(sShpH,vLon,vLat);
lPolyM = polygons2grid(sShpM,vLon,vLat);
lPoly = lPolyH | lPolyM;

% Make unstable terrain mask
lMask = makeMask(sParams.maskDir,vLon,vLat,mA,sParams) | lPoly;

% Read and resample overlapping DEMs
[mZ,vIdx] = readAndResampleRasters(sDemParams,vLon,vLat,sParams);
sDemParams = sDemParams(vIdx);
iNumDems = length(vIdx);

% Vector of DEM acquisition times (in years)
vYearFrac = years([sDemParams.acquisitionDate] - ...
    datetime(year([sDemParams.acquisitionDate]),1,1));
vYear = year([sDemParams.acquisitionDate])+vYearFrac;

% Shift DEMs to correct any remaining vertical biases
mZ = alignRastersAlongDim3(mZ,lMask,sParams);

% Estimate trends using RANSAC
sParams.ransac.dimension = 3;
sParams.ransac.spacing = vYear;
sT = fitTrends(mZ,sParams.ransac);
mT = sT.slope;

% Make single DEM (with NaN values filled and median filter applied)
iYr = min(vYear) + ((max(vYear) - min(vYear))/2);
mZ = makeDem(sParams,sT,iYr);

% Remove slopes larger than threshold
[~,mSlope,~,~]  = gradientm(mLat,mLon,mZ);
lS = mSlope > sParams.slopeMax;
mT(lS) = NaN;
lPolyH(lS) = false;
lPolyM(lS) = false;
lPoly(lS) = false;

% Remove outliers
mT = removeTrendOutliers(mLon,mLat,mT,sT,sParams);

% Interpolate data gaps within the polygon
[mT,lGaps,sBins] = interpolateGaps(mZ,mT,lPoly,sParams.interpParams);

% Apply smoothing filter to trends
mT = smoothingFilter(mT,sParams.filterWindow,@nanmedian);

% Make sure mean of stable terrain is zero
mT = mT - nanmean(mT(~lMask));

% Compute geomorphic change
sChange = computeChange(mA,lPolyH,lPolyM,mT,lGaps,sParams.materialDensity);

% Estimate errors
sSigma = estimateErrors(mA,lPoly,mT,lGaps,sChange,lMask,sParams);

% Save output
sOutput.historicalShapefile = sShpH;
sOutput.modernShapefile = sShpM;
sOutput.demParams = sDemParams;
sOutput.params = sParams;
sOutput.grid.longitude = mLon;
sOutput.grid.latitude = mLat;
sOutput.grid.elevation = mZ;
sOutput.grid.slope = mSlope;
sOutput.grid.historicalPolygon = lPolyH;
sOutput.grid.modernPolygon = lPolyM;
sOutput.grid.fit = sT;
sOutput.grid.trend = mT;
sOutput.grid.gaps = lGaps;
sOutput.grid.unstableTerrain = lMask;
sOutput.grid.spatialRef = sR;
sOutput.bins = sBins;
sOutput.change = sChange;
sOutput.sigma = sSigma;
sOutput.timespan = max(vYear) - min(vYear);
