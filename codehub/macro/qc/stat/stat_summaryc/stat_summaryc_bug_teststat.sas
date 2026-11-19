/*==============================================================================
 * stat_summaryc_bug_teststat.sas - Bug regression: TEST= statistics not attached to the analysis variable
 *==============================================================================
 * Macro under test : %stat_summaryc
 * Expected         : _TESTV_ / _TESTP_ / _TESTM_ hold the chi-square statistic,
 *                    p value and method on the first row of the analysis variable
 * Status           : OPEN 2026-11-01
 * Original defect  : the ODS Table label of the ZH_CN session ("表“trt-sex”")
 *                    is parsed into the class variable (trt) instead of the
 *                    analysis variable (sex), so the test record key never
 *                    matches and every TEST= output shows .N / .N / N/A
 * Fix              : parse the last token of the table label instead of the first
 * Test passes when  the defect is fixed (run_all then reports FIXED)
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
%include "&_QCDEV_STAT_.\stat_summaryc.sas";

%qc_begin(prog=stat_summaryc_bug_teststat, macro=stat_summaryc);

%macro _qc_rows(ds=, where=, expect=1, desc=);
  %local rc;
  proc sql noprint;
    select count(*) into :rc from &ds. where &where.;
  quit;
  %qc_check_eq(actual=&rc., expect=&expect., desc=&desc.);
%mend _qc_rows;

/* 2x2 table with adequate expected counts: no chi-square warning */
data sc_test;
  length trt $1 sex $1;
  do i=1 to 10; trt='A'; sex='F'; output; end;
  do i=1 to 5;  trt='A'; sex='M'; output; end;
  do i=1 to 5;  trt='B'; sex='F'; output; end;
  do i=1 to 10; trt='B'; sex='M'; output; end;
  drop i;
run;

%stat_summaryc(data=sc_test, out=ob1, class=trt, var=sex, test=chisq, debug=1);

/* diagnostic: record the actual key and attached values in the SAS log */
data _null_;
  set stat_summaryc_test;
  call symputx('_qc_tvarnam', _varnam_);
run;
data _null_;
  set ob1;
  where _varlvl_='F';
  call symputx('_qc_tm', _testm_);
  call symputx('_qc_tv', cats(_testv_));
  call symputx('_qc_tp', cats(_testp_));
run;
%put NOTE: BUG_TESTSTAT test record _varnam_=[&_qc_tvarnam.];
%put NOTE: BUG_TESTSTAT output F row _testm_=[&_qc_tm.] _testv_=[&_qc_tv.] _testp_=[&_qc_tp.];

%qc_case(desc=1 chisq statistic attached to the analysis variable);
%qc_expect_ds(ds=ob1, desc=C1 output dataset exists);
%_qc_rows(ds=ob1, where=_varlvl_='F' and _testm_='Chisq', expect=1, desc=C1 method recorded as Chisq);
%_qc_rows(ds=ob1, where=_varlvl_='F' and not missing(_testv_) and abs(_testv_-3.3333)<0.001, expect=1, desc=C1 chi square statistic recorded);
%_qc_rows(ds=ob1, where=_varlvl_='F' and not missing(_testp_) and abs(_testp_-0.0679)<0.001, expect=1, desc=C1 p value recorded);
%_qc_rows(ds=ob1, where=_varlvl_ in ('M','Total') and missing(_testv_) and missing(_testp_), expect=2, desc=C1 test values cleared after the first row);

%qc_end;
