// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop_SimTop.h"

VL_ATTR_COLD void VSimTop_SimTop___ctor_var_reset(VSimTop_SimTop* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+      VSimTop_SimTop___ctor_var_reset\n"); );
    // Body
    vlSelf->reset = VL_RAND_RESET_I(1);
    vlSelf->clock = VL_RAND_RESET_I(1);
    vlSelf->difftest_logCtrl_begin = VL_RAND_RESET_I(1);
    vlSelf->difftest_logCtrl_end = VL_RAND_RESET_I(1);
    vlSelf->difftest_uart_out_valid = VL_RAND_RESET_I(1);
    vlSelf->difftest_uart_out_ch = VL_RAND_RESET_I(8);
    vlSelf->difftest_uart_in_valid = VL_RAND_RESET_I(1);
    vlSelf->difftest_uart_in_ch = VL_RAND_RESET_I(8);
    vlSelf->difftest_perfCtrl_clean = VL_RAND_RESET_I(1);
    vlSelf->difftest_perfCtrl_dump = VL_RAND_RESET_I(1);
    vlSelf->difftest_exit = VL_RAND_RESET_I(1);
    vlSelf->difftest_step = VL_RAND_RESET_I(1);
    vlSelf->__Vcellinp__u_top__rst_n = VL_RAND_RESET_I(1);
    vlSelf->__PVT__cnt = VL_RAND_RESET_Q(64);
    vlSelf->__Vdly__cnt = VL_RAND_RESET_Q(64);
}
