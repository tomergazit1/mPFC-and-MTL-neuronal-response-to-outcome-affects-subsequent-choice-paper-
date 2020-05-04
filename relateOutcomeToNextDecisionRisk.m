function [decision,FRnorm,FRnormAverage,FRraw]=relateOutcomeToNextDecisionRisk(PSTH,recNeurons,signifNeurons,condition)

% this functions evaluates for a specific recording the relationship
% between response to outcome and the following decision to
% approach or avoid
% 0 means avoid, 1 means approach
% inputs:
% PSTH - the big structure 
% recNeurons - the relevant recording neurons indexes in PSTH
% signifNeurons - significant neurons you want to evaluate
% condition - xondition you want to evaluate
% outputs:
% decision - the subsequent decision per trial
% FRnorm - normalized figiring rate per trial
% FRnormAvearge - normalized FR avereged
% FRraw - raw firing rates

binSize=200;
Niter=1000; % iterations for bootstrapping
relevantWindows=[17:19]; % appears
useOnlyRisk=1;
useOnlyRiskForNeuralResponse=1;
signifNeuronsInSession=signifNeurons(find((signifNeurons>=recNeurons(1)) & (signifNeurons<=recNeurons(2)))); % take only frontal significant neuron in the relevant session
%%% get the times of events: punishment achieved and approach avoid appears
switch condition
    case 1
        condTimes=PSTH(recNeurons(1)).Achieve.ControlledGainAchieved.timesInMS;
    case 2
        condTimes=PSTH(recNeurons(1)).Achieve.ControlledLossAchieved.timesInMS;
    case 3
        condTimes=PSTH(recNeurons(1)).Achieve.UncontrolledGainAchieved.timesInMS;
    case 4
        condTimes=PSTH(recNeurons(1)).Achieve.UncontrolledLoseAchieved.timesInMS;
    case 5
        condTimes=PSTH(recNeurons(1)).Appear.ApproachRisk.timesInMS(:,1);
    case 6
        condTimes=PSTH(recNeurons(1)).Appear.ApproachNoRisk.timesInMS(:,1);

end;

approachRiskTimes=PSTH(recNeurons(1)).Appear.ApproachRisk.timesInMS;
avoidRiskTimes=PSTH(recNeurons(1)).Appear.AvoidRisk.timesInMS;
approachNoRiskTimes=PSTH(recNeurons(1)).Appear.ApproachNoRisk.timesInMS;
avoidNoRiskTimes=PSTH(recNeurons(1)).Appear.AvoidNoRisk.timesInMS;
approachTimes=[approachRiskTimes(:,1); approachNoRiskTimes(:,1)];
avoidTimes=[avoidRiskTimes(:,1);avoidNoRiskTimes(:,1)];

%%% the next loop is intended to detect wether a trials was followed by
%%% approach or avoid
counterPunish=0;
for i=1:length(condTimes)
    punishTimeTemp=condTimes(i);
    
    deltaApproach=(approachTimes-punishTimeTemp);
    deltaApproach(deltaApproach<=0)=NaN; 
    [minApproachValue,minApproachIndx]=min(deltaApproach);
    
    deltaAvoid=(avoidTimes-punishTimeTemp);
    deltaAvoid(deltaAvoid<=0)=NaN; 
    [minAvoidValue,minAvoidIndx]=min(deltaAvoid);
    
    deltaApproachRisk=(approachRiskTimes(:,1)-punishTimeTemp);
    deltaApproachRisk(deltaApproachRisk<=0)=NaN; 
    [minApproachRiskValue,minApproachRiskIndx]=min(deltaApproachRisk);
    
    deltaAvoidRisk=(avoidRiskTimes(:,1)-punishTimeTemp);
    deltaAvoidRisk(deltaAvoidRisk<=0)=NaN; 
    [minAvoidRiskValue,minAvoidRiskIndx]=min(deltaAvoidRisk);
    
    deltaApproachNoRisk=(approachNoRiskTimes(:,1)-punishTimeTemp);
    deltaApproachNoRisk(deltaApproachNoRisk<=0)=NaN; 
    [minApproachNoRiskValue,minApproachNoRiskIndx]=min(deltaApproachNoRisk);
    
    deltaAvoidNoRisk=(avoidNoRiskTimes(:,1)-punishTimeTemp);
    deltaAvoidNoRisk(deltaAvoidNoRisk<=0)=NaN; 
    [minAvoidNoRiskValue,minAvoidNoRiskIndx]=min(deltaAvoidNoRisk);
    
    mins=[minApproachRiskValue,minAvoidRiskValue,minApproachNoRiskValue,minAvoidNoRiskValue];
    [minVal,minInd]=min(mins);
    if useOnlyRisk
        switch minInd
            case 1
                decision(i)=1; % approach
            case 2
                decision(i)=0; % avoid
            otherwise
                decision(i)=NaN;
        end;
    else
       if minApproachValue<minAvoidValue
        decision(i)=1; % approach
        else
        decision(i)=0; % avoid
        end;    
    end;
    
    
    
    
end;
% the next loop is the big thing, calculated the FR for each trials and neuron and normalizes it
FRnorm=[];FRraw=[];
for i=1:length(signifNeuronsInSession)
    unit=signifNeuronsInSession(i);
    rasterBaseline=PSTH(unit).Appear.ControlledLoseAppears.raster; % take the raster from which you will create the baseline for bootstrapping. curently i use control lose appears which basically has all epochs of the game because the balls are all the time
    for line=1:size(rasterBaseline,1)
         windowedBasline(line,:)=bin_spikes(rasterBaseline(line,:),binSize)*(1000/binSize); %  bin and normalize to FR
    end;
    windowedBaslineResh=reshape(windowedBasline,1,size(windowedBasline,1)*size(windowedBasline,2)); % rearrange baseline matrix as vector
    randTemp=randperm(length(windowedBaslineResh),Niter); % choose random windows from baseline
    randCurrent=windowedBaslineResh(randTemp);
    med=median(randCurrent);s=std(randCurrent);
    switch condition
        case 1
            rasterCond=PSTH(unit).Achieve.ControlledGainAchieved.raster; 
        case 2
            rasterCond=PSTH(unit).Achieve.ControlledLossAchieved.raster; 
        case 3
            rasterCond=PSTH(unit).Achieve.UncontrolledGainAchieved.raster; 
        case 4
            rasterCond=PSTH(unit).Achieve.UncontrolledLoseAchieved.raster;
        case 5 
            rasterCond=PSTH(unit).Appear.ApproachRisk.raster;
        case 6 
            rasterCond=PSTH(unit).Appear.ApproachNoRisk.raster; 

    end;
            
            
    for line=1:size(rasterCond,1)
         windowedPunish(line,:)=bin_spikes(rasterCond(line,:),binSize)*(1000/binSize); %  bin and normalize to FR
    end;
    
    FRtemp=mean(windowedPunish(:,relevantWindows),2);
    FRnorm(:,i)=(FRtemp-med)/s;
    FRraw(:,i)=FRtemp;
end;
% % % if length(FRnorm
FRnormAverage=mean(abs(FRnorm),2); % notice that i take the absolute value to deal with descreases




    