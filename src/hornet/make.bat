%0\
cd %0\..
cd /d %0\..
perl -I "lib" ../../lib/prep.pl src/hornet.src.v > hornet.tmp.pl
perl -I "lib"                                      hornet.tmp.pl > rtl/hornet.v
