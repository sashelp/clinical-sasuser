/*==============================================================================
 * stat_rateci_bug_noby.sas - Bug regression: BY= empty cannot be processed
 *==============================================================================
 * Macro under test : %stat_rateci
 * Expected         : with BY= omitted the macro still produces the same result
 *                    as a single level BY= variable (the macro has an explicit
 *                    empty BY= branch, so empty BY= is meant to be supported)
 * Status           : FIXED 2026-10-30 - section 2.1.2 now has a separate SQL
 *                    branch for empty BY= (select b.*, c.* / group by class)
 * Original defect  : the 2.1.2 SQL builds "select distinct from ...",
 *                    "group by a.," and "countw()" with no argument when BY=
 *                    is empty, so the step stops with ERROR 22-322 plus
 *                    "COUNTW 参数过少" and the macro terminates without
 *                    creating the OUT= dataset
 * Fix              : build a separate SQL branch for empty BY= that does not
 *                    reference the BY variables, or validate BY= at entry
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

%qc_begin(prog=stat_rateci_bug_noby, macro=stat_rateci);

%qc_case(desc=1 empty BY must still produce the rate and difference);
%stat_rateci(data=rates, out=bug1, class=trt, var=resp, level=%str('Y'),
             smethod=WALD, dmethod=WALD, debug=0);
%qc_expect_ds(ds=bug1, desc=B1 output dataset created without BY);
%qc_expect_nobs(ds=bug1, expect=4, desc=B1 two single rows and two difference rows);
proc sql noprint;
  select count(*) into :b1a from bug1
    where trt='A' and missing(ref_trt) and strip(put(_prop_,8.1))='25.0';
  select count(*) into :b1d from bug1
    where trt='A' and ref_trt='B' and strip(put(_prop_,8.1))='-30.0';
quit;
%qc_check_eq(actual=&b1a., expect=1, desc=B1 class A rate without BY);
%qc_check_eq(actual=&b1d., expect=1, desc=B1 difference without BY);

%qc_end;
