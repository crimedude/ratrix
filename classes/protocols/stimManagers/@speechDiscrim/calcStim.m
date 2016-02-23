function [stimulus,updateSM,resolutionIndex,preRequestStim,preResponseStim,discrimStim,LUT,targetPorts,distractorPorts,...
    details,interTrialLuminance,text,indexPulses,imagingTasks,sounds] =...
    calcStim(stimulus,trialManagerClass,allowRepeats,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords,targetPorts,distractorPorts,details,text)

indexPulses=[];
imagingTasks=[];

LUT=makeStandardLUT(LUTbits);

[resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[100 60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));

updateSM=0;
toggleStim=true;

scaleFactor = getScaleFactor(stimulus);
interTrialLuminance = getInterTrialLuminance(stimulus);

switch trialManagerClass
    case 'freeDrinks'
        type='cache';
    case 'nAFC'
        type='loop';%int32([10 10]); % This is 'timedFrames'
    otherwise
        error('unknown trial manager class')
end

details.laserON=0; %set to be 0, modify if necessary

details.responseTime=0;
details.soundONTime=0;




% %decide randomly if we issue a laser pulse on this trial or not

switch stimulus.soundType
    case {'tone'}
    case {'toneLaser'}
        %this is for pure tone control protocol
        details.laserON = rand>.9; %laser is on for 10% of trials
        details.laser_duration=.5; %seconds
        details.laser_start_time=Inf;
        details.laser_off_time=Inf;
        details.laser_start_window=0;
        details.laser_wait_start_time=Inf;
    case {'speechWav'}
    case {'speechWavLaser'}
        details.laserON = rand>.9; %laser is on for 10% of trials
        details.laser_duration=.5; %seconds
        details.laser_start_time=Inf;
        details.laser_off_time=Inf;
        details.laser_start_window=0;
        details.laser_wait_start_time=Inf;
    case {'speechWavReversedReward'}
    case {'speechWavLaserMulti'}
        details.laserON = rand>.8;
        details.laser_start_window=RandSample([0 .14]); %randomly choose one of the start points
        %details.laser_duration=(stimulus.freq(2)-stimulus.freq(1))*.001; %spacing between start times determines the interval length
        details.laser_duration=.14;
        details.laser_start_time=Inf;
        details.laser_wait_start_time=Inf;
        details.laser_off_time=Inf;
end






if stimulus.duration==50  %stimulus.freq empty for speech, [1] for speechlaser
    %special case for laserCal
    details.laserON = 1; %laser is on for 10% of trials
    details.laser_duration=30; %seconds
    details.laser_start_time=Inf;
    details.laser_off_time=Inf;
end



details.toneFreq = [];

if strcmp(stimulus.soundType, 'speechWav')  %files specified in getClip-just need to indicate sad/dad
    %this code works for no laser condition - below for laser
    [lefts, rights] = getBalance(responsePorts,targetPorts);
    
    %default case (e.g. rights==lefts )
    
    if lefts>rights %choose a left stim (wav1)
        details.toneFreq = 1;
    elseif rights>lefts %choose a right stim (wav2)
        details.toneFreq = 0;
    end
    if lefts == rights %left
        details.toneFreq = 1;
    end
end

if strcmp(stimulus.soundType, 'speechWavReversedReward') %files specified in getClip-just need to indicate sad/dad
    %this code works for no laser condition - below for laser
    %same as above for now, duplicated for future potential modifications
    %CO 5-6
    [lefts, rights] = getBalance(responsePorts,targetPorts);
    
    %default case (e.g. rights==lefts )
    
    if lefts>rights %choose a left stim (wav1)
        details.toneFreq = 1;
    elseif rights>lefts %choose a right stim (wav2)
        details.toneFreq = 0;
    end
    if lefts == rights %left
        details.toneFreq = 1;
    end
end


if strcmp(stimulus.soundType, 'tone') %files specified in getClip-just need to indicate sad/dad
    
    [lefts, rights] = getBalance(responsePorts,targetPorts);
    
    %default case (e.g. rights==lefts )
    
    tones = [4000 13000];
    
    if lefts>rights %choose a left stim (wav1)
        details.toneFreq = tones(1);
    elseif rights>lefts %choose a right stim (wav2)
        details.toneFreq = tones(2);
    end
    if lefts == rights %left
        details.toneFreq = tones(1);
    end
    
end


if strcmp(stimulus.soundType, 'toneLaser') %files specified in getClip-just need to indicate sad/dad
    
    [lefts, rights] = getBalance(responsePorts,targetPorts);
    
    %default case (e.g. rights==lefts )
    
    tones = [4000 13000];
    
    if lefts>rights %choose a left stim (wav1)
        details.toneFreq = tones(1);
    elseif rights>lefts %choose a right stim (wav2)
        details.toneFreq = tones(2);
    end
    if lefts == rights %left
        details.toneFreq = tones(1);
    end
    
    if details.laserON
        details.toneFreq=RandSample(tones);
    end
    
end

if strcmp(stimulus.soundType, 'speechLaser') || strcmp(stimulus.soundType, 'speechLaserMulti') %laser assignment - random stimulus for laser trials
    
    
    [lefts, rights] = getBalance(responsePorts,targetPorts);
    
    %default case (e.g. rights==lefts )
    
    if lefts>rights %choose a left stim (wav1)
        details.toneFreq = 1;
    elseif rights>lefts %choose a right stim (wav2)
        details.toneFreq = 0;
    end
    
    if lefts == rights %left
        details.toneFreq = 1;
    end
    
    if details.laserON %randomly reward by choosing random stimulus
        details.toneFreq=RandSample(0:1);
    end
    
    
end


details.rightAmplitude = stimulus.amplitude;
details.leftAmplitude = stimulus.amplitude;

% fid=fopen('miketest.txt', 'a+t')
% fprintf(fid, '\nintensity discrim/calcstim: laserON=%d',details.laserON)
% fclose(fid)
switch stimulus.soundType
    case {'allOctaves','tritones'}
        sSound = soundClip('stimSoundBase','allOctaves',[stimulus.freq],20000);
    case {'binaryWhiteNoise','gaussianWhiteNoise','uniformWhiteNoise','empty'}
        sSound = soundClip('stimSoundBase',stimulus.soundType);
    case {'wmReadWav'}
        sSound = soundClip('stimSoundBase','wmReadWav', [details.toneFreq]);
    case {'speechWav'}
        sSound = soundClip('stimSoundBase','speechWav', [details.toneFreq]);
    case {'speechWavLaser'}
        sSound = soundClip('stimSoundBase','speechWavLaser', [details.toneFreq]);
    case {'speechWavLaserMulti'}
        sSound = soundClip('stimSoundBase','speechWavLaserMulti', [details.toneFreq]);
    case {'speechWavReversedReward'} %%%shit shit shit shit
        sSound = soundClip('stimSoundBase','speechWavReversedReward', [details.toneFreq]);
    case {'tone'}
        sSound = soundClip('stimSoundBase','tone', [details.toneFreq]);
    case {'toneLaser'}
        sSound = soundClip('stimSoundBase','toneLaser', [details.toneFreq]);
end
stimulus.stimSound = soundClip('stimSound','dualChannel',{sSound,details.leftAmplitude},{sSound,details.rightAmplitude});


%do not want this line when laser enabled!
%parameterize it as "multi" and "reinforce"?
%make sure to figure out the falsed out stuff in getSoundsToPlay
sounds={stimulus.stimSound};

out=zeros(min(height,getMaxHeight(stimulus)),min(width,getMaxWidth(stimulus)),2);
out(:,:,1)=stimulus.mean;
out(:,:,2)=stimulus.mean;

discrimStim=[];
discrimStim.stimulus=out;
discrimStim.stimType=type;
discrimStim.scaleFactor=scaleFactor;
discrimStim.startFrame=0;
%discrimStim.autoTrigger=[];

preRequestStim=[];
preRequestStim.stimulus=interTrialLuminance;
preRequestStim.stimType='loop';
preRequestStim.scaleFactor=0;
preRequestStim.startFrame=0;
%preRequestStim.autoTrigger=[];
preRequestStim.punishResponses=false;

preResponseStim=discrimStim;
preResponseStim.punishResponses=false;