load("stdlib.mu")

var sr = 48000

# Stereo
var chL = vec(-1, -0.5, 0, 0.5, 1)
var chR = vec( 1,  0.5, 0, -0.5, -1)
writewav("test_wav_stereo.wav", sr, [chL, chR])
var r = readwav("test_wav_stereo.wav")
var r_sr = r[0]
var r_chs = r[1]

assert_eq(len(r_sr), 1, "stereo sr scalar")
assert_eq(r_sr[0], sr, "stereo sr")
assert_eq(len(r_chs), 2, "stereo nch")
assert_eq(len(r_chs[0]), len(chL), "stereo ch0 len")
assert_eq(len(r_chs[1]), len(chR), "stereo ch1 len")
assert_near(r_chs[0][0], chL[0], 0.0001, "stereo ch0 sample0")
assert_near(r_chs[0][4], chL[4], 0.0001, "stereo ch0 sample4")
assert_near(r_chs[1][0], chR[0], 0.0001, "stereo ch1 sample0")
assert_near(r_chs[1][4], chR[4], 0.0001, "stereo ch1 sample4")

# Mono
var chM = vec(0, 0.25, 0.5, 0.75, 1)
writewav("test_wav_mono.wav", sr, [chM])
var rM = readwav("test_wav_mono.wav")
var rM_sr = rM[0]
var rM_chs = rM[1]

assert_eq(rM_sr[0], sr, "mono sr")
assert_eq(len(rM_chs), 1, "mono nch")
assert_eq(len(rM_chs[0]), len(chM), "mono len")
assert_near(rM_chs[0][4], chM[4], 0.0001, "mono sample4")

test_summary()
