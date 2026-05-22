%% Test sensitivity to prior specification

function napls2_sim_sensitivity(opt)

%% Define paths
switch opt.task
    case 'MMN'
        opt.truth = {fullfile(opt.pmean, 'mmn_grandmean_all.mat')};
    case 'P300'
        opt.truth = {fullfile(opt.pmean, 'filtered', 'p300_grandmean_all_f15.mat')};
end

% Find DCMs (run using napls2_*_fit_dcm_to_grandmean.m with different priors)
psims   = fullfile(opt.presults, 'dcm_ei', 'simulations_sensitivity');
all_dcm = dir(fullfile(psims, '*/*/dcm/dcm*.mat'));
fnames  = fullfile({all_dcm.folder}, {all_dcm.name}); clear temp

cd(psims)

%% Run and plot simulations

% Simulation options
% opt = struct();
opt.noise = 'nn';
opt.mode  = 'abs';
opt.est   = 1; % simulate from estimated parameters only

% Plotting options
switch opt.task
    case 'MMN'
        opt.chan = {'F3','Fz','F4','C3','Cz','C4'}; % for MMN
    case 'P300'
        opt.chan = 'Pz'; % for P300
end

for i = 1:numel(fnames)
    opt.dcm = fnames{i};
    
    % Update Dfile
    load(opt.dcm)
    DCM.xY.Dfile = opt.truth{:}; save(opt.dcm,'DCM');

    % Simulate from condition-specific parameters
    % SP-SP
    opt.vals = linspace(-0.5, 0.5, 9);
    field = getfield(DCM.Ep,'B_g_ee'); temp = 1;
    p = struct(); p = setfield(p,'B_g_ee',temp);
    sDCM = sim_dcm(opt.dcm, p, opt);
    opt.title = '';
    opt.legend_sim = arrayfun(@num2str, opt.vals , 'UniformOutput', false); opt.legend_sim{opt.vals==0} = 'Ep';
    fh = plot_sim_dcms_napls(sDCM,opt);
    if iscell(opt.chan); save_name = sprintf('%s_%s', opt.chan{1}, string(fieldnames(p)));
    else; save_name = sprintf('%s_%s', opt.chan, string(fieldnames(p))); end
    [~,pre_name] = fileparts(fileparts(fileparts(fileparts(fnames{i}))));
    saveas(fh, fullfile(opt.pfigures, [pre_name '_' save_name '.svg']));
    saveas(fh, fullfile(opt.pfigures, [pre_name '_' save_name '.fig']));

    % II-II
    opt.vals = linspace(-0.5, 0.5, 9);
    field = getfield(DCM.Ep,'B_g_ii'); temp = 1;
    p = struct(); p = setfield(p,'B_g_ii',temp);
    sDCM = sim_dcm(opt.dcm, p, opt);
    opt.title = '';
    opt.legend_sim = arrayfun(@num2str, opt.vals , 'UniformOutput', false); opt.legend_sim{opt.vals==0} = 'Ep';
    fh = plot_sim_dcms_napls(sDCM,opt);
    if iscell(opt.chan); save_name = sprintf('%s_%s', opt.chan{1}, string(fieldnames(p)));
    else; save_name = sprintf('%s_%s', opt.chan, string(fieldnames(p))); end
    [~,pre_name] = fileparts(fileparts(fileparts(fileparts(fnames{i}))));
    saveas(fh, fullfile(opt.pfigures, [pre_name '_' save_name '.svg']));
    saveas(fh, fullfile(opt.pfigures, [pre_name '_' save_name '.fig']));
end
end
