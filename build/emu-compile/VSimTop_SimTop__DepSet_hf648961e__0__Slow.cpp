// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop_SimTop.h"
#include "VSimTop__Syms.h"

VL_ATTR_COLD void VSimTop_SimTop___eval_initial__TOP__SimTop(VSimTop_SimTop* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+      VSimTop_SimTop___eval_initial__TOP__SimTop\n"); );
    // Body
    vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_coreid = 0U;
    vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_pc = 0ULL;
    vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_code = 0U;
    vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_hasWFI = 0U;
    vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_instrCnt = 0ULL;
    vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_hasTrap = 0U;
    vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__enable = 1U;
    vlSelf->difftest_step = 1U;
    vlSelf->difftest_exit = 0U;
    vlSelf->difftest_uart_out_ch = 0U;
    vlSelf->difftest_uart_out_valid = 0U;
}

VL_ATTR_COLD void VSimTop_SimTop___stl_sequent__TOP__SimTop__0(VSimTop_SimTop* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+      VSimTop_SimTop___stl_sequent__TOP__SimTop__0\n"); );
    // Body
    vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_cycleCnt 
        = vlSelf->__PVT__cnt;
    vlSelf->__Vcellinp__u_top__rst_n = (1U & (~ (IData)(vlSelf->reset)));
    vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__clock 
        = vlSelf->clock;
    vlSymsp->TOP__SimTop__u_top.__PVT__clk = vlSelf->clock;
    vlSymsp->TOP__SimTop__u_top.__PVT__rst_n = vlSelf->__Vcellinp__u_top__rst_n;
}
