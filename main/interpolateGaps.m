function [mT,lGaps,sBins] = interpolateGaps(mZ,mT,lPoly,sParams)

switch sParams.method
    case 'simpleFill'
        
        % No elevation bins
        sBins = [];
        
        % Save data gaps mask
        lGaps = lPoly & isnan(mT);
        
        % Fill data gaps with specified value
        mT(lGaps) = sParams.fillVal;
        
    case 'spatialInterp'
        
        % No elevation bins
        sBins = [];
        
        % Save data gaps mask
        lGaps = lPoly & isnan(mT);
        
        % Fill data gaps by spatial linear interpolation
        if isnumeric(sParams.polygonEdges)
            mTi = mT;
            mTi(~lPoly) = sParams.polygonEdges;
            mTi = inpaint_nans(mTi);
            mT(lPoly) = mTi(lPoly);
        else
            lGapsOutsidePoly = ~lPoly & isnan(mT);
            mT = inpaint_nans(mT);
            mT(lGapsOutsidePoly) = NaN;
        end
        
    case 'elevationBins'
        
        % Remove elevation bin outliers (within the polygon)
        mT(lPoly) = removeBinOutliers(mZ(lPoly),mT(lPoly),sParams);
        
        % Save elevation bin data (before interpolation)
        sBins = makeBins(mZ(lPoly),mT(lPoly),sParams.binWidth);
        
        % Save data gaps mask
        lGaps = lPoly & isnan(mT);
        
        % Fill data gaps by linear interpolation of elevation bins
        mT(lPoly) = elevBinsFill(mZ(lPoly),mT(lPoly),sParams);
        
end
