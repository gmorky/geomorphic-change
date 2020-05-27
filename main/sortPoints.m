function [mX,mY] = sortPoints(mX,mY,strOrder)

% Get size of matrices. Each row is a polygon, columns are vertices.
[iR,iC] = size(mX);

% Sort points in counter-clockwise order
[~,mIdx] = sort(atan2(mY-repmat(mean(mY,2),1,iC), ...
                      mX-repmat(mean(mX,2),1,iC)),2,'ascend');
mIdx = sub2ind(size(mIdx),repmat((1:iR)',1,iC),mIdx);
mX = mX(mIdx);
mY = mY(mIdx);

% Flip order if clockwise is specified
if strcmp(strOrder,'cw')
    mX = fliplr(mX);
    mY = fliplr(mY);
elseif ~strcmp(strOrder,'ccw')
    error('Invalid input.')
end
