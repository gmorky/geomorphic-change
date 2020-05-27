function [] = polyLoop(strSaveDir,strIdField,cFun,sPoly,iNumPoly,iPoly)

try

    % Update display
    disp(['    processing polygon ' num2str(iPoly) ...
        ' of ' num2str(iNumPoly) ' in current block...'])
    
    % Filename to save
    strFile = sPoly.(strIdField);
    strSave = [strSaveDir strFile '.mat'];
    
    % Loop through user-defined functions
    for j = 1:numel(cFun)      
        sPoly = cFun{j}(sPoly);       
    end

    % Save the polygon
    savePolygon(strSave,sPoly);

catch objExc

    warning(objExc.message)
    warning('An error occured, skipping polygon...')

end


