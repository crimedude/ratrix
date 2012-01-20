function [stimulus updateSM resolutionIndex preRequestStim preResponseStim discrimStim LUT targetPorts distractorPorts ...
    details interTrialLuminance text indexPulses imagingTasks] = ...
    calcStim(stimulus,trialManagerClass,allowRepeats,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords)

indexPulses=[];
imagingTasks=[];

LUT=makeStandardLUT(LUTbits);
updateSM=true;

if IsLinux
    depth=24;
else
    depth=32;
end
[resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[100 60],depth,getMaxWidth(stimulus),getMaxHeight(stimulus));

scaleFactor = getScaleFactor(stimulus);
interTrialLuminance = getInterTrialLuminance(stimulus);

if ~isempty(trialRecords) && length(trialRecords)>=2
    lastRec=trialRecords(end-1);
else
    lastRec=[];
end
stimulus.initialPos=[width height]'/2;
details.track=[stimulus.initialPos nan(2,60*60)];

stimulus.mouseIndices=[];
if IsLinux    
    [a,b,c]=GetMouseIndices; % http://tech.groups.yahoo.com/group/psychtoolbox/message/13259
    
    for i = 1:length(c) % any way to reliably determine which mouse is which?  ie, who is plugged in to which port?  locationID/interfaceID?
        if isempty(strfind(c{i}.product,'Virtual')) && ~isempty(strfind(c{i}.product,'USB Optical Mouse')) && ~isempty(strfind(c{i}.usageName,'slave pointer'))        
            stimulus.mouseIndices = [stimulus.mouseIndices c{i}.index];
            c{i}.locationID
            c{i}.interfaceID
        end
    end
    
    if length(stimulus.mouseIndices) ~= 2
        error('didn''t find exactly 2 mice on linux')
    end
end

mouse(stimulus);

[targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);

type='dynamic';
out=zeros([height width]./scaleFactor); %destrect is set to stretch this to the screen, so dynamic generated stims should be the same size

discrimStim=[];
discrimStim.stimulus=out;
discrimStim.stimType=type;
discrimStim.scaleFactor=scaleFactor;
discrimStim.startFrame=0;

preRequestStim=[];
preRequestStim.stimulus=interTrialLuminance;
preRequestStim.stimType='loop';
preRequestStim.scaleFactor=0;
preRequestStim.startFrame=0;
preRequestStim.punishResponses=false;

preResponseStim=discrimStim;
preResponseStim.punishResponses=false;

text='';