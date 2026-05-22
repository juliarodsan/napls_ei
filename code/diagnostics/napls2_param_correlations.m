%% Plot parameter correlations

function napls2_param_correlations(opt)

%% Options
switch opt.task
    case 'MMN'
        dcm_version = 14; % DCM version to use
        pdcm = fullfile(opt.presults, 'dcm_ei', ['mmn_all_subjects_v', num2str(dcm_version)]);
    case 'P300'
        dcm_version = 21; % DCM version to use
        pdcm = fullfile(opt.pdresults, 'dcm_ei', ['p300_all_subjects_v', num2str(dcm_version)]);
end

%% Plot
which_params = [309 310];
param_names = {'B^{g_{ee}}', 'B^{g_{ii}}'};

napls2_pident_correlation_matrix(pdcm, opt.pfigures, which_params, param_names, opt.vis_plots)
title(opt.task)
saveas(gcf, fullfile(opt.pfigures,sprintf('fig_s1_%s_param_identifiability.png',lower(opt.task))))
saveas(gcf, fullfile(opt.pfigures,sprintf('fig_s1_%s_param_identifiability.svg',lower(opt.task))))
saveas(gcf, fullfile(opt.pfigures,sprintf('fig_s1_%s_param_identifiability.fig',lower(opt.task))))