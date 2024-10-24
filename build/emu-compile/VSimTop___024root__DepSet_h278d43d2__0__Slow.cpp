// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop__Syms.h"
#include "VSimTop___024root.h"

VL_ATTR_COLD void VSimTop_SimTop___eval_initial__TOP__SimTop(VSimTop_SimTop* vlSelf);
VL_ATTR_COLD void VSimTop_top___eval_initial__TOP__SimTop__u_top(VSimTop_top* vlSelf);

VL_ATTR_COLD void VSimTop___024root___eval_initial(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___eval_initial\n"); );
    // Body
    VSimTop_SimTop___eval_initial__TOP__SimTop((&vlSymsp->TOP__SimTop));
    vlSelf->__Vm_traceActivity[3U] = 1U;
    vlSelf->__Vm_traceActivity[2U] = 1U;
    vlSelf->__Vm_traceActivity[1U] = 1U;
    vlSelf->__Vm_traceActivity[0U] = 1U;
    VSimTop_top___eval_initial__TOP__SimTop__u_top((&vlSymsp->TOP__SimTop__u_top));
    vlSelf->__Vtrigprevexpr___TOP__SimTop__clock__0 
        = vlSymsp->TOP__SimTop.clock;
    vlSelf->__Vtrigprevexpr___TOP__SimTop__u_top____PVT__clk__0 
        = vlSymsp->TOP__SimTop__u_top.__PVT__clk;
    vlSelf->__Vtrigprevexpr___TOP__SimTop__u_DifftestTrapEvent____PVT__clock__0 
        = vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__clock;
    vlSelf->__Vtrigprevexpr___TOP__SimTop__u_top__mem____PVT__clock__0 
        = vlSymsp->TOP__SimTop__u_top__mem.__PVT__clock;
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VSimTop___024root___dump_triggers__stl(VSimTop___024root* vlSelf);
#endif  // VL_DEBUG

VL_ATTR_COLD void VSimTop___024root___eval_triggers__stl(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___eval_triggers__stl\n"); );
    // Body
    vlSelf->__VstlTriggered.set(0U, (IData)(vlSelf->__VstlFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        VSimTop___024root___dump_triggers__stl(vlSelf);
    }
#endif
}

VL_ATTR_COLD void VSimTop___024root___stl_sequent__TOP__0(VSimTop___024root* vlSelf);
VL_ATTR_COLD void VSimTop_SimTop___stl_sequent__TOP__SimTop__0(VSimTop_SimTop* vlSelf);
VL_ATTR_COLD void VSimTop_top___stl_sequent__TOP__SimTop__u_top__0(VSimTop_top* vlSelf);

VL_ATTR_COLD void VSimTop___024root___eval_stl(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___eval_stl\n"); );
    // Body
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        VSimTop___024root___stl_sequent__TOP__0(vlSelf);
        vlSelf->__Vm_traceActivity[3U] = 1U;
        vlSelf->__Vm_traceActivity[2U] = 1U;
        vlSelf->__Vm_traceActivity[1U] = 1U;
        vlSelf->__Vm_traceActivity[0U] = 1U;
        VSimTop_SimTop___stl_sequent__TOP__SimTop__0((&vlSymsp->TOP__SimTop));
        VSimTop_top___stl_sequent__TOP__SimTop__u_top__0((&vlSymsp->TOP__SimTop__u_top));
    }
}

VL_ATTR_COLD void VSimTop___024root___stl_sequent__TOP__0(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___stl_sequent__TOP__0\n"); );
    // Body
    vlSelf->difftest_step = vlSymsp->TOP__SimTop.difftest_step;
    vlSelf->difftest_exit = vlSymsp->TOP__SimTop.difftest_exit;
    vlSymsp->TOP__SimTop.difftest_perfCtrl_dump = vlSelf->difftest_perfCtrl_dump;
    vlSymsp->TOP__SimTop.difftest_perfCtrl_clean = vlSelf->difftest_perfCtrl_clean;
    vlSymsp->TOP__SimTop.difftest_uart_in_ch = vlSelf->difftest_uart_in_ch;
    vlSymsp->TOP__SimTop.difftest_uart_in_valid = vlSelf->difftest_uart_in_valid;
    vlSelf->difftest_uart_out_ch = vlSymsp->TOP__SimTop.difftest_uart_out_ch;
    vlSelf->difftest_uart_out_valid = vlSymsp->TOP__SimTop.difftest_uart_out_valid;
    vlSymsp->TOP__SimTop.difftest_logCtrl_end = vlSelf->difftest_logCtrl_end;
    vlSymsp->TOP__SimTop.difftest_logCtrl_begin = vlSelf->difftest_logCtrl_begin;
    vlSymsp->TOP__SimTop.reset = vlSelf->reset;
    vlSymsp->TOP__SimTop.clock = vlSelf->clock;
}
