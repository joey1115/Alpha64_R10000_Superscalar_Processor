echo
ls -A ./test_progs | sed -e 's/\.s$//'
echo -e "\nEnter filename to generate program.mem file: "
read filename

while true
do
	if [[ ! -e ./test_progs/"$filename".s ]]
	then
		echo -e "File cannot found. Please enter again: "
		read filename
	else
		break
	fi
done

echo "Generating program.mem file from $filename"
./vs-asm < test_progs/"$filename".s > program.mem
echo "File ready. Good luck testing!"


