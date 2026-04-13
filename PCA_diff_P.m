clc;
clear;
close all;

%% ================= USER SETTINGS =================
folder = 'C:\Users\ADITYA\Downloads\Extracted_Frames'; % <<< CHANGE

p_list = [20];   % <<< YOUR FREQUENCY LABELS
numPC_static = 3;                    % Static PCs to remove

mainSaveFolder = 'PCA_Freq_Output';
if ~exist(mainSaveFolder,'dir')
    mkdir(mainSaveFolder);
end

%% ================= FILE SORTING =================
filesStruct = dir(fullfile(folder,'*.tif'));
fileNames = {filesStruct.name};

fileNumbers = zeros(length(fileNames),1);
for i = 1:length(fileNames)
    numStr = regexp(fileNames{i}, '\d+', 'match');
    fileNumbers(i) = str2double(numStr{end});
end
[~, idx] = sort(fileNumbers);
files = fileNames(idx);

totalFrames = length(files);
disp(['Total frames available: ', num2str(totalFrames)]);

%% ================= LOOP OVER p =================
for p = p_list

    fprintf('\n========== Processing p = %d ==========\n', p);

    %% ===== Select frames with gap p =====
    indices = 1:p:totalFrames;
    files_selected = files(indices);

    N = length(files_selected);
    fprintf('Frames used: %d\n', N);

    % Safety check
    if N < 10
        warning('Too few frames for PCA. Skipping p = %d', p);
        continue;
    end

    %% ===== Read first image =====
    img0 = double(imread(fullfile(folder, files_selected{1})));
    [rows, cols] = size(img0);
    M = rows * cols;

    %% ===== Build data matrix =====
    disp('Building data matrix...');
    X = zeros(M, N, 'double');

    for i = 1:N
        img = double(imread(fullfile(folder, files_selected{i})));
        X(:,i) = img(:);
    end

    %% ===== Center data =====
    meanFrame = mean(X,2);
    X_centered = X - meanFrame;

    %% ===== PCA using SVD =====
    disp('Performing PCA...');
    [U,S,V] = svd(X_centered,'econ');

    %% ===== Static reconstruction =====
    U_static = U(:,1:numPC_static);
    S_static = S(1:numPC_static,1:numPC_static);
    V_static = V(:,1:numPC_static);

    X_static = U_static * S_static * V_static';

    %% ===== Dynamic component =====
    X_dynamic = X_centered - X_static;

    %% ===== Save results =====
    saveFolder = fullfile(mainSaveFolder, sprintf('p_%d', p));
    if ~exist(saveFolder,'dir')
        mkdir(saveFolder);
    end

    disp('Saving dynamic frames...');
    for i = 1:N
        dynFrame = reshape(X_dynamic(:,i), rows, cols);
        dynFrame = mat2gray(dynFrame);

        imwrite(dynFrame, fullfile(saveFolder, ...
            sprintf('dyn_%04d.tif', i)));
    end

    fprintf('DONE for p = %d\n', p);

end

disp('ALL DONE!');