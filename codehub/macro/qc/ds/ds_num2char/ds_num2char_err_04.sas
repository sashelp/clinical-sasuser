/*==============================================================================
 * ds_num2char_err_04.sas - Negative test: VAR= empty
 *==============================================================================
 * Macro under test : %ds_num2char
 * Expected         : abort cancel. %var_coexist(data=,var=) is invoked inside
 *                    and detects "Parameter VAR= not specified."
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
%include "&_QCDEV_DS_.\ds_varlist.sas";
%include "&_QCDEV_DS_.\ds_num2char.sas";
data n2ce4; x=1; run;
%qc_begin(prog=ds_num2char_err_04, macro=ds_num2char);
%qc_case(desc=1 VAR= empty must abort);
*EXPECTED_ERROR: Parameter VAR= not specified.;
%qc_abort_marker;
%ds_num2char(data=n2ce4,out=n2ce4o,var=);
%qc_unexpected_continue;
%qc_end;