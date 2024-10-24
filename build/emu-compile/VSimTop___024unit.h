// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VSimTop.h for the primary calling header

#ifndef VERILATED_VSIMTOP___024UNIT_H_
#define VERILATED_VSIMTOP___024UNIT_H_  // guard

#include "verilated.h"


class VSimTop__Syms;

class alignas(VL_CACHE_LINE_BYTES) VSimTop___024unit final : public VerilatedModule {
  public:

    // INTERNAL VARIABLES
    VSimTop__Syms* const vlSymsp;

    // CONSTRUCTORS
    VSimTop___024unit(VSimTop__Syms* symsp, const char* v__name);
    ~VSimTop___024unit();
    VL_UNCOPYABLE(VSimTop___024unit);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
