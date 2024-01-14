package wcwidth

/*
 * Copyright (C) 2024 Mason Austin Green
 * Distributed under the MIT License.
 *
 * Implementation of wcwidth as an Odin port of:
 * https://github.com/jquast/wcwidth
 *
 */

import "core:unicode/utf8"
import "core:strings"

Interval :: struct {
	first, last: rune,
}

Table :: []Interval

bisearch :: proc(r: rune, t: Table) -> bool {
	lbound := 0
	ubound := len(t) - 1

	if r < t[0].first || r > t[ubound].last do return false

	for ubound >= lbound {
		mid := (lbound + ubound) >> 1
		if r > t[mid].last {
			lbound = mid + 1
		} else if r < t[mid].first {
			ubound = mid - 1
		} else {
			return true
		}
	}

	return false
}

// procedure alias
rune_width :: wcwidth

// Return the visible rune width
wcwidth :: proc(r: rune) -> int {
	// small optimization: early return of 1 for printable ASCII, this provides
	// approximately 40% performance improvement for mostly-ascii documents, with
	// less than 1% impact to others.
	if 32 <= r && r < 0x7f do return 1

	// C0/C1 control characters are -1 for compatibility with POSIX-like calls
	if r < 32 || (0x07F <= r && r < 0x0A0) do return -1

	// Zero width
	if bisearch(r, ZERO_WIDTH) do return 0

	// 1 or 2 width
	return bisearch(r, WIDE_EASTASIAN) ? 2 : 1

}

// procedure alias
string_width :: wcswidth

// Return the visible string width
wcswidth :: proc(s: string) -> int {
	runes := utf8.string_to_runes(s)
	end := len(runes)
	width, idx: int
	last_measured: rune
	for idx < end {
		r := runes[idx]
		if r == '\u200D' {
			// Zero Width Joiner, do not measure this or next character
			idx += 2
			continue
		}
		if r == '\uFE0F' && last_measured != 0 {
			// on variation selector 16 (VS16) following another character,
			// conditionally add '1' to the measured width if that character is
			// known to be converted from narrow to wide by the VS16 character.
			width += bisearch(last_measured, VS16_NARROW_TO_WIDE) ? 1 : 0
			last_measured = 0
			idx += 1
			continue
		}
		// measure character at current index
		wcw := wcwidth(r)
		// early return -1 on C0 and C1 control characters
		if wcw < 0 do return wcw
		// track last character measured to contain a cell, so that
		// subsequent VS-16 modifiers may be understood
		if wcw > 0 do last_measured = r

		width += wcw
		idx += 1
	}

	return width
}

// Truncate return string with size cells
truncate :: proc(s: string, size: int, tail: string) -> string {
	if wcswidth(s) <= size do return s
	w := size - wcswidth(tail)
	width: int
	pos := len(s)
	runes := utf8.string_to_runes(s)
	for r in runes {
		rw := wcwidth(r)
		if width + rw > w {
			pos = width
			break
		}
		width += rw
	}
	str := utf8.runes_to_string(runes[:pos])
	a := [2]string{str, tail}
	return strings.concatenate(a[:])
}
