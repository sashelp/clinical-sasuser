/*===============================================================================
 * lib_memlist_err_04.sas - Negative test: PATTERN= invalid regular expression
 *===============================================================================
 * Macro under test : %lib_memlist
 * Expected         : abort cancel with "invalid regular expression"
 * Note             : TYPE= is intentionally left empty so that the PATTERN
 *                    validation branch is actually reached (see
 *                    lib_memlist_bug_typepattern.sas for the TYPE+PATTERN bug).
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
%include "&_QCDEV_LIB_.\lib_memlist.sas";
%qc_begin(prog=lib_memlist_err_04, macro=lib_memlist);
%qc_case(desc=1 PATTERN= invalid regex must abort);
*EXPECTED_ERROR: invalid regular expression;
%qc_abort_marker;
%let _badpat=%nrstr(/[a-/);
%lib_memlist(library=work,pattern=%superq(_badpat));
%qc_unexpected_continue;
%qc_end;