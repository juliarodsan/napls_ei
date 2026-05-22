function fh = plot_peb(PEB, options)
%--------------------------------------------------------------------------
% IN:
%  PEB - PEB model to plot
%  options - structure of options for plotting
% 
% OUT:
%  fh - plot handle
%--------------------------------------------------------------------------

%% Set defaults
if ~isfield(options, 'visibility')
    options.visibility = 'on';
end

if ~isfield(options, 'barcolor')
    options.barcolor = [.7 .7 .7];
end

if ~isfield(options, 'barwidth')
    options.barwidth = 0.8;
end

%% Parameter labels
[Ep, Cp, names] = get_peb_parameters(PEB);

%% Plot
if ~isfield(options, 'fh')
    scrsz = get(0,'ScreenSize');
    fh = figure('units','normalized','outerposition',[0 0 0.48 0.9],'Visible',options.visibility);
else
    fh = options.fh;
end

% Plot
set(0,'defaultTextInterpreter','none');
set(0,'defaultAxesTickLabelInterpreter','tex');
set(0,'DefaultFigureColor',[1 1 1]);
set(0,'DefaultAxesFontSize',29);
set(0,'DefaultAxesFontWeight','normal');
set(0,'DefaultAxesFontName','Calibri');

hold on

% Plot Ep
bar(Ep, options.barwidth, 'FaceColor', options.barcolor, 'EdgeColor', [0 0 0], 'LineWidth', 2.5);
hold on

% Compute confidence intervals
ci95 = spm_invNcdf(1 - 0.05);
ci99 = spm_invNcdf(1 - 0.01);
c95 = ci95*sqrt(Cp);
c99 = ci99*sqrt(Cp);

% Plot error bars
errorbar(1:numel(Ep),Ep,c95,'LineStyle','none','Color','k',...
    'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0 0 0],'LineWidth',2.5);

% Plot significance
ylims = [min(Ep-c95)-0.03 max(Ep+c95)+0.03];
yrange = range(ylims);
ylim([ylims(1)-0.01*yrange ylims(2)+0.08*yrange])
y = ylims(2)+0.01*yrange;
txt = repmat({''}, size(Ep));
txt(abs(Ep)> c95) = {'*'};
txt(abs(Ep)> c99) = {'**'};
text(1:numel(Ep), repmat(y, size(Ep)), txt, 'FontSize', 42, 'HorizontalAlignment', 'center')

% Label axes
xlim([0 numel(Ep)+0.5])
xticks(1:numel(names))
xticklabels(names); xtickangle(45);
yline(0, 'k', 'LineWidth', 1.5); 
set(gca, 'XColor', 'k', 'YColor', 'k', 'Layer', 'top');
ax = gca; ax.XAxis.LineWidth = 1.5; ax.YAxis.LineWidth = 1.5;
ylabel('Effect'); xlabel('Parameter')
xticks(1:numel(options.param))
if isequal(options.param,{'B_g_ee', 'B_g_ii'}); options.param = {'B^{g_{ee}}','B^{g_{ii}}'}; end
xticklabels(options.param); xtickangle(0);

% Adjust lines
yline(0, 'k', 'LineWidth', 2.5); 
allAxes = findall(fh, 'Type', 'axes');
for k = 1:length(allAxes)
    ax = allAxes(k);
    ax.XAxis.LineWidth = 2.5;
    ax.YAxis.LineWidth = 2.5;
    set(ax, 'XColor', 'k', 'YColor', 'k', 'Layer', 'top');
end

% Add title
title(options.title);

end