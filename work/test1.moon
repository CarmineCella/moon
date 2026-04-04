# a simple script - this is a comment

load ("a_module.mu") # load another file containing vars and procs

var a = 10
var b = 20

proc sum_two (x, y) {
    return x + y
}

print "the sum is " sum_two (a, b)
var text = "this is a string"

write ("output.txt", text)
var r = read ("output.txt")
print "the file contains: " r   

var g = 1.221332
print "expression: " ( a + b ) * g / 10 - 3.2

var i = 0
while (i < 10) {
    print text
    i = i + 1
}

if (g > 0.5) {
    print "g is big"
} else {
    print "g is small"
}


var h = .532 # float literal with leading dot





