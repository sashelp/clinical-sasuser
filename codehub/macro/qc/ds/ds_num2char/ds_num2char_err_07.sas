/*===============================================================================
 * ds_num2char_err_07.sas - Negative test: MISSING= invalid value
 *===============================================================================
 * Macro under test : %ds_num2char
 * Expected         : abort cancel with "invalid value, expecting one of"
 * Regression       : same root cause as ds_num2char_err_06 (missing
 *                    /minoperator made the IN checks compare plain text).
 *                    Fixed on 2026-10-28; this test now guards the behaviour.
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
data n2ce7; x=1; run;
%qc_begin(prog=ds_num2char_err_07, macro=ds_num2char);
%qc_case(desc=1 MISSING= invalid must abort);
*EXPECTED_ERROR: invalid value;
%qc_abort_marker;
%ds_num2char(data=n2ce7,out=n2ce7o,var=x,missing=weird);
%qc_unexpected_continue;
%qc_end;