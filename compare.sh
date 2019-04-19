#!/usr/bin/env bash
echo "Removing old files"
if [[ -d ./output/ ]]
then
  rm -rf ./output/
fi
if [[ -d ./result/ ]]
then
  rm -rf ./result/
fi
if [[ -d ./project4_provided/output/ ]]
then
  rm -rf ./project4_provided/output/
fi
echo "Creating output directory"
mkdir ./output/
mkdir ./result/

echo "Running test programs with solution"
cd project4_provided
echo "Running make"
make nuke &> /dev/null
make simv &> compile.out
for i in ./../test_progs/*.s
do
  echo "Running $i"
  ./vs-asm < "$i" > program.mem
  filename=$(basename -- "$i")
  filename="${filename%.*}"
  if [[ ! -f ./../output/"$filename".program.sol.out ]]
  then
    ./simv &> ./../output/"$filename".program.sol.out
    cat writeback.out &> ./../output/"$filename".writeback.sol.out
    cat pipeline.out &> ./../output/"$filename".pipeline.sol.out
  fi
done
cd ..

echo "Running test programs"
echo "Running make"
make nuke &> /dev/null
make simv &> compile.out
for i in ./test_progs/*.s
do
  echo "Running $i"
  ./vs-asm < "$i" > program.mem
  filename=$(basename -- "$i")
  filename="${filename%.*}"
  ./simv &> ./output/"$filename".program.test.out
  cat writeback.out &> ./output/"$filename".writeback.test.out
  cat pipeline.out &> ./output/"$filename".pipeline.test.out
done

for i in ./test_progs/*.s
do
  echo "Comparing $i"
  filename=$(basename -- "$i")
  filename="${filename%.*}"
  result_mem=$(diff <(grep '@@@ mem' ./output/"$filename".program.sol.out) <(grep '@@@ mem' ./output/"$filename".program.test.out))
  result_wb=$(diff ./output/"$filename".writeback.sol.out ./output/"$filename".writeback.test.out)
  # diff ./output/"$filename".program.sol.out ./output/"$filename".program.test.out
  # diff ./output/"$filename".writeback.sol.out ./output/"$filename".writeback.test.out
  if [[ -n $result_mem ]]
  then
    echo "Error $filename mem"
    cp -pf "./output/"$filename".program.sol.out" ./result/
    cp -pf "./output/"$filename".program.test.out" ./result/
  fi
  if [[ -n $result_wb ]]
  then
    echo "Error $filename wb"
    cp -pf "./output/"$filename".writeback.sol.out" ./result/
    cp -pf "./output/"$filename".writeback.test.out" ./result/
  fi
  if [[ -n $result_mem || -n $result_wb ]]
  then
    echo "Error $filename wb"
    cp -pf "./output/"$filename".pipeline.sol.out" ./result/
    cp -pf "./output/"$filename".pipeline.test.out" ./result/
  fi
done