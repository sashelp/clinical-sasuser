/*==============================================================================
 * ds_varlist_err_04.sas - Negative test: PATTERN= invalid regex
 *==============================================================================
 * Macro under test : %ds_varlist
 * Expected         : abort cancel with "invalid regular expression"
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
%include "&_QCDEV_DS_.\ds_varlist.sas";
data vle4; x=1; run;
%qc_begin(prog=ds_varlist_err_04, macro=ds_varlist);
%qc_case(desc=1 invalid PATTERN must abort);
*EXPECTED_ERROR: invalid regular expression;
%qc_abort_marker;
%ds_varlist(data=vle4,pattern=[);
%qc_unexpected_continue;
%qc_end;