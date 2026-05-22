%% Run simulations and plot

function napls2_sim_grandmean(opt)

%% Define paths
switch opt.task
    case 'MMN'
        opt.psim  = fullfile(opt.presults, 'dcm_ei', 'mmn_grandmean_all_simulations_v11');
        opt.dcm   = fullfile(opt.psim, 'napls_dcm_mmn_grandmean_all_cmc_ei_v1_vbsv898_ei.mat');
        opt.truth = {fullfile(opt.pmean, 'mmn_grandmean_all.mat')};
    case 'P300'
        opt.psim  = fullfile(opt.presults, 'dcm_ei', 'p300_grandmean_all_simulations_v17');
        opt.dcm   = fullfile(opt.psim, 'napls_dcm_p300_grandmean_all_cmc_ei_v1_vbsv1753_ei.mat');
        opt.truth = {fullfile(opt.pmean, 'filtered', 'p300_grandmean_all_f15.mat')};
end

% Make results directory
if ~isequal(exist(opt.psim,'dir'),7); mkdir(opt.psim); end
cd(opt.pfigures)

%% Run and plot simulations

% Simulation options
opt.noise = 'nn';
opt.mode  = 'abs';
opt.est   = 1; % simulate from estimated parameters only

% Plotting options
switch opt.task
    case 'MMN'
        opt.chan = {'F3','Fz','F4','C3','Cz','C4'};
    case 'P300'
        opt.chan = 'Pz';
end
opt.visibility       = 'on';

%-------------------------------------------
% 4-population convolution-based model (CMC)
%-------------------------------------------
% Update Dfile
if ~isfile(opt.dcm)
    [~, fname, ext] = fileparts(opt.dcm);
    copyfile(fullfile(opt.presults, 'dcm_ei', 'priors', [fname ext]), opt.psim);
end
load(opt.dcm)
DCM.xY.Dfile = opt.truth{:}; save(opt.dcm,'DCM');

% Simulate from B_g_ee
opt.vals = linspace(-0.5, 0.5, 9);
field = getfield(DCM.Ep,'B_g_ee'); temp = 1;
p = struct(); p = setfield(p,'B_g_ee',temp);
sDCM = sim_dcm(opt.dcm, p, opt);
opt.legend_sim = arrayfun(@num2str, opt.vals , 'UniformOutput', false); opt.legend_sim{opt.vals==0} = 'Ep';
opt.legend_sim_title = 'B^{g_{ee}}';
fh = plot_sim_dcms_napls(sDCM,opt);
if iscell(opt.chan); save_name = sprintf('fig3_%s_%s', 'frontocentral', string(fieldnames(p)));
else; save_name = sprintf('fig3_%s_%s', opt.chan, string(fieldnames(p))); end
saveas(fh, fullfile(opt.pfigures, [save_name '.svg']));

% Simulate from B_g_ii
opt.vals = linspace(-0.5, 0.5, 9);
field = getfield(DCM.Ep,'B_g_ii'); temp = 1;
p = struct(); p = setfield(p,'B_g_ii',temp);
sDCM = sim_dcm(opt.dcm, p, opt);
opt.legend_sim = arrayfun(@num2str, opt.vals ,'UniformOutput', false); opt.legend_sim{opt.vals==0} = 'Ep';
opt.legend_sim_title = 'B^{g_{ii}}';
fh = plot_sim_dcms_napls(sDCM,opt);
if iscell(opt.chan); save_name = sprintf('fig3_%s_%s', 'frontocentral', string(fieldnames(p)));
else; save_name = sprintf('fig3_%s_%s', opt.chan, string(fieldnames(p))); end
saveas(fh, fullfile(opt.pfigures, [save_name '.svg']));
end