load("signals.mu")

var wav_info = readwav("../../data/cage.wav")
var sr       = wav_info[0]
var chans    = wav_info[1]
var w        = chans[0]

print "lowpass\n"

var cutoff_lp = 200
var Q_lp      = 0.707
var w_lp      = lowpass(w, sr, cutoff_lp, Q_lp)
writewav("lp.wav", sr, [w_lp])

print "bandpass (highpass + lowpass cascade)\n"

var cutoff_hp = 2000
var cutoff_bp = 2500
var Q_bp      = 0.707

var w_hp = highpass(w, sr, cutoff_hp, Q_bp)
var w_bp = lowpass(w_hp, sr, cutoff_bp, Q_bp)
writewav("bp.wav", sr, [w_bp])
