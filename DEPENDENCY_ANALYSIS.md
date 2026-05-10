# NeuroSequences Dependency Analysis

**Analysis date:** May 10, 2026  
**Repository:** `~/tools/NeuroSequences`

## Executive Summary

The repository currently contains:

- 6 active `MAIN_*_Exp.m` simulation entry points
- 4 figure-only reproduction scripts
- 3 external dependency families
  - `HAI_LANGUAGE`
  - `TrialBox`
  - `SPM`

The maintained simulation workflow is now built around:

- `run_sequence` or `run_sensors`
- `Collect_Trial_Results` or `Collect_Sensor_Results`
- `extract_sequence_trials`
- `plot_sequence_firing_rate`
- `plot_sequence_raster`
- `BETA_pcaSpace`

The older `SAMPLE_Sequence` / `BETA_pca` path is no longer the primary path for the active Chen and Xie mains. `Mushiake` still contains a legacy PCA block, but that block is currently inactive because the script returns earlier.

## 1. Entry Points

### Active model simulations

| File | Family | Purpose |
|------|--------|---------|
| `Chen/MAIN_Chen01_S1S2S3_Forward_Exp.m` | Chen | Forward-only simulation across 1D, 2D, 3D sequence families |
| `Chen/MAIN_Chen01_S1S2S3_Backward_Exp.m` | Chen | Backward-only simulation across 1D, 2D, 3D sequence families |
| `Chen/MAIN_Chen01_S1S2S3_Sensors_Exp.m` | Chen | Sensory / neutral control branch |
| `Chen/MAIN_Chen02_S2_FwBw_Exp.m` | Chen | 2D forward/backward branch with policy-type priors |
| `Xie/MAIN_Xie_S3_Forward_Exp.m` | Xie | 3D forward-only branch |
| `Mushiake/MAIN_Mushiake_Exp.m` | Mushiake | AY maze branch using the sensor runner |

### Figure-only scripts

These do not run the model. They generate printed or stylized figure reproductions.

| File | Role |
|------|------|
| `Chen/chenForward.m` | forward figure sketch / reproduction |
| `Chen/chenBackward.m` | backward figure sketch / reproduction |
| `Chen/chenSensory.m` | sensory figure sketch / reproduction |
| `Xie/xie.m` | Xie polygon-style figure reproduction |

## 2. External Dependencies

### HAI_LANGUAGE

**Repository:** `https://github.com/donnarumma/HAI_LANGUAGE`

Main roles in this project:

- default HAI parameter setup
- hierarchical active-inference execution
- MDP-to-firing-rate helper functions
- rate extension and plotting-side helpers

Examples used directly or indirectly:

- `HAI_DefaultParams`
- `HAI_initialiseParams`
- `HAI_RUN`
- `HAI_smartMDP`
- `HAI_extendFiringRates`

### TrialBox

**Repository:** `https://github.com/donnarumma/TrialBox`

Main role in this project:

- parameter resolution via `resolveFunctionParams`

This is used extensively by the newer parameterized helper functions and plotting utilities.

### SPM

**Project:** `https://www.fil.ion.ucl.ac.uk/spm/`

Main role in this project:

- active-inference / MDP solver support and utility functions

Examples used in the solver path:

- `spm_MDP_check`
- `spm_MDP_VB_X`
- `spm_dot`
- `spm_softmax`

## 3. Core Internal Modules

### Execution layer

| File | Role |
|------|------|
| `engine/run_sequence.m` | execute one generic sequence trial |
| `engine/run_sensors.m` | execute one sensor-style trial |
| `engine/build_sequence_model.m` | build the static sequence model for a batch |
| `engine/VB_MDP_X.m` | main variational solver wrapper / implementation |

### Collection layer

| File | Role |
|------|------|
| `utilites/Collect_Trial_Results.m` | rebuild collected sequence trial summaries from saved `MDP_*` files |
| `utilites/Collect_Sensor_Results.m` | rebuild collected sensor-style trial summaries |
| `utilites/build_mushiake_trial_data.m` | Mushiake readout reconstruction |
| `utilites/build_sensor_trial_data.m` | sensor readout reconstruction |

### Readout preparation

| File | Role |
|------|------|
| `utilites/extract_sequence_trials.m` | maintained loader / expander for plotting-side `data_trials` |
| `pms/extract_sequence_data_trialsParams.m` | defaults for readout extraction and spike generation |
| `utilites/firingRatesToSpikes.m` | centralized spike generator with legacy and newer modes |
| `utilites/getCosineTuning.m` | select tuning function, tuning parameters, and default spike mode |
| `utilites/cosineTuneCircularBlocks.m` | block-circular tuning implementation |

### Plotting and geometry

| File | Role |
|------|------|
| `plot/plot_sequence_firing_rate.m` | maintained sample firing-rate wrapper |
| `plot/plot_sequence_raster.m` | maintained sample raster wrapper |
| `plot/tileNeuronPolarByTypes.m` | tiled polar plots by symbolic step |
| `plot/BETA_pcaSpace.m` | maintained PCA / geometry analysis path |
| `pms/BETA_pcaSpaceParams.m` | self-contained defaults for `BETA_pcaSpace` |

## 4. Shared Sequence Pipeline

This is the common path for:

- `Chen/MAIN_Chen01_S1S2S3_Forward_Exp.m`
- `Chen/MAIN_Chen01_S1S2S3_Backward_Exp.m`
- `Chen/MAIN_Chen02_S2_FwBw_Exp.m`
- `Xie/MAIN_Xie_S3_Forward_Exp.m`

### Dependency chain

```text
MAIN_*_Exp
-> run_sequenceParams
-> build_batch_description
-> build_sequence_model
-> save_batch_metadata / get_or_create_trial_seeds
-> build_sequence_trial_description
-> run_sequence
-> Collect_Trial_Results
-> getCosineTuning
-> extract_sequence_trials
-> plot_sequence_firing_rate
-> plot_sequence_raster
-> tileNeuronPolarByTypes
-> BETA_pcaSpace
```

### Important notes

- `extract_sequence_trials` is the maintained readout-preparation entry point.
- `getCosineTuning` now controls both tuning choice and the default spike mode returned to the mains.
- The active mains typically use `PopRates` for polar plots and PCA summaries.
- `BETA_pcaSpace` is the maintained PCA path for these branches.

## 5. Chen01 Forward / Backward

### `Chen/MAIN_Chen01_S1S2S3_Forward_Exp.m`

Key settings:

- `include3D = true`
- `include2D = true`
- `include1D = true`
- `typeMask3D = [1 0 0 0 0 0]`

Readout / plotting path:

- `getCosineTuning(tunemode)`
- `extract_sequence_trials`
- sample firing-rate and raster plots
- polar plots over `type1:type3`
- `BETA_pcaSpace`

### `Chen/MAIN_Chen01_S1S2S3_Backward_Exp.m`

Same structure as forward, with:

- `typeMask3D = [0 0 0 0 0 1]`

It also uses the maintained `BETA_pcaSpace` path and sequence-style legacy compatibility settings for some `PcaTime` layout details.

## 6. Chen02 Forward / Backward

### `Chen/MAIN_Chen02_S2_FwBw_Exp.m`

This main uses the same sequence pipeline, but with a different batch definition:

- 2D families only
- fixed minimum sequence length of 2
- both forward and backward trial types
- non-uniform `policyTypeWeights = [10, 1]`

Extra dependency detail:

- the collected batch is split into forward and backward subsets after collection
- both subsets are passed separately to `BETA_pcaSpace`
- the PCA branch uses `pcaNeuronSelectionMode = 'matched_step_blocks'`

## 7. Xie Forward

### `Xie/MAIN_Xie_S3_Forward_Exp.m`

This is structurally the same maintained sequence path as the Chen01 forward branch, with Xie-specific figure and timing conventions.

Key chain:

```text
MAIN_Xie_S3_Forward_Exp
-> run_sequenceParams
-> build_sequence_model
-> run_sequence
-> Collect_Trial_Results
-> getCosineTuning
-> extract_sequence_trials
-> plot_sequence_firing_rate / plot_sequence_raster
-> tileNeuronPolarByTypes
-> BETA_pcaSpace
```

## 8. Chen Sensors

### `Chen/MAIN_Chen01_S1S2S3_Sensors_Exp.m`

This branch differs from the generic sequence mains because it uses the sensor runner and preprocessed readouts.

### Dependency chain

```text
MAIN_Chen01_S1S2S3_Sensors_Exp
-> run_sensorsParams
-> run_sensors
-> Collect_Sensor_Results
-> extract_sequence_trials(usePreprocessedPopFR = true)
-> plot_sequence_firing_rate
-> plot_sequence_raster
-> add_sensor_type_fields
-> tileNeuronPolarByTypes
-> BETA_pcaSpace
```

### Important notes

- cosine-shaped sensor readouts are already assembled upstream during collection
- `extract_sequence_trials(..., usePreprocessedPopFR = true)` extends those preprocessed population responses and generates `PopRates`, `firingRates`, and `Spikes`
- the branch uses sensor-style compatibility settings in `BETA_pcaSpace`
- symbolic fields such as `type1:type3` are reconstructed locally for the generic polar plotters

## 9. Mushiake

### `Mushiake/MAIN_Mushiake_Exp.m`

This branch is the main exception in the repository.

### Active dependency chain

```text
MAIN_Mushiake_Exp
-> run_sensorsParams
-> run_sensors
-> run_mushiake_trial
-> Collect_Sensor_Results
-> build_mushiake_trial_data
-> mushiake_apply_readout_preset
-> plot_mushiake_mazes
-> extract_sequence_data_trials(usePreprocessedPopFR = true)
-> plot_sequence_firing_rate
-> plot_sequence_raster
```

### Important notes

- `run_sensors` is reused, but trial execution is redirected through `run_mushiake_trial`
- maze plotting is part of the main active path
- sample plots use preprocessed Mushiake readouts
- a legacy PCA block using `BETA_pca` still exists below an early `return`
- because of that `return`, the active path currently does not execute PCA

## 10. Tuning and Spike-Generation Dependencies

The newer mains rely on the combination:

```text
getCosineTuning
-> chosen cosine function
-> cosine parameter struct
-> default spikeGenerationMode
-> firingRatesToSpikes
```

### Current maintained spike modes

| Mode | Meaning |
|------|---------|
| `legacy` | original dense Bernoulli-like rule |
| `legacy_logit_noise` | old alternative logit/noise rule |
| `thresholded_bernoulli` | sparse thresholded Bernoulli spikes |
| `thresholded_refractory` | thresholded Bernoulli with refractory silence |

### Current maintained cosine modes

| Mode | Main implementation |
|------|---------------------|
| no tuning | identity / empty function |
| legacy cosine | `cosineTune` |
| step cosine | `cosineTuningStep` |
| circular blocks | `cosineTuneCircularBlocks` |

## 11. Figure-Only Script Dependencies

These scripts are lightweight compared with the simulation mains.

### Chen figure reproductions

- `Chen/chenForward.m`
- `Chen/chenBackward.m`
- `Chen/chenSensory.m`

Typical direct dependencies:

- `plotPCAHexagonTraj`
- `hfigPrint`
- basic MATLAB plotting functions

They do not call:

- `run_sequence`
- `run_sensors`
- `Collect_*`
- `extract_sequence_trials`
- `BETA_pcaSpace`

### Xie figure reproduction

- `Xie/xie.m`

Typical direct dependencies:

- `linspecer`
- `hfigPrint`
- basic MATLAB plotting functions

This script is also figure-only and not connected to the model simulation pipeline.

## 12. Practical Interpretation

If the goal is:

- to run the model
  - start from one of the 6 `MAIN_*_Exp.m` files
- to reproduce stylized publication-like figures without rerunning the model
  - use `chenForward`, `chenBackward`, `chenSensory`, or `xie`

If the goal is to follow the maintained analysis path, the most important functions to inspect are:

- `run_sequence`
- `run_sensors`
- `Collect_Trial_Results`
- `Collect_Sensor_Results`
- `extract_sequence_trials`
- `firingRatesToSpikes`
- `getCosineTuning`
- `BETA_pcaSpace`
