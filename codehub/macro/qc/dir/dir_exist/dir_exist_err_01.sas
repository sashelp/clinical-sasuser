/*===============================================================================
 * dir_exist_err_01.sas - Negative test: DIR= empty
 *===============================================================================
 * Macro under test : %dir_exist
 * Expected         : abort cancel with "Parameter DIR= not specified."
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
%qc_begin(prog=dir_exist_err_01, macro=dir_exist);
%qc_case(desc=1 DIR= empty must abort);
*EXPECTED_ERROR: Parameter DIR= not specified.;
%qc_abort_marker;
%dir_exist(dir=);
%qc_unexpected_continue;
%qc_end;
