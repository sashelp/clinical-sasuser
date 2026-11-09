/*===============================================================================
 * lib_memlist_err_01.sas - Negative test: LIBRARY= empty
 *===============================================================================
 * Macro under test : %lib_memlist
 * Expected         : abort cancel with "not specified"
 * Note             : the message text uses DATA= (a wording bug in the macro,
 *                    asserted as-is so any change is caught).
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
%qc_begin(prog=lib_memlist_err_01, macro=lib_memlist);
%qc_case(desc=1 LIBRARY= empty must abort);
*EXPECTED_ERROR: not specified;
%qc_abort_marker;
%lib_memlist(library=);
%qc_unexpected_continue;
%qc_end;