function [noisyAll, cleanAll] = buildPairsForAllSNR(cleanFiles, root, snrFolders)
% buildPairsForAllSNR
% 
% For each clean slice path, create corresponding noisy slice paths for
% each SNR folder. Used for preparing training and validation datasets.
%
% INPUTS:
%   cleanFiles  - list of clean slice paths
%   root        - project root containing clean_slices/ and noisy_slices/
%   snrFolders  - list of noisy SNR directories
%
% OUTPUTS:
%   noisyAll    - all noisy slice paths, inside SNR folders
%   cleanAll    - clean paths are duplicated for each noisy version

    root = string(root);
    cleanFiles = string(cleanFiles);

    noisyAll = strings(0,1);
    cleanAll = strings(0,1);

    cleanBase = fullfile(root, "clean_slices");
    noisyBase = fullfile(root, "noisy_slices");

    for i = 1:numel(cleanFiles)
        cf = cleanFiles(i);

        % Create one noisy path for each SNR level
        for s = 1:numel(snrFolders)
            snrFolder = snrFolders(s);

            noisyPath = strrep(cf, cleanBase, fullfile(noisyBase, snrFolder));

            noisyAll(end+1,1) = noisyPath;
            cleanAll(end+1,1) = cf;
        end
    end
end
