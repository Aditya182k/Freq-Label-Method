clc;
clear;
close all;

%% ---------------- SELECT FOLDER ----------------
videoFolder = uigetdir;
if videoFolder == 0
    disp('No folder selected');
    return;
end

%% ---------------- GET VIDEO FILES --------------
videoFiles = [ ...
    dir(fullfile(videoFolder, '*.avi')); 
    dir(fullfile(videoFolder, '*.mp4')); 
    dir(fullfile(videoFolder, '*.mov')) 
];

if isempty(videoFiles)
    disp('No video files found in selected folder');
    return;
end

fprintf('\nTotal Videos Found: %d\n\n', length(videoFiles));

%% ---------------- PROCESS EACH VIDEO ----------
for v = 1:length(videoFiles)
    
    filename = videoFiles(v).name;
    videoPath = fullfile(videoFolder, filename);
    
    fprintf('\n========================================\n');
    fprintf('Processing Video: %s\n', filename);
    
    %% -------- CREATE VIDEO OBJECT --------------
    vid = VideoReader(videoPath);
    
    %% -------- VIDEO INFO -----------------------
    FPS      = vid.FrameRate;
    Duration = vid.Duration;
    
    FrameTime = 1 / FPS;
    ExpectedFrames = floor(FPS * Duration);
    
    fprintf('FPS               : %.4f\n', FPS);
    fprintf('Duration (s)      : %.4f\n', Duration);
    fprintf('Expected Frames   : %d\n', ExpectedFrames);
    
    %% -------- OUTPUT FOLDER --------------------
    [~, name, ~] = fileparts(filename); % remove extension
    outputFolder = fullfile(videoFolder, name);
    
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
    
    %% -------- FRAME EXTRACTION -----------------
    fprintf('Extracting frames...\n');
    
    vid.CurrentTime = 0;
    extractedCount = 0;
    
    for k = 1:ExpectedFrames
        
        targetTime = (k-1) * FrameTime;
        
        if targetTime >= Duration
            break;
        end
        
        vid.CurrentTime = targetTime;
        
        if hasFrame(vid)
            frame = readFrame(vid);
            extractedCount = extractedCount + 1;
            
            frameName = sprintf('frame_%05d.tif', extractedCount);
            imwrite(frame, fullfile(outputFolder, frameName), 'tif');
        end
    end
    
    %% -------- REPORT ---------------------------
    fprintf('Extracted Frames     : %d\n', extractedCount);
    fprintf('Dropped Frames       : %d\n', ExpectedFrames - extractedCount);
    fprintf('Saved Folder         : %s\n', outputFolder);
    fprintf('========================================\n');
    
end

fprintf('\n\n✅ ALL VIDEOS PROCESSED SUCCESSFULLY\n');