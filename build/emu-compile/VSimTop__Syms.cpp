// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "VSimTop__pch.h"
#include "VSimTop.h"
#include "VSimTop___024root.h"
#include "VSimTop_SimTop.h"
#include "VSimTop___024unit.h"
#include "VSimTop_top.h"
#include "VSimTop_DifftestTrapEvent.h"
#include "VSimTop_MemRWHelper.h"

// FUNCTIONS
VSimTop__Syms::~VSimTop__Syms()
{
}

VSimTop__Syms::VSimTop__Syms(VerilatedContext* contextp, const char* namep, VSimTop* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
    , TOP__SimTop{this, Verilated::catName(namep, "SimTop")}
    , TOP__SimTop__u_DifftestTrapEvent{this, Verilated::catName(namep, "SimTop.u_DifftestTrapEvent")}
    , TOP__SimTop__u_top{this, Verilated::catName(namep, "SimTop.u_top")}
    , TOP__SimTop__u_top__mem{this, Verilated::catName(namep, "SimTop.u_top.mem")}
    , TOP____024unit{this, Verilated::catName(namep, "$unit")}
{
        // Check resources
        Verilated::stackCheck(284);
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-12);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    TOP.__PVT__SimTop = &TOP__SimTop;
    TOP__SimTop.__PVT__u_DifftestTrapEvent = &TOP__SimTop__u_DifftestTrapEvent;
    TOP__SimTop.__PVT__u_top = &TOP__SimTop__u_top;
    TOP__SimTop__u_top.__PVT__mem = &TOP__SimTop__u_top__mem;
    TOP.__PVT____024unit = &TOP____024unit;
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    TOP__SimTop.__Vconfigure(true);
    TOP__SimTop__u_DifftestTrapEvent.__Vconfigure(true);
    TOP__SimTop__u_top.__Vconfigure(true);
    TOP__SimTop__u_top__mem.__Vconfigure(true);
    TOP____024unit.__Vconfigure(true);
    // Setup export functions
    for (int __Vfinal = 0; __Vfinal < 2; ++__Vfinal) {
    }
}
