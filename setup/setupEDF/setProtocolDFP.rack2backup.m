% Usage: setProtocolDFP({'173','174','175','176'})
function setProtocolDFP(ids)
for i=1:length(ids)
    ratID=ids{i};
    if ~any(strcmp(ratID,{'173','174','175','176'}))
        error('not an dan rat')
    end
end

dataPath=fullfile(fileparts(fileparts(getRatrixPath)),'ratrixData',filesep);
r=ratrix(fullfile(dataPath, 'ServerData'),0); %load from file


msFlushDuration         =1000;
rewardSizeULorMS        =50;
msMinimumPokeDuration   =10;
msMinimumClearDuration  =10;
msPenalty               =3000;
msRewardSoundDuration   =rewardSizeULorMS;
sm=makeStandardSoundManager();

freeDrinkLikelihood=0.003;
%fd1 = freeDrinks(msFlushDuration,rewardSizeULorMS,msMinimumPokeDuration,msMinimumClearDuration,sm,msPenalty,msRewardSoundDuration,freeDrinkLikelihood);
freeDrinkLikelihood=0;
fd = freeDrinks(msFlushDuration,rewardSizeULorMS,msMinimumPokeDuration,msMinimumClearDuration,sm,msPenalty,msRewardSoundDuration,freeDrinkLikelihood);

requestRewardSizeULorMS=0;
percentCorrectionTrials=.5;
msResponseTimeLimit=0;
pokeToRequestStim=true;
maintainPokeToMaintainStim=true;
msMaximumStimPresentationDuration=0;
maximumNumberStimPresentations=0;
doMask=false;


rewardSizeULorMS        =90;
msRewardSoundDuration   =rewardSizeULorMS;

vh=nAFC(msFlushDuration,rewardSizeULorMS,msMinimumPokeDuration,msMinimumClearDuration,sm,msPenalty,requestRewardSizeULorMS,...
    percentCorrectionTrials,msResponseTimeLimit,pokeToRequestStim,maintainPokeToMaintainStim,msMaximumStimPresentationDuration,...
    maximumNumberStimPresentations,doMask,msRewardSoundDuration);

pixPerCycs              =[20];
targetContrasts         =[0.8];
distractorContrasts     =[];
fieldWidthPct           = 0.2;
fieldHeightPct          = 0.2;
mean                    =.5;
stddev                  =.04; % Only used for Gaussian Flicker
thresh                  =.00005;
flickerType             =0; % 0 - Binary Flicker; 1 - Gaussian Flicker
yPosPct                 =.65;
maxWidth                =800;
maxHeight               =600;
scaleFactor             =[1 1];
interTrialLuminance     =.5;

freq = 200; % Sound frequency to use in hz
amplitudes = [0 0.4]; % For now bias completely in one direction
discrimStim1 = stereoDiscrim(mean,freq,amplitudes,maxWidth,maxHeight,scaleFactor,interTrialLuminance);
%freeStim = hemifieldFlicker(pixPerCycs,targetContrasts,distractorContrasts,fieldWidthPct,fieldHeightPct,mean,stddev,thresh,flickerType,yPosPct,maxWidth,maxHeight,scaleFactor,interTrialLuminance);
amplitudes = [0.1 0.4]; % Add a distractor sound
%distractorContrasts  =[0.4];
%discrimStim2 = stereoDiscrim(mean,freq,amplitudes,maxWidth,maxHeight,scaleFactor,interTrialLuminance);
discrimStim2 = hemifieldFlicker(pixPerCycs,targetContrasts,distractorContrasts,fieldWidthPct,fieldHeightPct,mean,stddev,thresh,flickerType,yPosPct,maxWidth,maxHeight,scaleFactor,interTrialLuminance);

ts1 = trainingStep(vh, discrimStim1, repeatIndefinitely(), noTimeOff());
ts2 = trainingStep(vh, discrimStim2, repeatIndefinitely(), noTimeOff());

p=protocol('stereodiscrim free drinks',{ts1, ts2});


for i=1:length(ids)
    ratID=ids{i};
    s = getSubjectFromID(r,ratID);
    stepNum = 2;
    [s r]=setProtocolAndStep(s,p,1,0,1,stepNum,r,'DFP(actually) putting rat on stereo discrim','edf');
end
