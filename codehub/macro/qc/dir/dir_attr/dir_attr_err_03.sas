/*===============================================================================
 * dir_attr_err_03.sas - Negative test: ATTR= empty
 *===============================================================================
 * Macro under test : %dir_attr
 * Expected         : abort cancel with "Parameter ATTR= has invalid value,
 *                    expecting one of: DIRECTORY, NMEMS."
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
%include "&_QCDEV_DIR_.\dir_exist.sas";
%include "&_QCDEV_DIR_.\dir_attr.sas";
%qc_begin(prog=dir_attr_err_03, macro=dir_attr);
%qc_case(desc=1 ATTR= empty must abort);
*EXPECTED_ERROR: Parameter ATTR= has invalid value, expecting one of: DIRECTORY, NMEMS.;
%qc_abort_marker;
%dir_attr(dir=&_QCQC_.,attr=);
%qc_unexpected_continue;
%qc_end;
