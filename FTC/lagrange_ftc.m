
% Define the function (usually at the end of the script or in its own file)
function out = lagrange_ftc(in, m)
    load Pint
    P=Pint/256
    [hw_phase_len,order] = size(P);
    ftc_n = 1;
    out_size = ceil(length(in) / m);

    acc = (0:(out_size-1)) * m;
    sh = floor(acc / ftc_n);
    acc = acc - sh * ftc_n;
    mu = acc - 0.5;

    % Ensure indices are within bounds
    % Adding padding to 'in' to avoid index out of bounds
    in_padded = [in, zeros(1, hw_phase_len + 10)];

    % Fractional Timing Control Logic
    % Constructing the index matrix
    idx = (sh') + (1:hw_phase_len);
    cbr = in_padded(idx);

    % P should be your Lagrange coefficient matrix (8x8 for hw_phase_len 8)
    % Assuming you have lagrange_coef defined or loaded
    %P = lagrange_coef(hw_phase_len);
    %P = round(P * 2^12) / 2^12;

    method = 'farrow';
    if strcmp(method, 'farrow')
        z = cbr * P;
        x = zeros(out_size, 1);
        for r = 1:order-1
            x = (x + z(:, r)) .* mu'; % Fixed 'xt' to 'x'
        end
        out = x + z(:, order);
    end
end

