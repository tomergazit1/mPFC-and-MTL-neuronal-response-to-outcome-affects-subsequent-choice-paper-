function PSTH=SplitAchievedAndMissed(PSTH,binSize) % this function splits the achieved to cases that were risk approach, norisk approach
% this function splits approach Risk to approach risk achieved and missed
% it also splits approach no Risk to approach no risk achieved and missed
% it takes the approach risk and no risk from the big PSTH structre and
% adds to it the 4 new conditions with their time of events, rasters, PSTHs and clicks
timesAchieved=PSTH(1).Achieve.ControlledGainAchieved.timesInMS;
timesMissed=PSTH(1).Achieve.ControlledGainMissed.timesInMS;
timesApRisk=PSTH(1).Appear.ApproachRisk.timesInMS;
timesApNoRisk=PSTH(1).Appear.ApproachNoRisk.timesInMS;
achievedN=length(timesAchieved);
missedN=length(timesMissed);
ApRiskN=size(timesApRisk,1);
ApNoRiskN=size(timesApNoRisk,1);
ApRiskAchInd=[];ApRiskMissInd=[];ApNoRiskAchInd=[];ApNoRiskMissInd=[];
%% finding the indexes of appraoch risk and approach no risk in the achieved and missed
for i=1:ApRiskN
    [tempAch,Iach]=min(abs(repmat(timesApRisk(i,2),achievedN,1)-timesAchieved));
    [tempMiss,Imiss]=min(abs(repmat(timesApRisk(i,2),missedN,1)-timesMissed));
    if min(tempAch,tempMiss)>100
        warning(['match of approach risk trial ' num2str(i) ' in achieved or missed has a strange long delay' ]);
    end;
    if (tempAch<tempMiss) % if there is a hit in this trial
        ApRiskAchInd=[ApRiskAchInd Iach]; 
    else
        ApRiskMissInd=[ApRiskMissInd Imiss]; 
    end;
end;
    
for i=1:ApNoRiskN
    [tempAch,Iach]=min(abs(repmat(timesApNoRisk(i,2),achievedN,1)-timesAchieved));
    [tempMiss,Imiss]=min(abs(repmat(timesApNoRisk(i,2),missedN,1)-timesMissed));
    if min(tempAch,tempMiss)>100
        warning(['match of approach no risk trial ' num2str(i) ' in achieved or missed has a strange long delay' ]);
    end;
    if (tempAch<tempMiss) % if there is a hit in this trial
        ApNoRiskAchInd=[ApNoRiskAchInd Iach]; 
    else
        ApNoRiskMissInd=[ApNoRiskMissInd Imiss]; 
    end;
end;
for i=1:length(PSTH)
    PSTH(i).Achieve.ApproachRiskAchieve.timesInMS=PSTH(i).Achieve.ControlledGainAchieved.timesInMS(ApRiskAchInd); %% appraoc risk achieved
    PSTH(i).Achieve.ApproachRiskAchieve.raster=PSTH(i).Achieve.ControlledGainAchieved.raster(ApRiskAchInd,:);
    PSTH(i).Achieve.ApproachRiskAchieve.clicks=PSTH(i).Achieve.ControlledGainAchieved.clicks(ApRiskAchInd,:);
    PSTH(i).Achieve.ApproachRiskAchieve.PSTH=bin_spikes(sum(PSTH(i).Achieve.ApproachRiskAchieve.raster),binSize)/size(PSTH(i).Achieve.ApproachRiskAchieve.raster,1)./(binSize/1000);
    
    PSTH(i).Achieve.ApproachNoRiskAchieve.timesInMS=PSTH(i).Achieve.ControlledGainAchieved.timesInMS(ApNoRiskAchInd); %% appraoc no risk achieved
    PSTH(i).Achieve.ApproachNoRiskAchieve.raster=PSTH(i).Achieve.ControlledGainAchieved.raster(ApNoRiskAchInd,:);
    PSTH(i).Achieve.ApproachNoRiskAchieve.clicks=PSTH(i).Achieve.ControlledGainAchieved.clicks(ApNoRiskAchInd,:);
    PSTH(i).Achieve.ApproachNoRiskAchieve.PSTH=bin_spikes(sum(PSTH(i).Achieve.ApproachNoRiskAchieve.raster),binSize)/size(PSTH(i).Achieve.ApproachNoRiskAchieve.raster,1)./(binSize/1000);

    PSTH(i).Achieve.ApproachRiskMissed.timesInMS=PSTH(i).Achieve.ControlledGainMissed.timesInMS(ApRiskMissInd); %% appraoc risk missed
    PSTH(i).Achieve.ApproachRiskMissed.raster=PSTH(i).Achieve.ControlledGainMissed.raster(ApRiskMissInd,:);
    PSTH(i).Achieve.ApproachRiskMissed.clicks=PSTH(i).Achieve.ControlledGainMissed.clicks(ApRiskMissInd,:);
    PSTH(i).Achieve.ApproachRiskMissed.PSTH=bin_spikes(sum(PSTH(i).Achieve.ApproachRiskMissed.raster),binSize)/size(PSTH(i).Achieve.ApproachRiskMissed.raster,1)./(binSize/1000);
    
    PSTH(i).Achieve.ApproachNoRiskMissed.timesInMS=PSTH(i).Achieve.ControlledGainMissed.timesInMS(ApNoRiskMissInd); %% appraoc no risk missed
    PSTH(i).Achieve.ApproachNoRiskMissed.raster=PSTH(i).Achieve.ControlledGainMissed.raster(ApNoRiskMissInd,:);
    PSTH(i).Achieve.ApproachNoRiskMissed.clicks=PSTH(i).Achieve.ControlledGainMissed.clicks(ApNoRiskMissInd,:);
    PSTH(i).Achieve.ApproachNoRiskMissed.PSTH=bin_spikes(sum(PSTH(i).Achieve.ApproachNoRiskMissed.raster),binSize)/size(PSTH(i).Achieve.ApproachNoRiskMissed.raster,1)./(binSize/1000);

end;