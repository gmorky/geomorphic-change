function lMask = makeMask(strMsk,vLon,vLat,mA,sParams)

% Get files in user-specified folder
cShp = getFiles(strMsk,'.shp');
cRas = getFiles(strMsk,'.tif');

% Initialize
lMask = false(length(vLat),length(vLon));

% Add shapefiles to mask
for i = 1:numel(cShp)
    sParams.blockSize = 5000;
    lM = polygons2grid(strMsk,vLon,vLat,sParams) > 0;
    lMask = sum(cat(3,lMask,lM),3) > 0;    
end

% Add rasters to mask
for i = 1:numel(cRas)
    sParams.blockSize = 500;
    lM = grid2grid(geotiffinfo(cRas{i}),vLon,vLat,sParams) > 0;
    lMask = sum(cat(3,lMask,lM),3) > 0;
end

% Dilate
dRes = mean(sqrt(mA(:)));
iRadSz = max([1 round(sParams.maskDilateRadius / dRes)]);
lMask = imdilate(lMask,strel('disk',iRadSz));
