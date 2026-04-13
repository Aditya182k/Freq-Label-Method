clc; clear; close all;

%% ================= USER CONTROL PANEL =================
folder = 'PATH';   % <<< CHANGE
fps = 30;                           % acquisition frame rate
chunkSize = 1626;

% ===== CHOOSE ONE METHOD =====
% --- Option A: Define frequency labels (Hz)
freq_labels = [50 20 10 5 2 1 0.5 0.2 0.1];
p_list = round(fps ./ freq_labels);

% --- Option B: Define p directly (comment Option A if using this)
% p_list = [1 2 5 10 20 50 100 200 500 1000];
% freq_labels = fps ./ p_list;

apply_smoothing = true;
smooth_sigma = 1.5;
%% ======================================================

%% ---- Load images ----
files = dir(fullfile(folder,'*.tif'));
files = sort_nat({files.name});
N = numel(files);

fprintf('Frames detected: %d\n',N);

I0 = im2double(imread(fullfile(folder,files{1})));
if size(I0,3)==3, I0=rgb2gray(I0); end
[H,W] = size(I0);

outdir = fullfile(folder,'Fujii_Output');
if ~exist(outdir,'dir'), mkdir(outdir); end

%% ======================================================
%% NORMAL FUJII (p = 1)
%% ======================================================
fprintf('\nComputing Normal Fujii (p=1)\n');
F_normal = compute_fujii(folder,files,1,chunkSize);
save_fujii(F_normal,'Fujii_p1_Normal',outdir);

%% ======================================================
%% MULTI-p / MULTI-FREQUENCY FUJII
%% ======================================================
for i = 1:length(p_list)
    p = p_list(i);
    f = freq_labels(i);
    pairs = N - p;

    if pairs < 50
        fprintf('Skipping p=%d (%.2f Hz): insufficient pairs\n',p,f);
        continue;
    end

    fprintf('Computing Fujii: p=%d (%.2f Hz)\n',p,f);
    Fp = compute_fujii(folder,files,p,chunkSize);

    if apply_smoothing && p > fps   % slow dynamics
        Fp = imgaussfilt(Fp,smooth_sigma);
    end

    save_fujii(Fp,sprintf('Fujii_p%d_%.2fHz',p,f),outdir);
end

fprintf('\n✅ All Fujii maps completed\n');

%% ================== FUNCTIONS ==================

function F = compute_fujii(folder,files,p,chunkSize)
    N = numel(files);
    I0 = im2double(imread(fullfile(folder,files{1})));
    if size(I0,3)==3, I0=rgb2gray(I0); end
    [H,W] = size(I0);

    numSum = zeros(H,W);
    denSum = zeros(H,W);
    pairs = N - p;

    for k = 1:chunkSize:pairs
        k_end = min(k+chunkSize-1,pairs);
        for kk = k:k_end
            I1 = im2double(imread(fullfile(folder,files{kk})));
            I2 = im2double(imread(fullfile(folder,files{kk+p})));
            if size(I1,3)==3, I1=rgb2gray(I1); end
            if size(I2,3)==3, I2=rgb2gray(I2); end
            numSum = numSum + abs(I1-I2);
            denSum = denSum + (I1+I2);
        end
    end
    F = numSum ./ (denSum + eps);
end

function save_fujii(F,mapname,outdir)
    vmin = prctile(F(:),2);
    vmax = prctile(F(:),98);
    Fn = (F-vmin)/(vmax-vmin+eps);
    Fn = min(max(Fn,0),1);

    imwrite(Fn, fullfile(outdir,[mapname '_gray.png']));

    figure('Visible','off');
    imagesc(F); axis image off;
    colormap(jet); colorbar;
    title(mapname,'Interpreter','none');
    saveas(gcf, fullfile(outdir,[mapname '_color.png']));
    close;

    save(fullfile(outdir,[mapname '.mat']),'F');
end

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
