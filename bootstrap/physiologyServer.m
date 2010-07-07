function physiologyServer()


global ai;

% =========================================================================
% ===============
f2=[];
a2=[];
data=[];
ai=[];

% ========================================================================================
% size of the GUI - parameters
oneRowHeight=25;
margin=10;
fieldWidth=100;
fWidth=2*margin+10*fieldWidth;
fHeight=margin+25*oneRowHeight+margin;

ai_parameters=[];
ai_parameters.numChans=3;  % 3 or 16
ai_parameters.sampRate=40000;
ai_parameters.inputRanges=repmat([-1 6],ai_parameters.numChans,1);
ai_parameters.channelConfiguration={'framePulse','photodiode'};
numPhysChannels=ai_parameters.numChans-2;
for i=1:numPhysChannels
    ai_parameters.channelConfiguration{i+2}=['phys' num2str(i)];
end

% ========================================================================================
% lists of values for settings
ampGainStrs = {'','100','1000','10000'}; defaultGainIndex = 3;
ampLPStrs = {'','0.1','1','10','100','300'}; defaultLPIndex = 3;
ampHPStrs = {'','500','1000','5000','10000','20000'};defaultHPIndex = 4;
ampNotchStrs = {'','Out','In'}; defaultNotchIndex = 2;
ampModeStrs = {'','Rec','Imp','Stim'}; defaultModeIndex = 2;


clientIPStrs={'132.239.158.180','132.239.158.179'};  % now we use 180... why was it set to only 179 before november 2009?
ratIDStrs={'demo1','231','356','342','230','calib','test1','306','305','257','252','250','fan_demo1','131','303','138','262','261','249'};
ratProtocolStrs={'setProtocolPhys2','','setProtocolPhys3','ctxCharPtcl','ctxQckNDirtyPtcl','flankerCalibProtocol'};
experimenterStrs={'','pmeier','bsriram','dnguyen','eflister'};
electrodeMakeStrs={'FHC','MPI','gentner','neuronexus'};
electrodeModelStrs={'','UEWMCGLEEN3M','UEWMCGLECN3M','UEWMCGTECN3M','WE3PT35.0A3-ME4925','1x16-100um-413um2'};  
lotNumStrs={'','885191','885192','885431','120016','57','1','6266'};
IDNumStrs={'','1','2','3','4','5','6','7','8','9','10','11','12'};
impedanceStrs={'','.5','1','2','5','10'};

running=false;
recording=false;
keepLooping=false;
runningLoop=false;
recordingT='start recording';
runningT='start trials';
cellT='start cell';
cellActive=false;
externalRequest=[];

neuralFilename=[];
stimFilename=[];
data=[];

eventTypeStrs={'comment','top of fluid','top of brain','ctx cell','hipp cell',...
    'deadzone','theta chatter','visual hash','visual cell','electrode bend','clapping','rat obs',...
    'anesth check'};
visualHashStrs={'weak','strong'};
snrStrs={[]};
for i=1:0.5:7
    snrStrs{end+1}=num2str(i);
end
vcTypeStrs={[],'on','off','unsure'};
vcEyeStrs={[],'ipsi','contra','both'};
vcBurstyStrs={[],'yes','no'};
vcRFAzimuthStrs={[]};
for i=-90:5:180
    vcRFAzimuthStrs{end+1}=num2str(i);
end
vcRFElevationStrs={[]};
for i=-90:5:180
    vcRFElevationStrs{end+1}=num2str(i);
end

arousalStrs={[],'awake','asleep','anesth'};
eyesStrs={[],'open','closed','squinty','stable','saccades','poor signal'};
faceStrs={[],'whisking','no whisking','grinding','licking','squeaking'};

isofluraneStrs={[],'0.0','0.25','0.5','0.75','1.0','1.25','1.5','2.0','2.5','3.0','4.0','5.0','oxy'};
withdrawalStrs={[],'none','sluggish','quick'};
breathPerMinStrs={[],'24-','30','36','42','48','54','60','66','72','78+'};
breathTypeStrs={[],'normal','arrhythmic','wheezing','hooting'};

displayModeStrs={'condensed','stims','full'};

% indices for event types
defaultIndex=1;
visualHashIndex=find(strcmp(eventTypeStrs,'visual hash'));
cellIndices=find(ismember(eventTypeStrs,{'ctx cell','hipp cell','visual cell'}));
visualCellIndex=find(strcmp(eventTypeStrs,'visual cell'));
ratObsIndex=find(strcmp(eventTypeStrs,'rat obs'));
anesthCheckIndex=find(strcmp(eventTypeStrs,'anesth check'));
displayModeIndex=find(strcmp(displayModeStrs,'condensed'));

% ========================================================================================
events_data=[];
labels=[];
eventNum=1;
eventsToSendIndex=1;
savePath=fullfile('\\Reinagel-lab.AD.ucsd.edu\RLAB\Rodent-Data\physiology',ratIDStrs{defaultIndex},...
    datestr(now,'mm.dd.yyyy'));
historyDates={};
historyDateIndex=[];
% d=dir(fullfile(savePath,'*.mat')); % look for existing files
% % should only have one element in d
% if length(d)==1
%     load(fullfile(savePath,d(1).name));
%     disp('loaded existing event data');
% else
%     events_data=[];
% end
% eventNum=length(events_data)+1;
% eventsToSendIndex=eventNum;
% ========================================================================================
% the GUI
f = figure('Visible','off','MenuBar','none','Name','neural GUI',...
    'NumberTitle','off','Resize','off','Units','pixels','Position',[50 50 fWidth fHeight],...
    'CloseRequestFcn',@cleanup);
    function cleanup(source,eventdata)
        % return event here
        %         events = guidata(f);
        %         events_data
        %         save temp events_data;
        if running
            errordlg('must stop running before closing','error','modal')
        else
            FlushEvents('mouseUp','mouseDown','keyDown','autoKey','update');
            ListenChar(0) %'called listenchar(0) -- why doesn''t keyboard work?'
            ShowCursor(0)
            closereq;
            return;
        end
    end % end cleanup function
    function updateDisplay(source,eventdata)
        doDisplayUpdate(displayModeStrs{get(displayModeSelector,'Value')});
    end
    function doDisplayUpdate(mode)
        dispStrs = createDisplayStrs(events_data,labels,mode);
        
        set(recentEventsDisplay,'String',dispStrs);
        % %         dispStrs={};
        % %         for i=length(events_data):-1:1
        % %             dispStrs=[dispStrs;num2str(i)];
        % %         end
        % %         set(eventsSelector,'String',dispStrs);
    end % end function
% quick plot events
% % %         vhToPlot=strcmp({events_data.eventType},'visual hash');
% % %         vcToPlot=strcmp({events_data.eventType},'visual cell');
% % %         vhp=vertcat(events_data(vhToPlot).position);
% % %         vcp=vertcat(events_data(vcToPlot).position);
% % %         if ~exist('f2','var') || isempty(f2)
% % %             f2=figure('Name','physiology events quick plot','NumberTitle','off');
% % %         end
% % %         if ~exist('a2','var') || isempty(a2)
% % %             a2=axes;
% % %         end
% % %
% % %         set(0,'CurrentFigure',f2)
% % %         set(f2,'CurrentAxes',a2)
% % %         hold off
% % %         if ~isempty(vhp)
% % %             plot3(a2,vhp(:,1),vhp(:,2),vhp(:,3),'.');
% % %         end
% % %         hold on
% % %         if ~isempty(vcp)
% % %             plot3(a2,vcp(:,1),vcp(:,2),vcp(:,3),'.r');
% % %         end
% % %         hold off
% % %         xlabel('x position');
% % %         ylabel('y position');
% % %         zlabel('z position');
% % %         grid on;
% % %     end % end updateDisplay function

    function updateUI()
        % updates the physiologyServer UI control panel (not the recent events display)
        if recording
            recordingT='stop recording';
        else
            recordingT='start recording';
        end
        if running
            runningT='stop trials';
        else
            runningT='start trials';
        end
        set(toggleRecordingButton,'String',recordingT);
        set(toggleTrialsButton,'String',runningT);
        set(toggleCellButton,'String',cellT);
        
        % previous, next, and today buttons
        if historyDateIndex>1
            set(previousDayButton,'Enable','on');
        else
            set(previousDayButton,'Enable','off');
        end
        if historyDateIndex==length(historyDates)
            set(nextDayButton,'Enable','off');
            set(todayButton,'Enable','off');
        else
            set(nextDayButton,'Enable','on');
            set(todayButton,'Enable','on');
        end
        
        drawnow;
    end

    function turnOffAllLabelsAndMenus()
        set(visualHashLabel,'Visible','off');
        set(snrLabel,'Visible','off');
        set(vcTypeLabel,'Visible','off');
        set(vcEyeLabel,'Visible','off');
        set(vcBurstyLabel,'Visible','off');
        set(vcRFAzimuthLabel,'Visible','off');
        set(vcRFElevationLabel,'Visible','off');
        set(arousalLabel,'Visible','off');
        set(eyesLabel,'Visible','off');
        set(faceLabel,'Visible','off');
        set(isofluraneLabel,'Visible','off');
        set(withdrawalLabel,'Visible','off');
        set(breathPerMinLabel,'Visible','off');
        set(breathTypeLabel,'Visible','off');
        set(visualHashMenu,'Visible','off','Enable','off');
        set(snrMenu,'Visible','off','Enable','off');
        set(vcTypeMenu,'Visible','off','Enable','off');
        set(vcEyeMenu,'Visible','off','Enable','off');
        set(vcBurstyMenu,'Visible','off','Enable','off');
        set(vcRFAzimuthMenu,'Visible','off','Enable','off');
        set(vcRFElevationMenu,'Visible','off','Enable','off');
        set(arousalMenu,'Visible','off','Enable','off');
        set(eyesMenu,'Visible','off','Enable','off');
        set(faceMenu,'Visible','off','Enable','off');
        set(isofluraneMenu,'Visible','off','Enable','off');
        set(withdrawalMenu,'Visible','off','Enable','off');
        set(breathPerMinMenu,'Visible','off','Enable','off');
        set(breathTypeMenu,'Visible','off','Enable','off');
    end

% =========================================================================
% the grand header!
%GrandHeader = uicontrol(f,'Style','text','String','Physiology Server','Visible','on','Units','pixels',...
%    'FontWeight','bold','HorizontalAlignment','center', 'FontSize',15, ...
%    'Position',[margin+3*fieldWidth fHeight-1.5*oneRowHeight-margin 3*fieldWidth oneRowHeight]);

% =========================================================================
% date selector for which day's event to show and write to
dateField = uicontrol(f,'Style','text','String',datestr(now,'mm.dd.yyyy'),'Visible','on','Units','pixels',...
    'HorizontalAlignment','center',...
    'Position',[margin+4.4*fieldWidth fHeight-0.9*oneRowHeight-margin fieldWidth*0.6 oneRowHeight*0.8]);
nextDayButton = uicontrol(f,'Style','pushbutton','String','>','Visible','on','Units','pixels','Enable','off',...
    'FontWeight','bold','HorizontalAlignment','center','CallBack',@nextDay, ...
    'Position',[2*margin+4.9*fieldWidth fHeight-0.9*oneRowHeight-margin 2*margin oneRowHeight*0.8]);
    function nextDay(source,eventdata)
        historyDateIndex=historyDateIndex+1;
        set(dateField,'String',historyDates{historyDateIndex});
        updateUI();
        reloadEventsAndSurgeryFields([],[],false);
    end
previousDayButton = uicontrol(f,'Style','pushbutton','String','<','Visible','on','Units','pixels','Enable','on',...
    'FontWeight','bold','HorizontalAlignment','center','CallBack',@previousDay, ...
    'Position',[0*margin+4.3*fieldWidth fHeight-0.9*oneRowHeight-margin 2*margin oneRowHeight*0.8]);
    function previousDay(source,eventdata)
        historyDateIndex=historyDateIndex-1;
        set(dateField,'String',historyDates{historyDateIndex});
        updateUI();
        reloadEventsAndSurgeryFields([],[],false);
    end
todayButton = uicontrol(f,'Style','pushbutton','String','>>','Visible','on','Units','pixels','Enable','off',...
    'FontWeight','bold','HorizontalAlignment','center','CallBack',@goToToday, ...
    'Position',[4*margin+4.9*fieldWidth fHeight-0.9*oneRowHeight-margin 2*margin oneRowHeight*0.8]);
    function goToToday(source,eventdata)
        historyDateIndex=length(historyDates);
        set(dateField,'String',historyDates{historyDateIndex});
        updateUI();
        reloadEventsAndSurgeryFields([],[],false);
    end




% ========================================================================================
% draw text labels for the rig state
DistHeader = uicontrol(f,'Style','text','String','Distance','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+fieldWidth fHeight-1*oneRowHeight-margin fieldWidth oneRowHeight]);
HeightHeader = uicontrol(f,'Style','text','String','Height','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+2*fieldWidth fHeight-1*oneRowHeight-margin fieldWidth oneRowHeight]);
AngleHeader = uicontrol(f,'Style','text','String','Angle','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+3*fieldWidth fHeight-1*oneRowHeight-margin fieldWidth oneRowHeight]);
rigStateLabel = uicontrol(f,'Style','text','String','Rig State','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+0*fieldWidth fHeight-2*oneRowHeight-margin fieldWidth oneRowHeight]);
rigDistField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+1*fieldWidth fHeight-2*oneRowHeight-margin fieldWidth oneRowHeight]);
rigHeightField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+2*fieldWidth fHeight-2*oneRowHeight-margin fieldWidth oneRowHeight]);
rigAngleField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+3*fieldWidth fHeight-2*oneRowHeight-margin fieldWidth oneRowHeight]);

% checkbox to enable rig field input
enableRigStateFields = uicontrol(f,'Style','checkbox',...
    'String','unlock rig fields','Enable','on','Visible','on',...
    'Value',0,'Units','pixels','Position',[2*margin+4*fieldWidth fHeight-2*oneRowHeight-margin fieldWidth+margin*3 oneRowHeight],...
    'CallBack',@enableRigStateEntry);
    function enableRigStateEntry(source,eventdata)
        if get(enableRigStateFields,'Value')==1
            set(rigDistField,'Enable','on');
            set(rigHeightField,'Enable','on');
            set(rigAngleField,'Enable','on');
        else
            set(rigDistField,'Enable','off');
            set(rigHeightField,'Enable','off');
            set(rigAngleField,'Enable','off');
        end
    end % end enableRigStateEntry function

% ========================================================================================
% draw text labels for the Amp settings
ampGainHeader = uicontrol(f,'Style','text','String','Gain','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+fieldWidth fHeight-3*oneRowHeight-margin fieldWidth/2 oneRowHeight]);
ampLPHeader = uicontrol(f,'Style','text','String','LCO','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+1.5*fieldWidth fHeight-3*oneRowHeight-margin fieldWidth/2 oneRowHeight]);
ampHPHeader = uicontrol(f,'Style','text','String','HCO','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+2*fieldWidth fHeight-3*oneRowHeight-margin fieldWidth/2 oneRowHeight]);
ampNotchHeader = uicontrol(f,'Style','text','String','Notch','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+2.5*fieldWidth fHeight-3*oneRowHeight-margin fieldWidth/2 oneRowHeight]);
ampModeHeader = uicontrol(f,'Style','text','String','Mode','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+3*fieldWidth fHeight-3*oneRowHeight-margin fieldWidth/2 oneRowHeight]);
ampCapCompHeader = uicontrol(f,'Style','text','String','Cap','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+3.5*fieldWidth fHeight-3*oneRowHeight-margin fieldWidth/2 oneRowHeight]);

ampStateLabel = uicontrol(f,'Style','text','String','Amp Settings','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+0*fieldWidth fHeight-4*oneRowHeight-margin fieldWidth oneRowHeight]);
ampGainField = uicontrol(f,'Style','popupmenu','String',ampGainStrs,'Units','pixels','Value',defaultGainIndex,...
    'Enable','off','Position',[1*margin+1*fieldWidth fHeight-4*oneRowHeight-margin fieldWidth/2 oneRowHeight],'BackgroundColor','w');
ampLPField = uicontrol(f,'Style','popupmenu','String',ampLPStrs,'Units','pixels','Value',defaultLPIndex,...
    'Enable','off','Position',[1*margin+1.5*fieldWidth fHeight-4*oneRowHeight-margin fieldWidth/2 oneRowHeight],'BackgroundColor','w');
ampHPField = uicontrol(f,'Style','popupmenu','String',ampHPStrs,'Units','pixels','Value',defaultHPIndex,...
    'Enable','off','Position',[1*margin+2*fieldWidth fHeight-4*oneRowHeight-margin fieldWidth/2 oneRowHeight],'BackgroundColor','w');
ampNotchField = uicontrol(f,'Style','popupmenu','String',ampNotchStrs,'Units','pixels','Value',defaultNotchIndex,...
    'Enable','off','Position',[1*margin+2.5*fieldWidth fHeight-4*oneRowHeight-margin fieldWidth/2 oneRowHeight],'BackgroundColor','w');
ampModeField = uicontrol(f,'Style','popupmenu','String',ampModeStrs,'Units','pixels','Value',defaultModeIndex,...
    'Enable','off','Position',[1*margin+3*fieldWidth fHeight-4*oneRowHeight-margin fieldWidth/2 oneRowHeight],'BackgroundColor','w');
ampCapCompField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+3.5*fieldWidth fHeight-4*oneRowHeight-margin fieldWidth/2 oneRowHeight],'BackgroundColor','w');

% checkbox to enable amp field input
enableAmpStateFields = uicontrol(f,'Style','checkbox',...
    'String','unlock amp fields','Enable','on','Visible','on',...
    'Value',0,'Units','pixels','Position',[2*margin+4*fieldWidth fHeight-4*oneRowHeight-margin fieldWidth+margin*3 oneRowHeight],...
    'CallBack',@enableAmpStateEntry);
    function enableAmpStateEntry(source,eventdata)
        if get(enableAmpStateFields,'Value')==1
            set(ampGainField,'Enable','on');
            set(ampLPField,'Enable','on');
            set(ampHPField,'Enable','on');
            set(ampNotchField,'Enable','on');
            set(ampModeField,'Enable','on');
            set(ampCapCompField,'Enable','on');
        else
            set(ampGainField,'Enable','off');
            set(ampLPField,'Enable','off');
            set(ampHPField,'Enable','off');
            set(ampNotchField,'Enable','off');
            set(ampModeField,'Enable','off');
            set(ampCapCompField,'Enable','off');
        end
    end % end enableAmpStateEntry function

% ========================================================================================
% draw text labels for the lens state
Lens1DistHeader = uicontrol(f,'Style','text','String','L1 Distance','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+6.5*fieldWidth fHeight-3*oneRowHeight-margin 0.75*fieldWidth oneRowHeight]);
Lens1PowerHeader = uicontrol(f,'Style','text','String','L1 Power','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+7.25*fieldWidth fHeight-3*oneRowHeight-margin 0.75*fieldWidth oneRowHeight]);
Lens2DistHeader = uicontrol(f,'Style','text','String','L2 Distance','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+8.0*fieldWidth fHeight-3*oneRowHeight-margin 0.75*fieldWidth oneRowHeight]);
Lens2PowerHeader = uicontrol(f,'Style','text','String','L2 Power','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+8.75*fieldWidth fHeight-3*oneRowHeight-margin 0.75*fieldWidth oneRowHeight]);

lensStateLabel = uicontrol(f,'Style','text','String','Lens settings','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+5.5*fieldWidth fHeight-4*oneRowHeight-margin fieldWidth oneRowHeight]);

lens1DistField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[margin+6.5*fieldWidth fHeight-4*oneRowHeight-margin 0.75*fieldWidth oneRowHeight]);
lens1PowerField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[margin+7.25*fieldWidth fHeight-4*oneRowHeight-margin 0.75*fieldWidth oneRowHeight]);
lens2DistField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[margin+8.0*fieldWidth fHeight-4*oneRowHeight-margin 0.75*fieldWidth oneRowHeight]);
lens2PowerField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[margin+8.75*fieldWidth fHeight-4*oneRowHeight-margin 0.75*fieldWidth oneRowHeight]);

% checkbox to enable rig field input
enableLens1StateFields = uicontrol(f,'Style','checkbox',...
    'String','unlock lens1 fields','Enable','on','Visible','on',...
    'Value',0,'Units','pixels','Position',[2*margin+6.55*fieldWidth fHeight-4.8*oneRowHeight-margin fieldWidth+margin*3 0.8*oneRowHeight],...
    'CallBack',@enableLens1StateEntry);
enableLens2StateFields = uicontrol(f,'Style','checkbox',...
    'String','unlock lens2 fields','Enable','on','Visible','on',...
    'Value',0,'Units','pixels','Position',[2*margin+8.05*fieldWidth fHeight-4.8*oneRowHeight-margin fieldWidth+margin*3 0.8*oneRowHeight],...
    'CallBack',@enableLens2StateEntry);
    function enableLens1StateEntry(source,eventdata)
        if get(enableLens1StateFields,'Value')==1
            set(lens1DistField,'Enable','on');
            set(lens1PowerField,'Enable','on');
        else
            set(lens1DistField,'Enable','off');
            set(lens1PowerField,'Enable','off');
        end
    end % end enableLens1StateEntry function

    function enableLens2StateEntry(source,eventdata)
        if get(enableLens2StateFields,'Value')==1
            set(enableLens1StateFields,'Value',1); enableLens1StateEntry();
            set(lens2DistField,'Enable','on');
            set(lens2PowerField,'Enable','on');
        else
            set(lens2DistField,'Enable','off');
            set(lens2PowerField,'Enable','off');
        end
    end % end enableLens2StateEntry function


% ========================================================================================

% draw text labels for surgery anchor
APHeader = uicontrol(f,'Style','text','String','AP','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+fieldWidth fHeight-6*oneRowHeight-margin fieldWidth oneRowHeight]);
MLHeader = uicontrol(f,'Style','text','String','ML','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+2*fieldWidth fHeight-6*oneRowHeight-margin fieldWidth oneRowHeight]);
ZHeader = uicontrol(f,'Style','text','String','Z','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+3*fieldWidth fHeight-6*oneRowHeight-margin fieldWidth oneRowHeight]);
surgeryAnchorLabel = uicontrol(f,'Style','text','String','Surgery Anchor','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+0*fieldWidth fHeight-7*oneRowHeight-margin fieldWidth oneRowHeight]);
surgeryBregmaLabel = uicontrol(f,'Style','text','String','Surgery Bregma','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+0*fieldWidth fHeight-8*oneRowHeight-margin fieldWidth oneRowHeight]);

% ========================================================================================
% surgery anchor and bregma text fields
surgeryAnchorAPField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+1*fieldWidth fHeight-7*oneRowHeight-margin fieldWidth oneRowHeight]);
surgeryAnchorMLField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+2*fieldWidth fHeight-7*oneRowHeight-margin fieldWidth oneRowHeight]);
surgeryAnchorZField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+3*fieldWidth fHeight-7*oneRowHeight-margin fieldWidth oneRowHeight]);
surgeryBregmaAPField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+1*fieldWidth fHeight-8*oneRowHeight-margin fieldWidth oneRowHeight]);
surgeryBregmaMLField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+2*fieldWidth fHeight-8*oneRowHeight-margin fieldWidth oneRowHeight]);
surgeryBregmaZField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+3*fieldWidth fHeight-8*oneRowHeight-margin fieldWidth oneRowHeight]);

% checkbox to enable surgery field input
enableSurgeryFields = uicontrol(f,'Style','checkbox',...
    'String','unlock surgery fields','Enable','on','Visible','on',...
    'Value',0,'Units','pixels','Position',[2*margin+4*fieldWidth fHeight-7*oneRowHeight-margin fieldWidth+margin*3 oneRowHeight],...
    'CallBack',@enableSurgeryEntry);
    function enableSurgeryEntry(source,eventdata)
        if get(enableSurgeryFields,'Value')==1
            set(surgeryAnchorAPField,'Enable','on');
            set(surgeryAnchorMLField,'Enable','on');
            set(surgeryAnchorZField,'Enable','on');
            set(surgeryBregmaAPField,'Enable','on');
            set(surgeryBregmaMLField,'Enable','on');
            set(surgeryBregmaZField,'Enable','on');
        else
            set(surgeryAnchorAPField,'Enable','off');
            set(surgeryAnchorMLField,'Enable','off');
            set(surgeryAnchorZField,'Enable','off');
            set(surgeryBregmaAPField,'Enable','off');
            set(surgeryBregmaMLField,'Enable','off');
            set(surgeryBregmaZField,'Enable','off');
        end
    end % end enableSurgeryEntry function

% ========================================================================================
% current anchor label
currentAnchorLabel = uicontrol(f,'Style','text','String','Current Anchor','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+0*fieldWidth fHeight-9*oneRowHeight-margin fieldWidth oneRowHeight]);
% current anchor text field
currentAnchorAPField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+1*fieldWidth fHeight-9*oneRowHeight-margin fieldWidth oneRowHeight]);
currentAnchorMLField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+2*fieldWidth fHeight-9*oneRowHeight-margin fieldWidth oneRowHeight]);
currentAnchorZField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+3*fieldWidth fHeight-9*oneRowHeight-margin fieldWidth oneRowHeight]);

% checkbox to enable current anchor field input
enableCurrentAnchorField = uicontrol(f,'Style','checkbox',...
    'String','unlock current anchor','Enable','on','Visible','on',...
    'Value',0,'Units','pixels','Position',[2*margin+4*fieldWidth fHeight-9*oneRowHeight-margin fieldWidth+margin*3 oneRowHeight],...
    'CallBack',@enableCurrentAnchorEntry);
    function enableCurrentAnchorEntry(source,eventdata)
        if get(enableCurrentAnchorField,'Value')==1
            set(currentAnchorAPField,'Enable','on');
            set(currentAnchorMLField,'Enable','on');
            set(currentAnchorZField,'Enable','on');
        else
            set(currentAnchorAPField,'Enable','off');
            set(currentAnchorMLField,'Enable','off');
            set(currentAnchorZField,'Enable','off');
        end
    end % end enableCurrentAnchorEntry function

% ========================================================================================
% calculated theoretical center of LGN display
theoreticalLGNCenterLabel = uicontrol(f,'Style','text','String','theor. LGN center','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+0*fieldWidth fHeight-10*oneRowHeight-margin fieldWidth oneRowHeight]);
theoreticalLGNCenterAPField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+1*fieldWidth fHeight-10*oneRowHeight-margin fieldWidth oneRowHeight],...
    'HorizontalAlignment','center');
theoreticalLGNCenterMLField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+2*fieldWidth fHeight-10*oneRowHeight-margin fieldWidth oneRowHeight],...
    'HorizontalAlignment','center');
theoreticalLGNCenterZField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+3*fieldWidth fHeight-10*oneRowHeight-margin fieldWidth oneRowHeight],...
    'HorizontalAlignment','center');

% ========================================================================================
% calculated current - what is 'current' anyways?
currentLabel = uicontrol(f,'Style','text','String','Current','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+0*fieldWidth fHeight-11*oneRowHeight-margin fieldWidth oneRowHeight]);
currentAPField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+1*fieldWidth fHeight-11*oneRowHeight-margin fieldWidth oneRowHeight],...
    'HorizontalAlignment','center');
currentMLField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+2*fieldWidth fHeight-11*oneRowHeight-margin fieldWidth oneRowHeight],...
    'HorizontalAlignment','center');
currentZField = uicontrol(f,'Style','edit','String','nan','Units','pixels',...
    'Enable','off','Position',[1*margin+3*fieldWidth fHeight-11*oneRowHeight-margin fieldWidth oneRowHeight],...
    'HorizontalAlignment','center');

% ========================================================================================
% penetration parameters (ratID, experimenter, electrode make/model, lot#, ID#, impedance)
clientIPLabel = uicontrol(f,'Style','text','String','Client IP','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+7*fieldWidth fHeight-6*oneRowHeight-margin fieldWidth oneRowHeight]);
ratIDLabel = uicontrol(f,'Style','text','String','Rat ID','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+7*fieldWidth fHeight-7*oneRowHeight-margin fieldWidth oneRowHeight]);
ratProtocolLabel = uicontrol(f,'Style','text','String','Protocol','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+7*fieldWidth fHeight-8*oneRowHeight-margin fieldWidth oneRowHeight]);
experimenterLabel = uicontrol(f,'Style','text','String','Experimenter','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+7*fieldWidth fHeight-9*oneRowHeight-margin fieldWidth oneRowHeight]);
electrodeMakeLabel = uicontrol(f,'Style','text','String','electrode make','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+7*fieldWidth fHeight-10*oneRowHeight-margin fieldWidth oneRowHeight]);
electrodeModelLabel = uicontrol(f,'Style','text','String','electrode model','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+7*fieldWidth fHeight-11*oneRowHeight-margin fieldWidth oneRowHeight]);
lotNumLabel = uicontrol(f,'Style','text','String','lot #','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+7*fieldWidth fHeight-12*oneRowHeight-margin fieldWidth oneRowHeight]);
IDNumLabel = uicontrol(f,'Style','text','String','ID #','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+7*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
impedanceLabel = uicontrol(f,'Style','text','String','impedance','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+7*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);

clientIPField = uicontrol(f,'Style','popupmenu','String',clientIPStrs,'Units','pixels','Value',defaultIndex,...
    'Enable','on','Position',[margin+8*fieldWidth fHeight-6*oneRowHeight-margin 1.1*fieldWidth oneRowHeight],...
    'BackgroundColor','w');
deleteDbInClient = uicontrol(f,'Style','checkbox','String','delete db','Enable','on','Visible','on',...
    'Value',1,'Units','pixels','Position',[margin+9.2*fieldWidth fHeight-6*oneRowHeight-margin fieldWidth*0.7 oneRowHeight]);

ratIDField = uicontrol(f,'Style','popupmenu','String',ratIDStrs,'Units','pixels','Value',defaultIndex,...
    'Enable','on','Position',[margin+8*fieldWidth fHeight-7*oneRowHeight-margin 1.1*fieldWidth oneRowHeight],...
    'BackgroundColor','w','Callback',@reloadEventsAndSurgeryFields);
    function reloadEventsAndSurgeryFields(source,eventdata,reloadHistory)
        if ~exist('reloadHistory','var')
            reloadHistory=true;
        end
        % reload physiology event log
        savePath=fullfile('\\Reinagel-lab.AD.ucsd.edu\RLAB\Rodent-Data\physiology',ratIDStrs{get(ratIDField,'Value')});
        if reloadHistory
            d=dir(savePath);
            historyDates={};
            historyDateIndex=[];
            for dd=1:length(d)
                match=regexp(d(dd).name,'\d{2}\.\d{2}\.\d{4}','match');
                if ~isempty(match)
                    historyDates{end+1}=d(dd).name;
                end
            end
            historyDateIndex=find(strcmp(datestr(now,'mm.dd.yyyy'),historyDates));
            if isempty(historyDateIndex)
                historyDates{end+1}=datestr(now,'mm.dd.yyyy');
                historyDateIndex=length(historyDates);
            end
            set(dateField,'String',historyDates{historyDateIndex});
        end
        savePath=fullfile(savePath,get(dateField,'String'));
        d=dir(fullfile(savePath,'*.mat')); % look for existing files
        % should only have one element in d
        if length(d)==1
            events_data=load(fullfile(savePath,d(1).name));
            if isfield(events_data,'labels')
                labels=events_data.labels;
            else
                labels=nan*ones(1,length(events_data.events_data));
            end
            events_data=events_data.events_data;
            cellStartInds=find(strcmp({events_data.eventType},'cell start'));
            cellStopInds=find(strcmp({events_data.eventType},'cell stop'));
            if length(cellStopInds)==length(cellStartInds)
                cellT='start cell';
                cellActive=false;
            else
                cellT='stop cell';
                cellActive=true;
            end
        else
            events_data=[];
        end
        eventNum=length(events_data)+1;
        eventsToSendIndex=eventNum;
        updateDisplay();
        % get surgery anchor and bregma fields from oracle if possible
        surgValuesinOracle = 0;
        try
            conn=dbConn();
            surg=struct2array(getSurgeryFields(conn,ratIDStrs{get(ratIDField,'Value')}));
            
            % is any of surg values a NaN? %
            surgValuesisNaN = isnan(surg);
            if(any(surgValuesisNaN))
                error('this is weird. there is no entry in db. yet the procedure does not error out!')
            else
                set(surgeryAnchorAPField,'String',num2str(surg(1)));
                set(surgeryAnchorMLField,'String',num2str(surg(2)));
                set(surgeryAnchorZField,'String',num2str(surg(3)));
                set(surgeryBregmaAPField,'String',num2str(surg(4)));
                set(surgeryBregmaMLField,'String',num2str(surg(5)));
                set(surgeryBregmaZField,'String',num2str(surg(6)));
                surgValuesinOracle = 1;
            end
        catch ex
            
            warning('could not get surgery fields from oracle. trying to obtain these fields from server.');
        end
        [rigState ampState lensState surgBregma surgAnchor currAnchor currPositn penetParams isNewDay] = ...
            getDataFromEventLog(fullfile('\\Reinagel-lab.AD.ucsd.edu\RLAB\Rodent-Data\physiology',ratIDStrs{get(ratIDField,'Value')},''));
%         rigState
%         ampState
%         lensState
%         surgBregma
%         surgAnchor
%         currAnchor
%         currPositn
%         penetParams
%         isNewDay
        if ~surgValuesinOracle
            % look for anchor data in the events_log
            set(surgeryAnchorAPField,'String',num2str(surgAnchor(1)));
            set(surgeryAnchorMLField,'String',num2str(surgAnchor(2)));
            set(surgeryAnchorZField,'String',num2str(surgAnchor(3)));
            set(surgeryBregmaAPField,'String',num2str(surgBregma(1)));
            set(surgeryBregmaMLField,'String',num2str(surgBregma(2)));
            set(surgeryBregmaZField,'String',num2str(surgBregma(3)));
        end
        if isNewDay
            set(enableCurrentAnchorField,'Value',1);enableCurrentAnchorEntry();
            set(currentAnchorAPField,'String',num2str(currAnchor(1)),'BackgroundColor','r');
            set(currentAnchorMLField,'String',num2str(currAnchor(2)),'BackgroundColor','r');
            set(currentAnchorZField,'String',num2str(currAnchor(3)),'BackgroundColor','r');
            set(enableRigStateFields,'Value',1);enableRigStateEntry();
            set(rigDistField,'String',num2str(rigState(1)),'BackgroundColor','r');
            set(rigHeightField,'String',num2str(rigState(2)),'BackgroundColor','r');
            set(rigAngleField,'String',num2str(rigState(3)),'BackgroundColor','r');
            set(enableAmpStateFields,'Value',1);enableAmpStateEntry();
            set(ampGainField, 'Value',find(strcmp(ampState{1},ampGainStrs)),'BackgroundColor','r');
            set(ampLPField, 'Value',find(strcmp(ampState{2},ampLPStrs)),'BackgroundColor','r');
            set(ampHPField, 'Value',find(strcmp(ampState{3},ampHPStrs)),'BackgroundColor','r');
            set(ampNotchField, 'Value',find(strcmp(ampState{4},ampNotchStrs)),'BackgroundColor','r');
            set(ampModeField, 'Value',find(strcmp(ampState{5},ampModeStrs)),'BackgroundColor','r');
            set(ampCapCompField, 'Value',ampState{6},'BackgroundColor','r');
            set(enableLens1StateFields,'Value',1);enableLens1StateEntry();
            set(enableLens2StateFields,'Value',1);enableLens2StateEntry();
            set(lens1DistField,'String',num2str(lensState(1)),'BackgroundColor','r');
            set(lens1PowerField,'String',num2str(lensState(2)),'BackgroundColor','r');
            set(lens2DistField,'String',num2str(lensState(3)),'BackgroundColor','r');
            set(lens2PowerField,'String',num2str(lensState(4)),'BackgroundColor','r');

        else
            set(currentAnchorAPField,'String',num2str(currAnchor(1)),'BackgroundColor','w');
            set(currentAnchorMLField,'String',num2str(currAnchor(2)),'BackgroundColor','w');
            set(currentAnchorZField,'String',num2str(currAnchor(3)),'BackgroundColor','w');
            set(rigDistField,'String',num2str(rigState(1)),'BackgroundColor','w');
            set(rigHeightField,'String',num2str(rigState(2)),'BackgroundColor','w');
            set(rigAngleField,'String',num2str(rigState(3)),'BackgroundColor','w');
            set(ampGainField, 'Value',find(strcmp(ampState{1},ampGainStrs)),'BackgroundColor','w');
            set(ampLPField, 'Value',find(strcmp(ampState{2},ampLPStrs)),'BackgroundColor','w');
            set(ampHPField, 'Value',find(strcmp(ampState{3},ampHPStrs)),'BackgroundColor','w');
            set(ampNotchField, 'Value',find(strcmp(ampState{4},ampNotchStrs)),'BackgroundColor','w');
            set(ampModeField, 'Value',find(strcmp(ampState{5},ampModeStrs)),'BackgroundColor','w');
            set(ampCapCompField, 'Value',ampState{6},'BackgroundColor','w');
            set(lens1DistField,'String',num2str(lensState(1)),'BackgroundColor','w');
            set(lens1PowerField,'String',num2str(lensState(2)),'BackgroundColor','w');
            set(lens2DistField,'String',num2str(lensState(3)),'BackgroundColor','w');
            set(lens2PowerField,'String',num2str(lensState(4)),'BackgroundColor','w');
        end
        set(offsetAPField,'String',num2str(currPositn(1)));
        set(offsetMLField,'String',num2str(currPositn(2)));
        set(offsetZField,'String',num2str(currPositn(3)));
        if ~isempty(penetParams)
            if ~isempty(penetParams.experimenter)
                set(experimenterField,'Value',find(strcmp(penetParams.experimenter,experimenterStrs)),'BackgroundColor','w');
            else
                set(experimenterField,'String',experimenterStrs,'Value',defaultIndex,'BackgroundColor','r');
            end
            
            if ~isempty(penetParams.electrodeMake)
                set(electrodeMakeField,'Value',find(strcmp(penetParams.electrodeMake,electrodeMakeStrs)),'BackgroundColor','w');
            else
                set(electrodeMakeField,'String',electrodeMakeStrs,'Value',defaultIndex,'BackgroundColor','r');
            end
            
            if ~isempty(penetParams.electrodeModel)
                set(electrodeModelField,'Value',find(strcmp(penetParams.electrodeModel,electrodeModelStrs)),'BackgroundColor','w');
            else
                set(electrodeModelField,'String',electrodeModelStrs,'Value',defaultIndex,'BackgroundColor','r');
            end
            
            if ~isempty(penetParams.lotNum)
                set(lotNumField,'Value',find(strcmp(penetParams.lotNum,lotNumStrs)),'BackgroundColor','w');
            else
                set(lotNumField,'String',lotNumStrs,'Value',defaultIndex,'BackgroundColor','r');
            end
            
            if ~isempty(penetParams.IDNum)
                set(IDNumField,'Value',find(strcmp(penetParams.IDNum,IDNumStrs)),'BackgroundColor','w');
            else
                set(IDNumField,'String',IDNumStrs,'Value',defaultIndex,'BackgroundColor','r');
            end
            
            if ~isempty(penetParams.impedance)
                set(impedanceField,'Value',find(strcmp(penetParams.impedance,impedanceStrs)),'BackgroundColor','w');
            else
                set(impedanceField,'String',impedanceStrs,'Value',defaultIndex,'BackgroundColor','r');
            end  
        end
    end
ratProtocolField = uicontrol(f,'Style','popupmenu','String',ratProtocolStrs,'Units','pixels','Value',defaultIndex,...
    'Enable','on','Position',[margin+8*fieldWidth fHeight-8*oneRowHeight-margin 1.1*fieldWidth oneRowHeight],'BackgroundColor','w');
experimenterField = uicontrol(f,'Style','popupmenu','String',experimenterStrs,'Units','pixels','Value',defaultIndex,...
    'Enable','on','Position',[margin+8*fieldWidth fHeight-9*oneRowHeight-margin 1.1*fieldWidth oneRowHeight],'BackgroundColor','w');
electrodeMakeField = uicontrol(f,'Style','popupmenu','String',electrodeMakeStrs,'Units','pixels','Value',defaultIndex,...
    'Enable','on','Position',[margin+8*fieldWidth fHeight-10*oneRowHeight-margin 1.1*fieldWidth oneRowHeight],'BackgroundColor','w');
electrodeModelField = uicontrol(f,'Style','popupmenu','String',electrodeModelStrs,'Units','pixels','Value',defaultIndex,...
    'Enable','on','Position',[margin+8*fieldWidth fHeight-11*oneRowHeight-margin 1.1*fieldWidth oneRowHeight],'BackgroundColor','w');
lotNumField = uicontrol(f,'Style','popupmenu','String',lotNumStrs,'Units','pixels','Value',defaultIndex,...
    'Enable','on','Position',[margin+8*fieldWidth fHeight-12*oneRowHeight-margin 1.1*fieldWidth oneRowHeight],'BackgroundColor','w');
IDNumField = uicontrol(f,'Style','popupmenu','String',IDNumStrs,'Units','pixels','Value',defaultIndex,...
    'Enable','on','Position',[margin+8*fieldWidth fHeight-13*oneRowHeight-margin 1.1*fieldWidth oneRowHeight],'BackgroundColor','w');
impedanceField = uicontrol(f,'Style','popupmenu','String',impedanceStrs,'Units','pixels','Value',defaultIndex,...
    'Enable','on','Position',[margin+8*fieldWidth fHeight-14*oneRowHeight-margin 1.1*fieldWidth oneRowHeight],'BackgroundColor','w');

% ========================================================================================
% current event parameters - labels
eventTypeLabel = uicontrol(f,'Style','text','String','event type','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+0*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
visualHashLabel = uicontrol(f,'Style','text','String','visual hash','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+1*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
snrLabel = uicontrol(f,'Style','text','String','SNR','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+1*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
vcTypeLabel = uicontrol(f,'Style','text','String','vc type','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+2*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
vcEyeLabel = uicontrol(f,'Style','text','String','vc eye','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+3*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
vcBurstyLabel = uicontrol(f,'Style','text','String','vc bursty','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+4*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
vcRFAzimuthLabel = uicontrol(f,'Style','text','String','vc RF azimuth','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+5*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
vcRFElevationLabel = uicontrol(f,'Style','text','String','vc RF elevation (+ is up/right)','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+6*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
arousalLabel = uicontrol(f,'Style','text','String','arousal','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+1*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
eyesLabel = uicontrol(f,'Style','text','String','eyes','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+2*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
faceLabel = uicontrol(f,'Style','text','String','face','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+3*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
isofluraneLabel = uicontrol(f,'Style','text','String','isoflurane','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+1*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
withdrawalLabel = uicontrol(f,'Style','text','String','withdrawal','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+2*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
breathPerMinLabel = uicontrol(f,'Style','text','String','breath/min','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+3*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);
breathTypeLabel = uicontrol(f,'Style','text','String','breath type','Visible','off','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+4*fieldWidth fHeight-13*oneRowHeight-margin fieldWidth oneRowHeight]);

% ========================================================================================
% current event parameters - dropdown menus
eventTypeMenu = uicontrol(f,'Style','popupmenu','String',eventTypeStrs,'Visible','on','Units','pixels',...
    'Enable','on','Value',defaultIndex,'Callback',@eventTypeC,...
    'Position',[margin+0*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
    function eventTypeC(source,eventdata)
        turnOffAllLabelsAndMenus();
        if get(eventTypeMenu,'Value')==visualHashIndex
            set(visualHashLabel,'Visible','on');
            set(visualHashMenu,'Visible','on','Enable','on');
        elseif get(eventTypeMenu,'Value')==ratObsIndex
            set(arousalLabel,'Visible','on');
            set(eyesLabel,'Visible','on');
            set(faceLabel,'Visible','on');
            set(arousalMenu,'Visible','on','Enable','on');
            set(eyesMenu,'Visible','on','Enable','on');
            set(faceMenu,'Visible','on','Enable','on');
        elseif get(eventTypeMenu,'Value')==anesthCheckIndex
            set(isofluraneLabel,'Visible','on');
            set(withdrawalLabel,'Visible','on');
            set(breathPerMinLabel,'Visible','on');
            set(breathTypeLabel,'Visible','on');
            set(isofluraneMenu,'Visible','on','Enable','on');
            set(withdrawalMenu,'Visible','on','Enable','on');
            set(breathPerMinMenu,'Visible','on','Enable','on');
            set(breathTypeMenu,'Visible','on','Enable','on');
        elseif any(cellIndices==get(eventTypeMenu,'Value'))
            set(snrLabel,'Visible','on');
            set(snrMenu,'Visible','on','Enable','on');
            if get(eventTypeMenu,'Value')==visualCellIndex
                set(vcTypeLabel,'Visible','on');
                set(vcEyeLabel,'Visible','on');
                set(vcBurstyLabel,'Visible','on');
                set(vcRFAzimuthLabel,'Visible','on');
                set(vcRFElevationLabel,'Visible','on');
                set(vcTypeMenu,'Visible','on','Enable','on');
                set(vcEyeMenu,'Visible','on','Enable','on');
                set(vcBurstyMenu,'Visible','on','Enable','on');
                set(vcRFAzimuthMenu,'Visible','on','Enable','on');
                set(vcRFElevationMenu,'Visible','on','Enable','on');
            end
        else
            % do nothing - already all off
        end
    end % end function

visualHashMenu = uicontrol(f,'Style','popupmenu','String',visualHashStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+1*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
snrMenu = uicontrol(f,'Style','popupmenu','String',snrStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+1*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
vcTypeMenu = uicontrol(f,'Style','popupmenu','String',vcTypeStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+2*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
vcEyeMenu = uicontrol(f,'Style','popupmenu','String',vcEyeStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+3*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
vcBurstyMenu = uicontrol(f,'Style','popupmenu','String',vcBurstyStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+4*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
vcRFAzimuthMenu = uicontrol(f,'Style','popupmenu','String',vcRFAzimuthStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+5*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
vcRFElevationMenu = uicontrol(f,'Style','popupmenu','String',vcRFElevationStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+6*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
arousalMenu = uicontrol(f,'Style','popupmenu','String',arousalStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+1*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
eyesMenu = uicontrol(f,'Style','popupmenu','String',eyesStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+2*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
faceMenu = uicontrol(f,'Style','popupmenu','String',faceStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+3*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
isofluraneMenu = uicontrol(f,'Style','popupmenu','String',isofluraneStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+1*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
withdrawalMenu = uicontrol(f,'Style','popupmenu','String',withdrawalStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+2*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
breathPerMinMenu = uicontrol(f,'Style','popupmenu','String',breathPerMinStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+3*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);
breathTypeMenu = uicontrol(f,'Style','popupmenu','String',breathTypeStrs,'Visible','off','Units','pixels',...
    'Enable','off','Value',defaultIndex,...
    'Position',[margin+4*fieldWidth fHeight-14*oneRowHeight-margin fieldWidth oneRowHeight]);

% ========================================================================================
% offset event label, fields, and "submit" button
offsetEventLabel = uicontrol(f,'Style','text','String','Offset','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center', ...
    'Position',[margin+0*fieldWidth fHeight-15*oneRowHeight-2*margin fieldWidth oneRowHeight]);
offsetAPField = uicontrol(f,'Style','edit','Units','pixels','String','nan',...
    'Enable','on','Position',[1*margin+1*fieldWidth fHeight-15*oneRowHeight-2*margin fieldWidth oneRowHeight]);
offsetMLField = uicontrol(f,'Style','edit','Units','pixels','String','nan',...
    'Enable','on','Position',[1*margin+2*fieldWidth fHeight-15*oneRowHeight-2*margin fieldWidth oneRowHeight]);
offsetZField = uicontrol(f,'Style','edit','Units','pixels','String','nan',...
    'Enable','on','Position',[1*margin+3*fieldWidth fHeight-15*oneRowHeight-2*margin fieldWidth oneRowHeight]);
currentComment = uicontrol(f,'Style','edit','Units','pixels','String','',...
    'Enable','on','Position',[1*margin+4*fieldWidth fHeight-15*oneRowHeight-2*margin fieldWidth*4 oneRowHeight]);

offsetEventSubmit = uicontrol(f,'Style','pushbutton','String','enter','Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center','CallBack',@logEvent, ...
    'Position',[2*margin+8*fieldWidth fHeight-15*oneRowHeight-2*margin fieldWidth oneRowHeight]);
    function logEvent(source,eventdata)
        if isfield(events_data,'position')
            lastEventWithCoords=find(cellfun(@isempty,{events_data.position})==0,1,'last');
        else
            lastEventWithCoords=[];
        end
        
        % make a new entry in events
        events_data(end+1).time=now;
        labels(end+1)=nan;
        events_data(end).eventNumber=eventNum;
        events_data(end).rigState=[str2double(get(rigDistField,'String')) str2double(get(rigHeightField,'String')) str2double(get(rigAngleField,'String'))];
        events_data(end).ampState = {ampGainStrs{get(ampGainField,'Value')},ampLPStrs{get(ampLPField,'Value')},ampHPStrs{get(ampHPField,'Value')},...
            ampNotchStrs{get(ampNotchField,'Value')},ampModeStrs{get(ampModeField,'Value')},str2double(get(ampCapCompField,'String'))};
        events_data(end).lensState=[str2double(get(lens1DistField,'String')) str2double(get(lens1PowerField,'String')) str2double(get(lens2DistField,'String')) str2double(get(lens2PowerField,'String'))];
        events_data(end).surgeryAnchor=[str2double(get(surgeryAnchorAPField,'String')) str2double(get(surgeryAnchorMLField,'String')) str2double(get(surgeryAnchorZField,'String'))];
        events_data(end).surgeryBregma=[str2double(get(surgeryBregmaAPField,'String')) str2double(get(surgeryBregmaMLField,'String')) str2double(get(surgeryBregmaZField,'String'))];
        events_data(end).currentAnchor=[str2double(get(currentAnchorAPField,'String')) str2double(get(currentAnchorMLField,'String')) str2double(get(currentAnchorZField,'String'))];
        events_data(end).position=[str2double(get(offsetAPField,'String')) str2double(get(offsetMLField,'String')) str2double(get(offsetZField,'String'))];
        events_data(end).eventType=eventTypeStrs{get(eventTypeMenu,'Value')};
        eventParams=[];
        switch events_data(end).eventType
            case 'visual hash'
                eventParams.hashStrength=visualHashStrs{get(visualHashMenu,'Value')};
            case {'ctx cell','hipp cell','visual cell'}
                eventParams.SNR=str2double(snrStrs{get(snrMenu,'Value')});
                if strcmp(events_data(end).eventType,'visual cell')
                    eventParams.vcType=vcTypeStrs{get(vcTypeMenu,'Value')};
                    eventParams.vcEye=vcEyeStrs{get(vcEyeMenu,'Value')};
                    eventParams.vcBursty=vcBurstyStrs{get(vcBurstyMenu,'Value')};
                    eventParams.vcRFAzimuth=str2double(vcRFAzimuthStrs{get(vcRFAzimuthMenu,'Value')});
                    eventParams.vcRFElevation=str2double(vcRFElevationStrs{get(vcRFElevationMenu,'Value')});
                end
            case 'rat obs'
                eventParams.arousal=arousalStrs{get(arousalMenu,'Value')};
                eventParams.eyes=eyesStrs{get(eyesMenu,'Value')};
                eventParams.face=faceStrs{get(faceMenu,'Value')};
            case 'anesth check'
                eventParams.isoflurane=isofluraneStrs{get(isofluraneMenu,'Value')};
                eventParams.withdrawal=withdrawalStrs{get(withdrawalMenu,'Value')};
                eventParams.breathPerMin=breathPerMinStrs{get(breathPerMinMenu,'Value')};
                eventParams.breathType=breathTypeStrs{get(breathTypeMenu,'Value')};
            otherwise
                % nothing
        end
        events_data(end).eventParams=eventParams;
        events_data(end).comment=get(currentComment,'String');
        
        % update pNum if necessary (if AP or ML differ from last)
        if ~isempty(lastEventWithCoords)
            if (length(events_data)>=2 && any(events_data(lastEventWithCoords).position(1:2)~=events_data(end).position(1:2)) && all(~isnan(events_data(end).position(1:2))) ) ...
                    || length(events_data)==1
                % record events_data.penetrationParams here (ratID, experimenters,
                %   electrode make, model, lot#, ID#, impedance, reference mark xyz, target xy)
                
                params=[];
                params.ratID=ratIDStrs{get(ratIDField,'Value')};
                params.experimenter=experimenterStrs{get(experimenterField,'Value')};
                params.electrodeMake=electrodeMakeStrs{get(electrodeMakeField,'Value')};
                params.electrodeModel=electrodeModelStrs{get(electrodeModelField,'Value')};
                params.lotNum=lotNumStrs{get(lotNumField,'Value')};
                params.IDNum=IDNumStrs{get(IDNumField,'Value')};
                params.impedance=impedanceStrs{get(impedanceField,'Value')};
                events_data(end).penetrationParams=params;
                
                if length(events_data)==1
                    events_data(end).penetrationNum=1;
                else
                    events_data(end).penetrationNum=events_data(lastEventWithCoords).penetrationNum+1;
                end
            else
                events_data(end).penetrationNum=events_data(lastEventWithCoords).penetrationNum;
                events_data(end).penetrationParams=[];
            end
        else
            events_data(end).penetrationNum=1;
            events_data(end).penetrationParams=[];
        end
        
        % save event log
        deleteFilename=sprintf('physiologyEvents_%d-%d.mat',1,eventNum-1);
        saveFilename=sprintf('physiologyEvents_%d-%d.mat',1,eventNum);
        if ~isdir(savePath)
            mkdir(savePath);
        end
        save(fullfile(savePath,saveFilename),'events_data','labels');
        if eventNum~=1
            delete(fullfile(savePath,deleteFilename));
        end
        
        eventNum=eventNum+1;
        updateDisplay();
        % flush the comments buffer
        set(currentComment,'String','');
        % reset eventType to comment
        set(eventTypeMenu,'Value',defaultIndex);
        eventTypeC([],[]);
        
        % reset all colors to normal
        set(rigDistField,'BackgroundColor','w');
        set(rigHeightField,'BackgroundColor','w');
        set(rigAngleField,'BackgroundColor','w');
        set(enableRigStateFields,'Value',0);enableRigStateEntry();
        
        set(ratProtocolField,'BackgroundColor','w');
        set(experimenterField,'BackgroundColor','w');
        set(electrodeMakeField,'BackgroundColor','w');
        set(electrodeModelField,'BackgroundColor','w');
        set(lotNumField,'BackgroundColor','w');
        set(IDNumField,'BackgroundColor','w');
        set(impedanceField,'BackgroundColor','w');
               
        set(currentAnchorAPField,'BackgroundColor','w');
        set(currentAnchorMLField,'BackgroundColor','w');
        set(currentAnchorZField,'BackgroundColor','w');
        set(enableCurrentAnchorField,'Value',0);enableCurrentAnchorEntry();
        
        set(ampGainField,'BackgroundColor','w');
        set(ampLPField,'BackgroundColor','w');
        set(ampHPField,'BackgroundColor','w');
        set(ampNotchField,'BackgroundColor','w');
        set(ampModeField,'BackgroundColor','w');
        set(ampCapCompField,'BackgroundColor','w');
        set(enableAmpStateFields,'Value',0);enableAmpStateEntry();
        

        set(lens1DistField,'BackgroundColor','w');
        set(lens1PowerField,'BackgroundColor','w');
        set(lens2DistField,'BackgroundColor','w');
        set(lens2PowerField,'BackgroundColor','w');
        set(enableLens1StateFields,'Value',0);enableLens1StateEntry();
        set(enableLens2StateFields,'Value',0);enableLens2StateEntry();
        
    end % end logEvent function

% ========================================================================================
% quick plot - improved
levelToTOF = uicontrol(f,'Style','checkbox','String','level to TOF','Enable','on','Visible','on',...
    'Value',0,'Units','pixels','Position',[2*margin+8*fieldWidth fHeight-24.5*oneRowHeight-margin fieldWidth+margin*3 oneRowHeight]);

quickPlotButton = uicontrol(f,'Style','pushbutton','String','quick plot','Visible','on','Units','pixels',...
    'FontWeight','normal','HorizontalAlignment','center','CallBack',@quickPlot, ...
    'Position',[2*margin+8*fieldWidth fHeight-23*oneRowHeight-2*margin fieldWidth oneRowHeight]);
    function quickPlot(source,eventdata)
        
        %p=vertcat(events_data.position);
        %plot3(p(:,1),p(:,2),p(:,3),'k.')
        
        % there are some empty eventType records. i am working around them
        if ~isempty(cellfun(@isempty,{events_data.eventType}))
            warning('empty evetTypes in event_data. will remove same for quickPlot');
        end
        events_dataNoEmpty = events_data(find(~cellfun(@isempty,{events_data.eventType})));
        
%         REMOVE COMMENTS AFTER DE-BUGGING EMPTY EVENT_DATA TYPES
%         ALL=true(1,length(events_data));
%         TOB=ismember({events_data.eventType},{'top of brain'});
%         VIS=ismember({events_data.eventType},{'visual cell','visual hash'});
%         CELL=ismember({events_data.eventType},{'ctx cell','hipp cell','visual cell'});
%         BEND=ismember({events_data.eventType},{'electrode bend'});
%         %get the last defined position in the list 
%         CURRENT= false(1,length(events_data))  % this is the start of the logicals
%         candidates=find( ~cellfun('isempty',{events_data.position})  )
%         % next:  find the cands that are not nan ... problem:  all apear to
%         % be nan?  not true
%         CURRENT(max())=true;
%         % cellfun(@(x) any(isnan(x)),{events_data.position}) &  % that is
%         % not a nan .. prob is need to add back in
%         
%         g=figure;
%         levelToTopOfBrain=false;
%         plotInBregmaCoordinates(events_data,ALL,'.k',[1 1 1 1],levelToTopOfBrain);
%         hold on;
%         plotInBregmaCoordinates(events_data,TOB,'ok',[],levelToTopOfBrain);
%         plotInBregmaCoordinates(events_data,VIS,'c.',[],levelToTopOfBrain);
%         plotInBregmaCoordinates(events_data,CELL,'b*',[],levelToTopOfBrain);
%         plotInBregmaCoordinates(events_data,CELL & VIS,'r*',[],levelToTopOfBrain);
%         plotInBregmaCoordinates(events_data,BEND,'xr',[],levelToTopOfBrain);
%         plotInBregmaCoordinates(events_data,CURRENT,'og',[],levelToTopOfBrain);
%         
%         xlabel('posterior');
%         ylabel('lateral');
%         zlabel('depth');
%         grid on;
%         set(gca,'View',[240 60])
%         set(gca,'YDir','reverse');  %why?  thats just the way it is in plot3

        ALL=true(1,length(events_dataNoEmpty));
        TOB=ismember({events_dataNoEmpty.eventType},{'top of brain'});
        VIS=ismember({events_dataNoEmpty.eventType},{'visual cell','visual hash'});
        CELL=ismember({events_dataNoEmpty.eventType},{'ctx cell','hipp cell','visual cell'});
        BEND=ismember({events_dataNoEmpty.eventType},{'electrode bend'});
        %get the last defined position in the list
        CURRENT= false(1,length(events_dataNoEmpty));  % this is the start of the logicals
        candidates=find( ~cellfun('isempty',{events_dataNoEmpty.position})  );
        % next:  find the cands that are not nan ... problem:  all apear to
        % be nan?  not true
        %CURRENT(max())=true;
        % cellfun(@(x) any(isnan(x)),{events_data.position}) &  % that is
        % not a nan .. prob is need to add back in
        g=figure('Position',[50 700 800 400]);
        for subPlotID=1:2
            subplot(1,2,subPlotID)
            levelToTopOfBrain=get(levelToTOF,'Value');
            plotInBregmaCoordinates(events_dataNoEmpty,ALL,'.k',[1 0 1 1],levelToTopOfBrain);
            hold on;
            plotInBregmaCoordinates(events_dataNoEmpty,TOB,'ok',[],levelToTopOfBrain);
            plotInBregmaCoordinates(events_dataNoEmpty,VIS,'c.',[],levelToTopOfBrain);
            plotInBregmaCoordinates(events_dataNoEmpty,CELL,'b*',[],levelToTopOfBrain);
            plotInBregmaCoordinates(events_dataNoEmpty,CELL & VIS,'r*',[],levelToTopOfBrain);
            plotInBregmaCoordinates(events_dataNoEmpty,BEND,'xr',[],levelToTopOfBrain);
            %plotInBregmaCoordinates(events_dataNoEmpty,CURRENT,'og',[],levelToTopOfBrain);
            
            xlabel('posterior');
            ylabel('lateral');
            zlabel('depth');
            grid on;
            switch subPlotID 
                case 1
                    set(gca,'View',[-180 0])
                case 2
                   set(gca,'View',[-180 90])
                case 3
                    set(gca,'View',[240 60])
            end
            set(gca,'YDir','reverse');  %why?  thats just the way it is in plot3
            set(gca,'ZLim',[-10 0]);
        end
    end


% ========================================================================================
% start/stop cell
toggleCellButton = uicontrol(f,'Style','togglebutton','String',cellT,'Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center','CallBack',@toggleCell, ...
    'Position',[2*margin+8*fieldWidth fHeight-19*oneRowHeight-2*margin fieldWidth oneRowHeight]);
    function toggleCell(source,eventdata)
        if get(toggleCellButton,'Value')==1            
            externalRequest='cell start';
        else
            externalRequest='cell stop';
        end
        % get time from client machine (if it exists)
        if ~running
            events_data(end+1).time=now;
            labels(end+1)=nan;
            events_data(end).eventType=externalRequest;
            events_data(end).eventNumber=eventNum;
            % save events
            % save event log
            deleteFilename=sprintf('physiologyEvents_%d-%d.mat',1,eventNum-1);
            saveFilename=sprintf('physiologyEvents_%d-%d.mat',1,eventNum);
            if ~isdir(savePath)
                mkdir(savePath);
            end
            save(fullfile(savePath,saveFilename),'events_data','labels');
            if eventNum~=1
                delete(fullfile(savePath,deleteFilename));
            end
            eventNum=eventNum+1;
            externalRequest=[];
        else
            % we just need to pass externalRequest to the run loop
        end
        fprintf('finished getting time from client\n')
        if get(toggleCellButton,'Value') % start the cell
            cellActive=true;
            cellT='stop cell';
        else
            cellActive=false;
            cellT='start cell';
        end
        updateDisplay();
        updateUI();
    end
% ========================================================================================
% start/stop recording
toggleRecordingButton = uicontrol(f,'Style','togglebutton','String',recordingT,'Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center','CallBack',@toggleRecording, ...
    'Position',[2*margin+8*fieldWidth fHeight-20*oneRowHeight-2*margin fieldWidth oneRowHeight]);
    function toggleRecording(source,eventdata)
        if get(toggleRecordingButton,'Value') % start recording
            recording=true;
            keepLooping=false;
            if ~running
                q=questdlg('Also start trials?','start recording','Yes','No','Cancel','Yes');
                switch q
                    case {'Yes','No'}
                        if strcmp(q,'Yes')
                            running=true;
                            set(toggleTrialsButton,'Value',1);
                        end
                    case 'Cancel'
                        recording=false;
                        keepLooping=true;
                        set(toggleRecordingButton,'Value',0);
                        return;
                    otherwise
                        error('bad response from question dialog');
                end
            end
            updateUI();
            % if not currently looping, then start the loop
            if ~runningLoop
                if get(deleteDbInClient,'Value')
                    disp('deleting db.mat in the client. i am hardcoding it here. there might be a better way to handle it!')
                    dBFileName = '\\132.239.158.180\pmeier\ratrixTrunk\ratrixData\ServerData\db.mat';
                    succ = stochasticDelete(dBFileName);
                    if ~succ
                        warning('did not delete the db.mat');
                    end
                end
                run();
            end
        else
            if running
                q=questdlg('Also stop running trials?','stop recording','Yes','No','Cancel','Yes');
                switch q
                    case {'Yes','No'}
                        if strcmp(q,'Yes')
                            running=false;
                            set(toggleTrialsButton,'Value',0);
                        end
                        recording=false;
                        keepLooping=false;
                    case 'Cancel';
                        % do nothing;
                        set(toggleRecordingButton,'Value',1);
                    otherwise
                        error('bad response from question dialog');
                end
            else
                recording=false;
                keepLooping=false;
            end
        end
        updateUI();
    end % end function

% ========================================================================================
% start/stop trials
toggleTrialsButton = uicontrol(f,'Style','togglebutton','String',runningT,'Visible','on','Units','pixels',...
    'FontWeight','bold','HorizontalAlignment','center','CallBack',@toggleTrials, ...
    'Position',[2*margin+8*fieldWidth fHeight-21*oneRowHeight-2*margin fieldWidth oneRowHeight]);
    function toggleTrials(source,eventdata)
        if get(toggleTrialsButton,'Value') % start running
            running=true;
            keepLooping=false;
            if ~recording
                q=questdlg('Also start recording?','start trials','Yes','No','Cancel','Yes');
                switch q
                    case {'Yes','No'}
                        if strcmp(q,'Yes')
                            recording=true;
                            set(toggleRecordingButton,'Value',1);
                        end
                    case 'Cancel'
                        running=false;
                        keepLooping=true;
                        set(toggleTrialsButton,'Value',0);
                        return
                    otherwise
                        error('bad response from question dialog');
                end
            end
            updateUI();
            if ~runningLoop % if not currently looping, then start the loop
                if get(deleteDbInClient,'Value')
                    disp('deleting db.mat in the client. i am hardcoding it here. there might be a better way to handle it!')
                    dBFileName = '\\132.239.158.180\pmeier\ratrixTrunk\ratrixData\ServerData\db.mat';
                    succ = stochasticDelete(dBFileName);
                    if ~succ
                        warning('did not delete the db.mat');
                    end
                end
                run();
            end
        else
            if recording
                q=questdlg('Also stop recording?','stop trials','Yes','No','Cancel','Yes');
                switch q
                    case {'Yes','No'}
                        if strcmp(q,'Yes')
                            recording=false;
                            set(toggleRecordingButton,'Value',0);
                        end
                        running=false;
                        keepLooping=false;
                    case 'Cancel';
                        % do nothing;
                        set(toggleTrialsButton,'Value',1);
                    otherwise
                        error('bad response from question dialog');
                end
            else
                running=false;
                keepLooping=false;
            end
        end
        updateUI();
    end % end function

    function run
        runningLoop=true;
        keepLooping=true;
        
        storepath=fullfile('\\132.239.158.179\datanetOutput',ratIDStrs{get(ratIDField,'Value')});
        %storepath=fullfile('\\132.239.158.179\datanet_storage',ratIDStrs{get(ratIDField,'Value')});
        % check that neuralRecords,eyeRecord,stimRecords folders exist
        if ~isdir(fullfile(storepath,'neuralRecords'))
            mkdir(fullfile(storepath,'neuralRecords'));
        end
        if ~isdir(fullfile(storepath,'eyeRecords'))
            mkdir(fullfile(storepath,'eyeRecords'));
        end
        if ~isdir(fullfile(storepath,'stimRecords'))
            mkdir(fullfile(storepath,'stimRecords'));
        end
        client_hostname=clientIPStrs{get(clientIPField,'Value')};
        neuralFilename=[];
        stimFilename=[];
        chunkCount=1;
        chunkClock=[];
        startTime=0;
        % ==============================================
        % SET UP TRIALS
        if running
            pnet('closeall')
            data = datanet('data', getIPAddress(),client_hostname,storepath,ai_parameters); % how do we get client_hostname,storepath, and ai_parameters?
            [dataCmdCon dataAckCon]= connectToClient(data,client_hostname);
            if isempty(dataCmdCon) || isempty(dataAckCon)
                % this should error, because we pressed 'start trials' and then failed to connect to a client
                error('failed to connect to client');
            else
                data=setCmdCon(data,dataCmdCon);
                data=setAckCon(data,dataAckCon);
                gotAck=startClientTrials(data,ratIDStrs{get(ratIDField,'Value')},ratProtocolStrs{get(ratProtocolField,'Value')});
                fprintf('started client trials\n');
                if ~gotAck
                    error('wtf how did we call startClientTrials and then not get an ack back?');
                else
                    gotAck
                end
            end
        end
        % ==============================================
        % SET UP NIDAQ
        if recording
            % how to set up neuralFilename
            dirStr=fullfile(storepath,'neuralRecords');
            goodTrials=[];
            d=dir(dirStr);
            for j=1:length(d)
                [matches tokens] = regexpi(d(j).name, 'neuralRecords_(\d+)-(.*)\.mat', 'match', 'tokens');
                if length(matches) ~= 1
                    %         warning('not a neuralRecord file name');
                else
                    goodTrials(end+1)=str2double(tokens{1}{1});
                end
            end
            lastTrial=max(goodTrials);
            if isempty(lastTrial)
                lastTrial=1;
            end
            neuralFilename=fullfile(storepath,'neuralRecords',sprintf('neuralRecords_pretrial%d-%s.mat',lastTrial,datestr(now,30)));
            if ~running
                samplingRate=ai_parameters.sampRate;
                save(neuralFilename,'samplingRate'); %create the pretrial neuralRecords file!
            end
            chunkClock=GetSecs();
            startTime=chunkClock;
            [ai recordingFile]=startNidaq(ai_parameters);
        end
        
        quit=false;
        
        while ~quit && keepLooping
            allowTimeupChunkAdvancementCheck=true;
            params=[];
            params.ai=ai;
            params.neuralFilename=neuralFilename;
            params.stimFilename=stimFilename;
            params.samplingRate=ai_parameters.sampRate;
            params.ai_parameters=ai_parameters;
            params.chunkCount=chunkCount;
            params.startTime=startTime;
            fprintf('.%d',params.chunkCount)
            % ==============================================
            % handle all TRIALS stuff
            if running && ~isempty(dataCmdCon) && ~isempty(dataAckCon)
                [quit retval status requestDone]=doServerIteration(data,params,externalRequest);
                if requestDone % we have to do this instead of just updating the value of externalRequest, becuase of some weird matlab scope issue
                    externalRequest=[];
                end
                if ~isempty(retval) % we have events_data to save
                    % retval should be a struct with fields 'time' and 'type' (and possibly others to add...)
                    for j=1:length(retval)
                        if isfield(retval(j),'errorMethod') && ~isempty(retval(j).errorMethod)
                            % this is not a phys event, but rather a
                            % 'restart' or 'quit' from client
                            
                            % 6/9/09 - should we delete the neuralRecord at
                            % neuralFilename b/c it was error trial?
                            % also corresponding stimRecord/eyeRecord?
                            delete(neuralFilename);
                            delete(stimFilename);
                            quit=true;
                            disp('quitting due to client disconnect');
                            method=retval(j).errorMethod;
                            if ischar(method)
                                if strcmp(method,'Restart')
                                    % do nothing
                                elseif strcmp(method, 'Quit')
                                    running=false;
                                    recording=false;
                                    set(toggleTrialsButton,'Value',0);
                                    set(toggleRecordingButton,'Value',0);
                                else
                                    error('if not restart or quit, then what is the client method?');
                                end
                            else
                                error('ERROR_RECOVERY_METHOD must be a string');
                            end
                            updateUI();
                            updateDisplay();
                        else
                            events_data(end+1).time=retval(j).time;
                            labels(end+1)=nan;
                            events_data(end).eventType=retval(j).type;
                            events_data(end).eventNumber=eventNum;
                            
                            switch retval(j).type
                                case 'trial start'
                                    neuralFilename=retval(j).neuralFilename;
                                    stimFilename=retval(j).stimFilename;
                                    % reset chunkCount and chunkClock?
                                    chunkCount=1;
                                    
                                    chunkClock=GetSecs();
                                    startTime=chunkClock;
                                    events_data(end).eventParams.trialNumber=retval(j).trialNumber;
                                    events_data(end).eventParams.stimManagerClass=retval(j).stimManagerClass;
                                    events_data(end).eventParams.stepName=retval(j).stepName;
                                    events_data(end).eventParams.stepNumber=retval(j).stepNumber;
                                case 'trial end' 
                                    allowTimeupChunkAdvancementCheck=false;
                                    %this will prevent a short empty chunk the length of the save duration from
                                    %overwriting the last chunk. this bug 1st noticed and fixed when we saved longer
                                    %trials with 16 channels. -pmm 5/31/2010
                            end
                            
                            % should save events to phys log here?
                            % save event log
                            deleteFilename=sprintf('physiologyEvents_%d-%d.mat',1,eventNum-1);
                            saveFilename=sprintf('physiologyEvents_%d-%d.mat',1,eventNum);
                            if ~isdir(savePath)
                                mkdir(savePath);
                            end
                            save(fullfile(savePath,saveFilename),'events_data','labels');
                            if eventNum~=1
                                delete(fullfile(savePath,deleteFilename));
                            end
                            eventNum=eventNum+1;
                        end
                    end
                end
            else
                WaitSecs(0.3);
                drawnow;
            end
            % ==============================================
            % handle all NIDAQ stuff
            if recording
                % now check if it is time to spool off a 30sec chunk
                t=GetSecs();
                if t-chunkClock>=20 && allowTimeupChunkAdvancementCheck %hardcoded to 30 seconds before, but 20 has a better save ratio for 16 channels
                    disp(sprintf('going to save a chunk because %f secs elapsed',t-chunkClock))
                    numSampsToGet=get(ai,'SamplesAvailable');
                    [neuralData,neuralDataTimes]=getdata(ai,numSampsToGet);
                    elapsedTime=GetSecs()-startTime;
                    saveNidaqChunk(neuralFilename,neuralData,neuralDataTimes([1 end]),chunkCount,elapsedTime,ai_parameters.sampRate,ai_parameters);
                    clear neuralData neuralDataTimes;
                    % now increment chunkCount and chunkClock
                    chunkCount=chunkCount+1;
                    chunkClock=t;
                end
            end
            updateDisplay();
            WaitSecs(0.3);
        end
        % ==============================================
        % after a quit, handle all TRIALS stuff
        if ~isempty(data) && ~quit && status && ~keepLooping %not a client disconnect (so a normal stop by setting keepLooping to false)
            [gotAck retval]=stopClientTrials(data,ratIDStrs{get(ratIDField,'Value')},params);
            if ~isempty(retval) % save last trial's TRIAL_END event (the call to stopClientTrials saved its neuralRecord)
                for j=1:length(retval)
                    events_data(end+1).time=retval(j).time;
                    labels(end+1)=nan;
                    events_data(end).eventType=retval(j).type;
                    events_data(end).eventNumber=eventNum;
                    % save event log
                    deleteFilename=sprintf('physiologyEvents_%d-%d.mat',1,eventNum-1);
                    saveFilename=sprintf('physiologyEvents_%d-%d.mat',1,eventNum);
                    if ~isdir(savePath)
                        mkdir(savePath);
                    end
                    save(fullfile(savePath,saveFilename),'events_data','labels');
                    if eventNum~=1
                        delete(fullfile(savePath,deleteFilename));
                    end
                    eventNum=eventNum+1;
                end
            end
        end
        if ~isempty(ai) % stop nidaq recording after saving last chunk
            % need to spool off remaining neural data in standalone mode
            if isempty(data) % if we are running trials, then stopClientTrials handles saving of last chunk, DONT REPEAT
                try
                    numSampsToGet=get(ai,'SamplesAvailable');
                    [neuralData,neuralDataTimes]=getdata(ai,numSampsToGet);
                    elapsedTime=GetSecs()-startTime;
                    saveNidaqChunk(neuralFilename,neuralData,neuralDataTimes([1 end]),chunkCount,elapsedTime,ai_parameters.sampRate,ai_parameters);
                    clear neuralData neuralDataTimes;
                    flushdata(ai);
                catch ex
                    getReport(ex)
                    disp('failed to get neural records');
                    keyboard
                end
            end
            ai=stopNidaq(ai);
        end
        
        % reset some flags for next instance of run
        pnet('closeall');
        data=[];
        ai=[];
        runningLoop=false;
        if running || recording % if we only turned off one of recording/running, then restart the run loop
            updateDisplay();
            run();
        end
    end


% ========================================================================================
% display box
recentEventsDisplay = uicontrol(f,'Style','edit','String','recent events','Visible','on','Units','pixels',...
    'FontWeight','normal','HorizontalAlignment','left','Max',999,'Min',0,'Value',[],'Enable','on', ...
    'Position',[margin+1*fieldWidth fHeight-24*oneRowHeight-1*margin fieldWidth*7-margin oneRowHeight*8]);

displayModeLabel = uicontrol(f,'Style','text','String','Display Mode','Visible','on','Units','pixels',...
    'HorizontalAlignment','center','Position',...
    [margin fHeight-25*oneRowHeight-2*margin fieldWidth*1-margin oneRowHeight]);
displayModeSelector = uicontrol(f,'Style','popup',...
    'String',displayModeStrs,'Enable','on','Visible','on',...
    'Value',displayModeIndex,'Units','pixels','Position',...
    [margin+fieldWidth fHeight-25*oneRowHeight-2*margin fieldWidth*1-margin oneRowHeight],...
    'Callback',@updateDisplay);

% ========================================================================================
% labels
openLabelingWindowButton = uicontrol(f,'Style','pushbutton','String','add labels','Visible','on','Units','pixels',...
    'Position',[margin+0*fieldWidth fHeight-24*oneRowHeight-1*margin fieldWidth*1-margin oneRowHeight],...
    'Value',0,'Callback',@openLabelingWindow);
    function openLabelingWindow(source,eventdata)
        labels=grouper(events_data,labels);
        % need to save labels to file now? - could use safesave here!
        saveFilename=sprintf('physiologyEvents_%d-%d.mat',1,eventNum-1);
        save(fullfile(savePath,saveFilename),'events_data','labels');
    end

% ========================================================================================
% turn on the GUI
reloadEventsAndSurgeryFields([],[]);
set(f,'Visible','on');
end

% ========================================================================================
% HELPER FUNCTIONS
function [quit retval status requestDone]=doServerIteration(data,params,externalRequest)
% should also work in standalone phys logging mode (just do nothing...)
requestDone=false;
% check pnet('status') here if ratrix throws error, go back to
% connectToClient
status=pnet(getCmdCon(data),'status')>0 && pnet(getAckCon(data),'status')>0;

quit=false;
retval=[];
if ~isempty(getCmdCon(data)) && ~isempty(getAckCon(data))
    [data quit retval] = handleCommands(data,params);
end
if ~isempty(externalRequest)
    retval(end+1).time=getTimeFromClient(data);
    retval(end).type=externalRequest;
    requestDone=true;
end
% fprintf('did a server iteration\n')
WaitSecs(0.3);
end


%=========================================================================
function [ai recordingFile] = startNidaq(ai_parameters)
% start NIDAQ recording - in both standalone and ratrix cases
% ai_parameters = getAIParameters(data);
if isfield(ai_parameters, 'numChans')
    numChans = ai_parameters.numChans;
else
    numChans = 3;
end
if isfield(ai_parameters, 'sampRate')
    sampRate = ai_parameters.sampRate;
else
    sampRate = 40000;
end
if isfield(ai_parameters, 'inputRanges')
    inputRanges = ai_parameters.inputRanges;
else
    inputRanges = repmat([-1 6],numChans,1);
end
if isfield(ai_parameters, 'recordingFile')
    recordingFile = ai_parameters.recordingFile;
else
    recordingFile = [];
end
% start NIDAQ
sprintf('starting NIDAQ with %d channels %d sampRate',numChans,sampRate)
inputRanges

[ai chans recordingFile]=openNidaqForAnalogRecording(numChans,sampRate,inputRanges,recordingFile);
ai
recordingFile
set(ai)
get(ai)
get(ai,'Channel')
daqhwinfo(ai)
chans
set(chans(1))
get(chans(1))
start(ai);

end

%=========================================================================
function ai = stopNidaq(ai)
stop(ai);
delete(ai);
% clear ai;
ai=[];
end

%=========================================================================
function success=stochasticDelete(filename)
if ~exist('filename','var')||~ischar(filename)
    error('stochasticDelete requires a filename which has to be a character datapath')
end

success=false;
timedout = false;
numTries = 10;

currTry = 1;
while ~success && ~timedout
    try
        if exist(filename,'file')
            delete(filename);
            success = true;
        else
            success = true;
        end
    catch
        WaitSecs(abs(randn));
        dispStr=sprintf('failed to delete %s - trying again',filename);
        disp(dispStr)
        currTry = currTry +1;
    end
    if currTry > numTries
        timedout = true;
    end
end

success = success & ~timedout;
end % end function
