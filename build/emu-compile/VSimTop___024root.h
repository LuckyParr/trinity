// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VSimTop.h for the primary calling header

#ifndef VERILATED_VSIMTOP___024ROOT_H_
#define VERILATED_VSIMTOP___024ROOT_H_  // guard

#include "verilated.h"
class VSimTop_SimTop;
class VSimTop___024unit;


class VSimTop__Syms;

class alignas(VL_CACHE_LINE_BYTES) VSimTop___024root final : public VerilatedModule {
  public:
    // CELLS
    VSimTop_SimTop* __PVT__SimTop;
    VSimTop___024unit* __PVT____024unit;

    // DESIGN SPECIFIC STATE
    VL_IN8(reset,0,0);
    VL_IN8(clock,0,0);
    VL_IN8(difftest_logCtrl_begin,0,0);
    VL_IN8(difftest_logCtrl_end,0,0);
    VL_OUT8(difftest_uart_out_valid,0,0);
    VL_OUT8(difftest_uart_out_ch,7,0);
    VL_IN8(difftest_uart_in_valid,0,0);
    VL_IN8(difftest_uart_in_ch,7,0);
    VL_IN8(difftest_perfCtrl_clean,0,0);
    VL_IN8(difftest_perfCtrl_dump,0,0);
    VL_OUT8(difftest_exit,0,0);
    VL_OUT8(difftest_step,0,0);
    CData/*0:0*/ __VstlExecute;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VstlContinue;
    CData/*0:0*/ __VicoExecute;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __VicoContinue;
    CData/*0:0*/ __Vtrigprevexpr___TOP__SimTop__clock__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__SimTop__u_top____PVT__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__SimTop__u_DifftestTrapEvent____PVT__clock__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__SimTop__u_top__mem____PVT__clock__0;
    CData/*0:0*/ __VactExecute;
    CData/*0:0*/ __VactFirstIteration;
    CData/*0:0*/ __VactContinue;
    CData/*0:0*/ __VnbaExecute;
    CData/*0:0*/ __VnbaFirstIteration;
    CData/*0:0*/ __VnbaContinue;
    IData/*31:0*/ __VstlIterCount;
    IData/*31:0*/ __VicoIterCount;
    IData/*31:0*/ __VactIterCount;
    IData/*31:0*/ __VnbaIterCount;
    VlUnpacked<CData/*0:0*/, 4> __Vm_traceActivity;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<4> __VactTriggered;
    VlTriggerVec<4> __VpreTriggered;
    VlTriggerVec<4> __VnbaTriggered;

    // INTERNAL VARIABLES
    VSimTop__Syms* const vlSymsp;

    // CONSTRUCTORS
    VSimTop___024root(VSimTop__Syms* symsp, const char* v__name);
    ~VSimTop___024root();
    VL_UNCOPYABLE(VSimTop___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
