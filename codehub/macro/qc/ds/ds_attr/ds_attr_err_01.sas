/*===============================================================================
 * ds_attr_err_01.sas - Negative test: DATA= empty
 *===============================================================================
 * Macro under test : %ds_attr
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
%include "&_QCDEV_DS_.\ds_attr.sas";
%qc_begin(prog=ds_attr_err_01, macro=ds_attr);
%qc_case(desc=1 DATA= empty must abort);
*EXPECTED_ERROR: Parameter DATA= not specified.;
%qc_abort_marker;
%ds_attr(data=,attr=nobs);
%qc_unexpected_continue;
%qc_end;