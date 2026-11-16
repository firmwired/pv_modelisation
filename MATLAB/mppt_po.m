function [D] = mppt_po(V, I) 
     
    persistent V_old P_old D_old

    delta_D = 0.005;
    D_max = .85;
    D_min = .05;
    D_init = .40;

    if isempty(V_old) 
       V_old = 0;
       P_old = 0;
       D_old = D_init;
    end

    P = V * I;
    dP = P - P_old;
    dV = V - V_old;

    D = D_old;

    if dP ~= 0
        if dP > 0
            if dV > 0
                D = D_old - delta_D;
            else
                D = D_old + delta_D;        
            end
        else
            if dV > 0
                D = D_old + delta_D;
            else 
                D = D_old - delta_D;

             end           
        end
    end
  if D > D_max 
      D = D_max;
  elseif D < D_min
      D = D_min;
  end
  
    V_old = V;
    P_old = P;
    D_old = D;
    
end