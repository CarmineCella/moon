load("signals.mu")

var sr      = 44100
var dur     = 1.2
var samps   = floor(dur * sr)
var nyquist = sr / 2
var nwin    = 4096
var offset  = 128

var tab1 = gen(nwin, 1)

print "analysing......"

var wav_info = readwav("../../data/gong_c_sharp.wav")
var chans    = wav_info[1]
var input    = chans[0]

var spec     = fft(input)
var polar    = car2pol(spec)
var magphi   = deinterleave(polar)
var mag0     = head(magphi)
var nfft     = len(mag0)

var mag      = vslice(mag0, offset, nwin)
var fftfreqs0 = linspace(0, sr, nfft)
var fftfreqs  = vslice(fftfreqs0, offset, len(mag))

var amps  = []
var freqs = []
var i     = 0
while (i < len(mag)) {
    var v    = mag[i]
    var vsc  = v * (2 / nfft)
    var enva = linspace(vsc, vsc, samps)
    var envf = linspace(fftfreqs[i], fftfreqs[i], samps)
    push(amps, enva)
    push(freqs, envf)
    i = i + 1
}

print "done\nsynthesising..."

var out = oscbank(sr, amps, freqs, tab1)
var norm = 0.8
var fade = linspace(norm, 0.0, samps)
var out_faded = out * fade

print "done\n"
writewav("reconstructed.wav", sr, [out_faded])
