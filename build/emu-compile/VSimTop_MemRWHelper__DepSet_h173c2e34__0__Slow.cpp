// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop_MemRWHelper.h"

VL_ATTR_COLD void VSimTop_MemRWHelper___ctor_var_reset(VSimTop_MemRWHelper* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+          VSimTop_MemRWHelper___ctor_var_reset\n"); );
    // Body
    vlSelf->__PVT__r_enable = VL_RAND_RESET_I(1);
    vlSelf->__PVT__r_index = VL_RAND_RESET_Q(64);
    vlSelf->__PVT__r_data = VL_RAND_RESET_Q(64);
    vlSelf->__PVT__w_enable = VL_RAND_RESET_I(1);
    vlSelf->__PVT__w_index = VL_RAND_RESET_Q(64);
    vlSelf->__PVT__w_data = VL_RAND_RESET_Q(64);
    vlSelf->__PVT__w_mask = VL_RAND_RESET_Q(64);
    vlSelf->__PVT__enable = VL_RAND_RESET_I(1);
    vlSelf->__PVT__clock = VL_RAND_RESET_I(1);
    vlSelf->__Vfunc_difftest_ram_read__0__Vfuncout = 0;
    vlSelf->__Vdly__r_data = VL_RAND_RESET_Q(64);
}
