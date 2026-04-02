load("signals.mu")

var hop = 512
var sz  = 2048

var sig_data = readwav("../../data/Vox.wav")
var sr       = sig_data[0]
var sig_chs  = sig_data[1]
var sig1     = sig_chs[0]

var ir_data  = readwav("../../data/Beethoven_Symph7.wav")
var ir_chs   = ir_data[1]
var sig2     = ir_chs[0]

var sig1_len = len(sig1)
var sig2_len = len(sig2)
var min_len  = sig1_len
if (sig1_len > sig2_len) {
    min_len = sig2_len
}
min_len = min_len - sz

print "sig 1 len = " sig1_len ", sig 2 len = " sig2_len ", min len = " min_len "\n"

var bwin = window(sz, 0.5, 0.5, 0.0)
var outsig = zeros(sz + min_len)
#var half_sz = floor(sz / 2)
var threshold = 0.0001 
#linspace(0.0001, 0.0001, half_sz)

var i = 0
while (i < min_len) {
    var buff1   = vslice(sig1, i, sz) * bwin
    var spec1_p = car2pol(fft(buff1))
    var magphi1 = deinterleave(spec1_p)
    var amps1   = head(magphi1)
    var phi1    = tail(magphi1)
    amps1 = amps1 * (amps1 > threshold)

    var buff2   = vslice(sig2, i, sz) * bwin
    var spec2_p = car2pol(fft(buff2))
    var magphi2 = deinterleave(spec2_p)
    var amps2   = head(magphi2)
    var phi2    = tail(magphi2)

    var outamps = sqrt(amps1 * amps2)
    var outphi  = phi2
    var out_spec = interleave([outamps, outphi])
    var outbuff  = ifft(pol2car(out_spec)) * bwin

    outsig = vaddat(outsig, i, outbuff)
    # var j = 0
    # while (j < len(outbuff)) {
    #     outsig[i + j] = outsig[i + j] + outbuff[j]
    #     j = j + 1
    # }
    i = i + hop
}

writewav("xsynth.wav", sr, [outsig])
