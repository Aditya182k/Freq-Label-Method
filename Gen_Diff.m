clc; clear; close all;

%% ================= USER INPUT =================
folder = 'C:\Users\ADITYA\Downloads\Exp Data\Aman\frames'; % <<< CHANGE
chunkSize = 2000;
%% =============================================

files = dir(fullfile(folder,'*.tif'));
files = {files.name};
N = numel(files);

fprintf('Frames detected: %d\n',N);

I0 = im2double(imread(fullfile(folder,files{1})));
if size(I0,3)==3, I0 = rgb2gray(I0); end
[H,W] = size(I0);

GD = zeros(H,W);
pairs = N - 1;

fprintf('Computing GD map\n');

for k = 1:chunkSize:pairs
    k_end = min(k+chunkSize-1,pairs);

    for kk = k:k_end
        I1 = im2double(imread(fullfile(folder,files{kk})));
        I2 = im2double(imread(fullfile(folder,files{kk+1})));

        if size(I1,3)==3, I1 = rgb2gray(I1); end
        if size(I2,3)==3, I2 = rgb2gray(I2); end

        GD = GD + abs(I1 - I2);
    end
end

fprintf('GD computation completed.\n');

%% ---- Save ----
outdir = fullfile(folder,'Simple_GD_Output');
if ~exist(outdir,'dir'), mkdir(outdir); end

vmin = prctile(GD(:),2);
vmax = prctile(GD(:),98);
Gn = (GD - vmin) / (vmax - vmin + eps);
Gn = min(max(Gn,0),1);

imwrite(Gn, fullfile(outdir,'GD_gray.png'));

figure('Visible','off');
imagesc(GD); axis image off;
colormap(jet); colorbar;
title('GD Map');
saveas(gcf, fullfile(outdir,'GD_color.png'));
close;

save(fullfile(outdir,'GD.mat'),'GD');

fprintf('✅ GD map saved.\n');
