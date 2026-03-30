function [tx_out, bits] = lte_tx_symbol(symbol_idx, config)
    % לוגיקת אורך CP
    if mod(symbol_idx, 7) == 0
        cp_len = config.cp_first;
    else
        cp_len = config.cp_normal;
    end

    % יצירת ביטים אקראיים (0 או 1)
    bits = randi([0, 1], 1, config.num_sc * 2);

    % מיפוי QPSK
    syms = ((1 - 2*bits(1:2:end)) + 1j*(1 - 2*bits(2:2:end))) / sqrt(2);

    % בניית ה-Buffer בתדר
    buffer = zeros(1,config.n_fft);
    start_idx = floor((config.n_fft - config.num_sc) / 2) + 1;
    buffer(start_idx : start_idx + config.num_sc - 1) = syms;

    % IFFT ומעבר לזמן
    time_sig = ifft(ifftshift(buffer));

    % הוספת CP (8* להשוואת Gain כפי שמופיע ב-Python)
    tx_out = 8 * [time_sig(end-cp_len+1:end) time_sig];
end
