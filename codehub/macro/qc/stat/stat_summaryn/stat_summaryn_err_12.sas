/*==============================================================================
 * stat_summaryn_err_12.sas - Negative test: SHOWDENOM= invalid value
 *==============================================================================
 * Macro under test : %stat_summaryn
 * Expected         : abort cancel with "ERROR: Invalid value of SHOWDENOM=, expecting one of the following: Y, N."
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

%qc_begin(prog=stat_summaryn_err_12, macro=stat_summaryn);
%qc_case(desc=1 invalid showdenom value must abort);
*EXPECTED_ERROR: ERROR: Invalid value of SHOWDENOM=, expecting one of the following: Y, N.;
%qc_abort_marker;
%stat_summaryn(data=sashelp.class, out=oerr, class=sex, var=age, showdenom=YES);
%qc_unexpected_continue;
