/*==============================================================================
 * stat_countocc_err_17.sas - Negative test: DENOM= dataset has 0 observations
 *==============================================================================
 * Macro under test : %stat_countocc
 * Expected         : abort cancel with "Dataset adsl_zero has 0 observations."
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
%include "&_QCDEV_STAT_.\stat_countocc.sas";

%qc_begin(prog=stat_countocc_err_17, macro=stat_countocc);
%qc_case(desc=1 DENOM has 0 observations must abort);

data adae_ok;
  length usubjid $10 trt $3 cod $10;
  usubjid='S1'; trt='A'; cod='X'; output;
run;
data adsl_zero;
  length usubjid $10 trt $3;
  if 0;
run;
%qc_abort_marker;
*EXPECTED_ERROR: Dataset adsl_zero has 0 observations.;
%stat_countocc(data=adae_ok, denom=adsl_zero, out=z17, class=trt, code=cod);
%qc_unexpected_continue;
