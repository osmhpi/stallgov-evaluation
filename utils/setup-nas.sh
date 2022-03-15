#!/bin/bash

git clone https://github.com/GMAP/NPB-CPP.git
cd NPB-CPP/NPB-OMP
make EP CLASS=B
make EP CLASS=C
make EP CLASS=D
make MG CLASS=B
make MG CLASS=C
make MG CLASS=D
make CG CLASS=B
make CG CLASS=C
make CG CLASS=D
make FT CLASS=B
make FT CLASS=C
make FT CLASS=D
make IS CLASS=B
make IS CLASS=C
make IS CLASS=D
make IS CLASS=E
