// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop_SimTop.h"
#include "VSimTop__Syms.h"

void VSimTop_SimTop___ctor_var_reset(VSimTop_SimTop* vlSelf);

VSimTop_SimTop::VSimTop_SimTop(VSimTop__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    VSimTop_SimTop___ctor_var_reset(this);
}

void VSimTop_SimTop::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

VSimTop_SimTop::~VSimTop_SimTop() {
}
