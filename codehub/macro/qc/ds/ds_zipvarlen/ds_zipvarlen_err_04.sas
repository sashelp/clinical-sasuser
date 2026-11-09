/*===============================================================================
 * ds_zipvarlen_err_04.sas - Negative test: DELINFMT= invalid value
 *===============================================================================
 * Macro under test : %ds_zipvarlen
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
%include "&_QCDEV_DS_.\ds_varlist.sas";
%include "&_QCDEV_DS_.\ds_zipvarlen.sas";
data zve4; c='x'; run;
%qc_begin(prog=ds_zipvarlen_err_04, macro=ds_zipvarlen);
%qc_case(desc=1 DELINFMT= invalid value must abort);
*EXPECTED_ERROR: has invalid value;
%qc_abort_marker;
%ds_zipvarlen(data=zve4,delinfmt=x);
%qc_unexpected_continue;
%qc_end;