/*==============================================================================
 * var_coexist_err_05.sas - Negative test: RESULTTYPE= invalid value
 *==============================================================================
 * Macro under test : %var_coexist
 * Expected         : abort cancel with "invalid value, expecting one of"
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
data vce5; x=1; run;
%qc_begin(prog=var_coexist_err_05, macro=var_coexist);
%qc_case(desc=1 RESULTTYPE= invalid value must abort);
*EXPECTED_ERROR: invalid value;
%qc_abort_marker;
%var_coexist(data=vce5,var=x,resulttype=attack);
%qc_unexpected_continue;
%qc_end;