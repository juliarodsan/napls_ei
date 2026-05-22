%% Fit DCM to single subject P300 data

function napls2_p300_fit_dcm_to_grandmean(subj)

%% Options
version            = 1; % Set version (will be appended to results directory and DCM file)
run_headmodel      = 1; % Run a headmodel (required once before running a DCM inversion)
run_dcm            = 1; % Run DCM inversion
use_ep             = 1; % Flag to use posteriors from another inversion as priors

%% Specify user-specific paths
[~, user_id] = unix('whoami'); % get user id
user_id = user_id(1:end-1);

% Specify local paths
switch user_id
    case 'ahjr-radams-lt\julia' % Julia's paths
        pmain = 'D:/NAPLS2_FASTER/P300_preprocessed_Hamilton_v2/polished/';
        pcode = 'C:/Users/Julia/Documents/NAPLS/napls_ei/code/';
    otherwise % Julia's cluster paths
        pmain = '/SAN/intelsys/Psycho_Pheno2/Data/NAPLS2_FASTER/P300_preprocessed_Hamilton_v2';
        pcode = '/SAN/intelsys/Psycho_Pheno/Dropbox/Rick/Academic/Rodriguez-Sanchez/Code/NAPLS/dcm_ei_sim/code/';
end

pmean = fullfile(pmain,'grand_mean','filtered');
presults = fullfile(pmain,'dcm_ei',['p300_grandmean_all_v' num2str(version)]);
fep = fullfile(pmain,'dcm_ei','priors','dcm_p300_grandmean_hc_cmc_ei_v1_vbsv1753.mat');

%% Settings
% Set file prefix
dcm_prefix = 'dcm_p300'; % prefix of DCM file (model, ID and version will be appended)

% Condition names
conditions = {'standard', 'target'};

%% Run
file = dir(fullfile(pmean,'p300_grandmean_all_f15.mat'));
disp(['Fitting grand mean data! Results will be saved in ' presults])

%% Setup paths and results folder
cd(pcode);
setup_paths;
[~,~] = mkdir(presults);
cd(presults);

%% Fit head model
if run_headmodel
    cd(file(subj).folder);
    
    % Clean up previous source localisation
    D = spm_eeg_load(file(subj).name);
    try D = rmfield(D,'inv'); end
    save(D); clear D;
    
    % Specify new head model
    job{1}.spm.meeg.source.headmodel.D = {file(subj).name};
    job{1}.spm.meeg.source.headmodel.val = 1;
    job{1}.spm.meeg.source.headmodel.comment = '';
    job{1}.spm.meeg.source.headmodel.meshing.meshes.template = 1;
    job{1}.spm.meeg.source.headmodel.meshing.meshres = 2;
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.fiducial(1).fidname = 'spmnas';
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.fiducial(1).specification.type = [1 85 -41];
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.fiducial(2).fidname = 'spmlpa';
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.fiducial(2).specification.type = [-83 -20 -65];
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.fiducial(3).fidname = 'spmrpa';
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.fiducial(3).specification.type = [83 -20 -65];
    job{1}.spm.meeg.source.headmodel.coregistration.coregspecify.useheadshape = 0;
    job{1}.spm.meeg.source.headmodel.forward.eeg = '3-Shell Sphere';
    job{1}.spm.meeg.source.headmodel.forward.meg = 'Single Shell';
    
    tic;
    spm_jobman('run',{job});
    t = toc;
    fprintf('===\n\t Headmodel done in %s (HH:MM:SS).\n\n\n', datestr(datenum(0,0,0,0,0,t),'HH:MM:SS'));
end

%% Run DCM
if run_dcm
    % Set ID
    id = 'grandmean_all';
    
    % Switch off graphics if running on the cluster
    if startsWith(pcode,'/SAN/intelsys/'); no_graph = 1; 
    else no_graph = 0; end
    
    % Initialise DCM
    disp('Initialising DCM...')
    DCM = struct();
    
    % Set DCM type
    DCM.options.model = 'cmc';
    
    % Set DCM name
    dcm_name = [dcm_prefix '_' DCM.options.model];
    DCM.name = fullfile(presults, [dcm_name '_' id '.mat']);
    
    % Set data file name
    DCM.xY.Dfile = fullfile(file(subj).folder, file(subj).name);
    
    % DCM options
    DCM.options.analysis = 'ERP';       % analyse evoked responses
    DCM.options.spatial  = 'ECD';       % spatial model
    DCM.options.trials   = [1 2];       % index of ERPs within ERP/ERF file
    DCM.options.Tdcm(1)  = -100;        % start of peri-stimulus time to be modelled
    DCM.options.Tdcm(2)  = 800;         % end of peri-stimulus time to be modelled
    DCM.options.Nmodes   = 8;           % nr of modes for data selection
    DCM.options.h        = 1;           % nr of DCT components
    DCM.options.D        = 2;           % downsampling
    DCM.options.han      = 1;           % Hanning window
    DCM.options.onset    = 100;         % onset mean of input
    DCM.options.dur      = 16;          % sd of onset
    DCM.M.Nmax           = 64;          % default: 64
    
    % Sources
    DCM.Sname = {'lSTG', 'rSTG', 'lIFJ', 'rIFJ', 'lIPS', 'rIPS'};
    DCM.Lpos  = [-61 -32  8;  
                  59 -25  8;
                 -56   7 29;  
                  50   8 30;
                 -33 -42 64;  
                  33 -42 64]';
    
    % Forward connections
    DCM.A{1} = zeros(numel(DCM.Sname));
    DCM.A{1}(3,1) = 1;
    DCM.A{1}(4,2) = 1;
    DCM.A{1}(5,3) = 1;
    DCM.A{1}(6,4) = 1;
    
    % Backward connections
    DCM.A{2} = zeros(numel(DCM.Sname));
    DCM.A{2}(1,3) = 1;
    DCM.A{2}(2,4) = 1;
    DCM.A{2}(3,5) = 1;
    DCM.A{2}(4,6) = 1;
    
    % Connections modulated by condition
    DCM.B{1} = DCM.A{1} + DCM.A{2}; % Main effect of condition
    
    % Lateral connections
    DCM.A{1}(1,2) = 1;
    DCM.A{1}(2,1) = 1;
    DCM.A{1}(3,4) = 1;
    DCM.A{1}(4,3) = 1;
    DCM.A{1}(5,6) = 1;
    DCM.A{1}(6,5) = 1;
    
    % Input
    DCM.C = [1; 1; 0; 0; 0; 0];
    
    % Between trial effects
    DCM.xU.name{1} = {['Main effect of condition: ' conditions{2} ' > ' conditions{1}]};
    DCM.xU.X(:,1)  = [-1; 1];
    
    % Get priors
    DCM = get_priors_ei_cmc(DCM);
    
    % Adjust priors
    if use_ep
        ep = load(fep);
        DCM.M.pE = ep.DCM.Ep;
        DCM.M.pC = ep.DCM.M.pC;
        disp(['Using existing priors from ' fep])
    end
    
    % Adjust input onset and duration
    DCM.M.pC.R = [1/1024 1/1024];
    
    if no_graph
        DCM.M.nograph = 1; % No figure if running on cluster
    end
    
    % Invert
    DCM_inv = spm_dcm_erp(DCM);
    
    if ~startsWith(pcode,'/SAN/intelsys/')
        % If running locally, save inversion plot
        psave = fullfile(presults,['plots_' dcm_name],'inversion');
        if ~exist(psave,'dir'); mkdir(psave); end
        saveas(gcf,fullfile(psave, [id, '_inversion_plot.png']));
        saveas(gcf,fullfile(psave, [id, '_inversion_plot.fig']));

        % ...and save model fit
        fh = plot_actual_vs_predicted_responses(DCM_inv, conditions, 'off');
        psave = fullfile(presults,['plots_' dcm_name], 'model_fit');
        if ~exist(psave,'dir'); mkdir(psave); end
        saveas(fh,fullfile(psave, [id, '_model_fit_plot.png']));
        saveas(fh,fullfile(psave, [id, '_model_fit_plot.fig']));
    end
end
end
