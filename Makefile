V_FLAG = --cc --exe --build
INCDIR = -I./tb/ \
	-I./vsrc/
SIM_CPP = ./csrc/sim.cpp
CSRC = ./csrc/dpic.cpp
sim-verilog:
	echo NULL

emu: sim-verilog
	@$(MAKE) -C difftest emu WITH_CHISELDB=0 WITH_CONSTANTIN=0 

test_sim:
	verilator $(V_FLAG) -j 32 -Wall $(SIM_CPP) $(CSRC) tb_top.v $(INCDIR) --trace

test_run: test_sim
	./obj_dir/Vtb_top

vcd:
	gtkwave ./dump/sim.vcd

diff:
	cd difftest & make emu WITH_CHISELDB=0 WITH_CONSTANTIN=0 -j 16 EMU_TRACE=1

run_diff: diff
	./build/emu --diff=./r2r/riscv64-nemu-interpreter-so  --dump-wave --wave-path=./dump/sim.vcd -b 0 -e 5000 --image=/nfs/home/jinpeize/trinity/r2r/coremark-riscv64-xs-flash.bin