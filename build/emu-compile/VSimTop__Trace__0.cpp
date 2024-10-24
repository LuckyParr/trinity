// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "VSimTop__Syms.h"


void VSimTop___024root__trace_chg_0_sub_0(VSimTop___024root* vlSelf, VerilatedVcd::Buffer* bufp);

void VSimTop___024root__trace_chg_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_chg_0\n"); );
    // Init
    VSimTop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<VSimTop___024root*>(voidSelf);
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    VSimTop___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void VSimTop___024root__trace_chg_0_sub_0(VSimTop___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_chg_0_sub_0\n"); );
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    if (VL_UNLIKELY(vlSelf->__Vm_traceActivity[0U])) {
        bufp->chgBit(oldp+0,(vlSymsp->TOP__SimTop.difftest_uart_out_valid));
        bufp->chgCData(oldp+1,(vlSymsp->TOP__SimTop.difftest_uart_out_ch),8);
        bufp->chgBit(oldp+2,(vlSymsp->TOP__SimTop.difftest_exit));
        bufp->chgBit(oldp+3,(vlSymsp->TOP__SimTop.difftest_step));
        bufp->chgBit(oldp+4,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__enable));
        bufp->chgBit(oldp+5,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_hasTrap));
        bufp->chgQData(oldp+6,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_instrCnt),64);
        bufp->chgBit(oldp+8,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_hasWFI));
        bufp->chgIData(oldp+9,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_code),32);
        bufp->chgQData(oldp+10,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_pc),64);
        bufp->chgCData(oldp+12,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_coreid),8);
        bufp->chgBit(oldp+13,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__enable));
    }
    if (VL_UNLIKELY(vlSelf->__Vm_traceActivity[1U])) {
        bufp->chgBit(oldp+14,(vlSymsp->TOP__SimTop.reset));
        bufp->chgBit(oldp+15,(vlSymsp->TOP__SimTop.clock));
        bufp->chgBit(oldp+16,(vlSymsp->TOP__SimTop.difftest_logCtrl_begin));
        bufp->chgBit(oldp+17,(vlSymsp->TOP__SimTop.difftest_logCtrl_end));
        bufp->chgBit(oldp+18,(vlSymsp->TOP__SimTop.difftest_uart_in_valid));
        bufp->chgCData(oldp+19,(vlSymsp->TOP__SimTop.difftest_uart_in_ch),8);
        bufp->chgBit(oldp+20,(vlSymsp->TOP__SimTop.difftest_perfCtrl_clean));
        bufp->chgBit(oldp+21,(vlSymsp->TOP__SimTop.difftest_perfCtrl_dump));
        bufp->chgBit(oldp+22,(vlSymsp->TOP__SimTop__u_top.__PVT__clk));
        bufp->chgBit(oldp+23,(vlSymsp->TOP__SimTop__u_top.__PVT__rst_n));
        bufp->chgBit(oldp+24,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__clock));
        bufp->chgBit(oldp+25,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__clock));
    }
    if (VL_UNLIKELY(vlSelf->__Vm_traceActivity[2U])) {
        bufp->chgIData(oldp+26,(vlSymsp->TOP__SimTop__u_top.__PVT__opt),32);
        bufp->chgCData(oldp+27,(vlSymsp->TOP__SimTop__u_top.__PVT__a),4);
        bufp->chgIData(oldp+28,(vlSymsp->TOP__SimTop__u_top.__PVT__b),32);
        bufp->chgBit(oldp+29,(vlSymsp->TOP__SimTop__u_top.__PVT__r_enable));
        bufp->chgQData(oldp+30,(vlSymsp->TOP__SimTop__u_top.__PVT__r_index),64);
        bufp->chgBit(oldp+32,(vlSymsp->TOP__SimTop__u_top.__PVT__w_enable));
        bufp->chgQData(oldp+33,(vlSymsp->TOP__SimTop__u_top.__PVT__w_index),64);
        bufp->chgQData(oldp+35,(vlSymsp->TOP__SimTop__u_top.__PVT__w_data),64);
        bufp->chgQData(oldp+37,(vlSymsp->TOP__SimTop__u_top.__PVT__w_mask),64);
    }
    if (VL_UNLIKELY(vlSelf->__Vm_traceActivity[3U])) {
        bufp->chgBit(oldp+39,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__r_enable));
        bufp->chgQData(oldp+40,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__r_index),64);
        bufp->chgBit(oldp+42,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__w_enable));
        bufp->chgQData(oldp+43,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__w_index),64);
        bufp->chgQData(oldp+45,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__w_data),64);
        bufp->chgQData(oldp+47,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__w_mask),64);
    }
    bufp->chgBit(oldp+49,(vlSelf->reset));
    bufp->chgBit(oldp+50,(vlSelf->clock));
    bufp->chgBit(oldp+51,(vlSelf->difftest_logCtrl_begin));
    bufp->chgBit(oldp+52,(vlSelf->difftest_logCtrl_end));
    bufp->chgBit(oldp+53,(vlSelf->difftest_uart_out_valid));
    bufp->chgCData(oldp+54,(vlSelf->difftest_uart_out_ch),8);
    bufp->chgBit(oldp+55,(vlSelf->difftest_uart_in_valid));
    bufp->chgCData(oldp+56,(vlSelf->difftest_uart_in_ch),8);
    bufp->chgBit(oldp+57,(vlSelf->difftest_perfCtrl_clean));
    bufp->chgBit(oldp+58,(vlSelf->difftest_perfCtrl_dump));
    bufp->chgBit(oldp+59,(vlSelf->difftest_exit));
    bufp->chgBit(oldp+60,(vlSelf->difftest_step));
    bufp->chgQData(oldp+61,(vlSymsp->TOP__SimTop.__PVT__cnt),64);
    bufp->chgQData(oldp+63,(vlSymsp->TOP__SimTop__u_top.__PVT__r_data),64);
    bufp->chgQData(oldp+65,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_cycleCnt),64);
    bufp->chgQData(oldp+67,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__r_data),64);
}

void VSimTop___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_cleanup\n"); );
    // Init
    VSimTop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<VSimTop___024root*>(voidSelf);
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    vlSymsp->__Vm_activity = false;
    vlSymsp->TOP.__Vm_traceActivity[0U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[1U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[2U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[3U] = 0U;
}
