/*===============================================================================
 * dir_memlist_err_02.sas - Negative test: DIR= does not exist
 *===============================================================================
 * Macro under test : %dir_memlist
 * Expected         : abort cancel with "Directory ... no_such_dir_xyz not exist."
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
%include "&_QCDEV_DIR_.\dir_memlist.sas";
%qc_begin(prog=dir_memlist_err_02, macro=dir_memlist);
%qc_case(desc=1 missing DIR= must abort);
*EXPECTED_ERROR: no_such_dir_xyz not exist.;
%qc_abort_marker;
%dir_memlist(dir=&_QCQC_.\no_such_dir_xyz);
%qc_unexpected_continue;
%qc_end;
