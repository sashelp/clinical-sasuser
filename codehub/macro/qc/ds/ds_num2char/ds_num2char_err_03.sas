/*==============================================================================
 * ds_num2char_err_03.sas - Negative test: OUT= empty
 *==============================================================================
 * Macro under test : %ds_num2char
 * Expected         : abort cancel with "Parameter OUT= not specified."
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
data n2ce3; x=1; run;
%qc_begin(prog=ds_num2char_err_03, macro=ds_num2char);
%qc_case(desc=1 OUT= empty must abort);
*EXPECTED_ERROR: Parameter OUT= not specified.;
%qc_abort_marker;
%ds_num2char(data=n2ce3,out=,var=x);
%qc_unexpected_continue;
%qc_end;