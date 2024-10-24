V_FLAG = --cc --exe --build
INCDIR = -I./tb/ \
	-I./vsrc/
SIM_CPP = ./csrc/sim.cpp
CSRC = ./csrc/dpic.cpp
REF = /nfs/home/jinpeize/trinity/r2r/riscv64-nemu-interpreter-so
BIN = /nfs/home/jinpeize/trinity/r2r/coremark-riscv64-xs-flash.bin
WAVE_PATH = /nfs/home/jinpeize/trinity/dump/test.vcd
sim-verilog:
	echo NULL



test_sim:
	verilator $(V_FLAG) -j 32 -Wall $(SIM_CPP) $(CSRC) tb_top.v $(INCDIR) --trace

test_run: test_sim
	./obj_dir/Vtb_top

vcd:
	gtkwave ./dump/sim.vcd

diff:
	cd difftest && make emu WITH_CHISELDB=0 WITH_CONSTANTIN=0 -j 16 EMU_TRACE=1

run_diff: diff
	./build/emu --diff=$(REF)  --dump-wave-full --wave-path=$(WAVE_PATH) -b 0 -e 5119 --image=/nfs/home/jinpeize/trinity/r2r/coremark-riscv64-xs-flash.bin

strace:
	strace -e trace=open ./build/emu --diff=$(REF)  --dump-wave-full --wave-path=$(WAVE_PATH) -b 0 -e 5120 --image=/nfs/home/jinpeize/trinity/r2r/coremark-riscv64-xs-flash.bin