%0\
cd %0\..
cd /d %0\..
perl prep.pl ifu.vt > ifu.vt.pl
perl ifu.vt.pl j1.json > ifu.v

pause
