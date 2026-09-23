local Synth = require("src.audio.synth")
return function(t)
  t.test("synth renders a loop of the right length with audio in it", function()
    local song = { bpm = 120, stepsPerBeat = 4, bars = 1, synth = { chords = { "Am" } } }
    local buf, n = Synth.renderTrack(song, "drums", { pattern = "X...X...X...X..." })
    t.eq(n, math.floor(2.0 * Synth.RATE))
    local peak = 0
    for i = 1, n do peak = math.max(peak, math.abs(buf[i])) end
    t.truthy(peak > 0.1, "silent render")
  end)
  t.test("chord parsing", function()
    local c = Synth.parseChord("F#m")
    t.eq(c.root, -3); t.eq(c.minor, true)
    t.eq(Synth.parseChord("C").minor, false)
  end)
end
