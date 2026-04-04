
var salad = ["lettuce", "tomatoes", "avocado", "oil", "salt", "pepper", "onions"]
for (var ingredient in salad) {
	print "ingredient: " ingredient
}


var vector = rand (10)
for (var i in range (0, len (vector))) {
	if (i > 5) { break }
	print vector[i]
}

var s = "hallo musil!"
for (var i in range (0, len(s))) {
	print "letter: " sub (s, i, i + 1)
}