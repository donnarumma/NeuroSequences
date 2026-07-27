# NeuroSequences Dependency Analysis

This document maps the public simulation entry points to the MATLAB modules
they use. It focuses on executable code structure rather than project notes.

## 1. Entry Points

### Model simulation mains

The model is run from the `MAIN_*_Exp*.m` scripts.

| File | Family | Role |
|------|--------|------|
| `Chen/MAIN_Chen01_S1S2S3_Forward_Exp.m` | Chen01 | Forward 1D/2D/3D sequence simulation |
| `Chen/MAIN_Chen01_S1S2S3_Backward_Exp.m` | Chen01 | Backward 1D/2D/3D sequence simulation |
| `Chen/MAIN_Chen01_S1S2S3_Sensors_Exp.m` | Chen01 | Sensory / neutral control simulation |
| `Chen/MAIN_Chen02_S2_FwBw_Exp.m` | Chen02 | 2D forward/backward simulation with policy-type priors |
| `Chen/MAIN_Chen02_S2_FwBw_Exp_Supp.m` | Chen02 | Supplementary 2D forward/backward simulation with equal policy weights |
| `Xie/MAIN_Xie_S3_Forward_Exp.m` | Xie | 3D forward sequence simulation |
| `Xie/MAIN_Xie_S3_Forward_Exp_Supp.m` | Xie | Supplementary 3D forward simulation and readout configuration |
| `Mushiake/MAIN_Mushiake_Exp.m` | Mushiake | AY maze simulation with sample maze, firing-rate, and raster plots |
| `Mushiake/MAIN_Mushiake_Exp_Supp.m` | Mushiake | Supplementary AY maze simulation with outer/inner factor readouts |

### Figure-only scripts

These scripts use MATLAB plotting primitives to recreate task schematics or
published-data-style panels. They do not call the model runners.

| File | Role |
|------|------|
| `Chen/Chen01_Forward.m` | Chen01 forward figure reproduction |
| `Chen/Chen01_Backward.m` | Chen01 backward figure reproduction |
| `Chen/Chen01_Sensory.m` | Chen01 sensory figure reproduction |
| `Chen/Chen01_Exp.m` | Chen01 task schematic |
| `Chen/Chen02_FwdBwd.m` | Chen02 forward/backward panel reproduction |
| `Chen/Chen02_Exp.m` | Chen02 task schematic |
| `Xie/Xie_Exp.m` | Xie task schematic |
| `Xie/Xie_Target.m` | Xie target drawing helper |
| `Xie/Xie_Exagons.m` | Xie hexagon-style plotting helper |
| `Mushiake/Mushiake_Spikes.m` | Mushiake spike-panel reproduction |

## 2. External Dependencies

### HAI_LANGUAGE

Repository: <https://github.com/donnarumma/HAI_LANGUAGE>

Used for hierarchical active-inference setup, MDP execution helpers, and
firing-rate utilities. Commonly used functions include:

- `HAI_DefaultParams`
- `HAI_initialiseParams`
- `HAI_RUN`
- `HAI_smartMDP`
- `HAI_extendFiringRates`

### TrialBox

Repository: <https://github.com/donnarumma/TrialBox>

Used for parameter resolution and figure export. Commonly used functions
include:

- `resolveFunctionParams`
- `hfigPrint`
- `hfigPrintParams`

### SPM

Project: <https://www.fil.ion.ucl.ac.uk/spm/>

Used for active-inference / MDP utilities and variational updates. Commonly used
functions include:

- `spm_MDP_check`
- `spm_MDP_VB_X`
- `spm_dot`
- `spm_softmax`

## 3. Core Project Modules

### Model construction and execution

| File | Role |
|------|------|
| `pms/run_sequenceParams.m` | Defaults for generic sequence simulations |
| `pms/run_sensorsParams.m` | Defaults for sensor-style simulations |
| `engine/build_sequence_model.m` | Builds the static sequence model for sequence batches |
| `engine/run_sequence.m` | Executes a generic sequence trial |
| `engine/run_sensors.m` | Executes a sensor-style trial |
| `engine/VB_MDP_X.m` | Variational solver wrapper / implementation |
| `utilites/run_mushiake_trial.m` | Custom Mushiake trial runner used by the sensor runner |
| `utilites/TEST_AY_2LEV_Mushiake.m` | Builds and runs the Mushiake two-level maze MDP |
| `utilites/mushiake_attach_single_step_recognition_level.m` | Adds the inner one-step recognition level used by supplementary Mushiake readouts |

### Trial description and persistence

| File | Role |
|------|------|
| `utilites/build_batch_description.m` | Creates batch labels from experiment parameters |
| `utilites/build_sequence_trial_description.m` | Creates sequence trial labels |
| `utilites/build_sensor_trial_description.m` | Creates sensor trial labels |
| `utilites/save_batch_metadata.m` | Saves batch metadata |
| `utilites/get_or_create_trial_seeds.m` | Stores/reuses trial seeds |
| `utilites/find_existing_trial_file.m` | Locates reusable saved trials |
| `utilites/load_sequence_trial_mdp.m` | Loads saved MDP trials for plotting |

### Collection and readout preparation

| File | Role |
|------|------|
| `utilites/Collect_Trial_Results.m` | Rebuilds collected sequence summaries from saved `MDP_*` files |
| `utilites/Collect_Sensor_Results.m` | Rebuilds collected sensor / maze summaries |
| `utilites/extract_sequence_trials.m` | Main plotting-side loader for sequence summaries |
| `utilites/extract_sequence_data_trials.m` | Loader for preprocessed readouts and sensor-style summaries |
| `utilites/build_sensor_trial_data.m` | Sensor readout reconstruction |
| `utilites/build_mushiake_trial_data.m` | Mushiake readout reconstruction, including outer and inner levels |
| `pms/extract_sequence_data_trialsParams.m` | Defaults for readout extraction and spike generation |

### Tuning and spike generation

| File | Role |
|------|------|
| `utilites/getCosineTuning.m` | Selects tuning function, tuning parameters, and default spike mode |
| `utilites/cosineTune.m` | Legacy cosine tuning |
| `utilites/cosineTuningStep.m` | Step-wise cosine tuning |
| `utilites/cosineTuneCircularBlocks.m` | Circular-block tuning used by maintained mains |
| `pms/cosineTuneCircularBlocksParams.m` | Defaults for circular-block tuning |
| `utilites/firingRatesToSpikes.m` | Central spike generator |

Supported spike modes include:

| Mode | Description |
|------|-------------|
| `legacy` | Original dense spike-generation rule |
| `legacy_logit_noise` | Logit/noise variant of the original rule |
| `thresholded_bernoulli` | Sparse thresholded Bernoulli spikes |
| `thresholded_refractory` | Thresholded Bernoulli spikes with refractory silence |

### Plotting

| File | Role |
|------|------|
| `plot/plot_sequence_firing_rate.m` | Sample firing-rate wrapper |
| `plot/plot_sequence_raster.m` | Sample raster wrapper |
| `utilites/HAI_ABC_XIE_FiringRate_L1.m` | Firing-rate renderer used by Chen/Xie/Mushiake sample plots |
| `utilites/HAI_ABCDEF_3LEV_SampleRaster.m` | Raster renderer for ABCDEF-style sequence plots |
| `plot/HAI_Mushiake_SampleRaster.m` | Mushiake raster renderer with factor/level-specific labels and colors |
| `plot/tileNeuronPolarByTypes.m` | Tiled polar summaries by sequence type |
| `plot/tileNeuronPolars6x3.m` | Xie-style tiled polar summary |
| `plot/BETA_pcaSpace.m` | PCA / geometry analysis path |
| `pms/BETA_pcaSpaceParams.m` | Defaults for PCA / geometry plots |
| `plot/plot_MAZE.m` | Mushiake maze schematic and action-path plotter |
| `utilites/set_visible_axes_title.m` | Helper for figure titles after plot creation |

## 4. Generic Sequence Pipeline

Used by:

- `Chen/MAIN_Chen01_S1S2S3_Forward_Exp.m`
- `Chen/MAIN_Chen01_S1S2S3_Backward_Exp.m`
- `Chen/MAIN_Chen02_S2_FwBw_Exp.m`
- `Chen/MAIN_Chen02_S2_FwBw_Exp_Supp.m`
- `Xie/MAIN_Xie_S3_Forward_Exp.m`
- `Xie/MAIN_Xie_S3_Forward_Exp_Supp.m`

Dependency chain:

```text
MAIN_*_Exp*.m
-> run_sequenceParams
-> build_batch_description
-> build_sequence_model
-> save_batch_metadata
-> get_or_create_trial_seeds
-> build_sequence_trial_description
-> run_sequence
-> Collect_Trial_Results
-> getCosineTuning
-> extract_sequence_trials
-> plot_sequence_firing_rate
-> plot_sequence_raster
-> tileNeuronPolarByTypes / tileNeuronPolars6x3
-> BETA_pcaSpace
```

## 5. Chen Simulations

### Chen01 forward and backward

`Chen/MAIN_Chen01_S1S2S3_Forward_Exp.m` and
`Chen/MAIN_Chen01_S1S2S3_Backward_Exp.m` run 1D, 2D, and 3D sequence families.
The forward main selects the forward 3D type mask; the backward main selects the
backward 3D type mask. Both use the shared sequence pipeline and generate:

- sample firing-rate plots
- sample raster plots
- polar summaries by symbolic rank
- PCA / geometry summaries through `BETA_pcaSpace`

### Chen01 sensors

`Chen/MAIN_Chen01_S1S2S3_Sensors_Exp.m` uses the sensor runner rather than
`run_sequence`.

Dependency chain:

```text
MAIN_Chen01_S1S2S3_Sensors_Exp
-> run_sensorsParams
-> run_sensors
-> Collect_Sensor_Results
-> extract_sequence_trials(usePreprocessedPopFR = true)
-> plot_sequence_firing_rate
-> plot_sequence_raster
-> tileNeuronPolarByTypes
-> BETA_pcaSpace
```

### Chen02 forward/backward

`Chen/MAIN_Chen02_S2_FwBw_Exp.m` runs 2D forward and backward branches with
policy-type priors. After collection, trials are split into forward and backward
subsets for sample plots, polar plots, and PCA summaries.

`Chen/MAIN_Chen02_S2_FwBw_Exp_Supp.m` uses the same structural pipeline with
equal forward/backward policy weights and supplementary plotting settings.

## 6. Xie Simulations

`Xie/MAIN_Xie_S3_Forward_Exp.m` runs a 3D forward-only sequence branch with
Xie-specific timing and plotting conventions.

`Xie/MAIN_Xie_S3_Forward_Exp_Supp.m` uses the same pipeline and adds
supplementary tuning/readout settings. Both Xie mains generate:

- sample firing-rate and raster plots
- polar summaries for the three symbolic ranks
- a 6-by-3 polar summary
- PCA / geometry summaries through `BETA_pcaSpace`

## 7. Mushiake Simulations

`Mushiake/MAIN_Mushiake_Exp.m` runs the AY maze simulation through the sensor
pipeline and a custom trial runner.

Dependency chain:

```text
MAIN_Mushiake_Exp
-> run_sensorsParams
-> run_sensors
-> run_mushiake_trial
-> TEST_AY_2LEV_Mushiake
-> Collect_Sensor_Results
-> build_mushiake_trial_data
-> mushiake_apply_readout_preset
-> extract_sequence_data_trials(usePreprocessedPopFR = true)
-> plot_mushiake_mazes
-> plot_sequence_firing_rate
-> plot_sequence_raster
```

`Mushiake/MAIN_Mushiake_Exp_Supp.m` extends this path by plotting both factors
and both readout levels:

- factor 1: maze states
- factor 2: actions
- outer level: the parent low-level MDP readout
- inner level: the single-step recognition readout attached under
  `MDP.mdp(1).mdp`

The supplementary Mushiake path depends on:

- `utilites/mushiake_attach_single_step_recognition_level.m`
- `utilites/build_mushiake_trial_data.m`
- `plot/HAI_Mushiake_SampleRaster.m`

## 8. Figure-Only Dependencies

Figure-only scripts depend on MATLAB graphics utilities and, when saving
figures, `hfigPrint` from TrialBox. They do not call:

- `run_sequence`
- `run_sensors`
- `Collect_Trial_Results`
- `Collect_Sensor_Results`
- `extract_sequence_trials`
- `BETA_pcaSpace`

Use them to recreate visual panels, task layouts, target schematics, or
published-data-style figures. Use the `MAIN_*_Exp*.m` files to run the model.

## 9. Output Structure

Simulation outputs are saved under `/TESTS/HAI_SEQUENCES/...` by default.
Typical directories contain:

- `MDP_*` trial files
- collected `Collect_*` summaries
- saved MATLAB figure handles
- PDF / FIG outputs for firing-rate, raster, polar, maze, and PCA figures

Batch metadata and trial seeds are saved so completed trials can be reused by
subsequent runs.
