/*==============================================================================
 * stat_summaryc_err_17.sas - Negative test: BY= variable does not exist
 *==============================================================================
 * Macro under test : %stat_summaryc
 * Expected         : abort cancel with "ERROR: At least one variable in parameter BY= not exist."
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
%include "&_QCDEV_STAT_.\stat_summaryc.sas";

%qc_begin(prog=stat_summaryc_err_17, macro=stat_summaryc);
%qc_case(desc=1 missing by variable must abort);
data sc_ok;
  length trt $1 sex $1;
  input trt $ sex $;
  datalines;
A F
A M
B F
B M
;
run;
*EXPECTED_ERROR: ERROR: At least one variable in parameter BY= not exist.;
%qc_abort_marker;
%stat_summaryc(data=sc_ok, out=oerr, by=nobyvar, class=trt, var=sex);
%qc_unexpected_continue;
