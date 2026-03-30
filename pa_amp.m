function out = pa_amp(signal_in, model_type, varargin)
    % Unified Power Amplifier Impairment Function.
    % signal_in: Complex input signal
    % model_type: 'rapp', 'poly', or 'volterra'
    % varargin: Name-Value pairs (e.g., 'a1', [0.9, 0.1])

    if nargin < 2
        model_type = 'rapp';
    end

    % Gain Scaling (Matched to your Python code)
    gain1 = 16;
    x = signal_in * gain1;

    % Helper function to simulate kwargs.get()
    function val = get_kwarg(key, default_val)
        val = default_val;
        for i = 1:2:length(varargin)
            if strcmp(varargin{i}, key)
                val = varargin{i+1};
                return;
            end
        end
    end

    switch lower(model_type)
        case 'rapp'
            % SSPA soft-clipping (AM/AM)
            p = get_kwarg('p', 2.0);
            v_sat = get_kwarg('v_sat', 1.0);
            gain_db = get_kwarg('gain_db', 0);
            gain = 10 ^ (gain_db / 20);

            amplitude = abs(x);
            phase = angle(x);

            % Rapp Formula
            denom = (1 + (gain * amplitude / v_sat).^(2 * p)).^(1 / (2 * p));
            out_amp = (gain * amplitude) ./ denom;
            out = out_amp .* exp(1j * phase);

        case 'poly'
            % Memoryless Polynomial (AM/AM + AM/PM)
            c1 = get_kwarg('c1', 1.0 + 0j);
            c3 = get_kwarg('c3', -0.05 - 0.01j);
            c5 = get_kwarg('c5', -0.002 - 0.0005j);

            mag_sq = abs(x).^2;
            out = c1 * x + c3 * (mag_sq .* x) + c5 * (mag_sq.^2 .* x);

        case 'volterra'
            % Memory Polynomial Model (Simplified Volterra)
            % Default coeffs: a1 (Linear), a3 (3rd order)
            a1 = get_kwarg('a1', [1.0, -0.1]);
            a3 = get_kwarg('a3', [-0.05, -0.02]);

            % Equivalent to scipy.signal.lfilter(b, [1], x)
            branch1 = filter(a1, 1, x);
            branch3 = filter(a3, 1, x .* abs(x).^2);

            out = branch1 + branch3;

        otherwise
            error('Unknown model_type: %s', model_type);
    end

    % Scale back by gain1
    out = out / gain1;
end
