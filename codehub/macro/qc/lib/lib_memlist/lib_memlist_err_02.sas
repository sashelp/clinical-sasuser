/*===============================================================================
 * lib_memlist_err_02.sas - Negative test: library does not exist
 *===============================================================================
 * Macro under test : %lib_memlist
 * Expected         : abort cancel with "Library ... not exist"
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
%qc_begin(prog=lib_memlist_err_02, macro=lib_memlist);
%qc_case(desc=1 unassigned library must abort);
*EXPECTED_ERROR: not exist;
%qc_abort_marker;
%lib_memlist(library=nolib_xyz);
%qc_unexpected_continue;
%qc_end;