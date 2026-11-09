/*===============================================================================
 * var_exist_err_03.sas - Negative test: VAR= empty
 *===============================================================================
 * Expected : abort cancel with "Parameter VAR= not specified."
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
data vee3; x=1; run;
%qc_begin(prog=var_exist_err_03, macro=var_exist);
%qc_case(desc=1 VAR= empty must abort);
*EXPECTED_ERROR: Parameter VAR= not specified.;
%qc_abort_marker;
%var_exist(data=vee3,var=);
%qc_unexpected_continue;
%qc_end;