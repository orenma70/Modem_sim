pkg load signal

% פונקציה פנימית לחישוב הטאפים (מקבילה ל-get_23_resampling_taps)
function h = get_resampling_taps(N)
    % במקום kaiser_beta(40), נשתמש בנוסחה הישירה עבור 40dB attenuation:
    % עבור אטינואציה (A) של 40dB:
    A = 40;
    if A > 50
        beta = 0.1102 * (A - 8.7);
    elseif A >= 21
        beta = 0.5842 * (A - 21)^0.4 + 0.07886 * (A - 21);
    else
        beta = 0;
    end

    % תכנון הפילטר - שימוש ב-fir1 עם חלון קייזר
    % N-1 כי fir1 מקבלת Order
    h = fir1(N-1, 0.5, kaiser(N, beta)) * 2;
end

config = struct();

config.bw = 100
config.cfr_max_db = 6

% --- קבועים ומערכים ---
config.farrow_taps = [
     9,   17,  -11,  -35,  -11;
   -17,  -71,    2,   96,   42;
    24,  223,  170, -116, -104;
   229,    0, -327,    0,  142;
    24, -223,  170,  116, -104;
   -17,   71,    2,  -96,   42;
     9,  -17,  -11,   35,  -11
];

% הגדרת הטאפים המרכזיים
config.h_resample = get_resampling_taps(31);

mmw = 1; % דגל mmWave

if mmw
    config.Nc = 8;
    config.scs = 120000;
    fc1 = 417 * config.scs;
    % יצירת Nf (תדרי הקריירים)
    config.Nf = (-(config.Nc - 1):2:(config.Nc - 1)) * fc1;

    bw_options = [50, 100, 200, 400];
    rb_array    = [32, 66, 132, 264];
    fft_array   = [512, 1024, 2048, 4096];
    cp_normal_array = [36, 72, 144, 288];
    cp_first_array  = [44, 80, 160, 320];
    idx = 2; % ב-Octave האינדקס הוא 2 עבור הערך השני (100MHz)
else
    config.scs = 15000;
    bw_options = [1.4, 3, 5, 10, 15, 20];
    rb_array    = [6, 15, 25, 50, 75, 100];
    fft_array   = [128, 256, 512, 1024, 1536, 2048];
    cp_normal_array = [9, 18, 36, 72, 108, 144];
    cp_first_array  = [10, 20, 40, 80, 120, 160];
    idx = 6; % אינדקס 6 עבור 20MHz
end

% חישוב FS
fs_array = fft_array * config.scs;

% חילוץ ערכים לפי האינדקס שנבחר
config.bw = bw_options(idx);
config.fs = fs_array(idx);
config.fs_d2a2d = 38.4e6 * 52;

% חישוב resample_factor
config.resample_factor = 2 ^ floor(log2(config.fs_d2a2d / config.fs));

config.f_nco = config.fs * config.resample_factor;
config.m_ftc = config.f_nco / config.fs_d2a2d;
config.n_rb = rb_array(idx);
config.n_fft = fft_array(idx);
config.cp_first = cp_first_array(idx);
config.cp_normal = cp_normal_array(idx);
config.num_sc = config.n_rb * 12;

% פילטרים נוספים
config.tx_fir1 = get_resampling_taps(23); % N=23 כפי שמוגדר בפונקציה ב-Python
config.tx_fir2 = [3, 0, -25, 0, 150, 256, 150, 0, -25, 0, 3] / 256;
config.tx_fir3 = [-1, 0, 9, 16, 9, 0, -1] / 16;

% אתחול Random Seed
rand('seed', 42);

fprintf('Config Setup Complete: BW=%dMHz, FS=%d, Factor=%d\n', ...
        config.bw, config.fs, config.resample_factor);
