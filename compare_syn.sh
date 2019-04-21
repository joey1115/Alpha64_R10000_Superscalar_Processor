#!/usr/bin/env bash
echo "Removing old files"
if [[ -d ./output_syn/ ]]
then
  rm -rf ./output_syn/
fi
if [[ -d ./result_syn/ ]]
then
  rm -rf ./result_syn/
fi
if [[ -d ./project4_provided/output_syn/ ]]
then
  rm -rf ./project4_provided/output_syn/
fi
echo "Creating output directory"
mkdir ./output_syn/
mkdir ./result_syn/

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
  if [[ ! -f ./../output_syn/"$filename".program.sol.out ]]
  then
    ./simv &> ./../output_syn/"$filename".program.sol.out
    cat writeback.out &> ./../output_syn/"$filename".writeback.sol.out
    cat pipeline.out &> ./../output_syn/"$filename".pipeline.sol.out
  fi
done
cd ..

echo "Running test programs"
echo "Running make"
for i in ./test_progs/*.s
do
  echo "Running $i"
  ./vs-asm < "$i" > program.mem
  filename=$(basename -- "$i")
  filename="${filename%.*}"
  ./syn_simv &> ./output_syn/"$filename".program.test.out
  cat writeback.out &> ./output_syn/"$filename".writeback.test.out
  cat pipeline.out &> ./output_syn/"$filename".pipeline.test.out
done

for i in ./test_progs/*.s
do
  echo "Comparing $i"
  filename=$(basename -- "$i")
  filename="${filename%.*}"
  result_mem=$(diff <(grep '@@@ mem' ./output_syn/"$filename".program.sol.out) <(grep '@@@ mem' ./output_syn/"$filename".program.test.out))
  result_wb=$(diff ./output_syn/"$filename".writeback.sol.out ./output_syn/"$filename".writeback.test.out)
  # diff ./output/"$filename".program.sol.out ./output/"$filename".program.test.out
  # diff ./output/"$filename".writeback.sol.out ./output/"$filename".writeback.test.out
  if [[ -n $result_mem ]]
  then
    echo "Error $filename mem"
    cp -pf "./output_syn/"$filename".program.sol.out" ./result_syn/
    cp -pf "./output_syn/"$filename".program.test.out" ./result_syn/
  fi
  if [[ -n $result_wb ]]
  then
    echo "Error $filename wb"
    cp -pf "./output_syn/"$filename".writeback.sol.out" ./result_syn/
    cp -pf "./output_syn/"$filename".writeback.test.out" ./result_syn/
  fi
  if [[ -n $result_mem || -n $result_wb ]]
  then
    cp -pf "./output_syn/"$filename".pipeline.sol.out" ./result_syn/
    cp -pf "./output_syn/"$filename".pipeline.test.out" ./result_syn/
  fi
done
