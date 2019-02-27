cd ./verilog/ROB/
make nuke &> /dev/null
cd ./../../
make nuke &> /dev/null
# if [[ -d ./.git/ ]]
# then
#   mkdir ./../temp/
#   cp ./.git/ ./../temp/
#   rm -rf ./.git/
# fi
/afs/umich.edu/user/j/i/jieltan/Public/470submit -p4 ./../$(basename "$PWD")
# if [[ -d ./../temp/ ]]
# then
#   mkdir ./.git/
#   cp ./../temp/ ./.git/
#   rm -rf ./../temp/
# fi
