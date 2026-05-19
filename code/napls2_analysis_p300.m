%--------------------------------------------------------------------------
% NAPLS2 E/I Project: Analysis pipeline for the P300 data.
% 
% Runs analysis for the paper:
% "Biophysical modeling of excitation/inhibition balance and conversion to 
% psychosis in the clinical high risk syndrome"
% Rodriguez-Sanchez*, Hauke*, et al. (2026)
%--------------------------------------------------------------------------

%% Clear work space
restoredefaultpath
close all
clear
clc

%% Set options
% Steps
opt.task = 'P300';
opt.demographics    = 1; % Generate demographics table
opt.sensor_level    = 1; % Run sensor-level analysis
opt.grand_average   = 1; % Grand-average data for modelling
opt.source_recon    = 1; % Run source reconstruction
opt.fit_mean        = 1; % Fit DCM to grand mean
opt.fit_individuals = 1; % Fit DCM to individual subjects
opt.diagnostics     = 1; % Check model diagnostics
opt.peb             = 1; % Run PEB
opt.simulations     = 1; % Run simulations

% Plotting options
opt.vis_plots       = 'on'; % 'on' to show plots throughout
                            % 'off' plots are saved in the background

%% Specify user specific paths
[~, opt.user_id] = unix('whoami'); % get user id
opt.user_id = opt.user_id(1:end-1);

% Specify local paths
switch opt.user_id
    % Julia's paths
    case 'ahjr-radams-lt\julia'      
        opt.pcode         = 'C:/Users/Julia/Documents/NAPLS/napls_ei/code/';
        opt.pdata         = 'D:/NAPLS2_FASTER/P300_preprocessed_Hamilton_v2/NAPLS2-AOD-baseline-ERPfiles/';
        opt.presults      = 'D:/NAPLS2_FASTER/P300_preprocessed_Hamilton_v2/polished/';
        opt.fsubjects     = 'D:/NAPLS2_FASTER/NAPLS-2 AOD FINAL DATABASE June 2024_JRS.xlsx';
    otherwise
        error('Undefined user! Please specify a user in the "Specify user-specific paths" section and provide the relevant paths.');
end

%% Setup

% Create folders
if ~isfolder(opt.presults); mkdir(opt.presults); end

opt.pfigures = fullfile(opt.presults, 'figures_paper');
if ~isfolder(opt.pfigures); mkdir(opt.pfigures); end

opt.psubjects = fullfile(opt.presults, 'subjects');
if ~isfolder(opt.psubjects);  mkdir(opt.psubjects); end

opt.pmean = fullfile(opt.presults, 'grand_mean');
if ~isfolder(opt.pmean); mkdir(opt.pmean); end

% Add code & toolboxes to path
addpath(opt.pcode)
setup_paths

%% Generate demographics table

if opt.demographics
    % Demographics across MMN and P300 - Table 1
    napls2_demographics_tbl1;
    
    % Demographics for the P300 task - Table S2
    napls2_demographics_suppl(opt);
end

%% Plot ERPs by group

if opt.sensor_level
    napls2_sensor_p300(opt); 
end

%% Grand average data

if opt.grand_average 
    napls2_average_p300(opt);
end

%% Run source reconstruction to identify regions for the P300 task

if opt.source_recon
    napls2_source_recon(opt);
end

%% Fit grand mean to get empirical priors

if opt.fit_mean
    napls2_p300_fit_dcm_to_grandmean;
end

%% Fit individual subjects

if opt.fit_individuals
    % Get SPM files
    temp = dir(fullfile(opt.psubjects,'filtered','f15_Mp*.mat'));
    if isempty(temp); error('No SPM files found! Please convert data to SPM format.'); end
    spm_subjects = fullfile({temp.folder}',{temp.name}');
    clear temp
    
    % Run DCM for each subject
    for s = 1:numel(spm_subjects)
        napls2_p300_fit_dcm_to_individuals(s); 
    end 
    % If running on cluster, use sub_p300_dcm.sh instead.
end

%% Check model diagnostics

if opt.diagnostics
    % Model fit - Fig. 1e and S1b
    napls2_model_fit(opt);
    
    % Parameter correlations - Fig. S1d
    napls2_param_correlations(opt);
        
    % Sensitivity analysis - Fig. S7-10
    napls2_sim_sensitivity(opt);
end

%% Run Parametric Empirical Bayes

if opt.peb
    opt.dcm_version = 21;
    opt.peb_version = 1;
    opt.run_peb = 1;
    opt.plot_peb = 1;
    opt.field = {'B_g_ee','B_g_ii'};
    
    % CHR-Converters v CHR-Remitters (age and site covariates) - Fig. 2b
    opt.groups = 4;
    opt.use_cov = 2;
    opt.add_inter = 0;
    opt.use_site = 1;
    opt.use_ap = 0;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_p300_peb(opt);
    
    % CHR-Converters v SOPS Positive - Fig. 2d
    opt.groups = 6;
    opt.use_cov = 0;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 1;
    opt.exclude_ap = 0;
    napls2_p300_peb(opt);
    
    % CHR-Converters + CHR-Remitters v Age - Fig. S2b
    opt.groups = 4;
    opt.use_cov = 1;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_p300_peb(opt);
    
    % CHR-Converters + CHR-Remitters v Age x Group - Fig. S2d
    opt.groups = 4;
    opt.use_cov = 1;
    opt.add_inter = 1;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_p300_peb(opt);
    
    % CHR-Converters + CHR-Remitters v Antipsychotic use - Fig. S3b
    opt.groups = 4;
    opt.use_cov = 1;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 1;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_p300_peb(opt);
    
    % CHR-Converters + CHR-Remitters v Antipsychotic use x Group - Fig. S3d
    opt.groups = 4;
    opt.use_cov = 1;
    opt.add_inter = 1;
    opt.use_site = 0;
    opt.use_ap = 1;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_p300_peb(opt);
    
    % CHR-Converters v CHR-Remitters (antipsychotic use covariates) - Fig. S4b
    opt.groups = 4;
    opt.use_cov = 2;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 1;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_p300_peb(opt);
    
    % CHR-Converters v CHR-Remitters (unmedicated only) - Fig. S4d
    opt.groups = 4;
    opt.use_cov = 0;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 0;
    opt.exclude_ap = 1;
    napls2_p300_peb(opt);
    
    % CHR-Converters v SOPS Positive (unmedicated only) - Fig. S4f
    opt.groups = 6;
    opt.use_cov = 0;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 1;
    opt.exclude_ap = 1;
    napls2_p300_peb(opt);
    
    % CHR-Remitters v SOPS Positive - Fig. S5b
    opt.groups = 7;
    opt.use_cov = 0;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 1;
    opt.exclude_ap = 0;
    napls2_p300_peb(opt);
    
    % CHR-Remitters v SOPS Positive (unmedicated only) - Fig. S5d
    opt.groups = 7;
    opt.use_cov = 0;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 1;
    opt.exclude_ap = 1;
    napls2_p300_peb(opt);
    
    % CHR-Converters v HC - Fig. S6b 
    opt.groups = 2;
    opt.use_cov = 2;
    opt.add_inter = 0;
    opt.use_site = 1;
    opt.use_ap = 0;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_p300_peb(opt);
    
    % CHR-Converters v CHR-Nonconverters - Fig. S6d
    opt.groups = 3;
    opt.use_cov = 2;
    opt.add_inter = 0;
    opt.use_site = 1;
    opt.use_ap = 0;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_p300_peb(opt);
    
    % CHR-Converters + CHR-Persistent v CHR-Remitters - Fig. S6e
    opt.groups = 8;
    opt.use_cov = 2;
    opt.add_inter = 0;
    opt.use_site = 1;
    opt.use_ap = 0;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_p300_peb(opt);
end

%% Run simulations

if opt.simulations
    napls2_sim_grandmean(opt);
end