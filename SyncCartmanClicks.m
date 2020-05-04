function [AllLogsTimeAndPresses,Clicks] = SyncCartmanClicks(NevFile,LogFolder,LogNames,LogsDelay,SubjectTable)
%%
% This function will synchronize the KeyPress times from cartman game logs
% with their sessions respective .nev file, its output will be an addition
% of a "Clicks" column to the standard data table ("g")
% Inputs:
%   NevFile      : Path at which the relevant .NEV file may be found, required
%                  for finding start and end events as they are absent in some
%                  data tables (events 12 and 13 respectively)
%   LogFolder    : The folder at which the log files may be found
%   LogDelay     : vector of time in milliseconds of the delay betweem log and NEV (time in nev of the start of the log file).
%                  if you want the algorithm to compute the delay enter 0 
%   LogNames     : Names of the log files in the folder
%   SubjectTable : Path to the data table, this file will be overwritten
%                  with the new table containing the "Clicks" column
% 
% Outputs:
%   AllLogsTimeAndPress : A 2 Column Vector - Times,Clicks_Boolean
%   Clicks              : A Column vector containing the indexes in the
%                         table at which clicks occurred
%   In Addition, a new table will be written over the old one, with the
%   addition of the "Clicks" variable
%%
%% Parameter definition
if nargin == 0
    NevFile = '...\NEV.mat';
    LogFolder = '...\logs';
    LogNames = {'Log1Name'};
    LogsDelay = [[0 0 0 0]];
    SubjectTable = '...\*.mat';
end
if ~exist('NEV','var');
    load(NevFile);
end

StartTimes = NEV.Data.SerialDigitalIO.TimeStampSec((NEV.Data.SerialDigitalIO.UnparsedData == 12));
EndTimes = NEV.Data.SerialDigitalIO.TimeStampSec((NEV.Data.SerialDigitalIO.UnparsedData == 13));
% having this if loop means you can't count on the specifity of start/end
% events
if numel(StartTimes) < numel(EndTimes)
    StartTimes = [0,StartTimes];
elseif numel(StartTimes) > numel(EndTimes)
    EndTimes = [EndTimes,NEV.MetaTags.DataDurationSec];
end
    fprintf('start times are \n');
    fprintf([num2str(StartTimes) '\n'])
    SE_correct=input('is this correct (0 or 1)?');
    if ~SE_correct
        StartTimes=input('please correct start\n');
    end;
    fprintf('end times are \n');
    fprintf([num2str(EndTimes) '\n'])
    SE_correct=input('is this correct (0 or 1)?');
    if ~SE_correct
        EndTimes=input('please correct end\n');
    end;

    
        

%% Matching logs
N = 0;
AllLogsTimeAndPresses = [];
for LogFile = LogNames
        N = N + 1;
    
        %% Isolate nev data relevant for this log only
        LogNevTimes = NEV.Data.SerialDigitalIO.TimeStampSec(... %Multiplied by 1000 to transfer from s to ms
            NEV.Data.SerialDigitalIO.TimeStampSec>StartTimes(N) & NEV.Data.SerialDigitalIO.TimeStampSec<EndTimes(N)).*1000;
        LogNevEvents = NEV.Data.SerialDigitalIO.UnparsedData(...
            NEV.Data.SerialDigitalIO.TimeStampSec>StartTimes(N) & NEV.Data.SerialDigitalIO.TimeStampSec<EndTimes(N));
        %% Read Log File
        fprintf('Now Reading %s.csv\n',LogFile{1});
        FilePath = fullfile(LogFolder,[LogFile{1},'.csv']);
        [~,Headers,All] = xlsread(FilePath);
        EventHeaderInds = strncmp('Trigger',Headers,numel('Trigger'));
        EventHeaders = Headers(EventHeaderInds);
        LogTimes = cell2mat(All(2:end,strcmp('timerMilli',Headers)));
        LogPressed = cell2mat(All(2:end,strcmp('keyPressed',Headers)));
        LogEvents = cell2mat(All(2:end,EventHeaderInds));
        %     HeaderInds = [find(strcmp('timerMilli',Headers)),find(strcmp('keyPressed',Headers)),find(EventHeaderInds)];
        %     Headers = Headers(HeaderInds);
        %     LogData = All(2:end,HeaderInds);
        if LogsDelay(N)>0 % in the case you want to manually state the difference
            MeanTimeDiff=LogsDelay(N);
        else
            %% find and match first & last event of 8 types
            LogEventDiffs = logical(diff(LogEvents));  % this line and the next turn the original count into a logical value for each occurence
            LogEventDiffs = [zeros(1,size(LogEventDiffs,2));LogEventDiffs]; %#ok<AGROW>
            NevInds = zeros(8,2);
            LogInds = zeros(8,2);
            for Event = 1:8
                NevInds(Event,1) = find(LogNevEvents == Event,1,'first');
                NevInds(Event,2) = find(LogNevEvents == Event,1,'last');
                LogInds(Event,1) = find(LogEventDiffs(:,Event),1,'first');
                LogInds(Event,2) = find(LogEventDiffs(:,Event),1,'last');
            end
            EventNevTimes = LogNevTimes(NevInds); EventLogTimes = LogTimes(LogInds);
            TimeVar = var([EventNevTimes - EventLogTimes]/1000);
            LowestVar = find(TimeVar == min(TimeVar));
            MeanTimeDiff = mean(EventNevTimes(:,LowestVar)-EventLogTimes(:,LowestVar));
        end;
    
    fprintf('Time differences for this log is %.4f Seconds\n',MeanTimeDiff/1000);
    % This variable represents the time at which the respective event in
    % the log file, occured in the .nev file (times are synced with .nev)
    AllLogsTimeAndPresses = [AllLogsTimeAndPresses;[LogTimes+MeanTimeDiff,LogPressed]]; %#ok<AGROW>
    %     [EventNevTimes - EventLogTimes]./1000
    %     var([EventNevTimes - EventLogTimes]/1000)
end


%% Organize and place in table
AllLogsTimeAndPresses(AllLogsTimeAndPresses(:,1)<0,:) = [];
load(SubjectTable) % loads as the variable 'g'

% this is some algorithm found online for matching closest items in an
% array
a = AllLogsTimeAndPresses(logical(AllLogsTimeAndPresses(:,2)),1)'/1000; b = [g.data.Time]';
m = size(a,2); n = size(b,2);
[c,p] = sort([a,b]);
q = 1:m+n; q(p) = q;
t = cumsum(p>m);
r = 1:n; r(t(q(m+1:m+n))) = r;
s = t(q(1:m));
id = r(max(s,1));
iu = r(min(s+1,n));
[d,it] = min([abs(a-b(id));abs(b(iu)-a)]);
ib = id+(it-1).*(iu-id); % This variable (ib) is the index of the elements in the tables timeseries closest to those in the synced array

Clicks = false(size(g.data,1),1);
Clicks(ib) = true;
g.data = [g.data(:,1),table(Clicks),g.data(:,2:end)];

%% Save file
save(SubjectTable,'g','-v7.3')