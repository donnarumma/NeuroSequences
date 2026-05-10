# NeuroSequences

MATLAB repository for sequence-memory model simulations and companion figure-generation scripts.

The active `MAIN_*_Exp.m` entry points implement model simulations inspired by the framework described in the BioRxiv preprint:

- https://www.biorxiv.org/content/10.1101/2025.11.26.690672v1

These simulations are configured from experimental tasks reported in:

- `Chen` mains: Chen et al., Neuron (2024)
  - https://www.cell.com/neuron/fulltext/S0896-6273(24)00569-5
- `Mushiake` main: Mushiake et al., Neuron (2006)
  - https://www.cell.com/neuron/fulltext/S0896-6273(06)00272-8
- `Xie` main: Xie et al., Science (2022)
  - https://www.science.org/doi/10.1126/science.abm0204

## Repository Roles

This repository contains two different kinds of scripts.

### 1. Model simulations

These are the maintained entry points for running batches, collecting trial results, building readouts, and generating sample and PCA plots.

- `Chen/MAIN_Chen01_S1S2S3_Forward_Exp.m`
  - Chen01 forward-only simulation across 1D, 2D, and 3D sequence families.
- `Chen/MAIN_Chen01_S1S2S3_Backward_Exp.m`
  - Chen01 backward-only simulation across 1D, 2D, and 3D sequence families.
- `Chen/MAIN_Chen01_S1S2S3_Sensors_Exp.m`
  - Chen01 sensory / neutral control branch using preprocessed sensor readouts.
- `Chen/MAIN_Chen02_S2_FwBw_Exp.m`
  - Chen02 2D forward/backward simulation with explicit policy-type priors.
- `Xie/MAIN_Xie_S3_Forward_Exp.m`
  - Xie-style 3D forward-only simulation.
- `Mushiake/MAIN_Mushiake_Exp.m`
  - Mushiake AY maze branch using the sensor runner and a custom trial/readout path.

### 2. Figure-only reproductions

These scripts are not model simulations. They are used to print or sketch figure layouts that resemble published data figures.

- `Chen/chenForward.m`
- `Chen/chenBackward.m`
- `Chen/chenSensory.m`
- `Xie/xie.m`

They are useful for figure reproduction, but they are not part of the generative-model simulation pipeline.

## Current Simulation Pipeline

The maintained `MAIN_*_Exp.m` scripts follow a common structure.

### 1. Batch configuration

Sequence experiments start from:

- `pms/run_sequenceParams.m`
- `engine/build_sequence_model.m`
- `utilites/build_batch_description.m`

Sensor-style experiments start from:

- `pms/run_sensorsParams.m`
- `engine/run_sensors.m`

### 2. Trial execution

Sequence-model batches are executed through:

- `engine/run_sequence.m`

Sensor / control batches are executed through:

- `engine/run_sensors.m`

The `Mushiake` branch uses the sensor runner with a custom trial runner:

- `utilites/run_mushiake_trial.m`

### 3. Trial collection

Collected trial summaries are rebuilt from saved `MDP_*` files through:

- `utilites/Collect_Trial_Results.m`
- `utilites/Collect_Sensor_Results.m`

### 4. Readout construction

The preferred plotting-side loader is now:

- `utilites/extract_sequence_trials.m`

This function prepares:

- `PopRates`
- `firingRates`
- `Spikes`
- `timePopRates`
- `timeFiringRates`
- `timeSpikes`

and supports both:

- direct sequence readouts
- preprocessed sensor / maze readouts via `usePreprocessedPopFR = true`

Its defaults are defined in:

- `pms/extract_sequence_data_trialsParams.m`

### 5. Tuning and spike generation

The maintained mains route readout configuration through:

- `utilites/getCosineTuning.m`

The current tuning menu includes:

- no tuning
- legacy `cosineTune`
- `cosineTuningStep`
- `cosineTuneCircularBlocks`

The circular-block implementation is:

- `utilites/cosineTuneCircularBlocks.m`
- `pms/cosineTuneCircularBlocksParams.m`

Spike generation is centralized in:

- `utilites/firingRatesToSpikes.m`

Supported modes include:

- `legacy`
- `legacy_logit_noise`
- `thresholded_bernoulli`
- `thresholded_refractory`

### 6. Plotting and geometry

Sample-level plots use:

- `plot/plot_sequence_firing_rate.m`
- `plot/plot_sequence_raster.m`

Polar plots typically use:

- `plot/tileNeuronPolarByTypes.m`
- `plot/plotNeuronPolarByCondition.m`

PCA summaries use:

- `plot/BETA_pcaSpace.m`
- `pms/BETA_pcaSpaceParams.m`

This is now the maintained PCA path for the sequence branches. It replaces the old `BETA_pca` workflow for the active Chen and Xie mains.

## Important Branch-Specific Notes

### Chen01 / Chen02 / Xie

These branches use the generic sequence workflow:

- `run_sequence`
- `Collect_Trial_Results`
- `extract_sequence_trials`
- `plot_sequence_firing_rate`
- `plot_sequence_raster`
- `BETA_pcaSpace`

### Chen01 Sensors

The sensory branch is special because cosine-smoothed sensor readouts are already assembled upstream during sensor collection. In practice:

- `Collect_Sensor_Results` rebuilds the sensor trial summaries
- `extract_sequence_trials(..., usePreprocessedPopFR = true)` extends those preprocessed readouts for sample plots and PCA

### Mushiake

`MAIN_Mushiake_Exp.m` uses the sensor runner but a custom task and readout path:

- `run_mushiake_trial`
- `build_mushiake_trial_data`
- `mushiake_apply_readout_preset`

At the moment, the active path in `MAIN_Mushiake_Exp.m` focuses on trial execution, maze plotting, and sample plots. A legacy PCA block is still present after an early `return`, so it is not part of the active execution path.

## External Dependencies

The repository depends on:

- `HAI_LANGUAGE`
  - hierarchical active-inference utilities and HAI helper functions
  - https://github.com/donnarumma/HAI_LANGUAGE
- `TrialBox`
  - parameter-resolution helper `resolveFunctionParams`
  - https://github.com/donnarumma/TrialBox
- `SPM`
  - active-inference / MDP utilities used by the VB solvers
  - https://www.fil.ion.ucl.ac.uk/spm/

Make sure these dependencies are on the MATLAB path before running the mains.

## Outputs

Most simulations save results under:

- `/TESTS/HAI_SEQUENCES/...`

A typical batch contains:

- `MDP_*` trial files
- `Collect_*` summary files
- sample firing-rate and raster PDFs / FIGs
- PCA summary PDFs / FIGs

The mains are written to reuse already existing trial files when possible, so interrupted batches can be resumed safely.

## Related Documentation

- `DEPENDENCY_ANALYSIS.md`
  - current dependency map for the active mains and the figure-only scripts
