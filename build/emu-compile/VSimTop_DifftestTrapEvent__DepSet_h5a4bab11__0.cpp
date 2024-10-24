// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop_DifftestTrapEvent.h"

void VSimTop_DifftestTrapEvent____Vdpiimwrap_v_difftest_TrapEvent_TOP__SimTop__u_DifftestTrapEvent(CData/*0:0*/ io_hasTrap, QData/*63:0*/ io_cycleCnt, QData/*63:0*/ io_instrCnt, CData/*0:0*/ io_hasWFI, IData/*31:0*/ io_code, QData/*63:0*/ io_pc, CData/*7:0*/ io_coreid);

VL_INLINE_OPT void VSimTop_DifftestTrapEvent___nba_sequent__TOP__SimTop__u_DifftestTrapEvent__0(VSimTop_DifftestTrapEvent* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop_DifftestTrapEvent___nba_sequent__TOP__SimTop__u_DifftestTrapEvent__0\n"); );
    // Body
    if (vlSelf->__PVT__enable) {
        VSimTop_DifftestTrapEvent____Vdpiimwrap_v_difftest_TrapEvent_TOP__SimTop__u_DifftestTrapEvent(vlSelf->__PVT__io_hasTrap, vlSelf->__PVT__io_cycleCnt, vlSelf->__PVT__io_instrCnt, (IData)(vlSelf->__PVT__io_hasWFI), vlSelf->__PVT__io_code, vlSelf->__PVT__io_pc, (IData)(vlSelf->__PVT__io_coreid));
    }
}
