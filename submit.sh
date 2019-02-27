cd ./verilog/ROB/
make nuke &> /dev/null
cd ./../../
make nuke &> /dev/null
if [[ -d ./.git ]]
then
  rm -rf ./.git/
fi
/afs/umich.edu/user/j/i/jieltan/Public/470submit -p4 ./../$(basename "$PWD")
