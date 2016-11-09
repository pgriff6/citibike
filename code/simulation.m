close all
clear
clc

% FIX TIMING FOR INITIALIZATION AND SIMULATION!!! *****************************************************
% FIX ASPECT THAT NEW BIKE IDS COULD COME INTO PLAY DURING THE SIMULATION!!! **************************
% FIX ISSUE THAT STATIONS MAY HAVE MORE THAN THE MAXIMUM CAPACITY OF CURRENT BIKES!!! *****************

% Import bike trip data file for initialization
disp('Select bike trip data file to use for initialization');
[filename,pathname] = uigetfile('*.csv','Select bike trip data file to use for initialization'); % Specify file to import
if filename == 0
    error('No csv file selected');
end
data = {};
disp(['Importing "' pathname filename '"']);
fid = fopen([pathname filename],'r');
x = textscan(fid,'%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q','delimiter',',');
fclose(fid);
for k = 1:15
    data(:,k) = x{1,k};  % Append file data
end
data(1,:) = []; % Delete header information
[data(:,2),ii] = sort(data(:,2)); % Sort data according to start trip time
data(:,1) = data(ii,1);
data(:,3:end) = data(ii,3:end);

% Import maximum capacity information for each station
disp('Select maximum station capacity data file');
[filename2,pathname2] = uigetfile('*.csv','Select maximum station capacity data file'); % Specify file to import
if filename2 == 0
    error('No csv file selected');
end
disp(['Importing "' pathname2 filename2 '"']);
fid2 = fopen([pathname2 filename2],'r');
y = textscan(fid2,'%s%s%s','delimiter',',');
fclose(fid2);
for i = 1:3
    list(:,i) = y{1,i};
end
list(1,:) = []; % Delete header information

% Get initial state of Citibike system at end of first data file
[network_data,bike_ids,counter] = initializer(data,{},length(data(:,1))+1,{'ID' 'Label' 'Latitude' 'Longitude'},1,{'Bike IDs'},0);
clear data x k ii

% Import bike trip data file for simulation
disp('Select bike trip data file to use for simulation');
[filename3,pathname3] = uigetfile('*.csv','Select bike trip data file to use for simulation'); % Specify file to import
if filename3 == 0
    error('No csv file selected');
end
data = {};
disp(['Importing "' pathname3 filename3 '"']);
fid3 = fopen([pathname3 filename3],'r');
x = textscan(fid3,'%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q','delimiter',',');
fclose(fid3);
for k = 1:15
    data(:,k) = x{1,k};  % Append file data
end
data(1,:) = []; % Delete header information
[data(:,2),ii] = sort(data(:,2)); % Sort data according to start trip time
data(:,1) = data(ii,1);
data(:,3:end) = data(ii,3:end);

% Select start and end dates and times to run simulation
disp('Select start date');
h = uicontrol();
set(gcf,'Visible','Off');
uicalendar('DestinationUI',{h,'String'},'OutputDateFormat','yyyy-mm-dd');
waitfor(h,'String');
start_date = get(h,'String');
close all
disp('Select end date');
h2 = uicontrol();
set(gcf,'Visible','Off');
uicalendar('DestinationUI',{h2,'String'},'OutputDateFormat','yyyy-mm-dd');
waitfor(h2,'String');
end_date = get(h2,'String');
close all
txt1 = uicontrol('Style','text','Position',[25 390 225 25],'String',['Enter Start Time for ' start_date ' (hh:mm:ss)']);
text1 = uicontrol('Style','edit','Position',[25 370 225 25]);
txt2 = uicontrol('Style','text','Position',[25 340 225 25],'String',['Enter End Time for ' end_date ' (hh:mm:ss)']);
text2 = uicontrol('Style','edit','Position',[25 320 225 25]);
ok = uicontrol('Style','pushbutton','Position',[25 290 225 25],'String','OK','Callback','uiresume(gcbf)');
uiwait(gcf);
start_time = get(text1,'String');
end_time = get(text2,'String');
close all
pause(0.1);

% Find indices for subset of data to use in simulation
disp('Preparing initialization and simulation');
start_time_num = str2double(start_time([1 2 4 5 7 8]));
end_time_num = str2double(end_time([1 2 4 5 7 8]));
start_times = char(data(:,2));
[~,index] = ismember(' ',start_times(1,:));
% start_data_num = str2num(start_times(:,index+[1 2 4 5 7 8]));
start_data_num = [];
for kk = 1:length(start_times(:,1))
    start_data_num(kk,1) = str2double(start_times(kk,index+[1 2 4 5 7 8]));
end
start_cell = mat2cell(start_times,ones(1,length(start_times(:,1))),[index-1 length(start_times(1,:))-index+1]);
if strcmp(data{1,2}(5),'-') == 0
    start_date = [start_date(6:7) '/' start_date(9:10) '/' start_date(1:4)];
    start_date(start_date(1,1:5) == '0') = [];
    end_date = [end_date(6:7) '/' end_date(9:10) '/' end_date(1:4)];
    end_date(end_date(1,1:5) == '0') = [];
end
disp(['Start date and time: ' start_date ' ' start_time]);
disp(['End date and time: ' end_date ' ' end_time]);
[~,sidx] = ismember(start_date,start_cell(:,1));
[~,eidx] = ismember(end_date,flip(start_cell(:,1)));
idx1 = sidx;
while start_time_num > start_data_num(idx1,1)
    idx1 = idx1 + 1;
end
idx2 = length(start_data_num(:,1)) + 1 - eidx;
while end_time_num < start_data_num(idx2,1)
    idx2 = idx2 - 1;
end

% Get initial state of Citibike system up until start of simulation
[new_network_data,~,~] = initializer(data,list,idx1,network_data,2,bike_ids,counter);

% Simulate Citibike system for a specified time period
simulator(data,new_network_data,idx1,idx2);