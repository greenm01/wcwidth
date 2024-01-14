package wcwidth

import "core:fmt"

tests_run, test_failures: int

assert_width :: proc(expected_width: int, r: rune) {
	tests_run += 1
	actual_width := wcwidth(r)
	if actual_width != expected_width {
		fmt.printf(
			"ERROR: wcwidth(U+%04x) returned %d, expected %d\n",
			r,
			actual_width,
			expected_width,
		)
		test_failures += 1
	}
}

main :: proc() {
	assert_width(1, 'a')
	assert_width(1, 'ö')

	// Some wide:
	assert_width(2, 'Ａ')
	assert_width(2, 'Ｂ')
	assert_width(2, 'Ｃ')
	assert_width(2, '中')
	assert_width(2, '文')
	assert_width(2, 0x679C)
	assert_width(2, 0x679D)
	assert_width(2, 0x2070E)
	assert_width(2, 0x20731)

	assert_width(1, 0x11A3)

	assert_width(2, 0x1F428) // Koala emoji.
	assert_width(2, 0x231a) // Watch emoji.

	japanese := "コンニチハ"
	fmt.println(japanese, "len =", wcswidth(japanese))
	mixed := "つのだ⭐HIRO"
	fmt.println(mixed, "len =", wcswidth(mixed))

	// truncate test
	t_size : = 5
	fmt.printf("truncate japanese to visible size %d: %s\n", t_size, truncate(japanese, t_size, "..."))

	if test_failures > 0 do fmt.printf("%d tests FAILED, ", test_failures)
	fmt.printf("%d tests OK\n", tests_run - test_failures)

}
