/*==============================================================================
 * stat_summaryc_test.sas - Positive (functional) acceptance tests
 *==============================================================================
 * Macro under test : %stat_summaryc
 * File under test   : dev/stat/stat_summaryc.sas
 * Dependencies      : %var_exist, %var_coexist, %ds_attr
 * Coverage          : output structure, COL/ROW/TOTAL/NONE percentages,
 *                     PCTDENOM=, TOTLEVELSTAT=, PCTFMT=, SHOWDENOM=/DENOMDLM=,
 *                     custom total class and level ids, no CLASS= analysis,
 *                     numeric CLASS=, custom VAR= format levels, BY= groups,
 *                     three class levels, multiple VAR= variables, library
 *                     qualified OUT=, DEBUG= cleanup, all-missing CLASS=,
 *                     single class level forces TEST= to NONE (CHISQ and FISHER)
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

%qc_begin(prog=stat_summaryc_test, macro=stat_summaryc);

/* helper: count the rows of a dataset that satisfy a condition */
%macro _qc_rows(ds=, where=, expect=1, desc=);
  %local rc;
  proc sql noprint;
    select count(*) into :rc from &ds. where &where.;
  quit;
  %qc_check_eq(actual=&rc., expect=&expect., desc=&desc.);
%mend _qc_rows;

/* helper: read a column label through PROC CONTENTS OUT= */
%macro _qc_lbl(ds=, var=, mac=);
  %global &mac.;
  proc contents data=&ds. out=_qc_meta noprint;
  run;
  data _null_;
    set _qc_meta;
    if upcase(name)=upcase("&var.") then call symputx("&mac.", label);
  run;
%mend _qc_lbl;

/*----------------------------------------------------------------------------
 * Shared input data
 *   A : sex F=2, M=1, missing=1  -> 4 records
 *   B : sex F=2, M=1, missing=0  -> 3 records
 *   total: F=4, M=2, missing=1
 *--------------------------------------------------------------------------*/
data sc_base;
  length trt $1 sex $1 race $6;
  input trt $ sex $ race $;
  datalines;
A F WHITE
A F WHITE
A M BLACK
A . .
B F WHITE
B F BLACK
B M BLACK
;
run;

/* BY= data: group A has A=3 B=3; group B has A=2 B=4 */
data sc_by;
  length grp $1 trt $1 sex $1;
  input grp $ trt $ sex $;
  datalines;
A A F
A A F
A A M
A B F
A B M
A B M
B A F
B A M
B B F
B B F
B B M
B B M
;
run;

/* three class levels: A=3 B=3 C=3 */
data sc_3;
  length trt $1 sex $1;
  input trt $ sex $;
  datalines;
A F
A F
A M
B F
B M
B M
C F
C F
C M
;
run;

/* numeric CLASS= : 1=F2 M1, 2=F1 M2 */
data sc_num;
  length trtn 8 sex $1;
  input trtn sex $;
  datalines;
1 F
1 M
1 F
2 M
2 M
2 F
;
run;

/* class all missing -> overall analysis */
data sc_misscls;
  length trt $1 sex $1;
  input trt $ sex $;
  datalines;
. F
. M
. F
. M
;
run;

/* single class level for the TEST= fallback path */
data sc_one;
  length trt $1 sex $1;
  input trt $ sex $;
  datalines;
A F
A F
A M
;
run;

/*----------------------------------------------------------------------------
 * CASE 1 : default COL percent - structure, values, labels, sort order, cleanup
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 default COL percent structure values labels and cleanup);
%stat_summaryc(data=sc_base, out=o1, class=trt, var=sex);

%qc_expect_ds(ds=o1, desc=C1 output dataset exists);
%qc_expect_nobs(ds=o1, expect=3, desc=C1 one row per level plus total);
%qc_expect_var(ds=o1, var=_varidx_, type=N, desc=C1 varidx numeric);
%qc_expect_var(ds=o1, var=_varnam_, type=C, desc=C1 varnam character);
%qc_expect_var(ds=o1, var=_varlab_, type=C, desc=C1 varlab character);
%qc_expect_var(ds=o1, var=_varlvlidx_, type=N, desc=C1 varlvlidx numeric);
%qc_expect_var(ds=o1, var=_varlvl_, type=C, desc=C1 varlvl character);
%qc_expect_var(ds=o1, var=_statidx_, type=N, desc=C1 statidx numeric);
%qc_expect_var(ds=o1, var=_statlab_, type=C, desc=C1 statlab character);
%qc_expect_var(ds=o1, var=trt1, type=C, desc=C1 trt1 character);
%qc_expect_var(ds=o1, var=trt2, type=C, desc=C1 trt2 character);
%qc_expect_var(ds=o1, var=trt0, type=C, desc=C1 trt0 character);
%qc_expect_len(ds=o1, var=trt1, expect=200, desc=C1 trt1 length 200);
%qc_expect_len(ds=o1, var=_varnam_, expect=200, desc=C1 varnam length 200);

%_qc_rows(ds=o1, where=_varnam_='SEX' and _varidx_=1, expect=3, desc=C1 analysis variable identity on every row);
%_qc_rows(ds=o1, where=_varlvl_='F' and _varlvlidx_=1 and _statidx_=1 and _statlab_='n(%)' and trt1='2(66.7)' and trt2='2(66.7)' and trt0='4(66.7)', expect=1, desc=C1 F row counts and percents);
%_qc_rows(ds=o1, where=_varlvl_='M' and _varlvlidx_=2 and _statidx_=1 and _statlab_='n(%)' and trt1='1(33.3)' and trt2='1(33.3)' and trt0='2(33.3)', expect=1, desc=C1 M row counts and percents);
%_qc_rows(ds=o1, where=_varlvl_='Total' and _varlvlidx_=99 and _statidx_=2 and _statlab_='n(nmiss)' and trt1='3(1)' and trt2='3(0)' and trt0='6(1)', expect=1, desc=C1 total row n and nmiss);

%_qc_lbl(ds=o1, var=trt1, mac=_l1);
%qc_check_eq(actual=&_l1., expect=A@(N=4), desc=C1 trt1 label carries class N);
%_qc_lbl(ds=o1, var=trt2, mac=_l2);
%qc_check_eq(actual=&_l2., expect=B@(N=3), desc=C1 trt2 label carries class N);
%_qc_lbl(ds=o1, var=trt0, mac=_l3);
%qc_check_eq(actual=&_l3., expect=Total@(N=7), desc=C1 total label carries overall N);

%qc_check_eq(actual=%sysfunc(exist(work.stat_summaryc_result)), expect=0, desc=C1 DEBUG=0 deletes intermediates);

/*----------------------------------------------------------------------------
 * CASE 2 : PERCENT=ROW
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 percent row);
%stat_summaryc(data=sc_base, out=o2, class=trt, var=sex, percent=row);
%_qc_rows(ds=o2, where=_varlvl_='F' and trt1='2(50.0)' and trt2='2(50.0)' and trt0='4(66.7)', expect=1, desc=C2 row percent of F);
%_qc_rows(ds=o2, where=_varlvl_='M' and trt1='1(50.0)' and trt2='1(50.0)' and trt0='2(33.3)', expect=1, desc=C2 row percent of M);

/*----------------------------------------------------------------------------
 * CASE 3 : PERCENT=TOTAL
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 percent total);
%stat_summaryc(data=sc_base, out=o3, class=trt, var=sex, percent=total);
%_qc_rows(ds=o3, where=_varlvl_='F' and trt1='2(33.3)' and trt2='2(33.3)' and trt0='4(66.7)', expect=1, desc=C3 overall percent of F);
%_qc_rows(ds=o3, where=_varlvl_='M' and trt1='1(16.7)' and trt2='1(16.7)' and trt0='2(33.3)', expect=1, desc=C3 overall percent of M);

/*----------------------------------------------------------------------------
 * CASE 4 : PERCENT=NONE
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 percent none counts only);
%stat_summaryc(data=sc_base, out=o4, class=trt, var=sex, percent=none);
%_qc_rows(ds=o4, where=_varlvl_='F' and trt1='2' and trt2='2' and trt0='4', expect=1, desc=C4 F row counts without percent);
%_qc_rows(ds=o4, where=_varlvl_='M' and trt1='1' and trt2='1' and trt0='2', expect=1, desc=C4 M row counts without percent);
%_qc_rows(ds=o4, where=_varlvl_='Total' and trt1='3(1)' and trt2='3(0)' and trt0='6(1)', expect=1, desc=C4 total row still shows nmiss);

/*----------------------------------------------------------------------------
 * CASE 5 : PCTDENOM=TOTAL - denominator includes missing VAR values
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 percent denominator includes missing values);
%stat_summaryc(data=sc_base, out=o5, class=trt, var=sex, pctdenom=total);
%_qc_rows(ds=o5, where=_varlvl_='F' and trt1='2(50.0)' and trt2='2(66.7)' and trt0='4(57.1)', expect=1, desc=C5 F percent uses class records as denominator);
%_qc_rows(ds=o5, where=_varlvl_='M' and trt1='1(25.0)' and trt2='1(33.3)' and trt0='2(28.6)', expect=1, desc=C5 M percent uses class records as denominator);

/*----------------------------------------------------------------------------
 * CASE 6 : TOTLEVELSTAT=N
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 total level statistic N only);
%stat_summaryc(data=sc_base, out=o6, class=trt, var=sex, totlevelstat=n);
%_qc_rows(ds=o6, where=_varlvl_='Total' and _statlab_='n' and trt1='3' and trt2='3' and trt0='6', expect=1, desc=C6 total row shows counts only);

/*----------------------------------------------------------------------------
 * CASE 7 : TOTLEVELSTAT=NPERCENT
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 total level statistic N with percent);
%stat_summaryc(data=sc_base, out=o7, class=trt, var=sex, totlevelstat=npercent);
%_qc_rows(ds=o7, where=_varlvl_='Total' and trt1='3(50.0)' and trt2='3(50.0)' and trt0='6(100.0)', expect=1, desc=C7 total row shows count and percent);

/*----------------------------------------------------------------------------
 * CASE 8 : PCTFMT=8.2
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 percent format with two decimals);
%stat_summaryc(data=sc_base, out=o8, class=trt, var=sex, pctfmt=8.2);
%_qc_rows(ds=o8, where=_varlvl_='F' and trt1='2(66.67)' and trt2='2(66.67)' and trt0='4(66.67)', expect=1, desc=C8 percent shown with two decimals);

/*----------------------------------------------------------------------------
 * CASE 9 : SHOWDENOM=N removes the denominator text
 *--------------------------------------------------------------------------*/
%qc_case(desc=9 hide denominator in column labels);
%stat_summaryc(data=sc_base, out=o9, class=trt, var=sex, showdenom=n);
%_qc_lbl(ds=o9, var=trt1, mac=_l9a);
%qc_check_eq(actual=&_l9a., expect=A, desc=C9 trt1 label without denominator);
%_qc_lbl(ds=o9, var=trt0, mac=_l9b);
%qc_check_eq(actual=&_l9b., expect=Total, desc=C9 total label without denominator);

/*----------------------------------------------------------------------------
 * CASE 10 : custom total class id/label, total level id/label, DENOMDLM
 *--------------------------------------------------------------------------*/
%qc_case(desc=10 custom total ids labels and denominator delimiter);
%stat_summaryc(data=sc_base, out=o10, class=trt, var=sex, totclassid=9,
  totclasslab=ALL, totlevelid=88, totlevellab=SUM, denomdlm=~);

%qc_expect_var(ds=o10, var=trt9, type=C, desc=C10 total column uses TOTCLASSID);
%let _did=%sysfunc(open(o10));
%let _p0=%sysfunc(varnum(&_did.,trt0));
%let _rc=%sysfunc(close(&_did.));
%qc_check_eq(actual=&_p0., expect=0, desc=C10 default total column absent);

%_qc_rows(ds=o10, where=_varlvl_='SUM' and _varlvlidx_=88 and _statidx_=2 and _statlab_='n(nmiss)' and trt9='6(1)', expect=1, desc=C10 total level uses TOTLEVELID and TOTLEVELLAB);
%_qc_lbl(ds=o10, var=trt9, mac=_l10);
%qc_check_eq(actual=&_l10., expect=ALL~(N=7), desc=C10 total column label uses TOTCLASSLAB and DENOMDLM);

/*----------------------------------------------------------------------------
 * CASE 11 : no CLASS= - all observations analysed as one overall class
 *--------------------------------------------------------------------------*/
%qc_case(desc=11 no class variable overall analysis);
%stat_summaryc(data=sc_base, out=o11, var=sex);
%qc_expect_nobs(ds=o11, expect=3, desc=C11 one row per level plus total);
%_qc_rows(ds=o11, where=_varlvl_='F' and trt1='4(66.7)' and trt0='4(66.7)', expect=1, desc=C11 overall F count);
%_qc_rows(ds=o11, where=_varlvl_='M' and trt1='2(33.3)' and trt0='2(33.3)', expect=1, desc=C11 overall M count);
%_qc_rows(ds=o11, where=_varlvl_='Total' and trt1='6(1)' and trt0='6(1)', expect=1, desc=C11 overall total row);
%_qc_lbl(ds=o11, var=trt1, mac=_l11);
%qc_check_eq(actual=&_l11., expect=Overall@(N=7), desc=C11 overall column label);

/*----------------------------------------------------------------------------
 * CASE 12 : numeric CLASS=
 *--------------------------------------------------------------------------*/
%qc_case(desc=12 numeric class variable);
%stat_summaryc(data=sc_num, out=o12, class=trtn, var=sex);
%qc_expect_nobs(ds=o12, expect=3, desc=C12 one row per level plus total);
%_qc_rows(ds=o12, where=_varlvl_='F' and trt1='2(66.7)' and trt2='1(33.3)' and trt0='3(50.0)', expect=1, desc=C12 F counts by numeric class);
%_qc_rows(ds=o12, where=_varlvl_='M' and trt1='1(33.3)' and trt2='2(66.7)' and trt0='3(50.0)', expect=1, desc=C12 M counts by numeric class);
%_qc_lbl(ds=o12, var=trt1, mac=_l12);
%qc_check_eq(actual=&_l12., expect=1@(N=3), desc=C12 numeric class label);

/*----------------------------------------------------------------------------
 * CASE 13 : custom format on VAR= - all format levels are reported
 *--------------------------------------------------------------------------*/
%qc_case(desc=13 custom format levels including unobserved);
proc format;
  value $rfmtc 'WHITE'='White' 'BLACK'='Black' 'OTHER'='Other';
run;
data sc_fmt;
  length trt $1 race $6;
  input trt $ race $;
  datalines;
A WHITE
A WHITE
A BLACK
B WHITE
B BLACK
B BLACK
;
run;
data sc_fmt;
  set sc_fmt;
  format race $rfmtc.;
run;
%stat_summaryc(data=sc_fmt, out=o13, class=trt, var=race);
%qc_expect_nobs(ds=o13, expect=4, desc=C13 one row per format level plus total);
%_qc_rows(ds=o13, where=_varlvl_='Black' and _varlvlidx_=1 and trt1='1(33.3)' and trt2='2(66.7)' and trt0='3(50.0)', expect=1, desc=C13 observed format level Black);
%_qc_rows(ds=o13, where=_varlvl_='Other' and _varlvlidx_=2 and trt1='0(0.0)' and trt2='0(0.0)' and trt0='0(0.0)', expect=1, desc=C13 unobserved format level reported);
%_qc_rows(ds=o13, where=_varlvl_='White' and _varlvlidx_=3 and trt1='2(66.7)' and trt2='1(33.3)' and trt0='3(50.0)', expect=1, desc=C13 observed format level White);

/*----------------------------------------------------------------------------
 * CASE 14 : BY= groups
 *--------------------------------------------------------------------------*/
%qc_case(desc=14 by group analysis);
%stat_summaryc(data=sc_by, out=o14, by=grp, class=trt, var=sex);
%qc_expect_nobs(ds=o14, expect=6, desc=C14 three rows for each by group);
%_qc_rows(ds=o14, where=grp='A' and _varlvl_='F' and trt1='2(66.7)' and trt2='1(33.3)' and trt0='3(50.0)', expect=1, desc=C14 group A F counts);
%_qc_rows(ds=o14, where=grp='A' and _varlvl_='Total' and trt1='3(0)' and trt2='3(0)' and trt0='6(0)', expect=1, desc=C14 group A total row);
%_qc_rows(ds=o14, where=grp='B' and _varlvl_='F' and trt1='1(50.0)' and trt2='2(50.0)' and trt0='3(50.0)', expect=1, desc=C14 group B F counts);
%_qc_rows(ds=o14, where=grp='B' and _varlvl_='Total' and trt1='2(0)' and trt2='4(0)' and trt0='6(0)', expect=1, desc=C14 group B total row);

/*----------------------------------------------------------------------------
 * CASE 15 : three class levels
 *--------------------------------------------------------------------------*/
%qc_case(desc=15 three class levels);
%stat_summaryc(data=sc_3, out=o15, class=trt, var=sex);
%qc_expect_var(ds=o15, var=trt3, type=C, desc=C15 third class column created);
%_qc_rows(ds=o15, where=_varlvl_='F' and trt1='2(66.7)' and trt2='1(33.3)' and trt3='2(66.7)' and trt0='5(55.6)', expect=1, desc=C15 F counts across three classes);
%_qc_rows(ds=o15, where=_varlvl_='M' and trt1='1(33.3)' and trt2='2(66.7)' and trt3='1(33.3)' and trt0='4(44.4)', expect=1, desc=C15 M counts across three classes);

/*----------------------------------------------------------------------------
 * CASE 16 : multiple analysis variables
 *--------------------------------------------------------------------------*/
%qc_case(desc=16 multiple analysis variables);
%stat_summaryc(data=sc_base, out=o16, class=trt, var=sex race);
%qc_expect_nobs(ds=o16, expect=6, desc=C16 three rows for each analysis variable);
%_qc_rows(ds=o16, where=_varnam_='SEX' and _varidx_=1 and _varlvlidx_=1 and _statlab_='n(%)' and trt1='2(66.7)' and trt2='2(66.7)', expect=1, desc=C16 sex block first row);
%_qc_rows(ds=o16, where=_varnam_='RACE' and _varidx_=2 and _varlvlidx_=1 and _varlvl_='BLACK' and trt1='1(33.3)' and trt2='2(66.7)', expect=1, desc=C16 race block first row);
%_qc_rows(ds=o16, where=_varnam_='RACE' and _varlvl_='Total' and trt1='3(1)' and trt2='3(0)' and trt0='6(1)', expect=1, desc=C16 race total row nmiss);

/*----------------------------------------------------------------------------
 * CASE 17 : library qualified OUT=
 *--------------------------------------------------------------------------*/
%qc_case(desc=17 library qualified output dataset);
libname qcstat "&_QCRES_.";
%stat_summaryc(data=sc_base, out=qcstat.stat_summaryc_o17, class=trt, var=sex);
%qc_expect_ds(ds=qcstat.stat_summaryc_o17, desc=C17 output created in permanent library);
%qc_expect_nobs(ds=qcstat.stat_summaryc_o17, expect=3, desc=C17 permanent output rows);
%_qc_rows(ds=qcstat.stat_summaryc_o17, where=_varlvl_='F' and trt1='2(66.7)' and trt0='4(66.7)', expect=1, desc=C17 permanent output values);
libname qcstat clear;

/*----------------------------------------------------------------------------
 * CASE 18 : DEBUG=1 keeps intermediate datasets
 *--------------------------------------------------------------------------*/
%qc_case(desc=18 debug keeps intermediate datasets);
%stat_summaryc(data=sc_base, out=o18, class=trt, var=sex, debug=1);
%qc_check_eq(actual=%sysfunc(exist(work.stat_summaryc_result)), expect=1, desc=C18 result intermediate kept);
%qc_check_eq(actual=%sysfunc(exist(work.stat_summaryc_freqs)), expect=1, desc=C18 freqs intermediate kept);
%qc_check_eq(actual=%sysfunc(exist(work.stat_summaryc_weight)), expect=1, desc=C18 weight intermediate kept);

/*----------------------------------------------------------------------------
 * CASE 19 : CLASS= entirely missing -> overall analysis
 *--------------------------------------------------------------------------*/
%qc_case(desc=19 class variable entirely missing);
%stat_summaryc(data=sc_misscls, out=o19, class=trt, var=sex);
%qc_expect_ds(ds=o19, desc=C19 output dataset exists);
%qc_expect_nobs(ds=o19, expect=3, desc=C19 overall analysis rows);
%_qc_rows(ds=o19, where=_varlvl_='F' and trt1='2(50.0)' and trt0='2(50.0)', expect=1, desc=C19 overall F count);
%_qc_rows(ds=o19, where=_varlvl_='Total' and trt1='4(0)' and trt0='4(0)', expect=1, desc=C19 overall total row);

/*----------------------------------------------------------------------------
 * CASE 20 : single class level with TEST=CHISQ - test forced to NONE
 *   A single non-missing class level means there is nothing to compare, so the
 *   macro must emit a WARNING and drop the test columns from the output.
 *--------------------------------------------------------------------------*/
%qc_case(desc=20 single class level forces chisq test to none);
%stat_summaryc(data=sc_one, out=o20, class=trt, var=sex, test=chisq);
%qc_expect_ds(ds=o20, desc=C20 output dataset exists);
%qc_expect_nobs(ds=o20, expect=3, desc=C20 output rows);
%_qc_rows(ds=o20, where=_varlvl_='F' and trt1='2(66.7)' and trt0='2(66.7)', expect=1, desc=C20 F count);
%_qc_rows(ds=o20, where=_varlvl_='M' and trt1='1(33.3)' and trt0='1(33.3)', expect=1, desc=C20 M count);
%_qc_rows(ds=o20, where=_varlvl_='Total' and trt1='3(0)' and trt0='3(0)', expect=1, desc=C20 total row);
%let _did=%sysfunc(open(o20));
%let _p20=%sysfunc(varnum(&_did.,_testm_));
%let _rc=%sysfunc(close(&_did.));
%qc_check_eq(actual=&_p20., expect=0, desc=C20 test method column dropped);

/*----------------------------------------------------------------------------
 * CASE 21 : single class level with TEST=FISHER - test forced to NONE
 *--------------------------------------------------------------------------*/
%qc_case(desc=21 single class level forces fisher test to none);
%stat_summaryc(data=sc_one, out=o21, class=trt, var=sex, test=fisher);
%qc_expect_ds(ds=o21, desc=C21 output dataset exists);
%qc_expect_nobs(ds=o21, expect=3, desc=C21 output rows);
%_qc_rows(ds=o21, where=_varlvl_='F' and trt1='2(66.7)' and trt0='2(66.7)', expect=1, desc=C21 F count);
%let _did=%sysfunc(open(o21));
%let _p21=%sysfunc(varnum(&_did.,_testv_));
%let _rc=%sysfunc(close(&_did.));
%qc_check_eq(actual=&_p21., expect=0, desc=C21 test statistic column dropped);

%qc_end;
