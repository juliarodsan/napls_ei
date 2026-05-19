%% Demographics Tables S1 and S2

function napls2_demographics_suppl(opt)

%% Set paths
switch opt.task
    case 'MMN'
        fmatched = fullfile(opt.pmain, 'Demographics', 'MMN_HC_matched_IDs.mat');
        fdemo    = fullfile(opt.pmain, 'Demographics', 'NAPLS-2 MMN FINAL DATABASE March 2022.csv');
        fsops    = fullfile(opt.pmain, 'Demographics', 'MMN sops.csv');
    case 'P300'
        fmatched = fullfile(opt.pmain, 'Demographics', 'P300_HC_matched_IDs.mat');
        fdemo    = fullfile(opt.pmain, 'Demographics', 'NAPLS-2 AOD FINAL DATABASE June 2024.csv');
        fmmn     = fullfile(opt.pmain, 'Demographics', 'NAPLS-2 MMN FINAL DATABASE March 2022.csv');
        fsops    = fullfile(opt.pmain, 'Demographics', 'P300 Database April 2021 share.csv');
end

%% Load data
data_all = readtable(fdemo);
data_all(:, contains(data_all.Properties.VariableNames, 'Latency')) = [];
data_all(:, contains(data_all.Properties.VariableNames, 'Area')) = [];
if isequal(opt.task,'P300')
    data_all(:, contains(data_all.Properties.VariableNames, 'Peak')) = []; 
    data_all(:, contains(data_all.Properties.VariableNames, 'Pz')) = []; 
    data_all(:, contains(data_all.Properties.VariableNames, 'AOD')) = []; 
end

temp = data_all(data_all.FinalCCSGroup == 0, :); j = 1;
load(fmatched);
for i = 1:height(temp)
    id = sprintf('%02d-%04d', temp.SiteNumber(i), temp.SubjectNumber(i));
    if ~isempty(find(contains(HC_matched_IDs,id),1)); data_hc(j,:) = temp(i,:); j = j+1; end
end

data_conv = data_all(data_all.FinalCCSGroup == 1, :);
data_symp = data_all(data_all.FinalCCSGroup == 2, :);
data_rem = data_all(data_all.FinalCCSGroup == 3, :);

switch opt.task
    case 'MMN'
        % Add SOPS data
        sops_all = readtable(fsops);
        data_hc = outerjoin(data_hc, sops_all, 'Keys', {'SiteNumber', 'SubjectNumber'}, 'Type', 'left', 'MergeKeys', true);
        data_conv = outerjoin(data_conv, sops_all, 'Keys', {'SiteNumber', 'SubjectNumber'}, 'Type', 'left', 'MergeKeys', true);
        data_symp = outerjoin(data_symp, sops_all, 'Keys', {'SiteNumber', 'SubjectNumber'}, 'Type', 'left', 'MergeKeys', true);
        data_rem = outerjoin(data_rem, sops_all, 'Keys', {'SiteNumber', 'SubjectNumber'}, 'Type', 'left', 'MergeKeys', true);
    case 'P300'
        % Add SOPS data
        opts = detectImportOptions(fsops);
        opts.SelectedVariableNames = {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup', ...
            'cSOPSPositive', 'cSOPSNegative', 'cSOPSDisorganization', 'cSOPSGeneral'};
        opts = setvartype(opts, {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup', ...
            'cSOPSPositive', 'cSOPSNegative', 'cSOPSDisorganization', 'cSOPSGeneral'}, 'double');
        sops_all = readtable(fsops, opts);
        
        data_hc = outerjoin(data_hc, sops_all, 'Keys', {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup'}, 'Type', 'left', 'MergeKeys', true);
        data_conv = outerjoin(data_conv, sops_all, 'Keys', {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup'}, 'Type', 'left', 'MergeKeys', true);
        data_symp = outerjoin(data_symp, sops_all, 'Keys', {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup'}, 'Type', 'left', 'MergeKeys', true);
        data_rem = outerjoin(data_rem, sops_all, 'Keys', {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup'}, 'Type', 'left', 'MergeKeys', true);
        
        % Add sex and CHR-P data
        opts = detectImportOptions(fmmn);
        opts.SelectedVariableNames = {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup', 'Sex', 'APS', 'GRD', 'BIPS'};
        opts = setvartype(opts, {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup', 'Sex', 'APS', 'GRD', 'BIPS'}, 'double');
        mmn_all = readtable(fmmn, opts);
        
        data_hc = outerjoin(data_hc, mmn_all, 'Keys', {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup'}, 'Type', 'left', 'MergeKeys', true);
        data_conv = outerjoin(data_conv, mmn_all, 'Keys', {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup'}, 'Type', 'left', 'MergeKeys', true);
        data_symp = outerjoin(data_symp, mmn_all, 'Keys', {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup'}, 'Type', 'left', 'MergeKeys', true);
        data_rem = outerjoin(data_rem, mmn_all, 'Keys', {'SiteNumber', 'SubjectNumber', 'FinalCCSGroup'}, 'Type', 'left', 'MergeKeys', true);
        
        % Check it worked
        fprintf('Row counts after table join - HC: %d, CHR-C: %d, CHR-P: %d, CHR-R: %d\n', ...
        height(data_hc), height(data_conv), height(data_symp), height(data_rem));
end

%% Do stats
% 0 = HC, 1 = CONV, 2 = SYMP, 3 = REM
group_labels = [ ...
    zeros(height(data_hc), 1); ...
    ones(height(data_conv), 1); ...
    repmat(2, height(data_symp), 1); ...
    repmat(3, height(data_rem), 1)];

age_all = [data_hc.EEGage; data_conv.EEGage; data_symp.EEGage; data_rem.EEGage];
[p_age, tbl_age, stats_age] = anova1(age_all, group_labels, 'off');

sex_all = categorical([data_hc.Sex; data_conv.Sex; data_symp.Sex; data_rem.Sex], [1 2], {'Male', 'Female'});
[~, chi2stat_sex, p_sex] = crosstab(group_labels, sex_all);

% 0 = CONV, 1 = SYMP, 2 = REM
group_labels = [ ...
    zeros(height(data_conv), 1); ...
    ones(height(data_symp), 1); ...
    repmat(2, height(data_rem), 1)];

switch opt.task
    case 'MMN'
        pos_all = [data_conv.SOPS_Positive_Total; data_symp.SOPS_Positive_Total; data_rem.SOPS_Positive_Total];
        [p_pos, tbl_pos, stats_pos] = anova1(pos_all, group_labels, 'off');
        neg_all = [data_conv.SOPSNegative; data_symp.SOPSNegative; data_rem.SOPSNegative];
        [p_neg, tbl_neg, stats_neg] = anova1(neg_all, group_labels, 'off');
        dis_all = [data_conv.SOPSDisorganization; data_symp.SOPSDisorganization; data_rem.SOPSDisorganization];
        [p_dis, tbl_dis, stats_dis] = anova1(dis_all, group_labels, 'off');
        gen_all = [data_conv.SOPSGeneral; data_symp.SOPSGeneral; data_rem.SOPSGeneral];
        [p_gen, tbl_gen, stats_gen] = anova1(gen_all, group_labels, 'off');
    case 'P300'
        pos_all = [data_conv.cSOPSPositive; data_symp.cSOPSPositive; data_rem.cSOPSPositive];
        [p_pos, tbl_pos, stats_pos] = anova1(pos_all, group_labels, 'off');
        neg_all = [data_conv.cSOPSNegative; data_symp.cSOPSNegative; data_rem.cSOPSNegative];
        [p_neg, tbl_neg, stats_neg] = anova1(neg_all, group_labels, 'off');
        dis_all = [data_conv.cSOPSDisorganization; data_symp.cSOPSDisorganization; data_rem.cSOPSDisorganization];
        [p_dis, tbl_dis, stats_dis] = anova1(dis_all, group_labels, 'off');
        gen_all = [data_conv.cSOPSGeneral; data_symp.cSOPSGeneral; data_rem.cSOPSGeneral];
        [p_gen, tbl_gen, stats_gen] = anova1(gen_all, group_labels, 'off');
end

% Medication (AP vs noAP)
switch opt.task
    case 'MMN'
        ap_conv =  isnan(data_conv.GroupNOAP );
        ap_symp =  isnan(data_symp.GroupNOAP );
        ap_rem  =  isnan(data_rem.GroupNOAP  );
    case 'P300'
        ap_conv =  isnan(data_conv.groupNOAP );
        ap_symp =  isnan(data_symp.groupNOAP );
        ap_rem  =  isnan(data_rem.groupNOAP  );
end
ap_all_logical = [ap_conv; ap_symp; ap_rem]; 
ap_all = categorical(ap_all_logical, [0 1], {'noAP','AP'});
[~, chi2stat_ap, p_ap] = crosstab(group_labels, ap_all);

% APS
aps_all = categorical([data_conv.APS; data_symp.APS; data_rem.APS], [0 1], {'noAPS', 'APS'});
[~, chi2stat_aps, p_aps] = crosstab(group_labels, aps_all);

% GRD
grd_all = categorical([data_conv.GRD; data_symp.GRD; data_rem.GRD], [0 1], {'noGRD', 'GRD'});
[~, chi2stat_grd, p_grd] = crosstab(group_labels, grd_all);

% BIPS
bips_all = categorical([data_conv.BIPS; data_symp.BIPS; data_rem.BIPS], [0 1], {'noBIPS', 'BIPS'});
[~, chi2stat_bips, p_bips] = crosstab(group_labels, bips_all);

%% Display results
n_hc = height(data_hc); n_conv = height(data_conv);
n_symp = height(data_symp); n_rem = height(data_rem);
na = 'N/A';

fprintf('\n%-35s %-22s %-22s %-22s %-22s %-30s\n', 'Demographic', ...
    sprintf('Healthy Control (n=%d)', n_hc), ...
    sprintf('CHR-Converter (n=%d)', n_conv), ...
    sprintf('CHR-Persistent (n=%d)', n_symp), ...
    sprintf('CHR-Remitter (n=%d)', n_rem), ...
    'Statistical analysis');
fprintf('%s\n', repmat('-', 1, 135));

% Age
fprintf('%-35s %-22s %-22s %-22s %-22s %-30s\n', 'Age [mean (SD)]', ...
    sprintf('%d (%.1f)', round(mean(data_hc.EEGage,'omitnan')),   std(data_hc.EEGage,'omitnan')), ...
    sprintf('%d (%.1f)', round(mean(data_conv.EEGage,'omitnan')), std(data_conv.EEGage,'omitnan')), ...
    sprintf('%d (%.1f)', round(mean(data_symp.EEGage,'omitnan')), std(data_symp.EEGage,'omitnan')), ...
    sprintf('%d (%.1f)', round(mean(data_rem.EEGage,'omitnan')),  std(data_rem.EEGage,'omitnan')), ...
    sprintf('F(%d,%d)=%.2f, p=%.3f', tbl_age{2,3}, tbl_age{3,3}, tbl_age{2,5}, p_age));

% Sex
hc_f = sum(data_hc.Sex==2); conv_f = sum(data_conv.Sex==2);
symp_f = sum(data_symp.Sex==2); rem_f = sum(data_rem.Sex==2);
fprintf('%-35s %-22s %-22s %-22s %-22s %-30s\n', 'Female [n (%)]', ...
    sprintf('%d (%.1f%%)', hc_f,   100*hc_f/n_hc), ...
    sprintf('%d (%.1f%%)', conv_f, 100*conv_f/n_conv), ...
    sprintf('%d (%.1f%%)', symp_f, 100*symp_f/n_symp), ...
    sprintf('%d (%.1f%%)', rem_f,  100*rem_f/n_rem), ...
    sprintf('X2=%.2f, p=%.3f', chi2stat_sex, p_sex));

% CHR-P syndromes
fprintf('%-35s %-22s %-22s %-22s %-22s %-30s\n', 'APSS [n (%)]', na, ...
    sprintf('%d (%.1f%%)', sum(data_conv.APS==1), 100*mean(data_conv.APS==1)), ...
    sprintf('%d (%.1f%%)', sum(data_symp.APS==1), 100*mean(data_symp.APS==1)), ...
    sprintf('%d (%.1f%%)', sum(data_rem.APS==1),  100*mean(data_rem.APS==1)), ...
    sprintf('X2=%.2f, p=%.3f', chi2stat_aps, p_aps));

fprintf('%-35s %-22s %-22s %-22s %-22s %-30s\n', 'BIPS [n (%)]', na, ...
    sprintf('%d (%.1f%%)', sum(data_conv.BIPS==1), 100*mean(data_conv.BIPS==1)), ...
    sprintf('%d (%.1f%%)', sum(data_symp.BIPS==1), 100*mean(data_symp.BIPS==1)), ...
    sprintf('%d (%.1f%%)', sum(data_rem.BIPS==1),  100*mean(data_rem.BIPS==1)), ...
    sprintf('X2=%.2f, p=%.3f', chi2stat_bips, p_bips));

fprintf('%-35s %-22s %-22s %-22s %-22s %-30s\n', 'GRDS [n (%)]', na, ...
    sprintf('%d (%.1f%%)', sum(data_conv.GRD==1), 100*mean(data_conv.GRD==1)), ...
    sprintf('%d (%.1f%%)', sum(data_symp.GRD==1), 100*mean(data_symp.GRD==1)), ...
    sprintf('%d (%.1f%%)', sum(data_rem.GRD==1),  100*mean(data_rem.GRD==1)), ...
    sprintf('X2=%.2f, p=%.3f', chi2stat_grd, p_grd));

% Antipsychotic use
switch opt.task
    case 'MMN'
        conv_ap=sum(isnan(data_conv.GroupNOAP)); symp_ap=sum(isnan(data_symp.GroupNOAP)); rem_ap=sum(isnan(data_rem.GroupNOAP));
    case 'P300'
        conv_ap=sum(isnan(data_conv.groupNOAP)); symp_ap=sum(isnan(data_symp.groupNOAP)); rem_ap=sum(isnan(data_rem.groupNOAP));
end
fprintf('%-35s %-22s %-22s %-22s %-22s %-30s\n', 'Antipsychotic use [n (%)]', na, ...
    sprintf('%d (%.1f%%)', conv_ap, 100*conv_ap/n_conv), ...
    sprintf('%d (%.1f%%)', symp_ap, 100*symp_ap/n_symp), ...
    sprintf('%d (%.1f%%)', rem_ap,  100*rem_ap/n_rem), ...
    sprintf('X2=%.2f, p=%.3f', chi2stat_ap, p_ap));

% SOPS
switch opt.task
    case 'MMN'
        pos_conv=data_conv.SOPS_Positive_Total; pos_symp=data_symp.SOPS_Positive_Total; pos_rem=data_rem.SOPS_Positive_Total;
        neg_conv=data_conv.SOPSNegative;         neg_symp=data_symp.SOPSNegative;         neg_rem=data_rem.SOPSNegative;
        dis_conv=data_conv.SOPSDisorganization;  dis_symp=data_symp.SOPSDisorganization;  dis_rem=data_rem.SOPSDisorganization;
        gen_conv=data_conv.SOPSGeneral;           gen_symp=data_symp.SOPSGeneral;           gen_rem=data_rem.SOPSGeneral;
    case 'P300'
        pos_conv=data_conv.cSOPSPositive; pos_symp=data_symp.cSOPSPositive; pos_rem=data_rem.cSOPSPositive;
        neg_conv=data_conv.cSOPSNegative; neg_symp=data_symp.cSOPSNegative; neg_rem=data_rem.cSOPSNegative;
        dis_conv=data_conv.cSOPSDisorganization; dis_symp=data_symp.cSOPSDisorganization; dis_rem=data_rem.cSOPSDisorganization;
        gen_conv=data_conv.cSOPSGeneral;  gen_symp=data_symp.cSOPSGeneral;  gen_rem=data_rem.cSOPSGeneral;
end

sops_labels = {'SOPS Positive [mean (SD)]', 'SOPS Negative [mean (SD)]', ...
               'SOPS Disorganization [mean (SD)]', 'SOPS General [mean (SD)]'};
sops_conv   = {pos_conv, neg_conv, dis_conv, gen_conv};
sops_symp   = {pos_symp, neg_symp, dis_symp, gen_symp};
sops_rem    = {pos_rem,  neg_rem,  dis_rem,  gen_rem};
sops_tbls   = {tbl_pos, tbl_neg, tbl_dis, tbl_gen};
sops_ps     = {p_pos, p_neg, p_dis, p_gen};

for s = 1:4
    fprintf('%-35s %-22s %-22s %-22s %-22s %-30s\n', sops_labels{s}, na, ...
        sprintf('%.1f (%.1f)', mean(sops_conv{s},'omitnan'), std(sops_conv{s},'omitnan')), ...
        sprintf('%.1f (%.1f)', mean(sops_symp{s},'omitnan'), std(sops_symp{s},'omitnan')), ...
        sprintf('%.1f (%.1f)', mean(sops_rem{s}, 'omitnan'), std(sops_rem{s}, 'omitnan')), ...
        sprintf('F(%d,%d)=%.2f, p=%.3f', sops_tbls{s}{2,3}, sops_tbls{s}{3,3}, sops_tbls{s}{2,5}, sops_ps{s}));
end

%% Post hoc
group_names_posth = {'CHR-Converter', 'CHR-Persistent', 'CHR-Remitter'};
sops_posth_labels = {'SOPS Positive', 'SOPS Disorganization', 'SOPS General'};
sops_posth_stats  = {stats_pos, stats_dis, stats_gen};

for s = 1:numel(sops_posth_stats)
    fprintf('\nPost-hoc: %s\n', sops_posth_labels{s});
    fprintf('  %-20s %-20s %-12s %-10s\n', 'Group 1', 'Group 2', 'Mean diff', 'p');
    results = multcompare(sops_posth_stats{s}, 'Display', 'off');
    for r = 1:size(results, 1)
        fprintf('  %-20s %-20s %-12.2f %-10.3f\n', ...
            group_names_posth{results(r,1)}, ...
            group_names_posth{results(r,2)}, ...
            results(r,4), results(r,6));
    end
end

fprintf('\nPost-hoc: BIPS\n');
groups = [repmat({'CHR-Converter'}, height(data_conv), 1); ...
          repmat({'CHR-Persistent'}, height(data_symp), 1); ...
          repmat({'CHR-Remitter'}, height(data_rem),  1)];
bips_num = [data_conv.BIPS; data_symp.BIPS; data_rem.BIPS];
for i = 1:numel(group_names_posth)
    for j = i+1:numel(group_names_posth)
        idx_i = strcmp(groups, group_names_posth{i});
        idx_j = strcmp(groups, group_names_posth{j});
        tbl = [sum(bips_num(idx_i)==0), sum(bips_num(idx_i)==1); ...
               sum(bips_num(idx_j)==0), sum(bips_num(idx_j)==1)];
        [~, p] = fishertest(tbl);
        fprintf('  %-20s %-20s %-10.3f\n', group_names_posth{i}, group_names_posth{j}, p);
    end
end