/*===============================================================================
 * ds_zipvarlen_err_02.sas - Negative test: DATA= dataset does not exist
 *===============================================================================
 * Macro under test : %ds_zipvarlen
 * Expected         : abort cancel with "Dataset ... not exist"
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
%qc_begin(prog=ds_zipvarlen_err_02, macro=ds_zipvarlen);
%qc_case(desc=1 nonexistent dataset must abort);
*EXPECTED_ERROR: not exist;
%qc_abort_marker;
%ds_zipvarlen(data=no_such_ds_xyz);
%qc_unexpected_continue;
%qc_end;