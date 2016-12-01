function return_string = conv_datetime(date_time)
% Return a string that can be transformed into a number from the date and time input string given
% Example: '9/23/2016 08:31:42' => '20160923083142'
datime = strsplit(date_time);
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
return_string = [date time];
end