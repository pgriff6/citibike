function simulator(data,network_data,idx1,idx2)

% Use data from csv files to step through each bike trip, simulating users in the Citibike system
radius = 1; % Consider nearby stations within this number of miles
h = waitbar(0,'Simulating: 0%');
waittotal = idx2 - idx1 + 1;
for k = idx1:idx2
    start_station = data{k,4};
    end_station = data{k,8};
    [~,idxs] = ismember(start_station,network_data(:,1));
    [~,idxe] = ismember(end_station,network_data(:,1));
    % Determine start and end stations nearby user's 1st choice
    [start_list,end_list] = nearby_stations(network_data,idxs,idxe,radius);
    % Temporary incentives using probability - original stations are given
    % probability 0.5 and other stations' probabilities add up to 0.5
    start_prob = 0.5;
    start_prob(2:length(start_list)+1,1) = cumsum(sort(diff([0;sort(rand(length(start_list)-1,1));1])/2,'descend'))+0.5;
    end_prob = 0.5;
    end_prob(2:length(end_list)+1,1) = cumsum(sort(diff([0;sort(rand(length(end_list)-1,1));1])/2,'descend'))+0.5;
    probs = rand();
    for n = length(start_prob):-1:1
        if start_prob(n,1) <= probs
            break
        end
    end
    probe = rand();
    for m = length(end_prob):-1:1
        if end_prob(m,1) <= probe
            break
        end
    end
    if n ~= 1
        start_station = num2str(start_list(n-1,1));
        [~,idxs] = ismember(start_station,network_data(:,1));
    end
    if m ~= 1
        end_station = num2str(end_list(m-1,1));
        [~,idxe] = ismember(end_station,network_data(:,1));
    end
    % Update the state of the Citibike system accordingly
    network_data{idxs,6} = network_data{idxs,6} - 1; % Decrement current # bikes by 1
    network_data{idxe,6} = network_data{idxe,6} + 1; % Increment current # bikes by 1
    scatter(str2num(char(network_data(:,3))),str2num(char(network_data(:,4))),10+(2*str2num(char(network_data(:,6)))),'filled');
    clear start_list end_list start_prob end_prob
    if mod(k-idx1+1,50) == 0
        waitbar((k-idx1+1)/waittotal,h,['Simulating: ' num2str(((k-idx1+1)/waittotal)*100) '%']);
    end
end
close(h);

end