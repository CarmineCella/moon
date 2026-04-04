# ============================================================================
# music.mu — first draft of a Musil timeline / music event system
# ============================================================================
#
# Goals of this first version:
# - keep everything in Musil
# - represent heterogeneous musical/audio events
# - schedule them in beats
# - support seq/par/at/dur style composition
# - render either to a flat scheduled event list, or later to audio / score
#
# Notes:
# - this is intentionally conservative and data-oriented
# - events are represented as arrays of key/value pairs
# - helper functions below form a tiny "object" protocol
# - this draft does NOT yet depend on C++ support beyond what Musil already has
#
# Conventions:
# - time is in beats
# - duration is in beats
# - a scheduled event is an array of pairs including:
#     [ ["kind", "scheduled"], ["start", ...], ["dur", ...], ["event", ...] ]
# - a timeline is:
#     [ ["kind", "timeline"], ["events", [ ...scheduled events... ]] ]
# ============================================================================

# ----------------------------------------------------------------------------
# basic helpers for pair-list objects
# ----------------------------------------------------------------------------

proc kv (k, v) {
    return [k, v]
}

proc obj () {
    return []
}

proc obj_get (o, key) {
    var i = 0
    while (i < len(o)) {
        if (o[i][0] == key) {
            return o[i][1]
        }
        i = i + 1
    }
    return []
}

proc obj_has (o, key) {
    var i = 0
    while (i < len(o)) {
        if (o[i][0] == key) {
            return 1
        }
        i = i + 1
    }
    return 0
}

proc obj_set (o, key, value) {
    var r = []
    var found = 0
    var i = 0
    while (i < len(o)) {
        if (o[i][0] == key) {
            push(r, [key, value])
            found = 1
        } else {
            push(r, o[i])
        }
        i = i + 1
    }
    if (not found) {
        push(r, [key, value])
    }
    return r
}

proc obj_merge (a, b) {
    var r = a
    var i = 0
    while (i < len(b)) {
        r = obj_set(r, b[i][0], b[i][1])
        i = i + 1
    }
    return r
}

# ----------------------------------------------------------------------------
# predicates / accessors
# ----------------------------------------------------------------------------

proc kind_of (x) {
    return obj_get(x, "kind")
}

proc is_timeline (x) {
    return kind_of(x) == "timeline"
}

proc is_scheduled (x) {
    return kind_of(x) == "scheduled"
}

proc timeline_events (tl) {
    return obj_get(tl, "events")
}

proc make_timeline (events) {
    return [
        ["kind", "timeline"],
        ["events", events]
    ]
}

proc empty_timeline () {
    return make_timeline([])
}

proc scheduled_start (x) {
    return obj_get(x, "start")
}

proc scheduled_dur (x) {
    return obj_get(x, "dur")
}

proc scheduled_event (x) {
    return obj_get(x, "event")
}

proc scheduled_end (x) {
    return scheduled_start(x) + scheduled_dur(x)
}

proc timeline_length (tl) {
    var evs = timeline_events(tl)
    var mx = 0
    var i = 0
    while (i < len(evs)) {
        var e = scheduled_end(evs[i])
        if (e > mx) {
            mx = e
        }
        i = i + 1
    }
    return mx
}

# ----------------------------------------------------------------------------
# constants / symbols as plain strings
# ----------------------------------------------------------------------------
# pitches

var C0  = "C0"
var Cs0 = "C#0"
var D0  = "D0"
var Ds0 = "D#0"
var E0  = "E0"
var F0  = "F0"
var Fs0 = "F#0"
var G0  = "G0"
var Gs0 = "G#0"
var A0  = "A0"
var As0 = "A#0"
var B0  = "B0"

var C1  = "C1"
var Cs1 = "C#1"
var D1  = "D1"
var Ds1 = "D#1"
var E1  = "E1"
var F1  = "F1"
var Fs1 = "F#1"
var G1  = "G1"
var Gs1 = "G#1"
var A1  = "A1"
var As1 = "A#1"
var B1  = "B1"

var C2  = "C2"
var Cs2 = "C#2"
var D2  = "D2"
var Ds2 = "D#2"
var E2  = "E2"
var F2  = "F2"
var Fs2 = "F#2"
var G2  = "G2"
var Gs2 = "G#2"
var A2  = "A2"
var As2 = "A#2"
var B2  = "B2"

var C3  = "C3"
var Cs3 = "C#3"
var D3  = "D3"
var Ds3 = "D#3"
var E3  = "E3"
var F3  = "F3"
var Fs3 = "F#3"
var G3  = "G3"
var Gs3 = "G#3"
var A3  = "A3"
var As3 = "A#3"
var B3  = "B3"

var C4  = "C4"
var Cs4 = "C#4"
var D4  = "D4"
var Ds4 = "D#4"
var E4  = "E4"
var F4  = "F4"
var Fs4 = "F#4"
var G4  = "G4"
var Gs4 = "G#4"
var A4  = "A4"
var As4 = "A#4"
var B4  = "B4"

var C5  = "C5"
var Cs5 = "C#5"
var D5  = "D5"
var Ds5 = "D#5"
var E5  = "E5"
var F5  = "F5"
var Fs5 = "F#5"
var G5  = "G5"
var Gs5 = "G#5"
var A5  = "A5"
var As5 = "A#5"
var B5  = "B5"

var C6  = "C6"
var Cs6 = "C#6"
var D6  = "D6"
var Ds6 = "D#6"
var E6  = "E6"
var F6  = "F6"
var Fs6 = "F#6"
var G6  = "G6"
var Gs6 = "G#6"
var A6  = "A6"
var As6 = "A#6"
var B6  = "B6"

# dynamics
var ppp = "ppp"
var pp  = "pp"
var p   = "p"
var mp  = "mp"
var mf  = "mf"
var f   = "f"
var ff  = "ff"
var fff = "fff"

# techniques / articulations
var ord      = "ordinario"
var pizz     = "pizzicato"
var arco     = "arco"
var sulpont  = "sul_ponticello"
var sultasto = "sul_tasto"
var trem     = "tremolo"
var ten      = "tenuto"
var stacc    = "staccato"
var accent   = "accent"

# instruments
var Vl   = "Vl"
var Vla  = "Vla"
var Vc   = "Vc"
var Cb   = "Cb"
var Fl   = "Fl"
var Ob   = "Ob"
var Cl   = "Cl"
var Bn   = "Bn"
var Hn   = "Hn"
var Tpt  = "Tpt"
var Tbn  = "Tbn"
var Tba  = "Tba"
var Hp   = "Hp"
var Pf   = "Pf"
var Vibe = "Vibraphone"

# durations in beats (assuming quarter = 1 beat)
var w  = 4
var h  = 2
var q  = 1
var e  = 0.5
var s  = 0.25
var t  = 0.125

# ----------------------------------------------------------------------------
# primitive musical / audio events (unscheduled)
# ----------------------------------------------------------------------------

proc note (pitch, dyn, tech, instr) {
    return [
        ["kind",  "note"],
        ["pitch", pitch],
        ["dyn",   dyn],
        ["tech",  tech],
        ["instr", instr]
    ]
}

proc chord (pitches, dyn, tech, instr) {
    return [
        ["kind",   "chord"],
        ["pitches", pitches],
        ["dyn",    dyn],
        ["tech",   tech],
        ["instr",  instr]
    ]
}

proc rest () {
    return [
        ["kind", "rest"]
    ]
}

proc soundfile (path) {
    return [
        ["kind", "soundfile"],
        ["path", path]
    ]
}

proc synth (name, params) {
    return [
        ["kind",   "synth"],
        ["name",   name],
        ["params", params]
    ]
}

proc tempo (bpm) {
    return [
        ["kind", "tempo"],
        ["bpm",  bpm]
    ]
}

proc meter (num, den) {
    return [
        ["kind", "meter"],
        ["num",  num],
        ["den",  den]
    ]
}

proc text (s) {
    return [
        ["kind", "text"],
        ["text", s]
    ]
}

proc marker (name) {
    return [
        ["kind", "marker"],
        ["name", name]
    ]
}

# ----------------------------------------------------------------------------
# scheduling primitives
# ----------------------------------------------------------------------------

proc sched (start, dur, ev) {
    return [
        ["kind",  "scheduled"],
        ["start", start],
        ["dur",   dur],
        ["event", ev]
    ]
}

proc dur (beats, x) {
    if (is_timeline(x)) {
        var evs = timeline_events(x)
        var r = []
        var i = 0
        while (i < len(evs)) {
            var e0 = evs[i]
            push(r, sched(scheduled_start(e0), beats, scheduled_event(e0)))
            i = i + 1
        }
        return make_timeline(r)
    }
    return make_timeline([sched(0, beats, x)])
}

proc at (start, x) {
    if (is_timeline(x)) {
        var evs = timeline_events(x)
        var r = []
        var i = 0
        while (i < len(evs)) {
            var e0 = evs[i]
            push(r, sched(start + scheduled_start(e0), scheduled_dur(e0), scheduled_event(e0)))
            i = i + 1
        }
        return make_timeline(r)
    }

    # default duration 0 for instantaneous events if user schedules a raw event directly
    return make_timeline([sched(start, 0, x)])
}

proc shift (dt, x) {
    return at(dt, x)
}

proc stretch (k, x) {
    if (not is_timeline(x)) {
        return x
    }

    var evs = timeline_events(x)
    var r = []
    var i = 0
    while (i < len(evs)) {
        var e0 = evs[i]
        push(r,
            sched(
                scheduled_start(e0) * k,
                scheduled_dur(e0) * k,
                scheduled_event(e0)
            )
        )
        i = i + 1
    }
    return make_timeline(r)
}

# ----------------------------------------------------------------------------
# flattening helpers
# ----------------------------------------------------------------------------

proc as_timeline (x) {
    if (is_timeline(x)) {
        return x
    }
    return make_timeline([sched(0, 0, x)])
}

proc flatten_args (xs) {
    var r = []
    var i = 0
    while (i < len(xs)) {
        var x = xs[i]
        if (is_timeline(x)) {
            var evs = timeline_events(x)
            var j = 0
            while (j < len(evs)) {
                push(r, evs[j])
                j = j + 1
            }
        } else {
            push(r, sched(0, 0, x))
        }
        i = i + 1
    }
    return r
}

# ----------------------------------------------------------------------------
# combinators
# ----------------------------------------------------------------------------

proc par (xs) {
    return make_timeline(flatten_args(xs))
}

proc seq (xs) {
    var offset = 0
    var r = []
    var i = 0

    while (i < len(xs)) {
        var tl = as_timeline(xs[i])
        tl = shift(offset, tl)

        var evs = timeline_events(tl)
        var j = 0
        while (j < len(evs)) {
            push(r, evs[j])
            j = j + 1
        }

        offset = offset + timeline_length(as_timeline(xs[i]))
        i = i + 1
    }

    return make_timeline(r)
}

proc repeat (n, x) {
    var r = []
    var i = 0
    while (i < n) {
        push(r, x)
        i = i + 1
    }
    return seq(r)
}

# ----------------------------------------------------------------------------
# score-like sugar
# ----------------------------------------------------------------------------

proc qn (ev) {
    return dur(q, ev)
}

proc hn (ev) {
    return dur(h, ev)
}

proc wn (ev) {
    return dur(w, ev)
}

proc en (ev) {
    return dur(e, ev)
}

proc sn (ev) {
    return dur(s, ev)
}

proc tn (ev) {
    return dur(t, ev)
}

proc line (instr, xs) {
    var r = []
    var i = 0
    while (i < len(xs)) {
        var x = xs[i]
        if (is_timeline(x)) {
            var evs = timeline_events(x)
            var j = 0
            var loc = []
            while (j < len(evs)) {
                var se = evs[j]
                var ev = scheduled_event(se)
                if (kind_of(ev) == "note" or  kind_of(ev) == "chord") {
                    ev = obj_set(ev, "instr", instr)
                }
                push(loc, sched(scheduled_start(se), scheduled_dur(se), ev))
                j = j + 1
            }
            push(r, make_timeline(loc))
        } else {
            if (kind_of(x) == "note" or  kind_of(x) == "chord") {
                x = obj_set(x, "instr", instr)
            }
            push(r, x)
        }
        i = i + 1
    }
    return seq(r)
}

proc part (instr, x) {
    return line(instr, [x])
}

# small constructors for lighter notation inside line/seq
proc nq (pitch, dyn, tech, instr) {
    return qn(note(pitch, dyn, tech, instr))
}

proc nh (pitch, dyn, tech, instr) {
    return hn(note(pitch, dyn, tech, instr))
}

proc ne (pitch, dyn, tech, instr) {
    return en(note(pitch, dyn, tech, instr))
}

proc ns (pitch, dyn, tech, instr) {
    return sn(note(pitch, dyn, tech, instr))
}

# instrument-inheriting note wrappers for line()
proc q_note (pitch, dyn, tech) {
    return qn(note(pitch, dyn, tech, ""))
}

proc h_note (pitch, dyn, tech) {
    return hn(note(pitch, dyn, tech, ""))
}

proc e_note (pitch, dyn, tech) {
    return en(note(pitch, dyn, tech, ""))
}

proc s_note (pitch, dyn, tech) {
    return sn(note(pitch, dyn, tech, ""))
}

# ----------------------------------------------------------------------------
# transformations / queries
# ----------------------------------------------------------------------------

proc collect_events_of_kind (tl, k) {
    var evs = timeline_events(as_timeline(tl))
    var r = []
    var i = 0
    while (i < len(evs)) {
        if (kind_of(scheduled_event(evs[i])) == k) {
            push(r, evs[i])
        }
        i = i + 1
    }
    return make_timeline(r)
}

proc extract_part (tl, instr) {
    var evs = timeline_events(as_timeline(tl))
    var r = []
    var i = 0
    while (i < len(evs)) {
        var ev = scheduled_event(evs[i])
        if (obj_has(ev, "instr") and  obj_get(ev, "instr") == instr) {
            push(r, evs[i])
        }
        i = i + 1
    }
    return make_timeline(r)
}

proc map_dyn (tl, old_dyn, new_dyn) {
    var evs = timeline_events(as_timeline(tl))
    var r = []
    var i = 0
    while (i < len(evs)) {
        var se = evs[i]
        var ev = scheduled_event(se)
        if (obj_has(ev, "dyn") and  obj_get(ev, "dyn") == old_dyn) {
            ev = obj_set(ev, "dyn", new_dyn)
        }
        push(r, sched(scheduled_start(se), scheduled_dur(se), ev))
        i = i + 1
    }
    return make_timeline(r)
}

proc map_instr (tl, old_instr, new_instr) {
    var evs = timeline_events(as_timeline(tl))
    var r = []
    var i = 0
    while (i < len(evs)) {
        var se = evs[i]
        var ev = scheduled_event(se)
        if (obj_has(ev, "instr") and  obj_get(ev, "instr") == old_instr) {
            ev = obj_set(ev, "instr", new_instr)
        }
        push(r, sched(scheduled_start(se), scheduled_dur(se), ev))
        i = i + 1
    }
    return make_timeline(r)
}

# ----------------------------------------------------------------------------
# sorting (simple insertion sort by start time)
# ----------------------------------------------------------------------------

proc insert_scheduled_sorted (xs, x) {
    var r = []
    var placed = 0
    var i = 0
    while (i < len(xs)) {
        if (not placed and  scheduled_start(x) < scheduled_start(xs[i])) {
            push(r, x)
            placed = 1
        }
        push(r, xs[i])
        i = i + 1
    }
    if (not placed) {
        push(r, x)
    }
    return r
}

proc sort_timeline (tl) {
    var evs = timeline_events(as_timeline(tl))
    var r = []
    var i = 0
    while (i < len(evs)) {
        r = insert_scheduled_sorted(r, evs[i])
        i = i + 1
    }
    return make_timeline(r)
}

# ----------------------------------------------------------------------------
# rendering helpers
# ----------------------------------------------------------------------------

proc bpm_to_spb (bpm) {
    return 60 / bpm
}

proc tempo_map_default () {
    return 60
}

proc event_to_string (ev) {
    var k = kind_of(ev)

    if (k == "note") {
        return "note pitch=" + obj_get(ev, "pitch") +
               " dyn=" + obj_get(ev, "dyn") +
               " tech=" + obj_get(ev, "tech") +
               " instr=" + obj_get(ev, "instr")
    }

    if (k == "chord") {
        return "chord instr=" + obj_get(ev, "instr")
    }

    if (k == "soundfile") {
        return "soundfile path=" + obj_get(ev, "path")
    }

    if (k == "synth") {
        return "synth name=" + obj_get(ev, "name")
    }

    if (k == "tempo") {
        return "tempo bpm=" + str(obj_get(ev, "bpm"))
    }

    if (k == "meter") {
        return "meter"
    }

    if (k == "text") {
        return "text " + obj_get(ev, "text")
    }

    if (k == "marker") {
        return "marker " + obj_get(ev, "name")
    }

    if (k == "rest") {
        return "rest"
    }

    return "event"
}

proc render_score_events (tl) {
    var evs = timeline_events(sort_timeline(as_timeline(tl)))
    var r = []
    var i = 0
    while (i < len(evs)) {
        var se = evs[i]
        push(r,
            "t=" + str(scheduled_start(se)) +
            " dur=" + str(scheduled_dur(se)) +
            " :: " + event_to_string(scheduled_event(se))
        )
        i = i + 1
    }
    return r
}

# This is a placeholder. A real implementation will later dispatch on event kind:
# - note/chord -> sample selection or synthesis
# - soundfile  -> readwav + placement in mix
# - synth      -> invoke generator
#
# For now render_audio_plan returns a normalized list with onset/duration in seconds.
proc render_audio_plan (tl, bpm) {
    var evs = timeline_events(sort_timeline(as_timeline(tl)))
    var sec_per_beat = bpm_to_spb(bpm)
    var r = []
    var i = 0

    while (i < len(evs)) {
        var se = evs[i]
        var ev = scheduled_event(se)

        push(r,
            [
                ["kind", "audio_plan_event"],
                ["start_beats", scheduled_start(se)],
                ["dur_beats", scheduled_dur(se)],
                ["start_sec", scheduled_start(se) * sec_per_beat],
                ["dur_sec", scheduled_dur(se) * sec_per_beat],
                ["event", ev]
            ]
        )

        i = i + 1
    }

    return r
}

# ----------------------------------------------------------------------------
# example generators
# ----------------------------------------------------------------------------

proc cycle (xs, n) {
    var r = []
    var i = 0
    while (i < n) {
        push(r, xs[mod (i, len(xs))])
        i = i + 1
    }
    return r
}

proc simple_line (instr, pitches, n, dyn, tech, unit_dur) {
    var xs = []
    var i = 0
    while (i < n) {
        push(xs, dur(unit_dur, note(pitches[mod (i, len(pitches))], dyn, tech, instr)))
        i = i + 1
    }
    return seq(xs)
}

proc drone (instr, pitch, dyn, tech, total_dur) {
    return dur(total_dur, note(pitch, dyn, tech, instr))
}

# ----------------------------------------------------------------------------
# debug / examples
# ----------------------------------------------------------------------------

proc music_example () {
    var vl = line(Vl, [
        q_note(A4, pp, ord),
        q_note(B4, p, ord),
        h_note(C5, mp, ten)
    ])

    var vc = at(2,
        dur(4,
            note(C3, pp, sulpont, Vc)
        )
    )

    var tape = at(0, dur(8, soundfile("sea.wav")))
    var syn  = at(6, dur(3, synth("fm", [["freq", 440], ["amp", 0.2]])))
    var txt  = at(0, text("calmo"))
    var tmp  = at(0, tempo(72))
    var met  = at(0, meter(4, 4))

    return par([tmp, met, txt, vl, vc, tape, syn])
}

proc music_print_example () {
    var piece = music_example()
    var score = render_score_events(piece)

    var i = 0
    while (i < len(score)) {
        print score[i]
        i = i + 1
    }
}

# ============================================================================
# end of music.mu
# ============================================================================
