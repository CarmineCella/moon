# if / else if / else

proc classify (n) {
    if (n < 0) {
        return "negative"
    } else if (n == 0) {
        return "zero"
    } else if (n < 10) {
        return "small"
    } else {
        return "large"
    }
}

print classify(-5)
print classify(0)
print classify(7)
print classify(100)

# if without else
var x = 42
if (x > 40) {
    print "x is big"
}

# nested if
proc fizzbuzz (n) {
    var i = 1
    while (i <= n) {
        var div3 = i - floor(i / 3) * 3
        var div5 = i - floor(i / 5) * 5
        if (div3 == 0 and div5 == 0) {
            print "FizzBuzz"
        } else if (div3 == 0) {
            print "Fizz"
        } else if (div5 == 0) {
            print "Buzz"
        } else {
            print i
        }
        i = i + 1
    }
}
fizzbuzz(15)
