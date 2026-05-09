%% Evaluate MRI denoising on a single slice
% This script loads the trained U-Net model and evaluates it on one noisy/
% clean slice pair. It reports:
%   - MSE, MAE, PSNR, SSIM before denoising
%   - MSE, MAE, PSNR, SSIM after denoising
% It also displays the noisy, denoised, and clean images for comparison.

clear; clc;

%% 
%  CONFIGURATION
% 

% Base project directory
ROOT = "C:\WorkSpace\external\FMI"; 

% Path to trained MATLAB model (saved from train script)
modelPath = fullfile(ROOT, "unet2d_denoise.mat");

% Specific noisy and clean slice to test on
noisyPath = "C:\WorkSpace\external\FMI\IXI-T2\noisy_slices\rician_snr10\IXI086\IXI086_axial_k039.png";
cleanPath = "C:\WorkSpace\external\FMI\IXI-T2\clean_slices\IXI086\IXI086_axial_k039.png";

%% 
%  Load trained U-Net model
% 

if ~isfile(modelPath)
    error("Model file not found at: %s", modelPath);
end

fprintf("Loading model from:\n  %s\n", modelPath);
S   = load(modelPath);
net = S.net;

%% 
%  Load noisy and clean images
% 

noisy = readSliceAsSingle(noisyPath);
clean = readSliceAsSingle(cleanPath);

% Check dimension match
if ~isequal(size(noisy), size(clean))
    error("Noisy and clean images have different sizes:\n  noisy: %s\n  clean: %s", ...
        mat2str(size(noisy)), mat2str(size(clean)));
end

fprintf("Loaded noisy image:\n  %s\n", noisyPath);
fprintf("Loaded clean image:\n  %s\n", cleanPath);

%% 
%  Compute metrics BEFORE denoising
% 

[mse_noisy, mae_noisy, psnr_noisy, ssim_noisy] = computeMetrics(noisy, clean);

fprintf("\n=== BEFORE DENOISING (noisy vs clean) ===\n");
fprintf("MSE   : %.6f\n", mse_noisy);
fprintf("MAE   : %.6f\n", mae_noisy);
fprintf("PSNR  : %.2f dB\n", psnr_noisy);
fprintf("SSIM  : %.4f\n", ssim_noisy);

%% 
%  Run U-Net denoising
% 

denoised = predict(net, noisy);

% Ensure output is in single precision and correct size
denoised = im2single(denoised);

% Resize only if needed
if ~isequal(size(denoised), size(clean))
    warning("Denoised output size %s differs from clean size %s. Resizing...", ...
        mat2str(size(denoised)), mat2str(size(clean)));

    denoised = imresize(denoised, [size(clean,1) size(clean,2)]);
    denoised = reshape(denoised, size(clean));
end

%% 
%  Compute metrics AFTER denoising
% 

[mse_den, mae_den, psnr_den, ssim_den] = computeMetrics(denoised, clean);

fprintf("\n=== AFTER DENOISING (denoised vs clean) ===\n");
fprintf("MSE   : %.6f\n", mse_den);
fprintf("MAE   : %.6f\n", mae_den);
fprintf("PSNR  : %.2f dB\n", psnr_den);
fprintf("SSIM  : %.4f\n", ssim_den);

fprintf("\n=== IMPROVEMENT (noisy -> denoised) ===\n");
fprintf("ΔMSE  : %.6f\n", mse_noisy - mse_den);
fprintf("ΔMAE  : %.6f\n", mae_noisy - mae_den);
fprintf("ΔPSNR : %.2f dB\n", psnr_den - psnr_noisy);
fprintf("ΔSSIM : %.4f\n", ssim_den - ssim_noisy);

%% 
%  Visualization
% 

figure('Name','MRI Denoising Evaluation','NumberTitle','off');

subplot(1,3,1);
imshow(noisy, []);
title(sprintf('Noisy\nPSNR vs clean: %.2f dB', psnr_noisy));

subplot(1,3,2);
imshow(denoised, []);
title(sprintf('Denoised\nPSNR vs clean: %.2f dB', psnr_den));

subplot(1,3,3);
imshow(clean, []);
title('Clean (ground truth)');

%% 
%  Helper functions
% 

function img = readSliceAsSingle(filename)
    % Reads an image, converts it to grayscale if needed,
    % and returns it as a single-precision array in [0,1].

    I = imread(filename);

    if size(I,3) > 1
        I = rgb2gray(I);
    end

    I = im2single(I);
    img = reshape(I, size(I,1), size(I,2), 1);
end

function [mseVal, maeVal, psnrVal, ssimVal] = computeMetrics(pred, gt)
    % Computes standard evaluation metrics between pred and gt images.
    % Ensures both inputs are the same size and 2D.

    if ~isequal(size(pred), size(gt))
        error("computeMetrics: size mismatch between pred %s and gt %s", ...
            mat2str(size(pred)), mat2str(size(gt)));
    end

    % If 3D with a single channel, reduce to 2D
    if ndims(pred) == 3 && size(pred,3) == 1
        P = pred(:,:,1);
        G = gt(:,:,1);
    else
        P = pred;
        G = gt;
    end

    % Standard image metrics
    mseVal  = immse(P, G);
    maeVal  = mean(abs(P(:) - G(:)), 'omitnan');
    [psnrVal, ~] = psnr(P, G);
    [ssimVal, ~] = ssim(P, G);
end
