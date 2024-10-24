// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop_DifftestTrapEvent.h"

VL_ATTR_COLD void VSimTop_DifftestTrapEvent___ctor_var_reset(VSimTop_DifftestTrapEvent* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop_DifftestTrapEvent___ctor_var_reset\n"); );
    // Body
    vlSelf->__PVT__clock = VL_RAND_RESET_I(1);
    vlSelf->__PVT__enable = VL_RAND_RESET_I(1);
    vlSelf->__PVT__io_hasTrap = VL_RAND_RESET_I(1);
    vlSelf->__PVT__io_cycleCnt = VL_RAND_RESET_Q(64);
    vlSelf->__PVT__io_instrCnt = VL_RAND_RESET_Q(64);
    vlSelf->__PVT__io_hasWFI = VL_RAND_RESET_I(1);
    vlSelf->__PVT__io_code = VL_RAND_RESET_I(32);
    vlSelf->__PVT__io_pc = VL_RAND_RESET_Q(64);
    vlSelf->__PVT__io_coreid = VL_RAND_RESET_I(8);
}
