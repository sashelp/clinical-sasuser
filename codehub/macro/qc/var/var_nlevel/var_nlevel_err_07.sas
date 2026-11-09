/*===============================================================================
 * var_nlevel_err_07.sas - Negative test: INCLUDEMISSING= is empty
 *===============================================================================
 * Macro under test : %var_nlevel
 * Expected         : abort cancel with "Parameter INCLUDEMISSING= has invalid
 *                    value, expecting one of: N, Y."
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
data nlerr;
  x=1;
run;
%qc_begin(prog=var_nlevel_err_07, macro=var_nlevel);
%qc_case(desc=1 empty INCLUDEMISSING= must abort);
*EXPECTED_ERROR: Parameter INCLUDEMISSING= has invalid value, expecting one of: N, Y.;
%qc_abort_marker;
%var_nlevel(data=nlerr,var=x,includemissing=);
%qc_unexpected_continue;
%qc_end;
