/*==============================================================================
 * stat_rateci_bug_dmethod_all.sas - Bug regression: DMETHOD=ALL is never expanded
 *==============================================================================
 * Macro under test : %stat_rateci
 * Expected         : DMETHOD=ALL requests AC, EXACT, HA, MN, NEWCOMBE and WALD,
 *                    so each ordered pair yields six rows
 * Status           : FIXED 2026-10-30 - "%if dmethod=ALL" changed to "%if &dmethod.=ALL"
 * Original defect  : the macro uses "%if dmethod=ALL" without "&", so the
 *                    comparison is between the literal words dmethod and ALL
 *                    and never becomes true. The unexpanded token ALL is then
 *                    passed to PROC FREQ as "riskdiff(cl=(ALL))", which is not
 *                    a valid risk difference request: the step issues
 *                    ERROR 22-322, no PDiffCls table is created, the following
 *                    data steps fail and the OUT= dataset ends up with 0
 *                    observations while the log stays full of ERRORs
 * Fix              : change "%if dmethod=ALL" to "%if &dmethod.=ALL"
 * Test passes when  the defect is fixed (run_all then reports FIXED).
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

data rates;
  length subj $12 study $2 trt $1 resp $1;
  retain _k 0;
  input study $ trt $ resp $ n;
  do i=1 to n;
    _k+1;
    subj=cats(trt,_k);
    output;
  end;
  drop n i;
datalines;
S1 A Y 5
S1 A N 15
S1 B Y 11
S1 B N 9
;
run;

%qc_begin(prog=stat_rateci_bug_dmethod_all, macro=stat_rateci);

%qc_case(desc=1 DMETHOD ALL must request every documented method);
%stat_rateci(data=rates, out=bug2, by=study, class=trt, var=resp, level=%str('Y'),
             smethod=NONE, dmethod=ALL, debug=0);
%qc_expect_nobs(ds=bug2, expect=12, desc=B1 six methods for each ordered pair);
proc sql noprint;
  select count(*) into :b1nc from bug2 where _method_='Newcombe';
  select count(*) into :b1ha from bug2 where _method_='Hauck-Anderson';
  select count(*) into :b1mn from bug2 where _method_='Miettinen-Nurminen';
quit;
%qc_check_eq(actual=&b1nc., expect=2, desc=B1 Newcombe computed by ALL);
%qc_check_eq(actual=&b1ha., expect=2, desc=B1 Hauck-Anderson computed by ALL);
%qc_check_eq(actual=&b1mn., expect=2, desc=B1 Miettinen-Nurminen computed by ALL);

%qc_end;
