#!/bin/bash
echo "making project4_provided"
cd project4_provided
make simv &>/dev/null

echo "generating_solution from project4_provided..."
for file in ../test_progs/*.s; do
    basefile=$( echo "$(basename "$file")")
    file=$( echo $basefile | cut -d'.' -f1)
    echo "Assembling $file"
    ./vs-asm < ../test_progs/$file.s > program.mem
    echo "Running $file"
    ./simv > program.out
    echo "Saving $file ouputs"
    progOut="${file}_program_sol"
    writeOut="${file}_writeback_sol"
    cp program.out ../test_progs_solution/$progOut.out
    cp writeback.out ../test_progs_solution/$writeOut.out
done

