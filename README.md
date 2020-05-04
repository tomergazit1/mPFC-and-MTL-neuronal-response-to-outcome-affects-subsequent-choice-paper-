# mPFC-and-MTL-neuronal-response-to-outcome-affects-subsequent-choice-paper
Script List for the analysis performed in the paper:
mPFC and MTL neuronal response to outcome affects subsequent choice under goal-conflict in humans    
Gazit Tomer*, Gonen Tal*, Gurevitch Guy*, Cohen Noa, Strauss Ido, Zeevi Yoav, Yamin Hagar, Fahoum Firas, Hendler Talma* and Fried Itzhak*

tier1asTable.m
This function craetes a table g with all the data and triggers from the NSx file of blackrock

SyncCartmanClicks.m
This function will synchronize the KeyPress times from cartman game logs with their sessions respective .nev file, its output will be an addition of a "Clicks" column to the standard data table g

PRTtoStimulusTimesLog.m  
% This function reads the files of the approach avoid log
% and arranges them in matlab structure

ApproachAvoidLogTimesToNevTimes.m
% this script takes the matlab matlab structure from PRTStilmulusTimesLog along with the NEV file fron BlackRock to synchronize the timing and assign each event in the NEV triggers with its label from the log file with the correct timing
the output us a structure NevTimesAllUpdated with the correct timings in NEV time

BuildingSpikeTrainStructure.m
this script craetes a big structure called PSTH with all you need to
% know about the cartman single cell activity. each element is a neuron (or % MU) and the structure includes global parameters: x,y,z coordinates, % atlas label, channel name cluster..
Uses two subfunctions:

SplitAchievedAndMissed.m
% this function splits approach Risk to approach risk achieved and missed  it also splits approach no Risk to approach no risk achieved and missed  it takes the approach risk and no risk from the big PSTH structre and  adds to it the 4 new conditions with their time of events, rasters, PSTHs and clicks

bin_spikes.m
arranges spike time vectors to bins
NeuronSignificanceAndGLM
%%% this function is takes PSTHstructure (created with BuildingSpikeTrainStructure.m) containing all the spikes and given a set of conditions and time windows to say which neurons are responsive for each area

NeuronSignificanceAndGLMCombineConds.m
This function is supposed to take PSTHstructure containing all the
spikes and given a set of conditions and time windows to say which
neurons are responsive for each area.in combines conditions 1,2 and 3,4 for the purpose of main effects calculations.

SelectingNeurons.m
This function takes the signif all output of NeuronSignificance and GLM and craetes a structure with the (normalized) neural activation.

relateOutcomeToNextDecisionRiskBatch.m
this function takes the big PSTH structure and for the given significant neurons calculates approach probability following firing vs following no-firing. It uses the following function:

relateOutcomeToNextDecisionRisk.m
this functions evaluates for a specific recording the relationship between response to outcome and the following decision to approach or avoid

creatingEventSequenceBigTableBatch.m
This function takes neurons that are relevant for generalized linear mixed models regression of approach avoidance from frontal and temporal areas and creates tables (using creatingEventSequence) where rows are trials and columns are % 1. from this trial: whether its approach or avoidance 2. features from previous reward trial.  It uses this function:

creatingEventSequenceSingleCh.m
this function takes all reward risk cases in one recording and creates a tables where rows are trials and columns are 1.from this trial: whether its approach or avoidance 2. features from previous trial: movement, firing rates, approach avoidance, times , misse/achieved

creatingEventSequenceBigTablePunBatch.m
% this function takes neurons that ar erelvant for regression of approach avoidance from frontal and temporal areas and creates tables (using creatingEventSequence ) per recording a where rows are trials and columns are relevant variables. It uses this function:

creatingEventSequencePunishSingleCh.m
this function creates a table with
% 1. from this trial: whether its approach or avoidance
% 2. features from previous punishment trial: movement, firing rates, approach avoidance, times , misse/acheived

