%% Demographics Table 1

function napls2_demographics_tbl1(opt)

%% Set paths
psubjects_mmn = fullfile(opt.pmain, 'MMN_preprocessed_Hamilton', 'subjects');
psubjects_p3  = fullfile(opt.pmain, 'P300_preprocessed_Hamilton_v2', 'subjects', 'filtered');
fdemo         = fullfile(opt.pmain, 'Demographics', 'NAPLS-2 MMN FINAL DATABASE March 2022.csv');
fsops         = fullfile(opt.pmain, 'Demographics', 'P300 Database April 2021 share.csv');
fp3           = fullfile(opt.pmain, 'Demographics', 'NAPLS-2 AOD FINAL DATABASE June 2024_JRS.csv');

%% Identify all subjects
temp = dir(fullfile(psubjects_mmn,'NAPLS*.mat'));
mmn_subjects = {temp.name}';
clear temp

temp = dir(fullfile(psubjects_p3,'f*.mat'));
p3_subjects = {temp.name}';
clear temp

%% Load data
data_all = readtable(fdemo);
data_conv = data_all(data_all.FinalCCSGroup == 1, :);
data_rem = data_all(data_all.FinalCCSGroup == 3, :);

data_conv(:, contains(data_conv.Properties.VariableNames, 'Latency')) = [];
data_conv(:, contains(data_conv.Properties.VariableNames, 'Area')) = [];

data_rem(:, contains(data_rem.Properties.VariableNames, 'Latency')) = [];
data_rem(:, contains(data_rem.Properties.VariableNames, 'Area')) = [];

opts = detectImportOptions(fsops);
opts.SelectedVariableNames = {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup', ...
    'cSOPSPositive', 'cSOPSNegative', 'cSOPSDisorganization', 'cSOPSGeneral'};
opts = setvartype(opts, {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup', ...
    'cSOPSPositive', 'cSOPSNegative', 'cSOPSDisorganization', 'cSOPSGeneral'}, 'double');
sops_all = readtable(fsops, opts);

% Merge tables
data_conv = outerjoin(data_conv, sops_all, 'Keys', {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup'}, 'Type', 'left', 'MergeKeys', true);
data_rem = outerjoin(data_rem, sops_all, 'Keys', {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup'}, 'Type', 'left', 'MergeKeys', true);

%% Get P300 age
opts = detectImportOptions(fp3);
opts.SelectedVariableNames = {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup', ...
    'EEGage'};
opts = setvartype(opts, {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup', ...
    'EEGage'}, 'double');
fp3_age = readtable(fp3, opts);

% Merge tables
data_conv = outerjoin(data_conv, fp3_age, 'Keys', {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup'}, 'Type', 'left', 'MergeKeys', true);
data_rem = outerjoin(data_rem, fp3_age, 'Keys', {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup'}, 'Type', 'left', 'MergeKeys', true);

% Rename
data_conv.EEGage = data_conv.EEGage_data_conv;
data_conv.EEGage_data_conv = [];

data_rem.EEGage = data_rem.EEGage_data_rem;
data_rem.EEGage_data_rem = [];

%% Check data availability

for i = 1:height(data_conv)
    id = sprintf('%02d-%04d', data_conv.SiteNumber(i), data_conv.SubjectNumber(i));
    if ~isempty(find(contains(mmn_subjects,id),1)); data_conv.MMNdata(i) = 1;
    else data_conv.MMNdata(i) = 0; end
    if ~isempty(find(contains(p3_subjects,id),1)); data_conv.P300data(i) = 1;
    else data_conv.P300data(i) = 0; end
end

for i = 1:height(data_rem)
    id = sprintf('%02d-%04d', data_rem.SiteNumber(i), data_rem.SubjectNumber(i));
    if ~isempty(find(contains(mmn_subjects,id),1)); data_rem.MMNdata(i) = 1;
    else data_rem.MMNdata(i) = 0; end
    if ~isempty(find(contains(p3_subjects,id),1)); data_rem.P300data(i) = 1;
    else data_rem.P300data(i) = 0; end
end

%% Do stats
group_labels = [zeros(1, size(data_rem,1)), ones(1, size(data_conv,1))]; % 0 for REM, 1 for CONV

[~, p_age, ~, stats_age] = ttest2(data_conv.EEGage, data_rem.EEGage);
[~, p_age_p3, ~, stats_age_p3] = ttest2(data_conv.EEGage_fp3_age, data_rem.EEGage_fp3_age);
[~, p_pos, ~, stats_pos] = ttest2(data_conv.cSOPSPositive, data_rem.cSOPSPositive);
[~, p_neg, ~, stats_neg] = ttest2(data_conv.cSOPSNegative, data_rem.cSOPSNegative);
[~, p_dis, ~, stats_dis] = ttest2(data_conv.cSOPSDisorganization, data_rem.cSOPSDisorganization);
[~, p_gen, ~, stats_gen] = ttest2(data_conv.cSOPSGeneral, data_rem.cSOPSGeneral);

sex_labels_num = [data_rem.Sex; data_conv.Sex];
sex_labels = categorical(sex_labels_num, [1 2], {'Male', 'Female'});
[~, chi2stat_sex, p_sex] = crosstab(group_labels, sex_labels);

ap_status_rem = repmat({'noAP'}, height(data_rem), 1);
ap_status_rem(isnan(data_rem.GroupNOAP)) = {'AP'};
ap_status_conv = repmat({'noAP'}, height(data_conv), 1);
ap_status_conv(isnan(data_conv.GroupNOAP)) = {'AP'};
ap_labels = [ap_status_rem; ap_status_conv];
[~, chi2stat_ap, p_ap] = crosstab(group_labels, ap_labels);

aps_labels_num = [data_rem.APS; data_conv.APS];
aps_labels = categorical(aps_labels_num, [0 1], {'noAPS', 'APS'});
[~, chi2stat_aps, p_aps] = crosstab(group_labels, aps_labels);

grd_labels_num = [data_rem.GRD; data_conv.GRD];
grd_labels = categorical(grd_labels_num, [0 1], {'noGRD', 'GRD'});
[~, chi2stat_grd, p_grd] = crosstab(group_labels, grd_labels);

bips_labels_num = [data_rem.BIPS; data_conv.BIPS];
bips_labels = categorical(bips_labels_num, [0 1], {'noBIPS', 'BIPS'});
[~, chi2stat_bips, p_bips] = crosstab(group_labels, bips_labels);

mmn_labels_num = [data_rem.MMNdata; data_conv.MMNdata];
mmn_labels = categorical(mmn_labels_num, [0 1], {'noMMN', 'MMN'});
[~, chi2stat_mmn, p_mmn] = crosstab(group_labels, mmn_labels);

p3_labels_num = [data_rem.P300data; data_conv.P300data];
p3_labels = categorical(p3_labels_num, [0 1], {'noP3', 'P3'});
[~, chi2stat_p3, p_p3] = crosstab(group_labels, p3_labels);

%% Display the results
fprintf('\n%-35s %-25s %-25s %-30s\n', 'Demographic', ...
    sprintf('CHR-Converter (n=%d)', height(data_conv)), ...
    sprintf('CHR-Remitter (n=%d)', height(data_rem)), ...
    'Statistical analysis');
fprintf('%s\n', repmat('-', 1, 115));

% Continuous variables
conv_age_mmn = data_conv.EEGage;       rem_age_mmn = data_rem.EEGage;
conv_age_p3  = data_conv.EEGage_fp3_age; rem_age_p3  = data_rem.EEGage_fp3_age;

fprintf('%-35s %-25s %-25s %-30s\n', 'Age MMN [mean (SD)]', ...
    sprintf('%d (%.1f)', round(mean(conv_age_mmn,'omitnan')), std(conv_age_mmn,'omitnan')), ...
    sprintf('%d (%.1f)', round(mean(rem_age_mmn,'omitnan')),  std(rem_age_mmn,'omitnan')), ...
    sprintf('t(%.0f)=%.2f, p=%.3f', stats_age.df, stats_age.tstat, p_age));

fprintf('%-35s %-25s %-25s %-30s\n', 'Age P300 [mean (SD)]', ...
    sprintf('%.1f (%.1f)', mean(conv_age_p3,'omitnan'), std(conv_age_p3,'omitnan')), ...
    sprintf('%.1f (%.1f)', mean(rem_age_p3,'omitnan'),  std(rem_age_p3,'omitnan')), ...
    sprintf('t(%.0f)=%.2f, p=%.3f', stats_age_p3.df, stats_age_p3.tstat, p_age_p3));

% Categorical variables
n_conv = height(data_conv); n_rem = height(data_rem);
conv_female = sum(data_conv.Sex == 2); rem_female = sum(data_rem.Sex == 2);
conv_ap = sum(~isnan(data_conv.GroupNOAP)); rem_ap = sum(~isnan(data_rem.GroupNOAP));

fprintf('%-35s %-25s %-25s %-30s\n', 'Female [n (%)]', ...
    sprintf('%d (%.1f%%)', conv_female, 100*conv_female/n_conv), ...
    sprintf('%d (%.1f%%)', rem_female,  100*rem_female/n_rem), ...
    sprintf('X2(1)=%.2f, p=%.3f', chi2stat_sex, p_sex));

fprintf('%-35s %-25s %-25s %-30s\n', 'APSS [n (%)]', ...
    sprintf('%d (%.1f%%)', sum(data_conv.APS==1), 100*mean(data_conv.APS==1)), ...
    sprintf('%d (%.1f%%)', sum(data_rem.APS==1),  100*mean(data_rem.APS==1)), ...
    sprintf('X2(1)=%.2f, p=%.3f', chi2stat_aps, p_aps));

fprintf('%-35s %-25s %-25s %-30s\n', 'BIPS [n (%)]', ...
    sprintf('%d (%.1f%%)', sum(data_conv.BIPS==1), 100*mean(data_conv.BIPS==1)), ...
    sprintf('%d (%.1f%%)', sum(data_rem.BIPS==1),  100*mean(data_rem.BIPS==1)), ...
    sprintf('X2(1)=%.2f, p=%.3f', chi2stat_bips, p_bips));

fprintf('%-35s %-25s %-25s %-30s\n', 'GRDS [n (%)]', ...
    sprintf('%d (%.1f%%)', sum(data_conv.GRD==1), 100*mean(data_conv.GRD==1)), ...
    sprintf('%d (%.1f%%)', sum(data_rem.GRD==1),  100*mean(data_rem.GRD==1)), ...
    sprintf('X2(1)=%.2f, p=%.3f', chi2stat_grd, p_grd));

fprintf('%-35s %-25s %-25s %-30s\n', 'Antipsychotic use [n (%)]', ...
    sprintf('%d (%.1f%%)', conv_ap, 100*conv_ap/n_conv), ...
    sprintf('%d (%.1f%%)', rem_ap,  100*rem_ap/n_rem), ...
    sprintf('X2(1)=%.2f, p=%.3f', chi2stat_ap, p_ap));

% SOPS
fprintf('%-35s %-25s %-25s %-30s\n', 'SOPS Positive [mean (SD)]', ...
    sprintf('%.1f (%.1f)', mean(data_conv.cSOPSPositive,'omitnan'), std(data_conv.cSOPSPositive,'omitnan')), ...
    sprintf('%.1f (%.1f)', mean(data_rem.cSOPSPositive,'omitnan'),  std(data_rem.cSOPSPositive,'omitnan')), ...
    sprintf('t(%.0f)=%.2f, p=%.3f', stats_pos.df, stats_pos.tstat, p_pos));

fprintf('%-35s %-25s %-25s %-30s\n', 'SOPS Negative [mean (SD)]', ...
    sprintf('%.1f (%.1f)', mean(data_conv.cSOPSNegative,'omitnan'), std(data_conv.cSOPSNegative,'omitnan')), ...
    sprintf('%.1f (%.1f)', mean(data_rem.cSOPSNegative,'omitnan'),  std(data_rem.cSOPSNegative,'omitnan')), ...
    sprintf('t(%.0f)=%.2f, p=%.3f', stats_neg.df, stats_neg.tstat, p_neg));

fprintf('%-35s %-25s %-25s %-30s\n', 'SOPS Disorganization [mean (SD)]', ...
    sprintf('%.1f (%.1f)', mean(data_conv.cSOPSDisorganization,'omitnan'), std(data_conv.cSOPSDisorganization,'omitnan')), ...
    sprintf('%.1f (%.1f)', mean(data_rem.cSOPSDisorganization,'omitnan'),  std(data_rem.cSOPSDisorganization,'omitnan')), ...
    sprintf('t(%.0f)=%.2f, p=%.3f', stats_dis.df, stats_dis.tstat, p_dis));

fprintf('%-35s %-25s %-25s %-30s\n', 'SOPS General [mean (SD)]', ...
    sprintf('%.1f (%.1f)', mean(data_conv.cSOPSGeneral,'omitnan'), std(data_conv.cSOPSGeneral,'omitnan')), ...
    sprintf('%.1f (%.1f)', mean(data_rem.cSOPSGeneral,'omitnan'),  std(data_rem.cSOPSGeneral,'omitnan')), ...
    sprintf('t(%.0f)=%.2f, p=%.3f', stats_gen.df, stats_gen.tstat, p_gen));

% Available data
fprintf('%-35s %-25s %-25s %-30s\n', 'MMN data [n (%)]', ...
    sprintf('%d (%.1f%%)', sum(data_conv.MMNdata), 100*mean(data_conv.MMNdata)), ...
    sprintf('%d (%.1f%%)', sum(data_rem.MMNdata),  100*mean(data_rem.MMNdata)), ...
    sprintf('X2(1)=%.2f, p=%.3f', chi2stat_mmn, p_mmn));

fprintf('%-35s %-25s %-25s %-30s\n', 'P300 data [n (%)]', ...
    sprintf('%d (%.1f%%)', sum(data_conv.P300data), 100*mean(data_conv.P300data)), ...
    sprintf('%d (%.1f%%)', sum(data_rem.P300data),  100*mean(data_rem.P300data)), ...
    sprintf('X2(1)=%.2f, p=%.3f', chi2stat_p3, p_p3));
end