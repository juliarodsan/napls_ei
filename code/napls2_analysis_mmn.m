%--------------------------------------------------------------------------
% NAPLS2 E/I Project: Analysis pipeline for the MMN data.
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
opt.task = 'MMN';
opt.demographics    = 1; % Generate demographics table
opt.sensor_level    = 1; % Run sensor-level analysis
opt.grand_average   = 1; % Grand-average data for modelling
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
        opt.pmain         = 'D:/NAPLS2_FASTER/';
        opt.pcode         = 'C:/Users/Julia/Documents/NAPLS/napls_ei/code/';
        opt.pdata         = fullfile(opt.pmain, 'MMN_preprocessed_Hamilton', 'NAPLS2-MMN-baseline-ERPfiles');
        opt.presults      = fullfile(opt.pmain, 'MMN_preprocessed_Hamilton', 'polished');
        opt.fsubjects     = fullfile(opt.pmain, 'Demographics', 'NAPLS-2 MMN FINAL DATABASE March 2022_JRS.xlsx');
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
    napls2_demographics_tbl1(opt);
    
    % Demographics for the MMN task - Table S1
    napls2_demographics_suppl(opt);
end

%% Plot ERPs by group

if opt.sensor_level
    napls2_sensor_mmn(opt);
end

%% Grand average data

if opt.grand_average 
    napls2_average_mmn(opt);
end

%% Fit grand mean data
% napls2_mmn_fit_dcm_to_grandmean uses hardcoded paths (see function)

if opt.fit_mean
    napls2_mmn_fit_dcm_to_grandmean(1);
end

%% Fit individual subjects
% Note: napls2_mmn_fit_dcm_to_individuals uses hardcoded paths (see function)

if opt.fit_individuals
    % Get SPM files
    temp = dir(fullfile(opt.psubjects,'Mp*.mat'));
    if isempty(temp); error('No SPM files found! Please convert data to SPM format.'); end
    spm_subjects = fullfile({temp.folder}',{temp.name}');
    clear temp
    
    % Run DCM for each subject
    for s = 1:numel(spm_subjects)
        napls2_mmn_fit_dcm_to_individuals(s);
    end 
    % If running on cluster, use sub_mmn_dcm.sh instead.
end

%% Check model diagnostics

if opt.diagnostics
    % Model fit - Fig. 1d and S1a
    napls2_model_fit(opt);
    
    % Parameter correlations - Fig. S1c
    napls2_param_correlations(opt);
    
    % Sensitivity analysis - Fig. S7-10
    napls2_sim_sensitivity(opt);
end

%% Run Parametric Empirical Bayes

if opt.peb
    opt.vis_plots = 'off';
    opt.dcm_version = 14;
    opt.peb_version = 1;
    opt.run_peb = 1;
    opt.plot_peb = 1;
    opt.field = {'B_g_ee','B_g_ii'};
    
    % CHR-Converters v CHR-Remitters (age and site covariates) - Fig. 2a
    opt.groups = 4;
    opt.use_cov = 2;
    opt.add_inter = 0;
    opt.use_site = 1;
    opt.use_ap = 0;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_mmn_peb(opt);
    
    % CHR-Converters v SOPS Positive - Fig. 2c
    opt.groups = 6;
    opt.use_cov = 0;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 1;
    opt.exclude_ap = 0;
    napls2_mmn_peb(opt);
    
    % CHR-Converters + CHR-Remitters v Age - Fig. S2a
    opt.groups = 4;
    opt.use_cov = 1;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_mmn_peb(opt);
    
    % CHR-Converters + CHR-Remitters v Age x Group - Fig. S2c
    opt.groups = 4;
    opt.use_cov = 1;
    opt.add_inter = 1;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_mmn_peb(opt);
    
    % CHR-Converters + CHR-Remitters v Antipsychotic use - Fig. S3a
    opt.groups = 4;
    opt.use_cov = 1;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 1;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_mmn_peb(opt);
    
    % CHR-Converters + CHR-Remitters v Antipsychotic use x Group - Fig. S3c
    opt.groups = 4;
    opt.use_cov = 1;
    opt.add_inter = 1;
    opt.use_site = 0;
    opt.use_ap = 1;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_mmn_peb(opt);
    
    % CHR-Converters v Antipsychotic use - Fig. S3e
    opt.groups = 6;
    opt.use_cov = 1;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 1;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_mmn_peb(opt);
    
    % CHR-Remitters v Antipsychotic use - Fig. S3f
    opt.groups = 7;
    opt.use_cov = 1;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 1;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_mmn_peb(opt);
    
    % CHR-Converters v CHR-Remitters (antipsychotic use covariates) - Fig. S4a
    opt.groups = 4;
    opt.use_cov = 2;
    opt.add_inter = 2;
    opt.use_site = 0;
    opt.use_ap = 1;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_mmn_peb(opt);
    
    % CHR-Converters v CHR-Remitters (unmedicated only) - Fig. S4c
    opt.groups = 4;
    opt.use_cov = 0;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 0;
    opt.exclude_ap = 1;
    napls2_mmn_peb(opt);
    
    % CHR-Converters v SOPS Positive (unmedicated only) - Fig. S4e
    opt.groups = 6;
    opt.use_cov = 0;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 1;
    opt.exclude_ap = 1;
    napls2_mmn_peb(opt);
    
    % CHR-Remitters v SOPS Positive - Fig. S5a
    opt.groups = 7;
    opt.use_cov = 0;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 1;
    opt.exclude_ap = 0;
    napls2_mmn_peb(opt);
    
    % CHR-Remitters v SOPS Positive (unmedicated only) - Fig. S5c
    opt.groups = 7;
    opt.use_cov = 0;
    opt.add_inter = 0;
    opt.use_site = 0;
    opt.use_ap = 0;
    opt.use_symp = 1;
    opt.exclude_ap = 1;
    napls2_mmn_peb(opt);
    
    % CHR-Converters v HC - Fig. S6a 
    opt.groups = 2;
    opt.use_cov = 2;
    opt.add_inter = 0;
    opt.use_site = 1;
    opt.use_ap = 0;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_mmn_peb(opt);
    
    % CHR-Converters v CHR-Nonconverters - Fig. S6c
    opt.groups = 3;
    opt.use_cov = 2;
    opt.add_inter = 0;
    opt.use_site = 1;
    opt.use_ap = 0;
    opt.use_symp = 0;
    opt.exclude_ap = 0;
    napls2_mmn_peb(opt);
end

%% Run simulations

if opt.simulations
    napls2_sim_grandmean(opt);
end