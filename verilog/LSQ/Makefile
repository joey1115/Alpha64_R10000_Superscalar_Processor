# Given no targets, 'make' will default to building 'simv', the simulated version
# of the pipeline

# make          <- compile simv if needed

# As shortcuts, any of the following will build if necessary and then run the
# specified target

# make sim      <- runs simv (after compiling simv if needed)
# make vis      <- runs the "visual" debugger (visual/)
# make dve      <- runs int_simv interactively (after compiling it if needed)
# make syn      <- runs syn_simv (after synthesizing if needed then 
#                                 compiling synsimv if needed)
# make syn_dve  <- runs DVE on synthesized code


# make clean    <- remove files created during compilations (but not synthesis)
# make nuke     <- remove all files created during compilation and synthesis
#
# To compile additional files, add them to the TESTBENCH or SIMFILES as needed
# Every .vg file will need its own rule and one or more synthesis scripts
# The information contained here (in the rules for those vg files) will be 
# similar to the information in those scripts but that seems hard to avoid.
# 

################################################################################
## CONFIGURATION
################################################################################

VCS = SW_VCS=2017.12-SP2-1 vcs -sverilog +vc -Mupdate -line -full64 +define+CLOCK_PERIOD=$(CLOCK_PERIOD) +lint=PCWM
LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v

# SIMULATION CONFIG
MOD_NAME     = LSQ
HEADERS      = $(wildcard ../../*.vh)
HEADERS     += $(wildcard $(MOD_NAME).vh)
TESTBENCH    = $(wildcard test_$(MOD_NAME).v)
MODFILE      = $(wildcard $(MOD_NAME).v)

SIMFILES     = $(MODFILE)

# SYNTHESIS CONFIG

export HEADERS
export MODFILE

SYNFILES  = $(MOD_NAME).vg $(MOD_NAME)_svsim.sv

# Passed through to .tcl scripts:
export MOD_NAME
export CLOCK_NET_NAME = clock
export RESET_NET_NAME = reset
export CLOCK_PERIOD = 2.75
# TODO: You will want to make this more aggresive

################################################################################
## RULES
################################################################################

$(MOD_NAME).vg:	$(MOD_NAME).v $(MOD_NAME).tcl 
	dc_shell-t -f $(MOD_NAME).tcl | tee synth.out

# Default target:
all:    simv
	./simv | tee program.out

.PHONY: all

# Simulation:
dve:	$(SIMFILES) $(TESTBENCH) 
	$(VCS) +memcbk $(TESTBENCH) $(SIMFILES) -o dve -R -gui
	
dve_syn:	$(SYNFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SYNFILES) $(LIB) +define+SYNTH_TEST -o syn_simv -R -gui

simv:	$(SIMFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SIMFILES) -o simv

syn_simv:	$(SYNFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SYNFILES) $(LIB) +define+SYNTH_TEST -o syn_simv

syn:	syn_simv
	./syn_simv | tee syn_program.out

clean:
	rm -rvf simv *.daidir csrc vcs.key program.out \
	  syn_simv syn_simv.daidir syn_program.out \
          dve *.vpd *.vcd *.dump ucli.key 

nuke:	clean
	rm -rvf *.vg *.rep *.db *.chk *.log *.out DVEfiles/ *.ddc *.res *_svsim.sv default.svf *.vdb
