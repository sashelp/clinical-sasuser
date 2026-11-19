/*==============================================================================
 * stat_rateci_err_14.sas - Negative test: SMETHOD= and DMETHOD= both NONE
 *==============================================================================
 * Macro under test : %stat_rateci
 * Expected         : abort cancel with "No computation since both values of
 *                    SMETHOD= and DMETHOD= are NONE."
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
%include "&_QCDEV_VAR_.\var_coexist.sas";
%include "&_QCDEV_DS_.\ds_attr.sas";
%include "&_QCDEV_STAT_.\stat_rateci.sas";

data rci_in;
  length study $2 trt $1 resp $1;
  input study $ trt $ resp $ n;
  do i=1 to n; output; end;
  drop i n;
datalines;
S1 A Y 1
S1 A N 1
S1 B Y 1
S1 B N 1
;
run;

%qc_begin(prog=stat_rateci_err_14, macro=stat_rateci);
%qc_case(desc=1 both SMETHOD and DMETHOD NONE must abort);
*EXPECTED_ERROR: No computation since both values of SMETHOD= and DMETHOD= are NONE.;
%qc_abort_marker;
%stat_rateci(data=rci_in, out=x, by=study, class=trt, var=resp, level=%str('Y'),
             smethod=NONE, dmethod=NONE);
%qc_unexpected_continue;
