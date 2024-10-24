// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop_DifftestTrapEvent.h"
#include "VSimTop__Syms.h"

extern "C" void v_difftest_TrapEvent(svBit io_hasTrap, long long io_cycleCnt, long long io_instrCnt, svBit io_hasWFI, int io_code, long long io_pc, char io_coreid);

VL_INLINE_OPT void VSimTop_DifftestTrapEvent____Vdpiimwrap_v_difftest_TrapEvent_TOP__SimTop__u_DifftestTrapEvent(CData/*0:0*/ io_hasTrap, QData/*63:0*/ io_cycleCnt, QData/*63:0*/ io_instrCnt, CData/*0:0*/ io_hasWFI, IData/*31:0*/ io_code, QData/*63:0*/ io_pc, CData/*7:0*/ io_coreid) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop_DifftestTrapEvent____Vdpiimwrap_v_difftest_TrapEvent_TOP__SimTop__u_DifftestTrapEvent\n"); );
    // Body
    svBit io_hasTrap__Vcvt;
    for (size_t io_hasTrap__Vidx = 0; io_hasTrap__Vidx < 1; ++io_hasTrap__Vidx) io_hasTrap__Vcvt = io_hasTrap;
    long long io_cycleCnt__Vcvt;
    for (size_t io_cycleCnt__Vidx = 0; io_cycleCnt__Vidx < 1; ++io_cycleCnt__Vidx) io_cycleCnt__Vcvt = io_cycleCnt;
    long long io_instrCnt__Vcvt;
    for (size_t io_instrCnt__Vidx = 0; io_instrCnt__Vidx < 1; ++io_instrCnt__Vidx) io_instrCnt__Vcvt = io_instrCnt;
    svBit io_hasWFI__Vcvt;
    for (size_t io_hasWFI__Vidx = 0; io_hasWFI__Vidx < 1; ++io_hasWFI__Vidx) io_hasWFI__Vcvt = io_hasWFI;
    int io_code__Vcvt;
    for (size_t io_code__Vidx = 0; io_code__Vidx < 1; ++io_code__Vidx) io_code__Vcvt = io_code;
    long long io_pc__Vcvt;
    for (size_t io_pc__Vidx = 0; io_pc__Vidx < 1; ++io_pc__Vidx) io_pc__Vcvt = io_pc;
    char io_coreid__Vcvt;
    for (size_t io_coreid__Vidx = 0; io_coreid__Vidx < 1; ++io_coreid__Vidx) io_coreid__Vcvt = io_coreid;
    v_difftest_TrapEvent(io_hasTrap__Vcvt, io_cycleCnt__Vcvt, io_instrCnt__Vcvt, io_hasWFI__Vcvt, io_code__Vcvt, io_pc__Vcvt, io_coreid__Vcvt);
}
