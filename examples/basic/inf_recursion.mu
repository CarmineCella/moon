proc rec (a) {
	print a
	
	rec (a + 1)
}


# this example will stop reaching max recursion depth
rec (0)
