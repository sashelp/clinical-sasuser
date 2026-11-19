/*===============================================================================
 * ds_attr_err_03.sas - Negative test: ATTR= empty
 *===============================================================================
 * Macro under test : %ds_attr
 * Expected         : abort cancel with "Parameter ATTR= not specified."
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
data dae3; x=1; run;
%qc_begin(prog=ds_attr_err_03, macro=ds_attr);
%qc_case(desc=1 ATTR= empty must abort);
*EXPECTED_ERROR: Parameter ATTR= not specified.;
%qc_abort_marker;
%ds_attr(data=dae3,attr=);
%qc_unexpected_continue;
%qc_end;