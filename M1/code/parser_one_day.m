close all
clear
clc

all_files = 0; % 0: import selected files, 1: import all files in current directory
date = '9/14/2016';

% Create list of files to import data from
if all_files == 0
    answer = 'Yes';
    file_list = {};
    while(strcmp(answer,'Yes') == 1)
        filename = uigetfile('*.csv','Select csv file to import'); % Specify files to import
        if filename == 0
            error('No csv file selected');
        end
        file_list(end+1) = {filename};
        answer = questdlg('Would you like to import another csv file?');
    end
else
    files = ls('*.csv');
    file_list = strsplit(files,{'\t','\n'}); % Import all csv files in the current directory
    file_list = sort(file_list);
end

% Import data and create reformatted csv files
data = {};
if all_files == 1
    % Import data from list of csv files
    for j = 1:length(file_list)
        if strcmp(file_list{j},'') == 0
            disp(['Importing ' file_list{j}]);
            fid = fopen(file_list{j},'r');
            x = textscan(fid,'%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q','delimiter',',');
            fclose(fid);
            for k = 1:15
                data(:,k) = x{1,k};  % Create cell array of file data
            end
            data(1,:) = []; % Delete header information
            % Write all data from all files to one csv file
            fid2 = fopen('data.csv','a');
            for rw = 1:length(data(:,1))
                fprintf(fid2,'%s,',data{rw,:}); % Append data to csv file
                fprintf(fid2,'\n');
            end
            fclose(fid2);
            clear x data
            data = {};
        end
    end
else
    % Import data from list of csv files
    for j = 1:length(file_list)
        if strcmp(file_list{j},'') == 0
            disp(['Importing ' file_list{j}]);
            fid = fopen(file_list{j},'r');
            x = textscan(fid,'%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q','delimiter',',');
            fclose(fid);
            row = length(data);
            for k = 1:15
                data(row+1:row+length(x{1,k}),k) = x{1,k};  % Append file data
            end
            data(row+1,:) = []; % Delete header information
            clear x
        end
    end
    % Write data from selected columns to csv file for Gephi import
    datename = strrep(date, '/', '-')
    filename = strcat(datename, '.csv')
    fid2 = fopen(filename,'w');
    fprintf(fid2,'"Source","Target","Start Time","Stop Time","Number of Bikes at Source","Number of Bikes at Target"\n');
    for rww = 1:length(data(:,1))
        if strfind(data{rww,2}, date) == 1
            fprintf(fid2,'"%s","%s","%s","%s","1","1"\n', ...
                data{rww,4},data{rww,8},data{rww,2},data{rww,3});
        end
    end
    fclose(fid2);
    % Create list of station ids, names, and locations
    station_list = {'ID' 'Label' 'Latitude' 'Longitude'};
    for n = 1:length(data(:,4))
        if ismember(data{n,4},station_list(:,1)) == 0
            station_list{end+1,1} = data{n,4};
            station_list{end,2} = data{n,5};
            station_list{end,3} = data{n,6};
            station_list{end,4} = data{n,7};
        end
    end
    for m = 1:length(data(:,8))
        if ismember(data{m,8},station_list(:,1)) == 0
            station_list{end+1,1} = data{m,8};
            station_list{end,2} = data{m,9};
            station_list{end,3} = data{m,10};
            station_list{end,4} = data{m,11};
        end
    end
    % Write station list to csv file
    fid3 = fopen('station_list.csv','w');
    for t = 1:length(station_list(:,1))
        fprintf(fid3,'"%s","%s","%s","%s"\n',station_list{t,1},station_list{t,2},station_list{t,3},station_list{t,4});
    end
    fclose(fid3);
end
