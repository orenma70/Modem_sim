function rms_db = get_rms_db(sig)
    % חישוב RMS והמרה ל-dB
    rms_linear = sqrt(mean(abs(sig).^2));
    rms_db = 20 * log10(rms_linear);
end
