function [SelectingNeuronResults]=SelectingNeurons(PSTH,signifAll,neuronsPerArea,condSelect,outputFileName)
% this function takes the signif all output of NeuronSignificance and GLM
% and craetes a structure with the (normalized) neural activation. 
% the output structure has 4 fields:
% upNeuron - a list of neurons with a significant increase in FR per area
% upNeuronPSTH - the FR calculated in 200ms bins per neuron (increasing),time relative to outcome/cue, condition
% upNeuron - a list of neurons with a significant decrease in FR per area
% upNeuronPSTH - the FR calculated in 200ms bins per neuron (decreasing),time relative to outcome/cue, condition

% structure SelectingNeuronResults
% condSelect should be 0 if you want to choose selective neurons from all
% conditions, otherwise it will get the condition number from which you want to
% take only selective neurons
binSize=200;
plotting=1;
condN=4;
normalize=1;
outlierRejectB=0;
saving=1;

for reg=1:length(signifAll) % run on all regions
    neuronsPerAreaSorted{reg}=sort(neuronsPerArea{reg},'ascend');
    signifArea=signifAll{reg}; 
    if condSelect==0
        ups=sum((signifArea==1));% sum across conditions neurons which were positive
        downs=sum((signifArea==-1)); % sum across conditions neurons which were negative
        upNeurons{reg}=neuronsPerAreaSorted{reg}(find((ups>0).*(downs==0))); %% neurons which were only positive
        downNeurons{reg}=neuronsPerAreaSorted{reg}(find((ups==0).*(downs>0))); %% neurons which were only negative
        mixedNeurons{reg}=neuronsPerAreaSorted{reg}(find((ups>0).*(downs>0))); % neurons which wre mixed across conditions
    else
        upNeurons{reg}=neuronsPerAreaSorted{reg}(find(signifArea(condSelect,:)>0)); %% neurons which were only positive
        downNeurons{reg}=neuronsPerAreaSorted{reg}(find(signifArea(condSelect,:)<0)); %% neurons which were only positive
        mixedNeurons{reg}=[];
    end;
    for i=1:length(upNeurons{reg})

        temp=PSTH(upNeurons{reg}(i)).Achieve.ControlledGainAchieved.PSTH;
        tempBaseline=rasterToPSTH(PSTH(upNeurons{reg}(i)).Appear.ControlledLoseAppears.raster,length(PSTH(upNeurons{reg}(i)).Achieve.ControlledGainAchieved.timesInMS),binSize);
        if normalize
            temp=(temp-mean(tempBaseline(1:13)))/std(tempBaseline(1:13));
        end;
        upNeuronPSTH{reg}(i,1,:)=temp;
        
        temp=PSTH(upNeurons{reg}(i)).Achieve.ControlledLossAchieved.PSTH;
        tempBaseline=rasterToPSTH(PSTH(upNeurons{reg}(i)).Appear.ControlledLoseAppears.raster,length(PSTH(upNeurons{reg}(i)).Achieve.ControlledLossAchieved.timesInMS),binSize);
        if normalize
            temp=(temp-mean(tempBaseline(1:13)))/std(tempBaseline(1:13));
        end;
        upNeuronPSTH{reg}(i,2,:)=temp;
        
        
        
        temp=PSTH(upNeurons{reg}(i)).Achieve.UncontrolledGainAchieved.PSTH;
        tempBaseline=rasterToPSTH(PSTH(upNeurons{reg}(i)).Appear.ControlledLoseAppears.raster,length(PSTH(upNeurons{reg}(i)).Achieve.UncontrolledGainAchieved.timesInMS),binSize);
        if normalize
            temp=(temp-mean(tempBaseline(1:13)))/std(tempBaseline(1:13));
        end;
        upNeuronPSTH{reg}(i,3,:)=temp;  
        
        temp=PSTH(upNeurons{reg}(i)).Achieve.UncontrolledLoseAchieved.PSTH;
        tempBaseline=rasterToPSTH(PSTH(upNeurons{reg}(i)).Appear.ControlledLoseAppears.raster,length(PSTH(upNeurons{reg}(i)).Achieve.UncontrolledLoseAchieved.timesInMS),binSize);
        if normalize
            temp=(temp-mean(tempBaseline(1:13)))/std(tempBaseline(1:13));
        end;
        upNeuronPSTH{reg}(i,4,:)=temp;
    end;
      for i=1:length(downNeurons{reg})
        temp=PSTH(downNeurons{reg}(i)).Achieve.ControlledGainAchieved.PSTH;
        tempBaseline=rasterToPSTH(PSTH(downNeurons{reg}(i)).Appear.ControlledLoseAppears.raster,length(PSTH(downNeurons{reg}(i)).Achieve.ControlledGainAchieved.timesInMS),binSize);
        downNeuronPSTH{reg}(i,1,:)=(temp-mean(tempBaseline(1:13)))/std(tempBaseline(1:13));
        
        temp=PSTH(downNeurons{reg}(i)).Achieve.ControlledLossAchieved.PSTH;
        tempBaseline=rasterToPSTH(PSTH(downNeurons{reg}(i)).Appear.ControlledLoseAppears.raster,length(PSTH(downNeurons{reg}(i)).Achieve.ControlledLossAchieved.timesInMS),binSize);
        downNeuronPSTH{reg}(i,2,:)=(temp-mean(tempBaseline(1:13)))/std(tempBaseline(1:13));
        
        temp=PSTH(downNeurons{reg}(i)).Achieve.UncontrolledGainAchieved.PSTH;
        tempBaseline=rasterToPSTH(PSTH(downNeurons{reg}(i)).Appear.ControlledLoseAppears.raster,length(PSTH(downNeurons{reg}(i)).Achieve.UncontrolledGainAchieved.timesInMS),binSize);
        downNeuronPSTH{reg}(i,3,:)=(temp-mean(tempBaseline(1:13)))/std(tempBaseline(1:13));
        
        temp=PSTH(downNeurons{reg}(i)).Achieve.UncontrolledLoseAchieved.PSTH;
        tempBaseline=rasterToPSTH(PSTH(downNeurons{reg}(i)).Appear.ControlledLoseAppears.raster,length(PSTH(downNeurons{reg}(i)).Achieve.UncontrolledLoseAchieved.timesInMS),binSize);        
        downNeuronPSTH{reg}(i,4,:)=(temp-mean(tempBaseline(1:13)))/std(tempBaseline(1:13));
    end;

end;
downNeuronPSTHUpdated=downNeuronPSTH;
if plotting
    for reg=1:length(signifAll)  % plotting ups 
        figure;
        if outlierRejectB
            upNeuronPSTHUpdated{reg}=outlierReject(upNeuronPSTH{reg});
        else
            upNeuronPSTHUpdated=upNeuronPSTH;
        end;
        if size(upNeuronPSTHUpdated{reg},1)==1
            meanUp=squeeze(upNeuronPSTHUpdated{reg}(:,:,:));
        else
            meanUp=squeeze(nanmean(upNeuronPSTHUpdated{reg}(:,:,:)));
        end;
        
        stErrUp=squeeze(nanstd(upNeuronPSTHUpdated{reg}(:,:,:))./sqrt(size(upNeuronPSTHUpdated{reg},1)));
        colors={[0 200 0]/256,[255 0 0]/256,[0 255 255]/256,[255 100 255]/256,[0 256 256 ]/256};
        if  ~isnan(meanUp)
            for cond=1:condN
                hold on;
                x=[-2900:200:4900];
                x=x/1000;
                y=meanUp(cond,:);
                err=stErrUp(cond,:);

                    pp=patch([x fliplr(x)],[y+err fliplr(y-err)],colors{cond},'FaceAlpha',0.25,'LineStyle','none');

                plot(x,meanUp(cond,:),'Color',colors{cond},'LineWidth',3);
    %             legend({'Control Gain','Control Loss','UnControlGain','UncontrolLoss'})
        %         plot(meanUp(cond,:)+stErrUp(cond,:),['.' colors{cond}]); plot(meanUp(cond,:)-stErrUp(cond,:),['.' colors{cond}])
            end;
        end;
        meanUpReg{reg}=meanUp;
        stErrUpReg{reg}=stErrUp;
        xlabel('time(s)');
        ylabel('stds');
        a=gca;
        set(a,'FontSize',16);
        set(a,'FontWeight','bold');
        saveas(gcf, [outputFileName '_area' num2str(reg) '_ups' ], 'fig')
        saveas(gcf, [outputFileName '_area' num2str(reg) '_ups' ], 'tif')
        saveas(gcf, [outputFileName '_area' num2str(reg) '_ups' ], 'jpg')


        %title(['up area ' num2str(reg)]);
    end;
    
    
    %% ploting one condition different regions
    
    
    figure;
    for cond=1:condN
                hold on;
                x=[-2900:200:4900];
                x=x/1000;
                for reg=1:length(signifAll)
                    FRperArea(reg,:)=meanUpReg{reg}(cond,:);
                    FRerr(reg,:)=stErrUpReg{reg}(cond,:);
                    subplot(2,2,cond)
                hold on;
                    pp=patch([x(14:20) fliplr(x(14:20))],[FRperArea(reg,14:20)+FRerr(reg,14:20) fliplr(FRperArea(reg,14:20)-FRerr(reg,14:20))],colors{reg},'FaceAlpha',0.25,'LineStyle','none');
                    plot(x(14:20),FRperArea(reg,14:20),'Color',colors{reg},'LineWidth',2);
                end;

   end;
         saveas(gcf, [outputFileName '_area' num2str(reg) '_timing' ], 'fig');

            
            
            
            
            
    for reg=1:length(signifAll)  % plotting downs 
        figure;
        if outlierRejectB
            downNeuronPSTHUpdated{reg}=outlierReject(downNeuronPSTH{reg});
        else
            downNeuronPSTHUpdated=downNeuronPSTH;
        end;
        meanDown=squeeze(nanmean(downNeuronPSTHUpdated{reg}(:,:,:)))
        stErrDown=squeeze(nanstd(downNeuronPSTHUpdated{reg}(:,:,:))./sqrt(size(downNeuronPSTHUpdated{reg},1)));
        colors={[0 200 0]/256,[255 0 0]/256,[0 255 255]/256,[255 100 255]/256};
        if  ~isnan(meanDown)
            for cond=1:condN
                hold on;
                x=[-2900:200:4900];
                x=x/1000;
                y=meanDown(cond,:);
                err=stErrDown(cond,:);
               
                    pp=patch([x fliplr(x)],[y+err fliplr(y-err)],colors{cond},'FaceAlpha',0.25,'LineStyle','none');

                plot(x,meanDown(cond,:),'Color',colors{cond},'LineWidth',3);

            end;
        end;
        xlabel('time(s)');
        ylabel('stds');
        a=gca;
        set(a,'FontSize',16);
        set(a,'FontWeight','bold');
        %title(['down area ' num2str(reg)]);
        saveas(gcf, [outputFileName '_area' num2str(reg) '_downs' ], 'fig')
        saveas(gcf, [outputFileName '_area' num2str(reg) '_downs' ], 'tif')
        saveas(gcf, [outputFileName '_area' num2str(reg) '_downs' ], 'jpg')

    end;
    
end;
SelectingNeuronResults.upNeurons=upNeurons;
SelectingNeuronResults.downNeurons=downNeurons;
SelectingNeuronResults.mixedNeurons=mixedNeurons;
SelectingNeuronResults.upNeuronPSTH=upNeuronPSTH;
SelectingNeuronResults.downNeuronPSTH=downNeuronPSTH;
SelectingNeuronResults.downNeuronPSTHUpdated=downNeuronPSTHUpdated;
if saving
    save(outputFileName,'SelectingNeuronResults');
end;




function PSTHout=rasterToPSTH(raster,NofRandomTrials,binSize) % bins the raster to PSTH taking only NofRandomTrials
        trialsN=size(raster,1);
        for line=1:trialsN % bin the raster
            windowedRaster(line,:)=bin_spikes(raster(line,:),binSize)*(1000/binSize); %  bin and normalize to FR
        end;
        if nargin>1
           PSTHout=mean(windowedRaster);% average trials to PSTH
        else
           trialsToTake=randperm(trialsN,NofRandomTrials); % indexes of trials to take
           PSTHout=mean(windowedRaster(trialsToTake,:)); % average trials to PSTH
        end;
        
function  upNeuronPSTHUpdated=outlierReject(upNeuronPSTH)
        for i=1:size(upNeuronPSTH,2) % conditions
            upNeuronPSTHcond=squeeze(upNeuronPSTH(:,i,:));
            low=repmat(prctile(upNeuronPSTHcond,5),size(upNeuronPSTH,1),1);
            high=repmat(prctile(upNeuronPSTHcond,95),size(upNeuronPSTH,1),1);
            m=repmat(mean(upNeuronPSTHcond),size(upNeuronPSTH,1),1);
            [r]=find((upNeuronPSTHcond<low)|(upNeuronPSTHcond>high));
            upNeuronPSTHcondResh=reshape(upNeuronPSTHcond,size(upNeuronPSTHcond(:),1),1);
            upNeuronPSTHcondResh(r)=nan(length(r),1);
            upNeuronPSTHUpdated(:,i,:)=reshape(upNeuronPSTHcondResh,size(upNeuronPSTH,1),size(upNeuronPSTH,3))
            
        end;
           



