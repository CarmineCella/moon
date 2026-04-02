# ─────────────────────────────────────────────────────────────────────────────
# moon standard library  —  stdlib.moon  (v2, native arrays)
# load with:  load("stdlib.moon")
# ─────────────────────────────────────────────────────────────────────────────

# ── Constants ─────────────────────────────────────────────────────────────────

var PI    = 3.14159265358979
var TAU   = 6.28318530717959
var E     = 2.71828182845905
var PHI   = 1.61803398874989   # golden ratio
var LN2   = 0.693147180559945
var SQRT2 = 1.41421356237310

# ── Core math ─────────────────────────────────────────────────────────────────

proc min (a, b) {
    if (a < b) { return a }
    return b
}

proc max (a, b) {
    if (a > b) { return a }
    return b
}

proc clamp (x, lo, hi) {
    return min(max(x, lo), hi)
}

proc sign (x) {
    if (x > 0) { return 1 }
    if (x < 0) { return -1 }
    return 0
}

proc round (x) {
    return floor(x + 0.5)
}

proc round_to (x, decimals) {
    var factor = pow(10, decimals)
    return floor(x * factor + 0.5) / factor
}

proc mod (a, b) {
    return a - floor(a / b) * b
}

proc even (n) { return mod(n, 2) == 0 }
proc odd  (n) { return mod(n, 2) != 0 }

proc gcd (a, b) {
    a = abs(a)
    b = abs(b)
    while (a != b) {
        while (a > b) { a = a - b }
        while (b > a) { b = b - a }
    }
    return a
}

proc lcm (a, b) {
    return (a / gcd(a, b)) * b
}

proc ipow (base, exp) {
    var r = 1
    while (exp > 0) { r = r * base   exp = exp - 1 }
    return r
}

proc lerp (a, b, t) {
    return a + (b - a) * t
}

proc map_range (x, in_lo, in_hi, out_lo, out_hi) {
    return out_lo + (x - in_lo) * (out_hi - out_lo) / (in_hi - in_lo)
}

proc deg2rad (d) { return d * PI / 180 }
proc rad2deg (r) { return r * 180 / PI }

# ── Number formatting ─────────────────────────────────────────────────────────

proc pad_left (s, w, ch) {
    while (len(s) < w) { s = ch + s }
    return s
}

proc pad_right (s, w, ch) {
    while (len(s) < w) { s = s + ch }
    return s
}

proc fmt_fixed (x, decimals) {
    var neg = x < 0
    x = abs(x)
    if (decimals == 0) {
        var result = str(floor(x + 0.5))
        if (neg) { result = "-" + result }
        return result
    }
    var factor = pow(10, decimals)
    var shifted = floor(x * factor + 0.5)
    var int_part = floor(shifted / factor)
    var frac_part = shifted - int_part * factor
    var frac_str = pad_left(str(frac_part), decimals, "0")
    var result = str(int_part) + "." + frac_str
    if (neg) { result = "-" + result }
    return result
}

# ── String utilities ──────────────────────────────────────────────────────────

proc starts_with (s, prefix) {
    if (len(prefix) > len(s)) { return 0 }
    return sub(s, 0, len(prefix)) == prefix
}

proc ends_with (s, suffix) {
    var sl = len(s)
    var xl = len(suffix)
    if (xl > sl) { return 0 }
    return sub(s, sl - xl, sl) == suffix
}

proc ltrim (s) {
    while (len(s) > 0 and sub(s, 0, 1) == " ") { s = sub(s, 1, len(s)) }
    return s
}

proc rtrim (s) {
    while (len(s) > 0 and sub(s, len(s) - 1, len(s)) == " ") {
        s = sub(s, 0, len(s) - 1)
    }
    return s
}

proc trim (s) { return ltrim(rtrim(s)) }

proc repeat_str (s, n) {
    var out = ""
    while (n > 0) { out = out + s   n = n - 1 }
    return out
}

proc count_str (s, pattern) {
    var count = 0
    var pos = 0
    var plen = len(pattern)
    while (pos < len(s)) {
        var idx = find(sub(s, pos, len(s)), pattern)
        if (idx < 0) { break }
        count = count + 1
        pos = pos + idx + plen
    }
    return count
}

proc replace (s, old_s, new_s) {
    var result = ""
    var olen = len(old_s)
    while (len(s) > 0) {
        var idx = find(s, old_s)
        if (idx < 0) {
            result = result + s
            s = ""
        } else {
            result = result + sub(s, 0, idx) + new_s
            s = sub(s, idx + olen, len(s))
        }
    }
    return result
}

# ── Array operations ──────────────────────────────────────────────────────────
# All operate on native arrays (the [] type).
# Builtins already provided: len, push, pop, insert, remove,
#                            slice, concat, copy, range, join, split,
#                            arr (constructor).

proc arr_sum (a) {
    var s = 0
    for (var x in a) { s = s + x }
    return s
}

proc arr_max (a) {
    var m = a[0]
    for (var x in a) { if (x > m) { m = x } }
    return m
}

proc arr_min (a) {
    var m = a[0]
    for (var x in a) { if (x < m) { m = x } }
    return m
}

proc arr_reverse (a) {
    a = copy(a)
    var lo = 0
    var hi = len(a) - 1
    while (lo < hi) {
        var tmp = a[lo]
        a[lo] = a[hi]
        a[hi] = tmp
        lo = lo + 1
        hi = hi - 1
    }
    return a
}

proc arr_contains (a, val) {
    for (var x in a) { if (x == val) { return 1 } }
    return 0
}

proc arr_sort (a) {
    a = copy(a)
    var n = len(a)
    var i = 0
    while (i < n - 1) {
        var j = 0
        while (j < n - i - 1) {
            if (a[j] > a[j+1]) {
                var tmp = a[j]
                a[j] = a[j+1]
                a[j+1] = tmp
            }
            j = j + 1
        }
        i = i + 1
    }
    return a
}

# ── Assertion / testing ───────────────────────────────────────────────────────

var _tests_run    = 0
var _tests_passed = 0
var _tests_failed = 0

proc assert (cond, msg) {
    _tests_run = _tests_run + 1
    if (cond) {
        _tests_passed = _tests_passed + 1
    } else {
        _tests_failed = _tests_failed + 1
        print "FAIL: " msg
    }
}

proc assert_eq (a, b, msg) {
    _tests_run = _tests_run + 1
    if (a == b) {
        _tests_passed = _tests_passed + 1
    } else {
        _tests_failed = _tests_failed + 1
        print "FAIL: " msg " (got " a " expected " b ")"
    }
}

proc test_summary () {
    print repeat_str("-", 40)
    print "tests run:    " _tests_run
    print "tests passed: " _tests_passed
    if (_tests_failed > 0) {
        print "tests FAILED: " _tests_failed
    } else {
        print "all tests passed."
    }
}
