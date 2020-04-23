%% Simulate data with directed connections

rng('default')
rng(50) %arbitrarily chosen random number generator for reproducibility

% configuration
cfg             = [];
cfg.ntrials     = 500;
cfg.triallength = 1;
cfg.fsample     = 200;
cfg.nsignal     = 3;
cfg.method      = 'ar';

% NxN coefficient matrices
cfg.params(:,:,1) = [ 0.8    0    0 ;
                        0  0.9  0.5 ;
                      0.4    0  0.5];

cfg.params(:,:,2) = [-0.5    0    0 ;
                        0 -0.8    0 ;
                        0    0 -0.2];

cfg.noisecov      = [ 0.3    0    0 ;
                        0    1    0 ;
                        0    0  0.2];

data              = ft_connectivitysimulation(cfg);

% plot the data
figure
plot(data.time{1}, data.trial{1})
legend(data.label)
xlabel('time (s)')

% browse through the data
cfg = [];
cfg.viewmode = 'vertical';  % you can also specify 'butterfly'
ft_databrowser(cfg, data);

% computation of the multivariate autoregressive model
cfg         = [];
cfg.order   = 5;
cfg.toolbox = 'bsmart';
mdata       = ft_mvaranalysis(cfg, data);

% computation of the spectral transfer function
cfg        = [];
cfg.method = 'mvar';
mfreq      = ft_freqanalysis(cfg, mdata);

% non-parametric computation of the cross-spectral density matrix
cfg           = [];
cfg.method    = 'mtmfft';
cfg.taper     = 'dpss';
cfg.output    = 'fourier';
cfg.tapsmofrq = 2;
freq          = ft_freqanalysis(cfg, data);

% computation and inspection of the connectivity measures
cfg           = [];
cfg.method    = 'coh';
coh           = ft_connectivityanalysis(cfg, freq);
cohm          = ft_connectivityanalysis(cfg, mfreq);

figure        % plot
cfg           = [];
cfg.parameter = 'cohspctrm';
cfg.zlim      = [0 1];
ft_connectivityplot(cfg, coh, cohm);

% estimate the spectral transfer matrix from the multivariate autoregressive model
cfg           = [];
cfg.method    = 'granger';
granger_mfreq = ft_connectivityanalysis(cfg, mfreq);
granger_freq  = ft_connectivityanalysis(cfg, freq);

figure;         % plot
cfg           = [];
subplot(121)
cfg.parameter = 'grangerspctrm';
cfg.zlim      = [0 1];
ft_connectivityplot(cfg, granger_mfreq);
subplot(122)
cfg.parameter = 'grangerspctrm';
cfg.zlim      = [0 1];
ft_connectivityplot(cfg, granger_freq);

%% Simulated data with common pick-up and different noise levels

% create some instantaneously mixed data

% define some variables locally
nTrials  = 100;
nSamples = 1000;
fsample  = 1000;

% mixing matrix
mixing   = [0.8 0.2 0;
              0 0.2 0.8];

data       = [];
data.trial = cell(1,nTrials);
data.time  = cell(1,nTrials);
for k = 1:nTrials
  dat = randn(3, nSamples);
  dat(2,:) = ft_preproc_bandpassfilter(dat(2,:), 1000, [15 25]);
  dat = 0.2.*(dat-repmat(mean(dat,2),[1 nSamples]))./repmat(std(dat,[],2),[1 nSamples]);
  data.trial{k} = mixing * dat;
  data.time{k}  = (0:nSamples-1)./fsample;
end
data.label = {'chan1' 'chan2'}';

figure;plot(dat'+repmat([0 1 2],[nSamples 1]));
title('original ''sources''');

figure;plot((mixing*dat)'+repmat([0 1],[nSamples 1]));
axis([0 1000 -1 2]);
set(findobj(gcf,'color',[0 0.5 0]), 'color', [1 0 0]);
title('mixed ''sources''');

% do spectral analysis
cfg = [];
cfg.method    = 'mtmfft';
cfg.output    = 'fourier';
cfg.foilim    = [0 200];
cfg.tapsmofrq = 5;
freq          = ft_freqanalysis(cfg, data);
fd            = ft_freqdescriptives(cfg, freq);

figure;plot(fd.freq, fd.powspctrm);
set(findobj(gcf,'color',[0 0.5 0]), 'color', [1 0 0]);
title('power spectrum');

% compute connectivity
cfg = [];
cfg.method = 'granger';
g = ft_connectivityanalysis(cfg, freq);
cfg.method = 'coh';
c = ft_connectivityanalysis(cfg, freq);

% visualize the results
cfg = [];
cfg.parameter = 'grangerspctrm';
figure; ft_connectivityplot(cfg, g);
cfg.parameter = 'cohspctrm';
figure; ft_connectivityplot(cfg, c);
