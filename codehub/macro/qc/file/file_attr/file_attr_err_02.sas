/*===============================================================================
 * file_attr_err_02.sas - Negative test: FILE= does not exist
 *===============================================================================
 * Macro under test : %file_attr
 * Expected         : abort cancel with "File ... not exist"
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
%include "&_QCDEV_FILE_.\file_attr.sas";
%qc_begin(prog=file_attr_err_02, macro=file_attr);
%qc_case(desc=1 nonexistent file must abort);
*EXPECTED_ERROR: not exist;
%qc_abort_marker;
%file_attr(file=.\_external\definitely\no_such_file_xyz.txt,attr=filename);
%qc_unexpected_continue;
%qc_end;