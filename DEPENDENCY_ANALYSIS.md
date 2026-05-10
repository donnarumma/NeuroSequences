# MATLAB Sequences Project - Dependency Analysis Report

**Analysis Date:** April 24, 2026  
**Project Location:** `/home/donnarumma/OneDrive/tools/Sequences/`

---

## Executive Summary

The Sequences project is a MATLAB simulation framework for sequence planning and working memory tasks. It depends on **two external projects** (HAI_LANGUAGE and TrialBox) and the **SPM library** (Statistical Parametric Mapping). The project contains **6 active MAIN_*.m entry points** organized in 3 locations (Chen, Xie, Mushiake).

---

## 1. All MAIN_*.m Files in the Project

| File | Location | Status | Type |
|------|----------|--------|------|
| MAIN_Chen01_S1S2S3_Backward.m | Chen/ | Active | Sequence – Backward only |
| MAIN_Chen01_S1S2S3_Forward.m | Chen/ | Active | Sequence – Forward only |
| MAIN_Chen01_S1S2S3_Sensors.m | Chen/ | Active | Sensor/Neutral control |
| MAIN_Chen02_S2_FwBw.m | Chen/ | Active | Sequence – 2D, Fw+Bw |
| MAIN_Mushiake.m | Mushiake/ | Active | AY 2-Level Maze task |
| MAIN_Xie_S3_Forward.m | Xie/ | Active | Sequence – Forward 3D |

**Total Active:** 6

---

## 2. Dependency Chains for Each MAIN_*.m

### **ACTIVE SCRIPTS** (Chen, Xie, Mushiake)

#### **Chen/MAIN_Chen01_S1S2S3_Backward.m**

**Execution Flow:**
```
MAIN_Chen01_S1S2S3_Backward
├── run_sequenceParams()                    [Internal: pms/]
├── build_batch_description()               [Internal: utilites/]
├── build_sequence_model()                  [Internal: engine/]
│   ├── build_type_info()                   [Internal: engine/]
│   ├── build_family_specs()                [Internal: engine/]
│   └── SequenceTransitions()               [Internal: utilites/]
├── build_sequence_trial_description()      [Internal: utilites/]
├── run_sequence()                          [Internal: engine/]
│   ├── resolveFunctionParams()             [EXTERNAL: TrialBox]
│   ├── HAI_DefaultParams()                 [EXTERNAL: HAI_LANGUAGE]
│   ├── HAI_initialiseParams()              [EXTERNAL: HAI_LANGUAGE]
│   └── VB_MDP_X()                          [Internal: engine/]
│       ├── spm_MDP_check()                 [EXTERNAL: SPM]
│       └── spm_MDP_VB_H / spm_MDP_VB_X()   [EXTERNAL: SPM]
├── Collect_Trial_Results()                 [Internal: utilites/]
├── extract_sequence_data_trialsParams()    [Internal: pms/]
├── plot_sequence_firing_rateParams()       [Internal: pms/]
├── plot_sequence_firing_rate()             [Internal: plot/]
└── BETA_pca()                              [Internal: plot/]
```

**Dependencies Classification:**
- **Internal Sequences:** 12 functions
- **External HAI_LANGUAGE:** 2 functions
- **External TrialBox:** 1 function (resolveFunctionParams)
- **External SPM:** 2+ functions

---

#### **Chen/MAIN_Chen01_S1S2S3_Forward.m**

Identical structure to MAIN_Chen01_S1S2S3_Backward.m (same pipeline, only `typeMask3D` differs to select forward-only order templates).

**Key Differences:**
- `typeMask3D = logical([1 0 0 0 0 0])` (forward-only)

---

#### **Chen/MAIN_Chen01_S1S2S3_Sensors.m**

**Execution Flow:**
```
MAIN_Chen01_S1S2S3_Sensors
├── run_sensorsParams()                     [Internal: pms/]
├── feval(runPms.dictionary)                → DICTIONARY_ABCDEF_Neutral_2LEV()  [Internal: utilites/]
├── build_sensor_trial_description()        [Internal: utilites/]
├── run_sensors()                           [Internal: engine/]
│   ├── HAI_initialiseParams()              [EXTERNAL: HAI_LANGUAGE]
│   ├── HAI_DefaultParams()                 [EXTERNAL: HAI_LANGUAGE]
│   ├── resolveFunctionParams()             [EXTERNAL: TrialBox]
│   └── vb_infer_lower_level() / VB_MDP_X()  [Internal/External]
├── Collect_Sensor_Results()                [Internal: utilites/]
├── extract_sequence_data_trialsParams()    [Internal: pms/]
└── plot_sequence_firing_rate(), etc.       [Internal: plot/]
```

**Dependencies Classification:**
- **Internal Sequences:** 9 functions
- **External HAI_LANGUAGE:** 2 functions
- **External TrialBox:** 1 function
- **External SPM:** 1+ function (via VB_MDP_X)

---

#### **Chen/MAIN_Chen02_S2_FwBw.m**

**Execution Flow:**
Same as MAIN_Chen01_S1S2S3_Backward with different model configuration:
- Only 2D sequences enabled: `include2D = true; include3D = false`
- Policy type priors: `policyTypeWeights = [10, 1]` (favors forward)

---

#### **Mushiake/MAIN_Mushiake.m**

**Execution Flow:**
```
MAIN_Mushiake
├── run_sensorsParams()                     [Internal: pms/]
├── run_sensors()                           [Internal: engine/]
│   └── (uses trialRunner = 'run_mushiake_trial')
│       ├── run_mushiake_trial()            [Internal: utilites/]
│       │   └── TEST_AY_2LEV_Mushiake()     [Internal: utilites/]
│       │       ├── HAI_DefaultParams()     [EXTERNAL: HAI_LANGUAGE]
│       │       ├── HAI_initialiseParams()  [EXTERNAL: HAI_LANGUAGE]
│       │       ├── MAZE_Mushiake()         [Internal: utilites/]
│       │       ├── mushiake_get_all_state_sequences()  [Internal: utilites/]
│       │       └── run_hai_trial()         [Internal: utilites/]
│       │           ├── HAI_RUN()           [EXTERNAL: HAI_LANGUAGE]
│       │           └── HAI_smartMDP()      [EXTERNAL: HAI_LANGUAGE]
│       └── spm_MDP_VB_X() / VB_MDP_X()     [External/Internal]
├── Collect_Sensor_Results()                [Internal: utilites/]
├── build_mushiake_trial_data()             [Internal: utilites/]
├── mushiake_apply_readout_preset()         [Internal: utilites/]
├── plot_mushiake_mazes()                   [Internal: Mushiake/MAIN_Mushiake.m]
└── extract_sequence_data_trialsParams()    [Internal: pms/]
```

**Dependencies Classification:**
- **Internal Sequences:** 12 functions
- **External HAI_LANGUAGE:** 5 functions (HAI_DefaultParams, HAI_initialiseParams, HAI_RUN, HAI_smartMDP, and potentially spm_MDP_VB_X)
- **External TrialBox:** 1 function (resolveFunctionParams, indirectly via run_sensors)

---

#### **Xie/MAIN_Xie_S3_Forward.m**

Same pipeline as Chen series with custom parameters:
- Legacy Seq3_Fwd GoToTarget layout preservation
- `nStayStates = 7` (instead of default)
- 3D forward-only: `typeMask3D = logical([1 0 0 0 0 0])`

**Dependencies:** Identical to MAIN_Chen01_S1S2S3_Forward.m

---

## 3. External Dependency Summary

### **Dependency 1: HAI_LANGUAGE**

**Location:** `~/tools/HAI_LANGUAGE/`  
**GitHub:** https://github.com/donnarumma/HAI_LANGUAGE

**Functions Used from HAI_LANGUAGE:**
- `HAI_DefaultParams()` – Construct default parameter structures
- `HAI_initialiseParams()` – Initialize hierarchical inference parameters
- `HAI_RUN()` – Execute hierarchical active inference
- `HAI_smartMDP()` – Post-process MDP results

**Used by:**
- `engine/run_sequence.m`
- `engine/run_sensors.m`
- `utilites/run_hai_trial.m`
- `utilites/TEST_AY_2LEV_Mushiake.m`

**Purpose:** Provides hierarchical active inference framework (Level 1/Level 2 models)

---

### **Dependency 2: TrialBox**

**Location:** `~/tools/TrialBox/`  
**GitHub:** https://github.com/donnarumma/TrialBox

**Functions Used from TrialBox:**
- `resolveFunctionParams()` – Merge parameter structures with function defaults

**Used by:**
- `engine/run_sequence.m` (line 19)
- `engine/run_sensors.m` (indirectly via run_sequence)

**Purpose:** Generic parameter resolution and override mechanism for trial execution

---

### **Dependency 3: SPM (Statistical Parametric Mapping)**

**Location:** `~/tools/spm12/` (or system SPM installation)  
**URL:** https://www.fil.ion.ucl.ac.uk/spm/

**Functions Used from SPM:**
- `spm_MDP_check()` – Validate MDP structure integrity
- `spm_MDP_update()` – Update model parameters
- `spm_MDP_VB_X()` – Variational Bayes active inference solver (alternative to VB_MDP_X)
- `spm_MDP_VB_sleep()` – Bayesian model reduction
- `spm_MDP_VB_game()` – Game-theoretic MDP solver
- `spm_MDP_get_T()` – Extract temporal information
- `spm_dot()` – Tensor contraction utility
- `spm_log()` – Log transformation with epsilon protection
- `spm_softmax()` – Softmax normalization

**Used by:**
- `engine/VB_MDP_X.m` (wrapper around or alternative to SPM functions)
- `engine/vb_prepare_lower_level_mdp.m`
- `engine/vb_integrate_lower_level_outcomes.m`
- `engine/vb_infer_lower_level.m`

**Purpose:** Standard active inference inference solver and utilities. VB_MDP_X is a custom implementation that may call SPM functions or provides drop-in replacement.

---

## 4. Internal Dependencies Structure

### **Core Functional Modules**

#### **engine/** - Core Inference & Model Building

| File | Purpose | Internal Deps | External Deps |
|------|---------|---------------|---------------|
| `run_sequence.m` | Execute one sequence trial | build_sequence_model, VB_MDP_X, HAI_* | resolveFunctionParams, HAI_LANGUAGE, SPM |
| `run_sensors.m` | Execute sensor trial | (runs feval) | HAI_LANGUAGE, TrialBox, SPM |
| `build_sequence_model.m` | Construct generative model | build_type_info, build_family_specs, SequenceTransitions | None |
| `VB_MDP_X.m` | Variational Bayes solver | vb_* functions | SPM (conditional) |
| `VB_MDP_C.m`, `VB_MDP_XX.m` | Alternative solvers | – | SPM (probably) |

#### **pms/** - Parameter Specifications

| File | Purpose | Usage |
|------|---------|-------|
| `run_sequenceParams.m` | Default parameters for run_sequence | All active MAIN programs |
| `run_sensorsParams.m` | Default parameters for run_sensors | Sensor task MAIN programs |
| `plot_sequence_firing_rateParams.m` | Firing rate plot parameters | Plotting pipelines |
| `plot_sequence_rasterParams.m` | Raster plot parameters | Plotting pipelines |

#### **utilites/** - Helper Functions

| File | Purpose | Internal Deps |
|------|---------|---------------|
| `Collect_Trial_Results.m` | Gather saved trial MDP files | plot functions |
| `Collect_Sensor_Results.m` | Gather sensor trial results | build_mushiake_trial_data, etc. |
| `build_sequence_trial_description.m` | Trial naming/metadata | build_sequence_trial_description |
| `build_batch_description.m` | Batch folder naming | build_batch_family_label, etc. |
| `SequenceTransitions.m` | Generate transition matrices | None |
| `Sequences3D.m`, `Sequences2D.m`, `Sequences1D.m` | Task definitions | None |
| `DICTIONARY_*.m` | Task observation spaces | None |
| `run_mushiake_trial.m` | Mushiake trial runner | TEST_AY_2LEV_Mushiake, run_hai_trial |
| `run_hai_trial.m` | HAI execution wrapper | HAI_RUN, HAI_smartMDP |
| `TEST_AY_2LEV_Mushiake.m` | Mushiake 2-level test | run_hai_trial, HAI_* functions |

#### **plot/** - Visualization

| File | Purpose | Internal Deps |
|------|---------|---------------|
| `plot_sequence_firing_rate.m` | Firing rate heatmaps | extract_sequence_data_trials |
| `plot_sequence_raster.m` | Neural rasters | extract_sequence_data_trials |
| `BETA_pca.m` | PCA summaries | extract_sequence_data_trials |

---

## 5. Files That Belong to Shared/Multiple Projects

### **Potential Shared Files** (candidates for refactoring)

Based on file naming and function scope:

| File | Current Location | Could be Shared? | Reason |
|------|------------------|------------------|--------|
| `DICTIONARY_*.m` | `utilites/` | Maybe | Generic task definition format |
| `SequenceTransitions.m` | `utilites/` | Maybe | Generic sequence generation algorithm |
| `smoothFR.m` | `utilites/` | Yes | Neural data smoothing (general-purpose) |
| `extract_sequence_data_trials.m` | `utilites/` | Maybe | Data extraction (could be in TrialBox) |
| `run_hai_trial.m` | `utilites/` | Partial | Wrapper around HAI_RUN; could live in HAI_LANGUAGE |
| `TEST_AY_2LEV_Mushiake.m` | `utilites/` | No | Mushiake-specific test harness |

**Key Observation:** `run_hai_trial.m` acts as a bridge between Sequences and HAI_LANGUAGE, suggesting it could belong to either project.

---

## 6. External Path References

### **Documented in README.md**

The project's README explicitly lists two required external repositories:

```
1. Clone and add to the MATLAB path:
   - https://github.com/donnarumma/HAI_LANGUAGE
   - https://github.com/donnarumma/TrialBox

2. Add this repository to the MATLAB path.
```

### **No Relative Path References Found**

No `../` relative path references were detected in any .m file. This indicates:
- ✓ Clean separation of concerns
- ✓ Explicit path setup via setup_Sequences.m
- ✓ No hard dependencies on sister projects via relative paths

---

## 7. Modern vs. Legacy Dependency Styles

### **Modern Pipeline (Active MAIN scripts)**

**Pattern:** Modular, generic, hierarchical

```
MAIN_*.m
  ├── setup sequenceModel once
  ├── loop: run_sequence() / run_sensors()
  │   └── inference (VB_MDP_X or HAI_RUN)
  └── collect_results()
```

**Dependency Profile:** Heavy use of HAI_LANGUAGE, TrialBox, SPM

### **Legacy Pipeline (archived MAIN scripts in legacy/)**

**Pattern:** Direct, script-based, monolithic

```
legacy/MAIN_*.m
  ├── loop: TEST_ABC_XIE_*.m()  [custom trial code]
  │   └── old-style inference
  └── Collect_SEQUENCES_RESULTS()
```

**Dependency Profile:** Minimal external; functions embedded in legacy/

---

## 8. Summary: Dependency Classification Table

### **By MAIN Script**

| MAIN Script | Internal | HAI_LANGUAGE | TrialBox | SPM | Status |
|-------------|----------|--------------|----------|-----|--------|
| MAIN_Chen01_S1S2S3_Backward | ✓ | ✓ | ✓ | ✓ | Active |
| MAIN_Chen01_S1S2S3_Forward | ✓ | ✓ | ✓ | ✓ | Active |
| MAIN_Chen01_S1S2S3_Sensors | ✓ | ✓ | ✓ | ✓ | Active |
| MAIN_Chen02_S2_FwBw | ✓ | ✓ | ✓ | ✓ | Active |
| MAIN_Mushiake | ✓ | ✓✓ | ✓ | ✓ | Active |
| MAIN_Xie_S3_Forward | ✓ | ✓ | ✓ | ✓ | Active |

**Legend:**
- ✓ = Used
- ✓✓ = Heavily used (5+ functions)
- (✓) = Indirectly or conditionally used
- – = Not used

---

## 9. Recommendations

### **For Code Organization**

1. **Consider promoting shared utilities to TrialBox:**
   - `resolveFunctionParams()` integration
   - `extract_sequence_data_trials.m` (data I/O helpers)
   - Generic smoothing utilities (smoothFR.m)

2. **Consider promoting HAI bindings to HAI_LANGUAGE:**
   - `run_hai_trial.m` could be `HAI_sequence_wrapper.m` in HAI_LANGUAGE
   - `TEST_AY_2LEV_Mushiake.m` could be a Mushiake-specific module within HAI_LANGUAGE

3. **Keep Sequences-specific:**
   - Core model builders (build_sequence_model, SequenceTransitions)
   - MAIN_*.m scripts and parameter specs
   - Plotting functions (currently plot-specific anyway)

### **For Dependency Management**

- ✓ **Good:** No relative path references; clean modular separation
- ⚠ **Consider:** Document minimum versions of HAI_LANGUAGE and TrialBox required
- ⚠ **Consider:** Add automated dependency checker (setup_Sequences_Check.m)

### **For Future Development**

1. If adding new experiments, follow the active pipeline pattern:
   - Don't add to legacy/
   - Create new MAIN_*.m in a project-specific folder
   - Use setup_Sequences.m for path management

2. Consider abstracting the sensor/maze experiment pattern:
   - MAIN_Mushiake is more complex than sequence-only tasks
   - Could benefit from a "hierarchical task runner" utility in TrialBox

---

## Appendix: File Tree with Dependency Notation

```
Sequences/
├── README.md
├── setup_Sequences.m
│
├── Chen/
│   ├── MAIN_Chen01_S1S2S3_Backward.m         [Active, HAI✓ TrialBox✓ SPM✓]
│   ├── MAIN_Chen01_S1S2S3_Forward.m          [Active, HAI✓ TrialBox✓ SPM✓]
│   ├── MAIN_Chen01_S1S2S3_Sensors.m          [Active, HAI✓ TrialBox✓ SPM✓]
│   └── MAIN_Chen02_S2_FwBw.m                 [Active, HAI✓ TrialBox✓ SPM✓]
│
├── Xie/
│   └── MAIN_Xie_S3_Forward.m                 [Active, HAI✓ TrialBox✓ SPM✓]
│
├── Mushiake/
│   ├── MAIN_Mushiake.m                       [Active, HAI✓✓ TrialBox✓ SPM✓]
│   └── _snapshots/
│
├── engine/ [Generic inference & model building]
│   ├── build_sequence_model.m                [Internal]
│   ├── build_transition_matrices.m           [Internal]
│   ├── build_likelihood_matrices.m           [Internal]
│   ├── build_type_info.m                     [Internal]
│   ├── build_family_specs.m                  [Internal]
│   ├── run_sequence.m                        [HAI✓ TrialBox✓ SPM✓]
│   ├── run_sensors.m                         [HAI✓ TrialBox✓ SPM✓]
│   ├── VB_MDP_X.m                            [SPM✓]
│   ├── VB_MDP_C.m                            [SPM✓]
│   ├── VB_MDP_XX.m                           [SPM✓]
│   ├── vb_prepare_lower_level_mdp.m          [SPM✓]
│   ├── vb_infer_lower_level.m                [SPM✓]
│   ├── vb_integrate_lower_level_outcomes.m   [SPM✓]
│   └── vb_describe_lower_level_call.m        [Internal]
│
├── pms/ [Parameter specifications]
│   ├── run_sequenceParams.m                  [Internal]
│   ├── run_sensorsParams.m                   [Internal]
│   ├── plot_sequence_firing_rateParams.m     [Internal]
│   └── plot_sequence_rasterParams.m          [Internal]
│
├── utilites/ [Helper functions]
│   ├── Collect_Trial_Results.m               [Internal]
│   ├── Collect_Sensor_Results.m              [Internal]
│   ├── build_batch_description.m             [Internal]
│   ├── build_sequence_trial_description.m    [Internal]
│   ├── find_existing_trial_file.m            [Internal]
│   ├── get_or_create_trial_seeds.m           [Internal]
│   ├── SequenceTransitions.m                 [Internal]
│   ├── Sequences3D.m                         [Internal]
│   ├── Sequences2D.m                         [Internal]
│   ├── Sequences1D.m                         [Internal]
│   ├── DICTIONARY_ABCDEF_Neutral_2LEV.m      [Internal]
│   ├── DICTIONARY_ABC_t2_CONTEXT.m           [Internal]
│   ├── DICTIONARY_AY_2LEV_Mushiake.m         [Internal]
│   ├── extract_sequence_data_trials.m        [Internal]
│   ├── run_mushiake_trial.m                  [HAI✓]
│   ├── run_hai_trial.m                       [HAI✓]
│   ├── TEST_AY_2LEV_Mushiake.m               [HAI✓]
│   ├── MAZE_Mushiake.m                       [Internal]
│   ├── smoothFR.m                            [Internal]
│   └── [10+ other utilities]
│
├── plot/ [Visualization]
│   ├── plot_sequence_firing_rate.m           [Internal]
│   ├── plot_sequence_raster.m                [Internal]
│   ├── BETA_pca.m                            [Internal]
│   └── [3+ other plotting functions]
│
├── debug/ [Diagnostic & testing]
│   └── [Various debug/test scripts]
```

---

**End of Report**
