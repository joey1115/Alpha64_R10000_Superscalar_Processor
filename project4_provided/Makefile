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

VCS = SW_VCS=2017.12-SP2-1 vcs -sverilog +vc -Mupdate -line -full64 +define+CLOCK_PERIOD=$(CLOCK_PERIOD)
LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v

SYNTH_DIR = ./synth

PROGRAM = test_progs/evens.s
ASSEMBLED = program.mem
ASSEMBLER = vs-asm

# SIMULATION CONFIG

HEADERS     = $(wildcard *.vh)
TESTBENCH   = $(wildcard testbench/*.v)
TESTBENCH  += $(wildcard testbench/*.c)
PIPEFILES   = $(wildcard verilog/*.v)
CACHEFILES  = $(wildcard verilog/cache/*.v)

SIMFILES    = $(PIPEFILES) $(CACHEFILES)

# SYNTHESIS CONFIG

export HEADERS
export PIPEFILES
export CACHEFILES

export CACHE_NAME = cache
export PIPELINE_NAME = pipeline

PIPELINE  = $(SYNTH_DIR)/$(PIPELINE_NAME).vg 
SYNFILES  = $(PIPELINE) $(SYNTH_DIR)/$(PIPELINE_NAME)_svsim.sv
CACHE     = $(SYNTH_DIR)/$(CACHE_NAME).vg

# Passed through to .tcl scripts:
export CLOCK_NET_NAME = clock
export RESET_NET_NAME = reset
export CLOCK_PERIOD = 30	# TODO: You will want to make this more aggresive

################################################################################
## RULES
################################################################################

# Default target:
all:    simv
	./simv | tee program.out

.PHONY: all

# Simulation:

sim:	simv $(ASSEMBLED)
	./simv | tee sim_program.out

simv:	$(HEADERS) $(SIMFILES) $(TESTBENCH)
	$(VCS) $^ -o simv

.PHONY: sim

# Programs

$(ASSEMBLED):	$(PROGRAM)
	./$(ASSEMBLER) < $< > $@

# Synthesis

$(CACHE): $(CACHEFILES) $(SYNTH_DIR)/$(CACHE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(CACHE_NAME).tcl | tee $(CACHE_NAME)_synth.out

$(PIPELINE): $(SIMFILES) $(CACHE) $(SYNTH_DIR)/$(PIPELINE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(PIPELINE_NAME).tcl | tee $(PIPELINE_NAME)_synth.out
	echo -e -n 'H\n1\ni\n`timescale 1ns/100ps\n.\nw\nq\n' | ed $(PIPELINE)

syn:	syn_simv $(ASSEMBLED)
	./syn_simv | tee syn_program.out

syn_simv:	$(HEADERS) $(SYNFILES) $(TESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST -o syn_simv 

.PHONY: syn

# Debugging

dve_simv:	$(HEADERS) $(SIMFILES) $(TESTBENCH)
	$(VCS) +memcbk $^ -o $@ -gui

dve:	dve_simv $(ASSEMBLED)
	./$<

dve_syn_simv:	$(HEADERS) $(PIPELINE) $(TESTBENCH)
	$(VCS) +memcbk $^ $(LIB) -o $@ -gui

dve_syn:	dve_syn_simv $(ASSEMBLED)
	./$<

# For visual debugger
VISFLAGS = -lncurses
VISTESTBENCH = $(TESTBENCH:testbench.v=visual/visual_testbench.v) \
		testbench/visual/visual_c_hooks.c
vis_simv:	$(HEADERS) $(SIMFILES) $(VISTESTBENCH)
	$(VCS) $(VISFLAGS) $^ -o vis_simv
vis:	vis_simv $(ASSEMBLED)
	./vis_simv

.PHONY: dve syn_dve vis

clean:
	rm -rf simv simv.daidir csrc vcs.key ucli.key
	rm -rf vis_simv vis_simv.daidir
	rm -rf syn_simv syn_simv.daidir
	rm -f *.out
	rm -rf synsimv synsimv.daidir csrc vcdplus.vpd vcs.key synprog.out pipeline.out writeback.out vc_hdrs.h
	rm -rf dve_simv dve_syn_simv dve_simv.daidir DVEfiles dve_syn_simv.daidir

nuke:	clean
	rm -f $(SYNTH_DIR)/*.vg $(SYNTH_DIR)/*.rep $(SYNTH_DIR)/*.db $(SYNTH_DIR)/*.chk $(SYNTH_DIR)/command.log
	rm -f $(SYNTH_DIR)/*.out $(SYNTH_DIR)/*.ddc $(SYNTH_DIR)/*.log
	rm -f $(ASSEMBLED)

.PHONY: clean nuke dve
