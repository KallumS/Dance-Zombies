-- Song definition for the Mall stage. See assets/songs/graveyard_groove/song.lua for notes.
return {
  title = "Mall of the Dead",
  artist = "Placeholder Synth",
  bpm = 128,
  stepsPerBeat = 4,
  offset = 0.0,
  bars = 4,

  synth = { chords = { "Em", "C", "G", "D" } },

  tracks = {
    bed    = { file = "bed.ogg", volume = 0.7 },
    drums  = { file = "drums.ogg",  pattern = "X...X.o.X.x.X..." },
    perc   = { file = "perc.ogg",   pattern = "ooX.ooX.ooX.ooX." },
    bass   = { file = "bass.ogg",   pattern = "X..x..X...X.o.x." },
    guitar = { file = "guitar.ogg", pattern = "X.....X...x...o." },
    keys   = { file = "keys.ogg",   pattern = "....X.......x...|....X.......o..." },
    lead   = { file = "lead.ogg",   pattern = "X.x.....X...o...|X.x.o...X.....x." },
  },
}
