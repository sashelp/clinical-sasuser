/*===============================================================================
 * var_coexist_err_06.sas - Negative test: SAS view passed as DATA=
 *===============================================================================
 * Macro under test : %var_coexist
 * Expected         : reject view input and abort cancel ("... not exist")
 * Design note      : per the macro header (updated 2026-10-28), DATA= accepts
 *                    a DATASET only; SAS views are deliberately NOT supported.
 *                    The member check uses %sysfunc(exist()) without VIEW, so a
 *                    view is reported as "not exist" instead of answering
 *                    "variables do not coexist" (0), which would be misleading.
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
data vce6; x=1; y=2; z=3; run;
proc sql;
  create view vce6v as select x,y from vce6;
quit;
%qc_begin(prog=var_coexist_err_06, macro=var_coexist);
%qc_case(desc=1 view DATA= must be rejected);
*EXPECTED_ERROR: not exist;
%qc_abort_marker;
%var_coexist(data=vce6v,var=x y);
%qc_unexpected_continue;
%qc_end;