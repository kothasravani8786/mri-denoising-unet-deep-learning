function mri_denoise_gui_v2
% MRI Denoising GUI using a trained U-Net model (unet2d_denoise.mat)
% This interface allows the user to:
%   - Load any noisy MRI slice 
%   - Run the trained U-Net model to denoise it
%   - Display before/after/ground truth images
%   - Save the denoised output or a report screenshot

%% 
%  Load model and set basic configuration
% 

modelPath = "C:\WorkSpace\external\FMI\unet2d_denoise.mat";
dataRoot  = "C:\WorkSpace\external\FMI\IXI-T2";

% Ensure model file exists
if ~isfile(modelPath)
    error("Model file not found at:\n  %s", modelPath);
end

% Load trained U-Net
S   = load(modelPath);
net = S.net;
fprintf("Loaded trained model from:\n  %s\n", modelPath);

%% 
%  Main GUI window setup
% 

hFig = figure( ...
    'Name', 'MRI Denoising GUI (U-Net)', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'Toolbar', 'none', ...
    'Color', [0.95 0.95 0.95], ...
    'Units','normalized', ...
    'OuterPosition',[0 0 1 1]);   

% Layout values for image panels and buttons 
axTopY   = 0.35;      
axHeight = 0.55;
axWidth  = 0.25;
axGap    = 0.05;

axX1 = 0.05;
axX2 = axX1 + axWidth + axGap;
axX3 = axX2 + axWidth + axGap;

metricsY = 0.20;
metricsH = 0.10;
metricsW = 0.25;

btnRowY = 0.08;
btnH    = 0.05;
btnW    = 0.12;
btnGap  = 0.015;

totalBtnW = 5*btnW + 4*btnGap;
btnStartX = 0.5 - totalBtnW/2;

% Initial instruction text
statusText = uicontrol('Parent', hFig, 'Style','text', ...
    'String','Click "Load Noisy Image", then "Denoise" to run the model.', ...
    'HorizontalAlignment','center', ...
    'FontSize',10, ...
    'BackgroundColor',[0.95 0.95 0.95], ...
    'Units','normalized', ...
    'Position',[0.25, btnRowY+btnH+0.01, 0.5, 0.04]);

%% 
%  Axes (Noisy | Denoised | Clean)
% 

axNoisy    = axes('Parent', hFig, 'Position', [axX1 axTopY axWidth axHeight]);
axDenoised = axes('Parent', hFig, 'Position', [axX2 axTopY axWidth axHeight]);
axClean    = axes('Parent', hFig, 'Position', [axX3 axTopY axWidth axHeight]);

title(axNoisy,    'Noisy');    axis(axNoisy,'off');    colormap(axNoisy,gray);
title(axDenoised, 'Denoised'); axis(axDenoised,'off'); colormap(axDenoised,gray);
title(axClean,    'Clean');    axis(axClean,'off');    colormap(axClean,gray);

%% 
%  Text areas for metrics (Before | After | Improvement)
% 

txtBefore = uicontrol('Parent', hFig, 'Style','text', ...
    'HorizontalAlignment','left', 'FontName','Consolas', 'FontSize',9, ...
    'BackgroundColor',[0.95 0.95 0.95], 'Units','normalized', ...
    'Position',[axX1 metricsY metricsW metricsH], 'Visible','off');

txtAfter = uicontrol('Parent', hFig, 'Style','text', ...
    'HorizontalAlignment','left', 'FontName','Consolas', 'FontSize',9, ...
    'BackgroundColor',[0.95 0.95 0.95], 'Units','normalized', ...
    'Position',[axX2 metricsY metricsW metricsH], 'Visible','off');

txtDelta = uicontrol('Parent', hFig, 'Style','text', ...
    'HorizontalAlignment','left', 'FontName','Consolas', 'FontSize',9, ...
    'BackgroundColor',[0.95 0.95 0.95], 'Units','normalized', ...
    'Position',[axX3 metricsY metricsW metricsH], 'Visible','off');

%% 
%  Buttons
% 

btnLoad = uicontrol('Parent', hFig, 'Style','pushbutton', ...
    'String','Load Noisy', 'FontSize',10, 'Units','normalized', ...
    'Position',[btnStartX btnRowY btnW btnH], ...
    'Callback', @(src,evt)onLoadNoisy(hFig));

btnDenoise = uicontrol('Parent', hFig, 'Style','pushbutton', ...
    'String','Denoise', 'FontSize',11, 'FontWeight','bold', ...
    'BackgroundColor',[0.30 0.70 0.30], 'ForegroundColor',[1 1 1], ...
    'Units','normalized', ...
    'Position',[btnStartX + (btnW+btnGap) btnRowY btnW btnH], ...
    'Callback', @(src,evt)onDenoise(hFig));

btnHome = uicontrol('Parent', hFig, 'Style','pushbutton', ...
    'String','Home', 'FontSize',10, 'Units','normalized', ...
    'Visible','off', ...
    'Position',[btnStartX + 2*(btnW+btnGap) btnRowY btnW btnH], ...
    'Callback', @(src,evt)onHome(hFig));

btnSaveDenoised = uicontrol('Parent', hFig, 'Style','pushbutton', ...
    'String','Save Denoised', 'FontSize',10, 'Units','normalized', ...
    'Visible','off', ...
    'Position',[btnStartX + 3*(btnW+btnGap) btnRowY btnW btnH], ...
    'Callback', @(src,evt)onSaveDenoised(hFig));

btnSaveReport = uicontrol('Parent', hFig, 'Style','pushbutton', ...
    'String','Save Report', 'FontSize',10, 'Units','normalized', ...
    'Visible','off', ...
    'Position',[btnStartX + 4*(btnW+btnGap) btnRowY btnW btnH], ...
    'Callback', @(src,evt)onSaveReport(hFig));

%% 
%  Store GUI handles for use inside callbacks
% 

handles = struct();
handles.net          = net;
handles.dataRoot     = dataRoot;
handles.axNoisy      = axNoisy;
handles.axDenoised   = axDenoised;
handles.axClean      = axClean;
handles.btnLoad      = btnLoad;
handles.btnDenoise   = btnDenoise;
handles.btnHome      = btnHome;
handles.btnSaveDen   = btnSaveDenoised;
handles.btnSaveRep   = btnSaveReport;
handles.txtBefore    = txtBefore;
handles.txtAfter     = txtAfter;
handles.txtDelta     = txtDelta;
handles.statusText   = statusText;

% Data variables
handles.noisyImg     = [];
handles.noisyPath    = "";
handles.cleanImg     = [];
handles.denoisedImg  = [];

guidata(hFig, handles);

%% 
%  CALLBACKS
% 

function onLoadNoisy(hFigLocal)
    % Loads any noisy MRI slice the user selects
    handles = guidata(hFigLocal);

    [f, p] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif','Image files'}, ...
                       'Select noisy MRI slice');
    if isequal(f,0); return; end

    noisyPath = fullfile(p,f);
    noisy     = readSliceAsSingle(noisyPath);

    handles.noisyImg    = noisy;
    handles.noisyPath   = noisyPath;
    handles.cleanImg    = [];
    handles.denoisedImg = [];
    guidata(hFigLocal, handles);

    axes(handles.axNoisy);
    imshow(noisy, []);
    title(handles.axNoisy, sprintf('Noisy\n%s', f), 'Interpreter','none');

    % Reset other panels
    cla(handles.axDenoised); title(handles.axDenoised,'Denoised'); axis(handles.axDenoised,'off');
    cla(handles.axClean);    title(handles.axClean,'Clean');       axis(handles.axClean,'off');

    % Hide metric panels
    set(handles.txtBefore,'Visible','off');
    set(handles.txtAfter,'Visible','off');
    set(handles.txtDelta,'Visible','off');

    % Update buttons
    set(handles.btnDenoise,'Visible','on','Enable','on');
    set(handles.btnHome,'Visible','off');
    set(handles.btnSaveDen,'Visible','off');
    set(handles.btnSaveRep,'Visible','off');

    set(handles.statusText, 'String', 'Click "Denoise" to run the model.');
end

function onDenoise(hFigLocal)
    % Runs U-Net on the loaded noisy slice
    handles = guidata(hFigLocal);

    if isempty(handles.noisyImg)
        errordlg('Please load a noisy image first.','No Noisy Image');
        return;
    end

    % Hide buttons while model runs
    set(handles.btnDenoise,'Visible','off');
    set(handles.btnLoad,'Visible','off');
    set(handles.statusText,'Visible','off');

    noisy = handles.noisyImg;

    % Predict 
    den = predict(handles.net, noisy);
    den = im2single(den);

    % Keep size consistent
    if ~isequal(size(den), size(noisy))
        den = imresize(den, [size(noisy,1) size(noisy,2)]);
        den = reshape(den, size(noisy));
    end

    handles.denoisedImg = den;
    guidata(hFigLocal, handles);

    axes(handles.axDenoised);
    imshow(den, []);
    title(handles.axDenoised, 'Denoised');

    % Attempt to find matching clean image
    cleanPath = getCleanPathFromNoisy(handles.noisyPath, handles.dataRoot);

    if ~isfile(cleanPath)
        % If clean image not found, disable metrics
        warnMsg = sprintf('Clean image not found at:\n%s\nCannot compute metrics.', cleanPath);
        set(handles.txtBefore,'String',warnMsg,'Visible','on');
        return;
    end

    % Load clean version
    clean = readSliceAsSingle(cleanPath);
    handles.cleanImg = clean;
    guidata(hFigLocal, handles);

    axes(handles.axClean);
    [~,cleanName,ext] = fileparts(cleanPath);
    imshow(clean, []);
    title(handles.axClean, sprintf('Clean\n%s%s', cleanName,ext), 'Interpreter','none');

    % Compute metrics 
    [mse_noisy, mae_noisy, psnr_noisy, ssim_noisy] = computeMetrics(noisy, clean);
    [mse_den,   mae_den,   psnr_den,   ssim_den]   = computeMetrics(den, clean);

    % Before metrics
    set(handles.txtBefore,'Visible','on','String', sprintf( ...
        '=== BEFORE ===\nMSE: %.6f\nMAE: %.6f\nPSNR: %.2f dB\nSSIM: %.4f', ...
         mse_noisy, mae_noisy, psnr_noisy, ssim_noisy));

    % After metrics
    set(handles.txtAfter,'Visible','on','String', sprintf( ...
        '=== AFTER ===\nMSE: %.6f\nMAE: %.6f\nPSNR: %.2f dB\nSSIM: %.4f', ...
         mse_den, mae_den, psnr_den, ssim_den));

    % Improvements
    set(handles.txtDelta,'Visible','on','String', sprintf( ...
        '=== IMPROVEMENT ===\nΔMSE: %.6f\nΔMAE: %.6f\nΔPSNR: %.2f dB\nΔSSIM: %.4f', ...
         mse_noisy-mse_den, mae_noisy-mae_den, psnr_den-psnr_noisy, ssim_den-ssim_noisy));

    % Enable extra buttons
    set(handles.btnHome,'Visible','on');
    set(handles.btnSaveDen,'Visible','on');
    set(handles.btnSaveRep,'Visible','on');
end

function onHome(hFigLocal)
    % Resets the GUI to initial state
    handles = guidata(hFigLocal);

    handles.noisyImg    = [];
    handles.noisyPath   = "";
    handles.cleanImg    = [];
    handles.denoisedImg = [];
    guidata(hFigLocal, handles);

    cla(handles.axNoisy);    title(handles.axNoisy,'Noisy');    axis(handles.axNoisy,'off');
    cla(handles.axDenoised); title(handles.axDenoised,'Denoised'); axis(handles.axDenoised,'off');
    cla(handles.axClean);    title(handles.axClean,'Clean');    axis(handles.axClean,'off');

    set(handles.txtBefore,'Visible','off','String','');
    set(handles.txtAfter,'Visible','off','String','');
    set(handles.txtDelta,'Visible','off','String','');

    set(handles.btnDenoise,'Visible','on','Enable','on');
    set(handles.btnLoad,'Visible','on','Enable','on');

    set(handles.btnHome,'Visible','off');
    set(handles.btnSaveDen,'Visible','off');
    set(handles.btnSaveRep,'Visible','off');

    set(handles.statusText,'String',...
        'Click "Load Noisy Image", then "Denoise" to run the model.');
    set(handles.statusText,'Visible','on');
end

function onSaveDenoised(hFigLocal)
    % Save denoised output as PNG
    handles = guidata(hFigLocal);

    if isempty(handles.denoisedImg)
        errordlg('No denoised image to save.','Nothing to Save');
        return;
    end

    [f,p] = uiputfile({'*.png'}, 'Save denoised image');
    if isequal(f,0); return; end

    imgToSave = handles.denoisedImg;

    % Ensure it’s 2D
    if ndims(imgToSave)==3 && size(imgToSave,3)==1
        imgToSave = imgToSave(:,:,1);
    end

    imwrite(imgToSave, fullfile(p,f));
end

function onSaveReport(hFigLocal)
    % Saves a screenshot of the GUI including images and metrics
    [f,p] = uiputfile({'*.png'}, 'Save report screenshot');
    if isequal(f,0); return; end

    frame    = getframe(hFigLocal);
    imgFrame = frame2im(frame);
    imwrite(imgFrame, fullfile(p, f));
end

end 

%% 
%  Helper to reconstruct clean slice path from noisy slice path
% 
function cleanPath = getCleanPathFromNoisy(noisyPath, dataRoot)
    noisyPath = string(noisyPath);
    dataRoot  = string(dataRoot);

    noisyBase = fullfile(dataRoot, "noisy_slices");
    cleanBase = fullfile(dataRoot, "clean_slices");

    % Extract the relative part after noisy_slices/rician_snrXX
    rel = erase(noisyPath, noisyBase + filesep);
    parts = strsplit(rel, filesep);

    if numel(parts) < 2
        error("Unexpected noisy path structure: %s", noisyPath);
    end

    % Construct the path under clean_slices
    relClean = fullfile(parts{2:end});
    cleanPath = fullfile(cleanBase, relClean);
end

%% 
%  Helper to load 2D grayscale slice as single precision
% 
function img = readSliceAsSingle(filename)
    I = imread(filename);

    if size(I,3) > 1
        I = rgb2gray(I);
    end

    I = im2single(I);
    img = reshape(I, size(I,1), size(I,2), 1);
end

%% 
%  Helper to compute metrics between two images
% 
function [mseVal, maeVal, psnrVal, ssimVal] = computeMetrics(pred, gt)
    if ndims(pred)==3 && size(pred,3)==1
        P = pred(:,:,1);
        G = gt(:,:,1);
    else
        P = pred;
        G = gt;
    end

    mseVal  = immse(P,G);
    maeVal  = mean(abs(P(:)-G(:)), 'omitnan');
    [psnrVal, ~] = psnr(P,G);
    [ssimVal, ~] = ssim(P,G);
end
