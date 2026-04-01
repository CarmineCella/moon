# ─────────────────────────────────────────────────────────────────────────────
# moon standard library  —  stdlib.moon
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

# integer mod (works correctly for positive and negative)
proc mod (a, b) {
    return a - floor(a / b) * b
}

proc even (n) { return mod(n, 2) == 0 }
proc odd  (n) { return mod(n, 2) != 0 }

# greatest common divisor (repeated subtraction, integers only)
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

# integer power
proc ipow (base, exp) {
    var r = 1
    while (exp > 0) { r = r * base   exp = exp - 1 }
    return r
}

# linear interpolation
proc lerp (a, b, t) {
    return a + (b - a) * t
}

# map x from [in_lo, in_hi] into [out_lo, out_hi]
proc map_range (x, in_lo, in_hi, out_lo, out_hi) {
    return out_lo + (x - in_lo) * (out_hi - out_lo) / (in_hi - in_lo)
}

proc deg2rad (d) { return d * PI / 180 }
proc rad2deg (r) { return r * 180 / PI }

# ── Number formatting ─────────────────────────────────────────────────────────

# pad string s on left to width w using character ch
proc pad_left (s, w, ch) {
    while (len(s) < w) { s = ch + s }
    return s
}

proc pad_right (s, w, ch) {
    while (len(s) < w) { s = s + ch }
    return s
}

# format number with fixed decimal places
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

# count non-overlapping occurrences of pattern in s
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

# replace all occurrences of old_s with new_s
proc replace (s, old_s, new_s) {
    var result = ""
    var olen = len(old_s)
    var slen = len(s)
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

# ── Encoded arrays ────────────────────────────────────────────────────────────
#
#  Arrays are strings where each element is separated by ASCII unit-separator
#  (character 31, written as a multi-char sentinel).  Values must not contain
#  the sentinel.  Use arr_push, arr_get, arr_set, arr_len, arr_slice.
#
#  Example:
#      var a = arr_make()
#      a = arr_push(a, 10)
#      a = arr_push(a, 20)
#      print arr_get(a, 0)        # "10"
#      print arr_len(a)           # 2

var _SEP = "|~|"   # sentinel unlikely to appear in user data

proc arr_make () { return "" }

proc arr_push (a, val) { return a + str(val) + _SEP }

proc arr_len (a) {
    if (len(a) == 0) { return 0 }
    return count_str(a, _SEP)
}

proc arr_get (a, i) {
    var pos = 0
    var cur = 0
    var slen = len(_SEP)
    while (cur < i) {
        var idx = find(sub(a, pos, len(a)), _SEP)
        if (idx < 0) { return "" }
        pos = pos + idx + slen
        cur = cur + 1
    }
    var rest = sub(a, pos, len(a))
    var end = find(rest, _SEP)
    if (end < 0) { return rest }
    return sub(rest, 0, end)
}

# rebuild array with element i replaced by val
proc arr_set (a, i, val) {
    var n = arr_len(a)
    var out = arr_make()
    var j = 0
    while (j < n) {
        if (j == i) { out = arr_push(out, val) }
        else        { out = arr_push(out, arr_get(a, j)) }
        j = j + 1
    }
    return out
}

proc arr_slice (a, lo, hi) {
    var out = arr_make()
    var i = lo
    while (i < hi) { out = arr_push(out, arr_get(a, i))   i = i + 1 }
    return out
}

# split string s on delimiter, returns encoded array
proc split (s, delim) {
    var arr = arr_make()
    var dlen = len(delim)
    while (1) {
        var idx = find(s, delim)
        if (idx < 0) {
            arr = arr_push(arr, s)
            break
        }
        arr = arr_push(arr, sub(s, 0, idx))
        s = sub(s, idx + dlen, len(s))
    }
    return arr
}

# join encoded array into string with separator
proc join (a, delim) {
    var n = arr_len(a)
    var out = ""
    var i = 0
    while (i < n) {
        if (i > 0) { out = out + delim }
        out = out + arr_get(a, i)
        i = i + 1
    }
    return out
}

# ── Numeric array operations ──────────────────────────────────────────────────

proc arr_sum (a) {
    var n = arr_len(a)
    var s = 0
    var i = 0
    while (i < n) { s = s + num(arr_get(a, i))   i = i + 1 }
    return s
}

proc arr_mean (a) {
    var n = arr_len(a)
    if (n == 0) { return 0 }
    return arr_sum(a) / n
}

proc arr_min (a) {
    var n = arr_len(a)
    if (n == 0) { return 0 }
    var m = num(arr_get(a, 0))
    var i = 1
    while (i < n) { m = min(m, num(arr_get(a, i)))   i = i + 1 }
    return m
}

proc arr_max (a) {
    var n = arr_len(a)
    if (n == 0) { return 0 }
    var m = num(arr_get(a, 0))
    var i = 1
    while (i < n) { m = max(m, num(arr_get(a, i)))   i = i + 1 }
    return m
}

# population standard deviation
proc arr_std (a) {
    var n = arr_len(a)
    if (n == 0) { return 0 }
    var mean = arr_mean(a)
    var sum_sq = 0
    var i = 0
    while (i < n) {
        var d = num(arr_get(a, i)) - mean
        sum_sq = sum_sq + d * d
        i = i + 1
    }
    return sqrt(sum_sq / n)
}

# numeric bubble sort, ascending
proc arr_sort (a) {
    var n = arr_len(a)
    var i = 0
    while (i < n - 1) {
        var j = 0
        while (j < n - i - 1) {
            var x = num(arr_get(a, j))
            var y = num(arr_get(a, j + 1))
            if (x > y) {
                a = arr_set(a, j,     str(y))
                a = arr_set(a, j + 1, str(x))
            }
            j = j + 1
        }
        i = i + 1
    }
    return a
}

# build a numeric range [lo, hi) with given step
proc arr_range (lo, hi, step) {
    var a = arr_make()
    var x = lo
    while (x < hi) { a = arr_push(a, x)   x = x + step }
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
