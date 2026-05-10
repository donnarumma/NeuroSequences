# Sequence Simulations and Modelling

This repository contains MATLAB simulations for sequence planning, working
memory, and related control tasks. The active workflow now uses a generic
pipeline for running batches, collecting trials, and producing sample and
PCA plots.

## Setup

1. Clone and add to the MATLAB path:

   - `https://github.com/donnarumma/HAI_LANGUAGE`
   - `https://github.com/donnarumma/TrialBox`

2. Add this repository to the MATLAB path.

3. Make sure the helper functions used by the experiments are visible on
   the path as well.

## Active Main Scripts

These are the main scripts currently maintained in the generic workflow.

- `Chen/MAIN_Chen01_Forward.m`
  Runs the Chen01 variable-length sequence experiment in the forward-only
  setting. It includes 3D, 2D, and 1D sequence families, collects trial
  results, generates example sample plots with `SAMPLE_Sequence`, and runs
  PCA summaries with `BETA_pca`.

- `Chen/MAIN_Chen01_Backward.m`
  Runs the Chen01 variable-length sequence experiment in the backward-only
  setting. It is the backward counterpart of the forward main and follows
  the same generic execution and plotting pipeline.

- `Chen/MAIN_Chen02_FwBw.m`
  Runs the Chen02 fixed-length 2D experiment with both forward and
  backward policies enabled. This main also supports explicit policy-type
  priors, for example to favour forward policies over backward ones.

- `Chen/MAIN_Chen01_Sensors.m`
  Runs the sensor/neutral control experiment using the generic plotting
  tools where possible, while keeping the dedicated `run_sensors`
  execution path for this model family.

## Generic Simulation Pipeline

### Batch execution

The generic sequence batch runner is:

`engine/run_sequence.m`

This is the reference implementation for the current Chen/Xie-style
sequence simulations. It is the main entry point for executing one trial
once the static generative model has already been built.

Reference point for this formulation:

- `https://www.biorxiv.org/content/10.1101/2025.11.26.690672v1`

### Static model construction

The shared model for all trials in a batch is built by:

- `engine/build_sequence_model.m`

This function constructs:

- the admissible temporal-order types such as `fw` and `bw`
- the active sequence families such as `3D`, `2D`, and `1D`
- the hidden-state transition matrices `B`
- the likelihood matrices `A`
- the priors `D`
- the policy matrix `V`
- the task, state, and observation labels used later in execution and
  plotting

### Trial execution

For each trial, the main script sets:

- `pms.iTrial`
- `pms.irng`
- `pms.trialDescription`

Then `run_sequence`:

- selects the corresponding task from the prebuilt `sequenceModel`
- builds the initial hidden-state trajectory
- builds preferences `C`
- optionally builds a policy prior `E`
- runs `VB_MDP_X`
- saves the resulting `MDP` file

### Collection and post-processing

After a batch finishes, the workflow collects and validates the saved
trials directly from the `MDP_*` files.

Main collection entry points:

- `utilites/Collect_Trial_Results.m`
- `utilites/Collect_Sensor_Results.m`

The generic post-hoc tools are:

- `plot/SAMPLE_Sequence.m`
  Generates firing-rate and raster plots for selected trials.

- `plot/BETA_pca.m`
  Generates PCA summaries such as polygons, trajectories, and time plots.

## Parameter Files

The main parameter entry points are:

- `pms/run_sequenceParams.m`
  Default parameters for sequence batches and single-trial execution.

- `pms/run_sensorsParams.m`
  Default parameters for the sensor experiment.

- `pms/SAMPLE_SequenceParams.m`
  Default parameters for sample firing-rate and raster plots.

- `pms/BETA_pcaParams.m`
  Default parameters for PCA analyses and PCA figure export.

Each main script starts from one of these defaults and then overrides only
the parameters that are specific to the experiment.

## Output Structure

The current workflow writes results into deterministic batch folders under
`~/TESTS/HAI_SEQUENCES/...`.

For sequence experiments, a batch typically contains:

- `sequenceModel.mat`
- `trialSeeds.mat`
- one `MDP_*` file per executed trial
- one `Collect_*` summary file
- sample figures and PCA figures if saving is enabled

Before executing a trial, the main script checks whether a matching file
already exists. If so, the trial is reused instead of rerun. This makes it
easy to resume interrupted batches.

## Naming Scheme

The folder and file names are designed to encode the main simulation
choices:

- experiment label
- target set
- active sequence families
- forward/backward availability
- policy count
- optional policy-prior identifiers

For example, if a non-uniform type prior is used in a forward/backward
experiment:

- `pms.policyTypeWeights = [10, 1]`

then the generated names include a token such as:

- `PTfw10_bw1`

This allows different prior settings to be stored in separate folders and
matched again when reusing trials.

## Typical Usage

To run one of the maintained simulations, open MATLAB with the repository
and dependencies on the path, then launch one of the main scripts, for
example:

- `Chen/MAIN_Chen01_Forward.m`
- `Chen/MAIN_Chen01_Backward.m`
- `Chen/MAIN_Chen02_FwBw.m`
- `Chen/MAIN_Chen01_Sensors.m`

Each script:

1. builds or reloads the batch configuration
2. creates or reloads one seed per trial
3. skips already-saved matching trials
4. runs missing trials
5. collects results
6. optionally produces sample and PCA figures

## References

- Xie, Y. et al. (2022). *Geometry of sequence working memory in macaque
  prefrontal cortex*. Science, 375(6581), 632-639.

- Chen, J. et al. (2024). *Flexible control of sequence working memory in
  the macaque frontal cortex*. Neuron, 112(20), 3502-3514.

- Current sequence-runner reference point:
  `https://www.biorxiv.org/content/10.1101/2025.11.26.690672v1`
