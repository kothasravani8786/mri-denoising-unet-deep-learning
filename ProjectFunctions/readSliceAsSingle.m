function img = readSliceAsSingle(filename)
% readSliceAsSingle
% 
% Loads a 2D MRI slice from file, converts it to grayscale,
% rescales it to single precision in [0,1], and reshapes it to 256x256x1.
%
% INPUT:
%   filename  - full path to the image file (.png, .jpg, etc.)
%
% OUTPUT:
%   img       - image returned as 256x256x1, single precision

    I = imread(filename);

    % If image has 3 channels, convert to grayscale
    if size(I,3) > 1
        I = rgb2gray(I);
    end

    % Convert to single precision [0,1]
    I = im2single(I);

    % Ensure shape is H x W x 1
    img = reshape(I, size(I,1), size(I,2), 1);
end
