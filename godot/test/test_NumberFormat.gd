extends GutTest

var number_format: NumberFormat = null


func before_each():
	number_format = NumberFormat.new()


func after_each():
	number_format = null


func test_format_three_digits():
	# act
	var result = number_format.format(123)
	
	# assert
	assert_eq(result, "123")


func test_format_four_digits():
	# act
	var result = number_format.format(1234)
	
	# assert
	assert_eq(result, "1.234")


func test_format_seven_digits():
	# act
	var result = number_format.format(1234567)
	
	# assert
	assert_eq(result, "1.234.567")
