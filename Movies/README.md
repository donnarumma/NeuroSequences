# Simulation Movies

MATLAB code and local movie exports live in this directory. Generated files
are written to `output/` and excluded from Git.

## Combined Movie and Narration

[`Movie-Readme.md`](Movie-Readme.md) provides the running order, English
voice-over script, visual cues and scientific interpretation notes for
*Inferential planning in the frontal cortex*. The silent compilation combines
all eight examples below, with a cover, three chapter cards and closing credits
(4 minutes 23.2 seconds with the current sources).

```bash
python3 Movies/assemble_inferential_planning_movie.py --check-only
python3 Movies/assemble_inferential_planning_movie.py
```

The output is `Movies/output/Inferential_Planning/Inferential_Planning.mp4`.
The assembler copies the original clip streams without re-encoding and
verifies every decoded scientific frame against its source. It also writes
embedded chapters, a frame-accurate JSON timeline, source hashes and cover/
chapter-card PNGs. It requires Python 3, ffmpeg, ffprobe and DejaVu Sans fonts,
not MATLAB. The narration is supplied as text; no audio is synthesized.

## Figure 2: Maze Planning

`Mushiake_Fig02_Movie.m` animates the two Mushiake examples in Figure 2 of
*Inferential planning in the frontal cortex*.

| `caseName` | Trial | Path | Policy | Panels |
| --- | --- | --- | --- | --- |
| `ULL` (default) | 2 | S33, S23, S22, S21 | Up, left, left | D, E, F |
| `URR` | 1 | S33, S23, S24, S25 | Up, right, right | G, H, I |

Each movie first reveals the saved planning raster and firing-rate curves
over their original 0-1 time interval. The cursor remains at the start during
inference: the neural panels encode the prospective action sequence, not
physical movement along the maze. A second, explicitly schematic replay
then follows the cached MDP states while the neural panels remain frozen.
Each movement is followed by a 1.2-second stop so its destination state and
step number remain readable. The step number also stays visible during motion.
Replay speed is illustrative, not a simulated movement duration.

```matlab
setup_NeuroSequences;
outputsLeft = Mushiake_Fig02_Movie;
outputsRight = Mushiake_Fig02_Movie(struct('caseName', 'URR'));
outputs = Mushiake_Fig02_Movie(struct('previewOnly', true));
```

The default source is
`/TESTS/HAI_SEQUENCES/Mushiake/Mushiake_SEQUENCES_UDLRS/Rep01`.
Set `sourceDir` to this replicate directory or its `FIG` subdirectory. Each
case requires `Maze_Mushiake_UDLR_TrialN.fig`,
`Raster_Mushiake_UDLR_TrialN.fig`, `FiringRate_Mushiake_UDLR_TrialN.fig` and
a matching cached `MDP_*TrialN_*.mat` in the replicate directory. The newest
matching MDP is used, with its exact path and hash recorded in provenance.
The policy, state/action correspondence, goal and open doorways are checked
against the saved maze. Sources can be generated with
`Mushiake/MAIN_Mushiake_Exp.m`; the movie helper itself never runs that main.

Outputs are in `Movies/output/Mushiake_Fig02_<caseName>/`: an H.264 MP4,
PNG/PDF/FIG poster, seven preview frames and a MAT provenance file with input
hashes, original signals, state coordinates, code hashes and both clocks.
All saved firing-rate curves and legend entries are retained, including the
terminal fourth-rank readouts; the raster retains the source's three ranks.
No smoothing, random sampling or model parameters are changed.

Mushiake supports the common options below, with `playbackSpeed=0.10` by
default, plus `planHoldSeconds=1.5`, `replayStepSeconds=1.5` (movement duration)
and `replayStateHoldSeconds=1.2` (stop at each destination).

### State-by-State Overlay

`plot/plot_MAZE.m` draws the static maze. The movie-only helper
`mushiake_movie_path.m` adds a movable cursor and reveals the path arrows:

```matlab
% After drawing a maze with plot_MAZE; coordinates are [column, row].
view = mushiake_movie_path(gca, [3 3; 3 2; 2 2; 1 2]);
for step = 0:3
    view.setStep(step);
    drawnow;
    pause(1);
end
```

Fractional steps interpolate the cursor between adjacent states. This helper
only draws an overlay; the movie entry point performs the MDP/maze checks.
Run `test_mushiake_movie` to check the overlay and saved-source previews.

## Figure 4: Three-Target Examples

`Chen01_Fig04_Movie.m` animates the ABC examples in Figure 4 of
*Inferential planning in the frontal cortex*. The task permits sequences of
one to three targets; these movies show the three-target trial. Direction is
known before S1. The timeline is Pre, S1, S2, S3 and Delay, without a late cue.

| `caseName` | Presented targets | Readout | Final plan | Panels |
| --- | --- | --- | --- | --- |
| `ABC_Forward` | A, B, C | Level 2 memory | A(1), B(2), C(3) | F, G, H |
| `ABC_Backward` | A, B, C | Level 2 memory | C(1), B(2), A(3) | I, J, K |
| `ABC_Sensory` | A, B, C | Level 1 sensory | Transient input responses | L, M, N |

All three use their saved trial-1 raster and firing-rate figures. The three
PCA panels retain the original condition-level trajectories for targets A-F.
In the sensory case, the coloured hulls mark peak responses during each
sensory epoch, as in the source figure. The sensory readout applies to both
task directions and does not represent a maintained Level 2 plan.

```matlab
setup_NeuroSequences;
outputsFwd = Chen01_Fig04_Movie;
outputsBwd = Chen01_Fig04_Movie(struct('caseName', 'ABC_Backward'));
outputsSensory = Chen01_Fig04_Movie(struct('caseName', 'ABC_Sensory'));

% Inspect the six preview frames without encoding a movie.
outputs = Chen01_Fig04_Movie(struct('previewOnly', true));
```

Default source directories are under `/TESTS/HAI_SEQUENCES/Chen01/`:

| Case | Replicate directory |
| --- | --- |
| Forward | `Chen01_SEQUENCES_ABCDEF_S1S2S3_Fwd_COS(100,100)/Rep01` |
| Backward | `Chen01_SEQUENCES_ABCDEF_S1S2S3_Bwd_COS(100,100)/Rep01` |
| Sensory | `Chen01_SEQUENCES_ABCDEF_Sensors_Ord_COS(80,100)/Rep01` |

Use `sourceDir` to select another replicate directory or its `FIG` folder.
Missing exports can be generated with the corresponding
`MAIN_Chen01_S1S2S3_Forward_Exp`, `MAIN_Chen01_S1S2S3_Backward_Exp` or
`MAIN_Chen01_S1S2S3_Sensors_Exp` simulation main.

Default outputs are `Movies/output/Chen01_Fig04_<caseName>/`. Playback covers
the visible source intervals, including the complete PCA trajectories; the
original panel time offsets and axes remain unchanged. Each case has six
preview frames plus its movie, poster and provenance files.

## Figure 5: Two-Target Sequence Memory

`Chen02_Fig05_Movie.m` animates the three examples in Figure 5 of
*Inferential planning in the frontal cortex*:
<https://www.sciencedirect.com/science/article/pii/S2211124726009836>.
This is the **Chen02** fixed-length task. Each movie includes the task and
target layout from panels A/B, followed by the corresponding model readouts.

| `caseName` | Trial | Presented targets | Cue | Inferred plan | Readout panels |
| --- | --- | --- | --- | --- | --- |
| `AB_Forward` | 1 | A, B | Forward | A(1), B(2) | D, E, F |
| `AB_Backward` | 31 | A, B | Backward | B(1), A(2) | G, H, I |
| `BA_Backward` | 36 | B, A | Backward | A(1), B(2) | J, K, L |

The dashboard follows the NeuroConnStat movies: a dark title bar, task display,
progressive signal reveal, a common display clock, fixed axes and a final hold.
It shows the two targets in their presentation order, Delay 1, the direction
cue and Delay 2. It stops at
the end of the memory interval, before saccade execution.

The raster and firing-rate traces come directly from the selected trial's saved figures.
The PCA panel retains the original condition-level trajectories for targets
A-F at ranks 1 and 2, using PCAForward or PCABackward as appropriate. Both
backward examples share the same condition-level PCA panel, as in Figure 5.
It is not a projection of the individual trial. Numerical
coordinates, colours, smoothing and the original plotted time offsets are
retained. No simulation, spike sampling or PCA fit is repeated.

## Run Figure 5

Run `Chen/MAIN_Chen02_S2_FwBw_Exp.m` to generate the source figures, or reuse
its existing exports. MATLAB and ffmpeg with the `libx264` encoder are needed
for the movie. Rendering existing figures does not require HAI_LANGUAGE,
TrialBox or SPM on the MATLAB path.

```matlab
setup_NeuroSequences;
outputs = Chen02_Fig05_Movie;

% Render the two backward examples into separate output directories.
outputsAB = Chen02_Fig05_Movie(struct('caseName', 'AB_Backward'));
outputsBA = Chen02_Fig05_Movie(struct('caseName', 'BA_Backward'));

% Export still previews before rendering the complete movie.
outputs = Chen02_Fig05_Movie(struct('previewOnly', true));

% Use another directory containing the three matching .fig exports.
outputs = Chen02_Fig05_Movie(struct( ...
    'sourceDir', '/path/to/Rep01', ...
    'outputDir', '/path/to/movie-output'));
```

The default source is
`/TESTS/HAI_SEQUENCES/Chen02/Chen02_SEQUENCES_ABCDEF_S2_FwdBwd_PTfw10_bw1_COS(100,100)/Rep01`.
`sourceDir` can be either the replicate directory or its `FIG` subdirectory.
The required files for the default AB-forward example are:

- `Raster_Chen02_ABCDEF_S2_Fwd_Trial1.fig`
- `FiringRate_Chen02_ABCDEF_S2_Fwd_Trial1.fig`
- `PcaTime_Chen02_ABCDEF_S2_FwdBwd_PCAForward.fig`

For backward examples, the raster and firing-rate files use `Bwd_Trial31`
or `Bwd_Trial36`. Both use `PcaTime_Chen02_ABCDEF_S2_FwdBwd_PCABackward.fig`.

## Shared Options

Figure 5 output: `Movies/output/Chen02_Fig05_<caseName>/`. The file stem also
includes the case name, so each example has its own movie and companion files.
Exports include an H.264 MP4, PNG/PDF/FIG poster, five preview frames and a MAT
provenance file containing source hashes, code hashes, original trace
coordinates, options and frame times. Displayed coordinates and raster
visibility masks are checked against the saved values in the preview frames
and at the end of the clip, before encoding.

| Option | Default | Meaning |
| --- | --- | --- |
| `caseName` | `'ULL'` / `'ABC_Forward'` / `'AB_Forward'` | One of the cases supported by the selected entry point |
| `pixelSize` | `[1920 1080]` | Frame size in pixels |
| `frameRate` | `20` | Encoded frames per second |
| `playbackSpeed` | `0.10` (Mushiake), `0.25` (Chen) | Source time units per playback second |
| `holdStartSeconds` | `1` | Opening hold |
| `holdEndSeconds` | `5` | Final hold |
| `previewOnly` | `false` | Save still figures without encoding |
| `keepFrames` | `false` | Retain temporary PNG frames |
| `overwrite` | `false` | Allow replacement of an existing MP4 |

The Chen entry points use `chen_sequence_movie_render.m` for layout, progressive
reveal, verification and encoding, and `chen_sequence_movie_options.m` for
common option validation. Mushiake reuses the options validator but has its
own maze dashboard and path overlay. These helpers live in `Movies/`; they
read saved figures and are separate from the simulation mains and their
readout utilities.
