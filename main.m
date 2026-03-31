clc;
close all
clear;% טעינת פרמטרים (הנחה: הגדרת את המשתנים ב-config_setup.m או טענת מ-mat)
config_setup  % למשל: config = load_cconfig_setuponfig();

snr_db = 6;

fprintf('LTE %dMHz | FFT %d | SNR %ddB\n', config.bw, config.n_fft, snr_db);

% אתחול מבני נתונים
all_tx_sig = cell(config.Nc, 1);
all_tx_bits = cell(config.Nc, 7); % מטריצת Cell לשמירת הביטים

% לולאת יצירת הסיגנל
for f_idx = 1:config.Nc
temp_sig = [];
    for s_idx = 1:7
        % Generate the signal (הנחה: s_idx-1 כי ב-Python זה 0-6)
        [tx_sig, tx_bits] = lte_tx_symbol(s_idx - 1,config);

        temp_sig = [temp_sig tx_sig]; % שרשור וקטורי
        all_tx_bits{f_idx, s_idx} = tx_bits;
    end
    all_tx_sig{f_idx} = temp_sig;
end

% המרה למטריצה עבור ה-TX DFE (בהתאם למימוש שלך ב-Python)
all_tx_sig_mat = cell2mat(all_tx_sig);

% TX DFE
all_tx_sig_processed = tx_dfe(all_tx_sig_mat, config);

% Power Amplifier (PA)
% pa_out = pa_amp(all_tx_sig_processed, 'rapp', 3, 1.2);
pa_out = pa_amp(all_tx_sig_processed, 'volterra', [0.9, 0.1], [-0.04, -0.01]);


[spectra, Pxx_ci, freq] = pwelch(pa_out, 2048, 0.5, 2048, 1996.8e6, 'twosided');
%pa_out = all_tx_sig_processed;
% Channel & Noise
semilogy(freq/1e6, spectra);
grid on;
xlabel('Frequency [MHz]');
ylabel('PSD');rx_sig_total = add_awgn(pa_out, snr_db);

% RX DFE - מחזיר מטריצה שבה כל שורה/עמודה היא Carrier
rx_sig = rx_dfe(rx_sig_total, config);

delay_offset = 0;
total_errors = zeros(config.Nc, 1);
all_rx_samples = cell(config.Nc, 1);

% לולאה חיצונית: עיבוד כל Carrier
for f_idx = 1:config.Nc
    current_pos = 1; % ב-Octave מתחילים ב-1

    % שליפת הסיגנל של הקרייר הנוכחי (הנחה: rx_sig היא מטריצה Samples x Carriers)
    rx_carrier_sig = rx_sig(f_idx,:);

    % לולאה פנימית: עיבוד 7 סימבולים
    for s_idx = 1:7
        % CP length logic
        if s_idx == 1
            cp_len = config.cp_first;
        else
            cp_len = config.cp_normal;
        end

        symbol_total_length = cp_len + config.n_fft;

        % Windowing
        start_idx = current_pos + delay_offset;
        end_idx = start_idx + symbol_total_length - 1;

        % Guard against index out of bounds
        if end_idx > length(rx_carrier_sig)
            break;
        end

        symbol_segment = rx_carrier_sig(start_idx:end_idx);

        % Standard LTE/5G RX processing (Python s_idx-1)
        [rx_bits, extracted, freq] = lte_rx_symbol(symbol_segment, s_idx - 1,config);

        % חישוב שגיאות - השוואה מול הביטים שנשמרו
        tx_bits_compare = all_tx_bits{f_idx, s_idx};
        total_errors(f_idx) = total_errors(f_idx) + sum(tx_bits_compare(:) ~= rx_bits(:));

        % שמירת דגימות QAM
        all_rx_samples{f_idx} = [all_rx_samples{f_idx}; extracted(:)];

        current_pos = current_pos + symbol_total_length;
    end
end

% Reporting
for i = 1:config.Nc
    fprintf('Channel %d Errors: %d\n', i-1, total_errors(i));
end

fprintf('------------------------------\n');
ber = total_errors / (7 * config.num_sc * 2);
disp('Final BER:');
disp(ber);
fprintf('------------------------------\n');

fprintf('Fs : Nco - D2A : %f %f\n', config.f_nco, config.fs_d2a2d);
