// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop__Syms.h"
#include "VSimTop___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void VSimTop___024root___dump_triggers__ico(VSimTop___024root* vlSelf);
#endif  // VL_DEBUG

void VSimTop___024root___eval_triggers__ico(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___eval_triggers__ico\n"); );
    // Body
    vlSelf->__VicoTriggered.set(0U, (IData)(vlSelf->__VicoFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        VSimTop___024root___dump_triggers__ico(vlSelf);
    }
#endif
}

void VSimTop___024root___ico_sequent__TOP__0(VSimTop___024root* vlSelf);
void VSimTop_SimTop___ico_sequent__TOP__SimTop__0(VSimTop_SimTop* vlSelf);
void VSimTop_top___ico_sequent__TOP__SimTop__u_top__0(VSimTop_top* vlSelf);

void VSimTop___024root___eval_ico(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___eval_ico\n"); );
    // Body
    if ((1ULL & vlSelf->__VicoTriggered.word(0U))) {
        VSimTop___024root___ico_sequent__TOP__0(vlSelf);
        vlSelf->__Vm_traceActivity[1U] = 1U;
        VSimTop_SimTop___ico_sequent__TOP__SimTop__0((&vlSymsp->TOP__SimTop));
        VSimTop_top___ico_sequent__TOP__SimTop__u_top__0((&vlSymsp->TOP__SimTop__u_top));
    }
}

VL_INLINE_OPT void VSimTop___024root___ico_sequent__TOP__0(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___ico_sequent__TOP__0\n"); );
    // Body
    vlSymsp->TOP__SimTop.difftest_perfCtrl_dump = vlSelf->difftest_perfCtrl_dump;
    vlSymsp->TOP__SimTop.difftest_perfCtrl_clean = vlSelf->difftest_perfCtrl_clean;
    vlSymsp->TOP__SimTop.difftest_uart_in_ch = vlSelf->difftest_uart_in_ch;
    vlSymsp->TOP__SimTop.difftest_uart_in_valid = vlSelf->difftest_uart_in_valid;
    vlSymsp->TOP__SimTop.difftest_logCtrl_end = vlSelf->difftest_logCtrl_end;
    vlSymsp->TOP__SimTop.difftest_logCtrl_begin = vlSelf->difftest_logCtrl_begin;
    vlSymsp->TOP__SimTop.reset = vlSelf->reset;
    vlSymsp->TOP__SimTop.clock = vlSelf->clock;
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VSimTop___024root___dump_triggers__act(VSimTop___024root* vlSelf);
#endif  // VL_DEBUG

void VSimTop___024root___eval_triggers__act(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___eval_triggers__act\n"); );
    // Body
    vlSelf->__VactTriggered.set(0U, ((IData)(vlSymsp->TOP__SimTop.clock) 
                                     & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__SimTop__clock__0))));
    vlSelf->__VactTriggered.set(1U, ((IData)(vlSymsp->TOP__SimTop__u_top.__PVT__clk) 
                                     & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__SimTop__u_top____PVT__clk__0))));
    vlSelf->__VactTriggered.set(2U, ((IData)(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__clock) 
                                     & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__SimTop__u_DifftestTrapEvent____PVT__clock__0))));
    vlSelf->__VactTriggered.set(3U, ((IData)(vlSymsp->TOP__SimTop__u_top__mem.__PVT__clock) 
                                     & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__SimTop__u_top__mem____PVT__clock__0))));
    vlSelf->__Vtrigprevexpr___TOP__SimTop__clock__0 
        = vlSymsp->TOP__SimTop.clock;
    vlSelf->__Vtrigprevexpr___TOP__SimTop__u_top____PVT__clk__0 
        = vlSymsp->TOP__SimTop__u_top.__PVT__clk;
    vlSelf->__Vtrigprevexpr___TOP__SimTop__u_DifftestTrapEvent____PVT__clock__0 
        = vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__clock;
    vlSelf->__Vtrigprevexpr___TOP__SimTop__u_top__mem____PVT__clock__0 
        = vlSymsp->TOP__SimTop__u_top__mem.__PVT__clock;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        VSimTop___024root___dump_triggers__act(vlSelf);
    }
#endif
}

void VSimTop_DifftestTrapEvent___nba_sequent__TOP__SimTop__u_DifftestTrapEvent__0(VSimTop_DifftestTrapEvent* vlSelf);
void VSimTop_top___nba_sequent__TOP__SimTop__u_top__0(VSimTop_top* vlSelf);
void VSimTop_SimTop___nba_sequent__TOP__SimTop__0(VSimTop_SimTop* vlSelf);
void VSimTop_MemRWHelper___nba_sequent__TOP__SimTop__u_top__mem__0(VSimTop_MemRWHelper* vlSelf);
void VSimTop_top___nba_sequent__TOP__SimTop__u_top__1(VSimTop_top* vlSelf);
void VSimTop_top___nba_sequent__TOP__SimTop__u_top__2(VSimTop_top* vlSelf);

void VSimTop___024root___eval_nba(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___eval_nba\n"); );
    // Body
    if ((4ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VSimTop_DifftestTrapEvent___nba_sequent__TOP__SimTop__u_DifftestTrapEvent__0((&vlSymsp->TOP__SimTop__u_DifftestTrapEvent));
    }
    if ((2ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VSimTop_top___nba_sequent__TOP__SimTop__u_top__0((&vlSymsp->TOP__SimTop__u_top));
        vlSelf->__Vm_traceActivity[2U] = 1U;
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VSimTop_SimTop___nba_sequent__TOP__SimTop__0((&vlSymsp->TOP__SimTop));
    }
    if ((8ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VSimTop_MemRWHelper___nba_sequent__TOP__SimTop__u_top__mem__0((&vlSymsp->TOP__SimTop__u_top__mem));
        VSimTop_top___nba_sequent__TOP__SimTop__u_top__1((&vlSymsp->TOP__SimTop__u_top));
    }
    if ((2ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VSimTop_top___nba_sequent__TOP__SimTop__u_top__2((&vlSymsp->TOP__SimTop__u_top));
        vlSelf->__Vm_traceActivity[3U] = 1U;
    }
}
