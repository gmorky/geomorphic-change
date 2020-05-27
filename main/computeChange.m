function sChange = computeChange(mA,lPolyH,lPolyM,mT,lGaps, ...
    dMaterialDensity)

% Make sure no gaps remain within polygon
lPoly = lPolyH | lPolyM;
mT(~imdilate(lPoly,strel('disk',1))) = 0;
mT = inpaint_nans(mT);

% Historical and modern polygon areas
dAreaH = sum(mA(lPolyH));
dAreaM = sum(mA(lPolyM));

% Annual volume change
mV = mT.*mA;
dVlmChj = sum(mV(lPoly));

% Annual mean elevation change
dMnElvChj = dVlmChj/mean([dAreaH dAreaM]);

% Annual geodetic mass balance
dGeoMsBal = dMnElvChj*dMaterialDensity;

% Output
sChange.historicalArea = dAreaH;
sChange.modernArea = dAreaM;
sChange.percentDataCoverage = round((1 - sum(lGaps(:))/sum(lPoly(:)))*100);
sChange.volumeChange = dVlmChj;
sChange.meanElevationChange = dMnElvChj;
sChange.geodeticMassBalance = dGeoMsBal;
