# ADR-0003: Songs are layered stems that always play; weapons unmute them

- Status: Accepted
- Date: 2026-09-23

## Context
Picking up a weapon should "add a track to the song" (e.g. a shotgun brings in the guitars).
The new layer must come in perfectly aligned with what's already playing.

## Decision
- Each stage's song is a set of equal-length, looping stems: `bed` (always audible) plus one
  per instrument track: `drums, perc, bass, guitar, keys, lead`.
- **All stems start in the same `love.audio.play({...})` call and never stop.** Locked stems
  sit at volume 0. Unlocking fades a stem up over ~0.4 s.
- Every 2 s the non-master stems are checked against the master and re-seeked if they drift
  more than 30 ms (away from the loop point).
- Each weapon definition names its `track`. There are six weapons for six tracks; evolutions
  keep their base weapon's track.
- File stems are opened as `"stream"` sources (memory-friendly for 3-minute songs);
  synthesized placeholders are `"static"`.

## Alternatives considered
- Starting a stem when the weapon is picked up and seeking it to the master position: this
  risks audible clicks and small offsets, and adds complexity.
- A single mixed file per unlock combination: that's a combinatorial explosion (2^6 files).

## Consequences
- The CPU cost of decoding 7 streams is small, but not zero.
- All stems of a song **must have identical length and start at the same point**. The guide
  says so.
- Two weapons on the same track would share a stem. Adding more weapons than tracks means
  either adding tracks to songs or accepting sharing (the pattern and firing still work).
