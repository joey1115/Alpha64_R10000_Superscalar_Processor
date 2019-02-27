echo "Script Start"
if [ -d ./output/ ]; then
	echo "Removing old output"
	rm -rf ./output/
fi
echo "Creating output directory"
mkdir ./output/

if [ -d ./result/ ]; then
	echo "Removing old result"
	rm -rf ./result/
fi
echo "Creating result directory"
mkdir ./result/

echo "Entering provided code"
cd ./project4_provided

echo "Compiling provided code"
if [[ ! -f ./simv ]]
then
	echo "Running make nuke for provided code"
	make nuke &> /dev/null

	echo "Running make simv for provided code"
	make simv &> ./compiler.out
fi

if [ ! -d ./output/ ]; then
	echo "Creating output directory for provided code"
	mkdir ./output/
fi

for i in ./../test_progs/*.s
do
	filename=$(basename "$i")
	filename="${filename%.s}"
	if [[ ! -f ./output/$filename.writeback.sol.out ]]
	then
		echo "Start simulating $filename for provided code"
		echo "Running vs-asm $filename for provided code"
		./vs-asm < "$i" > program.mem
		echo "Running simv $filename for provided code"
		./simv > ./output/$filename.program.sol.out
		cat pipeline.out > "./output/$filename.pipeline.sol.out"
		cat writeback.out > "./output/$filename.writeback.sol.out"
		echo "Complete $filename for provided code"
	fi
done

if [[ -f ./*.out ]]
then
	echo "Removing out files for provided code"
	rm *.out
fi
if [[ -f ./*.mem ]]
then
	echo "Removing mem files for provided code"
	rm *.mem
fi

echo "Returning to main directory"
cd ..

echo "Running make nuke"
make nuke &> /dev/null

echo "Running make simv"
make simv &> ./compiler.out

error=$(grep -e 'Error' -e 'Warning' "./compiler.out")
if [[ -n "$error" ]]
then
	echo "Error: Copying files"
	cp -pf ./compiler.out ./result/
	echo "Could not make due to errors in ./result/"
	exit 1
fi

echo "Running vs-asm and simv"
for i in ./test_progs/*.s
do
	filename=$(basename "$i")
	filename="${filename%.s}"
	echo "Start simulating $filename"
	echo "Running vs-asm $filename"
	./vs-asm < "$i" > program.mem
	echo "Running simv $filename"
	./simv > ./output/$filename.program.test.out
	cat pipeline.out > "./output/$filename.pipeline.test.out"
	cat writeback.out > "./output/$filename.writeback.test.out"
	echo "Complete $filename"
done

echo "Checking simulation error"
for i in ./output/*.program.test.out
do
	filename=$(basename "$i")
	filename="${filename%.test.out}"
	echo "Checking $filename"
	error=$(grep -e '@@@ System halted on memory error' -e '@@@ System halted on illegal instruction' -e '@@@ System halted on unknown error code' $i)
	if [[ -n "$error" ]]
	then
		echo "Error: Copying files"
		cp -pf "$i" ./result/
		cp -pf "./project4_provided/output/$filename.sol.out" ./result/
	else
		echo "Passed $filename"
	fi
done

if [[ -f ./result/*.out ]]
then
	echo "Simulation errors in ./result/"
	exit 1
fi

echo "Start comparing"
# for i in ./P4_example/*.pipeline.out
# do
# 	filename=$(basename $i)
# 	filename="${filename%.out}"
# 	echo "Comparing $filename"
# 	if [[ -f ./output/$filename.test.out ]]
# 	then
# 		if [[ $(diff $i ./output/$filename.test.out) ]]
# 		then
# 			echo "Error: Copying files"
# 			cp -pf "./output/$filename.test.out" ./result/
# 			cp -pf "$i" ./result/
# 		else
# 			echo "Passed $filename"
# 		fi
# 	fi
# done

# for i in ./P4_example/*.writeback.out
# do
# 	filename=$(basename $i)
# 	filename="${filename%.out}"
# 	echo "Comparing $filename"
# 	if [[ -f ./output/$filename.test.out ]]
# 	then
# 		if [[ $(diff $i ./output/$filename.test.out) ]]
# 		then
# 			echo "Error: Copying files"
# 			cp -pf "./output/$filename.test.out" ./result/
# 			cp -pf "$i" ./result/
# 		else
# 			echo "Passed $filename"
# 		fi
# 	fi
# done

# for i in ./P4_example/*.program.out
# do
# 	filename=$(basename $i)
# 	filename="${filename%.out}"
# 	echo "Comparing $filename"
# 	if [[ -f ./output/$filename.test.out ]]
# 	then
# 		if [[ $(diff <(grep 'CPI' $i) <(grep 'CPI' ./output/$filename.test.out)) || $(diff <(grep '@@@' $i) <(grep '@@@' ./output/$filename.test.out)) ]]
# 		then
# 			echo "Error: Copying files"
# 			cp -pf "./output/$filename.test.out" ./result/
# 			cp -pf "$i" ./result/
# 		else
# 			echo "Passed $filename"
# 		fi
# 	fi
# done

for i in ./project4_provided/output/*.writeback.sol.out
do
	filename=$(basename $i)
	filename="${filename%.sol.out}"
	echo "Comparing $filename"
	if [[ -f ./output/$filename.test.out ]]
	then
		if [[ $(diff $i ./output/$filename.test.out) ]]
		then
			echo "Error: Copying files"
			cp -pf "./output/$filename.test.out" ./result/
			cp -pf "$i" ./result/
		else
			echo "Passed $filename"
		fi
	fi
done

echo "Finished comparing"

if [[ -f ./result/*.out ]]
then
	echo "Following test case failed:"
	ls -l ./result/
else
	echo "Passed all test cases"
fi

echo "Removing cache files"
for i in ./*.out
do
	rm "$i"
done
if [[ -f ./program.mem ]]
then
	rm ./program.mem
fi
rm -rf ./output/
