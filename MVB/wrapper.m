%% Purpose: Run MVB decoding

%% ========================================================================
%% Restart analysis?
%!rm -vvf data/CC*/MVB_*
%!rm -vvf data/CC*/*.ps
%%
%% Initial Setup?
%% Run setupDir.m
%% ========================================================================



%% Paths/Var Setup
%% ========================================================================

clear

qSPM % par(64) %Intiate spm fmri.

T = readtable('T_withROIs.csv');
CCIDList = T.SubCCIDc;

done_createXYZ = false;
done_MVB = false;

%% Setup ROI Features
%% ========================================================================
%% Choose one ROI pair to perform MVB model comparison between (e.g. L/R):

%% CUNEAL:
% roifN = {...
%   'taskMap_24POINT8.nii',              ... %Task
%   'compensationROI.nii' ... %compensation ROI
%   };

%% FRONTAL:
roifN = {...
  'taskMap_26.nii',              ... %Task
  'mask-cluster_con-intersectAgeBhv_ROI-frontalANDCing.nii' ... %compensation ROI
  };

%% Standardise variables
roiName = cellfun(@(x) x(1:end-4), roifN, 'Uniform', 0);  %cut '.nii'
roiPairs = [1,2]; %[1,2;3,4]; %etc

if ~done_createXYZ
  camcan_main_mvb_makexyz
  cd ../../
  %edit checknVox_mask.m
end


%% Run MVB
%% ========================================================================
conditions = {'Hard-Easy'}; %A name of contrast in a con image
contrasts = [3]; %the corresponding con image number
model = 'sparse';

if ~done_MVB
  for r = 1%:size(roiPairs,1) %rows
    for c = 1:length(contrasts)
    
    
      currROIs{1} = roiName{roiPairs(r,1)}; %LH
      currROIs{2} = roiName{roiPairs(r,2)}; %RH
      conditionName = conditions{c};
      con = contrasts(c);
    

      camcan_main_mvb_top(currROIs,conditionName,con,CCIDList,model);
          %tmp_controlVoxelSize_camcan_main_mvb_top(currROIs,conditionName,con,CCIDList,model);
    end
  end
end

%% PostProcessing 
%% ========================================================================
%% To write a table to R/data.csv:
%% Run doPostProcessing.m 
