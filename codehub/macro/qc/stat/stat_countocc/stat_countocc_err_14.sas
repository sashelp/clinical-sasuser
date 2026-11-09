/*==============================================================================
 * stat_countocc_err_14.sas - Negative test: TEST= empty
 *==============================================================================
 * Macro under test : %stat_countocc
 * Expected         : abort cancel with "Parameter TEST= not specified."
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
%include "&_QCDEV_STAT_.\stat_countocc.sas";

%qc_begin(prog=stat_countocc_err_14, macro=stat_countocc);
%qc_case(desc=1 TEST empty must abort);
data adae;
  length usubjid $10 trt $3 cod $10;
  usubjid='S1'; trt='A'; cod='X';
run;
data adsl;
  length usubjid $10 trt $3;
  usubjid='S1'; trt='A';
run;
%qc_abort_marker;
*EXPECTED_ERROR: Parameter TEST= not specified.;
%stat_countocc(data=adae, denom=adsl, out=x, class=trt, code=cod, test=);
%qc_unexpected_continue;
