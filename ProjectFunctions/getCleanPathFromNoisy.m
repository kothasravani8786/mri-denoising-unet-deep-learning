function cleanPath = getCleanPathFromNoisy(noisyPath, dataRoot)
% getCleanPathFromNoisy
% 
% Given the path of a noisy slice, reconstruct the corresponding
% clean slice path under clean_slices/.
%
% INPUTS:
%   noisyPath   - full path to noisy slice
%   dataRoot    - root folder containing noisy_slices/ and clean_slices/
%
% OUTPUT:
%   cleanPath   - full path to the matching clean slice

    noisyPath = string(noisyPath);
    dataRoot  = string(dataRoot);

    noisyBase = fullfile(dataRoot, "noisy_slices");
    cleanBase = fullfile(dataRoot, "clean_slices");

    % Remove "noisy_slices/rician_snrXX/" part
    rel = erase(noisyPath, noisyBase + filesep);
    parts = strsplit(rel, filesep);

    % parts{1} = rician_snrXX
    % parts{2} = subject folder
    % parts{3} = filename.png
    relClean = fullfile(parts{2:end});

    cleanPath = fullfile(cleanBase, relClean);
end
