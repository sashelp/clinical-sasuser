/*===============================================================================
 * ds_num2char_err_08.sas - Negative test: SAS view passed as DATA=
 *===============================================================================
 * Macro under test : %ds_num2char
 * Expected         : reject view input and abort cancel ("... not exist")
 * Design note      : per the macro header, DATA= accepts a DATASET only;
 *                    SAS views are deliberately NOT supported (see
 *                    var_coexist / ds_varlist / var_exist for the same rule).
 *                    The member check uses %sysfunc(exist()) without VIEW,
 *                    so a view is reported as "not exist" and processing stops
 *                    instead of silently producing a wrong result.
 * Ideal behaviour  : an explicit "view is not supported" message would be
 *                    friendlier; the current text is asserted below so any
 *                    change of that contract is caught by this test.
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
%include "&_QCDEV_VAR_.\var_coexist.sas";
%include "&_QCDEV_DS_.\ds_varlist.sas";
%include "&_QCDEV_DS_.\ds_num2char.sas";
data n2ce8; a=1; b=2; run;
proc sql;
  create view n2ce8v as select a from n2ce8;
quit;
%qc_begin(prog=ds_num2char_err_08, macro=ds_num2char);
%qc_case(desc=1 view DATA= must be rejected);
*EXPECTED_ERROR: not exist;
%qc_abort_marker;
%ds_num2char(data=n2ce8v,out=n2ce8o,var=a);
%qc_unexpected_continue;
%qc_end;