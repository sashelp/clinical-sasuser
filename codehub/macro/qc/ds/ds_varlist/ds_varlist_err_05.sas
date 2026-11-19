/*===============================================================================
 * ds_varlist_err_05.sas - Negative test: SAS view passed as DATA=
 *===============================================================================
 * Macro under test : %ds_varlist
 * Expected         : reject view input and abort cancel ("... not exist")
 * Design note      : per the macro header (updated 2026-10-28), DATA= accepts
 *                    a DATASET only; SAS views are deliberately NOT supported.
 *                    The member check uses %sysfunc(exist()) without VIEW, so a
 *                    view is reported as "not exist" instead of returning a
 *                    misleading variable list.
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
%include "&_QCDEV_DS_.\ds_varlist.sas";
data vle5; x=1; y='a'; run;
proc sql;
  create view vle5v as select x, y from vle5;
quit;
%qc_begin(prog=ds_varlist_err_05, macro=ds_varlist);
%qc_case(desc=1 view DATA= must be rejected);
*EXPECTED_ERROR: not exist;
%qc_abort_marker;
%ds_varlist(data=vle5v);
%qc_unexpected_continue;
%qc_end;