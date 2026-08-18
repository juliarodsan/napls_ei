# Biophysical modeling of excitation/inhibition balance and conversion to psychosis in the clinical high risk syndrome

This repository contains the analysis code for Rodriguez-Sanchez*, Hauke* et al. (2026, *Biological Psychiatry*). We use dynamic causal modelling (DCM) to estimate excitatory and inhibitory cell function from MMN and P300 EEG data in the NAPLS2 cohort and parametric empirical Bayes (PEB) to identify differences between CHR-P individuals who later convert to psychosis and those who remit, as well as associations with symptoms.

## Citing this work

If you use this code, please cite:
* Rodriguez-Sanchez\*, Hauke\* et al. (2026). Biophysical modeling of excitation/inhibition balance and conversion to psychosis in the clinical high risk syndrome. *Biological Psychiatry*. https://doi.org/10.1016/j.biopsych.2026.04.007

This code uses the canonical microcircuit model from:
* Hauke et al. (2025). A canonical microcircuit for estimating excitation/inhibition (E/I) balance. *Translational Psychiatry*. https://doi.org/10.1038/s41398-026-04312-y

The model implementation is available at: https://github.com/daniel-hauke/dcm_ei

This code runs in MATLAB and requires the SPM12 toolbox. Please also cite SPM12 if you use this code:

* Friston et al. (1994). Statistical parametric maps in functional imaging: A general linear approach. *Human Brain Mapping*. https://doi.org/10.1002/hbm.460020402

## Data access
This project used the NAPLS2 dataset. Data are not included in this repository but access can be arranged through a formal collaboration with the NAPLS2 principal investigators.
