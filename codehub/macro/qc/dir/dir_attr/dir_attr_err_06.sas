/*===============================================================================
 * dir_attr_err_06.sas - Negative test: DIR= points to a file
 *===============================================================================
 * Macro under test : %dir_attr
 * Expected         : abort cancel with "Directory ... f1.txt not exist."
 * Note             : a regular file must not be accepted as a directory.
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
%qc_begin(prog=dir_attr_err_06, macro=dir_attr);
%qc_case(desc=1 DIR= file path must abort);
*EXPECTED_ERROR: dir_attr.sas not exist.;
%qc_abort_marker;
%dir_attr(dir=&_QCDEV_DIR_.\dir_attr.sas,attr=NMEMS);
%qc_unexpected_continue;
%qc_end;
