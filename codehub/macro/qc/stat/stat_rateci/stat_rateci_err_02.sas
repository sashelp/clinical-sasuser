/*==============================================================================
 * stat_rateci_err_02.sas - Negative test: DATA= dataset not exist
 *==============================================================================
 * Macro under test : %stat_rateci
 * Expected         : abort cancel with "Dataset nosuch not exist."
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
%include "&_QCDEV_STAT_.\stat_rateci.sas";

%qc_begin(prog=stat_rateci_err_02, macro=stat_rateci);
%qc_case(desc=1 DATA dataset not exist must abort);
*EXPECTED_ERROR: Dataset nosuch not exist.;
%qc_abort_marker;
%stat_rateci(data=nosuch, out=x, by=study, class=trt, var=resp, level=%str('Y'));
%qc_unexpected_continue;
