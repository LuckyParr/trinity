// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VSimTop.h for the primary calling header

#include "VSimTop__pch.h"
#include "VSimTop__Syms.h"
#include "VSimTop___024unit.h"

extern "C" char pte_helper(long long satp, long long vpn, long long* pte, char* level);

VL_INLINE_OPT void VSimTop___024unit____Vdpiimwrap_pte_helper_TOP____024unit(QData/*63:0*/ satp, QData/*63:0*/ vpn, QData/*63:0*/ &pte, CData/*7:0*/ &level, CData/*7:0*/ &pte_helper__Vfuncrtn) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop___024unit____Vdpiimwrap_pte_helper_TOP____024unit\n"); );
    // Body
    long long satp__Vcvt;
    for (size_t satp__Vidx = 0; satp__Vidx < 1; ++satp__Vidx) satp__Vcvt = satp;
    long long vpn__Vcvt;
    for (size_t vpn__Vidx = 0; vpn__Vidx < 1; ++vpn__Vidx) vpn__Vcvt = vpn;
    long long pte__Vcvt;
    char level__Vcvt;
    char pte_helper__Vfuncrtn__Vcvt;
    pte_helper__Vfuncrtn__Vcvt = pte_helper(satp__Vcvt, vpn__Vcvt, &pte__Vcvt, &level__Vcvt);
    pte = pte__Vcvt;
    level = (0xffU & level__Vcvt);
    pte_helper__Vfuncrtn = (0xffU & pte_helper__Vfuncrtn__Vcvt);
}

extern "C" long long amo_helper(char cmd, long long addr, long long wdata, char mask);

VL_INLINE_OPT void VSimTop___024unit____Vdpiimwrap_amo_helper_TOP____024unit(CData/*7:0*/ cmd, QData/*63:0*/ addr, QData/*63:0*/ wdata, CData/*7:0*/ mask, QData/*63:0*/ &amo_helper__Vfuncrtn) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop___024unit____Vdpiimwrap_amo_helper_TOP____024unit\n"); );
    // Body
    char cmd__Vcvt;
    for (size_t cmd__Vidx = 0; cmd__Vidx < 1; ++cmd__Vidx) cmd__Vcvt = cmd;
    long long addr__Vcvt;
    for (size_t addr__Vidx = 0; addr__Vidx < 1; ++addr__Vidx) addr__Vcvt = addr;
    long long wdata__Vcvt;
    for (size_t wdata__Vidx = 0; wdata__Vidx < 1; ++wdata__Vidx) wdata__Vcvt = wdata;
    char mask__Vcvt;
    for (size_t mask__Vidx = 0; mask__Vidx < 1; ++mask__Vidx) mask__Vcvt = mask;
    long long amo_helper__Vfuncrtn__Vcvt;
    amo_helper__Vfuncrtn__Vcvt = amo_helper(cmd__Vcvt, addr__Vcvt, wdata__Vcvt, mask__Vcvt);
    amo_helper__Vfuncrtn = amo_helper__Vfuncrtn__Vcvt;
}

extern "C" void xs_assert(long long line);

VL_INLINE_OPT void VSimTop___024unit____Vdpiimwrap_xs_assert_TOP____024unit(QData/*63:0*/ line) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop___024unit____Vdpiimwrap_xs_assert_TOP____024unit\n"); );
    // Body
    long long line__Vcvt;
    for (size_t line__Vidx = 0; line__Vidx < 1; ++line__Vidx) line__Vcvt = line;
    xs_assert(line__Vcvt);
}

extern "C" void xs_assert_v2(const char* filename, long long line);

VL_INLINE_OPT void VSimTop___024unit____Vdpiimwrap_xs_assert_v2_TOP____024unit(std::string filename, QData/*63:0*/ line) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop___024unit____Vdpiimwrap_xs_assert_v2_TOP____024unit\n"); );
    // Body
    const char* filename__Vcvt;
    for (size_t filename__Vidx = 0; filename__Vidx < 1; ++filename__Vidx) filename__Vcvt = filename.c_str();
    long long line__Vcvt;
    for (size_t line__Vidx = 0; line__Vidx < 1; ++line__Vidx) line__Vcvt = line;
    xs_assert_v2(filename__Vcvt, line__Vcvt);
}

extern "C" int jtag_tick(svBit* jtag_TCK, svBit* jtag_TMS, svBit* jtag_TDI, svBit* jtag_TRSTn, svBit jtag_TDO);

VL_INLINE_OPT void VSimTop___024unit____Vdpiimwrap_jtag_tick_TOP____024unit(CData/*0:0*/ &jtag_TCK, CData/*0:0*/ &jtag_TMS, CData/*0:0*/ &jtag_TDI, CData/*0:0*/ &jtag_TRSTn, CData/*0:0*/ jtag_TDO, IData/*31:0*/ &jtag_tick__Vfuncrtn) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop___024unit____Vdpiimwrap_jtag_tick_TOP____024unit\n"); );
    // Body
    svBit jtag_TCK__Vcvt;
    svBit jtag_TMS__Vcvt;
    svBit jtag_TDI__Vcvt;
    svBit jtag_TRSTn__Vcvt;
    svBit jtag_TDO__Vcvt;
    for (size_t jtag_TDO__Vidx = 0; jtag_TDO__Vidx < 1; ++jtag_TDO__Vidx) jtag_TDO__Vcvt = jtag_TDO;
    int jtag_tick__Vfuncrtn__Vcvt;
    jtag_tick__Vfuncrtn__Vcvt = jtag_tick(&jtag_TCK__Vcvt, &jtag_TMS__Vcvt, &jtag_TDI__Vcvt, &jtag_TRSTn__Vcvt, jtag_TDO__Vcvt);
    jtag_TCK = (1U & VL_BITSEL_IIII(32, jtag_TCK__Vcvt, 0U));
    jtag_TMS = (1U & VL_BITSEL_IIII(32, jtag_TMS__Vcvt, 0U));
    jtag_TDI = (1U & VL_BITSEL_IIII(32, jtag_TDI__Vcvt, 0U));
    jtag_TRSTn = (1U & VL_BITSEL_IIII(32, jtag_TRSTn__Vcvt, 0U));
    jtag_tick__Vfuncrtn = jtag_tick__Vfuncrtn__Vcvt;
}

extern "C" long long difftest_ram_read(long long rIdx);

VL_INLINE_OPT void VSimTop___024unit____Vdpiimwrap_difftest_ram_read_TOP____024unit(QData/*63:0*/ rIdx, QData/*63:0*/ &difftest_ram_read__Vfuncrtn) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop___024unit____Vdpiimwrap_difftest_ram_read_TOP____024unit\n"); );
    // Body
    long long rIdx__Vcvt;
    for (size_t rIdx__Vidx = 0; rIdx__Vidx < 1; ++rIdx__Vidx) rIdx__Vcvt = rIdx;
    long long difftest_ram_read__Vfuncrtn__Vcvt;
    difftest_ram_read__Vfuncrtn__Vcvt = difftest_ram_read(rIdx__Vcvt);
    difftest_ram_read__Vfuncrtn = difftest_ram_read__Vfuncrtn__Vcvt;
}

extern "C" void difftest_ram_write(long long index, long long data, long long mask);

VL_INLINE_OPT void VSimTop___024unit____Vdpiimwrap_difftest_ram_write_TOP____024unit(QData/*63:0*/ index, QData/*63:0*/ data, QData/*63:0*/ mask) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VSimTop___024unit____Vdpiimwrap_difftest_ram_write_TOP____024unit\n"); );
    // Body
    long long index__Vcvt;
    for (size_t index__Vidx = 0; index__Vidx < 1; ++index__Vidx) index__Vcvt = index;
    long long data__Vcvt;
    for (size_t data__Vidx = 0; data__Vidx < 1; ++data__Vidx) data__Vcvt = data;
    long long mask__Vcvt;
    for (size_t mask__Vidx = 0; mask__Vidx < 1; ++mask__Vidx) mask__Vcvt = mask;
    difftest_ram_write(index__Vcvt, data__Vcvt, mask__Vcvt);
}
