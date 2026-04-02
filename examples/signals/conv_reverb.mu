load("signals.mu")

var scale    = 0.1
var mixc     = 0.8
var dry_gain = 1 - mixc
var wet_gain = scale * mixc

var sig_info = readwav("../../data/anechoic1.wav")
var ir_info  = readwav("../../data/Concertgebouw-s.wav")

var sr      = sig_info[0]
var sig_chs = sig_info[1]
var ir_chs  = ir_info[1]

var sigL = sig_chs[0]
var irL  = ir_chs[0]
var irR  = ir_chs[1]

print "input length = " len(sigL) ", IR L length = " len(irL) ", IR R length = " len(irR) "\n"
print "applying convolution...\n"

var wetL = conv(irL, sigL)
var wetR = conv(irR, sigL)

var dryL_scaled = sigL * dry_gain
var wetL_scaled = wetL * wet_gain
var wetR_scaled = wetR * wet_gain

var outsigL = mix(0, wetL_scaled, 0, dryL_scaled)
var outsigR = mix(0, wetR_scaled, 0, dryL_scaled)

print "done. output L length = " len(outsigL) ", R length = " len(outsigR) "\n"
writewav("reverb.wav", sr, [outsigL, outsigR])
print "reverb.wav written\n"
