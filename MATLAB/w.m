% Memristive Weight Transfer charcteristics:

clear; clc; close all;
% parameters (from the code training.ipynb)
s = 1.0;                 % Weight scale
L = 16;                  % 16 concuctances level
sigma_d2d = 0.05;        % 5% Device-to-Device variations
sigma_c2c = 0.05;        % 5% Cycle-to-Cycle variations
saf_rate = 0.03;         % 3% total SAF rate (divided equally)
r = 0.002;               % Retention drift factor

% Dense grid of target weights w in [-1, 1]
w_target = linspace(-1, 1, 1000);
num_trials = 20;      % number of monte carlo sweeps

% compute hardware weights
compute_hw = @(w, d2d, c2c, saf_lrs, saf_hrs) ...
    s * (exp(-r) * max(0, min(1, round((L-1) * (saf_lrs.*1 + (~saf_lrs & saf_hrs).*0 + (~saf_lrs & ~saf_hrs).*max(0, min(1, d2d(1) .* (w + 1)/2)))) / (L-1) + c2c(1))) - ...
        exp(-r) * max(0, min(1, ...
            round((L-1) * (saf_lrs.*1 + (~saf_lrs & saf_hrs).*0 + (~saf_lrs & ~saf_hrs).*max(0, min(1, d2d(2) .* (1 - w)/2)))) / (L-1) + c2c(2) ...
        )) ...
    )

 
figure('Color', 'w', 'Position', [100, 100, 850, 400]);

subplot(1, 2, 1);
hold on; grid on; box on;

% ideal linear weight
plot(w_target, w_target, 'k', 'LineWidth', 2.5, 'DisplayName', 'Ideal Linear (w)');


g_pos_ideal = round((L-1) * (w_target + 1)/2) / (L-1);
g_neg_ideal = round((L-1) * (1 - w_target)/2) / (L-1);
w_quant = s * (g_pos_ideal - g_neg_ideal);
plot(w_target, w_quant, 'b-', 'LineWidth', 1.2, 'DisplayName', '16-Level Quantized (4-bit)');

% Noisy weights 
for k = 1:num_trials
    d_pos = max(0.7, min(1.3, 1 + randn(1) * sigma_d2d));
    d_neg = max(0.7, min(1.3, 1 + randn(1) * sigma_d2d));
    eps_pos = randn(size(w_target)) * sigma_c2c;
    eps_neg = randn(size(w_target)) * sigma_c2c;
    
    % Compute for zero SAF to show noise band
    g_p = max(0, min(1, round((L-1) * max(0, min(1, d_pos * (w_target + 1)/2))) / (L-1) + eps_pos)) * exp(-r);
    g_n = max(0, min(1, round((L-1) * max(0, min(1, d_neg * (1 - w_target)/2))) / (L-1) + eps_neg)) * exp(-r);
    w_noisy = s * (g_p - g_n);
    
    if k == 1
        p_noise = plot(w_target, w_noisy, 'Color', [0.85, 0.35, 0.25, 0.15], 'DisplayName', 'Noisy Trials (C2C + D2D)');
    else
        plot(w_target, w_noisy, 'Color', [0.85, 0.35, 0.25, 0.15], 'HandleVisibility', 'off');
    end
end

% Highlight Stuck-at-Fault examples (horizontal defects)
% Stuck-at-LRS on g_pos causes positive baseline shift
plot(w_target, s*(1 - g_neg_ideal)*exp(-r), 'm:', 'LineWidth', 1.5, 'DisplayName', 'SAF (g^+ stuck LRS)');
plot(w_target, s*(g_pos_ideal - 1)*exp(-r), 'c:', 'LineWidth', 1.5, 'DisplayName', 'SAF (g^- stuck LRS)');

xlabel('Target Synaptic Weight (w)');
ylabel('Effective Hardware Weight (w^{hw})');
title('(A) Memristor Weight Transfer Function');
legend('Location', 'northwest', 'FontSize', 8);
xlim([-1, 1]); ylim([-1.2, 1.2]);

% weight error distribution
subplot(1, 2, 2);
hold on; grid on; box on;

% Sample 20,000 random weights from standard normal (typical trained weights)
w_sample = max(-1, min(1, randn(20000, 1) * 0.3));
d2d_p = max(0.7, min(1.3, 1 + randn(size(w_sample)) * sigma_d2d));
d2d_n = max(0.7, min(1.3, 1 + randn(size(w_sample)) * sigma_d2d));
c2c_p = randn(size(w_sample)) * sigma_c2c;
c2c_n = randn(size(w_sample)) * sigma_c2c;
saf_lrs_p = rand(size(w_sample)) < (saf_rate/2);
saf_hrs_p = rand(size(w_sample)) < (saf_rate/2);
saf_lrs_n = rand(size(w_sample)) < (saf_rate/2);
saf_hrs_n = rand(size(w_sample)) < (saf_rate/2);

% Compute hardware weights for this sample
gp = max(0, min(1, d2d_p .* (w_sample + 1)/2));
gp(saf_lrs_p) = 1; gp(saf_hrs_p) = 0;
gp = max(0, min(1, round((L-1)*gp)/(L-1) + c2c_p)) * exp(-r);

gn = max(0, min(1, d2d_n .* (1 - w_sample)/2));
gn(saf_lrs_n) = 1; gn(saf_hrs_n) = 0;
gn = max(0, min(1, round((L-1)*gn)/(L-1) + c2c_n)) * exp(-r);

w_hw_sample = s * (gp - gn);
err = w_hw_sample - w_sample;

histogram(err, 60, 'Normalization', 'pdf', 'FaceColor', [0.2, 0.5, 0.8], 'EdgeColor', 'none');
xlabel('Weight Error (w^{hw} - w)');
ylabel('Probability Density');
title('(B) Write/Read Error Distribution');
xlim([-0.8, 0.8]);
 
text(-0.7, max(ylim)*0.85, sprintf('\\mu = %.4f\n\\sigma = %.4f', mean(err), std(err)), ...
    'BackgroundColor', 'w', 'EdgeColor', 'k', 'FontSize', 9);
exportgraphics(gcf, 'weight_transfer.pdf', 'ContentType', 'vector')