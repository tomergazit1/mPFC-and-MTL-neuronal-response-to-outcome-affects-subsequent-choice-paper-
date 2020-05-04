function tier1AsTable(Dest,Orig,Params)
%% setting parameters
% this function craetes a table with all the data and triggers from the NSx
% file of blackrock
% separate to a cfg file and functions to make it generic
if nargin == 0
    Paradigm = 'Cartman';
	Subject = 'D001';
    NewFile='NewFileName.mat';
    NewDir='D:\NewDir';
    mkdir(NewDir);
    NSxFile='...ns5';
    NEVfile='.....NEV.mat';
    RemovedBadElectrodes = {'badChannel'}; % by visual inspection of DataCheckNSx. Can semi-automate
    %RemovedBadElectrodes = {};
    ElectrodePairsToRemove = []; % in indexes of pairs
	WhiteMatterElectrodes = {};
    FilterLineNoise = true;
    Resampling = false;
    NewSR = [3000]; %if resampling is done
    ReReference = 'Average'; %can be: 'Average', 'White Matter'. Any other string will keep as recorded. This value is also used for plotting in tier2, and this is why the names are clear and with spaces
    NpausesInNS=2; % blackrock uses pauses to sync between multiple NSPs
    usePauseN=2;
else
    Paradigm = Params.Subject.Paradigm;
    Subject = Params.Subject.Name;
    NewFile=Dest.File;
    NewDir=Dest.Dir;
    mkdir(NewDir);
    NSxFile=Orig.NSx;
    NEVfile=Orig.NEV;
	% @Add - Keep remove bad electrodes as info, add a remove/no remove boolean
    RemovedBadElectrodes = Params.BadElectrodes; % by visual inspection of DataCheckNSx. Can semi-automate
	WhiteMatterElectrodes = Params.WM_Electrodes;
    FilterLineNoise = Params.PreProc.FilterLineNoise;
    Resampling = Params.PreProc.Resampling;
    NewSR = Params.PreProc.NewSR; %if resampling is done
    ReReference = Params.PreProc.Reference; %can be: 'Average', 'White Matter'. Any other string will keep as recorded. This value is also used for plotting in tier2, and this is why the names are clear and with spaces
end
%% load Data
if Resampling 
    NSData = openNSx('noread',NSxFile);
    SR = NSData.MetaTags.SamplingFreq;
    SkipFactor = round(SR/NewSR);
    NewSR = SR/SkipFactor;
    NSData = openNSx(NSxFile,'skipfactor',SkipFactor);
else
    NSData = openNSx(NSxFile);
    SR = NSData.MetaTags.SamplingFreq;
    NewSR = SR;
end
if NpausesInNS>1 
    data=(double(NSData.Data{usePauseN}))'; %NOTICE THE LITTLE COMMA - IT TRANSPOSES THE DATA MATRIX (COLUMNS ARE NOW THE ELECTRODES) FOR SAVING AS TABLE
								  %@ToDo - Check if NPMK 3 makes the multiplication redundant!!!!!!!!!!!!!!!!!!
else
    data=(double(NSData.Data))';
end;
%% mark bad channels
% ENHANCE need to set the electrodes numbers to the corresponding channel
% numbers and not to assume that it is the same as their index.
% Ron: there is a code snippet which does just that in the beginning of
% microelecanalysis.m, though it looks like in the current logical indexing scheme it does not really matter 
GoodChannels=~ismember(deblank({NSData.ElectrodesInfo.Label}),RemovedBadElectrodes);
dataBeforeChannelRemove = data;
data=data(:,GoodChannels);

ElectrodeNames=deblank({NSData.ElectrodesInfo(:).Label});
cc=cell(1,length(ElectrodeNames));
cc(:)={'-'};
makafs = cellfun(@  strfind, ElectrodeNames,cc,'UniformOutput',false );
makafsLocationPlace=cellfun(@length,makafs);
makafsLocation=find(makafsLocationPlace>0);
for i=1:length(makafsLocation);
    ElecNameTemp=ElectrodeNames{makafsLocation(i)};
    ElecNameTemp(makafs{makafsLocation(i)})=[];
    ElectrodeNames{makafsLocation(i)}=ElecNameTemp;
end;
ElectrodeNamesBeforeRemove = ElectrodeNames;
ElectrodeNames=ElectrodeNames(GoodChannels);


%% mark bad time windows


%% Clean 50Hz noise with notch filter
% reference: http://www.mathworks.com/help/dsp/ref/iirnotch.html BUT see
% also:
% http://www.mathworks.com/help/signal/ug/remove-the-60-hz-hum-from-a-signal.html
% (since ver. 2014A)
if FilterLineNoise==true
    wo = 50/(NSData.MetaTags.SamplingFreq/2);  bw = wo/35;
    [b,a] = iirnotch(wo,bw);
    data=filtfilt(b,a,data); %filtfilt works per column ('the first non singleton dim, see http://www.mathworks.com/help/signal/ref/filtfilt.html)
    clear wo bw b a;
end
%% load triggers
NEV = [];
NEV = load(NEVfile);
NEV = NEV.NEV;
Triggers=[double(NEV.Data.SerialDigitalIO.UnparsedData), double(NEV.Data.SerialDigitalIO.TimeStamp')];
if isempty(NewSR)
    NewSR=NSData.MetaTags.SamplingFreq;
end
Triggers(:,2)=round(Triggers(:,2)/double((NEV.MetaTags.SampleRes/NewSR)));
Events=cell(size(data,1),1);
Events(:)={''};
EvenTrigs = EventTriggers(Paradigm);
N = 0;
for Event = [EvenTrigs{1,:}]
    N = N+1;
    Events(Triggers(Triggers(:,1)==Event,2))  = {EvenTrigs{2,N}};
end
Events=categorical(Events);
%% reReference
%Average reference, bipolar, WhiteMatter
if strcmp(ReReference,'Average')
    data=data';
    data = bsxfun(@minus,data,mean(data)); % ReReference to Average
											
    data=data';
end
if strcmp(ReReference,'Bipolar')
    data = dataBeforeChannelRemove';
    
    mone = 0;
    for i=1:length(ElectrodeNamesBeforeRemove)-1
        if length(find(ElectrodePairsToRemove==i))==0 % if its not in the electrode pairs to take out
            if  length(find(strcmp(RemovedBadElectrodes,ElectrodeNamesBeforeRemove{i})))==0 & length(find(strcmp(RemovedBadElectrodes,ElectrodeNamesBeforeRemove{i+1})))==0 % if doesnt contain a bad electrode
                mone = mone+1;
                ElectrodeNamesNew{mone}=[ElectrodeNamesBeforeRemove{i+1},'_',ElectrodeNamesBeforeRemove{i}];
                DataDiffClean(mone,:) = data(i+1,:)-data(i,:); % craete bipolar
                disp(['now doing elec: ',num2str(i)])
            end;
        end;
    end;
    ElectrodeNames = ElectrodeNamesNew
    data = DataDiffClean';

    
end;
if strcmp(ReReference,'White Matter')
    % ReReference to White Matter
    WhiteMatterElectrodesIDX=ismember(ElectrodeNames,WhiteMatterElectrodes);% @ToDo - ignore abnormal electrodes when calculating the average
    data=data';
    MeanVoltageWhiteMatter=mean(data(WhiteMatterElectrodesIDX,:));
    data=bsxfun(@minus,data,MeanVoltageWhiteMatter);
    data=data';
end

%% create data table
Time=(0:1/NewSR:(size(data,1)-1)*1/NewSR)';
Time=table(Time);
Time.Properties.VariableUnits={'sec'};
Events=table(Events);
d=array2table(data,'VariableNames',ElectrodeNames);
units=cell(size(d,2),1);
units(:)={'\muV'};
d.Properties.VariableUnits=units;
d=[Time, Events, d];
%% save data and finish preprocessing - can send to analysis
SR=NewSR;
g=struct();
g.data=d;
g.SR=SR;
g.MetaTags.Paradigm = Paradigm;
g.MetaTags.Subject = Subject;
g.MetaTags.DateTime=NSData.MetaTags.DateTime;
g.MetaTags.NewFile=NewFile;
g.MetaTags.NSxFile=NSxFile;
g.MetaTags.NEVfile=NEVfile;
g.MetaTags.ElectrodeNames=ElectrodeNames;
g.MetaTags.RemovedBadElectrodes=RemovedBadElectrodes;
g.MetaTags.FilterLineNoise=FilterLineNoise;
g.MetaTags.Resampling=Resampling;
g.MetaTags.ReReference=ReReference;
g.MetaTags.ElectrodePairsRemoved = ElectrodePairsToRemove;
if strcmp(ReReference,'White Matter')
    g.MetaTags.WhiteMatterElectrodesUsedForReReferencing=...
        ElectrodeNames(ismember(ElectrodeNames,WhiteMatterElectrodes)); %this is set and not 'WhiteMatterElectrodes' in case 'WhiteMatterElectrodes' includes a removed 'bad electrode'
end
save([NewDir NewFile],'g','-v7.3'); %large file size relative to NSx due to conversion to 'double'
clear all;
function EvenTrigs = EventTriggers(Paradigm)
        switch Paradigm
            case 'Domino'
                EvenTrigs = {0,1,2,11,12,13,14,15,16;...
                    'Choose','Ready','Go','Show match chip','Show non match chip','Picked match chip','Picked non match chip','NoShow match chip','NoShow non match chip'};
            case 'Cartman'
                EvenTrigs = {1,2,3,4,5,6,7,8,9,10,11,12,13;...
                    'Controlled Gain Appears','Controlled Lose Appears','Controlled Gain Achieved','Controlled Loss Achieved','Uncontrolled Gain Appears',...
                    'Uncontrolled Lose Appears','Uncontrolled Gain Achieved','Uncontrolled Lose Achieved','Controlled Gain missed','Start of baseline blackscreen',...
                    'End of baseline blackscreen','Start of game session','End of game session'};
        end
    end
end