-- Song definition for the Highway stage. See assets/songs/graveyard_groove/song.lua for notes.
return {
  title = "Highway to Hell (placeholder)",
  artist = "Placeholder Synth",
  bpm = 150,
  stepsPerBeat = 4,
  offset = 0.0,
  bars = 4,

  synth = { chords = { "Dm", "Bb", "F", "C" } },

  tracks = {
    bed    = { file = "bed.ogg", volume = 0.6 },
    drums  = { file = "drums.ogg",  pattern = "X.o.X...X.x.X.o." },
    perc   = { file = "perc.ogg",   pattern = "x.X.o.X.x.X.o.X." },
    bass   = { file = "bass.ogg",   pattern = "X.x.X.x.X.o.X.x." },
    guitar = { file = "guitar.ogg", pattern = "X..x..X...X.o..." },
    keys   = { file = "keys.ogg",   pattern = "X...............|........x...o..." },
    lead   = { file = "lead.ogg",   pattern = "X...x...o...X...|..X...x...o.X..." },
  },
}
