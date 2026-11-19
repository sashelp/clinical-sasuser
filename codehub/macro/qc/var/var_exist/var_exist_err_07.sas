/*===============================================================================
 * var_exist_err_07.sas - Negative test: TYPE= empty
 *===============================================================================
 * Macro under test : %var_exist
 * Expected         : abort cancel with "Parameter TYPE= has invalid value,
 *                    expecting one of: ALL, C, N."
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
data vee7; x=1; run;
%qc_begin(prog=var_exist_err_07, macro=var_exist);
%qc_case(desc=1 empty TYPE value must abort);
*EXPECTED_ERROR: Parameter TYPE= has invalid value, expecting one of: ALL, C, N.;
%qc_abort_marker;
%var_exist(data=vee7,var=x,type=);
%qc_unexpected_continue;
%qc_end;
