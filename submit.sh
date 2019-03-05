cd ./verilog/ROB/
make nuke &> /dev/null
cd ./../../
make nuke &> /dev/null
/afs/umich.edu/user/j/i/jieltan/Public/470submit -p4 ./../$(basename "$PWD")
