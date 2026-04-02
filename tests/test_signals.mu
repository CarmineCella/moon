load("stdlib.mu")
load("signals.mu")

var EPS = 0.00000001

# ---- conv ------------------------------------------------------------

var c = conv(vec(1, 2), vec(3, 4, 5))
assert_near(c[0], 3, EPS, "conv [0]")
assert_near(c[1], 10, EPS, "conv [1]")
assert_near(c[2], 13, EPS, "conv [2]")
assert_near(c[3], 10, EPS, "conv [3]")

# ---- convmc ----------------------------------------------------------

var xchs = arr(2)
xchs[0] = vec(1, 0)
xchs[1] = vec(0, 1)

var ychs = arr(2)
ychs[0] = vec(1, 2)
ychs[1] = vec(3, 4)

var mc = convmc(xchs, ychs)
var ch0 = mc[0]
var ch1 = mc[1]

assert_near(ch0[0], 1, EPS, "convmc ch0 [0]")
assert_near(ch0[1], 2, EPS, "convmc ch0 [1]")
assert_near(ch0[2], 0, EPS, "convmc ch0 [2]")

assert_near(ch1[0], 0, EPS, "convmc ch1 [0]")
assert_near(ch1[1], 3, EPS, "convmc ch1 [1]")
assert_near(ch1[2], 4, EPS, "convmc ch1 [2]")

# ---- deinterleave / interleave packed API ---------------------------

var stereo = vec(10, 20, 11, 21, 12, 22)
var packed = deinterleave(stereo)
var left   = head(packed)
var right  = tail(packed)

assert_eq(len(left), 3, "deinterleave left len")
assert_eq(len(right), 3, "deinterleave right len")
assert_eq(left[0], 10, "left[0]")
assert_eq(left[1], 11, "left[1]")
assert_eq(left[2], 12, "left[2]")
assert_eq(right[0], 20, "right[0]")
assert_eq(right[1], 21, "right[1]")
assert_eq(right[2], 22, "right[2]")

var stereo2 = interleave(packed)
assert_eq(len(stereo2), 6, "interleave len")
assert_eq(stereo2[0], 10, "interleave[0]")
assert_eq(stereo2[1], 20, "interleave[1]")
assert_eq(stereo2[2], 11, "interleave[2]")
assert_eq(stereo2[3], 21, "interleave[3]")
assert_eq(stereo2[4], 12, "interleave[4]")
assert_eq(stereo2[5], 22, "interleave[5]")

# ---- vslice / vaddat -------------------------------------------------

var s = vec(5, 6, 7, 8, 9)
var ss = vslice(s, 1, 3)
assert_eq(len(ss), 3, "vslice len")
assert_eq(ss[0], 6, "vslice[0]")
assert_eq(ss[1], 7, "vslice[1]")
assert_eq(ss[2], 8, "vslice[2]")

var dst = vec(1, 1, 1, 1)
var src = vec(10, 20)
var added = vaddat(dst, 1, src)
assert_eq(len(added), 4, "vaddat len")
assert_eq(added[0], 1, "vaddat[0]")
assert_eq(added[1], 11, "vaddat[1]")
assert_eq(added[2], 21, "vaddat[2]")
assert_eq(added[3], 1, "vaddat[3]")

# ---- filtdesign / filter packed coeffs -------------------------------

var coeffs = filtdesign("lowpass", 48000, 1000, 0.707, 0)
assert_eq(len(coeffs), 6, "filtdesign packed len")
assert_near(coeffs[3], 1, EPS, "filtdesign a0 == 1")

var x = vec(1, 0, 0, 0, 0, 0, 0, 0)
var y = aufilter(x, coeffs)
assert_eq(len(y), len(x), "filter output len")
assert(abs(sum(abs(y))) > 0, "filter produces non-zero output")

# ---- misc signal ops -------------------------------------------------

var w = window(8, 0.5, 0.5, 0.0)
assert_eq(len(w), 8, "window len")

var tbl = gen(16, 1)
assert_eq(len(tbl), 17, "gen guard-point len")

var freqs = vec(440, 440, 440, 440)
var osc_out = osc(44100, freqs, tbl)
assert_eq(len(osc_out), 4, "osc len")

var dc = dcblock(vec(1, 1, 1, 1, 1))
assert_eq(len(dc), 5, "dcblock len")

var rs = resample(vec(1, 2, 3, 4), 0.5)
assert(abs(len(rs) - 2) <= 1, "resample reasonable len")

test_summary()
