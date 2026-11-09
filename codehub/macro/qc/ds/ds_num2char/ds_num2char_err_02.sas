/*==============================================================================
 * ds_num2char_err_02.sas - Negative test: dataset not exist
 *==============================================================================
 * Macro under test : %ds_num2char
 * Expected         : abort cancel with "Dataset ... not exist"
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
%qc_begin(prog=ds_num2char_err_02, macro=ds_num2char);
%qc_case(desc=1 nonexistent dataset must abort);
*EXPECTED_ERROR: not exist;
%qc_abort_marker;
%ds_num2char(data=no_such_ds_xyz,var=x);
%qc_unexpected_continue;
%qc_end;