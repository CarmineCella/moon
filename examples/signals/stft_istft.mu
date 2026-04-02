load("signals.mu")

var snd   = readwav("../../data/Vox.wav")
var sr    = snd[0]
var chans = snd[1]

var N   = 2048
var hop = floor(N / 8)
var ch  = chans[0]

var specs = stft(ch, N, hop)
var recon = istft(specs, N, hop)
writewav("Vox_stft_istft_test.wav", sr, [recon])

var ratio   = 2
var outhop  = hop * ratio
var stretch = istft(specs, N, outhop)
writewav("Vox_stft_istft_2x.wav", sr, [stretch])

ch = resample(ch, 2)
writewav("Vox_resampled_2down.wav", sr, [ch])
