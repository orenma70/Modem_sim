function signal_out = cfr_cordic(signal_in, cfr_max_db, num_iter)
    % יצירת טבלת ארק-טאנגנס (LUT) - אינדקסים ב-Octave מתחילים ב-1
    i_vec = 0:(num_iter-1);
    atan_lut = atan(2.^-i_vec);

    % חישוב סף הקיטום (Clipping Threshold)
    rms_linear = sqrt(mean(abs(signal_in).^2));
    limit_linear = rms_linear * (10^(cfr_max_db / 20));

    % מקדם התיקון של CORDIC (מתכנס ל-1.6467...)
    % לחישוב מדויק לפי מספר האיטרציות:
    K = prod(sqrt(1 + 2.^(-2 * i_vec)));
    inv_K = 1/K;

    signal_out = signal_in;
    magnitudes = abs(signal_in);

    % מציאת האינדקסים שעוברים את הסף
    idx = find(magnitudes > limit_linear);

    % ריצה על כל דגימה שחורגת
    for k = 1:length(idx)
        curr_idx = idx(k);
        sample = signal_in(curr_idx);

        x = real(sample);
        if x<0
          neg_flag = -1;
        else
          neg_flag = 1;
        endif
        x = x * neg_flag;
        y = imag(sample);

        % שלב 1: וקטוריזציה (נרמול האמפליטודה תוך שמירה על הפאזה)
        % אנחנו נשתמש ב-CORDIC כדי לסובב את הווקטור המוגבל (limit_linear)
        % לאותה זווית של הווקטור המקורי.

        % נתחיל עם ווקטור על ציר ה-X באורך הגבול המבוקש
        x_rot = limit_linear * inv_K;
        y_rot = 0;

        % הרצה של ה-CORDIC (Vectoring Mode על האות המקורי)
        for i = 0:(num_iter-1)
            % בדיקת כיוון הסיבוב לפי ה-y הנוכחי של האות המקורי
            if y < 0
                d = -1;
            else
                d = 1;
            end

            % עדכון האות המקורי (כדי לדעת לאן לסובב)
            x_new = x + y * d * (2^-i);
            y_new = y - x * d * (2^-i);

            % סיבוב במקביל של הווקטור המוגבל (Rotation Mode)
            x_rot_new = x_rot - y_rot * d * (2^-i);
            y_rot_new = y_rot + x_rot * d * (2^-i);

            x = x_new;
            y = y_new;
            x_rot = x_rot_new;
            y_rot = y_rot_new;
        end

        % השמה של הערך המוגבל (שקיבל את הפאזה של המקור)
        signal_out(curr_idx) = x_rot * neg_flag + 1i * y_rot;
    end
end
