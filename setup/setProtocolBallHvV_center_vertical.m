function r = setProtocolHvV_center_vertical(r,subjIDs)

if ~isa(r,'ratrix')
    error('need a ratrix')
end

if ~all(ismember(subjIDs,getSubjectIDs(r)))
    error('not all those subject IDs are in that ratrix')
end

sm=makeStandardSoundManager();

rewardSizeULorMS          =80;
requestRewardSizeULorMS   =5;
requestMode               ='first';
msPenalty                 =3500;     %consider changing this also in future
fractionOpenTimeSoundIsOn =1;
fractionPenaltySoundIsOn  =1;
scalar                    =1;
msAirpuff                 =msPenalty;

% sca
% keyboard

if ~isscalar(subjIDs)
    error('expecting exactly one subject')
end
switch subjIDs{1}
    
case 'g62b7lt'           %started HvV_cent 1/21/14 
       requestRewardSizeULorMS = 0;
       rewardSizeULorMS        = 140; 
       msPenalty               =4000;    
    
%     case 'g54aa7lt' %changed to HvV 1/4/14
%        requestRewardSizeULorMS = 0;
%        rewardSizeULorMS        = 60;
   
%    case 'gcam44lt'  %changed to HvV 1/4/14
%         requestRewardSizeULorMS = 0;
%         rewardSizeULorMS        = 45; 
% case 'bfly1.5att' 
%        requestRewardSizeULorMS = 20;
%        rewardSizeULorMS        = 115;
    
case 'g62b1lt'     %moved to HvV_center 1/4/14   
       requestRewardSizeULorMS = 0;
       rewardSizeULorMS        = 160;
       msPenalty                 =3500; 
      
%    case 'g54a11rt'   %changed to GoToBlack 12/10/13
%         requestRewardSizeULorMS = 0;
%         rewardSizeULorMS        = 80;    
        

   case 'g62b3rt'          %changed 1/4/14
       requestRewardSizeULorMS = 0;
       rewardSizeULorMS        = 90; 
       msPenalty               = 3600; 
  
%    case 'g62b1lt'       %changed to GoToBlack 12/10/13   
%        requestRewardSizeULorMS = 0;
%        rewardSizeULorMS        = ; 
      
%    case 'g54b8tt' % Switched to GTB 12/19/13  
%        requestRewardSizeULorMS = 0;
%        rewardSizeULorMS        = 60;   
       
    otherwise
        warning('unrecognized mouse, using defaults')
end

noRequest = constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msAirpuff);

percentCorrectionTrials = .5;

maxWidth  = 1920;
maxHeight = 1080;

[w,h] = rat(maxWidth/maxHeight);
textureSize = 10*[w,h];
zoom = [maxWidth maxHeight]./textureSize;

svnRev = {'svn://132.239.158.177/projects/ratrix/trunk'};
svnCheckMode = 'session';

interTrialLuminance = .5;

stim.gain = 0.7 * ones(2,1);
stim.targetDistance = 500 * ones(1,2);
stim.timeoutSecs = 10;
stim.slow = [40; 80]; % 10 * ones(2,1);
stim.slowSecs = 1;
stim.positional = false;
stim.cue = true;
stim.soundClue = true;

pixPerCycs             = [100]; %*10^9;
targetOrientations     = 0
distractorOrientations = []; %-targetOrientations;
mean                   = .5;
radius                 = .35;
contrast               = 1;
thresh                 = .00005;
normalizedPosition      = [.5];
scaleFactor            = 0; %[1 1];
axis                   = pi/2;




targetOrientations = pi/2;
distractorOrientations = 0;

stim.stim = orientedGabors(pixPerCycs,{distractorOrientations [] targetOrientations},'abstract',mean,radius,contrast,thresh,normalizedPosition,maxWidth,maxHeight,scaleFactor,interTrialLuminance,[],[],axis);

 ballTM = ball(percentCorrectionTrials,sm,noRequest);
 
 ballSM = setReinfAssocSecs(trail(stim,maxWidth,maxHeight,zoom,interTrialLuminance),1);
 %change stim to stay on for 1 sec after
 
 ts1 = trainingStep(ballTM, ballSM, repeatIndefinitely(), noTimeOff(), svnRev, svnCheckMode); %ball
 
 p=protocol('mouse',{ts1});
%p=protocol('mouse',{ts1,ts2});

stepNum=uint8(1);
subj=getSubjectFromID(r,subjIDs{1});
[subj r]=setProtocolAndStep(subj,p,true,false,true,stepNum,r,'LY01 (40,80), R=36','edf');
end