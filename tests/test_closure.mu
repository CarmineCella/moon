# Musil closure / lexical scope / continue test suite
# Assumes stdlib-like helpers are already available if your runner loads them,
# but this file itself only relies on core language features.

print "=== test suite: core_closure ==="

proc assert_eq(label, a, b) {
    if (a == b) {
        print "PASS: " label
    } else {
        print "FAIL: " label " expected=" b " got=" a
    }
}

proc assert_true(label, cond) {
    if (cond) {
        print "PASS: " label
    } else {
        print "FAIL: " label " expected true"
    }
}

proc assert_false(label, cond) {
    if (cond) {
        print "FAIL: " label " expected false"
    } else {
        print "PASS: " label
    }
}

# ------------------------------------------------------------
# 1. lexical scope / shadowing
# ------------------------------------------------------------

var x = 100
proc read_global() {
    return x
}
assert_eq("global lookup from proc", read_global(), 100)

proc local_shadow() {
    var x = 7
    return x
}
assert_eq("local shadow inside proc", local_shadow(), 7)
assert_eq("global preserved after local shadow", x, 100)

# ------------------------------------------------------------
# 2. closure capture of outer variables
# ------------------------------------------------------------

proc make_adder(n) {
    proc adder(x) {
        return x + n
    }
    return adder
}

var add10 = make_adder(10)
var add3  = make_adder(3)
assert_eq("closure capture 10", add10(5), 15)
assert_eq("closure capture 3", add3(8), 11)
assert_eq("closures keep independent environments", add10(1), 11)

# ------------------------------------------------------------
# 3. nested closure + multi-level lexical scope
# ------------------------------------------------------------

proc make_affine(a) {
    proc with_b(b) {
        proc f(x) {
            return a * x + b
        }
        return f
    }
    return with_b
}

var affine2 = make_affine(2)
var f = affine2(5)
assert_eq("multi-level lexical scope", f(10), 25)

# ------------------------------------------------------------
# 4. closure should see surrounding bindings, not caller bindings
# ------------------------------------------------------------

var z = 1000
proc make_reader() {
    var z = 42
    proc r() {
        return z
    }
    return r
}

var r = make_reader()
proc caller_with_other_z(fun) {
    var z = 9999
    return fun()
}
assert_eq("lexical scope not dynamic scope", caller_with_other_z(r), 42)

# ------------------------------------------------------------
# 5. recursive named proc still works
# ------------------------------------------------------------

proc fact(n) {
    if (n <= 1) {
        return 1
    } else {
        return n * fact(n - 1)
    }
}
assert_eq("recursive named proc", fact(6), 720)

# ------------------------------------------------------------
# 6. closure with mutable captured variable
# ------------------------------------------------------------

proc make_counter(start) {
    var n = start
    proc next() {
        n = n + 1
        return n
    }
    return next
}

var c1 = make_counter(0)
var c2 = make_counter(10)
assert_eq("counter c1 first", c1(), 1)
assert_eq("counter c1 second", c1(), 2)
assert_eq("counter c2 independent", c2(), 11)
assert_eq("counter c1 third", c1(), 3)

# ------------------------------------------------------------
# 7. returning proc from inner lexical scope after outer exited
# ------------------------------------------------------------

proc outer(seed) {
    var acc = seed
    proc push(v) {
        acc = acc + v
        return acc
    }
    return push
}

var p = outer(100)
assert_eq("closure survives outer return 1", p(7), 107)
assert_eq("closure survives outer return 2", p(8), 115)

# ------------------------------------------------------------
# 8. continue in while
# ------------------------------------------------------------

var i = 0
var s = 0
while (i < 10) {
    i = i + 1
    if (i == 3) {
        continue
    }
    if (i == 7) {
        continue
    }
    s = s + i
}
# 1+2+4+5+6+8+9+10 = 45
assert_eq("continue in while", s, 45)

# ------------------------------------------------------------
# 9. continue in for over array
# ------------------------------------------------------------

var arr = [1, 2, 3, 4, 5]
var sf = 0
for (var x in arr) {
    if (x == 2) {
        continue
    }
    if (x == 4) {
        continue
    }
    sf = sf + x
}
assert_eq("continue in for array", sf, 9)

# ------------------------------------------------------------
# 10. continue in for over string
# ------------------------------------------------------------

var txt = "abcde"
var out = ""
for (var ch in txt) {
    if (ch == "b") {
        continue
    }
    if (ch == "d") {
        continue
    }
    out = out + ch
}
assert_eq("continue in for string", out, "ace")

# ------------------------------------------------------------
# 11. closure called inside loop with external captured state
# ------------------------------------------------------------

proc make_stepper(step) {
    var x = 0
    proc tick() {
        x = x + step
        return x
    }
    return tick
}

var step2 = make_stepper(2)
var tot = 0
var k = 0
while (k < 4) {
    tot = tot + step2()
    k = k + 1
}
# 2 + 4 + 6 + 8 = 20
assert_eq("closure state across repeated calls", tot, 20)

# ------------------------------------------------------------
# 12. proc passed as value
# ------------------------------------------------------------

proc apply_twice(f, x) {
    return f(f(x))
}
proc inc(x) {
    return x + 1
}
assert_eq("first-class proc argument", apply_twice(inc, 5), 7)
assert_eq("closure as proc argument", apply_twice(add10, 0), 20)

# ------------------------------------------------------------
# 13. nested closures with shadowed names
# ------------------------------------------------------------

var q = 1
proc mk() {
    var q = 2
    proc a() {
        var q = 3
        proc b() {
            return q
        }
        return b
    }
    return a
}
var aa = mk()
var bb = aa()
assert_eq("nearest lexical binding wins", bb(), 3)
assert_eq("global q still preserved", q, 1)

# ------------------------------------------------------------
# 14. continue should not terminate loop
# ------------------------------------------------------------

var csum = 0
for (var n in [1,2,3,4,5,6]) {
    if (n < 4) {
        continue
    }
    csum = csum + n
}
assert_eq("continue skips but loop continues", csum, 15)

# ------------------------------------------------------------
# 15. closure mutating captured array binding
# ------------------------------------------------------------

proc make_box(v) {
    var box = [v]
    proc put(x) {
        box[0] = x
        return box[0]
    }
    return put
}
var putx = make_box(9)
assert_eq("closure captures array binding 1", putx(12), 12)
assert_eq("closure captures array binding 2", putx(14), 14)

print "=== end test suite ==="
