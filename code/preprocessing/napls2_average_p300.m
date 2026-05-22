%% Compute grand mean

function napls2_average_p300(opt)

%% Grand mean across all subjects (HC + CHR-P) and across HC only
outfile = fullfile(opt.pmean, 'filtered', 'p300_grandmean_all_f15.mat');
outfile_HC = fullfile(opt.pmean, 'filtered', 'p300_grandmean_hc_f15.mat');

if isfile(outfile) && isfile(outfile_HC)
    disp('Grand mean files already exist:');
    disp(outfile);
    disp(outfile_HC);
else
    %% Load subject data
    [~, ~, subj_sheet] = xlsread(opt.fsubjects);
    subj_sheet(:,2:3) = []; % Remove columns with site and subject IDs - column 1 contains this already in the format siteID-subjID

    %% Get SPM files
    temp = dir(fullfile(opt.psubjects,'filtered','f15_Mp*.mat'));
    if isempty(temp); error('No SPM files found! Please convert data to SPM format.'); end
    spm_subjects = fullfile({temp.folder}',{temp.name}');
    clear temp

    %% Initialise variables
    hc = 0; chr = 0; bad = 0;

    % Loop over files
    for s = 1:numel(spm_subjects)
        % Get subject ID
        id = extractBetween(spm_subjects{s},'NAPLS-','-1');
        try
            % Find diagnosis
            subj_row = find(strcmp(subj_sheet(:,1),id));
            subj_diag = subj_sheet{subj_row,2};
            group = subj_sheet{subj_row,7};
            switch subj_diag
                case 0
                    hc = hc + 1;
                    subj_HC{hc,1} = spm_subjects{s};
                case 1
                    chr = chr + 1;
                    subj_CHR{chr,1} = spm_subjects{s};
            end
        catch
            bad = bad + 1;
            bad_subj{bad,1} = spm_subjects{s};
            disp(['Error (missing) for subj ', id{:}])
        end
    end

    if ~isfile(outfile)
        % Compute grand mean across all subjects
        S = [];
        S.D = char([subj_HC; subj_CHR]);
        S.outfile = outfile;
        Do = spm_eeg_grandmean(S);
    end
    
    if ~isfile(outfile_HC) 
        % Compute grand mean across HC
        S = [];
        S.D = char(subj_HC);
        S.outfile = outfile_HC;
        Do = spm_eeg_grandmean(S);
    end
end
end