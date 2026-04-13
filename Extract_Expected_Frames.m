clc;
clear;
close all;

%% ---------------- SELECT VIDEO ----------------
[filename, pathname] = uigetfile({'*.avi;*.mp4;*.mov','Video Files'});
if isequal(filename,0)
    disp('No video selected');
    return;
end
videoPath = fullfile(pathname, filename);

%% ---------------- READ VIDEO ------------------
vid = VideoReader(videoPath);

%% ---------------- VIDEO INFORMATION -----------
FPS      = vid.FrameRate;
Duration = vid.Duration;

FrameTime = 1 / FPS;
ExpectedFrames = floor(FPS * Duration);

fprintf('\n=========== VIDEO INFO ===========\n');
fprintf('FPS               : %.4f\n', FPS);
fprintf('Duration (s)      : %.4f\n', Duration);
fprintf('Frame Time (s)    : %.6f\n', FrameTime);
fprintf('Expected Frames   : %d\n', ExpectedFrames);
fprintf('==================================\n\n');

%% ---------------- OUTPUT FOLDER ----------------
outputFolder = fullfile(pathname, 'Extracted_Frames');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% ---------------- FRAME EXTRACTION -------------
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
        
        % Save frame
        frameName = sprintf('frame_%05d.tif', extractedCount);
        imwrite(frame, fullfile(outputFolder, frameName), 'tif');
    end
end

%% ---------------- FINAL REPORT -----------------
fprintf('\n=========== EXTRACTION REPORT ===========\n');
fprintf('Expected Frames      : %d\n', ExpectedFrames);
fprintf('Extracted Frames     : %d\n', extractedCount);
fprintf('Dropped Frames       : %d\n', ExpectedFrames - extractedCount);
fprintf('Saved Folder         : %s\n', outputFolder);
fprintf('========================================\n');
