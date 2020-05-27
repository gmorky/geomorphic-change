function mA = pixelAreas(mLon,mLat)

% Compute pixel areas
mPts = ll2utm([mLon(:) mLat(:)],[],[]);
mX = reshape(mPts(:,1),size(mLon));
mY = reshape(mPts(:,2),size(mLat));
mXr = abs(diff(mX,1,2)); mXr = [mXr(:,1) mXr];
mYr = abs(diff(mY,1,1)); mYr = [mYr(1,:);mYr];
mA = mXr .* mYr;
