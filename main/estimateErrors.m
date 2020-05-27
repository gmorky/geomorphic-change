function sSigma = estimateErrors(mA,lPoly,mT,lGaps,sChange,lMask,sParams)

% Pixel resolution
dRes = mean(sqrt(mA(:)));

% Standard deviation of trends over stable terrain
dSigma = nanstd(mT(~lMask));

% Combine stable terrain error with extrapolation error
dSigmaE = sqrt(dSigma^2+sParams.extrapolationSigma^2);

% Filter size
iFiltSz = max([1 round(sParams.spatialCorrelationRange / dRes)]);

% Initialize
iIter = sParams.simulationCount;
vSz = size(lPoly);
vVlmChj = NaN(1,iIter);

% Loop through Monte Carlo simulations
for i = 1:iIter
    
    % Normally distributed random error field, filtered to account for
    % spatial autocorrelation
    mR = imfilter(randn(vSz),fspecial('average',[iFiltSz iFiltSz])); 
    
    % Scale the random error field to get sigmas
    mR(~lGaps) = mR(~lGaps) * dSigma/std(mR(~lGaps));
    mR(lGaps) = mR(lGaps) * dSigmaE/std(mR(lGaps));
    
    % Compute annual volume change with introduced error
    mV = (mT + mR) .* mA;
    vVlmChj(i) = sum(mV(lPoly));
    
end

% Annual volume change error
dSigmaV = std(vVlmChj);

% Get annual geomorphic change data
dAreaH = sChange.historicalArea;
dAreaA = sChange.modernArea;
dVlmChj = sChange.volumeChange;
dMnElvChj = sChange.meanElevationChange;

% Glacier area errors
dSigmaH = dAreaH * sParams.areaPercentError/100;
dSigmaA = dAreaA * sParams.areaPercentError/100;

% Annual mean elevation change error
V = []; H = []; A = []; syms V H A
dSigmaE = PropError(V/mean([H A]),[V H A],[dVlmChj dAreaH dAreaA], ...
    [dSigmaV dSigmaH dSigmaA]); dSigmaE = dSigmaE{5};

% Annual geodetic mass balance error
E = []; D = []; syms E D
dSigmaG = PropError(E*D,[E D],[dMnElvChj sParams.materialDensity], ...
    [dSigmaE sParams.materialDensitySigma]); dSigmaG = dSigmaG{5};

% Output
sSigma.stableTerrain = dSigma;
sSigma.historicalArea = dSigmaH;
sSigma.modernArea = dSigmaA;
sSigma.volumeChange = dSigmaV;
sSigma.meanElevationChange = dSigmaE;
sSigma.geodeticMassBalance = dSigmaG;
