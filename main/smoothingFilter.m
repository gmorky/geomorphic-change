function mData = smoothingFilter(mData,vWin,hFun)

% Return if window size parameter is invalid
if ~isvector(vWin) || any(isnan(vWin))
    return
end

% Make sure filter size is odd
vWin = 2*round((vWin+1)/2)-1;

% Mark NaN values
lNaN = isnan(mData);

% Pad borders
mData = padarray(mData,(vWin-1)/2,'symmetric');

% Get size of data grid
vSz = size(mData);

% Convert sliding window neighborhoods to columns
mData = im2col(mData,vWin);

% Smoothing function
vMed = hFun(mData);

% Rearrange
mData = col2im(vMed,vWin,vSz);

% Reset NaN values
mData(lNaN) = NaN;
