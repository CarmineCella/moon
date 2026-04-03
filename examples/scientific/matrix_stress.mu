print "matrix multiplication test..."

var a = rand (1000, 1000)
var b = rand (1000, 1000)

#matdisp (matmul (a, b))

matdisp (hadamard (a, b))

print "done"