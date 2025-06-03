-- First column:    RD for "read", WR for "write", QQ for "quit" (end of sim), or -- for comment
-- Second column:   4-bit address as single hexadecimal character
-- Third column:    16-bit value as 4-digit hexadecimal string, asserted for RD
--
-- Front
WR 0 DEAD
RD 0 DEAD
WR 1 BEEF
RD 1 BEEF
-- Back, out of order
WR F F00D
WR E BAAD
RD E BAAD
RD F F00D
-- Overwrites, random read interleaving
WR 0 0000
WR 1 1111
WR 2 2222
WR 3 FFFF
WR 4 EEEE
WR 4 AAAA
RD 4 AAAA
WR 2 0000
RD 3 FFFF
RD 1 1111
RD 2 0000
WR 0 0F0F
RD 0 0F0F
QQ
