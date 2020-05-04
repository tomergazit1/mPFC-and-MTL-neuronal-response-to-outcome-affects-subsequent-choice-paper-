function [TallTemp,TallFront]=creatingEventSequenceBigTableBatch(PSTH,FirstNeuronInSessions,RewTempNeurons,RewFrontNeurons,risk0riskAndNoRisk1)
% this function takes neurons that ar erelvant for regression of approach
% avoidance from frontal and temporal areas and creates tables (using creatingEventSequence ) per recording a where rows are trials and columns are
% 1. from this trial: whether its approach or avoidance
% 2. features from previous trial: movement, firing rates (of neurons inserted  to neuronInds), approach avoidance, times , misse/acheived
totalNeuronCount=427;
TallTemp=[];
TallFront=[];
for i=1:length(FirstNeuronInSessions)
    if i==length(FirstNeuronInSessions)
        SessionNeurons=[FirstNeuronInSessions(i):totalNeuronCount]
    else
        SessionNeurons=[FirstNeuronInSessions(i):FirstNeuronInSessions(i+1)-1]
    end;
    C_rewTemp = intersect(SessionNeurons,RewTempNeurons);
    C_rewFront = intersect(SessionNeurons,RewFrontNeurons);
    if length(C_rewTemp)>0
        for ch=1:length(C_rewTemp)
            tableTemp = creatingEventSequenceSingleCh(C_rewTemp(ch),PSTH,risk0riskAndNoRisk1);
            TallTemp=[TallTemp;tableTemp];
        end;
        writetable(tableTemp,'RewTempRegressionBigTablesAllPosNeurons.xlsx','Sheet',height(TallTemp));
      
    end;
    if length(C_rewFront)>0
        for ch=1:length(C_rewFront)
            tableFront = creatingEventSequenceSingleCh(C_rewFront(ch),PSTH,risk0riskAndNoRisk1);
             TallFront=[TallFront;tableFront];
        end;
        writetable(tableFront,'RewFrontRegressionBigTablesAllPosNeurons.xlsx','Sheet',height(TallFront));
    end;
end;