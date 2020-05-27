function [] = savePolygon(strSave,sPoly)
    
try

    % Save mat file
    try
        save(strSave,'-struct','sPoly')
    catch
        save(strSave,'-struct','sPoly','-v7.3')
    end
    
catch objExc
    
    warning(objExc.message)
    error('An error occurred while saving the polygon...')

end
