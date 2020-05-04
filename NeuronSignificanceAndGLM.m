function [neuronsPerArea,signifAll,signifPercMatrix,signifPercAdd,signifContrastAll,signifToPreAppearAll,signifToPreAppearPerc,signifContrastAllClas,posUnits,negUnits,meansContrast,meansContrastNoMove]=NeuronSignificanceAndGLM(PSTHstruct,relevantRegions,relevantAtlasLabels,saveToFileName)
%%% this function is supposed to take PSTHstructure containing all the
%%% spikes and given a set of conditions and time windows to say which
%%% neurons are responsive for each area. before you begin you need to load
%%% the PSTH structure and the neuronsPerArea cell array
% PSTHstruct=PSTH8recs;

atlasLabels=[PSTHstruct.atlasLabel];
plotting=1;
for i=1:length(relevantRegions)
    relevantLabel=relevantAtlasLabels{i};
    neuronsPerArea{i}=[];
    for j=1:length(relevantLabel)
        neuronsPerArea{i}=[neuronsPerArea{i} find(atlasLabels==relevantLabel(j))];
    end;
    neuronsPerArea{i}=sort(neuronsPerArea{i},'ascend');
    NneuronsPerArea(i)=length(neuronsPerArea{i});
end;
    

% saveToFileName='M:\Intracranial\ParadigmAnalysis\Cartman\PSTHclustering\June2016\Results\figures\AppearCondsOutliers'
Nunits=length(PSTHstruct)
% Nunits=323;

binSize=200;
MultipleCorrections=0;
Niter=1000; % iterations for bootstrapping
if plotting
    figure;bar(NneuronsPerArea);
    a=gca;
    set(a,'XTickLabel',relevantRegions);
end;
STDsToRemove=0;  
ApearAchieveOrMove='Achieve' % 1 for appear, 2 for achieve and 3 for move
doContrasts=0;
BalanceNforAvoid=1;
% ApearAchieveOrMove='Achieve' % 1 for appear, 2 for achieve and 3 for move
% conds={'ControlledGainAppears','ControlledLoseAppears','UncontrolledGainAppears','UncontrolledLoseAppears'};
% conds={'ControlledGainAppears','ControlledLoseAppears'};

conds={'ControlledGainAchieved','ControlledLossAchieved','UncontrolledGainAchieved','UncontrolledLoseAchieved'};
% conds={'BallsN[oMoney'};
% conds={'ApproachRisk','ApproachNoRisk'}
condsAdd={'loss  con','loss uncon','both'};
% conds={'TimeOfApproachRisk','TimeOfApproachNoRisk'};

% condsAdd={'only risk','only no risk','risk and no risk'};
% condsAdd={'loss control','loss uncontrol', 'loss control and uncontrol'};
contrast=[  99 1 99 -1];
% contrast=0;
movementTimeBaseline=[1 14];
movementTimeBefAft=[15 30];
% movementTimeBaseline=[1 2];
% movementTimeBaseline=[3 4];
wilcoxon=0;
AdditionalConds=[ 99 1 99 -1; 99 -1 99 1 ;99 1 99 1]; % 99 means i dont care
relevantWindows=[17:19]; % appears
comparisonToPreAppearPeriod=1;
windowsOfPreAppearPeriod=[15-length(relevantWindows)-3:14-3]; % take 3 windows to move away from appear
% AdditionalConds=[]; % 99 means i dont care


% relevantWindows=[1:4];% achieve
p=0.01;
if MultipleCorrections 
    pBonferoni=(p/length(conds)/length(relevantWindows)); % craete bonferoni correction for number of conditions and time windows
else 
    pBonferoni=p;
end;

for i=1:length(relevantRegions)
    signifAll{i}=[];
    signifContrastAll{i}=[];
    meansContrast{i}=[];
    meansContrastNoMove{i}=[];
end;
signifPercAdd=[];
% for reg=1:length(relevantRegions) % run on all relevant regions
    for unit=[1:Nunits]
%     for unit=[272:272]

        reg=0;
        windowedBasline=[];baseMatForContrast=[];
        for regInd=1:length(neuronsPerArea) % find which region this neuron belongs to
            if length(find(neuronsPerArea{regInd}==unit))>0
                reg=regInd;
            end;
        end;
      
        fprintf(['unit number ' num2str(unit) '\n']);
        rasterBaseline=PSTHstruct(unit).Appear.ControlledLoseAppears.raster; % take the raster from which you will create the baseline for bootstrapping. curently i use control lose appears which basically has all epochs of the game because the balls are all the time
        
        for line=1:size(rasterBaseline,1)
            windowedBasline(line,:)=bin_spikes(rasterBaseline(line,:),binSize)*(1000/binSize); %  bin and normalize to FR
        end;
        baseMatForContrast=windowedBasline(:,1:length(relevantWindows)); % baseline for contrast and movement
        moveBaselineTemp=PSTHstruct(unit).Appear.ControlledLoseAppears.clicks;  
        baselineMove=mean(moveBaselineTemp(:,movementTimeBaseline),2);
        
        windowedBaslineResh=reshape(windowedBasline,1,size(windowedBasline,1)*size(windowedBasline,2)); % rearrange baseline matrix as vector
        signifCond=[];
        signifToPreAppear=zeros(length(conds),1);
        for cond=1:length(conds)
            rasterTempWindowed=[];
            fprintf(['condition: ' conds{cond} '\n']);

            PSTHtemp=eval(['PSTHstruct(unit).' ApearAchieveOrMove '.' conds{cond} '.PSTH']);
            rasterTemp=eval(['PSTHstruct(unit).' ApearAchieveOrMove '.' conds{cond} '.raster']);
            %%%%%%%%%%%%%% special treatment for approach avoid comparison
            %%%%%%%%%%%%%% because there are many more approach
            if BalanceNforAvoid
                if strcmp(conds{cond},'ApproachRisk')%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    ll=length(PSTHstruct(unit).Appear.AvoidRisk.timesInMS);%%%%%%%%%
                    rasterTempRand=rasterTemp(randperm(size(rasterTemp,1),ll),:);%%%
                    rasterTemp=rasterTempRand;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                end;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end;
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            for line=1:size(rasterTemp,1) % bin the raster
                rasterTempWindowed(line,:)=bin_spikes(rasterTemp(line,:),binSize)*(1000/binSize); %  bin and normalize to FR
            end;
            Ntrials=size(rasterTemp,1);
            for perm=1:Niter
                randTemp=randperm(length(windowedBaslineResh),Ntrials); % choose random windows from baseline
                randCurrent=windowedBaslineResh(randTemp);
                med=median(randCurrent);s=std(randCurrent);
                if STDsToRemove>0 % deal with outliers
                    med=median(randCurrent);s=std(randCurrent);
                    outlierOver=find(randCurrent>(med+s*STDsToRemove));
                    outlierUnder=find(randCurrent<(med-s*STDsToRemove));
                    randCurrent([outlierUnder,outlierOver])=[];
                end;
                baselineBoot(perm)=mean(randCurrent); % average the FR of the random windows
            end;
             eval(['PSTHstruct(unit).' ApearAchieveOrMove '.' conds{cond} '.Boot.p=' num2str(p) ';']);
             eval(['PSTHstruct(unit).' ApearAchieveOrMove '.' conds{cond} '.Boot.windows=[' num2str(relevantWindows) '];']);
             NeuronReacts=zeros(1,length(relevantWindows));   
             
             
             if contrast(cond)==1 % if you want to take this condition in the contrast
               cond1mat=rasterTempWindowed(:,relevantWindows);  
               moveTemp=eval(['PSTHstruct(unit).' ApearAchieveOrMove '.' conds{cond} '.clicks']);  
               cond1mov=mean(moveTemp(:,movementTimeBefAft),2);
               
             end;
             if contrast(cond)==-1 % if you want to take this condition in the contrast
               cond2mat=rasterTempWindowed(:,relevantWindows);  
               moveTemp=eval(['PSTHstruct(unit).' ApearAchieveOrMove '.' conds{cond} '.clicks']);  
               cond2mov=mean(moveTemp(:,movementTimeBefAft),2);
             end;
             for wind=1:length(relevantWindows)
                FRcurrent = rasterTempWindowed(:,relevantWindows(wind));
                if STDsToRemove>0 % deal with outliers
                    med=median(FRcurrent);s=std(FRcurrent);
                    outlierOver=find(FRcurrent>(med+s*STDsToRemove));
                    outlierUnder=find(FRcurrent<(med-s*STDsToRemove));
                    FRcurrent([outlierUnder,outlierOver])=[];
                    fprintf(['for unit ' num2str(unit) ' condition ' conds{cond} ' there are ' num2str(length(outlierUnder)+ length(outlierOver)) ' outliers\n' ]);
                end;
                 
                if (length(find(baselineBoot<=nanmean(FRcurrent)))/Niter)<pBonferoni % if the percentage of iterations that have a lower value than the actual is less than p
                    NeuronReacts(wind)=-1; % i changed < to <= to deal with low FR units where that are a lot of zeros
                end;
                if (length(find(baselineBoot<nanmean(FRcurrent)))/Niter)>(1-pBonferoni)
                    NeuronReacts(wind)=1;
                end;
                
                if comparisonToPreAppearPeriod % simple wilcoxon
                FRcurrentPreAppear = rasterTempWindowed(:,windowsOfPreAppearPeriod(wind));
                pDirectToPreAppear = ranksum(FRcurrent,FRcurrentPreAppear)
                if pDirectToPreAppear<pBonferoni
                    signifToPreAppear(cond,1)=1;
                end;
                
            end;
                
            end;
            
            if length(find(NeuronReacts==0))==length(relevantWindows)
                signifCond(cond,1)=0;
            else
                if sum(NeuronReacts)==0 % in the case there are the same amount of significant pluses and minuses
                    signifCond(cond,1)=1;
                else
                    signifCond(cond,1)=sign(sum(NeuronReacts));
                end;
            end;
            eval(['PSTHstruct(unit).' ApearAchieveOrMove '.' conds{cond} '.Boot.sig=' num2str(signifCond(cond,1)) ';'])
        end;
        signifContrast=0;signifContrastClas=0;
        cond1NoMove=[];cond2NoMove=[];baselineNoMove=[];
        if doContrasts
            for win=1:length(relevantWindows) % back to the contrast buisness
                [signifTemp,signifClasTemp,baselineNoMove(:,win),cond1NoMove(:,win),cond2NoMove(:,win),X,Y,B,yfit]=GLMextractMovement(baseMatForContrast(:,win),baselineMove,cond1mat(:,win),cond1mov,cond2mat(:,win),cond2mov,wilcoxon,pBonferoni);
                if signifTemp~=0;
                   signifContrast=signifTemp;
                end;
                if signifClasTemp~=0;
                   signifContrastClas=signifClasTemp;
                end;
            end;

            if signifTemp~=0; % to determine which condition is higher
               signifContrast=sign(mean(cond1mat(:))-mean(cond2mat(:)));
            end;
            if signifClasTemp~=0;
              signifContrastClas=sign(mean(cond1mat(:))-mean(cond2mat(:)));
            end;
        else
            cond1mat=[];
            cond2mat=[];
        end;
        if reg>0
            signifToPreAppearAll{reg}(1:length(conds),size(signifAll{reg},2)+1)=signifToPreAppear;
            signifAll{reg}(:,size(signifAll{reg},2)+1)=signifCond;
            signifContrastAll{reg}(length(signifAll{reg})+1)=signifContrast;
            signifContrastAllClas{reg}(length(signifAll{reg})+1)=signifContrastClas;
            meansContrast{reg}(:,size(meansContrast{reg},2)+1)=[mean(windowedBaslineResh);mean(cond1mat(:));mean(cond2mat(:))];
            meansContrastNoMove{reg}(:,size(meansContrastNoMove{reg},2)+1)=[mean(baselineNoMove(:));mean(cond1NoMove(:));mean(cond2NoMove(:))];
            cond1NoMove=[];cond2NoMove=[];

        end;
        
    end;
    for regInd=1:length(relevantRegions)
        sigAbs=abs(signifAll{regInd});
        signifPerc{regInd}=sum(sigAbs,2)/NneuronsPerArea(regInd);
        signifToPreAppearPerc{regInd}=sum(abs(signifToPreAppearAll{regInd}),2)/NneuronsPerArea(regInd);
        for i=1:size(AdditionalConds,1)
            mustCond=find(AdditionalConds(i,:)==1);
            mustNotCond=find(AdditionalConds(i,:)==0);
            if length(mustNotCond)>0
                signifPercAdd(i,regInd)=sum(prod(sigAbs(mustCond,:),1).*prod(~sigAbs(mustNotCond,:),1))/NneuronsPerArea(regInd);
            else
                signifPercAdd(i,regInd)=sum(prod(sigAbs(mustCond,:),1))/NneuronsPerArea(regInd);
            end;
        end;
        signifPercMatrix(:,regInd)=signifPerc{regInd};
        poss=find(sign(sum(signifAll{regInd})));
        negs=find(sign(sum(signifAll{regInd}))<0);
        posUnits{regInd}=neuronsPerArea{regInd}(poss);
        negUnits{regInd}=neuronsPerArea{regInd}(negs);
        PSTHposLoss=[];PSTHposGain=[];PSTHnegLoss=[];PSTHnegGain=[];
        for i=1:length(posUnits{regInd})
            PSTHposLoss(i,:)=zscore(PSTHstruct(posUnits{regInd}(i)).Achieve.ControlledLossAchieved.PSTH);
            PSTHposGain(i,:)=zscore(PSTHstruct(posUnits{regInd}(i)).Achieve.ControlledGainAchieved.PSTH);
        end;
        for i=1:length(negUnits{regInd})
            PSTHnegLoss(i,:)=zscore(PSTHstruct(negUnits{regInd}(i)).Achieve.ControlledLossAchieved.PSTH);
            PSTHnegGain(i,:)=zscore(PSTHstruct(negUnits{regInd}(i)).Achieve.ControlledGainAchieved.PSTH);
        end;
        PSTH(regInd).PSTHposLoss=PSTHposLoss;
        PSTH(regInd).PSTHposGain=PSTHposGain;
        PSTH(regInd).PSTHnegLoss=PSTHnegLoss;
        PSTH(regInd).PSTHnegGain=PSTHnegGain;
        
    end;
save(saveToFileName,'signifAll','signifPercMatrix','signifPercAdd','signifToPreAppearPerc','signifContrastAll','signifContrastAllClas','signifToPreAppearAll','conds','AdditionalConds','meansContrast','meansContrastNoMove');
% end;
if plotting 
    f=figure; 
    subplot(3,1,1);
    bar(signifPercMatrix');
    a=gca;
    set(a,'XTickLabel',relevantRegions);
    legend(conds);
    
    subplot(3,1,2);
    bar(signifPercMatrix);
    a=gca;
    set(a,'XTickLabel',conds);
    legend(relevantRegions);
    
     subplot(3,1,3);
    bar(signifPercAdd');
    a=gca;
    set(a,'XTickLabel',relevantRegions);
    legend(condsAdd);
    
    saveas(f,[saveToFileName ],'fig');

     
end;


        
    
    
                       
                    
            
            
