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
cfg.channel    = {'MEG', '-MLP31', '-MLO12'};        % read all MEG channels except MLP31 and MLO12
cfg.demean     = 'yes';
cfg.baselinewindow  = [-0.2 0];
cfg.lpfilter   = 'yes';                              % apply lowpass filter
cfg.lpfreq     = 35;                                 % lowpass at 35 Hz.

data_all = ft_preprocessing(cfg);

%% Select trial types for analysis

% Fully InCongruent trials (FIC)
cfg = [];
cfg.trials = data_all.trialinfo == 3;
dataFIC_LP = ft_redefinetrial(cfg, data_all);

% Fully Congruent trials (FIC)
cfg = [];
cfg.trials = data_all.trialinfo == 5;
dataFC_LP = ft_redefinetrial(cfg, data_all);

% save the data
save dataFIC_LP dataFIC_LP
save dataFC_LP dataFC_LP

%% Timelock

load dataFIC_LP
load dataFC_LP

cfg = [];
cfg.keeptrials = 'yes';
timelockFIC = ft_timelockanalysis(cfg, dataFIC_LP);
timelockFC  = ft_timelockanalysis(cfg, dataFC_LP);

%% Timelock statistic

% configuration
cfg = [];
cfg.method              = 'montecarlo'; % use the Monte Carlo Method to calculate the significance probability
cfg.statistic           = 'ft_statfun_indepsamplesT'; % use the independent samples T-statistic as a measure to evaluate the effect at the sample level
cfg.correctm            = 'cluster';
cfg.clusteralpha        = 0.05;     % alpha level of the sample-specific test statistic that will be used for thresholding
cfg.clusterstatistic    = 'maxsum'; % test statistic that will be evaluated under the permutation distribution.
cfg.minnbchan           = 2;        % minimum number of neighborhood channels that is required for a selected sample to be included in the clustering algorithm (default=0).
% cfg.neighbours = neighbours;      % see below
cfg.tail                = 0;        % -1, 1 or 0 (default = 0); one-sided or two-sided test
cfg.clustertail         = 0;
cfg.alpha               = 0.025;    % alpha level of the permutation test
cfg.numrandomization    = 100;      % number of draws from the permutation distribution

design = zeros(1,size(timelockFIC.trial,1) + size(timelockFC.trial,1));
design(1,1:size(timelockFIC.trial,1)) = 1;
design(1,(size(timelockFIC.trial,1)+1):(size(timelockFIC.trial,1) + size(timelockFC.trial,1)))= 2;

cfg.design              = design;   % design matrix
cfg.ivar                = 1;        % number or list with indices indicating the independent variable(s)

cfg_neighb              = [];
cfg_neighb.method       = 'distance';
neighbours              = ft_prepare_neighbours(cfg_neighb, dataFC_LP);

cfg.neighbours          = neighbours;  % the neighbours specify for each sensor with which other sensors it can form clusters
cfg.channel             = {'MEG'};     % cell-array with selected channel labels
cfg.latency             = [0 1];       % time interval over which the experimental conditions must be compared (in seconds)

% statistic
[stat] = ft_timelockstatistics(cfg, timelockFIC, timelockFC);

% save the output
save stat_ERF_axial_FICvsFC stat;

% load output
load stat_ERF_axial_FICvsFC

% plot the results
cfg = [];
figure
avgFIC = ft_timelockanalysis(cfg, dataFIC_LP);
avgFC = ft_timelockanalysis(cfg, dataFC_LP);

% take the difference of the averages using ft_math
cfg  = [];
cfg.operation = 'subtract';
cfg.parameter = 'avg';
raweffectFICvsFC = ft_math(cfg, avgFIC, avgFC);

% determine which clusters are reliable

pos_cluster_pvals = [stat.posclusters(:).prob];

% find which clusters are significant, outputting their indices as held in stat.posclusters
% In case you have downloaded and loaded the data, ensure stat.cfg.alpha exist
if ~isfield(stat.cfg,'alpha'); stat.cfg.alpha = 0.025; end; % stat.cfg.alpha was moved as the downloaded data was processed by an additional FieldTrip function to anonymize the data.

pos_signif_clust = find(pos_cluster_pvals < stat.cfg.alpha);
% (stat.cfg.alpha is the alpha level we specified earlier for cluster comparisons; In this case, 0.025)
% make a boolean matrix of which (channel,time)-pairs are part of a significant cluster
pos = ismember(stat.posclusterslabelmat, pos_signif_clust);

% and now for the negative clusters...
neg_cluster_pvals = [stat.negclusters(:).prob];
neg_signif_clust = find(neg_cluster_pvals < stat.cfg.alpha);
neg = ismember(stat.negclusterslabelmat, neg_signif_clust);

%{ 
% alternative way:
pos = stat.posclusterslabelmat == 1; % or == 2, or 3, etc.
  neg = stat.negclusterslabelmat == 1;
%}

% check that the sample-based time windows align with the time windows in seconds
timestep = 0.05; % timestep between time windows for each subplot (in seconds)
sampling_rate = dataFC_LP.fsample; % Data has a temporal resolution of 300 Hz
sample_count = length(stat.time);
% number of temporal samples in the statistics object
j = [0:timestep:1]; % Temporal endpoints (in seconds) of the ERP average computed in each subplot
m = [1:timestep*sampling_rate:sample_count]; % temporal endpoints in M/EEG samples

% plot the results

% First ensure the channels to have the same order in the average and in the statistical output.
% This might not be the case, because ft_math might shuffle the order
[i1,i2] = match_str(raweffectFICvsFC.label, stat.label);

figure
for k = 1:20
   subplot(4,5,k);
   cfg = [];
   cfg.xlim=[j(k) j(k+1)];   % time interval of the subplot
   cfg.zlim = [-2.5e-13 2.5e-13];
   % If a channel reaches this significance, then
   % the element of pos_int with an index equal to that channel
   % number will be set to 1 (otherwise 0).

   % Next, check which channels are significant over the
   % entire time interval of interest.
   pos_int = zeros(numel(raweffectFICvsFC.label),1);
   neg_int = zeros(numel(raweffectFICvsFC.label),1);
   pos_int(i1) = all(pos(i2, m(k):m(k+1)), 2);
   neg_int(i1) = all(neg(i2, m(k):m(k+1)), 2);

   cfg.highlight = 'on';
   % Get the index of each significant channel
   cfg.highlightchannel = find(pos_int | neg_int);
   cfg.comment = 'xlim';
   cfg.commentpos = 'title';
   cfg.layout = 'CTF151_helmet.mat';
   cfg.interactive = 'no';
   ft_topoplotER(cfg, raweffectFICvsFC);
end


