// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop__Syms.h"
#include "VSimTop_top.h"

void VSimTop_top___ctor_var_reset(VSimTop_top* vlSelf);

VSimTop_top::VSimTop_top(VSimTop__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    VSimTop_top___ctor_var_reset(this);
}

void VSimTop_top::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

VSimTop_top::~VSimTop_top() {
}
