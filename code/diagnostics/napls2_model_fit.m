%% Plot model fit

function napls2_model_fit(opt)

%% Options
switch opt.task
    case 'MMN'
        dcm_version = 14; % DCM version to use
        conditions = {'Standard', 'Deviant', 'Difference'};
        pdcm = fullfile(opt.presults, 'dcm_ei', ['mmn_all_subjects_v', num2str(dcm_version)]);
    case 'P300'
        dcm_version = 21; % DCM version to use
        conditions = {'Standard', 'Target', 'Difference'};
        pdcm = fullfile(opt.pdresults, 'dcm_ei', ['p300_all_subjects_v', num2str(dcm_version)]);
end

% Load subject sheet
[~,~,subj_sheet] = xlsread(opt.fsubjects);

%% Figure settings
set(0,'DefaultTextInterpreter','none');
set(0,'DefaultAxesTickLabelInterpreter','none');
set(0,'DefaultFigureColor',[1 1 1]);
set(0,'DefaultAxesFontSize',18);
set(0,'DefaultTextFontSize',18);
set(0,'DefaultAxesFontName','calibri');
set(0,'DefaultAxesFontWeight','normal');

%% Compute R2 and correlation
no_cond = 2;
all_dcm = dir(fullfile(pdcm,'*dcm*.mat'));

% Initialise
cor = NaN(length(all_dcm),no_cond+1);
R2 = NaN(length(all_dcm),no_cond+1);
diag = NaN(length(all_dcm),1);
group = NaN(length(all_dcm),1);

% Loop over files
for f = 1:length(all_dcm)
    % Load DCM
    load(fullfile(all_dcm(f).folder, all_dcm(f).name))
    
    % Find diagnosis (HC or CHR-P) and clinical outcome
    switch opt.task
        case 'MMN'
            id = extractBetween(all_dcm(f).name,'cmc_','.mat'); id = id{:};
        case 'P300'
            id = extractBetween(all_dcm(f).name,'cmc_','-1'); id = id{:}; 
    end
    subj_idx = find(ismember(subj_sheet(:,1),id));
    diag_col = find(ismember(subj_sheet(1,:),'Group'));
    diag(f) = subj_sheet{subj_idx,diag_col};
    group_col = find(ismember(subj_sheet(1,:),'FinalCCSGroup'));
    group(f) = subj_sheet{subj_idx,group_col};
    
    % Compute overall variance explained
    U = DCM.M.U';
    for c = 1:no_cond
        MSE(c) = sum(sum((DCM.R{c}*U).^2));
        SS(c) = sum(sum((((DCM.H{c} + DCM.R{c})*U).^2)));
        R2(f,c) = 1-(MSE(c)/SS(c));
    end
    % Difference wave
    R_diff = (DCM.R{2} - DCM.R{1}) * U;
    Y_diff = ((DCM.H{2} + DCM.R{2}) - (DCM.H{1} + DCM.R{1})) * U;
    MSE_diff = sum(sum(R_diff.^2));
    SS_diff = sum(sum(Y_diff.^2));
    R2(f,c+1) = 1 - (MSE_diff / SS_diff);
    
    % Compute correlation 
    y1 = (DCM.H{1}+DCM.R{1})*U;
    y2 = (DCM.H{2}+DCM.R{2})*U;
    yhat1 = DCM.H{1}*U;
    yhat2 = DCM.H{2}*U;
    cor(f,1) = corr(y1(:),yhat1(:),'type','Pearson');
    cor(f,2) = corr(y2(:),yhat2(:),'type','Pearson');
    
    % Difference wave
    y3 = y2 - y1; 
    yhat3 = yhat2 - yhat1;
    cor(f,3) = corr(y3(:),yhat3(:),'type','Pearson');
end

% Remove zeros from R2
R2(R2==0) = NaN;

%% Correlation
conv_cor = cor(group==1,:);
remit_cor = cor(group==3,:);
meancor = mean([conv_cor(:,3);remit_cor(:,3)]);
stdcor = std([conv_cor(:,3);remit_cor(:,3)]);

disp('Correlation');
disp(['  Mean (SD) = ', num2str(meancor, '%.2f'), ' (', num2str(stdcor, '%.2f'), ')']);

% Plot 
fh = figure('units','normalized','outerposition',[0.3 0.3 0.4 0.68],'Visible',opt.vis_plots);
pl = 1;
for c = 1:no_cond+1
    ax = subplot(1,no_cond+1,pl);
    meancor = cor(:,c);
    meancor(group == 32) = [];
    temp = group; temp(group == 32) = [];
    meancor(temp == 2) = []; temp(temp == 2) = [];
    meancor(temp == 0) = []; temp(temp == 0) = [];
    cor_conv = meancor(temp == 1);
    cor_remit = meancor(temp == 3);
    jittered_x1 = ones(size(cor_remit)) * 1 + (rand(size(cor_remit)) - 0.5) * 0.1;
    jittered_x2 = ones(size(cor_conv)) * 1.3 + (rand(size(cor_conv)) - 0.5) * 0.1;
    hold on
    scatter(jittered_x1,cor_remit,14,'o','filled','MarkerFaceColor',[0, 0.4, 0]);
    scatter(jittered_x2,cor_conv,14,'o','filled','MarkerFaceColor',[0.6, 0.8, 0.2]);
    h = boxplot(meancor, temp, 'positions', [1 1.3], 'widths', 0.1, 'colors', 'k', 'symbol', 'k');
    
    % For correlation
    plot([1 1.3],[1 1],'k','LineWidth',1);
    text(1.1,1.05,'n.s.','FontSize',14); hold off
    
    set(h,{'linew'},{1.5})
    pos = ax.Position; pos(2) = pos(2)+0.1; pos(4) = pos(4)-0.1; set(ax, 'Position', pos);
    xticklabels({sprintf('CHR-Remitter'), sprintf('CHR-Converter')}); xtickangle(45);
    title(conditions{pl},'FontWeight','bold');
    pl = pl+1;
end

% Figure settings
allAxes = findall(fh, 'Type', 'axes');
for k = 1:length(allAxes)
    ax1 = allAxes(k);
    ax1.XAxis.LineWidth = 1;
    ax1.YAxis.LineWidth = 1;
    set(ax1, 'XColor', 'k', 'YColor', 'k', 'Layer', 'top');
end
ylim([-0.2 1.1]); linkaxes(allAxes,'y');
% saveas(fh,fullfile(opt.pfigures, sprintf('fig_1de_%s_cor.png',lower(opt.task))));
saveas(fh,fullfile(opt.pfigures, sprintf('fig_1de_%s_cor.svg',lower(opt.task))));
saveas(fh,fullfile(opt.pfigures, sprintf('fig_1de_%s_cor.fig',lower(opt.task))));

% Test for normality
% for c = 1:3
%     disp(['Condition ', num2str(c)]);
%     [h, p] = kstest(conv_cor(:,c));
%     if h == 0; disp(['CHR-Converter data is normally distributed, p = ', num2str(p)]);
%     else; disp(['CHR-Converter data is NOT normally distributed, p = ', num2str(p)]); end
%     [h, p] = kstest(remit_cor(:,c));
%     if h == 0; disp(['CHR-Remitter data is normally distributed, p = ', num2str(p)]);
%     else; disp(['CHR-Remitter data is NOT normally distributed, p = ', num2str(p)]); end
% end

% r-to-z transform
z_cor = fisher_z(cor);
conv_cor = z_cor(group==1,:);
remit_cor = z_cor(group==3,:);

% Plot r-to-z transformed
fh = figure('units','normalized','outerposition',[0.3 0.3 0.4 0.68],'Visible',opt.vis_plots);
pl = 1;
for c = 1:no_cond+1
    ax = subplot(1,no_cond+1,pl);
    meancor = z_cor(:,c);
    meancor(group == 32) = [];
    temp = group; temp(group == 32) = [];
    meancor(temp == 2) = []; temp(temp == 2) = [];
    meancor(temp == 0) = []; temp(temp == 0) = [];
    cor_conv = meancor(temp == 1);
    cor_remit = meancor(temp == 3);
    jittered_x1 = ones(size(cor_remit)) * 1 + (rand(size(cor_remit)) - 0.5) * 0.1;
    jittered_x2 = ones(size(cor_conv)) * 1.3 + (rand(size(cor_conv)) - 0.5) * 0.1;
    hold on
    scatter(jittered_x1,cor_remit,14,'o','filled','MarkerFaceColor',[0, 0.4, 0]);
    scatter(jittered_x2,cor_conv,14,'o','filled','MarkerFaceColor',[0.6, 0.8, 0.2]);
    h = boxplot(meancor, temp, 'positions', [1 1.3], 'widths', 0.1, 'colors', 'k', 'symbol', 'k');
    
    % For correlation
    plot([1 1.3],[2.2 2.2],'k','LineWidth',1); 
    text(1.1,2.3,'n.s.','FontSize',14); hold off % Hardcoded, adjust if needed!

    set(h,{'linew'},{1.5})
    pos = ax.Position; pos(2) = pos(2)+0.1; pos(4) = pos(4)-0.1; set(ax, 'Position', pos);
    xticklabels({sprintf('CHR-Remitter'), sprintf('CHR-Converter')}); xtickangle(45);
    title(conditions{pl},'FontWeight','bold');
    pl = pl+1;
end

% Figure settings
allAxes = findall(fh, 'Type', 'axes');
for k = 1:length(allAxes)
    ax1 = allAxes(k);
    ax1.XAxis.LineWidth = 1;
    ax1.YAxis.LineWidth = 1;
    set(ax1, 'XColor', 'k', 'YColor', 'k', 'Layer', 'top');
end
ylim([-0.2 2.4]); linkaxes(allAxes,'y');
% saveas(fh,fullfile(opt.pfigures, sprintf('fig_s1ab_%s_zcor.png',lower(opt.task))));
saveas(fh,fullfile(opt.pfigures, sprintf('fig_s1ab_%s_zcor.svg',lower(opt.task))));
saveas(fh,fullfile(opt.pfigures, sprintf('fig_s1ab_%s_zcor.fig',lower(opt.task))));

% Check group differences
[p, ~] = ranksum(conv_cor(:,3), remit_cor(:,3));  
disp(['  CHR-Converters v CHR-Remitter: p = ',num2str(p)]);

%% Variance explained
conv_R2 = R2(group==1,:);
remit_R2 = R2(group==3,:);
meanR2 = mean([conv_R2(:,3);remit_R2(:,3)]);
stdR2 = std([conv_R2(:,3);remit_R2(:,3)]);

disp('Variance explained');
disp(['  Mean (SD) = ', num2str(meanR2, '%.2f'), ' (', num2str(stdR2, '%.2f'), ')']);

% Test for normality
% for c = 1:3
%     disp(['Condition ', num2str(c)]);
%     [h, p] = kstest(conv_R2(:,c));
%     if h == 0; disp(['CHR-Converter data is normally distributed, p = ', num2str(p)]);
%     else; disp(['CHR-Converter data is NOT normally distributed, p = ', num2str(p)]); end
%     [h, p] = kstest(remit_R2(:,c));
%     if h == 0; disp(['CHR-Remitter data is normally distributed, p = ', num2str(p)]);
%     else; disp(['CHR-Remitter data is NOT normally distributed, p = ', num2str(p)]); end
% end

% r-to-z transform
z_R2 = fisher_z(R2);
conv_R2 = z_R2(group==1,:);
remit_R2 = z_R2(group==3,:);

% Check group differences
[p, ~] = ranksum(conv_R2(:,3), remit_R2(:,3));
disp(['  CHR-Converters v CHR-Remitter: p = ',num2str(p)]);
    
end