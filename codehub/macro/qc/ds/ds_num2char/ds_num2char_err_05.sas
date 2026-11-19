/*==============================================================================
 * ds_num2char_err_05.sas - Negative test: VAR= points to a character variable
 *==============================================================================
 * Macro under test : %ds_num2char
 * Expected         : abort cancel with "Variable ... is not numeric."
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
%include "&_QCDEV_VAR_.\var_coexist.sas";
%include "&_QCDEV_DS_.\ds_varlist.sas";
%include "&_QCDEV_DS_.\ds_num2char.sas";
data n2ce5; x=1; c1='abc'; run;
%qc_begin(prog=ds_num2char_err_05, macro=ds_num2char);
%qc_case(desc=1 char var in VAR= must abort);
*EXPECTED_ERROR: is not numeric;
%qc_abort_marker;
%ds_num2char(data=n2ce5,out=n2ce5o,var=c1);
%qc_unexpected_continue;
%qc_end;