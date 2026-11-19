/*==============================================================================
 * stat_summaryn_err_15.sas - Negative test: input dataset has 0 observations
 *==============================================================================
 * Macro under test : %stat_summaryn
 * Expected         : abort cancel with "ERROR: Dataset SN_EMPTY has 0 observations."
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

data sn_empty;
  x=1;
  if 0 then output;
run;

%qc_begin(prog=stat_summaryn_err_15, macro=stat_summaryn);
%qc_case(desc=1 zero observation dataset must abort);
*EXPECTED_ERROR: ERROR: Dataset SN_EMPTY has 0 observations.;
%qc_abort_marker;
%stat_summaryn(data=sn_empty, out=oerr, var=x);
%qc_unexpected_continue;
