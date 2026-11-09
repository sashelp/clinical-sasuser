/*===============================================================================
 * lib_memlist_err_03.sas - Negative test: TYPE= invalid value is NOT rejected
 *===============================================================================
 * Macro under test : %lib_memlist
 * Expected         : abort cancel with "has invalid value"
 * Current          : FAIL - %macro lib_memlist(...) lacks /minoperator, so the
 *                    (%qupcase(&type.) in DATA VIEW ...)=0 check is a plain
 *                    text comparison that never fires.  This test drives the
 *                    fix; once /minoperator is added it will PASS.
 *============================================================================*/

/*--- bootstrap: derive repo root from SYSIN, no absolute paths (qc_env.sas) ---*/
%let _qcboot_=%sysfunc(getoption(sysin));
%let _qcboot_=%substr(&_qcboot_.,1,%eval(%length(&_qcboot_.)-%length(%scan(&_qcboot_.,-1,%str(\)))-1));
%let _qcboot_=%substr(&_qcboot_.,1,%eval(%length(&_qcboot_.)-%length(%scan(&_qcboot_.,-1,%str(\)))-1));
%let _qcboot_=%substr(&_qcboot_.,1,%eval(%length(&_qcboot_.)-%length(%scan(&_qcboot_.,-1,%str(\)))-1));
%include "&_qcboot_.\_framework\qc_env.sas";
%let _qcboot_=;
/*----------------------------------------------------------------------------*/

%include "&_QCFW_.";
%include "&_QCDEV_LIB_.\lib_memlist.sas";
%qc_begin(prog=lib_memlist_err_03, macro=lib_memlist);
%qc_case(desc=1 TYPE= invalid value must abort);
*EXPECTED_ERROR: has invalid value;
%qc_abort_marker;
%lib_memlist(library=work,type=notatype);
%qc_unexpected_continue;
%qc_end;