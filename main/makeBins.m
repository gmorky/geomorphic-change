function sOutput = makeBins(vX,vY,binParam,varargin)

% Set varargin to false
if nargin < 4
    varargin{1} = false;
end

% Define bins
if isscalar(binParam)
    dBinWidth = binParam;
    vBins = round(min(vX):dBinWidth:max(vX));
    vBinWidth = repmat(dBinWidth,[1 length(vBins)-1]);
elseif isvector(binParam)
    vBins = binParam;
    vBinWidth = diff(vBins);
end

% Initialize
iNumBins = max([1 length(vBins)-1]);
sOutput.bin = NaN(1,iNumBins);
sOutput.mean = NaN(1,iNumBins);
sOutput.median = NaN(1,iNumBins);
sOutput.min = NaN(1,iNumBins);
sOutput.max = NaN(1,iNumBins);
sOutput.std = NaN(1,iNumBins);
sOutput.mad = NaN(1,iNumBins);
sOutput.sum = NaN(1,iNumBins);
sOutput.nanCount = zeros(1,iNumBins);
sOutput.validCount = zeros(1,iNumBins);
if varargin{1}
    sOutput.values = cell(1,iNumBins);
end

% Check number of bins
if (iNumBins) < 2
    warning('Specified bin width resulted in less than 2 bins.')
    return
end

% Loop for each bin
for j = 1:iNumBins    

    % Index for data in current bin
    lIn = vX>vBins(j) & vX<=vBins(j+1);
    
    % Bin value
    sOutput.bin(j) = vBins(j)+vBinWidth(j)/2;   
    
    % Parameters
    try
        sOutput.mean(j) = nanmean(vY(lIn));
        sOutput.median(j) = nanmedian(vY(lIn));
        sOutput.min(j) = nanmin(vY(lIn));
        sOutput.max(j) = nanmax(vY(lIn));
        sOutput.std(j) = nanstd(vY(lIn));      
        sOutput.mad(j) = mad(vY(lIn & ~isnan(vY)));
        sOutput.sum(j) = nansum(vY(lIn));
        sOutput.nanCount(j) = sum(isnan(vY(lIn)));
        sOutput.validCount(j) = sum(~isnan(vY(lIn)));
        if varargin{1}
            sOutput.values{j} = vY(lIn);
        end
    catch
    end

end
