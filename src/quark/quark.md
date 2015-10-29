
### BINOP

| # | name |
|---|------|
| 0 | SLL
| 1 | SRL
| 2 | SRA
| 3 | ADD
| 4 | SUB
| 5 | XOR
| 6 | OR
| 7 | AND
| 8 | MUL
| 9 | MULU
| A | DIV
| B | DIVU
| C | REM
| D | REMU


```forth
: ?    ( -- ) ;
: call ( -- | -- a ) pc @ R> LIT# GOTO ;
: exit ( -- | a -- ) R> GOTO ;
: next ( -- |  )
```
