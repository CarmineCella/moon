load("signals.mu")

var N     = 4096
var hop   = floor(N / 4)
var SR    = 44100
var frame = N / SR
var Nspec = floor(N / 2)

var rw    = readwav("../../data/Vox.wav")
var sig   = rw[1][0]

var data    = stft(sig, N, hop)
var nframes = len(data)
var freqs   = linspace(0, SR / 2.0, Nspec)
var oamps   = zeros(Nspec)

var centr  = zeros(nframes)
var spread = zeros(nframes)
var skew   = zeros(nframes)
var kurt   = zeros(nframes)
var flux   = zeros(nframes)
var irr    = zeros(nframes)
var decr   = zeros(nframes)
var f0b    = zeros(nframes)
var nrg    = zeros(nframes)
var zx     = zeros(nframes)

var i = 0
while (i < nframes) {
    var magphi   = car2pol(data[i])
    var magphi_d = deinterleave(magphi)
    var ampsfull = magphi_d[0]
    var amps     = vslice(ampsfull, 0, Nspec)

    var c  = speccent(amps, freqs)
    var s  = specspread(amps, freqs, c)
    var sk = specskew(amps, freqs, c, s)
    var ku = speckurt(amps, freqs, c, s)
    var fl = specflux(amps, oamps)
    var ir = specirr(amps)
    var de = specdecr(amps)

    centr[i]  = c
    spread[i] = s
    skew[i]   = sk
    kurt[i]   = ku
    flux[i]   = fl
    irr[i]    = ir
    decr[i]   = de
    oamps     = amps

    var seg = vslice(sig, i * hop, N)
    f0b[i] = acorrf0(seg, SR)
    nrg[i] = energy(seg)
    zx[i]  = zcr(seg)
    i = i + 1
}

print len(centr) " " len(f0b) "\n"

# The original Scheme example also plotted descriptors and built a simple
# resynthesis from f0/energy envelopes. That part depended on additional
# higher-level stdlib helpers (plot, median, array2list, map2, ldrop, bpf).
# The core descriptor extraction above is the direct Musil translation.
