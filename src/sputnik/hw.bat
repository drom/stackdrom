%0\
cd %0\..
cd /d %0\..
perl ../../lib/prep.pl ../hw/stacks.dot > stacks.dot.pl
perl stacks.dot.pl > stacks.dot

perl ../../lib/prep.pl ../hw/source.dot > source.dot.pl
perl source.dot.pl > source.dot

perl ../../lib/prep.pl ../hw/ifx.dot > ifx.dot.pl
perl ifx.dot.pl > ifx.dot

REM perl ../../lib/prep.pl ../hw/ifu.vt > ifu.vt.pl
REM perl ifu.vt.pl sputnik.json > ifu.v

"c:/Program Files (x86)/Graphviz 2.28/bin/dot" -Tsvg stacks.dot >stacks.svg
"c:/Program Files (x86)/Graphviz 2.28/bin/dot" -Tsvg source.dot >source.svg
"c:/Program Files (x86)/Graphviz 2.28/bin/dot" -Tsvg ifx.dot    >ifx.svg

