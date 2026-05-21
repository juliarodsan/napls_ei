#   This is the most basic QSUB file needed for this cluster.
#   Further examples can be found under /share/apps/examples
#   Most software is NOT in your PATH but under /share/apps
#
#   For further info please read http://hpc.cs.ucl.ac.uk
#   For cluster help email cluster-support@cs.ucl.ac.uk
#
#   NOTE hash dollar is a scheduler directive not a comment.


# These are flags you must include - Two memory and one runtime.
# Runtime is either seconds or hours:min:sec

#$ -l tmem=10G
#$ -l h_vmem=10G
#$ -l h_rt=8:00:00 

#These are optional flags but you probably want them in all jobs

#$ -S /bin/bash
#$ -N napls2_p300_dcm_v1
#$ -t 1:790
#$ -o /home/jrodrigu/logfiles/
#$ -wd /SAN/intelsys/Psycho_Pheno/Dropbox/Rick/Academic/Rodriguez-Sanchez/Code/NAPLS/dcm_ei_sim/code/

#The code you want to run now goes here.

hostname
date

cd /SAN/intelsys/Psycho_Pheno/Dropbox/Rick/Academic/Rodriguez-Sanchez/Code/NAPLS/dcm_ei_sim/code/
echo "Current path: $PWD"
export PATH=/share/apps/matlabR2018b/bin:$PATH
echo "Execute command: napls2_p300_fit_dcm_to_individuals(${SGE_TASK_ID})" 
matlab -nodisplay -nodesktop -nojvm -nosplash -singleCompThread -r "napls2_p300_fit_dcm_to_individuals(${SGE_TASK_ID})" 

date

