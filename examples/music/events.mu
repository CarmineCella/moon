# ============================================================================
# music_examples.mu — Example usages for music.mu
# ============================================================================

load ("stdlib.mu")
load("music.mu")

# ----------------------------------------------------------------------------
# Example 1 — single note
# ----------------------------------------------------------------------------
print("---- Example 1 ----")

var x = dur(1, note(A4, mf, ord, Vl))
var score1 = render_score_events(x)

var i = 0
while (i < len(score1)) {
    print(score1[i])
    i = i + 1
}

# ----------------------------------------------------------------------------
# Example 2 — melodic line
# ----------------------------------------------------------------------------
print("---- Example 2 ----")

var vl = line(Vl, [
    q_note(A4, pp, ord),
    q_note(B4, p, ord),
    h_note(C5, mf, ten)
])

var score2 = render_score_events(vl)

i = 0
while (i < len(score2)) {
    print(score2[i])
    i = i + 1
}

# ----------------------------------------------------------------------------
# Example 3 — polyphony
# ----------------------------------------------------------------------------
print("---- Example 3 ----")

var vc = at(2,
    dur(4,
        note(C3, pp, sulpont, Vc)
    )
)

var piece3 = par([vl, vc])
var score3 = render_score_events(piece3)

i = 0
while (i < len(score3)) {
    print(score3[i])
    i = i + 1
}

# ----------------------------------------------------------------------------
# Example 4 — audio + synth
# ----------------------------------------------------------------------------
print("---- Example 4 ----")

var tape = at(0,
    dur(8,
        soundfile("sea.wav")
    )
)

var syn = at(4,
    dur(2,
        synth("fm", [
            ["freq", 440],
            ["amp", 0.2]
        ])
    )
)

var piece4 = par([vl, tape, syn])
var score4 = render_score_events(piece4)

i = 0
while (i < len(score4)) {
    print(score4[i])
    i = i + 1
}

# ----------------------------------------------------------------------------
# Example 5 — structure + annotations
# ----------------------------------------------------------------------------
print("---- Example 5 ----")

var structure = par([
    at(0, tempo(72)),
    at(0, meter(4, 4)),
    at(0, text("calmo"))
])

var piece5 = par([structure, vl, vc])
var score5 = render_score_events(piece5)

i = 0
while (i < len(score5)) {
    print(score5[i])
    i = i + 1
}

# ----------------------------------------------------------------------------
# Example 6 — algorithmic composition (simple deterministic version)
# ----------------------------------------------------------------------------
print("---- Example 6 ----")

proc simple_algo_line (instr, pitches, n) {
    var xs = []
    var i = 0
    while (i < n) {
        push(xs,
            dur(1,
                note(
                    pitches[mod (i, len(pitches))],
                    pp,
                    ord,
                    instr
                )
            )
        )
        i = i + 1
    }
    return seq(xs)
}

var vl_algo  = simple_algo_line(Vl,  [A4, B4, C5, E5], 8)
var vla_algo = simple_algo_line(Vla, [C4, D4, F4],     8)

var piece6 = par([vl_algo, vla_algo])
var score6 = render_score_events(piece6)

i = 0
while (i < len(score6)) {
    print(score6[i])
    i = i + 1
}

# ----------------------------------------------------------------------------
# Example 7 — audio plan
# ----------------------------------------------------------------------------
print("---- Example 7 ----")

var piece = music_example()
var plan = render_audio_plan(piece, 72)

print(plan)

# ============================================================================
# end
# ============================================================================
