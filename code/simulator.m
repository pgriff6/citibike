function simulator(data,network_data,idx1,idx2,queue)

B = 0; % budget during time interval t
t = 0; % time interval, in minutes

% Use data from csv files to step through each bike trip, simulating users in the Citibike system
% h = waitbar(0,'Simulating: 0%');
% waittotal = idx2 - idx1 + 1;
for k = idx1:idx2
    % Determine current time for present docking of bikes from queue
    datetime2 = conv_datetime(data{k,2});
    % Dock bikes finishing their trips at this time at correct stations
    while (isempty(queue) == 0) && (str2double(queue{1,1}) <= str2double(datetime2))
        network_data{queue{1,2},6} = network_data{queue{1,2},6} + 1; % Increment current # bikes by 1
        if network_data{queue{1,2},6} > network_data{queue{1,2},5}
            error('Bike station has overflowed capacity');
        end
    end
    % Compute N, the number of users in the system during time interval t
    start_min = str2double(datetime2(11:12))-t;
    start_hr = str2double(datetime2(9:10));
    start_day = str2double(datetime2(7:8));
    while start_min < 0
        start_hr = start_hr - 1;
        start_min = 60 - abs(start_min);
        while start_hr < 0
            start_day = start_day - 1;
            start_hr = 24 - abs(start_hr);
        end
    end
    interval_start = datetime2(1:6);
    if start_day < 10
        interval_start(end+1) = '0';
        interval_start(end+1) = num2str(start_day);
    else
        interval_start(end+1:end+2) = num2str(start_day);
    end
    if start_hr < 10
        interval_start(end+1) = '0';
        interval_start(end+1) = num2str(start_hr);
    else
        interval_start(end+1:end+2) = num2str(start_hr);
    end
    if start_min < 10
        interval_start(end+1) = '0';
        interval_start(end+1) = num2str(start_min);
    else
        interval_start(end+1:end+2) = num2str(start_min);
    end
    interval_start(end+1:end+2) = datetime2(13:14);
    N = 0;
    for u = k:-1:1
        if str2double(conv_datetime(data{u,2})) < str2double(interval_start)
            break
        end
        N = N + 1;
    end
    % Consider nearby stations within radius number of miles based on age Au
    Au = str2double(datetime2(1:4)) - str2double(data{k,14});
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
    % Figure out how each Vd will look in the future once the bike trip ends (predictive model)
    datetime1 = conv_datetime(data{k,3}); % Determine endtime
    for v = 1:length(Vd(:,1))
        % Determine bikes currently traveling that will arrive at station before endtime
        for z = 1:length(queue(:,1))
            if str2double(queue{z,1}) > str2double(datetime1)
                break
            end
            if queue{z,2} == idxe(v,1)
                Vd(v,1) = Vd(v,1) + 1;
            end
        end
        % Determine bikes not yet traveling that will arrive at station before endtime
        for w = k:length(data(:,1))
            datetime3 = conv_datetime(data{w,2});
            if str2double(datetime3) > str2double(datetime1)
                break
            end
            if strcmp(data{w,8},network_data{idxe(v,1),1})
                datetime4 = conv_datetime(data{w,3});
                if str2double(datetime4) <= str2double(datetime1)
                    Vd(v,1) = Vd(v,1) + 1;
                end
            end
        end
    end
    [Gd,new_inde] = min(Vd); % Gd = Vd is congestion level
    new_idxe = idxe(new_inde,1);
    % If the best option is what the user intended to do, do nothing; otherwise, run convex optimization to compute the payment
    if (new_inds == 1) && (new_inde == 1)
        Du = 0;
    else
        dp = lldistkm([str2double(network_data{idxs(1,1),3}) str2double(network_data{idxs(1,1),4})],[str2double(network_data{new_idxs,3}) str2double(network_data{new_idxs,4})]);
        dp = distdim(dp,'km','miles'); % dp is pickup station distance
        dd = lldistkm([str2double(network_data{idxe(1,1),3}) str2double(network_data{idxe(1,1),4})],[str2double(network_data{new_idxe,3}) str2double(network_data{new_idxe,4})]);
        dd = distdim(dd,'km','miles'); % dd is dropoff station distance
        du = dp + dd; % du is total distance
        [payment,Du] = solve_cvx(B,N,Au,du,Gp,network_data{new_idxs,5},Gd,network_data{new_idxe,5}); % Calculate payment using convex optimization
        % Probability model for whether or not person accepts payment option
        if rand > payment/(B/N) % If he/she does not accept the payment option
            new_idxs = idxs(1,1);
            new_idxe = idxe(1,1);
        end
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
    % Update the state of the Citibike system accordingly
    network_data{new_idxs,6} = network_data{new_idxs,6} - 1; % Decrement current # bikes by 1
    if network_data{new_idxs,6} < 0
        error('Bike station has a negative number of bikes');
    end
    % Add endtime to queue for future docking of bike
    queue{end+1,1} = datetime1;
    queue{end,2} = new_idxe;
    [~,ii] = sort(queue(:,1)); % Sort queue according to endtime
    queue(:,:) = queue(ii,:);
    clear start_list end_list idxs idxe Cp Vp Vd%start_prob end_prob
    % Network visualization
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