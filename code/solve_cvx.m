function [pu,Du] = solve_cvx(w1,w2,w3,B,n,Au,du,Gpu,Cp,Gdu,Cd)

% B = 1000;
% n = 100;
% Au = 60;
% du = 0.1;
% Gpu = 10;
% Cp = 30;
% Gdu = 5;
% Cd = 20;

% w1 = 1;
% w2 = 1;
% w3 = 1;

% min1 = (B*((Au^2*du^2*w1^2 + 2*Au*Gdu*du*w1*w3 + 2*Au*Gpu*du*w1*w2 + Cd^2*w3^2 + 2*Cd*Cp*w2*w3 + Cp^2*w2^2 + Gdu^2*w3^2 + 2*Gdu*Gpu*w2*w3 + Gpu^2*w2^2)/(Au^2*w1^2 + Cd^2*w3^2 + 2*Cd*Cp*w2*w3 + Cp^2*w2^2) - (2*(Cd*w3 + Cp*w2)*(Gdu*w3 + Gpu*w2 + Au*du*w1)*(Cd*Gdu*w3^2 + Cp*Gpu*w2^2 + Au*w1*(- Au^2*du^2*w1^2 + Au^2*w1^2 - 2*Au*Gdu*du*w1*w3 - 2*Au*Gpu*du*w1*w2 + Cd^2*w3^2 + 2*Cd*Cp*w2*w3 + Cp^2*w2^2 - Gdu^2*w3^2 - 2*Gdu*Gpu*w2*w3 - Gpu^2*w2^2)^(1/2) + Cd*Gpu*w2*w3 + Cp*Gdu*w2*w3 + Au*Cd*du*w1*w3 + Au*Cp*du*w1*w2))/(Au^2*w1^2 + Cd^2*w3^2 + 2*Cd*Cp*w2*w3 + Cp^2*w2^2)^2))/n;
% min2 = (B*((Au^2*du^2*w1^2 + 2*Au*Gdu*du*w1*w3 + 2*Au*Gpu*du*w1*w2 + Cd^2*w3^2 + 2*Cd*Cp*w2*w3 + Cp^2*w2^2 + Gdu^2*w3^2 + 2*Gdu*Gpu*w2*w3 + Gpu^2*w2^2)/(Au^2*w1^2 + Cd^2*w3^2 + 2*Cd*Cp*w2*w3 + Cp^2*w2^2) - (2*(Cd*w3 + Cp*w2)*(Gdu*w3 + Gpu*w2 + Au*du*w1)*(Cd*Gdu*w3^2 + Cp*Gpu*w2^2 - Au*w1*(- Au^2*du^2*w1^2 + Au^2*w1^2 - 2*Au*Gdu*du*w1*w3 - 2*Au*Gpu*du*w1*w2 + Cd^2*w3^2 + 2*Cd*Cp*w2*w3 + Cp^2*w2^2 - Gdu^2*w3^2 - 2*Gdu*Gpu*w2*w3 - Gpu^2*w2^2)^(1/2) + Cd*Gpu*w2*w3 + Cp*Gdu*w2*w3 + Au*Cd*du*w1*w3 + Au*Cp*du*w1*w2))/(Au^2*w1^2 + Cd^2*w3^2 + 2*Cd*Cp*w2*w3 + Cp^2*w2^2)^2))/n;

cvx_begin quiet
    variable pu
    % sub functions
    Gp=Cp*sqrt(1-((n/B)*pu));
    Gd=Cd*sqrt(1-((n/B)*pu));
    d=sqrt((n/B)*pu);

    % objective function
    Du=(w1*Au*(du-d))+(w2*(Gpu-Gp))+(w3*(Gdu-Gd));
    
    % constraints
    minimize(Du)
    subject to
        pu >= 0;
        pu <= B/n;
%         pu >= min1;
%         pu >= min2;
cvx_end

% disp(['pu = ' num2str(pu)]);
% disp(['Du = ' num2str(Du)]);
end