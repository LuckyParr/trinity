// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop_MemRWHelper.h"
#include "VSimTop__Syms.h"

void VSimTop___024unit____Vdpiimwrap_difftest_ram_read_TOP____024unit(QData/*63:0*/ rIdx, QData/*63:0*/ &difftest_ram_read__Vfuncrtn);
void VSimTop___024unit____Vdpiimwrap_difftest_ram_write_TOP____024unit(QData/*63:0*/ index, QData/*63:0*/ data, QData/*63:0*/ mask);

VL_INLINE_OPT void VSimTop_MemRWHelper___nba_sequent__TOP__SimTop__u_top__mem__0(VSimTop_MemRWHelper* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+          VSimTop_MemRWHelper___nba_sequent__TOP__SimTop__u_top__mem__0\n"); );
    // Body
    vlSelf->__Vdly__r_data = vlSelf->__PVT__r_data;
    if (vlSelf->__PVT__enable) {
        if (vlSelf->__PVT__r_enable) {
            VSimTop___024unit____Vdpiimwrap_difftest_ram_read_TOP____024unit(vlSelf->__PVT__r_index, vlSelf->__Vfunc_difftest_ram_read__0__Vfuncout);
            vlSelf->__Vdly__r_data = vlSelf->__Vfunc_difftest_ram_read__0__Vfuncout;
        }
        if (vlSelf->__PVT__w_enable) {
            VSimTop___024unit____Vdpiimwrap_difftest_ram_write_TOP____024unit(vlSelf->__PVT__w_index, vlSelf->__PVT__w_data, vlSelf->__PVT__w_mask);
        }
    }
    vlSelf->__PVT__r_data = vlSelf->__Vdly__r_data;
}
