function dataOut = preprocessMiniBatch(data)
% preprocessMiniBatch
% 
% Converts cell arrays of noisy/clean images from the datastore into 
% 4-D tensors formatted as:
%       noisyBatch (H x W x 1 x batchSize)
%       cleanBatch (H x W x 1 x batchSize)
%
% INPUT:
%   data - cell array where:
%           data(:,1) = noisy images
%           data(:,2) = clean images
%
% OUTPUT:
%   dataOut - {noisyBatch, cleanBatch}, ready for trainNetwork()

    noisyImgs = data(:,1);
    cleanImgs = data(:,2);

    % Combine into 4-D minibatch arrays
    noisyBatch = cat(4, noisyImgs{:});
    cleanBatch = cat(4, cleanImgs{:});

    dataOut = {noisyBatch, cleanBatch};
end
