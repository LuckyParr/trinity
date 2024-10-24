// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "VSimTop__pch.h"
#include "verilated_vcd_c.h"

//============================================================
// Constructors

VSimTop::VSimTop(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new VSimTop__Syms(contextp(), _vcname__, this)}
    , reset{vlSymsp->TOP.reset}
    , clock{vlSymsp->TOP.clock}
    , difftest_logCtrl_begin{vlSymsp->TOP.difftest_logCtrl_begin}
    , difftest_logCtrl_end{vlSymsp->TOP.difftest_logCtrl_end}
    , difftest_uart_out_valid{vlSymsp->TOP.difftest_uart_out_valid}
    , difftest_uart_out_ch{vlSymsp->TOP.difftest_uart_out_ch}
    , difftest_uart_in_valid{vlSymsp->TOP.difftest_uart_in_valid}
    , difftest_uart_in_ch{vlSymsp->TOP.difftest_uart_in_ch}
    , difftest_perfCtrl_clean{vlSymsp->TOP.difftest_perfCtrl_clean}
    , difftest_perfCtrl_dump{vlSymsp->TOP.difftest_perfCtrl_dump}
    , difftest_exit{vlSymsp->TOP.difftest_exit}
    , difftest_step{vlSymsp->TOP.difftest_step}
    , __PVT__SimTop{vlSymsp->TOP.__PVT__SimTop}
    , __PVT____024unit{vlSymsp->TOP.__PVT____024unit}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
    contextp()->traceBaseModelCbAdd(
        [this](VerilatedTraceBaseC* tfp, int levels, int options) { traceBaseModel(tfp, levels, options); });
}

VSimTop::VSimTop(const char* _vcname__)
    : VSimTop(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

VSimTop::~VSimTop() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void VSimTop___024root___eval_debug_assertions(VSimTop___024root* vlSelf);
#endif  // VL_DEBUG
void VSimTop___024root___eval_static(VSimTop___024root* vlSelf);
void VSimTop___024root___eval_initial(VSimTop___024root* vlSelf);
void VSimTop___024root___eval_settle(VSimTop___024root* vlSelf);
void VSimTop___024root___eval(VSimTop___024root* vlSelf);

void VSimTop::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate VSimTop::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    VSimTop___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_activity = true;
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        VSimTop___024root___eval_static(&(vlSymsp->TOP));
        VSimTop___024root___eval_initial(&(vlSymsp->TOP));
        VSimTop___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    VSimTop___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool VSimTop::eventsPending() { return false; }

uint64_t VSimTop::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* VSimTop::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void VSimTop___024root___eval_final(VSimTop___024root* vlSelf);

VL_ATTR_COLD void VSimTop::final() {
    VSimTop___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* VSimTop::hierName() const { return vlSymsp->name(); }
const char* VSimTop::modelName() const { return "VSimTop"; }
unsigned VSimTop::threads() const { return 1; }
void VSimTop::prepareClone() const { contextp()->prepareClone(); }
void VSimTop::atClone() const {
    contextp()->threadPoolpOnClone();
}
std::unique_ptr<VerilatedTraceConfig> VSimTop::traceConfig() const {
    return std::unique_ptr<VerilatedTraceConfig>{new VerilatedTraceConfig{false, false, false}};
};

//============================================================
// Trace configuration

void VSimTop___024root__trace_decl_types(VerilatedVcd* tracep);

void VSimTop___024root__trace_init_top(VSimTop___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD static void trace_init(void* voidSelf, VerilatedVcd* tracep, uint32_t code) {
    // Callback from tracep->open()
    VSimTop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<VSimTop___024root*>(voidSelf);
    VSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (!vlSymsp->_vm_contextp__->calcUnusedSigs()) {
        VL_FATAL_MT(__FILE__, __LINE__, __FILE__,
            "Turning on wave traces requires Verilated::traceEverOn(true) call before time 0.");
    }
    vlSymsp->__Vm_baseCode = code;
    tracep->pushPrefix(std::string{vlSymsp->name()}, VerilatedTracePrefixType::SCOPE_MODULE);
    VSimTop___024root__trace_decl_types(tracep);
    VSimTop___024root__trace_init_top(vlSelf, tracep);
    tracep->popPrefix();
}

VL_ATTR_COLD void VSimTop___024root__trace_register(VSimTop___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD void VSimTop::traceBaseModel(VerilatedTraceBaseC* tfp, int levels, int options) {
    (void)levels; (void)options;
    VerilatedVcdC* const stfp = dynamic_cast<VerilatedVcdC*>(tfp);
    if (VL_UNLIKELY(!stfp)) {
        vl_fatal(__FILE__, __LINE__, __FILE__,"'VSimTop::trace()' called on non-VerilatedVcdC object;"
            " use --trace-fst with VerilatedFst object, and --trace with VerilatedVcd object");
    }
    stfp->spTrace()->addModel(this);
    stfp->spTrace()->addInitCb(&trace_init, &(vlSymsp->TOP));
    VSimTop___024root__trace_register(&(vlSymsp->TOP), stfp->spTrace());
}
