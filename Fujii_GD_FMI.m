clc; clear; close all;

%% ================= USER INPUT =================
folder = 'C:\Users\ADITYA\Downloads\Exp Data\Aman\frames'; % <<< CHANGE
chunkSize = 500;   % increase if RAM allows
%% =============================================

%% ---- Load files ----
files = dir(fullfile(folder,'*.tif'));
files = sort_nat({files.name});
N = numel(files);

fprintf('Frames detected: %d\n',N);

I0 = im2double(imread(fullfile(folder,files{1})));
if size(I0,3)==3, I0 = rgb2gray(I0); end
[H,W] = size(I0);

%% ---- Initialize Maps ----
Fujii_num = zeros(H,W);
Fujii_den = zeros(H,W);
GD_map    = zeros(H,W);
FMI_map   = zeros(H,W);

pairs = N - 1;

%% =====================================================
%% STEP 1: Compute Fujii and GD together
%% =====================================================
fprintf('Computing Fujii and GD maps...\n');

for k = 1:chunkSize:pairs
    k_end = min(k+chunkSize-1,pairs);

    for kk = k:k_end
        I1 = im2double(imread(fullfile(folder,files{kk})));
        I2 = im2double(imread(fullfile(folder,files{kk+1})));

        if size(I1,3)==3, I1 = rgb2gray(I1); end
        if size(I2,3)==3, I2 = rgb2gray(I2); end

        diffImg = abs(I1 - I2);

        Fujii_num = Fujii_num + diffImg;
        Fujii_den = Fujii_den + (I1 + I2);

        GD_map = GD_map + diffImg;
    end
end

Fujii_map = Fujii_num ./ (Fujii_den + eps);

fprintf('Fujii & GD completed.\n');

%% =====================================================
%% STEP 2: Compute FMI
%% =====================================================
fprintf('Computing FMI map...\n');

for k = 1:chunkSize:N
    k_end = min(k+chunkSize-1,N);

    for kk = k:k_end
        I = im2double(imread(fullfile(folder,files{kk})));
        if size(I,3)==3, I = rgb2gray(I); end
        FMI_map = FMI_map + I;
    end
end

FMI_map = FMI_map / N;

fprintf('FMI completed.\n');

%% =====================================================
%% SAVE RESULTS
%% =====================================================
outdir = fullfile(folder,'Combined_Speckle_Output');
if ~exist(outdir,'dir'), mkdir(outdir); end

save_map(Fujii_map,'Fujii',outdir);
save_map(GD_map,'GD',outdir);
save_map(FMI_map,'FMI',outdir);

fprintf('\n✅ All maps saved successfully.\n');

%% =====================================================
%% FUNCTIONS
%% =====================================================

function save_map(M,mapname,outdir)

    vmin = prctile(M(:),2);
    vmax = prctile(M(:),98);
    Mn = (M - vmin) / (vmax - vmin + eps);
    Mn = min(max(Mn,0),1);

    % grayscale
    imwrite(Mn, fullfile(outdir,[mapname '_gray.png']));

    % color
    figure('Visible','off');
    imagesc(M); axis image off;
    colormap(jet); colorbar;
    title(mapname);
    saveas(gcf, fullfile(outdir,[mapname '_color.png']));
    close;

    save(fullfile(outdir,[mapname '.mat']),'M');
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
