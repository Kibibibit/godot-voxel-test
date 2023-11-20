extends Node


func nRn(chance: float, n: int) -> bool:
	var value: float = 0.0
	
	for i in n:
		value += randf()
	
	return value / float(n) <= chance
