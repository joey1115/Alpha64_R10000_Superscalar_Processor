# To compile additional files, add them to the TESTBENCH or SIMFILES as needed
# Every .vg file will need its own rule and one or more synthesis scripts
# The information contained here (in the rules for those vg files) will be
# similar to the information in those scripts but that seems hard to avoid.
#

# added "SW_VCS=2011.03 and "-full64" option -- awdeorio fall 2011
# added "-sverilog" and "SW_VCS=2012.09" option,
#	and removed deprecated Virsim references -- jbbeau fall 2013
# updated library path name -- jbbeau fall 2013

VCS = SW_VCS=2017.12-SP2-1 vcs +v2k -sverilog +vc -Mupdate -line -full64
LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v

all:    simv
	./simv | tee program.out
##### 
# Modify starting here
#####

HEADERS      = $(wildcard *.vh)
SIMFILES     = ./verilog/ROB/ROB.v
TESTBENCH    = ./testbench/testbench_ROB.v
SYNFILES     = ./synth/ROB.vg 

ROB.vg:	ROB.v ROB.vg ROB.tcl
	dc_shell-t -f ./synth/ROB.tcl | tee ROB_synth.out

#####
# Should be no need to modify after here
#####
sim:	simv $(ASSEMBLED)
	./simv | tee sim_program.out

simv:	$(HEADERS) $(SIMFILES) $(TESTBENCH)
	$(VCS) $^ -o simv

.PHONY: sim


# updated interactive debugger "DVE", using the latest version of VCS
# awdeorio fall 2011
dve:	$(SIMFILES) $(TESTBENCH)
	$(VCS) +memcbk $(TESTBENCH) $(SIMFILES) -o dve -R -gui

syn_simv:	$(HEADERS) $(SYNFILES) $(TESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST -o syn_simv 

syn:	syn_simv
	./syn_simv | tee syn_program.out

clean:
	rm -rvf simv *.daidir csrc vcs.key program.out \
	  syn_simv syn_simv.daidir syn_program.out \
          dve *.vpd *.vcd *.dump ucli.key

nuke:	clean
	rm -rvf *.vg *.rep *.db *.chk *.log *.out *.ddc *.svf DVEfiles/
	
.PHONY: dve clean nuke	
