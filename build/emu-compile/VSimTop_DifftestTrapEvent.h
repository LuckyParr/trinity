// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VSimTop.h for the primary calling header

#ifndef VERILATED_VSIMTOP_DIFFTESTTRAPEVENT_H_
#define VERILATED_VSIMTOP_DIFFTESTTRAPEVENT_H_  // guard

#include "verilated.h"


class VSimTop__Syms;

class alignas(VL_CACHE_LINE_BYTES) VSimTop_DifftestTrapEvent final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(__PVT__clock,0,0);
    VL_IN8(__PVT__enable,0,0);
    VL_IN8(__PVT__io_hasTrap,0,0);
    VL_IN8(__PVT__io_hasWFI,0,0);
    VL_IN8(__PVT__io_coreid,7,0);
    VL_IN(__PVT__io_code,31,0);
    VL_IN64(__PVT__io_cycleCnt,63,0);
    VL_IN64(__PVT__io_instrCnt,63,0);
    VL_IN64(__PVT__io_pc,63,0);

    // INTERNAL VARIABLES
    VSimTop__Syms* const vlSymsp;

    // CONSTRUCTORS
    VSimTop_DifftestTrapEvent(VSimTop__Syms* symsp, const char* v__name);
    ~VSimTop_DifftestTrapEvent();
    VL_UNCOPYABLE(VSimTop_DifftestTrapEvent);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
