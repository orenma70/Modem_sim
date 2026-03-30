function [signal_out, cfr_in_db, cfr_out_db] = cfr1(signal_in, cfr_max_db)
    % Main CFR Function
    % Supports 'HC' (Hard Clipping) and 'CORDIC' methods

    % Method Selection (Matched to your Python toggle)
    cfr_method = 'CORDIC';

    % 1. Calculate input CFR
    cfr_in_db = calculate_cfr(signal_in);

    % 2. Apply chosen method
    if strcmp(cfr_method, 'HC')
        signal_out = cfr_hc(signal_in, cfr_max_db);
    elseif strcmp(cfr_method, 'CORDIC')
        signal_out = cfr_cordic(signal_in, cfr_max_db);
    else
        signal_out = signal_in;
    end

    % 3. Calculate output CFR
    cfr_out_db = calculate_cfr(signal_out);

    fprintf('CFR In-Out:  %.2f dB   %.2f dB\n', cfr_in_db, cfr_out_db);
end

% --- Helper: PAPR Calculation ---
function cfr_db = calculate_cfr(x)
    peak_amp = max(abs(x));
    rms_amp = sqrt(mean(abs(x).^2));
    if rms_amp == 0
        cfr_db = 0;
    else
        cfr_db = 20 * log10(peak_amp / rms_amp);
    end
end

% --- Helper: CORDIC CFR Implementation ---
function signal_out = cfr_cordic(signal_in, cfr_max_db, num_iter)
    if nargin < 3, num_iter = 9; end

    rms_linear = sqrt(mean(abs(signal_in).^2));
    limit_linear = rms_linear * (10 ^ (cfr_max_db / 20));

    % CORDIC Inverse Gain approx 0.60725
    inv_cordic_gain = 1.0 / 1.646760258;

    magnitudes = abs(signal_in);
    over_limit_idx = find(magnitudes > limit_linear);

    signal_out = signal_in;

    % Process only samples exceeding the threshold
    for k = 1:length(over_limit_idx)
        idx = over_limit_idx(k);
        sample = signal_in(idx);

        x_orig = real(sample);
        neg_flag = sign(x_orig);
        if neg_flag == 0, neg_flag = 1; end

        x = x_orig * neg_flag;
        y = imag(sample);

        % Initialize target vector (Target phase = source phase, Target Mag = limit)
        x_p = limit_linear * inv_cordic_gain;
        y_p = 0.0;

        % CORDIC Iterations (0 to num_iter-1)
        for i = 0:(num_iter - 1)
            if y < 0
                d = -1.0;
            else
                d = 1.0;
            end

            shift = 2.0 ^ (-i);

            % Vectoring Mode (Source)
            x_new = x + y * d * shift;
            y_new = y - x * d * shift;

            % Rotation Mode (Target)
            x_p_new = x_p - y_p * d * shift;
            y_p_new = y_p + x_p * d * shift;

            x = x_new;
            y = y_new;
            x_p = x_p_new;
            y_p = y_p_new;
        end

        signal_out(idx) = x_p * neg_flag + 1j * y_p;
    end
end

% --- Helper: Hard Clipping Implementation ---
function signal_out = cfr_hc(signal_in, cfr_max_db)
    rms_linear = sqrt(mean(abs(signal_in).^2));
    limit_vector = rms_linear * (10 ^ (cfr_max_db / 20));

    % Independent I and Q clipping (Square box)
    limit_comp = limit_vector / sqrt(2);

    real_clipped = max(min(real(signal_in), limit_comp), -limit_comp);
    imag_clipped = max(min(imag(signal_in), limit_comp), -limit_comp);

    signal_out = real_clipped + 1j * imag_clipped;
end
