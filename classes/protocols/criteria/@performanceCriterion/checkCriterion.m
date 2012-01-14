function [graduate details pct] = checkCriterion(c,subject,trainingStep,trialRecords,playTone)

if isempty(trialRecords)
    graduate=false;
    details=[];
    pct=0;
    return
end

if ~exist('playTone','var') || isempty(playTone)
    playTone=true;
end

if any(trialRecords(end).trialNumber > c.consecutiveTrials) && any(length(trialRecords) < c.consecutiveTrials) %this needs to be smarter -- c.consecutiveTrials may have elements both shorter and longer than the buffer
    warning('criterion is longer than the circular buffer set in @station/doTrials (roughly line 76) -- you''ll never graduate -- how architect?')
end

fieldNames = fields(trialRecords);

trialsThisStep=[trialRecords.trainingStepNum]==trialRecords(end).trainingStepNum;

forcedRewards = 0;
stochastic = 0;
humanResponse = 0;

warnStatus = false;

if ismember({'containedForcedRewards'},fieldNames)
    ind = find(cellfun(@isempty,{trialRecords.containedForcedRewards}));
    if ~isempty(ind)
        warning('using pessimistic values for containedForcedRewards');
        for i=1:length(ind)
            trialRecords(ind(i)).containedForcedRewards = 1;
        end
    end
    forcedRewards = [trialRecords.containedForcedRewards]==1;
else
    warnStatus = true;
end
if ismember({'didStochasticResponse'},fieldNames)
    ind = find(cellfun(@isempty,{trialRecords.didStochasticResponse}));
    if ~isempty(ind)
        warning('using pessimistic values for didStochasticResponse');
        for i=1:length(ind)
            trialRecords(ind(i)).didStochasticResponse = 1;
        end
    end
    stochastic = [trialRecords.didStochasticResponse];
else
    warnStatus = true;
end
if ismember({'didHumanResponse'},fieldNames)
    ind = find(cellfun(@isempty,{trialRecords.didHumanResponse}));
    if ~isempty(ind)
        warning('using pessimistic values for didHumanResponse');
        for i=1:length(ind)
            trialRecords(ind(i)).didHumanResponse = 1;
        end
    end
    humanResponse = [trialRecords.didHumanResponse];
else
    warnStatus = true;
end

if warnStatus
    warning(['checkCriterion found trialRecords of the older format. some necessary fields are missing. ensure presence of ' ...
        '''containedForcedRewards'',''didStochasticResponse'' and ''didHumanResponse'' in trialRecords to remove this warning']);
end

try
    dets=[trialRecords.stimDetails]; % will lose last one (current trial), cuz its stimDetails is []
    correction=[[dets.correctionTrial] false];
    
    if length(correction)~=length(trialRecords)
        error('huh?')
    end
    
catch %stimDetails may have changed
    correction=false(1,length(trialRecords));
    for i=1:length(trialRecords)
        try %stimDetails.correctionTrial may not exist (and for sure won't on the last one, the current trial)
            correction(i)=trialRecords(i).stimDetails.correctionTrial;
        end
    end
end

which= trialsThisStep & ~stochastic & ~humanResponse & ~forcedRewards & ~correction;

% modified to allow human responses to count towards graduation (performanceCriterion)
% which= trialsThisStep & ~stochastic & ~forcedRewards & ~correction;

if all(humanResponse)
    warning('you are probably testing with the keyboard and we are throwing out those responses and you are confused')
end

[graduate whichCriteria correct]=aboveThresholdPerformance(c.consecutiveTrials,c.pctCorrect,trialRecords(which));

%play graduation tone
if graduate
    if playTone
        beep;
        WaitSecs(.2);
        beep;
        WaitSecs(.2);
        beep;
    end
    
    if (nargout > 1)
        details.date = now;
        details.criteria = c;
        if false %stepNum not defined, who writes this crap?  pmm writes this crap.
            details.graduatedFrom = stepNum;
            details.allowedGraduationTo = stepNum + 1;
        end
        details.correct = correct;
        details.whichCriteria = whichCriteria;
    end
else
    details=[];
end

if isscalar(c.consecutiveTrials) && c.consecutiveTrials<=length(correct)
    pct = sum(correct(end-double(c.consecutiveTrials)+1:end))/double(c.consecutiveTrials);
    %the first cast of c.consecutiveTrials is necessary due to a matlab bug
    %see request 1-GC4PFP
    % http://www.mathworks.com/support/service_requests/Service_Request_Detail.do?ID=578687
else
    pct = sum(correct)/length(correct);
end