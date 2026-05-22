function DCM = get_priors_ei_cmc(DCM)

%% Get neural priors
[DCM.M.pE,DCM.M.pC] = spm_dcm_neural_priors(DCM.A,DCM.B,DCM.C,DCM.options.model);

%% Priors on spatial model
DCM = spm_dcm_erp_data(DCM);
DCM = spm_dcm_erp_dipfit(DCM,1);

DCM.M.dipfit.model = DCM.options.model;
[DCM.M.gE,DCM.M.gC] = spm_L_priors(DCM.M.dipfit);

%% Fixed parameters and equality contraints 
% Fix regions-specific delay parameter
DCM.M.pC.D = zeros(size(DCM.M.pC.D));

% Fix modulatory extrinsic conenctions for now
DCM.M.pC.M = zeros(size(DCM.M.pC.M));

% Instead we will estimate delays that are constant across regions
% Interpretation: [intrinsic_delays extrinsic_delays]
DCM.M.pE.D_all_sources = [0 0];
DCM.M.pC.D_all_sources = [1/64 1/64];

% Fix J parameters to prior (only pyramidal cells contribute to the signal)
DCM.M.gC.J = sparse(zeros(size(DCM.M.gC.J)));

% Interpretation of G's: [g_ee g_ii g_ei g_ie g_se]
DCM.M.pE.G = zeros(1,5);
DCM.M.pC.G = ones(1,5)*1/32;

%% E/I parameters
% Means
DCM.M.pE.B_g_ee = zeros(1,numel(DCM.B));
DCM.M.pE.B_g_ii = zeros(1,numel(DCM.B));
DCM.M.pE.B_g_ei = zeros(1,numel(DCM.B));
DCM.M.pE.B_g_ie = zeros(1,numel(DCM.B));
DCM.M.pE.B_g_se = zeros(1,numel(DCM.B));

% Variances
DCM.M.pC.B_g_ee = 1/8*ones(1,numel(DCM.B));
DCM.M.pC.B_g_ii = 1/8*ones(1,numel(DCM.B));
DCM.M.pC.B_g_ei = 1/8*ones(1,numel(DCM.B));
DCM.M.pC.B_g_ie = 1/8*ones(1,numel(DCM.B));
DCM.M.pC.B_g_se = 1/8*ones(1,numel(DCM.B));
end