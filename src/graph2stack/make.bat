%0\
cd %0\..
cd /d %0\..

perl radix8.pl
dot -Tsvg -Nfontname=Helvetica -Efontname=Helvetica -odoc\00.svg dot\00.dot
dot -Tsvg -Nfontname=Helvetica -Efontname=Helvetica -odoc\01.svg dot\01.dot
dot -Tsvg -Nfontname=Helvetica -Efontname=Helvetica -odoc\02.svg dot\02.dot
dot -Tsvg -Nfontname=Helvetica -Efontname=Helvetica -odoc\03.svg dot\03.dot
dot -Tsvg -Nfontname=Helvetica -Efontname=Helvetica -odoc\04.svg dot\04.dot
dot -Tsvg -Nfontname=Helvetica -Efontname=Helvetica -odoc\05.svg dot\05.dot
dot -Tsvg -Nfontname=Helvetica -Efontname=Helvetica -odoc\06.svg dot\06.dot

dot -Tpng -Nfontname=Helvetica -Efontname=Helvetica -odoc\00.png dot\00.dot
dot -Tpng -Nfontname=Helvetica -Efontname=Helvetica -odoc\01.png dot\01.dot
dot -Tpng -Nfontname=Helvetica -Efontname=Helvetica -odoc\02.png dot\02.dot
dot -Tpng -Nfontname=Helvetica -Efontname=Helvetica -odoc\03.png dot\03.dot
dot -Tpng -Nfontname=Helvetica -Efontname=Helvetica -odoc\04.png dot\04.dot
dot -Tpng -Nfontname=Helvetica -Efontname=Helvetica -odoc\05.png dot\05.dot
dot -Tpng -Nfontname=Helvetica -Efontname=Helvetica -odoc\06.png dot\06.dot

neato -Tsvg -Nfontname=Helvetica -Efontname=Helvetica -odoc\map.svg dot\map.dot
