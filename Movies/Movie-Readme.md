# Inferential planning in the frontal cortex

## Movie Overview

**Subtitle:** A computational account of planning, sequence memory and flexible reordering.

This movie brings together eight model-generated examples from Figures 2, 4
and 5 of *Inferential planning in the frontal cortex*. It moves from planning
a route through a maze, to maintaining and reversing three-target sequences,
to revising a two-target plan after a late instruction cue.

**Duration:** 4 minutes 23.2 seconds. **Format:** 1920 x 1080, 20 fps.
The current master is silent. The English paragraphs under **Narration** below
are a voice-over script, not an audio track already present in the MP4.

**Movie:** [Inferential_Planning.mp4](output/Inferential_Planning/Inferential_Planning.mp4)

**Cover:** [Inferential_Planning_poster.png](output/Inferential_Planning/Inferential_Planning_poster.png)

The complete original clips are retained, including their opening and closing
holds. Only the cover, chapter cards and closing credits are new. Embedded
chapters allow navigation in players that support MP4 chapters. There are no
cuts, speed changes or overlays within the scientific clips, and their video
streams are copied without re-encoding.

## Running Order

Times refer to the assembled movie, not the neural clocks within its panels.

| Start | End | Content | Paper panels |
| --- | --- | --- | --- |
| 00:00.000 | 00:10.000 | Opening title | Overview |
| 00:10.000 | 00:16.000 | Chapter 1: Goal-directed sequence planning | Figure 2 |
| 00:16.000 | 00:41.650 | Up, left, left: goal S21 | 2D-F |
| 00:41.650 | 01:07.300 | Up, right, right: goal S25 | 2G-I |
| 01:07.300 | 01:13.300 | Chapter 2: Remembering and reversing sequences | Figure 4 |
| 01:13.300 | 01:40.550 | A, B, C: forward memory | 4F-H |
| 01:40.550 | 02:07.200 | A, B, C: backward memory | 4I-K |
| 02:07.200 | 02:33.850 | A, B, C: sensory responses | 4L-N |
| 02:33.850 | 02:39.850 | Chapter 3: Reordering memory after a late cue | Figure 5 |
| 02:39.850 | 03:10.300 | A, B followed by a forward cue | 5A/B and 5D-F |
| 03:10.300 | 03:40.750 | A, B followed by a backward cue | 5A/B and 5G-I |
| 03:40.750 | 04:11.200 | B, A followed by a backward cue | 5A/B and 5J-L |
| 04:11.200 | 04:23.200 | Closing message, authors and code | Overview |

## Voice-Over Script

Read only the blockquoted paragraphs. The visual cues are recording notes,
not part of the spoken text. Use a calm explanatory delivery, with short
pauses around target lists and rule changes. The script is approximately
two words per second within the spoken passages, with room for pauses in
the longer clips. The chapter boundaries are anchors rather than a
sentence-level forced alignment.

### 00:00.000 | Opening

**Visual cue:** Paper title and the question of representing a complete plan.

**Narration**

> How can the brain prepare a whole sequence before acting? These simulations explore planning and working memory as inference over ordered representations.

### 00:10.000 | Chapter 1: Goal-Directed Sequence Planning

**Visual cue:** Chapter card; maze task based on Mushiake et al. (2006).

**Narration**

> We begin with three-action plans for moving through a maze.

### 00:16.000 | Up, Left, Left

**Visual cue:** Goal S21. First the model infers the plan; the cursor then
replays it with pauses at the intermediate states. Reserve the last sentence
for the replay, which starts at 00:28.500 in the assembled movie.

**Narration**

> The agent starts at the centre and plans to reach the goal on the left. Different colours identify the first, second and third action positions. As competing possibilities are resolved, up, left and left remain active together. The subsequent cursor replay illustrates the chosen path; the neural traces are now frozen.

### 00:41.650 | Up, Right, Right

**Visual cue:** Goal S25. Notice the distinct second- and third-position
populations for the same movement, right. The replay starts at 00:54.150.

**Narration**

> Now the goal is on the right. The model retains up as the first movement, but selects right for both later positions. Separate populations represent the two occurrences of right. The complete plan is maintained in parallel before the schematic replay visits the corresponding states.

### 01:07.300 | Chapter 2: Remembering and Reversing Sequences

**Visual cue:** Chapter card; the variable-length sequence task based on
Chen et al. (2024). These clips show its three-target examples.

**Narration**

> We next consider a sequence-memory task, with the rule known in advance.

### 01:13.300 | A, B, C: Forward Memory

**Visual cue:** Targets arrive sequentially, but the inferred memory persists
after they disappear. The right-hand plots include all six target identities.

**Narration**

> Targets A, B and C appear one at a time. Under the forward rule, the model progressively assigns them to the first, second and third memory positions. Activity persists during the delay, after the stimuli have disappeared. The panels on the right show condition-level population trajectories for all six target identities.

### 01:40.550 | A, B, C: Backward Memory

**Visual cue:** The observed sequence remains A, B, C, while the final planned
order is C, B, A. Early uncertainty concerns the positions in that final plan.

**Narration**

> The targets are unchanged, but the required order is now reversed. Because sequence length is initially unknown, observing A does not yet determine its final rank. Later evidence resolves the alternatives, yielding C, B, A. The changing neural activity reflects inference about the required sequence, rather than a fixed replay of the inputs.

### 02:07.200 | A, B, C: Sensory Responses

**Visual cue:** Level 1 responses to the same sensory inputs. These are
transient responses, not another maintained forward or backward memory plan.

**Narration**

> This example shows the lower sensory level for the same inputs. Responses rise around each target presentation and then decay. Unlike the sustained memory populations, these signals are transient. The contrast separates encoding what is currently observed from maintaining a plan for later use.

### 02:33.850 | Chapter 3: Reordering Memory After a Late Cue

**Visual cue:** Chapter card; the fixed-length, two-target mixed condition.
Unlike Chapter 2, the direction is not known when the targets appear.

**Narration**

> Finally, a late cue determines how two remembered targets are reordered.

### 02:39.850 | A, B With a Forward Cue

**Visual cue:** A and B are presented, followed by Delay 1, the direction cue
and Delay 2. The source configuration gives forward policies a stronger prior
than backward policies; this is a property of this simulation, not a claim
that all task variants have the same bias.

**Narration**

> Here the sequence always contains two targets, but the direction is revealed only after a delay. A and then B are presented. In this configuration, prior beliefs favour a forward plan before the cue. The forward cue confirms A in the first position and B in the second, which remain represented during the final delay.

### 03:10.300 | A, B With a Backward Cue

**Visual cue:** The same inputs now lead to B(1), A(2). Describe the reversal
when the backward cue appears, rather than during the preceding sensory epochs.
Pause after "still missing" if needed, until the cue appears.

**Narration**

> Again, the model sees A and B. During the first delay, it favours a forward plan, just as in the previous example. The sensory history is unchanged; the direction cue is still missing. When the backward cue arrives, the model revises its plan: B comes first and A second.

### 03:40.750 | B, A With a Backward Cue

**Visual cue:** Different inputs, B and A, yield the same final A, B plan as
the forward example. The condition-level backward PCA panels are shared with
the preceding clip, as in the source figure; they are not independent
single-trial projections. Pause after "different sensory history" until the
backward cue appears.

**Narration**

> Now B appears before A. During the first delay, the model favours preserving this presentation order. We therefore start from a different sensory history. The backward cue reverses the sequence, producing A then B. This matches the first example's plan. Shared rank-specific populations can support different inputs and rules.

### 04:11.200 | Closing

**Visual cue:** Closing statement, paper authors, repository and concept DOI.

**Narration**

> Together, these examples illustrate one computational proposal: planning, sequence memory and flexible reordering can emerge from probabilistic inference over simultaneously represented, ordered plan elements.

## Recording and Interpretation

- Read A, B and C as individual letters. Read ULL as "up, left, left" and URR as "up, right, right", not as acronyms.
- Read A(1) as "A at rank one". If state names are spoken, read S33 as "state three-three", S21 as "state two-one" and S25 as "state two-five".
- All neural activity shown here is model-generated. It illustrates simulations of experimental paradigms, not recordings from animals.
- In the maze examples, the replay is illustrative and follows the cached state sequence. Its duration is not an inferred neural or movement latency; neural time is frozen during replay.
- In the Chen examples, the clips end before saccade execution. Target flashes show presentation, not executed eye movements.
- PCA means principal component analysis. The right-hand panels show condition-level population geometry for targets A-F, not the projection of the single raster trial. The movie alone is not a quantitative test of subspace orthogonality.
- Preserve each panel's source clock, offsets and playback speed. The eight examples do not share one continuous simulated time axis.
- This is a visual companion to selected results, not a complete presentation of the paper. Figure 3 and the supplementary analyses are not included.

## Paper and Code

Francesco Donnarumma, Thomas Parr, Karl Friston, James Whittington and Giovanni
Pezzulo. [*Inferential planning in the frontal cortex*](https://www.sciencedirect.com/science/article/pii/S2211124726009836).

Code and movie preparation: CONAN Lab, Institute of Cognitive Sciences and
Technologies, National Research Council of Italy (ISTC-CNR).

- [GitHub repository](https://github.com/donnarumma/NeuroSequences).
- [Zenodo concept DOI, covering all archived versions](https://doi.org/10.5281/zenodo.21628748).
- [Zenodo version DOI for the paper-final v1.0.0 release](https://doi.org/10.5281/zenodo.21628749). This movie was prepared separately from that archived release; it is not asserted to be part of the v1.0.0 archive.

## Rebuild the Compilation

With the eight individual MP4 files already present in `Movies/output/`, run
from the repository root:

```bash
python3 Movies/assemble_inferential_planning_movie.py --check-only
python3 Movies/assemble_inferential_planning_movie.py
```

Use `--overwrite` to replace an existing compilation. Use `--input-root` or
`--output-dir` for different directories. The builder requires Python 3,
ffmpeg with libx264, drawtext and gradients, ffprobe, and DejaVu Sans fonts;
use `--font-dir` if the fonts are installed elsewhere. It does not require
MATLAB and does not run or change any simulation.

The output directory contains the MP4, cover and chapter-card PNGs, an
FFmetadata chapter file, and `Inferential_Planning_timeline.json`. The JSON
records precise frame boundaries, input paths and SHA-256 hashes. Before
publishing the MP4, the builder checks that every decoded frame of each
scientific clip is identical to the corresponding frame of the compilation.
Generated assets stay in the Git-ignored `Movies/output/` directory.

If the source durations change, rebuild the movie and update this document's
running order and narration anchors against the generated JSON timeline.

```bash
python3 -m unittest discover -s Movies -p 'test_assemble*.py' -v
```
