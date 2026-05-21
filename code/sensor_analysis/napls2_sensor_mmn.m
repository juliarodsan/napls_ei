%% Run and plot sensor-level analysis for MMN task

function napls2_sensor_mmn(opt)

%% Load subject data
[~, ~, subj_sheet] = xlsread(opt.fsubjects);
subj_sheet(:,2:3) = []; % Remove columns with site and subject IDs - column 1 contains this already in the format siteID-subjID

%% Get SPM files
temp = dir(fullfile(opt.psubjects,'Mp*.mat'));
if isempty(temp); error('No SPM files found! Please convert data to SPM format.'); end
spm_subjects = {temp.name}';
clear temp

%% Run
% Start counts
conv = 0; remit = 0; bad = 0; bad_subj = {};

% Specify channels for analysis
channels = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4'};

% Determine variable prefix based on the number of channels
if numel(channels) == 1
    var_prefix = channels{1};  % Use the channel name if only one channel
else
    var_prefix = 'frontocentral';  % Use for multiple frontocentral channels
end

% Initialise storage for averaged data
eval([var_prefix, '_CONV_std = [];']);
eval([var_prefix, '_CONV_dbl = [];']);
eval([var_prefix, '_REMIT_std = [];']);
eval([var_prefix, '_REMIT_dbl = [];']);

for s = 1:numel(spm_subjects)
    try
        % Get subject ID
        id = extractBetween(spm_subjects{s}, 'NAPLS-', '-1');
        id = id{:};
        
        % Find diagnosis in final subject sheet
        subj_row = find(strcmp(subj_sheet(:,1), id));
        group = subj_sheet{subj_row,10};
        
        % Skip if not CHR-Converter or CHR-Remitter
        if ~ismember(group, [1 3])
            continue
        end
        
        % Load file and get data
        D = spm_eeg_load(fullfile(opt.psubjects, spm_subjects{s}));
        
        % Get trial indices
        std_id = D.indtrial('standard');
        dbl_id = D.indtrial('double deviant');
        
        % Initialise
        subj_std = zeros(length(std_id), size(D,2));
        subj_dbl = zeros(length(dbl_id), size(D,2));
        
        for ch = 1:length(channels)
            channel_name = channels{ch};
            channel_id = D.indchannel(channel_name);
            
            % Accumulate data across channels
            subj_std = subj_std + squeeze(D(channel_id,:,std_id));
            subj_dbl = subj_dbl + squeeze(D(channel_id,:,dbl_id));
        end
        
        % Average across channels
        subj_std = subj_std / length(channels);
        subj_dbl = subj_dbl / length(channels);
        
        % Store data for CHR-Converters and CHR-Remitters
        if group == 1
            conv = conv + 1;
            eval([var_prefix, '_CONV_std(conv,:) = subj_std;']);
            eval([var_prefix, '_CONV_dbl(conv,:) = subj_dbl;']);
        elseif group == 3
            remit = remit + 1;
            eval([var_prefix, '_REMIT_std(remit,:) = subj_std;']);
            eval([var_prefix, '_REMIT_dbl(remit,:) = subj_dbl;']);
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

%% Calculate MMN amplitude (double-deviant) at 90-170 ms
D = spm_eeg_load(fullfile(opt.psubjects, spm_subjects{1}));

time_win = nearest(D.time, 0.09) : nearest(D.time, 0.17);
mmn_CONV  = eval([var_prefix,'_CONV_dbl'])-eval([var_prefix,'_CONV_std']);
mmn_REMIT = eval([var_prefix,'_REMIT_dbl'])-eval([var_prefix,'_REMIT_std']);
mean_CONV  = mean(mmn_CONV(:,time_win), 2);
mean_REMIT = mean(mmn_REMIT(:,time_win), 2);

% t-test
[~, p_mmn_conv_remit, ~, stats_mmn_conv_remit] = ttest2(mean_REMIT,mean_CONV);

fprintf('\nCHR-Converters vs CHR-Remitters:\n');
fprintf('    t(%d) = %.3f\n', stats_mmn_conv_remit.df, stats_mmn_conv_remit.tstat);
fprintf('    p = %.3f\n', p_mmn_conv_remit);

% Run t-test per time point
REMIT_dbl = eval([var_prefix,'_REMIT_dbl']);
REMIT_std = eval([var_prefix,'_REMIT_std']);
CONV_dbl  = eval([var_prefix,'_CONV_dbl']);
CONV_std  = eval([var_prefix,'_CONV_std']);

for t = 1:length(D.time)
    [~, p_conv_remit(t)] = ttest2(REMIT_dbl(:,t)-REMIT_std(:,t), CONV_dbl(:,t)-CONV_std(:,t));
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

p1 = stdshade(D.time, eval([var_prefix,'_REMIT_dbl']) - eval([var_prefix,'_REMIT_std']), 0.1, color_REM);
hold on;
p2 = stdshade(D.time, eval([var_prefix,'_CONV_dbl']) - eval([var_prefix,'_CONV_std']), 0.1, color_CONV);
plot(sig_conv_remit, -6*ones(size(sig_conv_remit)), 'k.', 'MarkerSize', 20);
xlim([0 0.4]); ylim([-7 3]); xline(0.09,'linewidth',2); xline(0.17,'linewidth',2);
legend([p1(1),p2(1)],'CHR-Remitter','CHR-Converter','FontSize', 14, 'Location', 'EastOutside');
xlabel('Time (s)'); ylabel('Amplitude (µV)');
title({'MMN','(double deviant-standard)'},'FontSize', 16)

box off
allAxes = findall(fh, 'Type', 'axes');
for k = 1:length(allAxes)
    ax = allAxes(k);
    ax.XAxis.LineWidth = 1.5;
    ax.YAxis.LineWidth = 1.5;
    set(ax, 'XColor', 'k', 'YColor', 'k', 'Layer', 'top');
end

saveas(fh, fullfile(opt.pfigures, 'fig_1b_mmn.svg'));
saveas(fh, fullfile(opt.pfigures, 'fig_1b_mmn.fig'));
end