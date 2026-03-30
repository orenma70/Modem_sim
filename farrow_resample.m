function y = farrow_resample(ftc_in, fs_in, fs_out, config)
    % 1. Setup dimensions and ratio
    % הנחה: config.farrow_taps היא מטריצה בגודל (7x5)

    [L, N_poly] = size(config.farrow_taps); % L=7, N_poly=5
    ratio = fs_in / fs_out;
    pad_len = floor((L - 1) / 2);
    half_fir = floor((L - 1) / 2);

    % 2. Generate the floating-point clock grid for the OUTPUT
    % מ-0 עד אורך הכניסה בקפיצות של ratio
    N_in = length(ftc_in);
    m_float = 0:ratio:(N_in - 2); % Python: np.arange(0, N_in - 1, ratio)

    % 3. Find n_int (nearest neighbor) and mu (fractional offset)
    % ב-Octave אינדקסים מתחילים ב-1, לכן נוסיף 1 ל-n_int המחושב
    n_int_zero_based = floor(m_float + 0.5);
    mu_array = m_float - n_int_zero_based; % טווח: [-0.5, 0.5]
    n_int = n_int_zero_based + 1;


    % 4. Padding the input (Reflect mode)
    % ב-Octave משתמשים ב-padarray מחבילת ה-image, או מימוש ידני פשוט:
    in_padded = [fliplr(ftc_in(2:pad_len+1)) ftc_in fliplr(ftc_in(end-pad_len:end-1))];

    % 5. Prepare the Polynomial matrix (Powers of mu)
    % יצירת מטריצה שבה כל עמודה היא mu בחזקת i
    num_output_samples = length(mu_array);
    mu_powers = zeros(N_poly,num_output_samples);
    for i = 0:(N_poly - 1)
        mu_powers(i+1,:) = (mu_array(:) .^ i);
    end

    % 6. Generate the filter for every single output sample
    % (Samples x 5) * (5 x 7) -> (Samples x 7)
    all_filters = (config.farrow_taps * mu_powers) / 256.0;

    % 7. Extract windows from the padded signal
    % תיקון אינדקס בגלל ה-Padding
    n_shifted = n_int + pad_len;

    % שליפת חלונות (Windows) בצורה יעילה
    windows = zeros(L, num_output_samples);
    for i = 1:num_output_samples
        idx = n_shifted(i);
        % שליפת החלון והפיכתו (Flip) כפי שמופיע ב-Python [::-1]
        win = in_padded(idx - half_fir : idx + half_fir);
        windows(:,i) = win(end:-1:1);
    end

    % 8. Final Dot Product (Sum across rows)
    % הכפלה איבר-איבר בין המטריצות וסיכום שורות
    y = sum(windows .* all_filters, 1);


end
