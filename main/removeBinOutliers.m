function mData = removeBinOutliers(mGrid,mData,sParams)

% Make bins
sBins = makeBins(mGrid,mData,sParams.binWidth);

% Bin index
mIdx = reshape(knnsearch(sBins.bin(:),mGrid(:)),size(mGrid));

% Initialize
vIdx = unique(mIdx);

% Loop through unique bins
for i = 1:numel(vIdx)
    
    % Remove outliers
    lIn = mIdx == vIdx(i);   
    vQ = quantile(mData(lIn),sParams.binOutlierQuantiles);
    mData(lIn & (mData < vQ(1) | mData > vQ(2))) = NaN;
    
end
