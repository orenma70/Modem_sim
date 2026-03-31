classdef DPDBlock
    properties
        K % Non-linear order
        Q % Memory depth
        coeffs % Learned coefficients
    end

    methods
        function obj = DPDBlock(K, Q)
            if nargin < 2
                obj.K = 5;
                obj.Q = 3;
            else
                obj.K = K;
                obj.Q = Q;
            end
            obj.coeffs = [];
        end

        function A = create_matrix(obj, x)
            % מבטיח ש-x הוא וקטור עמודה
            x = x(:);
            N = length(x);
            powers = 0:obj.K;
            num_powers = length(powers);
            num_coeffs = num_powers * (obj.Q + 1);

            A = zeros(N, num_coeffs);

            col = 1;
            for k = powers
                % חישוב האיבר הלא-ליניארי
                if k == 0
                    term = ones(N, 1); % Bias/DC term
                else
                    term = x .* (abs(x).^(k - 1));
                end

                for q = 0:obj.Q
                    delayed_term = zeros(N, 1);
                    if q == 0
                        delayed_term = term;
                    else
                        % הזזה (Memory Effect) - מילוי באפסים בתחילת הוקטור
                        delayed_term(q+1:end) = term(1:end-q);
                    end

                    A(:, col) = delayed_term;
                    col = col + 1;
                end
            end
        end


        function obj = load_model(obj, model_file)
            if exist(model_file, 'file')
                % טעינה לתוך מבנה S
                S = load(model_file);

                % עכשיו אפשר לגשת למשתנה ששמרנו ב-train (נניח שקראנו לו coeffs_to_save)
                if isfield(S, 'coeffs_to_save')
                    obj.coeffs = S.coeffs_to_save;
                elseif isfield(S, 'obj')
                    % אם בטעות שמרת את ה-Object כולו
                    obj.coeffs = S.obj.coeffs;
                end

                printf('Successfully loaded model from: %s\n', model_file);
            else
                error('File %s not found!', model_file);
            end
        end

        function obj = train(obj, x_in, y_out, gain)
          A = obj.create_matrix(y_out);

            % Lambda קטן מאוד (למשל 1e-6) עוזר ליציבות הנומרית
            lambda = 1e-6;
            [M, N_cols] = size(A);

            % פתרון Tikhonov Regularization (Ridge)
            % (A'A + lambda*I) * w = A' * x_in
            coeffs = (A' * A + lambda * eye(N_cols)) \ (A' * x_in(:));
            obj.coeffs =  coeffs * gain;
            coeffs_to_save = obj.coeffs; % השמה למשתנה פשוט
            save('-v7', 'dpd_model_voltera5x11.mat', 'coeffs_to_save');
        end

        function out = apply(obj, x)
            % יישום ה-Pre-distortion על הסיגנל
            A = obj.create_matrix(x);
            out = A * obj.coeffs;
            out = out.';
        end
    end
end
