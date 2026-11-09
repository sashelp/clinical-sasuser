/*==============================================================================
 * stat_summaryn_err_07.sas - Negative test: MAXDEC= out of range
 *==============================================================================
 * Macro under test : %stat_summaryn
 * Expected         : abort cancel with "ERROR: Invalid value of MAXDEC=, expecting an integer between 0 and 9."
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
%include "&_QCDEV_VAR_.\var_exist.sas";
%include "&_QCDEV_VAR_.\var_coexist.sas";
%include "&_QCDEV_DS_.\ds_attr.sas";
%include "&_QCDEV_STAT_.\stat_summaryn.sas";

%qc_begin(prog=stat_summaryn_err_07, macro=stat_summaryn);
%qc_case(desc=1 two digit maxdec must abort);
*EXPECTED_ERROR: ERROR: Invalid value of MAXDEC=, expecting an integer between 0 and 9.;
%qc_abort_marker;
%stat_summaryn(data=sashelp.class, out=oerr, class=sex, var=age, maxdec=10);
%qc_unexpected_continue;
