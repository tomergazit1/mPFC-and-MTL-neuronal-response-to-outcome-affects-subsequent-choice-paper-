function Tall = creatingEventSequenceSingleCh(neuronInds,PSTH12,risk0riskAndNoRisk1)
% this function takes all reward risk cases in one recording and creates a tables where rows are trials and columns are
% 1. from this trial: whether its approach or avoidance
% 2. features from previous trial: movement, firing rates (of neurons inserted  to neuronInds), approach avoidance, times , misse/acheived


ApRiskTimes=PSTH12(neuronInds(1)).Appear.ApproachRisk.timesInMS;
AvRiskTimes=PSTH12(neuronInds(1)).Appear.AvoidRisk.timesInMS;
ApNoRiskTimes=PSTH12(neuronInds(1)).Appear.ApproachNoRisk.timesInMS;
AvNoRiskTimes=PSTH12(neuronInds(1)).Appear.AvoidNoRisk.timesInMS;
GainAchTimes=PSTH12(neuronInds(1)).Achieve.ControlledGainAchieved.timesInMS;

typeList={'ApRiskTimes','AvRiskTimes'}
for type=1:length(typeList)
    T = table;
    eval(['RiskTimes=' typeList{type}]); 
    counter=0;
    for i=1:size(RiskTimes,1) % ap trials analysis
        currTrialTime=RiskTimes(i,1);
        
     
            TimePrevAp=0;
            TimePrevAv=0;
            TimePrevApNoRisk=0;
            TimePrevAvNoRisk=0;
            %% the next few lines find the previous trial time and behavior
            [Iap]=find(ApRiskTimes(:,1)<currTrialTime,1,'last'); % find previous ap
            [Iav]=find(AvRiskTimes(:,1)<currTrialTime,1,'last');% find previous av
            [IapNo]=find(ApNoRiskTimes(:,1)<currTrialTime,1,'last'); % find previous ap
            [IavNo]=find(AvNoRiskTimes(:,1)<currTrialTime,1,'last');% find previous av
            if length(Iap)>0
                TimePrevAp=ApRiskTimes(Iap,1);
            end;    
            if length(Iav)>0
                TimePrevAv=AvRiskTimes(Iav,1);
            end;
            if length(IapNo)>0
                TimePrevApNoRisk=ApNoRiskTimes(IapNo,1);
            end;    
            if length(IavNo)>0
                TimePrevAvNoRisk=AvNoRiskTimes(IavNo,1);
            end;
            
            if risk0riskAndNoRisk1 % in case you want to take both risky and norisky previous trials

                if TimePrevAp~=0 || TimePrevAv~=0  || TimePrevApNoRisk~=0 || TimePrevAvNoRisk~=0 % if you can find at least one previous
                    [TimePrev,Itemp]=max([TimePrevAp,TimePrevAv,TimePrevApNoRisk,TimePrevAvNoRisk]); % take the closest one (approach/avoid)
                    counter=counter+1;
                else 
                    continue
                end;

             else % in case you want to take only risky previous trials 

                if TimePrevAp~=0 || TimePrevAv~=0 % if you can find at least one previous
                    [TimePrev,Itemp]=max([TimePrevAp,TimePrevAv]); % take the closest one (approach/avoid)
                    counter=counter+1;
                else
                    continue
                end;
            end;
            T{counter,'cueTime_Curr'}=currTrialTime;
            if type==1
                T{counter,'avoid0approach1_curr'}=1; 
            else
                T{counter,'avoid0approach1_curr'}=0;
            end;  
            switch Itemp
                case 1
                   T{counter,'avoid0approach1_Prev'}=1;
                   TimeOutcome=ApRiskTimes(Iap,2);
                case 2
                   T{counter,'avoid0approach1_Prev'}=0;
                   TimeOutcome=AvRiskTimes(Iav,2);
                case 3
                   T{counter,'avoid0approach1_Prev'}=1;
                   TimeOutcome=ApNoRiskTimes(IapNo,2);
                case 4
                   T{counter,'avoid0approach1_Prev'}=0;
                   TimeOutcome=AvNoRiskTimes(IavNo,2);

            end;
            T{counter,'cueTime_Prev'}=TimePrev; 

            %% the next few lines deal with finding the outcome time, type (gain,miss), movement, firing and ball hits of previous trial
            RewAchTimes=PSTH12(neuronInds(1)).Achieve.ControlledGainAchieved.timesInMS;
            RewMissTimes=PSTH12(neuronInds(1)).Achieve.ControlledGainMissed.timesInMS;
            PunAchTimes=PSTH12(neuronInds(1)).Achieve.ControlledLossAchieved.timesInMS;
            [closeAch,IndCloseAch]=min(abs(RewAchTimes-TimeOutcome));
            [closeMiss,IndCloseMiss]=min(abs(RewMissTimes-TimeOutcome));
            if closeAch<closeMiss % if outcome is achieved
                T{counter,'miss0ach1'}=1; 
                T{counter,'movement'}=mean(PSTH12(neuronInds(1)).Achieve.ControlledGainAchieved.clicks(IndCloseAch,10:20)); % average the movement 1sec before and 1 after outcome
                for neuronInd=neuronInds
                    if sum(PSTH12(neuronInd).Achieve.ControlledGainAchieved.raster(IndCloseAch,3200:3800))>0 % if the neuron fired 200 to 800 ms post outcome
                       T{counter,['fired']}=1;
                    else
                       T{counter,['fired']}=0;
                    end;
                end;


                PunBeforeTimes=(PunAchTimes<(RewAchTimes(IndCloseAch)+1000));
                PunAfterTimes=(PunAchTimes>TimePrev);

            else
                T{counter,'miss0ach1'}=0;
                T{counter,'movement'}=mean(PSTH12(neuronInds(1)).Achieve.ControlledGainMissed.clicks(IndCloseMiss,10:20));
                for neuronInd=neuronInds
                    if sum(PSTH12(neuronInds(1)).Achieve.ControlledGainMissed.raster(IndCloseMiss,3200:3800))>0 % if the neuron fired 200 to 800 ms post outcome
                       T{counter,['fired']}=1;
                    else
                       T{counter,['fired']}=0;
                    end;
                end;
                PunBeforeTimes=(PunAchTimes<(RewMissTimes(IndCloseMiss)+1000));
                PunAfterTimes=(PunAchTimes>TimePrev);
            end;
            T{counter,['neuronGroup']}={num2str(neuronInd)};
            T{counter,'ballHits'}=sum(PunBeforeTimes.*PunAfterTimes); % find how many ball hits between previous cue and outcome plus 1sec

        end; % close for
   if type==1   
       Tap=T;
   else
       Tav=T;
   end;
   clear T
end;
Tall=[Tap;Tav];
Tall.moveNorm=(Tall.movement-mean(Tall.movement))/std(Tall.movement);
    

 