function fh = plot_sim_dcms_napls(sDCM, opt)

%% Defaults
if ~isfield(opt, 'visibility'); opt.visibility = 'on'; end
if ~isfield(opt, 'task'); opt.task = 'P300'; end
if ~isfield(opt, 'chan'); opt.chan = 'Pz'; end

%% Get comparison data either from DCM or from opt.truth
% Get meta data
load(opt.dcm);
D = spm_eeg_load(DCM.xY.Dfile);

n_conds = 2;
t_DCM = DCM.xY.pst';

if iscell(opt.chan)
    for i = 1:numel(opt.chan)
        idx_chan(i) = find(strcmp(chanlabels(D), opt.chan{i}));
    end
    % unit = char(units(D, idx_chan(1)));
else
    idx_chan = find(strcmp(chanlabels(D), opt.chan));
    % unit = char(units(D, idx_chan));
end

%% Get simulated responses from DCM
for i = 1:numel(sDCM)
    for c = 1:n_conds
        y_sim(:,i,c) = mean(sDCM{i}.xY.y{c}(:,idx_chan),2);
    end
end

%% Plot
% Color options
warm_cols = flipud(autumn(sum(opt.vals>0)));
cold_cols = winter(sum(opt.vals<0));
colors_sim = [cold_cols; [0 0 0]; warm_cols];

fh = figure('units','normalized','outerposition',[0 0 0.8 0.6],'visible',opt.visibility);

% Figure settings
set(fh,'defaultLegendInterpreter','tex');
set(fh,'DefaultAxesFontSize',16);
set(fh,'DefaultAxesFontName','Calibri');
set(fh,'DefaultAxesFontWeight','normal');

ax1 = subplot(1,3,1);
for i = 1:numel(sDCM)
    plot(t_DCM/1000,y_sim(:,i,1),'Color',colors_sim(i,:),'LineWidth',1.5); hold on
end
title('Standard');
xlabel('Time (s)');
if iscell(opt.chan)
    ylabel(sprintf('Frontocentral'));
else
    ylabel(sprintf('%s',opt.chan));
end

ax2 = subplot(1,3,2);
for i = 1:numel(sDCM)
    plot(t_DCM/1000,y_sim(:,i,2),'Color',colors_sim(i,:),'LineWidth',1.5); hold on
end
switch opt.task
    case 'MMN'
        title('Deviant');
    case 'P300'
        title('Target');
end
xlabel('Time (s)');
yticks([])

ax3 = subplot(1,3,3);
for i = 1:numel(sDCM)
    plot(t_DCM/1000,(y_sim(:,i,2)-y_sim(:,i,1)),'Color',colors_sim(i,:),'LineWidth',1.5); hold on
end
title('Difference');
xlabel('Time (s)');
yticks([])

if isfield(opt, 'legend_sim'); lg=legend(opt.legend_sim,'Location','eastoutside','FontSize',16); end
if isfield(opt, 'legend_sim_title'); title(lg,opt.legend_sim_title,'FontSize',16); end
    
set(gca, 'XColor', 'k', 'YColor', 'k', 'Layer', 'top');
linkaxes([ax1 ax2 ax3],'xy');
xlim([min(t_DCM/1000) max(t_DCM/1000)]);
switch opt.task
    case 'MMN'
        ylim([-40 20])
    case 'P300'
        ylim([-25 30])
end

set(ax1, 'Position', [0.08 0.2 0.26 0.7]);
set(ax2, 'Position', [0.36 0.2 0.26 0.7]);
set(ax3, 'Position', [0.64 0.2 0.26 0.7]);

allAxes = findall(fh, 'Type', 'axes');
for k = 1:length(allAxes)
    ax = allAxes(k);
    ax.XAxis.LineWidth = 1.5;
    ax.YAxis.LineWidth = 1.5;
    set(ax, 'XColor', 'k', 'YColor', 'k', 'Layer', 'top');
end
end
