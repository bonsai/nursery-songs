# suno/

Paste-ready exports. Each file is the **Lyrics** field, already tagged. The
matching **Style of Music** prompt is in the table below.

| File | Register | BPM | Notes |
|---|---|---|---|
| `01-the-gizzmidge.suno.txt` | deadpan | 96 | flattest of the six |
| `02-snodgrass.suno.txt` | deadpan | 96 | 3-line chorus, ends cold |
| `03-plonk.suno.txt` | deadpan | 96 | hook line carries the punch |
| `04-the-bumbrix.suno.txt` | deadpan | 96 | chorus is a put-down, sing it kindly |
| `05-wibbledoo.suno.txt` | lullaby | 62 | no percussion, no lift |
| `06-pomelo.suno.txt` | wink | 104 | hand claps, one small lift |

## How to use one

1. Open the file, copy everything in it.
2. Paste into Suno's **Lyrics** box.
3. Paste the style prompt into **Style of Music**. Do not put lyrics in the
   style box, or music words in the lyrics box — it costs you the run.
4. Generate. Expect to discard the first two or three.

## Style prompts

**deadpan** — `deadpan acoustic children's folk, ukulele, brushed snare, single
female voice, 96 BPM, no backing vocals, no harmony stacks, no build, no big
finish, no autotune, no strings`

**wink** — `playful acoustic children's folk, ukulele, hand claps, single female
voice, 104 BPM, no backing vocals, no big finish, no autotune`

**lullaby** — `lullaby, solo voice, felt piano, no drums, no percussion, 62 BPM,
no backing vocals, no build, no big finish`

## Regenerating

After editing anything in `../songs/`:

```powershell
& "$env:USERPROFILE\.opencode\skills\suno\convert.ps1" `
  -In "..\songs\02-snodgrass.md" -Out "02-snodgrass.suno.txt" -Register deadpan
```

The converter reads the `## Lyrics` section of a `.md` and ignores `How to sing
it` and `Why it works`, so the prose never leaks into the prompt. Registers:
`deadpan`, `wink`, `lullaby`.

## Known fights

These are the three things Suno does that these six songs all need to not have:

1. **`[Chorus]` lifts.** It widens the vocal, stacks harmonies and raises
   energy by default. Every chorus tag here is parameterized to stop that, and
   the style prompt repeats the instruction. Both, or the style wins.
2. **It wants an outro.** Every file ends `[Outro: abrupt cut, no fade]`, and
   the final chorus is tagged `then stop`. Expect a fade anyway on some runs.
3. **It fills the gaps.** The blank line between a line and its short answer is
   the call-and-response. If Suno runs them together, the song stops working
   as a nursery rhyme even though it sounds fine.

## Before you generate

Run the earworm audit. A chorus that fails the 20-word rule will also read as
rushed in Suno, because the model has to fit it into a fixed number of bars.

```powershell
& "$env:USERPROFILE\.opencode\skills\earworm\audit.ps1" -In "..\songs\02-snodgrass.md"
```

All six currently pass every rule.
