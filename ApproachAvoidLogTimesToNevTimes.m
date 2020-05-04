% this script takes the matlab matlab structure from PRTStilmulusTimesLog
% along with the NEV file fron BlackRock to synchronize the timing and
% assign each event in the NEV triggers with its label from the log file
% with the correct timing
% the output us a structure NevTimesAllUpdated with the correct timings in
% NEV time
Triggers=[double(NEV.Data.SerialDigitalIO.UnparsedData), double(NEV.Data.SerialDigitalIO.TimeStamp')];
trigTimesStart=double(Triggers(find(Triggers(:,1)==12),2))
trigTimesEnd=double(Triggers(find(Triggers(:,1)==13),2))
trigTimesConGainApe=double(Triggers(find(Triggers(:,1)==1),2))
trigTimesConGainAch=double(Triggers(find(Triggers(:,1)==3),2))
trigTimesConGainMis=double(Triggers(find(Triggers(:,1)==9),2))



startingTimesInLog=45;
fsNEV=30000;
Nruns=length(LogTimesSess);
for i=1:Nruns
    eval(['NevTimesSess(' num2str(i) ').AvoidNoRisk=(LogTimesSess(' num2str(i) ').AvoidNoRisk/1000-startingTimesInLog+trigTimesStart(' num2str(i) ')/fsNEV)*fsNEV;']);
    eval(['NevTimesSess(' num2str(i) ').AvoidRisk=(LogTimesSess(' num2str(i) ').AvoidRisk/1000-startingTimesInLog+trigTimesStart(' num2str(i) ')/fsNEV)*fsNEV;']);
    eval(['NevTimesSess(' num2str(i) ').ApproachNoRisk=(LogTimesSess(' num2str(i) ').ApproachNoRisk/1000-startingTimesInLog+trigTimesStart(' num2str(i) ')/fsNEV)*fsNEV;']);
    eval(['NevTimesSess(' num2str(i) ').ApproachRisk=(LogTimesSess(' num2str(i) ').ApproachRisk/1000-startingTimesInLog+trigTimesStart(' num2str(i) ')/fsNEV)*fsNEV;']);
end;
switch Nruns
    case 2
        NevTimesAll.AvoidRisk=[NevTimesSess(1).AvoidRisk;NevTimesSess(2).AvoidRisk];
        NevTimesAll.AvoidNoRisk=[NevTimesSess(1).AvoidNoRisk;NevTimesSess(2).AvoidNoRisk];
        NevTimesAll.ApproachRisk=[NevTimesSess(1).ApproachRisk;NevTimesSess(2).ApproachRisk];
        NevTimesAll.ApproachNoRisk=[NevTimesSess(1).ApproachNoRisk;NevTimesSess(2).ApproachNoRisk];
    case 3
        NevTimesAll.AvoidRisk=[NevTimesSess(1).AvoidRisk;NevTimesSess(2).AvoidRisk;NevTimesSess(3).AvoidRisk];
        NevTimesAll.AvoidNoRisk=[NevTimesSess(1).AvoidNoRisk;NevTimesSess(2).AvoidNoRisk;NevTimesSess(3).AvoidNoRisk;];
        NevTimesAll.ApproachRisk=[NevTimesSess(1).ApproachRisk;NevTimesSess(2).ApproachRisk;NevTimesSess(3).ApproachRisk];
        NevTimesAll.ApproachNoRisk=[NevTimesSess(1).ApproachNoRisk;NevTimesSess(2).ApproachNoRisk;NevTimesSess(3).ApproachNoRisk];
    case 4
        NevTimesAll.AvoidRisk=[NevTimesSess(1).AvoidRisk;NevTimesSess(2).AvoidRisk;NevTimesSess(3).AvoidRisk;NevTimesSess(4).AvoidRisk];
        NevTimesAll.AvoidNoRisk=[NevTimesSess(1).AvoidNoRisk;NevTimesSess(2).AvoidNoRisk;NevTimesSess(3).AvoidNoRisk;NevTimesSess(4).AvoidNoRisk];
        NevTimesAll.ApproachRisk=[NevTimesSess(1).ApproachRisk;NevTimesSess(2).ApproachRisk;NevTimesSess(3).ApproachRisk;NevTimesSess(4).ApproachRisk];
        NevTimesAll.ApproachNoRisk=[NevTimesSess(1).ApproachNoRisk;NevTimesSess(2).ApproachNoRisk;NevTimesSess(3).ApproachNoRisk;NevTimesSess(4).ApproachNoRisk];
end;



conditions={'AvoidNoRisk','AvoidRisk','ApproachNoRisk','ApproachRisk'}
for con=1:4;
    eval(['TimesTemp=NevTimesAll.' conditions{con} ';']);
    for i=1:size(TimesTemp,1)

        onsetTimeTemp=TimesTemp(i,1);
        ofsetTimeTemp=TimesTemp(i,2);

        indFoundApe=find(trigTimesConGainApe>onsetTimeTemp,1,'first');
        if length(indFoundApe)==0
            indFoundApe=find(trigTimesConGainApe<onsetTimeTemp,1,'last');
        end;
        if indFoundApe==1;
            indFoundApe=2;
        end;

        if abs((trigTimesConGainApe(indFoundApe)-onsetTimeTemp))>abs((trigTimesConGainApe(indFoundApe-1)-onsetTimeTemp))
             indFoundApe=indFoundApe-1;
        end;
        onsetLag= abs(onsetTimeTemp-trigTimesConGainApe(indFoundApe))/30
        if onsetLag>200
            warning('onset lag is larger than 200ms');
        end;
        fprintf(['lag on onset is: ' num2str(onsetLag) ]);
        timeTrigStartTemp=trigTimesConGainApe(indFoundApe);

        indFoundAch=find(trigTimesConGainAch>ofsetTimeTemp,1,'first');
        if length(indFoundAch)==0
            indFoundAch=find(trigTimesConGainAch<ofsetTimeTemp,1,'last');
        end;
        if indFoundAch==1;
            indFoundAch=2;
        end;
        if abs((trigTimesConGainAch(indFoundAch)-ofsetTimeTemp))>abs((trigTimesConGainAch(indFoundAch-1)-ofsetTimeTemp))
            indFoundAch=indFoundAch-1;
        end;

        indFoundMis=find(trigTimesConGainMis>ofsetTimeTemp,1,'first');
        if length(indFoundMis)==0
            indFoundMis=find(trigTimesConGainMis<ofsetTimeTemp,1,'last');
        end;
        if indFoundMis==1;
            indFoundMis=2;
        end;
        if con==4
            sf=3;
        end;
        if abs((trigTimesConGainMis(indFoundMis)-ofsetTimeTemp))>abs((trigTimesConGainMis(indFoundMis-1)-ofsetTimeTemp))
            indFoundMis=indFoundMis-1;
        end;

        if abs((trigTimesConGainAch(indFoundAch)-ofsetTimeTemp))>abs((trigTimesConGainMis(indFoundMis)-ofsetTimeTemp))

            timeTrigEndTemp=trigTimesConGainMis(indFoundMis);
        else
            timeTrigEndTemp=trigTimesConGainAch(indFoundAch);
        end;
        ofsetLag=abs(ofsetTimeTemp-timeTrigEndTemp)/30
        fprintf(['lag on ofset is: ' num2str(ofsetLag) ]);
        if ofsetLag>200
            warning('ofset lag is larger than 200ms');
        end;

        eval(['NevTimesAllUpdated.' conditions{con} '(i,1)=timeTrigStartTemp;']);
        eval(['NevTimesAllUpdated.' conditions{con} '(i,2)=timeTrigEndTemp;']);
        
    end;
end;





    

    



    
    