function [TallTempPun,TallFrontPun]=creatingEventSequenceBigTablePunBatch(PSTH,FirstNeuronInSessions,punTempNeurons,punFrontNeurons,risk0riskAndNoRisk1)
% this function takes neurons that ar erelvant for regression of approach
% avoidance from frontal and temporal areas and creates tables (using creatingEventSequence ) per recording a where rows are trials and columns are
% 1. from this trial: whether its approach or avoidance
% 2. features from previous trial: movement, firing rates (of neurons inserted  to neuronInds), approach avoidance, times , misse/acheived
totalNeuronCount=460;
TallTempPun=[];
TallFrontPun=[];
for i=1:length(FirstNeuronInSessions)-1
    if i==length(FirstNeuronInSessions)-1
        SessionNeurons=[FirstNeuronInSessions(i):totalNeuronCount];
    else
        SessionNeurons=[FirstNeuronInSessions(i):FirstNeuronInSessions(i+1)-1];
    end;
    C_punTemp = intersect(SessionNeurons,punTempNeurons);
    C_punFront = intersect(SessionNeurons,punFrontNeurons);
    if length(C_punTemp)>0
        for ch=1:length(C_punTemp)
            tableTempPun = creatingEventSequencePunishSingleCh(C_punTemp(ch),PSTH,risk0riskAndNoRisk1);
            TallTempPun=[TallTempPun;tableTempPun];
        end;
        %writetable(TallTempPun,'RegressionBigTablesPun.xlsx','Sheet',height(TallTempPun));
      
    end;
    if length(C_punFront)>0
        for ch=1:length(C_punFront)
            tableFrontPun = creatingEventSequencePunishSingleCh(C_punFront(ch),PSTH,risk0riskAndNoRisk1);
             TallFrontPun=[TallFrontPun;tableFrontPun];
        end;
        %writetable(TallFrontPun,'FrontRegressionBigTablesPun.xlsx','Sheet',height(TallFrontPun));
    end;
end;