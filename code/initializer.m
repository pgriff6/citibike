function [network_data,bike_ids,counter,waittotal,queue] = initializer(data,list,idx1,network_data,flag,bike_ids,counter,total,queue)

% Create list of station ids, names, and locations
if flag == 2
    init = length(network_data(:,1));
end
h2 = waitbar(0,'Creating station information: 0%');
waittotal2 = 2*length(data(:,4));
for n = 1:length(data(:,4))
    if ismember(data{n,4},network_data(:,1)) == 0
        network_data{end+1,1} = data{n,4};
        network_data{end,2} = data{n,5};
        network_data{end,3} = data{n,6};
        network_data{end,4} = data{n,7};
    end
    if mod(n,10000) == 0
        waitbar(n/waittotal2,h2,['Creating station information: ' num2str((n/waittotal2)*100) '%']);
    end
end
for m = 1:length(data(:,8))
    if ismember(data{m,8},network_data(:,1)) == 0
        network_data{end+1,1} = data{m,8};
        network_data{end,2} = data{m,9};
        network_data{end,3} = data{m,10};
        network_data{end,4} = data{m,11};
    end
    if mod((n+m),10000) == 0
        waitbar((n+m)/waittotal2,h2,['Creating station information: ' num2str(((n+m)/waittotal2)*100) '%']);
    end
end
close(h2);

% Add max # of bikes as column
disp('Adding maximum capacity information');
max_default = 0; % Max # of bikes to assign to stations that we don't know max # of bikes for
if flag == 1
    network_data{1,5} = 'Maximum # Bikes';
elseif flag == 2
    [~,Locb] = ismember(network_data(:,2),list(:,2));
    capacity = str2num(char(list(Locb(:,1),3)));
    station_count = length(find(capacity == -1)) + length(find(capacity == -2));
    capacity(capacity == -1,1) = max_default;
    capacity(capacity == -2,1) = max_default;
    network_data(:,5) = mat2cell(capacity,ones(1,length(capacity)));
    disp(['Assigned ' num2str(max_default) ' as default maximum capacity for ' num2str(station_count) ' of ' num2str(length(network_data(:,1))-1) ' stations']);
end

% Initialize columns for the number of bikes
if flag == 1
    network_data(:,6) = {0};
    network_data{1,6} = 'Current # Bikes';
    network_data(:,7) = {{}};
    network_data{1,7} = 'Bike ID List';
elseif flag == 2
    network_data(init+1:end,6) = {0};
    network_data(init+1:end,7) = {{}};
end

% Step through Citibike data, updating bike information for each station
h = waitbar(0,'Initializing: 0%');
waittotal = idx1 - 1;
for entry = 1:(idx1-1)
    % Determine current time for present docking of bikes from queue
    datime2 = strsplit(data{entry,2});
    time2 = datime2{1,2};
    time2 = time2([1 2 4 5 7 8]);
    date2 = datime2{1,1};
    if ismember('/',date2)
        tempdate2 = date2(end-3:end);
        if strcmp(date2(2),'/')
            tempdate2(end+1) = '0';
            tempdate2(end+1) = date2(1);
            if strcmp(date2(4),'/')
                tempdate2(end+1) = '0';
                tempdate2(end+1) = date2(3);
            elseif strcmp(date2(5),'/')
                tempdate2(end+1) = date2(3);
                tempdate2(end+1) = date2(4);
            else
                error('Code should not reach this point');
            end
        elseif strcmp(date2(3),'/')
            tempdate2(end+1) = date2(1);
            tempdate2(end+1) = date2(2);
            if strcmp(date2(5),'/')
                tempdate2(end+1) = '0';
                tempdate2(end+1) = date2(4);
            elseif strcmp(date2(6),'/')
                tempdate2(end+1) = date2(4);
                tempdate2(end+1) = date2(5);
            else
                error('Code should not reach this point');
            end
        else
            error('Code should not reach this point');
        end
        date2 = tempdate2;
    else
        date2 = date2([1 2 3 4 6 7 9 10]);
    end
    % Dock bikes finishing their trips at this time at correct stations
    while (isempty(queue) == 0) && (str2double(queue{1,1}) <= str2double([date2 time2]))
        network_data{queue{1,2},7}{end+1,1} = queue{1,3}; % Add bike ID to station list
        network_data{queue{1,2},6} = network_data{queue{1,2},6} + 1; % Increment current # of bikes by 1
        if network_data{queue{1,2},6} > network_data{queue{1,2},5}
            network_data{queue{1,2},5} = network_data{queue{1,2},6}; % Dynamically increase max capacity of station
        end
        queue(1,:) = []; % Delete entry in queue
    end
    [~,Locb2] = ismember(data{entry,4},network_data(:,1)); % Find index for start station ID
    if Locb2 == 0
        error('Start station ID not found');
    else
        [Lia,Locb3] = ismember(data{entry,12},network_data{Locb2,7}); % Check to see if bike ID is in station list
        if Lia == 1
            network_data{Locb2,7}(Locb3,:) = []; % Delete bike ID from station list
            network_data{Locb2,6} = network_data{Locb2,6} - 1; % Decrement current # of bikes by 1
            if network_data{Locb2,6} < 0
                error('Bike station has a negative number of bikes');
            end
        else
            if ismember(data{entry,12},bike_ids(:,1)) ~= 1
                bike_ids{end+1,1} = data{entry,12}; % Add bike ID to overall bike ID list
            else
                % Find which station the bike is actually at
                for station = 1:length(network_data(:,1))
                    [Lia2,Locb5] = ismember(data{entry,12},network_data{station,7});
                    if Lia2 == 1
                        break
                    end
                end
                if Lia2 == 1
                    network_data{station,7}(Locb5,:) = []; % Delete bike ID from station list
                    network_data{station,6} = network_data{station,6} - 1; % Decrement current # of bikes by 1
                    if network_data{station,6} < 0
                        error('Bike station has a negative number of bikes');
                    end
                elseif ismember(data{entry,12},queue(:,3)) % If bike is not at a station and is in queue
                    [~,idx] = ismember(data{entry,12},queue(:,3));
                    queue(idx,:) = []; % Delete bike from queue
                else
                    error('Could not find which station bike is actually at');
                end
                counter = counter + 1;
            end
        end
    end
    [~,Locb4] = ismember(data{entry,8},network_data(:,1)); % Find index for end station ID
    if Locb4 == 0
        error('End station ID not found');
    end
    % Add endtime to queue for future docking of bike
    datime = strsplit(data{entry,3});
    time = datime{1,2};
    time = time([1 2 4 5 7 8]);
    date = datime{1,1};
    if ismember('/',date)
        tempdate = date(end-3:end);
        if strcmp(date(2),'/')
            tempdate(end+1) = '0';
            tempdate(end+1) = date(1);
            if strcmp(date(4),'/')
                tempdate(end+1) = '0';
                tempdate(end+1) = date(3);
            elseif strcmp(date(5),'/')
                tempdate(end+1) = date(3);
                tempdate(end+1) = date(4);
            else
                error('Code should not reach this point');
            end
        elseif strcmp(date(3),'/')
            tempdate(end+1) = date(1);
            tempdate(end+1) = date(2);
            if strcmp(date(5),'/')
                tempdate(end+1) = '0';
                tempdate(end+1) = date(4);
            elseif strcmp(date(6),'/')
                tempdate(end+1) = date(4);
                tempdate(end+1) = date(5);
            else
                error('Code should not reach this point');
            end
        else
            error('Code should not reach this point');
        end
        date = tempdate;
    else
        date = date([1 2 3 4 6 7 9 10]);
    end
    queue{end+1,1} = [date time];
    queue{end,2} = Locb4;
    queue{end,3} = data{entry,12};
    [~,ii] = sort(queue(:,1)); % Sort queue according to endtime
    queue(:,:) = queue(ii,:);
    if mod(entry,5000) == 0
        waitbar(entry/waittotal,h,['Initializing: ' num2str((entry/waittotal)*100) '%']);
    end
end
close(h);
if flag == 1
    bike_ids(1,:) = []; % Delete header information
    network_data(1,:) = []; % Delete header information
elseif flag == 2
    disp([num2str((counter/(total+waittotal))*100) '% of data entries had bikes which departed from unexpected stations']);
end

end