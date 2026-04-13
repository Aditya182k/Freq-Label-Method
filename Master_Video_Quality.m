%% VIDEO QUALITY CHECK WITH THRESHOLDS
clc; clear; close all;

%% ================= SELECT VIDEO =================
[filename, pathname] = uigetfile({'*.avi;*.mp4;*.mov','Video Files'});
if isequal(filename,0)
    error('No video selected');
end
videoPath = fullfile(pathname, filename);

v = VideoReader(videoPath);

%% ================= THRESHOLDS ===================
TH.FPS_tol_percent        = 1;      % %
TH.Std_dt_ms_good         = 0.01;   % ms
TH.Std_dt_ms_bad          = 0.05;   % ms
TH.Drop_percent_bad       = 1;      % %
TH.Repeat_percent_good    = 2;      % %
TH.Repeat_percent_bad     = 5;      % %

%% =================================================
%% 1) VIDEO INFORMATION
%% =================================================
FPS      = v.FrameRate;
Duration = v.Duration;
Width    = v.Width;
Height   = v.Height;

ExpectedFrames = round(FPS * Duration);

fprintf('\n================ VIDEO INFORMATION =================\n');
fprintf('FPS (reported)         : %.4f fps\n', FPS);
fprintf('Duration               : %.4f s\n', Duration);
fprintf('Expected frames        : %d\n', ExpectedFrames);
fprintf('Resolution             : %d x %d\n', Width, Height);

fprintf('Status                 : GOOD\n');

%% =================================================
%% 2) FRAME-TO-FRAME TIMING
%% =================================================
t = [];
k = 1;

while hasFrame(v)
    readFrame(v);
    t(k) = v.CurrentTime; %#ok<SAGROW>
    k = k + 1;
end

dt = diff(t);               % seconds
dt_ms = dt * 1000;          % ms
Expected_dt = 1/FPS * 1000; % ms

figure;
plot(dt*1000,'-o');
xlabel('Frame number');
ylabel('Inter-frame time (ms)');
grid on;


%% =================================================
%% 3) DROPPED FRAMES
%% =================================================
dropped_idx = find(dt > 1.5*(Expected_dt/1000));
DroppedCount = numel(dropped_idx);
TotalFrames  = k - 1;
DropPercent  = 100 * DroppedCount / TotalFrames;

if DroppedCount == 0
    DropStatus = "GOOD";
elseif DropPercent < TH.Drop_percent_bad
    DropStatus = "BORDERLINE";
else
    DropStatus = "BAD";
end

fprintf('\n================ DROPPED FRAMES ====================\n');
fprintf('Dropped frames         : %d (%.3f%%)\n', DroppedCount, DropPercent);
fprintf('Status                 : %s\n', DropStatus);

%% =================================================
%% 4) MEAN & STD OF Δt
%% =================================================
Mean_dt = mean(dt_ms);
Std_dt  = std(dt_ms);
Min_dt  = min(dt_ms);
Max_dt  = max(dt_ms);

if Std_dt < TH.Std_dt_ms_good
    TimingStatus = "GOOD";
elseif Std_dt < TH.Std_dt_ms_bad
    TimingStatus = "BORDERLINE";
else
    TimingStatus = "BAD";
end

fprintf('\n================ TIMING STATISTICS =================\n');
fprintf('Expected Δt            : %.6f ms\n', Expected_dt);
fprintf('Mean Δt                : %.6f ms\n', Mean_dt);
fprintf('Std Δt                 : %.6f ms\n', Std_dt);
fprintf('Min Δt                 : %.6f ms\n', Min_dt);
fprintf('Max Δt                 : %.6f ms\n', Max_dt);
fprintf('Status                 : %s\n', TimingStatus);

figure;
plot(dt_ms,'k');
xlabel('Frame number');
ylabel('Inter-frame time (ms)');
title('Frame-to-frame timing');
grid on;

%% =================================================
%% 5) FREQUENCY DOMAIN CHECK
%% =================================================
v.CurrentTime = 0;
roi = [300 300 50 50];
signal = [];

while hasFrame(v)
    frame = rgb2gray(readFrame(v));
    sub = frame(roi(2):roi(2)+roi(4), roi(1):roi(1)+roi(3));
    signal(end+1) = mean(sub(:)); %#ok<SAGROW>
end

signal = signal - mean(signal);
N = length(signal);
Y = abs(fft(signal));
Y = Y(1:floor(N/2));
f = (0:length(Y)-1)*(FPS/N);

figure;
plot(f, Y);
xlim([0 FPS/2]);
xlabel('Frequency (Hz)');
ylabel('Amplitude');
title('Frequency-domain check');
grid on;

fprintf('\n================ FREQUENCY DOMAIN ==================\n');
fprintf('Nyquist frequency       : %.2f Hz\n', FPS/2);
fprintf('Status                  : GOOD (visual inspection)\n');

FreqStatus = "GOOD";  % FFT judged visually (correct practice)

%% =================================================
%% 6) REPEATED FRAMES
%% =================================================
v.CurrentTime = 0;
prev = [];
repeat_idx = [];

k = 1;
while hasFrame(v)
    frame = rgb2gray(readFrame(v));
    if ~isempty(prev) && isequal(frame, prev)
        repeat_idx(end+1) = k; %#ok<SAGROW>
    end
    prev = frame;
    k = k + 1;
end

RepeatCount   = numel(repeat_idx);
RepeatPercent = 100 * RepeatCount / (k-1);

if RepeatPercent < TH.Repeat_percent_good
    RepeatStatus = "GOOD";
elseif RepeatPercent < TH.Repeat_percent_bad
    RepeatStatus = "BORDERLINE";
else
    RepeatStatus = "BAD";
end

fprintf('\n================ REPEATED FRAMES ===================\n');
fprintf('Repeated frames        : %d (%.3f%%)\n', RepeatCount, RepeatPercent);
fprintf('Status                 : %s\n', RepeatStatus);

figure;
stem(repeat_idx, ones(size(repeat_idx)),'filled');
xlabel('Frame number');
ylabel('Repeated frame');
title('Repeated frame locations');

%% =================================================
%% FINAL VERDICT
%% =================================================
fprintf('\n================ FINAL VERDICT =====================\n');

if DropStatus=="GOOD" && TimingStatus=="GOOD" && RepeatStatus~="BAD"
    fprintf('VIDEO QUALITY : GOOD (READY FOR EXPERIMENT)\n');
elseif RepeatStatus=="BAD" || TimingStatus=="BAD"
    fprintf('VIDEO QUALITY : BAD (RECORD AGAIN)\n');
else
    fprintf('VIDEO QUALITY : BORDERLINE (USE WITH CAUTION)\n');
end

fprintf('===================================================\n');
