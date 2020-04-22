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

% remove the trials that have artifacts from the trl
cfg.trl([2, 5, 6, 8, 9, 10, 12, 39, 43, 46, 49, 52, 58, 84, 102, 107, 114, 115, 116, 119, 121, 123, 126, 127, 128, 132, 133, 137, 143, 144, 147, 149, 158, 181, 229, 230, 233, 241, 243, 245, 250, 254, 260],:) = [];

% preprocess the data
cfg.channel   = {'MEG', '-MLP31', '-MLO12'};        % read all MEG channels except MLP31 and MLO12
cfg.demean    = 'yes';                              % do baseline correction with the complete trial

data_all = ft_preprocessing(cfg);

%% Define time windows

cfg = [];
cfg.trials = data_all.trialinfo == 3;
cfg.toilim = [-0.5 0];
dataPre = ft_redefinetrial(cfg, data_all);

cfg.trials = data_all.trialinfo == 3;
cfg.toilim = [0.8 1.3];
dataPost = ft_redefinetrial(cfg, data_all);

%% Cross-spectral density matrix

cfg = [];
cfg.method    = 'mtmfft';
cfg.output    = 'powandcsd';
cfg.tapsmofrq = 4;
cfg.foilim    = [18 18];
freqPre = ft_freqanalysis(cfg, dataPre);

cfg = [];
cfg.method    = 'mtmfft';
cfg.output    = 'powandcsd';
cfg.tapsmofrq = 4;
cfg.foilim    = [18 18];
freqPost = ft_freqanalysis(cfg, dataPost);

%% The forward model and lead field matrix
% Head model

% load segmented MRI from Fieldtrip
load segmentedmri

%{
% segmentation
mri = ft_read_mri('Subject01/Subject01.mri');
cfg = [];
cfg.write      = 'no';
[segmentedmri] = ft_volumesegment(cfg, mri);
%}

% prepare head model from segmented brain surface
cfg = [];
cfg.method = 'singleshell';
headmodel = ft_prepare_headmodel(cfg, segmentedmri);

% visualise the head model
figure
ft_plot_sens(freqPost.grad);
hold on
ft_plot_headmodel(ft_convert_units(headmodel,'cm'));

% lead fields
cfg                 = [];
cfg.grad            = freqPost.grad;
cfg.headmodel       = headmodel;
cfg.reducerank      = 2;
cfg.channel         = {'MEG','-MLP31', '-MLO12'};
cfg.resolution = 1;   % use a 3-D grid with a 1 cm resolution
cfg.sourcemodel.unit       = 'cm';
grid = ft_prepare_leadfield(cfg);

