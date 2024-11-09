V_FLAG = --cc --exe --build
INCDIR = -I./tb/ \
	-I./vsrc/
SIM_CPP = ./csrc/sim.cpp
CSRC = ./csrc/dpic.cpp
# REF = $(NOOP_HOME)/r2r/riscv64-nemu-interpreter-so
REF = $(NOOP_HOME)/r2r/tri-riscv64-nemu-interpreter-so

BIN = $(NOOP_HOME)/r2r/coremark-riscv64-nutshell.bin
WAVE_PATH = $(NOOP_HOME)/dump/sim.vcd
sim-verilog:
	echo NULL



test_sim:
	verilator $(V_FLAG) -j 32 -Wall $(SIM_CPP) $(CSRC) tb_top.v $(INCDIR) --trace

test_run: test_sim
	./obj_dir/Vtb_top

vcd:
	gtkwave ./dump/sim.vcd

diff: 
	cd difftest_trinity && make emu WITH_CHISELDB=0 WITH_CONSTANTIN=0 -j 32 EMU_TRACE=1 RELEASE=1

run_diff: diff
	./build/emu --diff=$(REF)  --dump-wave-full --wave-path=$(WAVE_PATH) -b 0 -e 1004001 --image=$(BIN)

strace:
	strace -e trace=open ./build/emu --diff=$(REF)  --dump-wave-full --wave-path=$(WAVE_PATH) -b 0 -e 5120 --image=$(BIN)

clean:
	rm -rf build/emu-compile build/emu time.log