function [ShutNoShutCon]=relateOutcomeToNextDecisionBatch(FirstNeuronInSessions,PSTH12,significantNeurons,condition)
% this function takes the big PSTH structure and for the given significant
% neurons calculates approach probability following firing vs following
% no-firing
% inputs:
% FirstNeuronInSessions - a list of indexes from PSTH of first neurons in session 
% PSTH12 - the big PSTH structure
% significantNeurons - relevant neurons you want to analyze
% condition - relevant condition
% Output:
% ShutNoShutCon - approach probablity following firing and following
% non-firing outcomes
ap=[];av=[];lowsAvPerc=[];highsAvPerc=[];
NumberOfTrialsPerNeuronAll=[];
for i=1:length(FirstNeuronInSessions)-1 % for each session
    recNeurons=[FirstNeuronInSessions(i) FirstNeuronInSessions(i+1)-1];
    [decision,FRnorm,FRnormAverage,FRraw]=relateOutcomeToNextDecisionRisk(PSTH12,recNeurons,significantNeurons,condition);
    
    indxNotNan=find(~isnan(decision));
    if length(FRnormAverage)>0
        av(i)=mean(FRnormAverage(find(decision==0)));
        ap(i)=mean(FRnormAverage(find(decision==1)));
        NumberOfTrialsPerNeuron=makeConfusionMatrix(decision,FRraw);
        NumberOfTrialsPerNeuronAll=[NumberOfTrialsPerNeuronAll; NumberOfTrialsPerNeuron];
        
        m=median(FRnormAverage(indxNotNan));
        lowsDec=decision(find(FRnormAverage<=m));
        lowsAvPerc(i)=length(find(lowsDec==0))/length(find(lowsDec==0|lowsDec==1));

        highsDec=decision(find(FRnormAverage>m));
        highsAvPerc(i)=length(find(highsDec==0))/length(find(highsDec==0|highsDec==1));
    end;
    
    
    
end;
figure; bar([lowsAvPerc;highsAvPerc]');
Shut=NumberOfTrialsPerNeuronAll(:,4)./(NumberOfTrialsPerNeuronAll(:,3)+NumberOfTrialsPerNeuronAll(:,4));
NoShut=NumberOfTrialsPerNeuronAll(:,2)./(NumberOfTrialsPerNeuronAll(:,1)+NumberOfTrialsPerNeuronAll(:,2));
figure;bar([NoShut(find(~isnan(NoShut))),Shut(find(~isnan(NoShut)))]);
colormap('gray');
mycmap = get(gcf,'Colormap');
set(gcf,'Colormap',flipud(mycmap));
ShutNoShutCon(:,1)=NumberOfTrialsPerNeuronAll(:,2)./(NumberOfTrialsPerNeuronAll(:,1)+NumberOfTrialsPerNeuronAll(:,2))
ShutNoShutCon(:,2)=NumberOfTrialsPerNeuronAll(:,4)./(NumberOfTrialsPerNeuronAll(:,3)+NumberOfTrialsPerNeuronAll(:,4))

function NumberOfTrialsPerNeuron=makeConfusionMatrix(decision,FRraw)
    indxNotNan=find(~isnan(decision));
    decisionNew=decision(indxNotNan)';
    FRrawNew=FRraw(indxNotNan,:);
    m=median(FRrawNew,1);
%     NeuronsResponsive=FRrawNew>=repmat(m,length(decisionNew),1);
    NeuronsResponsive=FRrawNew>0;

    for i=1:size(FRrawNew,2);
        % 1- no shut and no response, 2 - shut and no response, 
        % 3 - response and no shut, 4 - response and shut
        NumberOfTrialsPerNeuron(i,:)=[length(find(NeuronsResponsive(:,i)==0&decisionNew==0)),length(find(NeuronsResponsive(:,i)==0&decisionNew==1)),length(find(NeuronsResponsive(:,i)==1&decisionNew==0)),length(find(NeuronsResponsive(:,i)==1&decisionNew==1))];
        NumberOfTrialsPerNeuron(i,:)=NumberOfTrialsPerNeuron(i,:)./length(decisionNew);
    end;


    
    

