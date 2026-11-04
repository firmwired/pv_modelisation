% constants
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
%G = 1000;%
G_list = [400, 600, 800, 1000 ];
d = 0.00065;
vpv = 0:0.01:25;  

ipv = zeros(1, length(vpv));
ppv = zeros(1, length(vpv));
temp = [ 0, 25, 50, 75];

vtr = (k * Tref) / q;
ir = Isc / (exp(Voc / (p * ns * vtr)) - 1);

figIV = figure('Color', 'w');
hold on;
grid on;

figPV = figure('Color', 'w');
hold on;
grid on;

for c = 1:length(G_list)
    Tk = 25 + 273.15;
    G = G_list(c);
    % to-do: reverser tk et tref
    irs = ir * (Tk / Tref)^3 * exp(((q * Eg) / (p * k)) * (1/Tref - 1/Tk));
    iph = (Isc + d * (Tk - Tref)) * (G / 1000);
   
    ipv = zeros(1, length(vpv));
    ppv = zeros(1, length(vpv));
    
    for idx = 1:length(vpv)
        i_curr = iph;
        di = delta + 1;
       
        % method newton-raphson
        while abs(di) > delta  
            f = i_curr - np * iph + (np * irs) * (exp((q * vpv(idx)) / (p * k * ns * Tk)) - 1);
            df = 1;
            di = -f / df;

            i_curr = i_curr + di;
             
        end
        if i_curr < 0
            i_curr = 0;
        end
        
        ipv(idx) = i_curr;
        ppv(idx) = vpv(idx) * ipv(idx);
    end
    
    figure(figIV);
    plot(vpv, ipv, 'LineWidth', 1.8, 'DisplayName', sprintf('%d °C', G_list(c)));
    
    figure(figPV);
    plot(vpv, ppv, 'LineWidth', 1.8, 'DisplayName', sprintf('%d °C', G_list(c)));
end
figure(figIV);
title('I-V caractéristiques');
xlabel('V');
ylabel('A');
 
legend('show', 'Location', 'southwest');
grid on;

figure(figPV);
title("P-V caractéristiques");
xlabel("tension");
ylabel("Puissance");
legend('show', "Location", "northwest")
