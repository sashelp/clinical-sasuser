/*===============================================================================
 * var_exist_err_05.sas - Negative test: SAS view passed as DATA=
 *===============================================================================
 * Macro under test : %var_exist
 * Expected         : reject view input and abort cancel ("... not exist")
 * Design note      : per the macro header, DATA= accepts a DATASET only; SAS
 *                    views are deliberately NOT supported (same rule as
 *                    var_coexist / ds_varlist / ds_num2char).  The member
 *                    check uses %sysfunc(exist()) without VIEW, so a view is
 *                    reported as "not exist" instead of answering 0
 *                    ("variable absent"), which would be misleading.
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
%include "&_QCDEV_VAR_.\var_exist.sas";
data vee5; x=1; y=2; run;
proc sql;
  create view vee5v as select x,y from vee5;
quit;
%qc_begin(prog=var_exist_err_05, macro=var_exist);
%qc_case(desc=1 view DATA= must be rejected);
*EXPECTED_ERROR: not exist;
%qc_abort_marker;
%var_exist(data=vee5v,var=x);
%qc_unexpected_continue;
%qc_end;