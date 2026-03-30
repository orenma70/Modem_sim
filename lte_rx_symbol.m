function [rx_bits, extracted, freq] = lte_rx_symbol(rx_in, symbol_idx, config)
    if mod(symbol_idx, 7) == 0
        cp_len = config.cp_first;
    else
        cp_len = config.cp_normal;
    end

    % הסרת CP
    no_cp = rx_in(cp_len + 1 : end);

    % FFT ומעבר למרכז
    freq = fftshift(fft(no_cp));

    % חילוץ הקריירים הרלוונטיים
    start_idx = floor((config.n_fft - config.num_sc) / 2) + 1;
    extracted = freq(start_idx : start_idx + config.num_sc - 1);

    % De-mapping לביטים
    rx_bits = zeros(1, config.num_sc * 2);
    rx_bits(1:2:end) = real(extracted) < 0;
    rx_bits(2:2:end) = imag(extracted) < 0;
end
