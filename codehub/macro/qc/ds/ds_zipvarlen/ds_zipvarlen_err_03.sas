/*===============================================================================
 * ds_zipvarlen_err_03.sas - Negative test: DELFMT= invalid value
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
data zve3; c='x'; run;
%qc_begin(prog=ds_zipvarlen_err_03, macro=ds_zipvarlen);
%qc_case(desc=1 DELFMT= invalid value must abort);
*EXPECTED_ERROR: has invalid value;
%qc_abort_marker;
%ds_zipvarlen(data=zve3,delfmt=x);
%qc_unexpected_continue;
%qc_end;