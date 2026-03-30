function tx_out = interpolation2(tx_in, fir_taps)
    % 1. Upsampling (Zero-stuffing)
    % ב-Python: tx_upsampled[::2] = tx_in
    N = length(tx_in);
    tx_upsampled = zeros(1,N * 2);
    tx_upsampled(1:2:end) = tx_in;

    % 2. Anti-Imaging Filtering
    % ב-Python: np.convolve(..., mode='full')
    target_len = length(tx_upsampled);
    tx_full = conv(tx_upsampled, fir_taps, 'full');

    % 3. Delay Compensation (Alignment)
    % ב-Python: fir_delay = (len(fir_taps) - 1) // 2
    fir_delay = floor((length(fir_taps) - 1) / 2);

    % חיתוך האות לפי האורך המקורי (תוך פיצוי על השהיית הפילטר)
    % ב-Python: tx_full[fir_delay : fir_delay + target_len]
    start_idx = fir_delay + 1;
    end_idx = start_idx + target_len - 1;

    tx_out = tx_full(start_idx : end_idx);
end
