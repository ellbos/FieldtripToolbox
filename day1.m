%% Setup

cfg                         = [];
cfg.dataset                 = 'Subject01/Subject01.ds';
cfg.trialfun                = 'ft_trialfun_general'; % this is the default
cfg.trialdef.eventtype      = 'backpanel trigger';
cfg.trialdef.eventvalue     = [3 5 9]; % the values of the stimulus trigger for the three conditions
% 3 = fully incongruent (FIC), 5 = initially congruent (IC), 9 = fully congruent (FC)
cfg.trialdef.prestim        = 1; % in seconds
cfg.trialdef.poststim       = 2; % in seconds

cfg = ft_definetrial(cfg);

%% Clean the data

% remove the trials that have artifacts from the trl
cfg.trl([2, 5, 6, 8, 9, 10, 12, 39, 43, 46, 49, 52, 58, 84, 102, 107, 114, 115, 116, 119, 121, 123, 126, 127, 128, 132, 133, 137, 143, 144, 147, 149, 158, 181, 229, 230, 233, 241, 243, 245, 250, 254, 260],:) = [];

% preprocess the data
cfg.channel         = {'MEG', '-MLP31', '-MLO12'};        % read all MEG channels except MLP31 and MLO12
cfg.demean          = 'yes';
cfg.baselinewindow  = [-0.2 0];
cfg.lpfilter        = 'yes';                              % apply lowpass filter
cfg.lpfreq          = 35;                                 % lowpass at 35 Hz.

data_all = ft_preprocessing(cfg);

%% Split and save

% Fully InCongruent (FIC)
cfg = [];
cfg.trials = data_all.trialinfo == 3;
dataFIC_LP = ft_redefinetrial(cfg, data_all);

% Initially Congruent (IC)
cfg = [];
cfg.trials = data_all.trialinfo == 9;
dataIC_LP = ft_redefinetrial(cfg, data_all);

% Fully Congruent (FC)
cfg = [];
cfg.trials = data_all.trialinfo == 5;
dataFC_LP = ft_redefinetrial(cfg, data_all);

% save the three subsets of trials
save dataFIC_LP dataFIC_LP
save dataFC_LP dataFC_LP
save dataIC_LP dataIC_LP

% plot 
figure;
plot(dataFIC_LP.time{1}, dataFIC_LP.trial{1}(130,:))

%{
% load the subsets of trials
load dataFIC_LP
load dataFC_LP
load dataIC_LP
% I figure this step is redundant if I just split the data
%}

%% Timelock analysis

% average over trials
cfg = [];
avgFIC = ft_timelockanalysis(cfg, dataFIC_LP);
avgFC = ft_timelockanalysis(cfg, dataFC_LP);
avgIC = ft_timelockanalysis(cfg, dataIC_LP);

% plot the results

% multiplot: all sensors, 1 condition
figure;
cfg = [];
cfg.showlabels = 'yes';
cfg.fontsize = 6;
cfg.layout = 'CTF151_helmet.mat';
cfg.ylim = [-3e-13 3e-13];
ft_multiplotER(cfg, avgFIC);

% multiplot: all sensors, 3 conditions
figure;
cfg = [];
cfg.showlabels = 'no';
cfg.fontsize = 6;
cfg.layout = 'CTF151_helmet.mat';
cfg.baseline = [-0.2 0];
cfg.xlim = [-0.2 1.0];
cfg.ylim = [-3e-13 3e-13];
ft_multiplotER(cfg, avgFC, avgIC, avgFIC);

% singleplot: 1 sensor, 3 conditions
figure;
cfg = [];
cfg.xlim = [-0.2 1.0];
cfg.ylim = [-1e-13 3e-13];
cfg.channel = 'MLC24';
clf;
ft_singleplotER(cfg, avgFC, avgIC, avgFIC);

% topographic: 1 condition, 1 time interval
figure;
cfg = [];
cfg.xlim = [0.3 0.5];
cfg.colorbar = 'yes';
cfg.layout = 'CTF151_helmet.mat';
ft_topoplotER(cfg, avgFIC);

% topographic: 1 condition, 12 time intervals
figure;
cfg = [];
cfg.xlim = [-0.2 : 0.1 : 1.0];  % Define 12 time intervals
cfg.zlim = [-2e-13 2e-13];      % Set the 'color' limits.
cfg.layout = 'CTF151_helmet.mat';
clf;
ft_topoplotER(cfg, avgFIC);

%% Planar gradient

cfg                 = [];
cfg.feedback        = 'yes';
cfg.method          = 'template';
cfg.neighbours      = ft_prepare_neighbours(cfg, avgFIC);

cfg.planarmethod    = 'sincos';
avgFICplanar        = ft_megplanar(cfg, avgFIC);

% compute amplitude of planar gradient
cfg = [];
avgFICplanarComb = ft_combineplanar(cfg, avgFICplanar);

% plot the results
figure;
clf
subplot(121); % this has the original avgFIC
    cfg = [];
    cfg.xlim = [0.3 0.5];
    cfg.zlim = 'maxmin';
    cfg.colorbar = 'yes';
    cfg.layout = 'CTF151_helmet.mat';
    ft_topoplotER(cfg, avgFIC)
    colorbar; % you can also try out cfg.colorbar = 'south'
subplot(122); % this has the combined planar gradient avgFIC
    cfg.zlim = 'maxabs';
    cfg.layout = 'CTF151_helmet.mat';
    ft_topoplotER(cfg, avgFICplanarComb);
