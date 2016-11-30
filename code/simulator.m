function simulator(data,network_data,idx1,idx2,queue)

% Use data from csv files to step through each bike trip, simulating users in the Citibike system
% h = waitbar(0,'Simulating: 0%');
% waittotal = idx2 - idx1 + 1;
for k = idx1:idx2
    % Consider nearby stations within radius number of miles based on age Au
    Au = str2double(data{k,14});
    if Au <= 18
        radius = 1;
    elseif Au >= 60
        radius = 0.1;
    else
        radius = 2.683*exp(-0.055*Au);
    end
    start_station = data{k,4};
    end_station = data{k,8};
    [~,idxs] = ismember(start_station,network_data(:,1));
    [~,idxe] = ismember(end_station,network_data(:,1));
    % Determine start and end stations nearby user's 1st choice
    [start_list,end_list] = nearby_stations(network_data,idxs,idxe,radius);
    if isempty(start_list) == 0
        for j = 1:length(start_list(:,1))
            [~,idxs(end+1,1)] = ismember(num2str(start_list(j,1)),network_data(:,1));
        end
    end
    Cp = [];
    Vp = [];
    for n = 1:length(idxs(:,1))
        Cp(end+1,1) = network_data{idxs(n,1),5}; % Pick-up station's capacity
        Vp(end+1,1) = network_data{idxs(n,1),6}; % Pick-up station's current number of bikes
    end
    [Gp,new_inds] = min(Cp-Vp); % Gp = Cp-Vp is congestion level
    new_idxs = idxs(new_inds,1);
    if isempty(end_list) == 0
        for i = 1:length(end_list(:,1))
            [~,idxe(end+1,1)] = ismember(num2str(end_list(i,1)),network_data(:,1));
        end
    end
    Vd = [];
    for m = 1:length(idxe(:,1))
        Vd(end+1,1) = network_data{idxe(m,1),6};
    end
    [Gd,new_inde] = min(Vd); % NEED TO ADD SYSTEM KNOWLEDGE OF WHO WILL BE THERE
    new_idxe = idxe(new_inde,1);
    if (new_inds == 1) && (new_inde == 1)
        payment = 0;
    else
        dp = lldistkm([str2double(network_data{idxs(1,1),3}) str2double(network_data{idxs(1,1),4})],[str2double(network_data{new_idxs,3}) str2double(network_data{new_idxs,4})]);
        dp = distdim(dp,'km','miles'); % dp is pickup station distance
        dd = lldistkm([str2double(network_data{idxe(1,1),3}) str2double(network_data{idxe(1,1),4})],[str2double(network_data{new_idxe,3}) str2double(network_data{new_idxe,4})]);
        dd = distdim(dd,'km','miles'); % dd is dropoff station distance
        du = dp + dd; % du is total distance
        payment = ; % FIGURE OUT PAYMENT FROM OPTIMIZATION SOLVER
    end
    % Probability model for whether or not person accepts payment option - FINISH THIS
    if % If he/she does not accept the payment option - FINISH THIS
        new_idxs = idxs(1,1);
        new_idxe = idxe(1,1);
    end
%     % Temporary incentives using probability - original stations are given
%     % probability 0.5 and other stations' probabilities add up to 0.5
%     start_prob = 0; %0.5
%     start_prob(2:length(start_list)+1,1) = cumsum(sort(diff([0;sort(rand(length(start_list)-1,1));1]),'descend')); %/2 before descend,+0.5 before ;
%     end_prob = 0; %0.5
%     end_prob(2:length(end_list)+1,1) = cumsum(sort(diff([0;sort(rand(length(end_list)-1,1));1]),'descend')); %/2 before descend,+0.5 before ;
%     probs = rand();
%     for n = length(start_prob):-1:1
%         if start_prob(n,1) <= probs
%             break
%         end
%     end
%     if n ~= 1
%         start_station = num2str(start_list(n-1,1));
%         [~,idxs] = ismember(start_station,network_data(:,1));
%     end
%     probe = rand();
%     for m = length(end_prob):-1:1
%         if end_prob(m,1) <= probe
%             break
%         end
%     end
%     if m ~= 1
%         end_station = num2str(end_list(m-1,1));
%         [~,idxe] = ismember(end_station,network_data(:,1));
%     end
    % ***********************************************************************************************************
    % Update the state of the Citibike system accordingly
    network_data{new_idxs,6} = network_data{new_idxs,6} - 1; % Decrement current # bikes by 1
    if network_data{new_idxs,6} < 0
        error('Bike station has a negative number of bikes');
    end
    % Add endtime to queue for future docking of bike
    datime = strsplit(data{k,3});
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
    queue{end,2} = new_idxe;
    [~,ii] = sort(queue(:,1)); % Sort queue according to endtime
    queue(:,:) = queue(ii,:);
    % Determine current time for present docking of bikes from queue
    datime2 = strsplit(data{k,2});
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
        network_data{queue{1,2},6} = network_data{queue{1,2},6} + 1; % Increment current # bikes by 1
        if network_data{queue{1,2},6} > network_data{queue{1,2},5}
            error('Bike station has overflowed capacity');
        end
    end
    % ***********************************************************************************************************
    clear start_list end_list idxs idxe A B%start_prob end_prob
    if (mod(k-idx1+1,50) == 0) || (k == idx1)
        scatter(str2num(char(network_data(:,4))),str2num(char(network_data(:,3))),10+(2*cell2mat(network_data(:,6))),'filled','k');
%         scatter(str2num(char(network_data([1:end-11 end-9:end],4))),str2num(char(network_data([1:end-11 end-9:end],3))),10+(2*cell2mat(network_data([1:end-11 end-9:end],6))),'filled','k');
        xlabel('Longitude');
        ylabel('Latitude');
        title(data{k,2});
        print(num2str(k-idx1+1),'-dpng');
        pause(0.01);
%         waitbar((k-idx1+1)/waittotal,h,['Simulating: ' num2str(((k-idx1+1)/waittotal)*100) '%']);
    end
end
% close(h);

end