function sOutput = fitTrends(mData,sParams)

% RANSAC robust fit
warning('off','MATLAB:singularMatrix')
sOutput = ransac(mData,sParams);
warning('on','MATLAB:singularMatrix')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sOutput = ransac(mData,sParams)
    
% Parse
iDim = sParams.dimension;
vSpacing = sParams.spacing(:);

% Initialize
vSz = size(mData); vSz(iDim) = 1;
mC0 = zeros(vSz);
mR0 = Inf(vSz);
lInliers = false(size(mData));
vRepIdx = ones(size(vSz)); vRepIdx(iDim) = size(mData,iDim);

% Loop through RANSAC iterations
for i = 1:sParams.iterations
    
    % Index for random sets
    iSetSize = 2;
    vIdxRand = sort(randperm(size(mData,iDim),iSetSize));

    % Fit lines using linear least squares
    [mS,mI] = fit(mData,vSpacing,iDim,vIdxRand);
    
    % Residuals
    mR = residuals(mData,vSpacing,iDim,mS,mI);
    
    % Inliers
    lIn = mR < sParams.threshold.^2;
    
    % Inlier count
    mC = sum(lIn,iDim);
    
    % Residual sums
    mR(~lIn) = 0;
    mR = sum(mR,iDim);
    
    % Replace slope and intercept values where inlier count is equal or
    % higher, and residual sums are less or equal (inlier count supersedes
    % residual sums)
    lTest = (mC >= mC0) & (mR <= mR0);
    lTest(mC > mC0) = true;
    
    % Save current inlier counts and residual sums for next iteration
    mC0(lTest) = mC(lTest);
    mR0(lTest) = mR(lTest);
    
    % Save inliers index
    lTest = repmat(lTest,vRepIdx);
    lInliers(lTest) = lIn(lTest);

end

% Inliers
sOutput.inliers = lInliers;

% Final fit to inliers
[vIdx,iSzDim,vSz] = dimensions(mData,iDim);
mData = reshape(permute(mData,vIdx),iSzDim,[]);
lInliers = reshape(permute(lInliers,vIdx),iSzDim,[]);
mFit = NaN(2,prod(vSz));
for i = 1:prod(vSz)
        lIn = lInliers(:,i);
        if sum(lIn) > 1
            mFit(:,i) = [vSpacing(lIn) ones(sum(lIn),1)] \ mData(lIn,i);
        end
end

% Set RANSAC outliers to NaN
mData(~lInliers) = NaN;

% Final slope, intercept, inliner count
sOutput.slope = squeeze(ipermute(reshape(mFit(1,:),vSz),vIdx));
sOutput.intercept = squeeze(ipermute(reshape(mFit(2,:),vSz),vIdx));
sOutput.count = squeeze(ipermute(reshape(sum(lInliers),vSz),vIdx));

% Timespan
mTime = repmat(vSpacing,[1 prod(vSz)]); mTime(~lInliers) = NaN;
sOutput.timespan = ...
    squeeze(ipermute(reshape(max(mTime)-min(mTime),vSz),vIdx));

% Correlation coefficient
mFit = repmat(mFit(1,:),[iSzDim 1]).*mTime + repmat(mFit(2,:),[iSzDim 1]);
mR = nanmean((mFit-repmat(nanmean(mFit),[iSzDim 1])).* ...
    (mData-repmat(nanmean(mData),[iSzDim 1])))./ ...
    (nanstd(mFit).*nanstd(mData));
sOutput.correlation = squeeze(ipermute(reshape(mR,vSz),vIdx));

% Mean
sOutput.mean = squeeze(ipermute(reshape(nanmean(mData),vSz),vIdx));

% Median
sOutput.median = squeeze(ipermute(reshape(nanmedian(mData),vSz),vIdx));

% Standard deviation
sOutput.std = squeeze(ipermute(reshape(nanstd(mData),vSz),vIdx));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [vIdx,iSzDim,vSz] = dimensions(mData,iDim)
    
% Set dimension order
vDim = 1:ndims(mData);
vIdx = [iDim setdiff(vDim,iDim)];

% Size of input data matrix
vSz = size(mData);
iSzDim = vSz(iDim);
vSz(iDim) = 1;
vSz = vSz(vIdx);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [mS,mI] = fit(mData,vSpacing,iDim,vIdxRand)

% Dimension parameters   
[vIdx,iSzDim,vSz] = dimensions(mData,iDim);

% Manipulate data matrix
mData = reshape(permute(mData,vIdx),iSzDim,[]);

% Select random sets
mData = mData(vIdxRand,:);
vSpacing = vSpacing(vIdxRand);

% Solve linear system
mData = [vSpacing(:) ones(length(vSpacing),1)] \ mData;

% Slope and intercept
mS = squeeze(ipermute(reshape(mData(1,:),vSz),vIdx));
mI = squeeze(ipermute(reshape(mData(2,:),vSz),vIdx));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mR = residuals(mData,vSpacing,iDim,mSlope,mIntercept)

% Dimension parameters
[vIdx,iSzDim,vSz] = dimensions(mData,iDim);

% Spacing
mSpacing = ipermute(repmat(vSpacing(:),vSz),vIdx);
vRep = ones(1,iDim); vRep(iDim) = iSzDim;

% Residuals
mR = ((repmat(mSlope,vRep) .* mSpacing + repmat(mIntercept,vRep)) ...
    - mData).^2;

end
end