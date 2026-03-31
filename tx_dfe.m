function dpd_out = tx_dfe(tx_in, config)
    % tx_in: מטריצה בגודל (Nc x Samples)
    % nc: מספר הקריירים (שורו    nc = size(tx_in, 1);

    fs = config.fs;
    resample_factor = config.resample_factor;
    Nco_fs = fs * resample_factor;
    fs_d2a2d = config.fs_d2a2d;
    f_nco = config.f_nco;
    nc = config.Nc
    % מערך Cell לאחסון הסיגנלים המעובדים (עקב שינויי אורך קלים ב-conv)
    all_interpolated = cell(nc, 1);

    for i = 1:nc
        row = tx_in(i, :);

        % --- Interpolation Chain (As-Is) ---
        if resample_factor >= 2
            row = interpolation2(row, config.tx_fir1);
        end
        if resample_factor >= 4
            row = interpolation2(row, config.tx_fir2);
        end
        if resample_factor >= 8
            row = interpolation2(row, config.tx_fir3);
        end
        if resample_factor >= 16
            row = interpolation2(row, config.tx_fir3);
        end

        % NCO Up-conversion
        % Nf(i) עבור הקרייר הנוכחי
        n = (0:length(row)-1);
        nco = exp(1j * 2 * pi * config.Nf(i) / Nco_fs * n);
        row = row .* nco;

        all_interpolated{i} = row;
    end

    % מציאת האורך המינימלי לחיבור כל הקריירים
    min_len = min(cellfun(@length, all_interpolated));
    combined_signal = zeros(1, min_len);
    for i = 1:nc
        combined_signal = combined_signal + all_interpolated{i}(1:min_len);
    end

    % נרמול לפי מספר הקריירים
    combined_signal = combined_signal / nc;

    % --- Farrow Resample (x2 Gain) ---
    ftc_out = 2 * farrow_resample(combined_signal,f_nco, fs_d2a2d, config );

    % --- CFR (Crest Factor Reduction) ---
    [cfr_out, cfr_in_val, cfr_out_val] = cfr1(ftc_out, config.cfr_max_db);

    % --- DPD (Digital Pre-Distortion) ---
    % יצירת אובייקט DPD (K=5, Q=3)
    dpd_model = DPDBlock(5, 11);

    % אימון המודל על 10,000 דגימות ראשונות
    train_len = min(20000, length(cfr_out));
    x_in_train = cfr_out(1:train_len);
    x_in_train = x_in_train/norm(x_in_train);
    % קבלת דגימות מעוותות מה-PA לצורך הלמידה
    pa_distorted_initial = pa_amp(x_in_train, 'volterra', [0.9, 0.1], [-0.04, -0.01]);


    y_out_norm = pa_distorted_initial / (norm(pa_distorted_initial));
    % אימון ה-DPD (החזרת אובייקט מעודכן עם Coeffs)
    gain = adb20(my_rms_db(cfr_out));
    train_flag = false;
    if train_flag
      dpd_model = dpd_model.train(x_in_train, y_out_norm, gain);
    else
      dpd_model = dpd_model.load_model('dpd_model_voltera5x11.mat');
    endif
    % יישום ה-DPD על כל אות ה-CFR
    dpd_out = dpd_model.apply(cfr_out);


end
