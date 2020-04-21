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
cfg.channel   = {'MEG', '-MLP31', '-MLO12'};        % read all MEG channels except MLP31 and MLO12
cfg.demean    = 'yes';                              % do baseline correction with the complete trial

% NOTE: compared to day 1, there is no baseline window and filter specified
% here

data_all = ft_preprocessing(cfg);

%% Select one of the trial types for analysis

cfg = [];
cfg.trials = data_all.trialinfo == 3;
dataFIC = ft_redefinetrial(cfg, data_all);

% save
save dataFIC dataFIC

%% Time-frequency analysis
% Hanning taper, fixed window length

%{
load dataFIC
%} 

% specify time-frequency analysis specs
cfg              = [];
cfg.output       = 'pow';
cfg.channel      = 'MEG';
cfg.method       = 'mtmconvol';
cfg.taper        = 'hanning';
cfg.foi          = 2:2:30;                         % analysis 2 to 30 Hz in steps of 2 Hz
cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;   % length of time window = 0.5 sec
cfg.toi          = -0.5:0.05:1.5;                  % time window "slides" from -0.5 to 1.5 sec in steps of 0.05 sec (50 ms)
TFRhann = ft_freqanalysis(cfg, dataFIC);

% plot the results

% multiplot: all channels, time-frequency difference compared to the baseline
cfg = [];
cfg.baseline     = [-0.5 -0.1];
cfg.baselinetype = 'absolute';
cfg.zlim         = [-2.5e-27 2.5e-27];
cfg.showlabels   = 'yes';
cfg.layout       = 'CTF151_helmet.mat';
figure;
ft_multiplotTFR(cfg, TFRhann);

% multiplot: all channels, time-frequency difference compared to the baseline
cfg = [];
cfg.baseline     = [-0.5 -0.1];
cfg.baselinetype = 'relative';
cfg.zlim         = [0 3.0];
cfg.showlabels   = 'yes';
cfg.layout       = 'CTF151_helmet.mat';
figure;
ft_multiplotTFR(cfg, TFRhann);

% singleplot: one channel, time-frequency difference compared to the baseline
cfg = [];
cfg.baseline     = [-0.5 -0.1];
cfg.baselinetype = 'absolute';
cfg.maskstyle    = 'saturation';
cfg.zlim         = [-2.5e-27 2.5e-27];
cfg.channel      = 'MRC15';
cfg.layout       = 'CTF151_helmet.mat';
figure;
ft_singleplotTFR(cfg, TFRhann);

% singleplot: one channel, time-frequency difference compared to the baseline
cfg = [];
cfg.baseline     = [-0.5 -0.1];
cfg.baselinetype = 'relative';
cfg.maskstyle    = 'saturation';
cfg.zlim         = [0 3.0];
cfg.channel      = 'MRC15';
cfg.layout       = 'CTF151_helmet.mat';
figure;
ft_singleplotTFR(cfg, TFRhann);

% topoplot: 
cfg = [];
cfg.baseline     = [-0.5 -0.1];
cfg.baselinetype = 'absolute';
cfg.xlim         = [0.9 1.3];
cfg.zlim         = [-1e-27 1e-27];
cfg.ylim         = [15 20];
cfg.marker       = 'on';
cfg.layout       = 'CTF151_helmet.mat';
cfg.colorbar     = 'yes';
figure;
ft_topoplotTFR(cfg, TFRhann);

% topoplot: 
cfg = [];
cfg.baseline     = [-0.5 -0.1];
cfg.baselinetype = 'relative';
cfg.xlim         = [0.9 1.3];
cfg.zlim         = [0 3.0];
cfg.ylim         = [15 20];
cfg.marker       = 'on';
cfg.layout       = 'CTF151_helmet.mat';
cfg.colorbar     = 'yes';
figure;
ft_topoplotTFR(cfg, TFRhann);

%% Time-frequency analysis 2
% Hanning taper, frequency dependent window length

% configuration for a 7-cycle time window
cfg              = [];
cfg.output       = 'pow';
cfg.channel      = 'MRC15';
cfg.method       = 'mtmconvol';
cfg.taper        = 'hanning';
cfg.foi          = 2:1:30;
cfg.toi          = -0.5:0.05:1.5;
% 4 cycles per time window
cfg.t_ftimwin    = 4./cfg.foi;
TFRhann4 = ft_freqanalysis(cfg, dataFIC);
% 5 cycles per time window:
cfg.t_ftimwin    = 5./cfg.foi;
TFRhann5 = ft_freqanalysis(cfg, dataFIC);
% 7 cycles per time window
cfg.t_ftimwin    = 7./cfg.foi;  
TFRhann7 = ft_freqanalysis(cfg, dataFIC);
% 10 cycles per time window:
cfg.t_ftimwin    = 10./cfg.foi;
TFRhann10 = ft_freqanalysis(cfg, dataFIC);

% plot the results

% singleplot: one channel, time-frequency difference compared to the baseline
cfg              = [];
cfg.baseline     = [-0.5 -0.1];
cfg.baselinetype = 'absolute';
cfg.maskstyle    = 'saturation';
cfg.zlim         = [-2e-27 2e-27];
cfg.channel      = 'MRC15';
cfg.interactive  = 'no';
cfg.layout       = 'CTF151_helmet.mat';
figure;
subplot(221)
ft_singleplotTFR(cfg, TFRhann4);
subplot(222)
ft_singleplotTFR(cfg, TFRhann5);
subplot(223)
ft_singleplotTFR(cfg, TFRhann7);
subplot(224)
ft_singleplotTFR(cfg, TFRhann10);

%% Time-frequency analysis 3
% multitapers

% configuration for the multitapers
cfg = [];
cfg.output     = 'pow';
cfg.channel    = 'MEG';
cfg.method     = 'mtmconvol';
cfg.foi        = 1:2:30;
cfg.t_ftimwin  = 5./cfg.foi;    % the length of the sliding time-window in seconds 
cfg.tapsmofrq  = 0.4 *cfg.foi;  % the width of frequency smoothing in Hz
cfg.toi        = -0.5:0.05:1.5;
TFRmult = ft_freqanalysis(cfg, dataFIC);

% plot the result

% multiplot: all channels, absolute baseline
cfg = [];
cfg.baseline     = [-0.5 -0.1];
cfg.baselinetype = 'absolute';
cfg.zlim         = [-2e-27 2e-27];
cfg.showlabels   = 'yes';
cfg.layout       = 'CTF151_helmet.mat';
cfg.colorbar     = 'yes';
figure;
ft_multiplotTFR(cfg, TFRmult)

%% Time-frequency analysis 4
% Morlet wavelets

% calculate TFRs using Morlet wavelet: 4 different widths
cfg = [];
cfg.channel    = 'MEG';
cfg.method     = 'wavelet';
cfg.output     = 'pow';
cfg.foi        = 1:2:30;
cfg.toi        = -0.5:0.05:1.5;
cfg.width      = 3;
TFRwave3 = ft_freqanalysis(cfg, dataFIC);
cfg.width      = 5;
TFRwave5 = ft_freqanalysis(cfg, dataFIC);
cfg.width      = 7;     % this was the standard one
TFRwave7 = ft_freqanalysis(cfg, dataFIC);
cfg.width      = 10;
TFRwave10 = ft_freqanalysis(cfg, dataFIC);

% plot the result

% singleplot: one channel, four different widths
cfg              = [];
cfg.baseline     = [-0.5 -0.1];
cfg.baselinetype = 'absolute';
cfg.maskstyle    = 'saturation';
cfg.zlim         = [-2e-25 2e-25];
cfg.channel      = 'MLC24';
cfg.interactive  = 'no';
cfg.layout       = 'CTF151_helmet.mat';
figure;
subplot(221)
ft_singleplotTFR(cfg, TFRwave3)
subplot(222)
ft_singleplotTFR(cfg, TFRwave5)
subplot(223)
ft_singleplotTFR(cfg, TFRwave7)
subplot(224)
ft_singleplotTFR(cfg, TFRwave10)