// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Prototypes for DPI import and export functions.
//
// Verilator includes this file in all generated .cpp files that use DPI functions.
// Manually include this file where DPI .c import functions are declared to ensure
// the C functions match the expectations of the DPI imports.

#ifndef VERILATED_VSIMTOP__DPI_H_
#define VERILATED_VSIMTOP__DPI_H_  // guard

#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif


    // DPI IMPORTS
    // DPI import at /nfs/home/jinpeize/trinity/difftest/src/test/vsrc/common/ref.v:45:33
    extern long long amo_helper(char cmd, long long addr, long long wdata, char mask);
    // DPI import at ../vsrc/sim_ram/MemRWHelper.v:2:33
    extern long long difftest_ram_read(long long rIdx);
    // DPI import at ../vsrc/sim_ram/MemRWHelper.v:7:30
    extern void difftest_ram_write(long long index, long long data, long long mask);
    // DPI import at /nfs/home/jinpeize/trinity/difftest/src/test/vsrc/common/SimJTAG.v:7:29
    extern int jtag_tick(svBit* jtag_TCK, svBit* jtag_TMS, svBit* jtag_TDI, svBit* jtag_TRSTn, svBit jtag_TDO);
    // DPI import at /nfs/home/jinpeize/trinity/difftest/src/test/vsrc/common/ref.v:18:30
    extern char pte_helper(long long satp, long long vpn, long long* pte, char* level);
    // DPI import at /nfs/home/jinpeize/trinity/build/rtl/DifftestTrapEvent.v:16:30
    extern void v_difftest_TrapEvent(svBit io_hasTrap, long long io_cycleCnt, long long io_instrCnt, svBit io_hasWFI, int io_code, long long io_pc, char io_coreid);
    // DPI import at /nfs/home/jinpeize/trinity/difftest/src/test/vsrc/common/assert.v:18:30
    extern void xs_assert(long long line);
    // DPI import at /nfs/home/jinpeize/trinity/difftest/src/test/vsrc/common/assert.v:23:30
    extern void xs_assert_v2(const char* filename, long long line);

#ifdef __cplusplus
}
#endif

#endif  // guard
