% train_unet2d_full_slices.m
%
% This script trains a 2D U-Net model to denoise MRI slices.
% It uses:
%   - clean_slices/  (ground truth clean images)
%   - noisy_slices/rician_snrXX/  (noisy versions at different SNRs)
%
% For every clean slice, multiple noisy versions (one per SNR level) are used as separate training examples. 
% The model is trained as a regression network, not segmentation. Final trained model is saved as:
%       unet2d_denoise.mat

clear; clc;

%% 
%  CONFIGURATION
% 

ROOT = "C:\WorkSpace\external\FMI\IXI-T2";

% Folders inside ROOT/noisy_slices for each SNR level
snrFolders = ["rician_snr30","rician_snr20","rician_snr15","rician_snr10"];

% Training hyperparameters
miniBatchSize = 8;
maxEpochs     = 20;
initialLR     = 1e-3;

% File path where the trained model will be saved
modelSavePath = fullfile(ROOT, "unet2d_denoise.mat");

% Input image size
imageSize = [256 256 1];

%% 
%  Build train/validation file lists (clean and noisy)
% 

trainListFile = fullfile(ROOT, "splits_slices", "train.txt");
valListFile   = fullfile(ROOT, "splits_slices", "val.txt");

% Check that the split files exist
if ~isfile(trainListFile) || ~isfile(valListFile)
    error("Missing train/val split files. Expected:\n%s\n%s", trainListFile, valListFile);
end

fprintf("Reading train/val slice lists...\n");

% Read list of clean image paths
trainCleanFiles = readlines(trainListFile);
valCleanFiles   = readlines(valListFile);

% Remove empty lines
trainCleanFiles = trainCleanFiles(trainCleanFiles ~= "");
valCleanFiles   = valCleanFiles(valCleanFiles ~= "");

% Convert to full paths
trainCleanFiles = fullfile(string(trainCleanFiles));
valCleanFiles   = fullfile(string(valCleanFiles));

% Build clean–noisy pairs for *all* SNR folders
fprintf("Building train pairs (all SNRs)...\n");
[trainNoisyFilesAll, trainCleanFilesAll] = buildPairsForAllSNR(trainCleanFiles, ROOT, snrFolders);

fprintf("Train: %d clean slices x %d SNR = %d samples\n", ...
    numel(trainCleanFiles), numel(snrFolders), numel(trainNoisyFilesAll));

fprintf("Building val pairs (all SNRs)...\n");
[valNoisyFilesAll, valCleanFilesAll] = buildPairsForAllSNR(valCleanFiles, ROOT, snrFolders);

fprintf("Val: %d clean slices x %d SNR = %d samples\n", ...
    numel(valCleanFiles), numel(snrFolders), numel(valNoisyFilesAll));

%% 
%  Datastores for loading images
% 
%
% Each datastore loads either noisy or clean slices.
% Then both are combined to create input→target pairs.

noisyReadFcn = @(f) readSliceAsSingle(f);
cleanReadFcn = @(f) readSliceAsSingle(f);

noisyTrainDs = imageDatastore(trainNoisyFilesAll, 'ReadFcn', noisyReadFcn);
cleanTrainDs = imageDatastore(trainCleanFilesAll, 'ReadFcn', cleanReadFcn);

noisyValDs = imageDatastore(valNoisyFilesAll, 'ReadFcn', noisyReadFcn);
cleanValDs = imageDatastore(valCleanFilesAll, 'ReadFcn', cleanReadFcn);

% Pair input (noisy) with target (clean)
trainDs = combine(noisyTrainDs, cleanTrainDs);
valDs   = combine(noisyValDs,   cleanValDs);

% Apply the minibatch preprocessing function
trainDs = transform(trainDs, @preprocessMiniBatch);
valDs   = transform(valDs,   @preprocessMiniBatch);

%% 
%  Build U-Net model for regression
% 

encoderDepth = 4;

% Create standard U-Net
lgraph = unetLayers(imageSize, 1, "EncoderDepth", encoderDepth);

% Find segmentation layer and replace with regression layer
segLayerName = "";
for i = 1:numel(lgraph.Layers)
    if isa(lgraph.Layers(i), 'nnet.layer.ClassificationLayer')
        segLayerName = lgraph.Layers(i).Name;
        break;
    end
end

% Replace segmentation output with regression output
if segLayerName ~= ""
    lgraph = removeLayers(lgraph, segLayerName);
    regLayer = regressionLayer("Name","regressionoutput");

    % Connect regression layer in place of segmentation layer
    conn = lgraph.Connections;
    idx = strcmp(conn.Destination, segLayerName);
    prevLayerName = conn.Source(idx);

    lgraph = addLayers(lgraph, regLayer);
    lgraph = connectLayers(lgraph, prevLayerName, "regressionoutput");
end

%% 
%  Training setup
% 

options = trainingOptions("adam", ...
    "InitialLearnRate",      initialLR, ...
    "MaxEpochs",             maxEpochs, ...
    "MiniBatchSize",         miniBatchSize, ...
    "Shuffle",               "every-epoch", ...
    "Plots",                 "training-progress", ...
    "Verbose",               true, ...
    "ValidationData",        valDs, ...
    "ValidationFrequency",   max(1, floor(numel(trainNoisyFilesAll) / (miniBatchSize*5))), ...
    "ExecutionEnvironment",  "auto", ...
    "ResetInputNormalization", false);

%% 
%  Train U-Net
% 

fprintf("Starting training...\n");
[net, trainInfo] = trainNetwork(trainDs, lgraph, options);

fprintf("Training completed. Saving model to:\n  %s\n", modelSavePath);
save(modelSavePath, "net", "trainInfo");

%% 
%  Helper functions
% 

function [noisyAll, cleanAll] = buildPairsForAllSNR(cleanFiles, root, snrFolders)
    % For every clean slice, create a matching noisy slice path for each SNR level.
    % Returns two arrays:
    %   noisyAll — full paths to noisy images
    %   cleanAll — clean images duplicated for each SNR

    root = string(root);
    cleanFiles = string(cleanFiles);

    noisyAll = strings(0,1);
    cleanAll = strings(0,1);

    cleanBase = fullfile(root, "clean_slices");
    noisyBase = fullfile(root, "noisy_slices");

    % Loop through clean images and build corresponding noisy maps
    for i = 1:numel(cleanFiles)
        cf = cleanFiles(i);

        for s = 1:numel(snrFolders)
            snrFolder = snrFolders(s);

            % Replace clean_slices portion of path with noisy_slices/rician_snrXX
            noisyPath = strrep(cf, cleanBase, fullfile(noisyBase, snrFolder));

            noisyAll(end+1,1) = noisyPath;
            cleanAll(end+1,1) = cf;
        end
    end
end

function img = readSliceAsSingle(filename)
    % Read a PNG slice and convert it to single precision [0,1]
    I = imread(filename);

    % Ensure grayscale
    if size(I,3) > 1
        I = rgb2gray(I);
    end

    % Convert to single precision, keep dimensions consistent
    I = im2single(I);
    img = reshape(I, size(I,1), size(I,2), 1);
end

function dataOut = preprocessMiniBatch(data)
    % Convert a minibatch of noisy/clean pairs into 4D arrays
    noisyImgs = data(:,1);
    cleanImgs = data(:,2);

    noisyStack = cat(4, noisyImgs{:});
    cleanStack = cat(4, cleanImgs{:});

    % Return cell array formatted as {input, target}
    dataOut = {noisyStack, cleanStack};
end
