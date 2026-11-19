/*==============================================================================
 * stat_summaryc_err_03.sas - Negative test: DATA= dataset has 0 observations
 *==============================================================================
 * Macro under test : %stat_summaryc
 * Expected         : abort cancel with "ERROR: Dataset sc_zero has 0 observations."
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

%qc_begin(prog=stat_summaryc_err_03, macro=stat_summaryc);
%qc_case(desc=1 zero observation input must abort);
data sc_zero;
  length trt $1 sex $1;
  stop;
run;
*EXPECTED_ERROR: ERROR: Dataset sc_zero has 0 observations.;
%qc_abort_marker;
%stat_summaryc(data=sc_zero, out=oerr, class=trt, var=sex);
%qc_unexpected_continue;
