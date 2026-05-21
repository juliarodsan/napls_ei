%% Run and plot sensor-level analysis for MMN task

function napls2_sensor_p300(opt)

%% Load subject data
[~, ~, subj_sheet] = xlsread(opt.fsubjects);
subj_sheet(:,2:3) = []; % Remove columns with site and subject IDs - column 1 contains this already in the format siteID-subjID

%% Get SPM files
temp = dir(fullfile(opt.psubjects,'filtered','f15*.mat'));
if isempty(temp); error('No SPM files found! Please convert data to SPM format.'); end
spm_subjects = {temp.name}';
clear temp

%% Run
% Start counts
conv = 0; remit = 0; bad = 0; bad_subj = {};

% Initialise
CONV_std = [];
CONV_tgt = [];
REMIT_std = [];
REMIT_tgt = [];

for s = 1:numel(spm_subjects)
    try
        % Get subject ID
        id = extractBetween(spm_subjects{s}, 'NAPLS-', '-1');
        id = id{:};
        
        % Find diagnosis in final subject sheet
        subj_row = find(strcmp(subj_sheet(:,1), id));
        group = subj_sheet{subj_row,7};
        
        % Skip if not CHR-Converter or CHR-Remitter
        if ~ismember(group, [1 3])
            continue
        end
        
        % Load file and get data
        D = spm_eeg_load(fullfile(opt.psubjects, 'filtered', spm_subjects{s}));
        
        % Get trial indices
        std_id = D.indtrial('standard');
        tgt_id = D.indtrial('target');
        
        % Get channel index
        Pz_id = D.indchannel('Pz');
        
        % Get data for CHR-Converters and CHR-Remitters
        if group == 1
            conv = conv + 1;
            CONV_std(conv,:) = squeeze(D(Pz_id,:,std_id));
            CONV_tgt(conv,:) = squeeze(D(Pz_id,:,tgt_id));
        elseif group == 3
            remit = remit + 1;
            REMIT_std(remit,:) = squeeze(D(Pz_id,:,std_id));
            REMIT_tgt(remit,:) = squeeze(D(Pz_id,:,tgt_id));
        end
    catch
        bad = bad + 1;
        bad_subj{bad,1} = id;
        disp(['Error for subject: #', id])
    end
end

fprintf('Total CHR-Converters: %d\n', conv);
fprintf('Total CHR-Remitters:  %d\n', remit);
fprintf('Total errors:         %d\n', bad);

%% Calculate P300 amplitude (target) at 235-400 ms
D = spm_eeg_load(fullfile(opt.psubjects, 'filtered', spm_subjects{1}));

time_win = nearest(D.time, 0.235) : nearest(D.time, 0.4);
p300_CONV = squeeze(CONV_tgt-CONV_std);
p300_REMIT = squeeze(REMIT_tgt-REMIT_std);
mean_CONV  = mean(p300_CONV(:,time_win), 2);
mean_REMIT = mean(p300_REMIT(:,time_win), 2);

% t-test
[~, p_p300_conv_remit, ~, stats_p300_conv_remit] = ttest2(mean_CONV, mean_REMIT);

fprintf('\nCHR-Converters vs CHR-Remitters:\n');
fprintf('    t(%d) = %.3f\n', stats_p300_conv_remit.df, stats_p300_conv_remit.tstat);
fprintf('    p = %.3f\n', p_p300_conv_remit);

% Run t-test per time point
for t = 1:length(D.time)
    [~, p_conv_remit(t)] = ttest2(REMIT_tgt(:,t)-REMIT_std(:,t), CONV_tgt(:,t)-CONV_std(:,t));
end
sig_conv_remit = D.time(p_conv_remit < 0.05);

%% Plot
color_REM = [0, 0.4, 0]; % dark green
color_CONV = [0.6, 0.8, 0.2]; % light green

fh = figure('units','normalized','outerposition',[0 0 0.34 0.5],'Visible',opt.vis_plots);

set(fh,'defaultTextInterpreter','none');
set(fh,'defaultAxesTickLabelInterpreter','none');
set(fh,'DefaultAxesFontSize',14);
set(fh,'DefaultTextFontSize',14);
set(fh,'DefaultAxesFontWeight','normal');

p1 = stdshade(D.time, REMIT_tgt-REMIT_std, 0.1, color_REM);
hold on;
p2 = stdshade(D.time, CONV_tgt-CONV_std, 0.1, color_CONV);
plot(sig_conv_remit, -1*ones(size(sig_conv_remit)), 'k.', 'MarkerSize', 20);
xlim([0 0.9]); ylim([-2 10]); xline(0.235,'linewidth',2); xline(0.4,'linewidth',2);
legend([p1(1),p2(1)],'CHR-Remitter','CHR-Converter','FontSize', 14, 'Location', 'EastOutside');
xlabel('Time (s)'); ylabel('');
title({'P300','(target-standard)'},'FontSize', 16)

box off
allAxes = findall(fh, 'Type', 'axes');
for k = 1:length(allAxes)
    ax = allAxes(k);
    ax.XAxis.LineWidth = 1.5;
    ax.YAxis.LineWidth = 1.5;
    set(ax, 'XColor', 'k', 'YColor', 'k', 'Layer', 'top');
end

saveas(fh, fullfile(opt.pfigures, 'fig_1b_p300.svg'));
saveas(fh, fullfile(opt.pfigures, 'fig_1b_p300.fig'));
end