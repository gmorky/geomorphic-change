function mT = removeTrendOutliers(mLon,mLat,mT,sT,sParams)

% Remove trend outliers
mT(abs(mT) > sParams.trendMax) = NaN;
mT(sT.count < sParams.trendMinCount) = NaN;
mT(sT.timespan < sParams.trendMinTimespan) = NaN;
mT(sT.std > sParams.trendMaxStd) = NaN;
[~,mGrad,~,~] = gradientm(mLat,mLon,mT);
mT(mGrad > sParams.trendMaxGrad) = NaN;
