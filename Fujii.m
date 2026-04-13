clc; clear; close all;

%% ================= USER INPUT =================
folder = 'C:\Users\ADITYA\Downloads\Exp Data\Aman\6.2.26\30fps-10ms'; % <<< CHANGE
chunkSize = 1000;   % adjust if RAM issue
%% =============================================

%% ---- Load files ----
files = dir(fullfile(folder,'*.tif'));
files = sort_nat({files.name});
N = numel(files);

fprintf('Frames detected: %d\n',N);

I0 = im2double(imread(fullfile(folder,files{1})));
if size(I0,3)==3, I0 = rgb2gray(I0); end
[H,W] = size(I0);

%% ---- Initialize ----
numSum = zeros(H,W);
denSum = zeros(H,W);
pairs = N - 1;

%% ---- Compute Fujii (p = 1) ----
fprintf('Computing Simple Fujii Map (p=1)\n');

for k = 1:chunkSize:pairs
    k_end = min(k+chunkSize-1,pairs);

    for kk = k:k_end
        I1 = im2double(imread(fullfile(folder,files{kk})));
        I2 = im2double(imread(fullfile(folder,files{kk+1})));

        if size(I1,3)==3, I1 = rgb2gray(I1); end
        if size(I2,3)==3, I2 = rgb2gray(I2); end

        numSum = numSum + abs(I1 - I2);
        denSum = denSum + (I1 + I2);
    end
end

F = numSum ./ (denSum + eps);

fprintf('Fujii computation completed.\n');

%% ---- Save Output ----
outdir = fullfile(folder,'Simple_Fujii_Output');
if ~exist(outdir,'dir'), mkdir(outdir); end

% ---- Normalize for display ----
vmin = prctile(F(:),2);
vmax = prctile(F(:),98);
Fn = (F - vmin) / (vmax - vmin + eps);
Fn = min(max(Fn,0),1);

% Save grayscale
imwrite(Fn, fullfile(outdir,'Fujii_gray.png'));

% Save colormap
figure('Visible','off');
imagesc(F); axis image off;
colormap(jet); colorbar;
title('Simple Fujii Map (p=1)');
saveas(gcf, fullfile(outdir,'Fujii_color.png'));
close;

% Save MAT file
save(fullfile(outdir,'Fujii.mat'),'F');

fprintf('✅ Simple Fujii Map saved.\n');


%% ---------- Natural Sorting ----------
function sorted = sort_nat(c)
    expr = '(\d+)';
    tokens = regexp(c,expr,'match');
    nums = cellfun(@(x) sscanf([x{:}],'%f'),tokens,'UniformOutput',false);
    maxlen = max(cellfun(@numel,nums));
    padded = cellfun(@(x)[x(:);nan(maxlen-numel(x),1)],nums,'UniformOutput',false);
    M = cell2mat(padded');
    [~,idx] = sortrows(M);
    sorted = c(idx);
end
