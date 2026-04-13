clc; clear; close all;

%% ================= USER INPUT =================
folder = 'PATH of IMAGES'; % <<< CHANGE
chunkSize = 500;
%% =============================================

files = dir(fullfile(folder,'*.tif'));
files = {files.name};
N = numel(files);

fprintf('Frames detected: %d\n',N);

I0 = im2double(imread(fullfile(folder,files{1})));
if size(I0,3)==3, I0 = rgb2gray(I0); end
[H,W] = size(I0);

FMI = zeros(H,W);

fprintf('Computing FMI map\n');

for k = 1:chunkSize:N
    k_end = min(k+chunkSize-1,N);

    for kk = k:k_end
        I = im2double(imread(fullfile(folder,files{kk})));
        if size(I,3)==3, I = rgb2gray(I); end
        FMI = FMI + I;
    end
end

FMI = FMI / N;

fprintf('FMI computation completed.\n');

%% ---- Save ----
outdir = fullfile(folder,'Simple_FMI_Output');
if ~exist(outdir,'dir'), mkdir(outdir); end

vmin = prctile(FMI(:),2);
vmax = prctile(FMI(:),98);
Fn = (FMI - vmin) / (vmax - vmin + eps);
Fn = min(max(Fn,0),1);

imwrite(Fn, fullfile(outdir,'FMI_gray.png'));

figure('Visible','off');
imagesc(FMI); axis image off;
colormap(jet); colorbar;
title('FMI Map');
saveas(gcf, fullfile(outdir,'FMI_color.png'));
close;

save(fullfile(outdir,'FMI.mat'),'FMI');

fprintf('✅ FMI map saved.\n');
