function [analysisdata cumulativedata] = physAnalysis(stimManager,spikeRecord,stimulusDetails,plotParameters,parameters,cumulativedata,eyeData)
% stimManager is the stimulus manager
% spikes is a logical vector of size (number of neural data samples), where 1 represents a spike happening
% frameIndices is an nx2 array of frame start and stop indices - [start stop], n = number of frames
% stimulusDetails are the stimDetails from calcStim (hopefully they contain all the information needed to reconstruct stimData)
% photoDiode - currently not used
% plotParameters - currently not used



%% common - should put in util function for all physAnalysis
analysisdata=[]; %nothing passed out
cumulativedata=[]; % not used yet, wipe out whatever data we get

% %CHOOSE CLUSTER
% spikes=spikeRecord.spikes; %all waveforms
% waveInds=find(spikes); % location of all waveforms
% if isstruct(spikeData.spikeDetails) && ismember({'processedClusters'},fields(spikeData.spikeDetails)) 
%     thisCluster=spikeData.spikeDetails.processedClusters==1;
% else
%     thisCluster=logical(ones(size(waveInds)));
%     %use all (photodiode uses this)
% end
% spikes(waveInds(~thisCluster))=0; % set all the non-spike waveforms to be zero;
% %spikes(waveInds(spikeData.assig
% 
% %SET UP RELATION stimInd <--> frameInd
% analyzeDrops=true;
% if analyzeDrops
%     stimFrames=spikeData.stimIndices;
%     frameIndices=spikeData.frameIndices;
% else
%     numStimFrames=max(spikeData.stimIndices);
%     stimFrames=1:numStimFrames;
%     firstFramePerStimInd=~[0 diff(spikeData.stimIndices)==0];
%     frameIndices=spikeData.frameIndices(firstFramePerStimInd);
% end

%SET UP RELATION stimInd <--> frameInd
analyzeDrops=true;
if analyzeDrops
    stimFrames=spikeRecord.stimInds;
    correctedFrameIndices=spikeRecord.correctedFrameIndices;
else
    numStimFrames=max(spikeRecord.stimInds);
    stimFrames=1:numStimFrames;
    firstFramePerStimInd=~[0; diff(spikeRecord.stimInds)==0];
    correctedFrameIndices=spikeRecord.correctedFrameIndices(firstFramePerStimInd);
end

%CHOOSE CLUSTER
allSpikes=spikeRecord.spikes; %all waveforms
waveInds=allSpikes; % location of all waveforms
if isstruct(spikeRecord.spikeDetails) && ismember({'processedClusters'},fields(spikeRecord.spikeDetails))
    try
    if length([spikeRecord.spikeDetails.processedClusters])~=length(waveInds)
        length([spikeRecord.spikeDetails.processedClusters])
        length(waveInds)
        error('spikeDetails does not correspond to the spikeRecord''s spikes');
    end
    catch ex
        warning('oops')
       keyboard 
    end
    thisCluster=[spikeRecord.spikeDetails.processedClusters]==1;
else
    thisCluster=logical(ones(size(waveInds)));
    %use all (photodiode uses this)
end

viewSort=false;
if viewSort
    figure
    plot(spikeRecord.spikeWaveforms([spikeRecord.spikeDetails.processedClusters]~=1,:)','color',[0.2 0.2 0.2]);  hold on
    plot(spikeRecord.spikeWaveforms(find([spikeRecord.spikeDetails.processedClusters]==1),:)','r');
end

spikes=allSpikes;
spikes(~thisCluster)=[]; % remove spikes that dont belong to thisCluster

s=setStimFromDetails(stimManager, stimulusDetails);
[targetIsOn flankerIsOn effectiveFrame cycleNum sweptID repetition]=isTargetFlankerOn(s,stimFrames);

viewTypeAndDrop=sum(diff(stimFrames)==0)>0;
if viewTypeAndDrop
    dropFraction=conv([diff(stimFrames)==0; 0],ones(1,100));
   
    figure
    subplot(6,1,1); plot(effectiveFrame)
    subplot(6,1,2); plot(stimFrames)
    %subplot(6,1,3); plot(cycleNum)
    subplot(6,1,3); plot(dropFraction)
     ylabel(sprintf('drops: %d',sum(diff(stimFrames)==0)))
    subplot(6,1,4); plot(sweptID)
    subplot(6,1,5); plot(repetition)
    subplot(6,1,6); plot(targetIsOn)
    %warning ('paused!')
    %keyboard
end

    %old way is empirically
%samplingRate=round(diff(minmax(find(spikeData.spikes)'))/ diff(spikeData.spikeTimestamps([1 end])));
samplingRate=parameters.samplingRate;

ifi=1/stimulusDetails.hz;      %in old mode used to be same as empiric (diff(spikeData.frameIndices'))/samplingRate;
ifi2=1/parameters.refreshRate; %parameters.refreshRate might be wrong, so check it
if (abs(ifi-ifi2)/ifi)>0.01  % 1 percent error tolerated
    ifi
    ifi2
    er=(abs(ifi-ifi2)/ifi)
    error('refresh rate doesn''t agree!')
end

% count the number of spikes per frame
% spikeCount is a 1xn vector of (number of spikes per frame), where n = number of frames
spikeCount=zeros(1,size(correctedFrameIndices,1));
for i=1:length(spikeCount) % for each frame
    spikeCount(i)=length(find(spikes>=correctedFrameIndices(i,1)&spikes<=correctedFrameIndices(i,2)));
    %spikeCount(i)=sum(spikes(frameIndices(i,1):frameIndices(i,2)));  % inclusive?  policy: include start & stop
end


%%

swept=s.dynamicSweep.sweptParameters;
%assemble a vector struct per frame (like per trial)
d.date=correctedFrameIndices(:,1)'/(samplingRate*60*60*24); %define field just to avoid errors
for i=1:length(swept)
    switch swept{i}
        case {'targetContrast','flankerContrast'}
            d.(swept{i})=s.dynamicSweep.sweptValues(i,sweptID);
        case 'targetOrientations'
            d.targetOrientation=s.dynamicSweep.sweptValues(i,sweptID);
        case 'flankerOrientations'
            d.flankerOrientation=s.dynamicSweep.sweptValues(i,sweptID);
        case 'phase'
            d.targetPhase=s.dynamicSweep.sweptValues(i,sweptID);
            d.flankerPhase=d.targetPhase;
        otherwise
            d.(swept{i})= s.dynamicSweep.sweptValues(i,sweptID);
    end
end

%get the condition inds depending on what was swept
if any(strcmp(swept,'targetOrientations'))...
        && any(strcmp(swept,'flankerOrientations'))...
        && any(strcmp(swept,'flankerPosAngle'))...
        && any(strcmp(swept,'phase'))...
        && size(swept,2)==4; 
    conditionType='colin+3';
    [conditionInds conditionNames haveData colors]=getFlankerConditionInds(d,[],conditionType);
    colors(2,:)=colors(3,:); % both pop-outs the same
    colors(4,:)=[.5 .5 .5]; % grey not black
% elseif any(strcmp(swept,'targetContrast'))...
%     && any(strcmp(swept,'flankerContrast'))...
%     && size(swept,2)==2; 
% 
%     %flanker contrast only right now...
%     [conditionInds conditionNames haveData colors]=getFlankerConditionInds(d,[],'fiveFlankerContrastsFullRange');

%     
elseif any(strcmp(swept,'targetOrientations'))...
        && any(strcmp(swept,'phase'))...
        && size(swept,2)==2;
    conditionType='allTargetOrientationAndPhase';
      [conditionInds conditionNames haveData colors]=getFlankerConditionInds(d,[],conditionType);
else
    
    %default to each unique
    conditionsInds=zeros(max(sweptID),length(stimFrames));
    allSweptIDs=unique(sweptID);
    for i=1:length(allSweptIDs)
        conditionInds(i,:)=sweptID==allSweptIDs(i);
        conditionNames{i}=num2str(i);
    end
    colors=jet(length(allSweptIDs));
end

numConditions=size(conditionInds,1); % regroup as flanker conditions
numRepeats=max(repetition);
numUniqueFrames=max(effectiveFrame);
frameDurs=(correctedFrameIndices(:,2)-correctedFrameIndices(:,1))'/samplingRate;
%% set the values into the conditions
f=fields(d);
for i=1:numConditions
    for j=1:length(f)
        firstInstance=min(find(conditionInds(i,:)));
        value=d.(f{j})(firstInstance);
        if isempty(value)
            value=nan;
        end
        c.(f{j})(i)=value;
    end
end
%%
events=nan(numRepeats,numConditions,numUniqueFrames);
possibleEvents=events;
photodiode=events;
rasterDensity=ones(numRepeats*numConditions,numUniqueFrames)*0.1;
p2=rasterDensity;
tOn2=rasterDensity;
fprintf('%d repeats',numRepeats)
for i=1:numRepeats
    fprintf('.%d',i)
    for j=1:numConditions
        for k=1:numUniqueFrames
            which=find(conditionInds(j,:)' & repetition==i & effectiveFrame==k);
            events(i,j,k)=sum(spikeCount(which));
            possibleEvents(i,j,k)=length(which);
            %[i j k]
            photodiode(i,j,k)=mean(spikeRecord.photoDiode(which))/sum(frameDurs(which));;
            %             if photodiode(i,j,k)==theNumber
            %                 which
            %             end
            if isempty(which)
                [i j k]
                warning('should be at least 1!')
            end
            tOn(i,j,k)=mean(targetIsOn(which)>0.5);
            %in last repeat density = 0, for parsing and avoiding misleading half data
            if numRepeats~=i
                y=(j-1)*(numRepeats)+i;
                rasterDensity(y,k)=events(i,j,k)/possibleEvents(i,j,k);
                p2(y,k)=photodiode(i,j,k);
                tOn2(y,k)=tOn(i,j,k);
            end
        end
    end
end



%compare to the targets presence that I think I put out
%targetIsOnThatFit=targetIsOn(1:(numRepeats*numConditions*numUniqueFrames)); % why do I need to do this?
%targetIsOnMatrix=reshape(targetIsOnThatFit>0.5,numUniqueFrames,[])';
%xtra=targetIsOn((numRepeats*numConditions*numUniqueFrames)+1:end)

%%

rasterDensity(isnan(rasterDensity))=0;
p2(p2==0.1)=mean(p2(:)); p2(1)=mean(p2(:));  % a known problem from drops


figure; 
subplot(2,1,1); imagesc(rasterDensity);  colormap(gray);
%subplot(2,2,2); imagesc(targetIsOnMatrix);
subplot(2,1,2); plot(mean(rasterDensity)); set(gca,'xLim',[0 numUniqueFrames])
%subplot(2,2,4); plot(mean(targetIsOnMatrix)); set(gca,'xLim',[0 numUniqueFrames])
xlabel(sprintf('spikes: %d',sum(spikeCount)))

% figure
%  subplot(2,2,1); imagesc(p2);  colormap(gray); %title('why is this different?')
%  subplot(2,2,2); imagesc(tOn2); 
%  subplot(2,2,3); plot(mean(p2)); set(gca,'xLim',[0 numUniqueFrames])
%  subplot(2,2,4); plot(mean(tOn2)); set(gca,'xLim',[0 numUniqueFrames])
%  xlabel(sprintf('spikes: %d',sum(spikeCount)))
%%
figure
subplot(1,2,1); imagesc(p2);  colormap(gray); 
subplot(1,2,2); plot(mean(p2)); set(gca,'xLim',[0 numUniqueFrames])
%axis([0 35 80 150])
%% 


% if ~isempty(eyeData)
%     [px py crx cry]=getPxyCRxy(eyeData);
%     eyeSig=[crx-px cry-py];
%     eyeSig(end,:)=[]; % remove last ones to match (not principled... what if we should throw out the first ones?)
%     
%     if length(unique(eyeSig(:,1)))>10 % if at least 10 x-positions   
%         regionBoundsXY=[1 .5]; % these are CRX-PY bounds of unknown degrees
%         [within ellipses]=selectDenseEyeRegions(eyeSig,1,regionBoundsXY);  
%     else
%         disp(sprintf('no good eyeData on trial %d',parameters.trialNumber))
%     end
% end
%%
fullRate=events./(possibleEvents*ifi);
fullPhotodiode=photodiode(2:end,:,:);
rate=reshape(sum(events)./(sum(possibleEvents)*ifi),numConditions,numUniqueFrames); % combine repetitions

if numRepeats>2
    rateSEM=reshape(std(events(1:end-1,:,:)./(possibleEvents(1:end-1,:,:)*ifi)),numConditions,numUniqueFrames)/sqrt(numRepeats-1);
    photodiodeSEM=reshape(std(photodiode(1:end-1,:,:)),numConditions,numUniqueFrames)/sqrt(numRepeats-1);
else
    rateSEM=nan(size(rate));
    photodiodeSEM=nan(size(rate));
end

noStimDur=min([s.targetOnOff s.flankerOnOff]);
shift=floor(noStimDur/2);
shiftedFrameOrder=[(1+shift):numUniqueFrames  1:shift];

%%
photodiode=reshape(mean(photodiode(2:end,:,:),1),numConditions,numUniqueFrames); % combine repetitions
%%
%reshapeRate but half the means screen in front and half behind
% maybe do this b4 on all of them
rate=rate(:,shiftedFrameOrder);
rateSEM=rateSEM(:,shiftedFrameOrder);
rasterDensity=rasterDensity(:,shiftedFrameOrder);
fullPhotodiode=fullPhotodiode(:,:,shiftedFrameOrder);
photodiode=photodiode(:,shiftedFrameOrder);
photodiodeSEM=photodiodeSEM(:,shiftedFrameOrder);

figure(parameters.trialNumber); % new for each trial
%set(gcf,'position',[10 40 560 620])
set(gcf,'position',[10 40 500 400])
subplot(3,1,1); hold on; %p=plot([1:numPhaseBins]-.5,rate')
%plot([0 numUniqueFrames], [rate(1) rate(1)],'color',[1 1 1]); % to save tight axis chop
x=[1:numUniqueFrames]; 
for i=1:numConditions
    %plot(x,rate(i,:),'color',colors(i,:))
    
    %plot([x; x]+(i*0.05),[rate(i,:); rate(i,:)]+(rateSEM(i,:)'*[-1 1])','color',colors(i,:))
     plot(x,conv(rate(i,:),fspecial('gauss',[1 10],2),'same'),'color',colors(i,:))
end
%plot(x,rate(maxPowerInd,:),'color',colors(maxPowerInd,:),'lineWidth',2);
xlabel('time (msec)'); 
xvals=round(double([-shift 0 diff(s.targetOnOff) numUniqueFrames-shift])*ifi*1000);
xloc=[0 shift shift+diff(s.targetOnOff) numUniqueFrames];
set(gca,'XTickLabel',xvals,'XTick',xloc); 
ylabel('rate'); 
%set(gca,'YTickLabel',[0:.1:1]*parameters.refreshRate,'YTick',[0:.1:1])
axis tight


subplot(3,1,2); %2,2,4
hold on
dur=double(diff(s.targetOnOff))
relevantRange=[numUniqueFrames-(dur)+1:numUniqueFrames];


%meanPerRepetition?  fdivide by dur vs. divide by repetitions...

%meanRateDuringPeriod=sum(fullRate(:,:,relevantRange)/dur,3);
meanRateDuringPeriod=mean(fullRate(:,:,relevantRange),3);
if isnan(meanRateDuringPeriod(end))  %iF nan REPLACE THE LAST VALUE WITH THE AVERAGE ABOVE IT
    meanRateDuringPeriod(end)=mean(meanRateDuringPeriod(1:end-1,end));  
end
meanRatePerCond=mean(meanRateDuringPeriod,1); % 2 vs 3 check!
SEMRatePerCond=std(meanRateDuringPeriod,[],1)/sqrt(numRepeats);
stdRatePerCond=std(meanRateDuringPeriod,[],1);
for i=1:numConditions
    errorbar(i,meanRatePerCond(i),stdRatePerCond(i),'color',colors(i,:));
    plot(i,meanRatePerCond(i),'.','color',colors(i,:));
end
ylabel('<rate>_{on}'); 
set(gca,'xLim',[0 numConditions+1]);
set(gca,'XTickLabel',conditionNames,'XTick',1:numConditions); 


%%UGLY HACK REMOVED SOON
% subplot(2,2,4); 
% hold on
% dur=double(diff(s.targetOnOff));
% relevantRange=[numUniqueFrames-dur:numUniqueFrames];
% 
% meanRateDuringPeriod=sum(fullPhotodiode(:,:,relevantRange)/dur,3);
% meanRatePerCond=mean(meanRateDuringPeriod,1); % 2 vs 3 check!
% SEMRatePerCond=std(meanRateDuringPeriod,[],1)/sqrt(numRepeats);
% stdRatePerCond=std(meanRateDuringPeriod,[],1);
% for i=1:numConditions
%     errorbar(i,meanRatePerCond(i),stdRatePerCond(i),'color',colors(i,:));
%     plot(i,meanRatePerCond(i),'.','color',colors(i,:));
% end
% ylabel('sum volts_{on}'); 
% set(gca,'xLim',[0 numConditions+1]);
% set(gca,'yLim',[106 108]);
% set(gca,'XTickLabel',conditionNames,'XTick',1:numConditions);



subplot(3,1,3); imagesc(rasterDensity);  colormap(gray)

%PHOTODIODE
%%
doPhotodiode=1;
if doPhotodiode
    %figure; hold on;
    switch conditionType
        case 'allTargetOrientationAndPhase'
            %%
            %close all
            
            %%
            subplot(1,2,1); hold on 
            title(sprintf('grating %dppc',stimulusDetails.pixPerCycs(1)))
            
            ss=1+round(stimulusDetails.targetOnOff(1)/2);
            ee=ss+round(diff(stimulusDetails.targetOnOff))-1;
            or=unique(c.targetOrientation);
            if or(1)==0 && or(2)==pi/2
                l1='V';
                l2='H';
            elseif abs(or(1))==abs(or(2)) && or(1)<0 && or(2)>0
                l1=sprintf('%2.0f CW',180*or(2)/pi);
                l2='CCW';
            else
                l1='or1';
                l2='or2'
            end
            
            for i=1:length(or)
                which=find(c.targetOrientation==or(i));
                pho=photodiode(which,:)';
                [photoTime photoPhase ]=find(pho==max(pho(:)));
                phoSEM=photodiodeSEM(photoPhase,:);

                whichPlot='maxPhase'
                switch whichPlot
                    case 'maxPhase'
                        plot(1:numUniqueFrames,[pho(:,photoPhase) pho(:,photoPhase)],'.','color',colors(min(which),:));
                    case 'allRepsMaxPhase'
                        theseData=reshape(fullPhotodiode(:,which(photoPhase),:),size(fullPhotodiode,1),[]);
                        theFrames=repmat([1:numUniqueFrames],size(fullPhotodiode,1),1);
                        plot(theFrames,theseData,'.','color',colors(min(which),:))
                end
                
                h(i)=plot(pho(:,photoPhase),'color',colors(min(which),:));
                %plot([1:length(pho); 1:length(pho)],[pho(:,photoPhase) pho(:,photoPhase)]'+(phoSEM'*[-1 1])','color',colors(min(find(which)),:))
             end
             xlabel('frame #')
             ylabel('sum(volts)')
             legend(h,{l1,l2})
            %set(gca,'xlim',[0 size(pho,1)*2],'ylim',[7 11])
             
             subplot(1,2,2); hold on
             for i=1:length(or)
                 which=find(c.targetOrientation==or(i));
                 pha=c.targetPhase(which);
                 pho=photodiode(which,:)';
                 [photoTime photoPhase ]=find(pho==max(pho(:)));

                 options=optimset('TolFun',10^-14,'TolX',10^-14);
                 lb=[0 0 -pi*2]; ub=[6000 4000 2*pi]; % lb=[]; ub=[];
                 
                  
                 p=linspace(0,4*pi,100);
 
                whichPlot='allRepsOneTime';
                switch whichPlot
                    
                    case 'maxTime'
                        params = lsqcurvefit(@(x,xdata) x(1)+x(2)*sin(xdata+x(3)),[1000 100 1],pha,pho(photoTime,:),lb,ub,options); params(3)=mod(params(3),2*pi);
                        plot([pha pha+2*pi]+params(3),[pho(photoTime,:) pho(photoTime,:)],'.','color',colors(min(which),:));
                        
                        %plot([pha pha+2*pi]+params(3),[pho pho],'.','color',colors(min(find(which)),:));
                    case 'allRepsOneTime'
                        params = lsqcurvefit(@(x,xdata) x(1)+x(2)*sin(xdata+x(3)),[1000 100 1],pha,pho(photoTime,:),lb,ub,options); params(3)=mod(params(3),2*pi);
                        theseData=reshape(fullPhotodiode(:,which,photoTime),size(fullPhotodiode,1),[]);
                        thePhases=repmat(pha+params(3),size(fullPhotodiode,1),1);
                        plot(thePhases,theseData,'.','color',colors(min(which),:))
                    case 'allRepsTimeAveraged'
                        
                    case  'timeAveragedRepAveraged'
                        meanPho=mean(pho);
                        validPho=~isnan(meanPho);
                        params = lsqcurvefit(@(x,xdata) x(1)+x(2)*sin(xdata+x(3)),[1000 100 1],pha(validPho),meanPho(validPho),lb,ub,options); params(3)=mod(params(3),2*pi);
                        plot([pha pha+2*pi]+params(3),[mean(pho) mean(pho)],'.','color',colors(min(which),:));
                    case  'stimOnTimeAveragedRepAveraged'
                        meanPho=mean(pho(ss:ee,:));
                        validPho=~isnan(meanPho);
                        params = lsqcurvefit(@(x,xdata) x(1)+x(2)*sin(xdata+x(3)),[1000 100 1],pha(validPho),meanPho(validPho),lb,ub,options); params(3)=mod(params(3),2*pi);
                        plot([pha pha+2*pi]+params(3),[meanPho meanPho],'.','color',colors(min(which),:));
                
                end
               plot(p,params(1)+params(2)*sin(p),'-','color',colors(min(which),:))
                
                
                 amp(i)=params(2);
                 mn(i)=params(1);
             end
             meanFloor=min(photodiode(:));
             ratioDC=(mn(1)-meanFloor)/(mn(2)-meanFloor);
             string=sprintf('%s:%s = %2.3f mean  %2.3f amp',l1,l2,ratioDC,abs(amp(1)/amp(2)));
             title(string)
            xlabel('phase (\pi)')
            set(gca,'ytick',[ylim ],'yticklabel',[ylim ])
            set(gca,'xtick',[0 pi 2*pi 3*pi 4*pi],'xticklabel',[0 1 2 3 4],'xlim',[0 6*pi]);%,'ylim',[1525 1600])
            cleanUpFigure
        otherwise
            %% inspect distribution of photodiode output
            close all
            figure;
            subplot(2,2,1); hist(photodiode(:),100)
            xlabel ('luminance (volts)'); ylabel ('count')
            subplot(2,2,2); plot(diff(spikeRecord.correctedFrameTimes',1)*1000,spikeRecord.photoDiode,'.');
            xlabel('frame time (msec)'); ylabel ('luminance (volts)')
                        subplot(2,2,3); plot(spikeRecord.spikeWaveforms(8,:)')

            
            
            
            
            
            %%

            subplot(1,2,1); hold on
            for i=1:numConditions
                plot(x,photodiode(i,:),'color',colors(i,:));
                plot([x; x]+(i*0.05),[photodiode(i,:); photodiode(i,:)]+(photodiodeSEM(i,:)'*[-1 1])','color',colors(i,:))
            end
            xlabel('time (msec)');
            set(gca,'XTickLabel',xvals,'XTick',xloc);
            ylabel('sum volts (has errorbars)');
            set(gca,'Xlim',[1 numUniqueFrames])
            
            %rate density over phase... doubles as a legend
            subplot(1,2,2); hold on
            im=zeros([size(rasterDensity) 3]);
            hues=rgb2hsv(colors);  % get colors to match jet
            hues=repmat(hues(:,1)',numRepeats,1); % for each rep
            hues=repmat(hues(:),1,numUniqueFrames);  % for each phase bin
            grey=repmat(all((colors==repmat(colors(:,1),1,3))'),numRepeats,1); % match grey vals to hues
            im(:,:,1)=hues; % hue
            im(grey(:)~=1,:,2)=0.6; % saturation
            im(:,:,3)=rasterDensity/max(rasterDensity(:)); % value
            rgbIm=hsv2rgb(im);
            image(rgbIm);
            axis([0 size(im,2) 0 size(im,1)]+.5);
            set(gca,'YTickLabel',conditionNames,'YTick',size(im,1)*([1:length(conditionNames)]-.5)/length(conditionNames))
            xlabel('time');
            %set(gca,'XTickLabel',{'0','pi','2pi'},'XTick',([0 .5  1]*numPhaseBins)+.5);
            
    end
end

