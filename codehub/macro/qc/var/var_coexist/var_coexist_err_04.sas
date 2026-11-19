/*==============================================================================
 * var_coexist_err_04.sas - Negative test: RESULTTYPE= empty
 *==============================================================================
 * Macro under test : %var_coexist
 * Expected         : abort cancel with "Parameter RESULTTYPE= not specified."
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
data vce4; x=1; run;
%qc_begin(prog=var_coexist_err_04, macro=var_coexist);
%qc_case(desc=1 RESULTTYPE= empty must abort);
*EXPECTED_ERROR: Parameter RESULTTYPE= not specified.;
%qc_abort_marker;
%var_coexist(data=vce4,var=x,resulttype=);
%qc_unexpected_continue;
%qc_end;