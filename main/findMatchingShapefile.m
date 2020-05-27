function sShpM = findMatchingShapefile(sParams,sShpH,strShpM)

% Read the matching shapefile
idField = sParams.polygonIdField;
if isnumeric(sShpH.(idField))
    sShpM = shaperead(strShpM,'Selector', ...
        {@(x) x == sShpH.(idField),idField});
elseif ischar(sShpH.(idField))
    sShpM = shaperead(strShpM,'Selector', ...
        {@(x) strcmp(x,sShpH.(idField)),idField});
else
    error('Unsupported polygon ID field type.')
end

% Return if matching shapefile not found
if isempty(sShpM)
    error('Matching modern shapefile not found.')
end

% Return if more than one matching shapefile found
if numel(sShpM) > 1
    error('More than one matching modern shapefile found.')
end

% Return if polygon has too many vertices
if length(sShpH.X) > sParams.maxVertices || ...
   length(sShpM.X) > sParams.maxVertices
    error('Number of vertices exceeds the threshold.')
end
