/*===============================================================================
 * var_attr_err_02.sas - Negative test: ATTR= empty
 *===============================================================================
 * Macro under test : %var_attr
 * Expected         : abort cancel with "Parameter ATTR= not specified."
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
data vae2; x=1; run;
%qc_begin(prog=var_attr_err_02, macro=var_attr);
%qc_case(desc=1 ATTR= empty must abort);
*EXPECTED_ERROR: Parameter ATTR= not specified.;
%qc_abort_marker;
%var_attr(data=vae2,var=x,attr=);
%qc_unexpected_continue;
%qc_end;