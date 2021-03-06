%% Purpose: Perform 1st/2nd level models, TFCE, define ROIs & extract ROI 
%% timecourses.
%%
%% Depends on commonality toolbox:
%% https://github.com/kamentsvetanov/CommonalityAnalysis


%% Dependencies:
restoredefaultpath
addpath(genpath('/imaging/camcan/sandbox/kt03/projects/private-code/kamen')); %% https://github.com/kamentsvetanov/CommonalityAnalysis 
addpath(genpath('/home/kt03/Projects/public-code/CommonalityAnalysis')); %% https://github.com/kamentsvetanov/CommonalityAnalysis 
kat_import('palm');
kat_import('spm12');
kat_import('matlabcentral'); % Needed for 'rdir' function
kat_import('tfce');
kat_import('cbrewer') % in mat/colormaps



clear
% Load table T consisting subject sprcific information e.g. age, gender, filepaths to imaging data 
path2data = '/imaging/camcan/sandbox/kt03/projects/collabs/ethanK/ccc'; %see OSF
load(fullfile(path2data,'T_settings_sw20210622.mat'));

S.paths.results = '/imaging/camcan/sandbox/kt03/projects/collabs/ethanK/ccc/results';

% -------------------------------
% Remove variables of no interest
% -------------------------------
varnames = T.Properties.VariableNames;
idx = contains(varnames,{'roi','cv_','comp','ecg', 'bp_','pulse'});
T(:,idx) = [];

writetable(T,fullfile(path2data,'T_ccc_ethan.xlsx'));

% Update f_Cattellcont with CBU location
T.f_Cattellcont = regexprep(T.f_Cattellcont,'/home/sw932/Cattell_analysis/cattell_data/','/imaging/camcan/sandbox/kt03/projects/collabs/ethanK/ccc/');
% T.f_ASL =   regexprep(T.f_ASL,'/home/sw932/Cattell_analysis/rsfa/asl/','/imaging/camcan/sandbox/kt03/archived/2020TsvetanovPsyP/data/mri/release003/asl/data_qCBF/');


%% Voxel-based Analysis

% -------------------------------------------------
% Specify model for Voxel-based analysis
% -------------------------------------------------
Model = 'f_Cattellcont ~  PC6 + Age';%  + G + H+ f_ASL

% -------------------------------------------------
% Assemble cfg structure needed to run the analysis
% -------------------------------------------------
cfg                 = [];
cfg.model           = Model;
cfg.rootDir         = S.paths.results; 
cfg.f_mask          = fullfile('/imaging/camcan/sandbox/kt03/templates/masks/brain/mask_ICV_61x73x61.nii');
cfg.numPerm         = 2000;
cfg.doCommonality   = 0;
cfg                 = ca_vba_glm_fitlm(T,cfg);

% -------------------------------------------------------------------------
% Perform TFCE thresholding 
% (cfg from previous step or load analysis_cfg.mat in cfg.rootDir from previous step)
% -------------------------------------------------------------------------
cfg.tfce.path2data  = cfg.outDir;
cfg.tfce.typeStats  = 'tval'; 
cfg.tfce.Ns         = size(cfg.tbl,1);
cfg.tfce.Np         = size(cfg.tbl,2)-1;
cfg.tfce.th         = 1.97;
ca_vba_tfce_threshold(cfg);


%% Use FSL to generate cluster masks (rather than using spheres)
%% ------------------------------------------------------------------------
createMasks_FSL

%% Define & View ROIs
%% ------------------------------------------------------------------------
extract_ROIs


%% Write data table to R/csv/T.csv (modelling & plots)
%% ------------------------------------------------------------------------
%% Grab STW Cam-CAN data (not critical - comment out STW column if no CBU Cam-CAN access)
%HI = CCQuery_LoadHIData('700', 'homeint');
HIadd = CCQuery_LoadHIData('700', 'additional'); 
for s = 1:height(T);  CCID = T.SubCCIDc{s};
  T.STW(s) = HIadd.STW_total(strcmp(CCID,HIadd.CCID));
end

%% Write table
toWrite = table(T.SubCCIDc,T.Age,T.GenderNum,T.handedness,...
  T.PC6,T.CattellCC700_TotalScore,T.STW,...
  T.lSPOC,T.rMFG,T.antCing,T.lPFC,T.frontal);
toWrite.Properties.VariableNames = {'CCID','Age','Gender','handedness',...
  'bhv','bhv_outOfScanner','STW',...
  'lSPOC','rMFG','antCing','lPFC','frontal'};
writetable(toWrite,'R/csv/T.csv')

