/*===============================================================================
 * var_exist_err_04.sas - Negative test: invalid variable name
 *===============================================================================
 * Expected : abort cancel with "is invalid variable name"
 * Note     : %sysfunc(nvalid()) rejects names such as "1abc".
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
data vee4; x=1; run;
%qc_begin(prog=var_exist_err_04, macro=var_exist);
%qc_case(desc=1 invalid var name must abort);
*EXPECTED_ERROR: is invalid variable name;
%qc_abort_marker;
%var_exist(data=vee4,var=1abc);
%qc_unexpected_continue;
%qc_end;