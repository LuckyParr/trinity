// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "VSimTop__Syms.h"


VL_ATTR_COLD void VSimTop___024root__trace_init_sub__TOP__SimTop__0(VSimTop___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD void VSimTop___024root__trace_init_sub__TOP__0(VSimTop___024root* vlSelf, VerilatedVcd* tracep) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_init_sub__TOP__0\n"); );
    // Init
    const int c = vlSymsp->__Vm_baseCode;
    // Body
    tracep->pushPrefix("SimTop", VerilatedTracePrefixType::SCOPE_MODULE);
    VSimTop___024root__trace_init_sub__TOP__SimTop__0(vlSelf, tracep);
    tracep->popPrefix();
    tracep->declBit(c+50,0,"reset",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+51,0,"clock",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+52,0,"difftest_logCtrl_begin",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+53,0,"difftest_logCtrl_end",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+54,0,"difftest_uart_out_valid",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBus(c+55,0,"difftest_uart_out_ch",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 7,0);
    tracep->declBit(c+56,0,"difftest_uart_in_valid",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBus(c+57,0,"difftest_uart_in_ch",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 7,0);
    tracep->declBit(c+58,0,"difftest_perfCtrl_clean",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+59,0,"difftest_perfCtrl_dump",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+60,0,"difftest_exit",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+61,0,"difftest_step",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
}

VL_ATTR_COLD void VSimTop___024root__trace_init_sub__TOP__SimTop__u_top__0(VSimTop___024root* vlSelf, VerilatedVcd* tracep);
VL_ATTR_COLD void VSimTop___024root__trace_init_sub__TOP__SimTop__u_DifftestTrapEvent__0(VSimTop___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD void VSimTop___024root__trace_init_sub__TOP__SimTop__0(VSimTop___024root* vlSelf, VerilatedVcd* tracep) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_init_sub__TOP__SimTop__0\n"); );
    // Init
    const int c = vlSymsp->__Vm_baseCode;
    // Body
    tracep->declBit(c+15,0,"reset",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+16,0,"clock",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+17,0,"difftest_logCtrl_begin",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+18,0,"difftest_logCtrl_end",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+1,0,"difftest_uart_out_valid",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBus(c+2,0,"difftest_uart_out_ch",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 7,0);
    tracep->declBit(c+19,0,"difftest_uart_in_valid",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBus(c+20,0,"difftest_uart_in_ch",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 7,0);
    tracep->declBit(c+21,0,"difftest_perfCtrl_clean",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+22,0,"difftest_perfCtrl_dump",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+3,0,"difftest_exit",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+4,0,"difftest_step",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->pushPrefix("u_top", VerilatedTracePrefixType::SCOPE_MODULE);
    VSimTop___024root__trace_init_sub__TOP__SimTop__u_top__0(vlSelf, tracep);
    tracep->popPrefix();
    tracep->declQuad(c+62,0,"cnt",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->pushPrefix("u_DifftestTrapEvent", VerilatedTracePrefixType::SCOPE_MODULE);
    VSimTop___024root__trace_init_sub__TOP__SimTop__u_DifftestTrapEvent__0(vlSelf, tracep);
    tracep->popPrefix();
}

VL_ATTR_COLD void VSimTop___024root__trace_init_sub__TOP__SimTop__u_top__mem__0(VSimTop___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD void VSimTop___024root__trace_init_sub__TOP__SimTop__u_top__0(VSimTop___024root* vlSelf, VerilatedVcd* tracep) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_init_sub__TOP__SimTop__u_top__0\n"); );
    // Init
    const int c = vlSymsp->__Vm_baseCode;
    // Body
    tracep->declBit(c+23,0,"clk",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+24,0,"rst_n",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBus(c+27,0,"opt",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 31,0);
    tracep->declBus(c+28,0,"a",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 3,0);
    tracep->declBus(c+29,0,"b",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 31,0);
    tracep->declBit(c+30,0,"r_enable",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declQuad(c+31,0,"r_index",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->declQuad(c+64,0,"r_data",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->declBit(c+33,0,"w_enable",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declQuad(c+34,0,"w_index",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->declQuad(c+36,0,"w_data",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->declQuad(c+38,0,"w_mask",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->declBit(c+70,0,"enable",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->pushPrefix("mem", VerilatedTracePrefixType::SCOPE_MODULE);
    VSimTop___024root__trace_init_sub__TOP__SimTop__u_top__mem__0(vlSelf, tracep);
    tracep->popPrefix();
}

VL_ATTR_COLD void VSimTop___024root__trace_init_sub__TOP__SimTop__u_DifftestTrapEvent__0(VSimTop___024root* vlSelf, VerilatedVcd* tracep) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_init_sub__TOP__SimTop__u_DifftestTrapEvent__0\n"); );
    // Init
    const int c = vlSymsp->__Vm_baseCode;
    // Body
    tracep->declBit(c+25,0,"clock",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+5,0,"enable",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+6,0,"io_hasTrap",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declQuad(c+66,0,"io_cycleCnt",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->declQuad(c+7,0,"io_instrCnt",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->declBit(c+9,0,"io_hasWFI",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBus(c+10,0,"io_code",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 31,0);
    tracep->declQuad(c+11,0,"io_pc",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->declBus(c+13,0,"io_coreid",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 7,0);
}

VL_ATTR_COLD void VSimTop___024root__trace_init_sub__TOP__SimTop__u_top__mem__0(VSimTop___024root* vlSelf, VerilatedVcd* tracep) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_init_sub__TOP__SimTop__u_top__mem__0\n"); );
    // Init
    const int c = vlSymsp->__Vm_baseCode;
    // Body
    tracep->declBit(c+40,0,"r_enable",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declQuad(c+41,0,"r_index",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->declQuad(c+68,0,"r_data",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->declBit(c+43,0,"w_enable",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declQuad(c+44,0,"w_index",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->declQuad(c+46,0,"w_data",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->declQuad(c+48,0,"w_mask",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 63,0);
    tracep->declBit(c+14,0,"enable",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+26,0,"clock",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
}

VL_ATTR_COLD void VSimTop___024root__trace_init_top(VSimTop___024root* vlSelf, VerilatedVcd* tracep) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_init_top\n"); );
    // Body
    VSimTop___024root__trace_init_sub__TOP__0(vlSelf, tracep);
}

VL_ATTR_COLD void VSimTop___024root__trace_const_0(void* voidSelf, VerilatedVcd::Buffer* bufp);
VL_ATTR_COLD void VSimTop___024root__trace_full_0(void* voidSelf, VerilatedVcd::Buffer* bufp);
void VSimTop___024root__trace_chg_0(void* voidSelf, VerilatedVcd::Buffer* bufp);
void VSimTop___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/);

VL_ATTR_COLD void VSimTop___024root__trace_register(VSimTop___024root* vlSelf, VerilatedVcd* tracep) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_register\n"); );
    // Body
    tracep->addConstCb(&VSimTop___024root__trace_const_0, 0U, vlSelf);
    tracep->addFullCb(&VSimTop___024root__trace_full_0, 0U, vlSelf);
    tracep->addChgCb(&VSimTop___024root__trace_chg_0, 0U, vlSelf);
    tracep->addCleanupCb(&VSimTop___024root__trace_cleanup, vlSelf);
}

VL_ATTR_COLD void VSimTop___024root__trace_const_0_sub_0(VSimTop___024root* vlSelf, VerilatedVcd::Buffer* bufp);

VL_ATTR_COLD void VSimTop___024root__trace_const_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_const_0\n"); );
    // Init
    VSimTop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<VSimTop___024root*>(voidSelf);
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    VSimTop___024root__trace_const_0_sub_0((&vlSymsp->TOP), bufp);
}

VL_ATTR_COLD void VSimTop___024root__trace_const_0_sub_0(VSimTop___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_const_0_sub_0\n"); );
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode);
    // Body
    bufp->fullBit(oldp+70,(vlSymsp->TOP__SimTop__u_top.__PVT__enable));
}

VL_ATTR_COLD void VSimTop___024root__trace_full_0_sub_0(VSimTop___024root* vlSelf, VerilatedVcd::Buffer* bufp);

VL_ATTR_COLD void VSimTop___024root__trace_full_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_full_0\n"); );
    // Init
    VSimTop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<VSimTop___024root*>(voidSelf);
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    VSimTop___024root__trace_full_0_sub_0((&vlSymsp->TOP), bufp);
}

VL_ATTR_COLD void VSimTop___024root__trace_full_0_sub_0(VSimTop___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    (void)vlSelf;  // Prevent unused variable warning
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VSimTop___024root__trace_full_0_sub_0\n"); );
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode);
    // Body
    bufp->fullBit(oldp+1,(vlSymsp->TOP__SimTop.difftest_uart_out_valid));
    bufp->fullCData(oldp+2,(vlSymsp->TOP__SimTop.difftest_uart_out_ch),8);
    bufp->fullBit(oldp+3,(vlSymsp->TOP__SimTop.difftest_exit));
    bufp->fullBit(oldp+4,(vlSymsp->TOP__SimTop.difftest_step));
    bufp->fullBit(oldp+5,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__enable));
    bufp->fullBit(oldp+6,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_hasTrap));
    bufp->fullQData(oldp+7,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_instrCnt),64);
    bufp->fullBit(oldp+9,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_hasWFI));
    bufp->fullIData(oldp+10,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_code),32);
    bufp->fullQData(oldp+11,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_pc),64);
    bufp->fullCData(oldp+13,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_coreid),8);
    bufp->fullBit(oldp+14,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__enable));
    bufp->fullBit(oldp+15,(vlSymsp->TOP__SimTop.reset));
    bufp->fullBit(oldp+16,(vlSymsp->TOP__SimTop.clock));
    bufp->fullBit(oldp+17,(vlSymsp->TOP__SimTop.difftest_logCtrl_begin));
    bufp->fullBit(oldp+18,(vlSymsp->TOP__SimTop.difftest_logCtrl_end));
    bufp->fullBit(oldp+19,(vlSymsp->TOP__SimTop.difftest_uart_in_valid));
    bufp->fullCData(oldp+20,(vlSymsp->TOP__SimTop.difftest_uart_in_ch),8);
    bufp->fullBit(oldp+21,(vlSymsp->TOP__SimTop.difftest_perfCtrl_clean));
    bufp->fullBit(oldp+22,(vlSymsp->TOP__SimTop.difftest_perfCtrl_dump));
    bufp->fullBit(oldp+23,(vlSymsp->TOP__SimTop__u_top.__PVT__clk));
    bufp->fullBit(oldp+24,(vlSymsp->TOP__SimTop__u_top.__PVT__rst_n));
    bufp->fullBit(oldp+25,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__clock));
    bufp->fullBit(oldp+26,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__clock));
    bufp->fullIData(oldp+27,(vlSymsp->TOP__SimTop__u_top.__PVT__opt),32);
    bufp->fullCData(oldp+28,(vlSymsp->TOP__SimTop__u_top.__PVT__a),4);
    bufp->fullIData(oldp+29,(vlSymsp->TOP__SimTop__u_top.__PVT__b),32);
    bufp->fullBit(oldp+30,(vlSymsp->TOP__SimTop__u_top.__PVT__r_enable));
    bufp->fullQData(oldp+31,(vlSymsp->TOP__SimTop__u_top.__PVT__r_index),64);
    bufp->fullBit(oldp+33,(vlSymsp->TOP__SimTop__u_top.__PVT__w_enable));
    bufp->fullQData(oldp+34,(vlSymsp->TOP__SimTop__u_top.__PVT__w_index),64);
    bufp->fullQData(oldp+36,(vlSymsp->TOP__SimTop__u_top.__PVT__w_data),64);
    bufp->fullQData(oldp+38,(vlSymsp->TOP__SimTop__u_top.__PVT__w_mask),64);
    bufp->fullBit(oldp+40,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__r_enable));
    bufp->fullQData(oldp+41,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__r_index),64);
    bufp->fullBit(oldp+43,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__w_enable));
    bufp->fullQData(oldp+44,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__w_index),64);
    bufp->fullQData(oldp+46,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__w_data),64);
    bufp->fullQData(oldp+48,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__w_mask),64);
    bufp->fullBit(oldp+50,(vlSelf->reset));
    bufp->fullBit(oldp+51,(vlSelf->clock));
    bufp->fullBit(oldp+52,(vlSelf->difftest_logCtrl_begin));
    bufp->fullBit(oldp+53,(vlSelf->difftest_logCtrl_end));
    bufp->fullBit(oldp+54,(vlSelf->difftest_uart_out_valid));
    bufp->fullCData(oldp+55,(vlSelf->difftest_uart_out_ch),8);
    bufp->fullBit(oldp+56,(vlSelf->difftest_uart_in_valid));
    bufp->fullCData(oldp+57,(vlSelf->difftest_uart_in_ch),8);
    bufp->fullBit(oldp+58,(vlSelf->difftest_perfCtrl_clean));
    bufp->fullBit(oldp+59,(vlSelf->difftest_perfCtrl_dump));
    bufp->fullBit(oldp+60,(vlSelf->difftest_exit));
    bufp->fullBit(oldp+61,(vlSelf->difftest_step));
    bufp->fullQData(oldp+62,(vlSymsp->TOP__SimTop.__PVT__cnt),64);
    bufp->fullQData(oldp+64,(vlSymsp->TOP__SimTop__u_top.__PVT__r_data),64);
    bufp->fullQData(oldp+66,(vlSymsp->TOP__SimTop__u_DifftestTrapEvent.__PVT__io_cycleCnt),64);
    bufp->fullQData(oldp+68,(vlSymsp->TOP__SimTop__u_top__mem.__PVT__r_data),64);
}
