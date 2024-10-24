# Verilated -*- Makefile -*-
# DESCRIPTION: Verilator output: Make include file with class lists
#
# This file lists generated Verilated files, for including in higher level makefiles.
# See VSimTop.mk for the caller.

### Switches...
# C11 constructs required?  0/1 (always on now)
VM_C11 = 1
# Timing enabled?  0/1
VM_TIMING = 0
# Coverage output mode?  0/1 (from --coverage)
VM_COVERAGE = 0
# Parallel builds?  0/1 (from --output-split)
VM_PARALLEL_BUILDS = 0
# Tracing output mode?  0/1 (from --trace/--trace-fst)
VM_TRACE = 1
# Tracing output mode in VCD format?  0/1 (from --trace)
VM_TRACE_VCD = 1
# Tracing output mode in FST format?  0/1 (from --trace-fst)
VM_TRACE_FST = 0

### Object file lists...
# Generated module classes, fast-path, compile with highest optimization
VM_CLASSES_FAST += \
	VSimTop \
	VSimTop___024root__DepSet_h278d43d2__0 \
	VSimTop___024root__DepSet_hd5918264__0 \
	VSimTop_SimTop__DepSet_hf648961e__0 \
	VSimTop___024unit__DepSet_hd90c3539__0 \
	VSimTop_top__DepSet_h408aef70__0 \
	VSimTop_top__DepSet_h3292ddc2__0 \
	VSimTop_DifftestTrapEvent__DepSet_h5a4bab11__0 \
	VSimTop_DifftestTrapEvent__DepSet_h01878c60__0 \
	VSimTop_MemRWHelper__DepSet_h90153ece__0 \

# Generated module classes, non-fast-path, compile with low/medium optimization
VM_CLASSES_SLOW += \
	VSimTop___024root__Slow \
	VSimTop___024root__DepSet_h278d43d2__0__Slow \
	VSimTop___024root__DepSet_hd5918264__0__Slow \
	VSimTop_SimTop__Slow \
	VSimTop_SimTop__DepSet_h092b29f4__0__Slow \
	VSimTop_SimTop__DepSet_hf648961e__0__Slow \
	VSimTop___024unit__Slow \
	VSimTop___024unit__DepSet_hab1093f9__0__Slow \
	VSimTop_top__Slow \
	VSimTop_top__DepSet_h408aef70__0__Slow \
	VSimTop_top__DepSet_h3292ddc2__0__Slow \
	VSimTop_DifftestTrapEvent__Slow \
	VSimTop_DifftestTrapEvent__DepSet_h5a4bab11__0__Slow \
	VSimTop_MemRWHelper__Slow \
	VSimTop_MemRWHelper__DepSet_h173c2e34__0__Slow \

# Generated support classes, fast-path, compile with highest optimization
VM_SUPPORT_FAST += \
	VSimTop__Dpi \
	VSimTop__Trace__0 \

# Generated support classes, non-fast-path, compile with low/medium optimization
VM_SUPPORT_SLOW += \
	VSimTop__Syms \
	VSimTop__Trace__0__Slow \
	VSimTop__TraceDecls__0__Slow \

# Global classes, need linked once per executable, fast-path, compile with highest optimization
VM_GLOBAL_FAST += \
	verilated \
	verilated_dpi \
	verilated_vcd_c \
	verilated_threads \

# Global classes, need linked once per executable, non-fast-path, compile with low/medium optimization
VM_GLOBAL_SLOW += \


# Verilated -*- Makefile -*-
