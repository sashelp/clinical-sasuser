/*===============================================================================
 * var_nlevel_err_01.sas - Negative test: DATA= empty
 *===============================================================================
 * Macro under test : %var_nlevel
 * Expected         : abort cancel with "Parameter DATA= not specified."
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
%include "&_QCDEV_VAR_.\var_nlevel.sas";
%qc_begin(prog=var_nlevel_err_01, macro=var_nlevel);
%qc_case(desc=1 DATA= empty must abort);
*EXPECTED_ERROR: Parameter DATA= not specified.;
%qc_abort_marker;
%var_nlevel(data=,var=x);
%qc_unexpected_continue;
%qc_end;
