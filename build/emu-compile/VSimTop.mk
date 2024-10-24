# Verilated -*- Makefile -*-
# DESCRIPTION: Verilator output: Makefile for building Verilated archive or executable
#
# Execute this makefile from the object directory:
#    make -f VSimTop.mk

default: /nfs/home/jinpeize/trinity/build/emu

### Constants...
# Perl executable (from $PERL)
PERL = perl
# Path to Verilator kit (from $VERILATOR_ROOT)
VERILATOR_ROOT = /usr/local/share/verilator
# SystemC include directory with systemc.h (from $SYSTEMC_INCLUDE)
SYSTEMC_INCLUDE ?= 
# SystemC library directory with libsystemc.a (from $SYSTEMC_LIBDIR)
SYSTEMC_LIBDIR ?= 

### Switches...
# C++ code coverage  0/1 (from --prof-c)
VM_PROFC = 0
# SystemC output mode?  0/1 (from --sc)
VM_SC = 0
# Legacy or SystemC output mode?  0/1 (from --sc)
VM_SP_OR_SC = $(VM_SC)
# Deprecated
VM_PCLI = 1
# Deprecated: SystemC architecture to find link library path (from $SYSTEMC_ARCH)
VM_SC_TARGET_ARCH = linux

### Vars...
# Design prefix (from --prefix)
VM_PREFIX = VSimTop
# Module prefix (from --prefix)
VM_MODPREFIX = VSimTop
# User CFLAGS (from -CFLAGS on Verilator command line)
VM_USER_CFLAGS = \
	-I/nfs/home/jinpeize/trinity/difftest/src/test/csrc/common -I/nfs/home/jinpeize/trinity/difftest/config -DNOOP_HOME=\"/nfs/home/jinpeize/trinity\" -I/nfs/home/jinpeize/trinity/build/generated-src -I/nfs/home/jinpeize/trinity/difftest/src/test/csrc/plugin/include -I/nfs/home/jinpeize/trinity/difftest/src/test/csrc/difftest -I/nfs/home/jinpeize/trinity/difftest/src/test/csrc/plugin/spikedasm -I/nfs/home/jinpeize/trinity/difftest/src/test/csrc/verilator -DVERILATOR -DNUM_CORES=1 --std=c++17 -DVERILATOR_4_210 \
	$(PGO_CFLAGS) \
	-ggdb \

# User LDLIBS (from -LDFLAGS on Verilator command line)
VM_USER_LDLIBS = \
	-lz -lzstd -ldl \
	$(PGO_LDFLAGS) \
	-ggdb \

# User .cpp files (from .cpp's on Verilator command line)
VM_USER_CLASSES = \
	difftest-dpic \
	SimJTAG \
	common \
	compress \
	coverage \
	device \
	dut \
	flash \
	golden \
	keyboard \
	lightsss \
	main \
	perf \
	ram \
	remote_bitbang \
	sdcard \
	uart \
	vga \
	difftest \
	difftrace \
	goldenmem \
	refproxy \
	spikedasm \
	emu \
	snapshot \

# User .cpp directories (from .cpp's on Verilator command line)
VM_USER_DIR = \
	/nfs/home/jinpeize/trinity/build/generated-src \
	/nfs/home/jinpeize/trinity/difftest/src/test/csrc/common \
	/nfs/home/jinpeize/trinity/difftest/src/test/csrc/difftest \
	/nfs/home/jinpeize/trinity/difftest/src/test/csrc/plugin/spikedasm \
	/nfs/home/jinpeize/trinity/difftest/src/test/csrc/verilator \


### Default rules...
# Include list of all generated classes
include VSimTop_classes.mk
# Include global rules
include $(VERILATOR_ROOT)/include/verilated.mk

### Executable rules... (from --exe)
VPATH += $(VM_USER_DIR)

difftest-dpic.o: /nfs/home/jinpeize/trinity/build/generated-src/difftest-dpic.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
SimJTAG.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/SimJTAG.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
common.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/common.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
compress.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/compress.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
coverage.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/coverage.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
device.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/device.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
dut.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/dut.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
flash.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/flash.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
golden.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/golden.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
keyboard.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/keyboard.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
lightsss.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/lightsss.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
main.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/main.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
perf.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/perf.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
ram.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/ram.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
remote_bitbang.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/remote_bitbang.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
sdcard.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/sdcard.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
uart.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/uart.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
vga.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/common/vga.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
difftest.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/difftest/difftest.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
difftrace.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/difftest/difftrace.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
goldenmem.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/difftest/goldenmem.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
refproxy.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/difftest/refproxy.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
spikedasm.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/plugin/spikedasm/spikedasm.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
emu.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/verilator/emu.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
snapshot.o: /nfs/home/jinpeize/trinity/difftest/src/test/csrc/verilator/snapshot.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<

### Link rules... (from --exe)
/nfs/home/jinpeize/trinity/build/emu: $(VK_USER_OBJS) $(VK_GLOBAL_OBJS) $(VM_PREFIX)__ALL.a $(VM_HIER_LIBS)
	$(LINK) $(LDFLAGS) $^ $(LOADLIBES) $(LDLIBS) $(LIBS) $(SC_LIBS) -o $@


# Verilated -*- Makefile -*-
