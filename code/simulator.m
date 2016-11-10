function simulator(data,network_data,idx1,idx2)

% Use data from csv files to step through each bike trip, simulating users in the Citibike system
radius = 1; % Consider nearby stations within this number of miles
% h = waitbar(0,'Simulating: 0%');
% waittotal = idx2 - idx1 + 1;
for k = idx1:idx2
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
    A = [];
    for n = 1:length(idxs(:,1))
        A(end+1,1) = network_data{idxs(n,1),6};
    end
    [~,new_inds] = max(A);
    new_idxs = idxs(new_inds,1);
    if isempty(end_list) == 0
        for i = 1:length(end_list(:,1))
            [~,idxe(end+1,1)] = ismember(num2str(end_list(i,1)),network_data(:,1));
        end
    end
    B = [];
    for m = 1:length(idxe(:,1))
        B(end+1,1) = network_data{idxe(m,1),6};
    end
    [~,new_inde] = min(B);
    new_idxe = idxe(new_inde,1);
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
%     if network_data{idxs,6} ~= 0
    network_data{new_idxs,6} = network_data{new_idxs,6} - 1; % Decrement current # bikes by 1
%     end
    network_data{new_idxe,6} = network_data{new_idxe,6} + 1; % Increment current # bikes by 1
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