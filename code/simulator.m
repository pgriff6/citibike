function simulator(data,network_data,idx1,idx2,queue,incentives)

% Constant definitions and directory creation for visualization files
B = 1000; % budget during time interval t
t = 10; % time interval, in minutes
w1 = 1; % weight 1 in objective function
w2 = 1; % weight 2 in objective function
w3 = 1; % weight 3 in objective function
if incentives == 1
    if exist('incentives','dir') == 0
        mkdir('incentives');
    else
        rmdir('incentives','s');
    end
else
    if exist('no_incentives','dir') == 0
        mkdir('no_incentives');
    else
        rmdir('no_incentives','s');
    end
end

% Use data from csv files to step through each bike trip, simulating users in the Citibike system
% h = waitbar(0,'Simulating: 0%');
% waittotal = idx2 - idx1 + 1;
overall_PSQ = 0;
for k = idx1:idx2
    % Determine current time for present docking of bikes from queue
    datetime2 = conv_datetime(data{k,2});
    % Dock bikes finishing their trips at this time at correct stations
    while (isempty(queue) == 0) && (str2double(queue{1,1}) <= str2double(datetime2))
        network_data{queue{1,2},6} = network_data{queue{1,2},6} + 1; % Increment current # bikes by 1
        if network_data{queue{1,2},6} > network_data{queue{1,2},5}
            error('Bike station has overflowed capacity');
        end
        queue(1,:) = []; % Delete entry in queue
    end
    % Compute N, the number of users in the system during time interval t
    if incentives == 1
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
    end
    % Consider nearby stations within radius number of miles based on age Au
    if incentives == 1
        Au = str2double(datetime2(1:4)) - str2double(data{k,14});
        if Au <= 18
            radius = 1;
        elseif Au >= 60
            radius = 0.1;
        else
            radius = 2.683*exp(-0.055*Au);
        end
    else
        radius = 1;
    end
    % User's 1st choice of stations
    start_station = data{k,4};
    end_station = data{k,8};
    [~,idxs] = ismember(start_station,network_data(:,1));
    [~,idxe] = ismember(end_station,network_data(:,1));
    % Determine start and end stations nearby user's 1st choice
    if incentives == 1
        [start_list,end_list] = nearby_stations(network_data,idxs,idxe,radius);
    else
        start_list = [];
        end_list = [];
    end
    % Determine capacity and current number of bikes for start stations
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
    % Determine capacity and current number of bikes for end stations
    if isempty(end_list) == 0
        for i = 1:length(end_list(:,1))
            [~,idxe(end+1,1)] = ismember(num2str(end_list(i,1)),network_data(:,1));
        end
    end
    Cd = [];
    Vd = [];
    for m = 1:length(idxe(:,1))
        Cd(end+1,1) = network_data{idxe(m,1),5}; % Drop-off station's capacity
        Vd(end+1,1) = network_data{idxe(m,1),6}; % Drop-off station's current number of bikes
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
%         % Determine bikes not yet traveling that will arrive at station before endtime
%         for w = k:length(data(:,1))
%             datetime3 = conv_datetime(data{w,2});
%             if str2double(datetime3) > str2double(datetime1)
%                 break
%             end
%             if strcmp(data{w,8},network_data{idxe(v,1),1})
%                 datetime4 = conv_datetime(data{w,3});
%                 if str2double(datetime4) <= str2double(datetime1)
%                     Vd(v,1) = Vd(v,1) + 1;
%                 end
%             end
%         end
    end
    % Calculate total distance and congestion for each pair of alternative stations
    idxcombo = [];
    if incentives == 1
        for id1 = 1:length(idxs(:,1))
            dp = lldistkm([str2double(network_data{idxs(1,1),3}) str2double(network_data{idxs(1,1),4})],[str2double(network_data{idxs(id1,1),3}) str2double(network_data{idxs(id1,1),4})]);
            dp = distdim(dp,'km','miles'); % dp is pick-up station distance
            for id2 = 1:length(idxe(:,1))
                dd = lldistkm([str2double(network_data{idxe(1,1),3}) str2double(network_data{idxe(1,1),4})],[str2double(network_data{idxe(id2,1),3}) str2double(network_data{idxe(id2,1),4})]);
                dd = distdim(dd,'km','miles'); % dd is drop-off station distance
                du = dp + dd; % du is total distance
                % Make sure total distance du is less than radius
                if du <= radius
                    Gp = (Cp(id1,1)-Vp(id1,1))/Cp(id1,1); % Gp = (Cp-Vp)/Cp is pick-up station congestion level
                    Gd = Vd(id2,1)/Cd(id2,1); % Gd = Vd/Cd is drop-off station congestion level
                    idxcombo(end+1,:) = [idxs(id1,1) idxe(id2,1) Gp Gd du];
                end
            end
        end
    else
        Gp = (Cp-Vp)/Cp; % Gp = (Cp-Vp)/Cp is pick-up station congestion level
        Gd = Vd/Cd; % Gd = Vd/Cd is drop-off station congestion level
    end
    % Determine pair of stations with minimum amount of congestion
    if incentives == 1
        [~,new_idx] = min(idxcombo(:,3)+idxcombo(:,4));
        new_idxs = idxcombo(new_idx,1);
        new_idxe = idxcombo(new_idx,2);
        Gp = idxcombo(new_idx,3);
        Gd = idxcombo(new_idx,4);
        du = idxcombo(new_idx,5);
    end
    % If the best option is what the user intended to do, don't offer a payment; otherwise, run convex optimization to compute the payment
    if (idxs(1,1) == new_idxs) && (idxe(1,1) == new_idxe)
        PSQ = (w2*(Gp-1))+(w3*(Gd-1)); % Calculate poor service quality
    else
        [payment,PSQ] = solve_cvx(w1,w2,w3,B,N,Au,du,Gp,Gd); % Calculate payment using convex optimization
        % Probability model for whether or not person accepts payment option
        if rand > payment/(B/N) % If he/she does not accept the payment option
            if (Gp == 1) || (Gd == 1)
                % Person must take incentive if congestion at start or end station is maxed out
            else
                new_idxs = idxs(1,1);
                new_idxe = idxe(1,1);
            end
        end
    end
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
    clear start_list end_list idxs idxe Cp Vp Cd Vd idxcombo
    % Network visualization
    overall_PSQ = overall_PSQ + PSQ;
    if (mod(k-idx1+1,50) == 0) || (k == idx1)
        scatter(str2num(char(network_data(:,4))),str2num(char(network_data(:,3))),10+(2*cell2mat(network_data(:,6))),'filled','k');
%         scatter(str2num(char(network_data([1:end-11 end-9:end],4))),str2num(char(network_data([1:end-11 end-9:end],3))),10+(2*cell2mat(network_data([1:end-11 end-9:end],6))),'filled','k');
        xlabel('Longitude');
        ylabel('Latitude');
        title(data{k,2});
        text(-73.95,40.795,'Average Du:','FontSize',16);
        text(-73.95,40.785,num2str(overall_PSQ/(k-idx1+1)),'FontSize',16);
        if incentives == 1
            print(['incentives/' num2str(k-idx1+1)],'-dpng');
        else
            print(['no_incentives/' num2str(k-idx1+1)],'-dpng');
        end
        pause(0.01);
%         waitbar((k-idx1+1)/waittotal,h,['Simulating: ' num2str(((k-idx1+1)/waittotal)*100) '%']);
    end
end
% close(h);

end