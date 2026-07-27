# NeuroSequences

MATLAB code for running sequence-memory model simulations and generating
model-derived figures inspired by experimental sequence tasks.

The repository is organized around two kinds of files:

- `MAIN_*_Exp*.m` scripts run the computational model, collect trials, build
  firing-rate/spike readouts, and save simulation figures.
- Non-`MAIN` Chen, Xie, and Mushiake scripts recreate paper-style figure panels
  and task schematics. They are visualization helpers, not model simulations.

The simulation tasks are based on experimental paradigms from:

- Chen et al., Neuron (2024): <https://www.cell.com/neuron/fulltext/S0896-6273(24)00569-5>
- Mushiake et al., Neuron (2006): <https://www.cell.com/neuron/fulltext/S0896-6273(06)00272-8>
- Xie et al., Science (2022): <https://www.science.org/doi/10.1126/science.abm0204>

The model framework is described in the associated BioRxiv preprint:

- <https://www.biorxiv.org/content/10.1101/2025.11.26.690672v1>

## Simulation Entry Points

The maintained simulation scripts are the `MAIN_*_Exp*.m` files.

### Chen

- `Chen/MAIN_Chen01_S1S2S3_Forward_Exp.m`
  - Forward sequence simulation across 1D, 2D, and 3D sequence families.
- `Chen/MAIN_Chen01_S1S2S3_Backward_Exp.m`
  - Backward sequence simulation across 1D, 2D, and 3D sequence families.
- `Chen/MAIN_Chen01_S1S2S3_Sensors_Exp.m`
  - Sensory / neutral control simulation using the sensor runner and
    preprocessed sensor readouts.
- `Chen/MAIN_Chen02_S2_FwBw_Exp.m`
  - Chen02 2D forward/backward simulation with policy-type priors.
- `Chen/MAIN_Chen02_S2_FwBw_Exp_Supp.m`
  - Supplementary Chen02 forward/backward simulation with equal
    forward/backward policy weights and supplementary plotting settings.

### Xie

- `Xie/MAIN_Xie_S3_Forward_Exp.m`
  - Xie-style 3D forward simulation using the generic sequence pipeline.
- `Xie/MAIN_Xie_S3_Forward_Exp_Supp.m`
  - Supplementary Xie 3D forward simulation with adjusted tuning/readout and
    supplementary figure outputs.

### Mushiake

- `Mushiake/MAIN_Mushiake_Exp.m`
  - Mushiake AY maze simulation using the sensor runner, a custom maze trial
    runner, maze plots, and sample firing-rate/raster figures.
- `Mushiake/MAIN_Mushiake_Exp_Supp.m`
  - Supplementary Mushiake simulation that compares outer and inner readout
    levels for maze state and action factors.

## Figure-Only Scripts

These scripts recreate publication-style layouts or schematics with MATLAB
graphics. They do not run the generative model and should not be used as
simulation entry points.

### Chen figure helpers

- `Chen/Chen01_Forward.m`
- `Chen/Chen01_Backward.m`
- `Chen/Chen01_Sensory.m`
- `Chen/Chen01_Exp.m`
- `Chen/Chen02_FwdBwd.m`
- `Chen/Chen02_Exp.m`

### Xie figure helpers

- `Xie/Xie_Exp.m`
- `Xie/Xie_Target.m`
- `Xie/Xie_Exagons.m`

### Mushiake figure helpers

- `Mushiake/Mushiake_Spikes.m`

## Core Pipeline

Most sequence simulations follow this path:

```text
MAIN_*_Exp*.m
-> run_sequenceParams
-> build_sequence_model
-> run_sequence
-> Collect_Trial_Results
-> extract_sequence_trials
-> plot_sequence_firing_rate
-> plot_sequence_raster
-> tileNeuronPolarByTypes
-> BETA_pcaSpace
```

Sensor-style and maze simulations use:

```text
MAIN_*_Exp*.m
-> run_sensorsParams
-> run_sensors
-> custom trial runner when needed
-> Collect_Sensor_Results
-> extract_sequence_trials or extract_sequence_data_trials
-> plot_sequence_firing_rate
-> plot_sequence_raster
```

The Mushiake branch adds:

- `utilites/run_mushiake_trial.m`
- `utilites/build_mushiake_trial_data.m`
- `utilites/mushiake_apply_readout_preset.m`
- `utilites/mushiake_attach_single_step_recognition_level.m`
- `plot/plot_MAZE.m`

## Readouts and Plotting

The plotting-side readout functions prepare population firing rates, single-unit
firing rates, spikes, and matching time axes:

- `utilites/extract_sequence_trials.m`
- `utilites/extract_sequence_data_trials.m`
- `utilites/build_mushiake_trial_data.m`

Spike generation is centralized in:

- `utilites/firingRatesToSpikes.m`

Tuning options are selected through:

- `utilites/getCosineTuning.m`

The maintained sample plotting wrappers are:

- `plot/plot_sequence_firing_rate.m`
- `plot/plot_sequence_raster.m`

The maintained PCA and geometry path is:

- `plot/BETA_pcaSpace.m`
- `pms/BETA_pcaSpaceParams.m`

## External Dependencies

Before running the simulation mains, add these dependencies to the MATLAB path:

- `HAI_LANGUAGE`: hierarchical active-inference utilities and helper functions.
  <https://github.com/donnarumma/HAI_LANGUAGE>
- `TrialBox`: parameter-resolution and figure-export utilities, including
  `resolveFunctionParams` and `hfigPrint`.
  <https://github.com/donnarumma/TrialBox>
- `SPM`: active-inference / MDP solver support.
  <https://www.fil.ion.ucl.ac.uk/spm/>

## Outputs

Simulation outputs are written under `/TESTS/HAI_SEQUENCES/...` by default.
Typical output folders contain:

- saved `MDP_*` trial files
- collected `Collect_*` summaries
- sample firing-rate and raster figures
- maze figures for Mushiake simulations
- polar and PCA summary figures for sequence simulations

Existing trial files are reused by the mains when possible, so interrupted
batches can be resumed without regenerating completed trials.

## Additional Documentation

- `DEPENDENCY_ANALYSIS.md`
  - dependency map for the simulation mains, readout utilities, plotting
    wrappers, and figure-only scripts.
