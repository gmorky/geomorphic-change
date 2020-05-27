function mBox = makeBox(mBox,varargin)

% Get box limits
mBox = [min(mBox); max(mBox)];

% Add edge buffer
if nargin > 1
    iB = varargin{1};
    mBox = mBox + repmat(diff(mBox),[2 1]) .* ([-iB -iB; iB iB]/100);
end

% Specify all 4 corners
[mA,mB] = meshgrid(mBox(:,1),mBox(:,2));
mBox = reshape(cat(2,mA',mB'),[],2);

% Sort in clockwise order
mBox = mBox';
[mBox(1,:),mBox(2,:)] = sortPoints(mBox(1,:),mBox(2,:),'cw');
mBox = mBox';

% Find lower left corner
iRow = find(mBox(:,1) == min(mBox(:,1)) & mBox(:,2) == min(mBox(:,2)));

% Put lower left corner first
mBox = circshift(mBox,[size(mBox,1)-iRow+1 0]);


