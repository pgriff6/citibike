close all
clear
clc

data = xlsread('data_plots.xlsx',2);
data(:,1) = data(:,1) - 1;

subplot(2,2,1);
plot(data(:,1),data(:,2));
datetick('x','mm/dd/yy');
xlabel('Time');
ylabel('Average Node Degree');
title('Average Node Degree');

subplot(2,2,2);
plot(data(:,1),data(:,4));
datetick('x','mm/dd/yy');
xlabel('Time');
ylabel('Average Path Length');
title('Average Path Length');

subplot(2,2,[3,4]);
[hAx,~,~] = plotyy(data(:,1),data(:,5),data(:,1),data(:,6));
ylabel(hAx(1),'Modularity');
ylabel(hAx(2),'Number of Communities');
datetick('x','mm/dd/yy');
xlabel('Time');
legend('Modularity','Number of Communities');
title('Modularity and Number of Communities');