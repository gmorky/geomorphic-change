function [mZ,vIdx] = readAndResampleRasters(sInput,vLon,vLat,sParams)

% Initialize
iCount = 1;

% Loop through rasters
for i = 1:numel(sInput)
    
    % Read and resample the raster
    mZt = grid2grid(sInput(i).file,vLon,vLat,sParams);
    
    % Save if not empty
    if ~all(isnan(mZt(:)))
        mZ(:,:,iCount) = mZt;
        vIdx(iCount) = i;
        iCount = iCount + 1;
    end
    
end

% Return if no valid pixels found
if iCount == 1
    error('No valid pixels found.')
end
