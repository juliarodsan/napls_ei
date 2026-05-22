function napls2_pident_correlation_matrix(pdcms,pplots,which_params,param_names,visibility)

%% Defaults
if nargin<3
    plot_spec_params = 0;
else
    plot_spec_params = 1;
end
[~, ~] = mkdir(pplots);

%% Get files
temp = dir(fullfile(pdcms,'*.mat'));
files = fullfile({temp.folder}, {temp.name})';

%% Get parameters
load(files{1})
n_params   = length(full(spm_vec(DCM.Ep)));
n_subjects = numel(files);
is_fixed   = (spm_vec(DCM.M.pC)==0);

params     = zeros(n_subjects,n_params);

for s = 1:n_subjects
    load(files{s});
    params(s,:) = full(spm_vec(DCM.Ep));
end

% Remove fixed parameters
free_params = params(:,~is_fixed);
pnames = spm_fieldindices(DCM.Ep,find(~is_fixed));

%% Compute correlation matrix
c_all = corrcoef(free_params);
is_unconcerning = (isnan(c_all) | abs(c_all) < 0.6);

c_all(is_unconcerning) = 0; % Threshold correlation matrix at 0.6

%% Correct names
for i = 1:numel(pnames)
    if sum(c_all(i,:)) == 1 && sum(c_all(:,i)) == 1 &&...
            ~strcmp(pnames{i}, 'B_g_ii(1)') && ~strcmp(pnames{i}, 'B_g_ee(1)') &&...
            ~strcmp(pnames{i}, 'G(1)') && ~strcmp(pnames{i}, 'G(2)')
        pnames{i} = '';
    end
end

if plot_spec_params
    pnames{contains(pnames, 'B_g_ii(1)')} = 'B-g_{ii}';
    pnames{contains(pnames, 'B_g_ee(1)')} = 'B-g_{ee}';
end

if plot_spec_params
    c_spec = corrcoef(params(:,which_params));
end

%% Plot
min_fontsize = 10;
set(0,'defaultAxesTickLabelInterpreter','tex');
set(0,'DefaultAxesFontSize',min_fontsize,'defaultLegendInterpreter','none')
set(0,'DefaultAxesFontName','calibri');
set(0,'DefaultAxesFontWeight','normal')

% Define colormap
warm = flipud(autumn(40));
cool = winter(40);
white = repmat([1 1 1],120,1); % Pure white (transition -0.6 to 0.6)
cmap = [cool; white; warm];    % Combine into a full colormap

fh = figure('Position',  [100, 100, 300, 300], 'Visible', visibility);
imagesc(c_spec)
caxis([-1 1])
colormap(cmap)
add_values_to_imagesc(c_spec);  % Add values onto imagesc
axis('square');
cb = colorbar;
cb.Ticks = [-1, -0.6, 0, 0.6, 1]; 
cb.TickLabels = {'-1.0', '-0.6', ' 0.0', ' 0.6', ' 1.0'}; 
set(findall(gcf,'-property','FontSize'),'FontSize',min_fontsize)
xlabel('Parameters','FontSize',min_fontsize)
ylabel('Parameters','FontSize',min_fontsize)
xticks(1:numel(param_names))
xticklabels(param_names)
yticks(1:numel(param_names))
yticklabels(param_names)