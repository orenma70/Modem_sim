function rx_out = decimation2(rx_in, fir_taps)
    % קונבולוציה עם חילוק ב-2 של המקדמים
    temp_out = conv(rx_in, fir_taps / 2, 'full');

    % פיצוי על השהיית הפילטר (fir_delay)
    fir_delay = floor((length(fir_taps) - 1) / 2);

    % חיתוך ודגימה מחדש (Downsample ב-2)
    rx_out = temp_out(fir_delay + 1 : fir_delay + length(rx_in));
    rx_out = rx_out(1:2:end);
end
