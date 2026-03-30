function rx_noisy = add_awgn(sig, snr_db)
    sig_power = mean(abs(sig).^2);
    noise_power = sig_power / (10^(snr_db/10));

    % יצירת רעש קומפלקסי
    noise = (sqrt(noise_power/2) * randn(size(sig))) + ...
            1j * (sqrt(noise_power/2) * randn(size(sig)));

    rx_noisy = sig + noise;
end
