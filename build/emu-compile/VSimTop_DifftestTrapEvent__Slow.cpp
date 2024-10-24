// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop_DifftestTrapEvent.h"
#include "VSimTop__Syms.h"

void VSimTop_DifftestTrapEvent___ctor_var_reset(VSimTop_DifftestTrapEvent* vlSelf);

VSimTop_DifftestTrapEvent::VSimTop_DifftestTrapEvent(VSimTop__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    VSimTop_DifftestTrapEvent___ctor_var_reset(this);
}

void VSimTop_DifftestTrapEvent::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

VSimTop_DifftestTrapEvent::~VSimTop_DifftestTrapEvent() {
}
