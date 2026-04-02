load("signals.mu")

var N   = 4096
var hop = floor(N / 4)
var SR  = 44100
var frame = N / SR

var snd = readwav("../../data/Gambale_cut.wav")
var sr  = snd[0]
var sig = snd[1][0]

var spec_list = stft(sig, N, hop)
var nframes   = len(spec_list)

var amps = []
var phis = []
var i = 0
while (i < nframes) {
    var mp = deinterleave(car2pol(spec_list[i]))
    push(amps, mp[0])
    push(phis, mp[1])
    i = i + 1
}

var clusters = kmeans(amps, 2)
var labels   = clusters[0]

var tamps = []
var samps = []
var j = 0
while (j < nframes) {
    var a   = amps[j]
    var lab = labels[j]
    push(tamps, a * (1 - lab))
    push(samps, a * lab)
    j = j + 1
}

var imre_t = []
var imre_s = []
var k = 0
while (k < nframes) {
    push(imre_t, pol2car(interleave([tamps[k], phis[k]])))
    push(imre_s, pol2car(interleave([samps[k], phis[k]])))
    k = k + 1
}

var sig_t = istft(imre_t, N, hop)
var sig_s = istft(imre_s, N, hop)

writewav("component_1.wav", sr, [sig_t])
writewav("component_2.wav", sr, [sig_s])
