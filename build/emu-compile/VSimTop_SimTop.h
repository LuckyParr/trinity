// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VSimTop.h for the primary calling header

#ifndef VERILATED_VSIMTOP_SIMTOP_H_
#define VERILATED_VSIMTOP_SIMTOP_H_  // guard

#include "verilated.h"
class VSimTop_DifftestTrapEvent;
class VSimTop_top;


class VSimTop__Syms;

class alignas(VL_CACHE_LINE_BYTES) VSimTop_SimTop final : public VerilatedModule {
  public:
    // CELLS
    VSimTop_top* __PVT__u_top;
    VSimTop_DifftestTrapEvent* __PVT__u_DifftestTrapEvent;

    // DESIGN SPECIFIC STATE
    VL_IN8(clock,0,0);
    VL_IN8(reset,0,0);
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
    CData/*0:0*/ __Vcellinp__u_top__rst_n;
    QData/*63:0*/ __PVT__cnt;
    QData/*63:0*/ __Vdly__cnt;

    // INTERNAL VARIABLES
    VSimTop__Syms* const vlSymsp;

    // CONSTRUCTORS
    VSimTop_SimTop(VSimTop__Syms* symsp, const char* v__name);
    ~VSimTop_SimTop();
    VL_UNCOPYABLE(VSimTop_SimTop);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
