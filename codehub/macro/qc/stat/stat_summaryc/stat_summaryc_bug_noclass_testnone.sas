/*==============================================================================
 * stat_summaryc_bug_noclass_testnone.sas - Bug regression: TEST= not forced to NONE when CLASS= identifies a single group
 *==============================================================================
 * Macro under test : %stat_summaryc
 * Expected         : when CLASS= is not specified, or no CLASS= value is
 *                    nonmissing, all observations form one overall group, so
 *                    TEST= is forced to NONE and the output carries no
 *                    _TESTV_ / _TESTP_ / _TESTM_ columns
 * Status           : OPEN 2026-11-01
 * Original defect  : the forcing block is gated by "%if &class.^=" (line 124),
 *                    therefore an empty or all-missing CLASS= skips it and TEST=
 *                    stays active; PROC FREQ produces no test statistics, so
 *                    every analysis variable shows .N / .N / N/A
 * Fix              : apply the single-group check after CLASS= is empty or
 *                    classallmissing=1 is set, not only inside the &class.^= gate
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

%qc_begin(prog=stat_summaryc_bug_noclass_testnone, macro=stat_summaryc);

%macro _qc_rows(ds=, where=, expect=1, desc=);
  %local rc;
  proc sql noprint;
    select count(*) into :rc from &ds. where &where.;
  quit;
  %qc_check_eq(actual=&rc., expect=&expect., desc=&desc.);
%mend _qc_rows;

%macro _qc_colabs(ds=, var=, mac=);
  %global &mac.;
  %let _did_=%sysfunc(open(&ds.));
  %if &_did_.^=0 %then %do;
    %let &mac.=%sysfunc(varnum(&_did_,&var.));
    %let _did_=%sysfunc(close(&_did_));
  %end;
  %else %let &mac.=-1;
%mend _qc_colabs;

/* 5 records, no CLASS= : F=3 M=2 */
data sc_noclass;
  length trt $1 sex $1;
  input trt $ sex $;
  datalines;
A F
A F
A M
B F
B M
;
run;

/* every CLASS= value missing : F=2 M=2 */
data sc_allmiss;
  length trt $1 sex $1;
  input trt $ sex $;
  datalines;
. F
. M
. F
. M
;
run;

%qc_case(desc=1 chisq forced to none when class is not specified);

%stat_summaryc(data=sc_noclass, out=b1, var=sex, test=chisq);

%qc_expect_ds(ds=b1, desc=B1 output dataset exists);
%qc_expect_nobs(ds=b1, expect=3, desc=B1 one row per level plus total);
%_qc_rows(ds=b1, where=_varlvl_='F' and trt1='3(60.0)' and trt0='3(60.0)', expect=1, desc=B1 overall F count kept);
%_qc_rows(ds=b1, where=_varlvl_='Total' and trt1='5(0)' and trt0='5(0)', expect=1, desc=B1 overall total row kept);
%_qc_colabs(ds=b1, var=_testm_, mac=_b1m);
%qc_check_eq(actual=&_b1m., expect=0, desc=B1 test method column must be absent);
%_qc_colabs(ds=b1, var=_testv_, mac=_b1v);
%qc_check_eq(actual=&_b1v., expect=0, desc=B1 test statistic column must be absent);
%_qc_colabs(ds=b1, var=_testp_, mac=_b1p);
%qc_check_eq(actual=&_b1p., expect=0, desc=B1 p value column must be absent);

%qc_case(desc=2 chisq forced to none when all class values are missing);

%stat_summaryc(data=sc_allmiss, out=b2, class=trt, var=sex, test=chisq);

%qc_expect_ds(ds=b2, desc=B2 output dataset exists);
%qc_expect_nobs(ds=b2, expect=3, desc=B2 one row per level plus total);
%_qc_rows(ds=b2, where=_varlvl_='F' and trt1='2(50.0)' and trt0='2(50.0)', expect=1, desc=B2 overall F count kept);
%_qc_colabs(ds=b2, var=_testm_, mac=_b2m);
%qc_check_eq(actual=&_b2m., expect=0, desc=B2 test method column must be absent);

%qc_end;
