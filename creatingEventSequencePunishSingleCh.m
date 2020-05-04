function Tall = creatingEventSequencePunishSingleCh(neuronInd,PSTH12,risk0riskAndNoRisk1)
% this function takes all risk cases in one recording and creates a tables where rows are trials and columns are
% 1. from this trial: whether its approach or avoidance
% 2. time lag from last punishment, firing during last punishment, movement
% during last punishment


ApRiskTimes=PSTH12(neuronInd).Appear.ApproachRisk.timesInMS;
AvRiskTimes=PSTH12(neuronInd).Appear.AvoidRisk.timesInMS;
ApNoRiskTimes=PSTH12(neuronInd).Appear.ApproachNoRisk.timesInMS;
AvNoRiskTimes=PSTH12(neuronInd).Appear.AvoidNoRisk.timesInMS;
PunishTimes=PSTH12(neuronInd).Achieve.ControlledLossAchieved.timesInMS;
if risk0riskAndNoRisk1
    typeList={'ApRiskTimes','AvRiskTimes'};
else
    typeList={'ApNoRiskTimes','AvNoRiskTimes'};
end;
for type=1:length(typeList)
    T = table;
    eval(['RiskTimes=' typeList{type}]); 
    counter=0;
    for i=1:size(RiskTimes,1) % ap trials analysis
        currTrialTime=RiskTimes(i,1);
        
      
            TimePrevPun=0;
            %% the next few lines find the previous trial time and behavior
            [Ipun]=find(PunishTimes<currTrialTime,1,'last'); % find previous ap
            if length(Ipun)>0
                TimePrevPun=PunishTimes(Ipun);
            
                counter=counter+1;
                T{counter,'cueTime_Curr'}=currTrialTime;
                if type ==1
                    T{counter,'avoid0approach1'}=1;
                else
                    T{counter,'avoid0approach1'}=0;
                end;
                T{counter,'punTime_Prev'}=TimePrevPun; 
                T{counter,'deltaTime'}=currTrialTime-TimePrevPun;
                %% the next few lines deal with finding the outcome time, type (gain,miss), movement, firing and ball hits of previous trial

                T{counter,'movement'}=mean(PSTH12(neuronInd).Achieve.ControlledLossAchieved.clicks(Ipun,10:20)); % average the movement 1sec before and 1 after outcome
                        if sum(PSTH12(neuronInd).Achieve.ControlledLossAchieved.raster(Ipun,3200:3800))>0 % if the neuron fired 200 to 800 ms post outcome
                           T{counter,['fired']}=1;
                        else
                           T{counter,['fired']}=0;
                        end;
     
                T{counter,['neuronGroup']}={num2str(neuronInd)};
            end; % close verification if

        

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
    

 