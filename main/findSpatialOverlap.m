function vIdx = findSpatialOverlap(sParams,cBox,sShpH,sShpM)

% Spatial limits of polygon
mBoxA = [sShpH.BoundingBox;sShpM.BoundingBox];
mBoxA = [min(mBoxA(:,1)) max(mBoxA(:,1)) ...
    min(mBoxA(:,2)) max(mBoxA(:,2))];

% Spatial limits of rasters
cBox = cBox(:);
mBoxB = cell2mat(cellfun(@(x) ...
    [min(x(:,1)) max(x(:,1)) min(x(:,2)) max(x(:,2))],cBox,'Uni',0));

% Find where boxes overlap
vIdx = find(mBoxA(1) < mBoxB(:,2) & mBoxA(2) > mBoxB(:,1) & ...
    mBoxA(4) > mBoxB(:,3) & mBoxA(3) < mBoxB(:,4));

if sParams.polygonOverlapCheck
    
    % Combine polygon vertices to find overlapping rasters
    [mVerts(:,1),mVerts(:,2)] = polybool('union', ...
        sShpH.X,sShpH.Y,sShpM.X,sShpM.Y);

    % Simplify polygon for slight speed boost
    [mVertsS(:,2),mVertsS(:,1)] = reducem(mVerts(:,2),mVerts(:,1));
    mVerts = mVertsS; clear mVertsS

    % Find overlapping rasters
    for i = 1:numel(vIdx)   
        if isempty(polybool('intersection', ...
                mVerts(:,1),mVerts(:,2), ...
                cBox{vIdx(i)}(:,1),cBox{vIdx(i)}(:,2)))
            vIdx(i) = NaN;
        end    
    end

    % Remove rasters which don't overlap the polygon
    vIdx(isnan(vIdx)) = [];

end