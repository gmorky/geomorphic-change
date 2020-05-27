% This script uses an example glacier change dataset (ASTER DEMs in the
% Bhutanese Himalayas) which can be downloaded at
% https://github.com/gmorky/aster-dems-cleanup

% Add dependencies paths
addpath(genpath('heximap\main\shared'))
addpath(genpath('geomorphicChange'))

% Path to historical shapefile (glacier outlines at beginning of timespan of interest)
strShpFileH = 'asterDemsCleanup\glacierOutlines\selected_2000.shp';

% Path to modern shapefile (glacier outlines at end of timespan of
% interest). Corresponding historical and modern polygons will be matched
% up based on their ID field values (see "sParams.polygonIdField" below)
strShpFileM = 'asterDemsCleanup\glacierOutlines\selected_2016.shp';

% Initialize structure array which will contain properties of individual
% DEMs needed for futher processing
sDemParams = struct();

% DEM filenames
strDemDir = 'asterDemsCleanup\cleanedDems\';
cFiles = getFiles(strDemDir,'.tif');
for i = 1:numel(cFiles)
    sDemParams(i).file = cFiles{i};
end

% DEM bounding boxes
for i = 1:numel(cFiles)
    sInfo = imfinfo(cFiles{i});
    mPoints = [sInfo.ModelTiepointTag(4) ...
        sInfo.ModelTiepointTag(5) - sInfo.ModelPixelScaleTag(2)*sInfo.Height; ...
        sInfo.ModelTiepointTag(4) + sInfo.ModelPixelScaleTag(1)*sInfo.Width ...
        sInfo.ModelTiepointTag(5)];
    sDemParams(i).boundingBox = makeBox(mPoints);
end

% DEM acquisition dates in matlab datetime format. In this case we are
% using output from the example ASTER DEM dataset
load('asterDemsCleanup\cleanedDems\asterScenesMetadata.mat')
for i = 1:numel(cFiles)
    cId = extractBetween(cFiles{i},'dem_','.tif');
    lIdx = cell2mat(cellfun(@(x) strcmp(x.id,cId{1}),cMetadata,'Uni',0));
    sDemParams(i).acquisitionDate = cMetadata{lIdx}.acquisitionDate;
end

% Parameters
sParams = struct();
sParams.maskDir = 'asterDemsCleanup\unstableTerrainMask\';
sParams.maxVertices = 10000;
sParams.polygonIdField = 'RGIId';
sParams.polygonOverlapCheck = true;
sParams.boundingBoxPctBuffer = 25;
sParams.alignThresh = 30;
sParams.nullVal = 'dem';
sParams.ransac.iterations = 100;
sParams.ransac.threshold = 15;
sParams.filterWindow = [5 5];
sParams.slopeMax = 45;
sParams.trendMax = 6;
sParams.trendMinCount = 3;
sParams.trendMinTimespan = 10;
sParams.trendMaxStd = 50;
sParams.trendMaxGrad = 3;
sParams.refDem.path = 'asterDemsCleanup\alosRefDem.tif';
sParams.refDem.nullVal = 'dem';
sParams.interpParams.method = 'elevationBins';
sParams.interpParams.binWidth = 50;
sParams.interpParams.binOutlierQuantiles = [0.02 0.98];
sParams.interpParams.binMinValidCount = 100;
sParams.interpParams.endBinsFillVal = [0 0];
sParams.materialDensity = 850;
sParams.maskDilateRadius = 250;
sParams.spatialCorrelationRange = 500;
sParams.simulationCount = 100;
sParams.extrapolationSigma = 0.6;
sParams.materialDensitySigma = 60;
sParams.areaPercentError = 10;

% Function handles
cFun = { ...
    @(x) geomorphicChange(x,strShpFileM,sDemParams,sParams) ...
};

% Directory to save output
strSaveDir = 'geomorphicChange\output\';

% Use parallel processing?
lParallel = true;

% Number of processing blocks (within geographic extent of shapefile) in
% horizontal and vertical directions
iNumBlocksX = 1;
iNumBlocksY = 1;

% Loop through shapefile and apply functions to each polygon
shapefileLoop(strShpFileH,strSaveDir,sParams.polygonIdField, ...
    iNumBlocksX,iNumBlocksY,cFun,lParallel)

% How to export elevation change maps (meters year^{-1}) as geotiffs:
cOutputFiles = getFiles(strSaveDir,'.mat');
for i = 1:numel(cOutputFiles)
    
    % Load grid data
    load(cOutputFiles{i},'grid');
    
    % Write geotiff
    [strDir,strFile,strExt] = fileparts(cOutputFiles{i});
    geotiffwrite([strDir '\' strFile '.tif'],grid.trend,grid.spatialRef)

end
