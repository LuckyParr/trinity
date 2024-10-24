// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop___024root.h"

void VSimTop___024root___eval_triggers__ico(VSimTop___024root* vlSelf);
void VSimTop___024root___eval_ico(VSimTop___024root* vlSelf);

bool VSimTop___024root___eval_phase__ico(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___eval_phase__ico\n"); );
    // Body
    VSimTop___024root___eval_triggers__ico(vlSelf);
    vlSelf->__VicoExecute = vlSelf->__VicoTriggered.any();
    if (vlSelf->__VicoExecute) {
        VSimTop___024root___eval_ico(vlSelf);
    }
    return (vlSelf->__VicoExecute);
}

void VSimTop___024root___eval_act(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___eval_act\n"); );
}

void VSimTop___024root___eval_triggers__act(VSimTop___024root* vlSelf);

bool VSimTop___024root___eval_phase__act(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___eval_phase__act\n"); );
    // Body
    VSimTop___024root___eval_triggers__act(vlSelf);
    vlSelf->__VactExecute = vlSelf->__VactTriggered.any();
    if (vlSelf->__VactExecute) {
        vlSelf->__VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
        vlSelf->__VnbaTriggered.thisOr(vlSelf->__VactTriggered);
        VSimTop___024root___eval_act(vlSelf);
    }
    return (vlSelf->__VactExecute);
}

void VSimTop___024root___eval_nba(VSimTop___024root* vlSelf);

bool VSimTop___024root___eval_phase__nba(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___eval_phase__nba\n"); );
    // Body
    vlSelf->__VnbaExecute = vlSelf->__VnbaTriggered.any();
    if (vlSelf->__VnbaExecute) {
        VSimTop___024root___eval_nba(vlSelf);
        vlSelf->__VnbaTriggered.clear();
    }
    return (vlSelf->__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VSimTop___024root___dump_triggers__ico(VSimTop___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void VSimTop___024root___dump_triggers__nba(VSimTop___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void VSimTop___024root___dump_triggers__act(VSimTop___024root* vlSelf);
#endif  // VL_DEBUG

void VSimTop___024root___eval(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___eval\n"); );
    // Init
    IData/*31:0*/ __Vtemp_1;
    IData/*31:0*/ __Vtemp_2;
    IData/*31:0*/ __Vtemp_3;
    // Body
    vlSelf->__VicoIterCount = 0U;
    vlSelf->__VicoFirstIteration = 1U;
    vlSelf->__VicoContinue = 1U;
    while (vlSelf->__VicoContinue) {
        if (VL_UNLIKELY((0x64U < vlSelf->__VicoIterCount))) {
#ifdef VL_DEBUG
            VSimTop___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("/nfs/home/jinpeize/trinity/build/rtl/SimTop.sv", 1, "", "Input combinational region did not converge.");
        }
        __Vtemp_1 = ((IData)(1U) + vlSelf->__VicoIterCount);
        vlSelf->__VicoIterCount = __Vtemp_1;
        vlSelf->__VicoContinue = 0U;
        if (VSimTop___024root___eval_phase__ico(vlSelf)) {
            vlSelf->__VicoContinue = 1U;
        }
        vlSelf->__VicoFirstIteration = 0U;
    }
    vlSelf->__VnbaIterCount = 0U;
    vlSelf->__VnbaFirstIteration = 1U;
    vlSelf->__VnbaContinue = 1U;
    while (vlSelf->__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < vlSelf->__VnbaIterCount))) {
#ifdef VL_DEBUG
            VSimTop___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("/nfs/home/jinpeize/trinity/build/rtl/SimTop.sv", 1, "", "NBA region did not converge.");
        }
        __Vtemp_2 = ((IData)(1U) + vlSelf->__VnbaIterCount);
        vlSelf->__VnbaIterCount = __Vtemp_2;
        vlSelf->__VnbaContinue = 0U;
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactFirstIteration = 1U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                VSimTop___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("/nfs/home/jinpeize/trinity/build/rtl/SimTop.sv", 1, "", "Active region did not converge.");
            }
            __Vtemp_3 = ((IData)(1U) + vlSelf->__VactIterCount);
            vlSelf->__VactIterCount = __Vtemp_3;
            vlSelf->__VactContinue = 0U;
            if (VSimTop___024root___eval_phase__act(vlSelf)) {
                vlSelf->__VactContinue = 1U;
            }
            vlSelf->__VactFirstIteration = 0U;
        }
        if (VSimTop___024root___eval_phase__nba(vlSelf)) {
            vlSelf->__VnbaContinue = 1U;
        }
        vlSelf->__VnbaFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
void VSimTop___024root___eval_debug_assertions(VSimTop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->reset & 0xfeU))) {
        Verilated::overWidthError("reset");}
    if (VL_UNLIKELY((vlSelf->clock & 0xfeU))) {
        Verilated::overWidthError("clock");}
    if (VL_UNLIKELY((vlSelf->difftest_logCtrl_begin 
                     & 0xfeU))) {
        Verilated::overWidthError("difftest_logCtrl_begin");}
    if (VL_UNLIKELY((vlSelf->difftest_logCtrl_end & 0xfeU))) {
        Verilated::overWidthError("difftest_logCtrl_end");}
    if (VL_UNLIKELY((vlSelf->difftest_uart_in_valid 
                     & 0xfeU))) {
        Verilated::overWidthError("difftest_uart_in_valid");}
    if (VL_UNLIKELY((vlSelf->difftest_perfCtrl_clean 
                     & 0xfeU))) {
        Verilated::overWidthError("difftest_perfCtrl_clean");}
    if (VL_UNLIKELY((vlSelf->difftest_perfCtrl_dump 
                     & 0xfeU))) {
        Verilated::overWidthError("difftest_perfCtrl_dump");}
}
#endif  // VL_DEBUG
