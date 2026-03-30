function all_rx_carriers = rx_dfe(rx_in, config)
    % RX Digital Front End
    % rx_in: אות הכניסה (אחרי ה-Channel/PA)

    nc = config.Nc;
    fs = config.fs;
    resample_factor = config.resample_factor;
    Nco_fs = fs * resample_factor;
    fs_d2a2d = config.fs_d2a2d;
    f_nco = config.f_nco;

    % 1. Farrow Resampling (ממעבר תדר דגימה של ה-DAC חזרה לקצב ה-NCO)
    ftc_out = farrow_resample(rx_in, fs_d2a2d, f_nco, config);

    % אתחול Cell Array לאחסון הקריירים (למקרה שיש הבדלי אורך קלים מהפילטרים)
    all_rx_carriers_cell = cell(nc, 1);

    % 2. עיבוד כל קרייר בנפרד
    for i = 1:nc
        rx_out = ftc_out;

        % NCO Down-conversion (שימוש במינוס בתוך האקספוננט)
        n = (0:length(rx_out)-1);
        nco = exp(-1j * 2 * pi * config.Nf(i) / Nco_fs * n);

        % וודא ש-rx_out ו-nco באותם ממדים (וקטור עמודה/שורה)
        if size(rx_out, 1) ~= size(nco, 1)
            nco = nco.';
        end
        rx_out = rx_out .* nco;

        % --- Decimation Chain (As-Is) ---
        % סדר הפילטרים הפוך מה-TX כדי להוריד את קצב הדגימה חזרה ל-Baseband
        if resample_factor >= 16
            rx_out = decimation2(rx_out, config.tx_fir3);
        end
        if resample_factor >= 8
            rx_out = decimation2(rx_out, config.tx_fir3);
        end
        if resample_factor >= 4
            rx_out = decimation2(rx_out, config.tx_fir2);
        end
        if resample_factor >= 2
            rx_out = decimation2(rx_out, config.tx_fir1);
        end

        all_rx_carriers_cell{i} = rx_out;
    end

    % 3. המרה למטריצה סופית (Nc x Samples)
    % מוודא שכל הקריירים באותו אורך לפני ההמרה
    min_len = min(cellfun(@length, all_rx_carriers_cell));
    all_rx_carriers = zeros(nc, min_len);
    for i = 1:nc
        all_rx_carriers(i, :) = all_rx_carriers_cell{i}(1:min_len);
    end
end
