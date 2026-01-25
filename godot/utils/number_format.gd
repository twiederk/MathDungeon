class_name NumberFormat


func format(input: int) -> String:
	var num_str = str(input)
	var result = ""
	var count = 0
	
	# Iterate from right to left
	for i in range(num_str.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "." + result
		result = num_str[i] + result
		count += 1
	
	return result
