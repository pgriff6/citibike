% This function looks at the latitude and longitude information for a bike
% trip's start station and end station; based on a radius (in miles) deined
% by the user, it ouputs two sorted lists of alternative stations near the
% start and end stations

% Update: incorporated into the main simulation routine. No need to import
% .csv file including station list anymore

function [candidate_start_list,candidate_end_list] = nearby_stations(network_data,idxs,idxe,radius)
% convert char arrays to double
start_latitude = str2double(network_data{idxs,3});
start_longitude = str2double(network_data{idxs,4});
end_latitude = str2double(network_data{idxe,3});
end_longitude = str2double(network_data{idxe,4});

% fid = fopen('station_list.csv', 'r');
% stations = textscan(fid, '%s %s %s %s','Delimiter',',');
% fclose(fid);
% station_count = size(stations{1},1);

stations= network_data(:,1:4);
station_count = size(stations,1);

start_list = [];
end_list = [];
% network_data = {'ID' 'Label' 'Latitude' 'Longitude'};
for i = 1 : station_count
    % determine if current station is a candidate for the start station or end station
    station_lat = str2double(stations{i,3});
    station_long = str2double(stations{i,4});
    
    % start station
    %start_distance = sqrt((stations{3}{i}-start_latitude).^2 + (stations{4}{i}-start_longitude).^2);
    start_distance = lldistkm([station_lat station_long],...
                     [start_latitude start_longitude]);
    start_distance = distdim(start_distance,'km','miles');
    if start_distance <= radius && start_distance ~= 0
        start_list = [start_list; [str2num(stations{i,1}), start_distance]];
    end
    % end station
    %end_distance = sqrt((stations{3}{i}-end_latitude).^2 + (stations{4}{i}-end_longitude).^2);
    end_distance = lldistkm([station_lat station_long],...
                     [end_latitude, end_longitude]);
    end_distance = distdim(end_distance,'km','miles');
    if end_distance <= radius && end_distance ~= 0
        end_list = [end_list; [str2num(stations{i,1}), end_distance]];
    end
end

% check if candidate lists are empty and output them as strings
if isempty(start_list) == 0
    start_list = sortrows(start_list,2);
    candidate_start_list = start_list(:,1);
else
    candidate_start_list = [];
end

if isempty(end_list) == 0
    end_list = sortrows(end_list,2);
    candidate_end_list = end_list(:,1);
else
    candidate_end_list = [];
end





