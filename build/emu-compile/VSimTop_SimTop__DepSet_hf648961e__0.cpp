// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop_SimTop.h"
#include "VSimTop__Syms.h"

VL_INLINE_OPT void VSimTop_SimTop___ico_sequent__TOP__SimTop__0(VSimTop_SimTop* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+      VSimTop_SimTop___ico_sequent__TOP__SimTop__0\n"); );
    // Body
    vlSelf->__Vcellinp__u_top__rst_n = (1U & (~ (IData)(vlSelf->reset)));
    vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__clock 
        = vlSelf->clock;
    vlSymsp->TOP__SimTop__u_top.__PVT__clk = vlSelf->clock;
    vlSymsp->TOP__SimTop__u_top.__PVT__rst_n = vlSelf->__Vcellinp__u_top__rst_n;
}

VL_INLINE_OPT void VSimTop_SimTop___nba_sequent__TOP__SimTop__0(VSimTop_SimTop* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+      VSimTop_SimTop___nba_sequent__TOP__SimTop__0\n"); );
    // Body
    vlSelf->__Vdly__cnt = vlSelf->__PVT__cnt;
    vlSelf->__Vdly__cnt = ((IData)(vlSelf->reset) ? 0ULL
                            : (1ULL + vlSelf->__PVT__cnt));
    vlSelf->__PVT__cnt = vlSelf->__Vdly__cnt;
    vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_cycleCnt 
        = vlSelf->__PVT__cnt;
}
