/*===============================================================================
 * var_attr_err_01.sas - Negative test: variable does not exist in DATA=
 *===============================================================================
 * Macro under test : %var_attr
 * Expected         : abort cancel with "Variable ... not exist."
 * Note             : propagation from %var_exist's 0 result.
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
data vae1; x=1; run;
%qc_begin(prog=var_attr_err_01, macro=var_attr);
%qc_case(desc=1 nonexistent variable must abort);
*EXPECTED_ERROR: not exist;
%qc_abort_marker;
%var_attr(data=vae1,var=zzz,attr=type);
%qc_unexpected_continue;
%qc_end;