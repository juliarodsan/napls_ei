function [Ep, Cp, names] = get_peb_parameters(PEB)

%--------------------------------------------------------------------------
% Function to create plot of estimated DCM parameters.
% 
% IN:
%  PEB          -> PEB or DCM structure
% 
% OUT:
%  Ep           -> vectorised posterior parameter estimates to be plotted
%  Cp           -> vectorised posterior parameter variances to be plotted
%  names        -> parameter names
% 
%--------------------------------------------------------------------------

% Correct BMA matrix size (Ep)
np = length(PEB.Pnames); % Parameters
nc = size(PEB.M.X,2);    % Covariates
if size(PEB.Ep,2) ~= nc
    PEB.Ep = reshape(PEB.Ep,np,nc);
end

% Correct BMA matrix size (Cp)
if isvector(PEB.Cp)
    PEB.Cp = diag(PEB.Cp);
end

effect = 2;
if effect > 0 && effect <= nc
    % Identify relevant parameters
    effect_idx         = 1:np:(np*nc);
    peb_param_idx      = effect_idx(effect) : (effect_idx(effect) + np - 1);

    % Posterior means / covariance
    Ep = PEB.Ep(:,effect); 
    Cp = diag(PEB.Cp);
    Cp = Cp(peb_param_idx); 
    names = PEB.Pnames;
end
end