# break: exit loops early

# find first multiple of 7 above 50
var i = 50
while (1) {
    var r = i - floor(i / 7) * 7
    if (r == 0) {
        print "first multiple of 7 >= 50: " i
        break
    }
    i = i + 1
}

# break from nested structure: only breaks inner while
proc find_pair (target) {
    var x = 1
    while (x <= target) {
        var y = x
        while (y <= target) {
            if (x + y == target) {
                print "pair summing to " target ": " x " + " y
                break   # exits inner while only
            }
            y = y + 1
        }
        if (x + x == target) { break }   # exit outer when done
        x = x + 1
    }
}
find_pair(10)
find_pair(7)

# break in while with accumulator
var count = 0
var n = 2
while (n < 1000) {
    # check if n is prime (trial division)
    var is_prime = 1
    var d = 2
    while (d * d <= n) {
        var r = n - floor(n / d) * d
        if (r == 0) { is_prime = 0   break }
        d = d + 1
    }
    if (is_prime) { count = count + 1 }
    n = n + 1
}
print "primes below 1000: " count
