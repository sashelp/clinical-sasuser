/*===============================================================================
 * ds_attr_err_04.sas - Negative test: ATTR= invalid value
 *===============================================================================
 * Macro under test : %ds_attr
 * Expected         : abort cancel with "has invalid value"
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
data dae4; x=1; run;
%qc_begin(prog=ds_attr_err_04, macro=ds_attr);
%qc_case(desc=1 ATTR= invalid value must abort);
*EXPECTED_ERROR: has invalid value;
%qc_abort_marker;
%ds_attr(data=dae4,attr=notanattr);
%qc_unexpected_continue;
%qc_end;