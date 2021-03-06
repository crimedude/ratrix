function r = setProtocolCNM(r,subjIDs)

if ~isa(r,'ratrix')
    error('need a ratrix')
end

if ~all(ismember(subjIDs,getSubjectIDs(r)))
    error('not all those subject IDs are in that ratrix')
end

sm=makeIntensityDiscrimSoundManager(); %we can just use this one mw 10-23-2012

rewardSizeULorMS          =80;
requestRewardSizeULorMS   =80;
requestMode               ='first';
msPenalty                 =1000;
fractionOpenTimeSoundIsOn =1;
fractionPenaltySoundIsOn  =1;
scalar                    =1;
msAirpuff                 =msPenalty;

constantRewards=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msAirpuff);

allowRepeats=false;
freeDrinkLikelihood=0.004; %p per frame
fd = freeDrinks(sm,freeDrinkLikelihood,allowRepeats,constantRewards);

freeDrinkLikelihood=0;
fd2 = freeDrinks(sm,freeDrinkLikelihood,allowRepeats,constantRewards);

percentCorrectionTrials=.5;

maxWidth               = 1920;
maxHeight              = 1080;
interTrialLuminance = .5;
scaleFactor = 0;

[w,h]=rat(maxWidth/maxHeight);

eyeController=[];

dropFrames=false;
nafcTM=nAFC(sm,percentCorrectionTrials,constantRewards,eyeController,{'off'},dropFrames,'ptb','center');
% 
% textureSize=10*[w,h];
% zoom=[maxWidth maxHeight]./textureSize;
% 
% pixPerCycs              =[100];
% targetOrientations      =[pi/4];
% distractorOrientations  =[];
% mean                    =.5;
% radius                  =.085;
% contrast                =1;
% thresh                  =.00005;
% yPosPct                 =.65;
% scaleFactor            = 0; %[1 1];
% interTrialLuminance     =.5;
% freeStim = orientedGabors(pixPerCycs,targetOrientations,distractorOrientations,mean,radius,contrast,thresh,yPosPct,maxWidth,maxHeight,scaleFactor,interTrialLuminance);

%stim params for free drinks
soundParams.soundType='allOctaves'; %should put in pure tones later one mw 10-2012
soundParams.freqs = [300 450];
soundParams.duration=10000; %ms
maxSPL=80; %measured max level attainable by speakers
ampdB=60; %requested amps in dB
amplitude=10.^((ampdB -maxSPL)/20); %amplitudes = line level, 0 to 1
soundParams.amp = amplitude; %for intensityDisrim

CNMStim = CNM(interTrialLuminance,soundParams,maxWidth,maxHeight,scaleFactor,interTrialLuminance);

requestRewardSizeULorMS = 0;
msPenalty               = 1000;
noRequest=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msAirpuff);
nrTM=nAFC(sm,percentCorrectionTrials,noRequest,eyeController,{'off'},dropFrames,'ptb','center');

svnRev={'svn://132.239.158.177/projects/ratrix/trunk'};
svnCheckMode='session';

trialsPerMinute = 7;
minutes = .5;
numTriggers = 20;
ts1 = trainingStep(fd,  CNMStim, rateCriterion(trialsPerMinute,minutes), noTimeOff(), svnRev,svnCheckMode);  %stochastic free drinks
ts2 = trainingStep(fd2, CNMStim, numTrialsDoneCriterion(numTriggers)   , noTimeOff(), svnRev,svnCheckMode);  %free drinks

%nafc
trialsPerMinute = 6;
minutes = 1;
ts3 = trainingStep(nafcTM, CNMStim, rateCriterion(trialsPerMinute,minutes), noTimeOff(), svnRev,svnCheckMode);  %side discrim

%no request reward
ts4 = trainingStep(nrTM  , CNMStim,  numTrialsDoneCriterion(400)          , noTimeOff(), svnRev,svnCheckMode);

%long penalty
msPenalty = 3000;
longPenalty=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msAirpuff);
lpTM=nAFC(sm,percentCorrectionTrials,longPenalty,eyeController,{'off'},dropFrames,'ptb','center',[],[],[]);
ts5 = trainingStep(lpTM  , CNMStim, performanceCriterion(.85, int8(200))  , noTimeOff(), svnRev,svnCheckMode);

ts6 = trainingStep(lpTM  , CNMStim, repeatIndefinitely()  , noTimeOff(), svnRev,svnCheckMode);


p=protocol('mouse CNM task',{ts1, ts2, ts3, ts4, ts5 ts6});

for i=1:length(subjIDs),
    subj=getSubjectFromID(r,subjIDs{i});
    
    switch subjIDs{i}
        case 'test'
            stepNum=uint8(1);
        otherwise
            stepNum=uint8(1);
    end
    
    [subj r]=setProtocolAndStep(subj,p,true,false,true,stepNum,r,'call to setProtocolCNM','edf');
end