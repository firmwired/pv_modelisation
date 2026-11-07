% constant
t = 0 : 0.01 :200;
k = 1.38e-23;
q = 1.6021e-19;
Eg = 1.1;
p = 1.3;
ns = 36;
np = 1;
Isc = 4.8;
Voc = 21.7;
delta = 1e-8;
Tref = 25 + 273.15; 
 
% rayonement 
G = 1000;%                  
%G = [1000, 800, 600, 400 ];
d = 0.00065;
vpv = 0:0.01:25;  
ipv = zeros(1, length(vpv));
ppv = zeros(1, length(vpv));
temp = [ 0, 25, 50, 75];
%temp = [25];
vtr = (k * Tref) / q;
ir = Isc / (exp(Voc / (p * ns * vtr)) - 1);

% parameters de chage et convertiseur D
R_load = 30;     % resistance de la charge 
V_out_bus = 30;    
mode_D = 'R';    
D_min = 0.05;    % rapport cyclique max
D_max = 0.85;    % rapport cyclique max
 
G_sweep = 100:50:1000;    
temp_sweep = 15:5:65;     

dataset = [];

% figIV = figure('Color', 'w');
% hold on;
% grid on;
% 
% figPV = figure('Color', 'w');
% hold on;
% grid on;
% figMPPT = figure('Color', 'w');
% hold on;
% grid on;
 
for G_curr = G_sweep
    for c = 1:length(temp_sweep)
        Tk = temp_sweep(c) + 273.15;
        % to-do: reverser tk et tref
        irs = ir * (Tk / Tref)^3 * exp(((q * Eg) / (p * k)) * (1/Tref - 1/Tk));
        iph = (Isc + d * (Tk - Tref)) * (G_curr / 1000);
       
        ipv = zeros(1, length(vpv));
        ppv = zeros(1, length(vpv));
        mppt = zeros(1, length(vpv));

        for idx = 1:length(vpv)
            i_curr = iph;
            di = delta + 1;
           
            % method   raphson
            while abs(di) > delta  
                f = i_curr - np * iph + (np * irs) * (exp((q * vpv(idx)) / (p * k * ns * Tk)) - 1);
                df = 1;
                di = -f / df;

                i_curr = i_curr + di;
                 
            end
            if i_curr < 0
                i_curr = 0;
            end

            % mppt(idx) = mppt_po(vpv(idx), i_curr);
            ipv(idx) = i_curr;
            ppv(idx) = vpv(idx) * ipv(idx);
        end
        
        [P_mpp, max_idx] = max(ppv);
        V_mpp = vpv(max_idx);
        I_mpp = ipv(max_idx);
        
        if strcmp(mode_D, 'R')
            % cas charge resistive: Rin = (1 - D)^2 * R_load
            R_in = V_mpp / max(I_mpp, 1e-4);
            if R_in <= R_load
                D_mpp = 1 - sqrt(R_in / R_load);
            else
                D_mpp = D_min;
            end
        else
            % Cas sortie connectee a un bus DC: V_out = V_mpp / (1 - D)
            D_mpp = 1 - (V_mpp / V_out_bus);
        end
        
        D_mpp = max(D_min, min(D_max, D_mpp));
        
        dataset = [dataset; G_curr, temp_sweep(c), V_mpp, I_mpp, P_mpp, D_mpp];
        
        % figure(figMPPT);
        % plot(vpv, mppt, 'LineWidth', 1.8, 'DisplayName', sprintf('%d °C', temp(c)));
        % 
        % figure(figIV);
        % plot(vpv, ipv, 'LineWidth', 1.8, 'DisplayName', sprintf('%d °C', temp(c)));
        %  
        % figure(figPV);
        % plot(vpv, ppv, 'LineWidth', 1.8, 'DisplayName', sprintf('%d °C', temp(c)));
    end
end

inputs = dataset(:, 1:2);   % col 1 et 2: [G, T]
 
targets = dataset(:, 6);    % col 6: [D_mpp]

save('mppt_dataset.mat', 'dataset', 'inputs', 'targets');
 
% figure(figIV);
% title('I-V caractéristiques');
% xlabel('V');
% ylabel('A');
% axis([0 25 0 6]);
% legend('show', 'Location', 'southwest');
% grid on;
% 
% figure(figPV);
% title("P-V caractéristiques");
% xlabel("tension");
% ylabel("Puissance");
% legend('show', "Location", "northwest")
%  
% 
% figure(figMPPT);
% title("P-V caractéristiques");
% xlabel("tension");
% ylabel("Puissance");
% legend('show', "Location", "northwest")
% figure
% plot(vpv, vpv)
