/*===============================================================================
 * lib_zipvarlen_err_01.sas - Negative test: LIBRARY= empty
 *===============================================================================
 * Macro under test : %lib_zipvarlen
 * Expected         : abort cancel with "Parameter LIBRARY= not specified."
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
%include "&_QCDEV_DS_.\ds_attr.sas";
%include "&_QCDEV_DS_.\ds_varlist.sas";
%include "&_QCDEV_DS_.\ds_zipvarlen.sas";
%include "&_QCDEV_LIB_.\lib_zipvarlen.sas";
%qc_begin(prog=lib_zipvarlen_err_01, macro=lib_zipvarlen);
%qc_case(desc=1 LIBRARY= empty must abort);
*EXPECTED_ERROR: Parameter LIBRARY= not specified.;
%qc_abort_marker;
%lib_zipvarlen(library=);
%qc_unexpected_continue;
%qc_end;