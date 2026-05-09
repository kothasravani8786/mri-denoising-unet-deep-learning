function [mseVal, maeVal, psnrVal, ssimVal] = computeMetrics(pred, gt)
% computeMetrics
% 
% Computes common image quality metrics between two MRI slices.
%
% INPUTS:
%   pred  - predicted/denoised image, it is same size as gt
%   gt    - ground truth clean image
%
% OUTPUTS:
%   mseVal   - mean squared error
%   maeVal   - mean absolute error
%   psnrVal  - peak signal-to-noise ratio
%   ssimVal   structural similarity index

    % Use only the single channel if shape is HxWx1
    if ndims(pred) == 3 && size(pred,3) == 1
        P = pred(:,:,1);
        G = gt(:,:,1);
    else
        P = pred;
        G = gt;
    end

    mseVal  = immse(P, G);
    maeVal  = mean(abs(P(:) - G(:)), 'omitnan');
    [psnrVal, ~] = psnr(P, G);
    [ssimVal, ~] = ssim(P, G);
end
