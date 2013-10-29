function r = setProtocolCNM2(r,subjIDs)

if ~isa(r,'ratrix')
    error('need a ratrix')
end

if ~all(ismember(subjIDs,getSubjectIDs(r)))
    error('not all those subject IDs are in that ratrix')
end

sm=makeCNMSoundManager(); 

rewardSizeULorMS          =80;
requestRewardSizeULorMS   =80;
requestMode               ='first';
msPenalty                 =20;
fractionOpenTimeSoundIsOn =1;
fractionPenaltySoundIsOn  =1;
scalar                    =1;
msAirpuff                 =0;
responseLockoutMs = 0;
Delay = constantDelay(20);         %length of the first phase in ms
earlyP = 0; %
constantRewards=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msAirpuff);

allowRepeats=false;
freeDrinkLikelihood=0; %p per frame
fd = freeDrinks(sm,freeDrinkLikelihood,allowRepeats,constantRewards);

fd2 = freeDrinks(sm,freeDrinkLikelihood,allowRepeats,constantRewards);

percentCorrectionTrials=0;

maxWidth               = 1920;
maxHeight              = 1080; 
interTrialLuminance = .5;
scaleFactor = 0;

[w,h]=rat(maxWidth/maxHeight);

eyeController=[];

dropFrames=false;

%freegNGTM=freeGoNoGo(sm,percentCorrectionTrials,responseLockoutMs,constantRewards,eyeController,{'off'},dropFrames,'ptb','none',[],Delay, []);
gNGTM=goNoGo(sm,percentCorrectionTrials,responseLockoutMs,constantRewards,eyeController,{'off'},dropFrames,'ptb','none',[],Delay, []);
freeGNGTM=freeGoNoGo(sm,percentCorrectionTrials,earlyP,constantRewards,eyeController,{'off'},dropFrames,'ptb','none',[],Delay, []); 
earlyP = 1;
freePGNGTM=freeGoNoGo(sm,percentCorrectionTrials,earlyP,constantRewards,eyeController,{'off'},dropFrames,'ptb','none',[],Delay, []); 
%delaymanager sets the delay in each trial before stimulus presentation
% 
% textureSize=10*[w,h];
% zoom=[maxWidth maxHeight]./textureSize;
% 
pixPerCycs              =[100];
targetOrientations      =[pi/4];
distractorOrientations  =[];
mean                    =.5;
radius                  =.085;
contrast                =1;
thresh                  =.00005;
yPosPct                 =.65;
scaleFactor            = 0; %[1 1];
interTrialLuminance     =.5;
freeStim = orientedGabors(pixPerCycs,targetOrientations,distractorOrientations,mean,radius,contrast,thresh,yPosPct,maxWidth,maxHeight,scaleFactor,interTrialLuminance);

%stim params for free drinks
soundParams.soundType='CNMToneTrain'; %new soundType for CNM stimulus
soundParams.freqs = [1000 8000]; %the two possible frequencies
soundParams.duration=[]; %ms, total duration of stimSound-calculated in calcstim
soundParams.isi=500; %ms, time between tones in a CNMToneTrain
soundParams.toneDuration=500; %ms, duration of each tone in a CNMToneTrain
soundParams.startfreq = randi(2, 1, 1); %randomly choose a starting tone

maxSPL=80; %measured max level attainable by speakers
ampdB=60; %requested amps in dB
amplitude=10.^((ampdB -maxSPL)/20); %amplitudes = line level, 0 to 1
soundParams.amp = amplitude; %for intensityDiscrim

%freeCNMStim = freeCNM(interTrialLuminance,soundParams,maxWidth,maxHeight,scaleFactor,interTrialLuminance);
%soundParams.soundType='CNMToneTrain';
CNMStim = CNM(interTrialLuminance,soundParams,maxWidth,maxHeight,scaleFactor,interTrialLuminance);

soundParams.soundType='freeCNMToneTrain';
freeCNMStim = freeCNM(interTrialLuminance,soundParams,maxWidth,maxHeight,scaleFactor,interTrialLuminance);
requestRewardSizeULorMS = 0;
msPenalty               = 20; %length of the reinforced phase for timeouts
noRequest=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msAirpuff);
nrGNGTM=goNoGo(sm,percentCorrectionTrials,responseLockoutMs,noRequest,eyeController,{'off'},dropFrames,'ptb','center');

svnRev={'svn://132.239.158.177/projects/ratrix/CNM'};
svnCheckMode='session';

trialsPerMinute = 7;
minutes = .5;
numTriggers = 20;

ts1 = trainingStep(freeGNGTM,  freeCNMStim, repeatIndefinitely(), noTimeOff(), svnRev,svnCheckMode);
ts2 = trainingStep(freePGNGTM,  freeCNMStim, repeatIndefinitely(), noTimeOff(), svnRev,svnCheckMode);
ts3 = trainingStep(gNGTM, CNMStim, repeatIndefinitely()   , noTimeOff(), svnRev,svnCheckMode);  %free drinks

%nafc
trialsPerMinute = 6;
minutes = 1;
%no request reward
ts4 = trainingStep(fd2  , freeStim,  repeatIndefinitely()          , noTimeOff(), svnRev,svnCheckMode);

%long penalty
msPenalty = 3000;
longPenalty=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msAirpuff);
lpGNGTM=goNoGo(sm,percentCorrectionTrials,responseLockoutMs,longPenalty,eyeController,{'off'},dropFrames,'ptb','center',[],[],[]);
ts5 = trainingStep(lpGNGTM, CNMStim, performanceCriterion(.85, int8(200))  , noTimeOff(), svnRev,svnCheckMode);

ts6 = trainingStep(lpGNGTM, CNMStim, repeatIndefinitely()  , noTimeOff(), svnRev,svnCheckMode);


%p=protocol('mouse CNM task',{ts1, ts2, ts3, ts4, ts5 ts6}); %normal setup
p=protocol('mouse CNM task',{ts1, ts2, ts3, ts4, ts5 ts6}); %to test CNM/goNoGo

for i=1:length(subjIDs),
    subj=getSubjectFromID(r,subjIDs{i});
    
    switch subjIDs{i}
        case 'test'
            stepNum=uint8(1);
        otherwise
            stepNum=uint8(1);
    end
    
    [subj r]=setProtocolAndStep(subj,p,true,false,true,stepNum,r,'call to setProtocolCNM2','edf');
end