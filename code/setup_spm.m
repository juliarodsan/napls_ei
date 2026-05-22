function setup_spm(modality)
%--------------------------------------------------------------------------
% Sets up SPM with reasonable parameters
%--------------------------------------------------------------------------

%% Defaults
if nargin < 1
    modality = 'EEG';
end

%% Main
% Init batch editor
spm_jobman('initcfg');

% Initialise FieldTrip etc.
spm('defaults', modality);

% Large .mat files (>2GB) can only be saved with 7.3
spm_get_defaults('mat.format', '-v7.3');

% This should speed up GLM estimation
spm_get_defaults('stats.maxmem', 2^31); % 2 GB RAM
% spm_get_defaults('stats.maxmem', 4^31);
% spm_get_defaults('stats.resmem', true); % store GLM temp files in memory, not on disk

% Set to true for cluster job where no graphics can be output
spm_get_defaults('cmdline', false);
% spm_get_defaults('cmdline', true);