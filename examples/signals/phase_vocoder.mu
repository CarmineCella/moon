load("signals.mu")

proc pvoc(sig, stretch, semitones, N, hop) {
    var Ha = hop
    var specs = stft(sig, N, Ha)
    var nframes = len(specs)
    if (nframes == 0) {
        return zeros(1)
    }

    var pi = 3.141592653589793
    var two_pi = 2.0 * pi
    var pitch_ratio = exp(log(2.0) * (semitones / 12.0))
    var A = stretch * pitch_ratio
    var Hs = floor(Ha * A)

    var kidx = linspace(0, N - 1, N)
    var omega = kidx * (two_pi / N)

    var out_specs = []

    var spec0    = specs[0]
    var magphi0  = deinterleave(car2pol(spec0))
    var amps0    = magphi0[0]
    var phi0_in  = magphi0[1]
    var phi0_out = phi0_in

    push(out_specs, pol2car(interleave([amps0, phi0_out])))

    var prev_phi_in  = phi0_in
    var prev_phi_out = phi0_out

    var f = 1
    while (f < nframes) {
        var mp     = deinterleave(car2pol(specs[f]))
        var amps   = mp[0]
        var phi_in = mp[1]

        var delta      = phi_in - prev_phi_in
        var expected   = omega * Ha
        var delta_p    = delta - expected
        var q          = floor((delta_p + pi) / two_pi)
        var delta_wrap = delta_p - (q * two_pi)
        var inst_freq  = omega + (delta_wrap / Ha)
        var phi_out    = prev_phi_out + (inst_freq * Hs)

        push(out_specs, pol2car(interleave([amps, phi_out])))
        prev_phi_in  = phi_in
        prev_phi_out = phi_out
        f = f + 1
    }

    var y_pv = istft(out_specs, N, Hs)
    var resamp_factor = 1.0 / pitch_ratio
    return resample(y_pv, resamp_factor)
}

var snd   = readwav("../../data/Vox.wav")
var sr    = snd[0]
var ch    = snd[1][0]
var N     = 2048
var hop   = floor(N / 8)

var out1 = pvoc(ch, 2.0, 0, N, hop)
writewav("Vox_pvoc_2x_time.wav", sr, [out1])

var out2 = pvoc(ch, 1.0, 5, N, hop)
writewav("Vox_pvoc_up5st.wav", sr, [out2])

var out3 = pvoc(ch, 1.5, -3, N, hop)
writewav("Vox_pvoc_1p5x_down3st.wav", sr, [out3])
