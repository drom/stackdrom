000 @p+ @p+ call 7
001 8
002 C
003 jump 3

004 dup push not .
005 + @p+ pop +
006 1

007 if B
008 not over . +
009 -if 4
00A not jump 7
00B drop ;
