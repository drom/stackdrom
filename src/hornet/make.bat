%0\
cd %0\..
cd /d %0\..

perl -I "lib" ../../lib/prep.pl src/hornet_core.v > hornet_core.pl
perl -I "lib"                                       hornet_core.pl > rtl/hornet_core.v

perl -I "lib" ../../lib/prep.pl src/hornet_memo.v > hornet_memo.pl
perl -I "lib"                                       hornet_memo.pl > rtl/hornet_memo.v

perl -I "lib" ../../lib/prep.pl src/hornet_topo.v > hornet_topo.pl
perl -I "lib"                                       hornet_topo.pl > rtl/hornet_topo.v
