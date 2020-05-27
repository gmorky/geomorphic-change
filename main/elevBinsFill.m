function mData = elevBinsFill(mGrid,mData,sParams)

% Make bins
sBins = makeBins(mGrid,mData,sParams.binWidth);

% Remove bins with lower than the specified min valid count
lCut = sBins.validCount < sParams.binMinValidCount;

% Set end bins to specified values if empty
sBins.mean(lCut) = NaN;
if isnan(sBins.mean(1))
    sBins.mean(1) = sParams.endBinsFillVal(1);
end
if isnan(sBins.mean(end))
    sBins.mean(end) = sParams.endBinsFillVal(end);
end

% Interpolate bins
sBins.mean = inpaint_nans(sBins.mean);

% Bin index
mIdx = reshape(knnsearch(sBins.bin(:),mGrid(:)),size(mGrid));

% Initialize
vIdx = unique(mIdx);

% Loop through unique bins
for i = 1:numel(vIdx)
    
    % Set data gaps to bin mean
    lIn = mIdx == vIdx(i);
    mData(lIn & isnan(mData)) = sBins.mean(vIdx(i));
    
end
