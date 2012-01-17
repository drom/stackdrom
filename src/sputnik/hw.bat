%0\
cd %0\..
cd /d %0\..
perl ../../lib/prep.pl ../hw/ifu.vt > ifu.vt.pl
perl ifu.vt.pl sputnik.json > ifu.v

pause
