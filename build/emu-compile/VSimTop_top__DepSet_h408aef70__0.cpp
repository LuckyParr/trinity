// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop__Syms.h"
#include "VSimTop_top.h"

VL_INLINE_OPT void VSimTop_top___ico_sequent__TOP__SimTop__u_top__0(VSimTop_top* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop_top___ico_sequent__TOP__SimTop__u_top__0\n"); );
    // Body
    vlSymsp->TOP__SimTop__u_top__mem.__PVT__clock = vlSelf->__PVT__clk;
}

VL_INLINE_OPT void VSimTop_top___nba_sequent__TOP__SimTop__u_top__1(VSimTop_top* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop_top___nba_sequent__TOP__SimTop__u_top__1\n"); );
    // Body
    vlSelf->__PVT__r_data = vlSymsp->TOP__SimTop__u_top__mem.__PVT__r_data;
}

VL_INLINE_OPT void VSimTop_top___nba_sequent__TOP__SimTop__u_top__2(VSimTop_top* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop_top___nba_sequent__TOP__SimTop__u_top__2\n"); );
    // Body
    vlSymsp->TOP__SimTop__u_top__mem.__PVT__r_enable 
        = vlSelf->__PVT__r_enable;
    vlSymsp->TOP__SimTop__u_top__mem.__PVT__r_index 
        = vlSelf->__PVT__r_index;
    vlSymsp->TOP__SimTop__u_top__mem.__PVT__w_enable 
        = vlSelf->__PVT__w_enable;
    vlSymsp->TOP__SimTop__u_top__mem.__PVT__w_index 
        = vlSelf->__PVT__w_index;
    vlSymsp->TOP__SimTop__u_top__mem.__PVT__w_data 
        = vlSelf->__PVT__w_data;
    vlSymsp->TOP__SimTop__u_top__mem.__PVT__w_mask 
        = vlSelf->__PVT__w_mask;
}
