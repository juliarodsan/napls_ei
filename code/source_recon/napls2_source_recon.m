%% Source reconstruction for NAPLS2 P300 data

function napls2_source_recon(opt)

% Use MSP to test the following networks agains unconstrained (IID) source
% reconstruction:

% Sources from  Kim 2014 https://doi.org/10.1002/hbm.22326
% MSP analysis 1 (consists of ventral attention network + auditory visual network)
% - rTPJ: 52 -52 28 (peak converted to MNI from https://journals.sagepub.com/doi/abs/10.1177/1073858407304654, confirmed by eyeballing Figure 3 in Kim 2014)
% - lTPJ: -52 -52 28 (flipped rTPJ)
% - rAI: 32 24 6 (converted to MNI from: https://www.sciencedirect.com/science/article/pii/S0730725X02004964#FIG4, confirmed by eyeballing Figure 3 in Kim 2014)
% - lAI: -32 20 14 (converted to MNI from: https://www.sciencedirect.com/science/article/pii/S0730725X02004964#FIG4, confirmed by eyeballing Figure 3 in Kim 2014)
% - right aMFG: 39 29 30 (Table S2 converted to MNI)
% - left aMFG: -37 36 30 (Table S2 converted to MNI)
% - rACC/SMA: 3 5 44 (flipped lACC )
% - lACC/SMA: -3 5 44 (Table S2 converted to MNI)
% - rTTG: 57 -42 21; (Table S2 converted to MNI with https://bioimagesuiteweb.github.io/webapp/mni2tal.html)
% - lTTG: -57 -42 21 (flipped x coordinates)
% - rSTG: 59 -25 8 (from Garrido et al 2007, https://www.sciencedirect.com/science/article/pii/S1053811907001358?via%3Dihub confirmed by eyeballing Figure 3 in Kim 2014)
% - lSTG -61 -32 8 (from Garrido et al 2007, https://www.sciencedirect.com/science/article/pii/S1053811907001358?via%3Dihub confirmed by eyeballing Figure 3 in Kim 2014)
% - right Lingual gyrus: 16 -70 0 (Table S2 converted to MNI)
% - right lingual gyrus: -9 -68 0 (Table S2 converted to MNI)
%
% MSP analysis 2 (consists of dorsal attention network + auditory visual network)
% - rIFJ: 50 8 30 (Table S2 converted to MNI)
% - lIFJ: -56 7 29 (Table S2 converted to MNI)
% - l medial IPS/SPL: -33 -42 64 (Table S2 converted to MNI)
% - r medial IPS/SPL: 33 -42 64 (flipped left Medial IPS/SPL)
% - rTTG: 57 -42 21; (Table S2 converted to MNI with https://bioimagesuiteweb.github.io/webapp/mni2tal.html)
% - lTTG: -57 -42 21 (flipped x coordinates)
% - rSTG: 59 -25 8 (from Garrido et al 2007, https://www.sciencedirect.com/science/article/pii/S1053811907001358?via%3Dihub confirmed by eyeballing Figure 3 in Kim 2014)
% - lSTG -61 -32 8 (from Garrido et al 2007, https://www.sciencedirect.com/science/article/pii/S1053811907001358?via%3Dihub confirmed by eyeballing Figure 3 in Kim 2014)
% - right Lingual gyrus: 16 -70 0 (Table S2 converted to MNI)
% - right lingual gyrus: -9 -68 0 (Table S2 converted to MNI)

%% Settings
method  = {'IID', 'MSP', 'MSP'}; % Choose source recon method: 'MSP' or 'IID'
network = {'IID', 'DAN_STG', 'VAN_STG'};
fwd_model = '3-Shell Sphere';
woi       = [-100 800];

%% Create results directory
opt.psources = fullfile(opt.presults, 'source_recon', 'filtered');
if ~isfolder(opt.psources); mkdir(opt.psources); end

fmean = fullfile(opt.pmean, 'filtered', 'p300_grandmean_hc_f15.mat');
[~, fname, ext] = fileparts(fmean);

%% Create a copy of the data file
cd(opt.psources)
D = spm_eeg_load(fmean);
copy(D, fullfile(opt.psources, [fname ext]));
clear D

%% Run
for val = 1:numel(method)
    
    % Load correct network
    switch network{val}
        case 'IID'
            source_coords = [0 0 0];
            source_labels = {''};
        case 'DAN_STG'
            source_coords = [ 50   8 30;
                             -56   7 29;
                              33 -42 64;
                             -33 -42 64;
                              59 -25  8;
                             -61 -32  8];
            
            source_labels = {'rIFJ';
                             'lIFJ';
                             'rIPS';
                             'lIPS';
                             'rSTG';
                             'lSTG'}';
        case 'VAN_STG'
            source_coords = [ 52 -52 28;
                             -52 -52 28;
                              32  24  6;
                             -32  20 14;
                              39  29 30;
                             -37  36 30;
                               3   5 44;
                              -3   5 44;
                              59 -25  8;
                             -61 -32  8];
            
            source_labels = {'rTPJ';
                             'lTPJ';
                             'rAI';
                             'lAI';
                             'rMFG';
                             'lMFG';
                             'rACC';
                             'lACC';
                             'rSTG';
                             'lSTG'}';
    end
    
    % Head model job
    job = cell(0);
    job{1}.spm.meeg.source.headmodel.D = {fullfile(opt.psources, [fname ext])};
    job{1}.spm.meeg.source.headmodel.val = val;
    job{1}.spm.meeg.source.headmodel.meshing.meshes.template = 1;
    job{1}.spm.meeg.source.headmodel.meshing.meshres = 2;
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.fiducial(1).fidname = 'spmnas';
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.fiducial(1).specification.type = [1 85 -41];
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.fiducial(2).fidname = 'spmlpa';
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.fiducial(2).specification.type = [-83 -20 -65];
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.fiducial(3).fidname = 'spmrpa';
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.fiducial(3).specification.type = [83 -20 -65];
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.useheadshape = 0;
    job{1}.spm.meeg.source.headmodel.forward.eeg = fwd_model;
    
    % Inversion job
    job{2}.spm.meeg.source.invert.D = {fullfile(opt.psources, [fname ext])};
    job{2}.spm.meeg.source.invert.val = val;
    job{2}.spm.meeg.source.invert.whatconditions.condlabel = {'standard'
                                                              'target'}';
    job{2}.spm.meeg.source.invert.isstandard.custom.invtype = method{val};
    job{2}.spm.meeg.source.invert.modality = {'EEG'};
    job{2}.spm.meeg.source.invert.isstandard.custom.woi = woi;
    job{2}.spm.meeg.source.invert.isstandard.custom.hanning = 1;
    job{2}.spm.meeg.source.invert.isstandard.custom.priors.priorsmask = {''};
    job{2}.spm.meeg.source.invert.isstandard.custom.priors.space = 1;
    job{2}.spm.meeg.source.invert.isstandard.custom.restrict.locs = source_coords; 
    job{2}.spm.meeg.source.invert.isstandard.custom.restrict.radius = 16;
    % spm_jobman('interactive', job);
    spm_jobman('run', job);
    
    saveas(gcf,fullfile(opt.psources,[network{val} '.png']));
    
    % Extract source time course (for MSP only)
    if strcmp(method{val},'MSP')
        job = cell(0);
        job{1}.spm.meeg.source.extract.D(1) = {fullfile(opt.psources, [fname ext])};
        job{1}.spm.meeg.source.extract.val = val;
        job{1}.spm.meeg.source.extract.rad = 16;
        job{1}.spm.meeg.source.extract.type = 'trials';
        job{1}.spm.meeg.source.extract.fname = fullfile(opt.psources,[fname '_' network{val}]);
        job{1}.spm.meeg.source.extract.source = struct();
        for s = 1:numel(source_labels)
            job{1}.spm.meeg.source.extract.source(s).label = source_labels{s};
            job{1}.spm.meeg.source.extract.source(s).xyz = source_coords(s,:);
        end
        spm_jobman('run', job);
    end
    
end
end