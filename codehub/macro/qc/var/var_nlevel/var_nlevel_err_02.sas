/*===============================================================================
 * var_nlevel_err_02.sas - Negative test: DATA= does not exist
 *===============================================================================
 * Macro under test : %var_nlevel
 * Expected         : abort cancel with "Dataset no_such_ds not exist."
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
%qc_begin(prog=var_nlevel_err_02, macro=var_nlevel);
%qc_case(desc=1 DATA= not exist must abort);
*EXPECTED_ERROR: Dataset no_such_ds not exist.;
%qc_abort_marker;
%var_nlevel(data=no_such_ds,var=x);
%qc_unexpected_continue;
%qc_end;
