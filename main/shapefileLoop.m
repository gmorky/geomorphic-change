function [] = shapefileLoop(strShp,strSaveDir,strIdField, ...
    iNumBlocksX,iNumBlocksY,cFun,lParallel)

% Make sure save directory ends with backslash
if ~strcmp(strSaveDir(end),'\')
    strSaveDir = [strSaveDir '\'];
end

% Make spatial referencing vectors
sInfo = shapeinfo(strShp);
mBnd = sInfo.BoundingBox;
vX = linspace(mBnd(1),mBnd(2),iNumBlocksX+1);
vY = linspace(mBnd(3),mBnd(4),iNumBlocksY+1);

% Initialize block count variable
iBlock = 0;

% Function handle for processing blocks
hFun = @(x) process(x,strShp,strSaveDir,strIdField,cFun,vX,vY,lParallel);

% Block processing
warning('off','MATLAB:wrongBlockSize');
blockProcess([length(vY) length(vX)],1,'double',hFun);
warning('on','MATLAB:wrongBlockSize');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mGrid = process(sInput,strShp,strSaveDir,strIdField,cFun, ...
        vX,vY,lParallel)
    
% Initialize output
mGrid = [];
    
% Get input from block processing function
iX = sInput.countX;
iY = sInput.countY;

% Total number of blocks
iBlockTotal = (length(vX)-1)*(length(vY)-1);

if iBlockTotal == 1
    
    % Only a single block
    iBlock = [];
    
else
    
    % Current block number
    iBlock = sub2ind([length(vX)-1 length(vY)-1],iX,iY);

    % Update display
    disp(['processing block ' num2str(iBlock) ' of ' ...
         num2str(iBlockTotal) '...'])
end

% Bounding box for current block
mBox = [vX(iX) vY(iY);vX(iX+1) vY(iY+1)];

% Read shapefile
sShp = shaperead(strShp,'BoundingBox',mBox);

% Return if shapefile is empty
if isempty(sShp)
    warning('Empty shapefile...')
    return
end

% Process polygons in current block
processBlock(strSaveDir,strIdField,cFun,sShp,lParallel);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = processBlock(strSaveDir,strIdField,cFun,sShp,lParallel)

% Initialize
iNumPoly = numel(sShp);

% Normal or parallel processing
if lParallel
    
    % Loop through polygons
    parfor i = 1:iNumPoly
         polyLoop(strSaveDir,strIdField,cFun,sShp(i),iNumPoly,i);
    end
    
else
    
    % Loop through polygons
    for i = 1:iNumPoly
         polyLoop(strSaveDir,strIdField,cFun,sShp(i),iNumPoly,i);
    end
    
end
end
end