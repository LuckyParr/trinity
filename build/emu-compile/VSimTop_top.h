// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VSimTop.h for the primary calling header

#ifndef VERILATED_VSIMTOP_TOP_H_
#define VERILATED_VSIMTOP_TOP_H_  // guard

#include "verilated.h"
class VSimTop_MemRWHelper;


class VSimTop__Syms;

class alignas(VL_CACHE_LINE_BYTES) VSimTop_top final : public VerilatedModule {
  public:
    // CELLS
    VSimTop_MemRWHelper* __PVT__mem;

    // DESIGN SPECIFIC STATE
    VL_IN8(__PVT__clk,0,0);
    VL_IN8(__PVT__rst_n,0,0);
    CData/*3:0*/ __PVT__a;
    CData/*0:0*/ __PVT__r_enable;
    CData/*0:0*/ __PVT__w_enable;
    CData/*0:0*/ __PVT__enable;
    CData/*3:0*/ __Vdly__a;
    CData/*0:0*/ __Vdly__r_enable;
    CData/*0:0*/ __Vdly__w_enable;
    VL_OUT(__PVT__opt,31,0);
    IData/*31:0*/ __PVT__b;
    IData/*31:0*/ __Vdly__b;
    QData/*63:0*/ __PVT__r_index;
    QData/*63:0*/ __PVT__r_data;
    QData/*63:0*/ __PVT__w_index;
    QData/*63:0*/ __PVT__w_data;
    QData/*63:0*/ __PVT__w_mask;
    QData/*63:0*/ __Vdly__r_index;
    QData/*63:0*/ __Vdly__w_index;
    QData/*63:0*/ __Vdly__w_data;
    QData/*63:0*/ __Vdly__w_mask;

    // INTERNAL VARIABLES
    VSimTop__Syms* const vlSymsp;

    // CONSTRUCTORS
    VSimTop_top(VSimTop__Syms* symsp, const char* v__name);
    ~VSimTop_top();
    VL_UNCOPYABLE(VSimTop_top);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
