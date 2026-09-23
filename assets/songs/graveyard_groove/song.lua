-- Song definition for the Graveyard stage.
-- Full format reference: docs/GUIDE.md ("Adding a song").
--
-- Each track is one stem. `file` is the audio file in this folder. If the file does not
-- exist, a placeholder is synthesised from `pattern`, which is why this song plays
-- even though the folder has no audio yet.
--
-- `pattern` is ALSO the firing pattern for the weapon bound to that track, one char
-- per 16th note:  X = level 1+,  x = level 3+,  o = level 5+,  . = rest
-- When you add real stems, write the pattern to match where the hits are in your audio.
return {
  title = "Graveyard Groove",
  artist = "Placeholder Synth",
  bpm = 110,
  stepsPerBeat = 4,  -- 16th-note grid
  offset = 0.0,      -- seconds of silence before beat 1 in your audio files
  bars = 4,          -- loop length in bars (used by the placeholder synth)

  synth = { chords = { "Am", "F", "C", "G" } },  -- placeholder synth only

  tracks = {
    bed    = { file = "bed.ogg", volume = 0.7 },                           -- always playing
    drums  = { file = "drums.ogg",  pattern = "X.o.X.x.X.o.X.x." },       -- Crossbow
    perc   = { file = "perc.ogg",   pattern = "xoXoxoXoxoXoxoXo" },       -- Hi-Hat Blades
    bass   = { file = "bass.ogg",   pattern = "X.....x...X..o.." },       -- Bass Cannon
    guitar = { file = "guitar.ogg", pattern = "X.......X..x..o." },       -- Shotgun
    keys   = { file = "keys.ogg",   pattern = "X.......x.......|....o...........|X.......x.......|........x...o..." }, -- Molotov
    lead   = { file = "lead.ogg",   pattern = "..X...x...X..o..|..X...x.o.X...x." }, -- Lightning Mic
  },
}
