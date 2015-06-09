%batch2pBehavior    JW 6/5/15

clear all
close all
dbstop if error
pathname = 'F:/2p data/compiled 2p/'; %for Maxwell
outpathname = '';

% n=1;
% files(n).subj = 'g62m9tt'; 
% files(n).expt = '042215';
% files(n).topox_session_data =  '';
% files(n).topoy_session_data = '';
% files(n).behav_session_data = 'GTS behavior session data.mat';
% files(n).2pOrientations_w_blank_session_data = '';
% files(n).behavstim2sf_session_data = '';
% files(n).behavstim3x4orient_session_data = '';
% files(n).topox_pts =  '';
% files(n).topoy_pts = '';
% files(n).behav_pts = '';
% files(n).2pOrientations_w_blank_pts = '';
% files(n).behavstim2sf_pts = '';
% files(n).behavstim3x4orient_pts = '';
% files(n).master_pts = '';
% files(n).monitor = 'vert';
% files(n).task = 'GTS';
% files(n).learningDay = '';
% files(n).spatialfreq = '200';
% files(n).label = 'camk2 gc6';
% files(n).notes = 'good imaging session';

% n=n+1;
% files(n).subj = 'g62l10rt'; 
% files(n).expt = '060215';
% files(n).topox_session_data =  'topoX session data.mat';
% files(n).topoy_session_data = 'TopoY session data.mat';
% files(n).behav_session_data = 'GTS behavior session data.mat';
% files(n).2pOrientations_w_blank_session_data = '2pOrientations session data.mat';
% files(n).behavstim2sf_session_data = 'behaveStim2sf session data.mat';
% files(n).behavstim3x4orient_session_data = 'BehaveStim3x4orient session data.mat';
% files(n).topox_pts =  'topoX pts.mat';
% files(n).topoy_pts = 'TopoY pts.mat';
% files(n).behav_pts = 'GTS behavior pts.mat';
% files(n).2pOrientations_w_blank_pts = '';
% files(n).behavstim2sf_pts = 'behaveStim2sf pts.mat';
% files(n).behavstim3x4orient_pts = 'BehaveStim3x4orient pts.mat';
% files(n).master_pts = 'master pts.mat';
% files(n).monitor = 'vert';
% files(n).task = 'GTS';
% files(n).learningDay = '';
% files(n).spatialfreq = '200';
% files(n).label = 'camk2 gc6';
% files(n).notes = 'good imaging session';

% n=n+1;
% files(n).subj = 'g62n1ln'; 
% files(n).expt = '060215';
% files(n).topox_session_data =  'TopoX session data.mat';
% files(n).topoy_session_data = 'TopoY session data.mat';
% files(n).behav_session_data = 'GTS behavior session data.mat';
% files(n).2pOrientations_w_blank_session_data = '2pOrientations session data.mat';
% files(n).behavstim2sf_session_data = 'BehaveStim2sf session data.mat';
% files(n).behavstim3x4orient_session_data = 'BehaveStim3x4orient session data.mat';
% files(n).topox_pts =  'TopoX pts.mat';
% files(n).topoy_pts = 'TopoY pts.mat';
% files(n).behav_pts = 'GTS behavior pts.mat';
% files(n).2pOrientations_w_blank_pts = '';
% files(n).behavstim2sf_pts = 'BehaveStim2sf pts.mat';
% files(n).behavstim3x4orient_pts = 'BehaveStim3x4orient pts.mat';
% files(n).master_pts = 'master pts.mat';
% files(n).monitor = 'vert';
% files(n).task = 'GTS';
% files(n).learningDay = '';
% files(n).spatialfreq = '200';
% files(n).label = 'camk2 gc6';
% files(n).notes = 'good imaging session';

% n=n+1;
% files(n).subj = 'g62a4tt'; 
% files(n).expt = '060415';
% files(n).topox_session_data =  'topoX session data.mat';
% files(n).topoy_session_data = 'topoY session data.mat';
% files(n).behav_session_data = 'HvV behavior session data.mat';
% files(n).2pOrientations_w_blank_session_data = '2porientations_w_blank session data.mat';
% files(n).behavstim2sf_session_data = 'behaveStim2sf session data.mat';
% files(n).behavstim3x4orient_session_data = 'behaveStim3x4orient session data.mat';
% files(n).topox_pts =  'topoX pts.mat';
% files(n).topoy_pts = 'topoY pts.mat';
% files(n).behav_pts = 'HvV behavior pts.mat';
% files(n).2pOrientations_w_blank_pts = '';
% files(n).behavstim2sf_pts = 'behaveStim2sf pts.mat';
% files(n).behavstim3x4orient_pts = 'behaveStim3x4orient pts.mat';
% files(n).master_pts = 'master_pts.mat';
% files(n).monitor = 'vert';
% files(n).task = 'HvV';
% files(n).learningDay = '';
% files(n).spatialfreq = '200';
% files(n).label = 'camk2 gc6';
% files(n).notes = 'good imaging session';

% n=n+1;
% files(n).subj = 'g62a5nn'; 
% files(n).expt = '060515';
% files(n).topox_session_data =  'TopoX session data.mat';
% files(n).topoy_session_data = 'TopoY session data.mat';
% files(n).behav_session_data = 'HvV behavior session data.mat';
% files(n).2pOrientations_w_blank_session_data = '2porientations_w_blank session data.mat';
% files(n).behavstim2sf_session_data = 'behaveStim2sf session data.mat';
% files(n).behavstim3x4orient_session_data = 'behaveStim3x4orient session data.mat';
% files(n).topox_pts =  'topox pts.mat';
% files(n).topoy_pts = 'topoY pts.mat';
% files(n).behav_pts = 'HvV behavior pts.mat';
% files(n).2pOrientations_w_blank_pts = '2porientations_w_blank pts.mat';
% files(n).behavstim2sf_pts = 'behaveStim2sf pts.mat';
% files(n).behavstim3x4orient_pts = 'behaveStim3x4orient pts.mat';
% files(n).master_pts = 'master pts _std_35_green_250.mat';
% files(n).monitor = 'vert';
% files(n).task = 'HvV';
% files(n).learningDay = '';
% files(n).spatialfreq = '200';
% files(n).label = 'camk2 gc6';
% files(n).notes = 'good imaging session';





% n=n+1;
% files(n).subj = ''; 
% files(n).expt = '';
% files(n).topox_session_data =  '';
% files(n).topoy_session_data = '';
% files(n).behav_session_data = '';
% files(n).2pOrientations_w_blank_session_data = '';
% files(n).behavstim2sf_session_data = '';
% files(n).behavstim3x4orient_session_data = '';
% files(n).topox_pts =  '';
% files(n).topoy_pts = '';
% files(n).behav_pts = '';
% files(n).2pOrientations_w_blank_pts = '';
% files(n).behavstim2sf_pts = '';
% files(n).behavstim3x4orient_pts = '';
% files(n).master_pts = '';
% files(n).monitor = 'vert';
% files(n).task = '';
% files(n).learningDay = '';
% files(n).spatialfreq = '200';
% files(n).label = 'camk2 gc6';
% files(n).notes = 'good imaging session';