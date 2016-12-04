function [pu,PSQ] = solve_cvx(w1,w2,w3,B,n,Au,du,Gpu,Gdu)

% B = 1000;
% n = 100;
% Au = 60;
% du = 0.1;
% Gpu = 10;
% Gdu = 5;

% w1 = 1;
% w2 = 1;
% w3 = 1;

cvx_begin quiet
    variable pu
    % sub functions
    Gp=sqrt(1-((n/B)*pu));
    Gd=sqrt(1-((n/B)*pu));
    d=sqrt((n/B)*pu);

    % objective function
    PSQ=(w1*Au*(du-d))+(w2*(Gpu-Gp))+(w3*(Gdu-Gd));
    
    % constraints
    minimize(PSQ)
    subject to
        pu >= 0;
        pu <= B/n;
cvx_end

% disp(['pu = ' num2str(pu)]);
% disp(['Du = ' num2str(Du)]);
end