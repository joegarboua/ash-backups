package handlers

import (
	"strings"

	qrcode "github.com/skip2/go-qrcode"
)

// GenerateUnicodeQR creates a terminal-friendly QR code using Unicode block characters.
// Returns a string that can be printed in any terminal.
func GenerateUnicodeQR(content string) (string, error) {
	qr, err := qrcode.New(content, qrcode.Medium)
	if err != nil {
		return "", err
	}
	qr.DisableBorder = false
	bitmap := qr.Bitmap()
	rows := len(bitmap)
	cols := 0
	if rows > 0 {
		cols = len(bitmap[0])
	}

	var sb strings.Builder

	// Process two rows at a time using half-block characters
	// Upper half = top row, lower half = bottom row
	// █ = both black, ▀ = top black, ▄ = bottom black, ' ' = both white
	for y := 0; y < rows; y += 2 {
		for x := 0; x < cols; x++ {
			top := bitmap[y][x] // true = black
			bot := false
			if y+1 < rows {
				bot = bitmap[y+1][x]
			}
			// Invert: QR black modules = white on terminal (dark background)
			if !top && !bot {
				sb.WriteRune('█')
			} else if !top && bot {
				sb.WriteRune('▀')
			} else if top && !bot {
				sb.WriteRune('▄')
			} else {
				sb.WriteRune(' ')
			}
		}
		sb.WriteRune('\n')
	}

	return sb.String(), nil
}
