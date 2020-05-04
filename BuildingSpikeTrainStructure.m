
% this script craetes a big structure called PSTH with all you need to
% know about the cartman single cell activity. each element is a neuron (or
% MU) and the structure includes global parameters: x,y,z coordinates,
% atlas label, channel name cluster..
% and the data itself which is organized into conditions. the conditions
% are organized to 3 categories according to the event to which they are
% time locked (apearnce and achieve). Each category is divided into conditions, for example:
% PSTH(1).Appear.ControlledGainAppears. these conditions include all relevant: reward/punish, control/uncontol, risk/ no
% risk, approach/avoid and appraoch risk achieved/missed
% each condition has 4 arrays:
% 1. timesInMS is the time of events in milliscond
% 2. raster is a binary matrix with spikes (currently including 3000ms before and 5000ms after the event)
% 3. PSTH - the PSTH (sum of raster, binned to windows which are currently 200ms)
% 4. clicks - number of movement presses during each window (currently 200ms long)
patient='D001';
pathi_ApAv='...\ApproachAvoid';
pathi='...*'
tableFile='...\*_Micro.mat';
unitsSummaryFile='...\UnitList.xlsx'; % an excel listing all neurons
columnsInUnitSummaryFile=[1:4]; % the 4 columns in this excel that are relevant for this recording: v - if to use this neuron, channel #, cluster #, electrode name
d=dir([ pathi '\Channel*']); % if a PNG file exists it means that the raster of this cluster has been calculated
[NUM,TXT,RAW]=xlsread(unitsSummaryFile,1);
d_ApAv=dir([ pathi_ApAv '\Channel*']); % if a PNG file exists it means that the raster of this cluster has been calculated
rowN=size(RAW,1);
binSize=200; % bin size for raster
timeBefore=3000;
timeAfter=5000;

needToLoadTable=1;
AppearConditions={'ControlledGainAppears','ControlledLoseAppears','UncontrolledGainAppears','UncontrolledLoseAppears'};
AppearConditionsApAv={'AvoidRisk','AvoidNoRisk','ApproachRisk','ApproachNoRisk'};
AchieveConditions={'ControlledGainAchieved','ControlledLossAchieved','UncontrolledGainAchieved','UncontrolledLoseAchieved','ControlledGainMissed'};
AchieveConditionsApAv={'AvoidRiskEnd','AvoidNoRiskEnd','ApproachRiskEnd','ApproachNoRiskEnd'};

load('...\ElecNames.mat'); % loading the electrode names, cell array 
load('...\MNIlocs.mat'); % loading electrode locations matlab table wityh x,y,z
load([pathi '\StimulusTimes.mat']); % loading trigger times in 30000 fs 
load([pathi_ApAv '\StimulusTimesApAv.mat']); % loading trigger times
if needToLoadTable % to save time
    load(tableFile);
end;
FSofTable=g.SR;
counterUnits=0;
for i=1:rowN % this is the main loop which runs on all units craetes the PSTH structure for them
    if RAW{i,columnsInUnitSummaryFile(1)}=='v'; % if there is a v in the first relevant excel column then this unit should be considered
        channel=RAW{i,columnsInUnitSummaryFile(2)};
        cluster=RAW{i,columnsInUnitSummaryFile(3)};
        area =  RAW{i,columnsInUnitSummaryFile(4)};
        fileNamePNG=['Channel' num2str(channel) '_Cluster' num2str(cluster) '_' num2str(area)  '.mat' ];
    %     fileNamePNG=d(i).name;
        found=0;
        foundApAv=0;
        for units=1:length(d) % look for this unit in the ApAv folder
            if strcmp(fileNamePNG,d(units).name)
                found=1;
            end;
        end;
        for unitsApAv=1:length(d_ApAv) % look for this unit in the ApAv folder
            if strcmp(fileNamePNG,d_ApAv(unitsApAv).name)
                foundApAv=1;
            end;
        end;
        if (found)&&(foundApAv) % only if the unit exists also in Aproach Avoid then it will process it
            counterUnits=counterUnits+1;
            PSTH(counterUnits).patient=patient;
%             if fileNamePNG(14)=='_' % deals with the case of electrode name with just one digit
            PSTH(counterUnits).channel=channel;
            PSTH(counterUnits).cluster=cluster;
            PSTH(counterUnits).area=area;
            
%             else % case of elec name with 2 digits
%                 PSTH(counterUnits).channel=fileNamePNG(13:14);
%                 PSTH(counterUnits).cluster=fileNamePNG(23);
%             end;
%             loc=strfind(fileNamePNG,'_stimSet');
            fileName{counterUnits}=fileNamePNG;
            load([pathi_ApAv '\' fileName{counterUnits}]);
            BlockSpikeTrains_ApAv=BlockSpikeTrains;
            load([pathi '\' fileName{counterUnits}]);

        %     condition=fieldnames(BlockSpikeTrains);
            for j=1:length(AppearConditions); % run on all appear conditions, bin the rasters, get the timings of events and get the clicks (movement)
                binned_vec = eval(['bin_spikes(sum(BlockSpikeTrains.' AppearConditions{j} '),' num2str(binSize) ');']);
                Ntrials=eval(['size(BlockSpikeTrains.' AppearConditions{j} ',1);']);
                binned_vec=binned_vec/Ntrials./(binSize/1000); % normalize to firing rate
                timesInMS=eval(['StimulusTimes.' AppearConditions{j} '/30;']); % get the time of events and convert to ms
                %%% the following lines deal with inserting the clicks 3000 ms
                %%% before and 5000ms after the event
                indsOfClicks=[round((timesInMS-timeBefore)*(FSofTable/1000)) round((timesInMS-timeBefore)*(FSofTable/1000)+(timeBefore+timeAfter)*(FSofTable/1000))-1]; % get the relevant indices of g.data that will be taken
                for trialN=1:size(indsOfClicks,1);
                    missingSamples=round(FSofTable*(binSize/1000))*((timeBefore+timeAfter)/binSize)-(indsOfClicks(trialN,2)-indsOfClicks(trialN,1)+1);
                    if missingSamples>0 % sometings there are some missing samples to be taken care of for the reshape
                        indsOfClicks(trialN,2)=indsOfClicks(trialN,2)+missingSamples;
                        fprintf(['in trial number ' num2str(trialN) ' there were ' num2str(missingSamples) ' missing samples\n']);
                    end
                    clicksTemp=g.data.Clicks(indsOfClicks(trialN,1):indsOfClicks(trialN,2));
                    clicksMatrix(trialN,:)=sum(reshape(clicksTemp,round(FSofTable*(binSize/1000)),(timeBefore+timeAfter)/binSize)); % decrease the resolution to coult the number of presses for each bin (currently 200ms bins)
                end;
                eval(['PSTH(counterUnits).Appear.' AppearConditions{j} '.PSTH=binned_vec;']); % place PSTH vector it in the structure PSTH
                eval(['PSTH(counterUnits).Appear.' AppearConditions{j} '.raster=BlockSpikeTrains.' AppearConditions{j} ';']); % place rasster matrix in the structure PSTH
                eval(['PSTH(counterUnits).Appear.' AppearConditions{j} '.timesInMS=timesInMS;']); % place time of events vector in the structure PSTH
                eval(['PSTH(counterUnits).Appear.' AppearConditions{j} '.clicks=clicksMatrix;']); % place clicks matrix in the structure PSTH
                clear clicksMatrix;
            end;

            for j=1:length(AppearConditionsApAv);% run on all appear aproach avoid conditions, bin the rasters, get the timings of events and get the clicks (movement)
                binned_vec = eval(['bin_spikes(sum(BlockSpikeTrains_ApAv.' AppearConditionsApAv{j} '),' num2str(binSize) ');']);
                Ntrials=eval(['size(BlockSpikeTrains_ApAv.' AppearConditionsApAv{j} ',1);']);
                binned_vec=binned_vec/Ntrials./(binSize/1000);
                timesInMS=eval(['StimulusTimesApAv.' AppearConditionsApAv{j} '/30;']); % notice that in ApAv the timings are given in a matrix with 2 columns signifying the timing of start and end of the trial
                %%% the following lines deal with inserting the clicks 3000 ms
                %%% before and 5000ms after the event
                indsOfClicks=[round((timesInMS(:,1)-timeBefore)*(FSofTable/1000)) round((timesInMS(:,1)+timeAfter)*(FSofTable/1000))-1]; % take only the start time
                for trialN=1:size(indsOfClicks,1);
                    missingSamples=round(FSofTable*(binSize/1000))*((timeBefore+timeAfter)/binSize)-(indsOfClicks(trialN,2)-indsOfClicks(trialN,1)+1);
                    if missingSamples>0 % sometings there are some missing samples to be taken care of for the reshape
                        indsOfClicks(trialN,2)=indsOfClicks(trialN,2)+missingSamples;
                        fprintf(['in trial number ' num2str(trialN) ' there were ' num2str(missingSamples) ' missing samples\n']);
                    end
                    clicksTemp=g.data.Clicks(indsOfClicks(trialN,1):indsOfClicks(trialN,2));
                    clicksMatrix(trialN,:)=sum(reshape(clicksTemp,round(FSofTable*(binSize/1000)),(timeBefore+timeAfter)/binSize));
                end;
                eval(['PSTH(counterUnits).Appear.' AppearConditionsApAv{j} '.PSTH=binned_vec;']); % place it in the structure PSTH
                eval(['PSTH(counterUnits).Appear.' AppearConditionsApAv{j} '.raster=BlockSpikeTrains_ApAv.' AppearConditionsApAv{j} ';']); % place it in the structure PSTH
                eval(['PSTH(counterUnits).Appear.' AppearConditionsApAv{j} '.timesInMS=timesInMS;']);
                eval(['PSTH(counterUnits).Appear.' AppearConditionsApAv{j} '.clicks=clicksMatrix;']); % place it in the structure PSTH
                clear clicksMatrix;
            end;

           for j=1:length(AchieveConditions); % run on all achieve conditions, bin the rasters, get the timings of events and get the clicks (movement)
                binned_vec = eval(['bin_spikes(sum(BlockSpikeTrains.' AchieveConditions{j} '),' num2str(binSize) ');']);
                Ntrials=eval(['size(BlockSpikeTrains.' AchieveConditions{j} ',1);']);
                binned_vec=binned_vec/Ntrials./(binSize/1000);
                timesInMS=eval(['StimulusTimes.' AchieveConditions{j} '/30;']);
                %%% the following lines deal with inserting the clicks 3000 ms
                %%% before and 5000ms after the event
                indsOfClicks=[round((timesInMS-timeBefore)*(FSofTable/1000)) round((timesInMS+timeAfter)*(FSofTable/1000))-1];
                [rr,cc]=find(indsOfClicks<0);


                for trialN=1:size(indsOfClicks,1);
                    if indsOfClicks(trialN,1)<0 % dael with the special case that the recording starts after 3000ms before the trigger - currently i only did this for the achieved section
                        clickTemp=zeros(1,(timeBefore+timeAfter)/binSize);
                    else
                        clicksTemp=g.data.Clicks(indsOfClicks(trialN,1):indsOfClicks(trialN,2));
                    end;
                    clicksMatrix(trialN,:)=sum(reshape(clicksTemp,round(FSofTable*(binSize/1000)),(timeBefore+timeAfter)/binSize));
                end;
                eval(['PSTH(counterUnits).Achieve.' AchieveConditions{j} '.PSTH=binned_vec;']); % place it in the structure PSTH
                eval(['PSTH(counterUnits).Achieve.' AchieveConditions{j} '.raster=BlockSpikeTrains.' AchieveConditions{j} ';']); % place it in the structure PSTH
                eval(['PSTH(counterUnits).Achieve.' AchieveConditions{j} '.timesInMS=timesInMS;']);
                eval(['PSTH(counterUnits).Achieve.' AchieveConditions{j} '.clicks=clicksMatrix;']); % place it in the structure PSTH
                clear clicksMatrix;
            end;

            for j=1:length(AchieveConditionsApAv); % run on all achieve aproach avoid conditions, bin the rasters, get the timings of events and get the clicks (movement)
                binned_vec = eval(['bin_spikes(sum(BlockSpikeTrains_ApAv.' AchieveConditionsApAv{j} '),' num2str(binSize) ');']);
                Ntrials=eval(['size(BlockSpikeTrains_ApAv.' AchieveConditionsApAv{j} ',1);']);
                binned_vec=binned_vec/Ntrials./(binSize/1000);
                timesInMS=eval(['StimulusTimesApAv.' AppearConditionsApAv{j} '/30;']);% notice that in ApAv the timings are given in a matrix with 2 columns signifying the timing of start and end of the trial
                %%% the following lines deal with inserting the clicks 3000 ms
                %%% before and 5000ms after the event
                indsOfClicks=[round((timesInMS(:,2)-timeBefore)*(FSofTable/1000)) round((timesInMS(:,2)+timeAfter)*(FSofTable/1000))-1]; % here we take the second colomn of timesinMS because we want to sync with the  end of the trial
                for trialN=1:size(indsOfClicks,1);
                    clicksTemp=g.data.Clicks(indsOfClicks(trialN,1):indsOfClicks(trialN,2));
                    clicksMatrix(trialN,:)=sum(reshape(clicksTemp,round(FSofTable*(binSize/1000)),(timeBefore+timeAfter)/binSize));
                end;
                eval(['PSTH(counterUnits).Achieve.' AchieveConditionsApAv{j} '.PSTH=binned_vec;']); % place it in the structure PSTH
                eval(['PSTH(counterUnits).Achieve.' AchieveConditionsApAv{j} '.raster=BlockSpikeTrains_ApAv.' AchieveConditionsApAv{j} ';']); % place it in the structure PSTH
                eval(['PSTH(counterUnits).Achieve.' AchieveConditionsApAv{j} '.timesInMS=timesInMS(:,2)/30;']); % take the times from the second colomn of the appear condition
                eval(['PSTH(counterUnits).Achieve.' AchieveConditionsApAv{j} '.clicks=clicksMatrix;']); % place it in the structure PSTH
                clear clicksMatrix;

            end;
        PSTH=SplitAchievedAndMissed(PSTH,binSize); % this outer function adds 4 additional conditions under achieve: approach risk achieved, approach risk missed,approach no risk achieved,approach no risk missed
        else
            fprintf(['unit: ' fileNamePNG ' was not found in either classic or ApAv \n']);  
        end 
    end;
end;
%%%%%%%%%% include elec names (taken from a made already structure)
% % for i=1:length(PSTH)
% %     ch=PSTH(i).channel;
% %     patient=PSTH(i).patient;
% %     PSTH(i).chName=eval(['ElecNames' patient '{' ch '};']);
% % end;
%%%%%%%%


% % %     for i=1:length(PSTH) % remove digits from channel names
% % %         a=PSTH(i).chName;
% % %         a(find((double(a)>47)&(double(a)<58)))=[];PSTH(i).chName=a;
% % %     end;
% % %     for i=1:length(PSTH) % remove digits from channel names
% % %         a=PSTH(i).chName;
% % %         a(find(double(a)==0))=[];PSTH(i).chName=a;
% % %     end;
    %
%%% the following lines insert the xyz and labels of the electrode
elecs=MNIlocs.elec;
patients=MNIlocs.patient;
for i=1:length(PSTH)
    patientTemp=PSTH(i).patient;
    chNameTemp=PSTH(i).area;
    chInd=find(ismember(elecs,chNameTemp).*ismember(patients,patientTemp));
    if length(chInd)~=1
        error('too many or too litle channels fit');
    else
        xtemp=table2array(MNIlocs(chInd,'x'));
        ytemp=table2array(MNIlocs(chInd,'y'));
        ztemp=table2array(MNIlocs(chInd,'z'));
        atalstemp=table2array(MNIlocs(chInd,'atlas'));
        PSTH(i).x=xtemp{1};
        PSTH(i).y=ytemp{1};
        PSTH(i).z=ztemp{1};
        PSTH(i).atlasLabel=atalstemp{1};
    end;
end








  




 


 
        