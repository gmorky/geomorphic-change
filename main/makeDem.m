function mZ = makeDem(sParams,sT,iYr)

% Compute DEM at specified time
mZ = sT.slope*iYr + sT.intercept;

% Remove outliers
mZ(abs(sT.slope) > sParams.trendMax) = NaN;
mZ(sT.count < sParams.trendMinCount) = NaN;
mZ(sT.timespan < sParams.trendMinTimespan) = NaN;

% Interpolate
mZ = inpaint_nans(mZ);

% Filter
vWin = sParams.filterWindow;
if ~isvector(vWin) || any(isnan(vWin))
    return
end
mZ = smoothingFilter(mZ,vWin,@nanmedian);
