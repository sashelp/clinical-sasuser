/*==============================================================================
 * stat_summaryn_err_16.sas - Negative test: STATIS= contains an invalid statistic
 *==============================================================================
 * Macro under test : %stat_summaryn
 * Expected         : abort cancel with "ERROR: Invalid value of STATIS=, expecting one of the following: N, NMISS, N_NMISS, MEAN, LCLM, UCLM, CLM,"
 * Note             : the macro message is longer than the SAS log line width, so
 *                    the EXPECTED_ERROR marker carries the prefix that reliably
 *                    fits on one log line
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

%qc_begin(prog=stat_summaryn_err_16, macro=stat_summaryn);
%qc_case(desc=1 unknown statistic keyword must abort);
*EXPECTED_ERROR: ERROR: Invalid value of STATIS=, expecting one of the following: N, NMISS, N_NMISS, MEAN, LCLM, UCLM, CLM,;
%qc_abort_marker;
%stat_summaryn(data=sashelp.class, out=oerr, class=sex, var=age, statis=meanx);
%qc_unexpected_continue;
