function mZ = alignRastersAlongDim3(mZ,lMask,sParams)

% Mean along 3rd dimension
mRef = nanmean(mZ,3); mRef = mRef(~lMask);

% Loop through rasters
for i = 1:size(mZ,3)
    
    % Difference
    mZt = mZ(:,:,i); 
    mZt = mZt(~lMask);
    vDiff = mZt - mRef;
    
    % Mask any differences larger than the threshold
    vDiff(abs(vDiff) > sParams.alignThresh) = NaN; 
       
    % Shift
    dShift = nanmean(vDiff(:));
    mZ(:,:,i) = mZ(:,:,i) - dShift;
    
end
