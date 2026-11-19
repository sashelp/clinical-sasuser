/*===============================================================================
 * var_attr_err_04.sas - Negative test: DATA= dataset does not exist
 *===============================================================================
 * Macro under test : %var_attr
 * Expected         : abort cancel with "Dataset ... not exist."
 * Note             : the missing-DATA= error is propagated from %var_exist.
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
%include "&_QCDEV_VAR_.\var_attr.sas";
%qc_begin(prog=var_attr_err_04, macro=var_attr);
%qc_case(desc=1 nonexistent dataset must abort);
*EXPECTED_ERROR: Dataset not exist;
%qc_abort_marker;
%var_attr(data=no_such_ds_abc,var=x,attr=type);
%qc_unexpected_continue;
%qc_end;