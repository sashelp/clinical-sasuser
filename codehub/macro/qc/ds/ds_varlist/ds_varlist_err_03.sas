/*==============================================================================
 * ds_varlist_err_03.sas - Negative test: TYPE= invalid value
 *==============================================================================
 * Macro under test : %ds_varlist
 * Expected         : abort cancel with "invalid value, expecting one of: C, N."
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
data vle3; x=1; run;
%qc_begin(prog=ds_varlist_err_03, macro=ds_varlist);
%qc_case(desc=1 TYPE= invalid must abort);
*EXPECTED_ERROR: invalid value;
%qc_abort_marker;
%ds_varlist(data=vle3,type=z);
%qc_unexpected_continue;
%qc_end;