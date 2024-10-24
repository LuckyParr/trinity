// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VSimTop.h for the primary calling header

#ifndef VERILATED_VSIMTOP_MEMRWHELPER_H_
#define VERILATED_VSIMTOP_MEMRWHELPER_H_  // guard

#include "verilated.h"


class VSimTop__Syms;

class alignas(VL_CACHE_LINE_BYTES) VSimTop_MemRWHelper final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(__PVT__clock,0,0);
    VL_IN8(__PVT__r_enable,0,0);
    VL_IN8(__PVT__w_enable,0,0);
    VL_IN8(__PVT__enable,0,0);
    VL_IN64(__PVT__r_index,63,0);
    VL_OUT64(__PVT__r_data,63,0);
    VL_IN64(__PVT__w_index,63,0);
    VL_IN64(__PVT__w_data,63,0);
    VL_IN64(__PVT__w_mask,63,0);
    QData/*63:0*/ __Vfunc_difftest_ram_read__0__Vfuncout;
    QData/*63:0*/ __Vdly__r_data;

    // INTERNAL VARIABLES
    VSimTop__Syms* const vlSymsp;

    // CONSTRUCTORS
    VSimTop_MemRWHelper(VSimTop__Syms* symsp, const char* v__name);
    ~VSimTop_MemRWHelper();
    VL_UNCOPYABLE(VSimTop_MemRWHelper);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
