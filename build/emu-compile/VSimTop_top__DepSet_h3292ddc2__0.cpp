// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop_top.h"

VL_INLINE_OPT void VSimTop_top___nba_sequent__TOP__SimTop__u_top__0(VSimTop_top* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop_top___nba_sequent__TOP__SimTop__u_top__0\n"); );
    // Body
    vlSelf->__Vdly__a = vlSelf->__PVT__a;
    vlSelf->__Vdly__b = vlSelf->__PVT__b;
    vlSelf->__Vdly__w_mask = vlSelf->__PVT__w_mask;
    vlSelf->__Vdly__w_data = vlSelf->__PVT__w_data;
    vlSelf->__Vdly__w_index = vlSelf->__PVT__w_index;
    vlSelf->__Vdly__w_enable = vlSelf->__PVT__w_enable;
    vlSelf->__Vdly__r_index = vlSelf->__PVT__r_index;
    vlSelf->__Vdly__r_enable = vlSelf->__PVT__r_enable;
    vlSelf->__Vdly__a = (0xfU & ((IData)(vlSelf->__PVT__rst_n)
                                  ? ((1U & VL_BITSEL_IIII(4, (IData)(vlSelf->__PVT__a), 3U))
                                      ? (IData)(vlSelf->__PVT__a)
                                      : ((IData)(1U) 
                                         + (IData)(vlSelf->__PVT__a)))
                                  : 0U));
    if (vlSelf->__PVT__rst_n) {
        if ((1U & VL_BITSEL_IIII(4, (IData)(vlSelf->__PVT__a), 3U))) {
            vlSelf->__Vdly__b = 1U;
        }
    } else {
        vlSelf->__Vdly__b = 0U;
    }
    if ((1U & (~ (IData)(vlSelf->__PVT__rst_n)))) {
        vlSelf->__Vdly__r_enable = 0U;
        vlSelf->__Vdly__r_index = 0ULL;
        vlSelf->__Vdly__w_enable = 0U;
        vlSelf->__Vdly__w_index = 0ULL;
        vlSelf->__Vdly__w_data = 0ULL;
        vlSelf->__Vdly__w_mask = 0ULL;
    }
    vlSelf->__PVT__a = vlSelf->__Vdly__a;
    vlSelf->__PVT__b = vlSelf->__Vdly__b;
    vlSelf->__PVT__r_enable = vlSelf->__Vdly__r_enable;
    vlSelf->__PVT__r_index = vlSelf->__Vdly__r_index;
    vlSelf->__PVT__w_enable = vlSelf->__Vdly__w_enable;
    vlSelf->__PVT__w_index = vlSelf->__Vdly__w_index;
    vlSelf->__PVT__w_data = vlSelf->__Vdly__w_data;
    vlSelf->__PVT__w_mask = vlSelf->__Vdly__w_mask;
    vlSelf->__PVT__opt = vlSelf->__PVT__b;
}
