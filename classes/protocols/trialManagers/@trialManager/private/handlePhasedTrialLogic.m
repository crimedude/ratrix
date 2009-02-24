function [tm done newSpecInd specInd updatePhase transitionedByTimeFlag transitionedByPortFlag response trialResponse...
    isRequesting lastSoundsLooped getSoundsTime soundsDoneTime framesDoneTime portSelectionDoneTime isRequestingDoneTime goDirectlyToError] = ...
    handlePhasedTrialLogic(tm, done, ...
    ports, lastPorts, station, specInd, transitionCriterion, framesUntilTransition, numFramesInStim,...
    stepsInPhase, isFinalPhase, response, trialResponse, ...
    stimManager, msRewardSound, mePenaltySound, targetOptions, distractorOptions, requestOptions, ...
    playRequestSoundLoop, isRequesting, soundNames, lastSoundsLooped)

updatePhase=0;
newSpecInd = specInd;
transitionedByTimeFlag = false;
transitionedByPortFlag = false;
goDirectlyToError=false;

soundsToPlay = getSoundsToPlay(stimManager, ports, lastPorts, specInd, stepsInPhase,msRewardSound, mePenaltySound, ...
    targetOptions, distractorOptions, requestOptions, playRequestSoundLoop, class(tm));
getSoundsTime=GetSecs;
% soundsToPlay is a cell array of sound names {{playLoop sounds}, {playSound sounds}} to be played at current frame
% validate soundsToPlay here (make sure they are all members of soundNames)
if ~isempty(setdiff(soundsToPlay{1},soundNames)) || ~all(cellfun(@(x) ismember(x{1},soundNames),soundsToPlay{2}))
    error('getSoundsToPlay assigned sounds that are not in the soundManager!');
end

% first end any loops that were looping last frame but should no longer be looped
stopLooping=setdiff(lastSoundsLooped,soundsToPlay{1});
for snd=stopLooping
    tm.soundMgr = playLoop(tm.soundMgr,snd,station,0);
end

% then start any loops that weren't already looping
startLooping=setdiff(soundsToPlay{1},lastSoundsLooped);
for snd=startLooping
    tm.soundMgr = playLoop(tm.soundMgr,snd,station,1);
end

lastSoundsLooped = soundsToPlay{1};

% now play one-time sounds
for i=1:length(soundsToPlay{2})
    tm.soundMgr = playSound(tm.soundMgr,soundsToPlay{2}{i}{1},soundsToPlay{2}{i}{2}/1000.0,station);
end

soundsDoneTime=GetSecs;

% ===================================================
% Check against framesUntilTransition - Transition BY TIME
% if we are at grad by time, then manually set port to the correct one
% note that we will need to flag that this was done as "auto-request"
if ~isempty(framesUntilTransition) && stepsInPhase == framesUntilTransition - 1 % changed to framesUntilTransition-1 % 8/19/08
    % find the special 'timeout' transition (the port set should be empty)
    newSpecInd = transitionCriterion{cellfun('isempty',transitionCriterion)+1}; 
    % this will always work as long as we guarantee the presence of this special indicator (checked in stimSpec constructor)
    updatePhase = 1;
    if isFinalPhase
        done = 1;
        %      error('we are done by time');
    end
    %error('transitioned by time in phase %d', specInd);
    transitionedByTimeFlag = true;
end

% Check against transition by numFramesInStim (based on size of the stimulus in 'cache' or 'timedIndexed' mode)
% in other modes, such as 'loop', this will never pass b/c numFramesInStim==Inf
if stepsInPhase==numFramesInStim
    % find the special 'timeout' transition (the port set should be empty)
    newSpecInd = transitionCriterion{cellfun('isempty',transitionCriterion)+1}; 
    % this will always work as long as we guarantee the presence of this special indicator (checked in stimSpec constructor)
    updatePhase = 1;
    if isFinalPhase
        done = 1;
        %      error('we are done by time');
    end
end

framesDoneTime=GetSecs;

% Check for transition by port selection
for gcInd=1:2:length(transitionCriterion)-1
    if ~isempty(transitionCriterion{gcInd}) && any(logical(ports(transitionCriterion{gcInd})))
        % we found port in this port set
        % first check if we are done with this trial, in which case we do nothing except set done to 1
        if isFinalPhase
            done = 1;
            updatePhase = 1;
            %              'we are done with this trial'
            %              specInd
        else
            % move to the next phase as specified by graduationCriterion
            %      specInd = transitionCriterion{gcInd+1};
            newSpecInd = transitionCriterion{gcInd+1};
            %             if (specInd == newSpecInd)
            %                 error('same indices at %d', specInd);
            %             end
            updatePhase = 1;
        end
        transitionedByPortFlag = true;

        % set response to the ports array when it is triggered during a phase transition (ie response will be whatever the last port to trigger
        %   a transition was)
        response = ports;
        % set correct if we are on a target or distractor
        if any(ports(targetOptions))
            trialResponse =response;
        elseif any(ports(distractorOptions))
            trialResponse = response;
        end

        if length(find(ports))>1
            goDirectlyToError=true;
        end

        % we should stop checking all the criteria if we already passed one (essentially first come first served)
        break;
    end
end

portSelectionDoneTime=GetSecs;

% set isRequesting when request port is hit according to these rules:
%   if isRequesting was already 1, then set it to 0
%   if isRequesting was 0, then set it to 1
%   (basically flip the bit every time request port is hit)
% 
if any(ports(requestOptions)) && ~any(lastPorts(requestOptions))
    if isRequesting
        isRequesting=false;
    else
        isRequesting=true;
    end
end

isRequestingDoneTime=GetSecs;

% moved to runRealTimeLoop to save on copy-on-write 10/16/08
% stepsInPhase = stepsInPhase + 1; % increment number of steps in this phase

end % end function