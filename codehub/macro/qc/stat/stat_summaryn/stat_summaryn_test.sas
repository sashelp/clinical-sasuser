/*==============================================================================
 * stat_summaryn_test.sas - Positive (functional) acceptance tests
 *==============================================================================
 * Macro under test : %stat_summaryn
 * File under test   : dev/stat/stat_summaryn.sas
 * Dependencies      : %var_exist, %var_coexist, %ds_attr
 * Coverage          : output structure, default statistics, multiple VAR=,
 *                     STATIS= order and labels, format options, CI_ALPHA=,
 *                     SHOWDENOM=/DENOMDLM=/TOTCLASSID=/TOTCLASSLAB=, BY=,
 *                     numeric CLASS=, no CLASS=, TEST=PAR/NPAR/AUTO, geometric
 *                     statistics, RAWDECSOURCE=, custom CLASS= format,
 *                     library-qualified OUT=, single class level, all-missing
 *                     CLASS= and VAR=, single observation, DEBUG= cleanup
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
%include "&_QCDEV_STAT_.\stat_summaryn.sas";

%qc_begin(prog=stat_summaryn_test, macro=stat_summaryn);

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

/* helper: get the column number of a variable, 0 when absent */
%macro _qc_nov(ds=, var=, mac=);
  %global &mac.;
  %local _did _rc;
  %let _did=%sysfunc(open(&ds.));
  %let &mac.=%sysfunc(varnum(&_did.,&var.));
  %let _rc=%sysfunc(close(&_did.));
%mend _qc_nov;

/*----------------------------------------------------------------------------
 * Shared input data
 *   trt A: 5 records, trt B: 6 records; total 11
 *   age    A 10,12,14,16,18        B 20,22,24,26,28,30
 *   height A 50,52,54,56,58        B 60,62,64,66,68,70
 *   weight A 100,110,120,130,140   B 150,160,170,180,190,200
 *--------------------------------------------------------------------------*/
data sn_base;
  length trt $1 sex $1;
  input trt $ sex $ age height weight;
  datalines;
A F 10 50 100
A F 12 52 110
A F 14 54 120
A F 16 56 130
A F 18 58 140
B F 20 60 150
B F 22 62 160
B F 24 64 170
B F 26 66 180
B M 28 68 190
B M 30 70 200
;
run;

/* BY= data: four by groups of two records each */
data sn_by2;
  length grp $1 subj $1;
  input grp $ subj $ x;
  datalines;
A P 1
A P 2
A Q 3
A Q 4
B P 5
B P 6
B Q 7
B Q 8
;
run;

/* three class levels, four records each */
data sn_3;
  length trt $1;
  input trt $ x;
  datalines;
A 1
A 2
A 3
A 4
B 5
B 6
B 7
B 8
C 9
C 10
C 11
C 12
;
run;

/* numeric CLASS= : 1 has 1 2 3, 2 has 5 7 9 */
data sn_num;
  input grpn x;
  datalines;
1 1
1 2
1 3
2 5
2 7
2 9
;
run;

/* TEST=AUTO: Y is symmetric, X contains an extreme outlier */
data sn_auto;
  length trt $1;
  input trt $ y x;
  datalines;
A 1 1
A 2 1
A 3 1
A 4 1
A 5 100
B 2 2
B 3 2
B 4 2
B 5 2
B 6 2
;
run;

/* geometric statistics: four positive values plus one zero and one negative */
data sn_gm;
  input x;
  datalines;
1
2
4
8
0
-2
;
run;

/* decimal places differ between BY groups */
data sn_dec;
  length grp $1;
  input grp $ x;
  datalines;
A 1
A 2
A 3
B 1.25
B 2.25
B 3.25
;
run;

/* custom CLASS= format with an unobserved level */
proc format;
  value $sfmt 'F'='Female' 'M'='Male' 'U'='Unknown';
run;
data sn_fmt;
  length trt $1 sex $1;
  input trt $ sex $ age;
  format sex $sfmt.;
  datalines;
A F 10
A F 12
A M 14
B F 16
B M 18
B M 20
;
run;

/* CLASS= entirely missing */
data sn_misscls;
  length trt $1;
  input trt $ x;
  datalines;
. 1
. 2
. 3
. 4
;
run;

/* VAR= entirely missing */
data sn_missvar;
  length trt $1;
  input trt $ x;
  datalines;
A .
A .
B .
B .
;
run;

/* single observation */
data sn_single;
  x=5;
run;

/* single class level */
data sn_one;
  length trt $1;
  input trt $ x;
  datalines;
A 1
A 2
A 3
;
run;

/* one observation in each of two groups - no test is computable */
data sn_n1;
  length trt $1;
  input trt $ x;
  datalines;
A 1
B 5
;
run;

/* five ordered values for MED_Q1_Q3 */
data sn_med;
  input x;
  datalines;
1
2
3
4
5
;
run;

/*----------------------------------------------------------------------------
 * CASE 1 : default output - structure, values, labels, sort order, cleanup
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 default output structure values labels and cleanup);
%stat_summaryn(data=sn_base, out=o1, class=trt, var=age);

%qc_expect_ds(ds=o1, desc=C1 output dataset exists);
%qc_expect_nobs(ds=o1, expect=5, desc=C1 one row per statistic);
%qc_expect_var(ds=o1, var=_varidx_, type=N, desc=C1 varidx numeric);
%qc_expect_var(ds=o1, var=_varnam_, type=C, desc=C1 varnam character);
%qc_expect_var(ds=o1, var=_varlab_, type=C, desc=C1 varlab character);
%qc_expect_var(ds=o1, var=_statidx_, type=N, desc=C1 statidx numeric);
%qc_expect_var(ds=o1, var=_statnam_, type=C, desc=C1 statnam character);
%qc_expect_var(ds=o1, var=_statlab_, type=C, desc=C1 statlab character);
%qc_expect_var(ds=o1, var=trt0, type=C, desc=C1 total column character);
%qc_expect_var(ds=o1, var=trt1, type=C, desc=C1 class A column character);
%qc_expect_var(ds=o1, var=trt2, type=C, desc=C1 class B column character);
%qc_expect_len(ds=o1, var=trt1, expect=200, desc=C1 trt1 length 200);
%qc_expect_len(ds=o1, var=_varnam_, expect=200, desc=C1 varnam length 200);
%qc_expect_len(ds=o1, var=_statlab_, expect=200, desc=C1 statlab length 200);

%_qc_rows(ds=o1, where=%str(_varidx_=1 and _varnam_='AGE' and _varlab_='age'), expect=5, desc=C1 analysis variable identity on every row);
%_qc_rows(ds=o1, where=%str(_statidx_=1 and _statnam_='N_NMISS' and _statlab_='n(miss)' and trt0='11(0)' and trt1='5(0)' and trt2='6(0)'), expect=1, desc=C1 N and NMISS row);
%_qc_rows(ds=o1, where=%str(_statidx_=2 and _statnam_='MEAN_STD' and _statlab_='Mean(SD)' and trt0='20.0(6.63)' and trt1='14.0(3.16)' and trt2='25.0(3.74)'), expect=1, desc=C1 mean and SD row);
%_qc_rows(ds=o1, where=%str(_statidx_=3 and _statnam_='MEDIAN' and trt0='20.0' and trt1='14.0' and trt2='25.0'), expect=1, desc=C1 median row);
%_qc_rows(ds=o1, where=%str(_statidx_=4 and _statnam_='Q1_Q3' and _statlab_='Q1,Q3' and trt0='14.0, 26.0' and trt1='12.0, 16.0' and trt2='22.0, 28.0'), expect=1, desc=C1 quartile row);
%_qc_rows(ds=o1, where=%str(_statidx_=5 and _statnam_='MIN_MAX' and _statlab_='Min,Max' and trt0='10, 30' and trt1='10, 18' and trt2='20, 30'), expect=1, desc=C1 min and max row);

%_qc_lbl(ds=o1, var=trt0, mac=_l1a);
%_qc_lbl(ds=o1, var=trt1, mac=_l1b);
%_qc_lbl(ds=o1, var=trt2, mac=_l1c);
%qc_check_eq(actual=&_l1a., expect=Total@(N=11), desc=C1 total label carries overall N);
%qc_check_eq(actual=&_l1b., expect=A@(N=5), desc=C1 first class label carries N);
%qc_check_eq(actual=&_l1c., expect=B@(N=6), desc=C1 second class label carries N);

%_qc_nov(ds=o1, var=_testv_, mac=_n1);
%qc_check_eq(actual=&_n1., expect=0, desc=C1 no test columns when TEST=NONE);
%qc_check_eq(actual=%sysfunc(exist(work.stat_summaryn_dsin)), expect=0, desc=C1 DEBUG=0 deletes intermediates);

/*----------------------------------------------------------------------------
 * CASE 2 : multiple analysis variables
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 multiple analysis variables);
%stat_summaryn(data=sn_base, out=o2, class=trt, var=age height);
%qc_expect_nobs(ds=o2, expect=10, desc=C2 five rows for each analysis variable);
%_qc_rows(ds=o2, where=%str(_varidx_=2 and _varnam_='HEIGHT' and _statidx_=1 and trt0='11(0)' and trt1='5(0)' and trt2='6(0)'), expect=1, desc=C2 height N row);
%_qc_rows(ds=o2, where=%str(_varidx_=2 and _statidx_=2 and trt0='60.0(6.63)' and trt1='54.0(3.16)' and trt2='65.0(3.74)'), expect=1, desc=C2 height mean and SD);
%_qc_rows(ds=o2, where=%str(_varidx_=2 and _statidx_=4 and trt0='54.0, 66.0' and trt1='52.0, 56.0' and trt2='62.0, 68.0'), expect=1, desc=C2 height quartiles);
%_qc_rows(ds=o2, where=%str(_varidx_=2 and _statidx_=5 and trt0='50, 70' and trt1='50, 58' and trt2='60, 70'), expect=1, desc=C2 height min and max);

/*----------------------------------------------------------------------------
 * CASE 3 : custom STATIS= list - order, names, labels and values
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 custom statistic list order and labels);
%stat_summaryn(data=sn_base, out=o3, class=trt, var=height,
  statis=n nmiss sum stddev stderr var cv min max range);

%qc_expect_nobs(ds=o3, expect=10, desc=C3 one row per requested statistic);
%_qc_rows(ds=o3, where=%str(_statidx_=1 and _statnam_='N' and trt0='11' and trt1='5' and trt2='6'), expect=1, desc=C3 N row);
%_qc_rows(ds=o3, where=%str(_statidx_=2 and _statnam_='NMISS' and trt0='0' and trt1='0' and trt2='0'), expect=1, desc=C3 NMISS row);
%_qc_rows(ds=o3, where=%str(_statidx_=3 and _statnam_='SUM' and trt0='660' and trt1='270' and trt2='390'), expect=1, desc=C3 sum row);
%_qc_rows(ds=o3, where=%str(_statidx_=4 and _statnam_='STDDEV' and trt0='6.63' and trt1='3.16' and trt2='3.74'), expect=1, desc=C3 standard deviation row);
%_qc_rows(ds=o3, where=%str(_statidx_=5 and _statnam_='STDERR' and trt0='2.00' and trt1='1.41' and trt2='1.53'), expect=1, desc=C3 standard error row);
%_qc_rows(ds=o3, where=%str(_statidx_=6 and _statnam_='VAR' and trt0='44.00' and trt1='10.00' and trt2='14.00'), expect=1, desc=C3 variance row);
%_qc_rows(ds=o3, where=%str(_statidx_=7 and _statnam_='CV' and trt0='11.06' and trt1='5.86' and trt2='5.76'), expect=1, desc=C3 coefficient of variation row);
%_qc_rows(ds=o3, where=%str(_statidx_=8 and _statnam_='MIN' and trt0='50' and trt1='50' and trt2='60'), expect=1, desc=C3 min row);
%_qc_rows(ds=o3, where=%str(_statidx_=9 and _statnam_='MAX' and trt0='70' and trt1='58' and trt2='70'), expect=1, desc=C3 max row);
%_qc_rows(ds=o3, where=%str(_statidx_=10 and _statnam_='RANGE' and trt0='20' and trt1='8' and trt2='10'), expect=1, desc=C3 range row);

/*----------------------------------------------------------------------------
 * CASE 4 : display formats - MAXDEC=, MINMAXFMT=, POSFMT=, SCAFMT=, CVFMT=
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 display format overrides);
%stat_summaryn(data=sn_base, out=o4, class=trt, var=age,
  statis=n mean stddev median q1 q3 min max min_max sum cv,
  maxdec=0, minmaxfmt=8.1, posfmt=8.1, scafmt=6.2, cvfmt=8.3);
%qc_expect_nobs(ds=o4, expect=11, desc=C4 one row per statistic);
%_qc_rows(ds=o4, where=%str(_statidx_=2 and trt0='20.0' and trt1='14.0' and trt2='25.0'), expect=1, desc=C4 POSFMT controls mean);
%_qc_rows(ds=o4, where=%str(_statidx_=3 and trt0='6.63' and trt1='3.16' and trt2='3.74'), expect=1, desc=C4 SCAFMT controls standard deviation);
%_qc_rows(ds=o4, where=%str(_statidx_=7 and trt0='10.0' and trt1='10.0' and trt2='20.0'), expect=1, desc=C4 MINMAXFMT controls min);
%_qc_rows(ds=o4, where=%str(_statidx_=9 and trt0='10.0, 30.0' and trt1='10.0, 18.0' and trt2='20.0, 30.0'), expect=1, desc=C4 MINMAXFMT controls Min and Max pair);
%_qc_rows(ds=o4, where=%str(_statidx_=10 and trt0='220.0' and trt1='70.0' and trt2='150.0'), expect=1, desc=C4 MINMAXFMT controls sum);
%_qc_rows(ds=o4, where=%str(_statidx_=11 and trt0='33.166' and trt1='22.588' and trt2='14.967'), expect=1, desc=C4 CVFMT controls CV);

/*----------------------------------------------------------------------------
 * CASE 5 : CI_ALPHA= and confidence limit statistics
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 confidence limits with alpha 0.1);
%stat_summaryn(data=sn_base, out=o5, class=trt, var=age,
  statis=clm lclm uclm mean median, ci_alpha=0.1, maxdec=2);
%qc_expect_nobs(ds=o5, expect=5, desc=C5 one row per statistic);
%_qc_rows(ds=o5, where=%str(_statidx_=1 and _statnam_='CLM' and _statlab_='90% CI' and trt0='16.4, 23.6' and trt1='11.0, 17.0' and trt2='21.9, 28.1'), expect=1, desc=C5 confidence interval pair);
%_qc_rows(ds=o5, where=%str(_statidx_=2 and _statnam_='LCLM' and _statlab_='90% CI Lower' and trt0='16.4' and trt1='11.0' and trt2='21.9'), expect=1, desc=C5 lower confidence limit);
%_qc_rows(ds=o5, where=%str(_statidx_=3 and _statnam_='UCLM' and _statlab_='90% CI Upper' and trt0='23.6' and trt1='17.0' and trt2='28.1'), expect=1, desc=C5 upper confidence limit);

/*----------------------------------------------------------------------------
 * CASE 6 : SHOWDENOM=, DENOMDLM=, TOTCLASSID=, TOTCLASSLAB=
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 denominator text total id and total label options);
%stat_summaryn(data=sn_base, out=o6, class=trt, var=age,
  showdenom=n, denomdlm=~, totclassid=9, totclasslab=ALL);
%qc_expect_var(ds=o6, var=trt9, type=C, desc=C6 total column uses TOTCLASSID);
%_qc_nov(ds=o6, var=trt0, mac=_n6);
%qc_check_eq(actual=&_n6., expect=0, desc=C6 default total column absent);
%_qc_rows(ds=o6, where=%str(_statidx_=1 and trt1='5(0)' and trt2='6(0)' and trt9='11(0)'), expect=1, desc=C6 values stay in class and total columns);
%_qc_lbl(ds=o6, var=trt1, mac=_l6a);
%_qc_lbl(ds=o6, var=trt2, mac=_l6b);
%_qc_lbl(ds=o6, var=trt9, mac=_l6c);
%qc_check_eq(actual=&_l6a., expect=A, desc=C6 class label without denominator);
%qc_check_eq(actual=&_l6b., expect=B, desc=C6 second class label without denominator);
%qc_check_eq(actual=&_l6c., expect=ALL, desc=C6 total label uses TOTCLASSLAB);

/*----------------------------------------------------------------------------
 * CASE 7 : BY= groups
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 by group analysis);
%stat_summaryn(data=sn_base, out=o7, by=sex, class=trt, var=age);
%qc_expect_nobs(ds=o7, expect=10, desc=C7 five rows for each by group);
%_qc_rows(ds=o7, where=%str(sex='F' and _statidx_=1 and trt0='9(0)' and trt1='5(0)' and trt2='4(0)'), expect=1, desc=C7 female group counts);
%_qc_rows(ds=o7, where=%str(sex='F' and _statidx_=2 and trt0='18.0(5.48)' and trt1='14.0(3.16)' and trt2='23.0(2.58)'), expect=1, desc=C7 female group mean and SD);
%_qc_rows(ds=o7, where=%str(sex='M' and _statidx_=1 and trt0='2(0)' and trt1='' and trt2='2(0)'), expect=1, desc=C7 absent class level stays blank);
%_qc_rows(ds=o7, where=%str(sex='M' and _statidx_=2 and trt0='29.0(1.41)' and trt2='29.0(1.41)'), expect=1, desc=C7 male group mean and SD);

/*----------------------------------------------------------------------------
 * CASE 8 : multiple BY= variables
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 multiple by variables);
%stat_summaryn(data=sn_by2, out=o8, by=grp subj, var=x);
%qc_expect_nobs(ds=o8, expect=20, desc=C8 five rows for each by combination);
%_qc_rows(ds=o8, where=%str(grp='A' and subj='P' and _statidx_=2 and trt0='1.5(0.71)'), expect=1, desc=C8 group A P statistics);
%_qc_rows(ds=o8, where=%str(grp='A' and subj='Q' and _statidx_=2 and trt0='3.5(0.71)'), expect=1, desc=C8 group A Q statistics);
%_qc_rows(ds=o8, where=%str(grp='B' and subj='P' and _statidx_=2 and trt0='5.5(0.71)'), expect=1, desc=C8 group B P statistics);
%_qc_rows(ds=o8, where=%str(grp='B' and subj='Q' and _statidx_=2 and trt0='7.5(0.71)'), expect=1, desc=C8 group B Q statistics);

/*----------------------------------------------------------------------------
 * CASE 9 : numeric CLASS=
 *--------------------------------------------------------------------------*/
%qc_case(desc=9 numeric class variable);
%stat_summaryn(data=sn_num, out=o9, class=grpn, var=x);
%qc_expect_nobs(ds=o9, expect=5, desc=C9 one row per statistic);
%_qc_rows(ds=o9, where=%str(_statidx_=1 and trt0='6(0)' and trt1='3(0)' and trt2='3(0)'), expect=1, desc=C9 counts by numeric class);
%_qc_rows(ds=o9, where=%str(_statidx_=2 and trt0='4.5(3.08)' and trt1='2.0(1.00)' and trt2='7.0(2.00)'), expect=1, desc=C9 means by numeric class);
%_qc_lbl(ds=o9, var=trt1, mac=_l9);
%qc_check_eq(actual=&_l9., expect=1@(N=3), desc=C9 numeric class label);

/*----------------------------------------------------------------------------
 * CASE 10 : no CLASS= - overall group
 *--------------------------------------------------------------------------*/
%qc_case(desc=10 no class overall analysis);
%stat_summaryn(data=sn_base, out=o10, var=age);
%qc_expect_nobs(ds=o10, expect=5, desc=C10 one row per statistic);
%_qc_rows(ds=o10, where=%str(_statidx_=1 and trt0='11(0)' and trt1='11(0)'), expect=1, desc=C10 overall counts in both columns);
%_qc_rows(ds=o10, where=%str(_statidx_=2 and trt0='20.0(6.63)' and trt1='20.0(6.63)'), expect=1, desc=C10 overall mean and SD);
%_qc_rows(ds=o10, where=%str(trt0 ne trt1), expect=0, desc=C10 total and overall columns agree);
%_qc_lbl(ds=o10, var=trt1, mac=_l10);
%qc_check_eq(actual=&_l10., expect=Overall@(N=11), desc=C10 overall column label);

/*----------------------------------------------------------------------------
 * CASE 11 : TEST=PAR with two groups - pooled t test
 *--------------------------------------------------------------------------*/
%qc_case(desc=11 parametric test for two groups);
%stat_summaryn(data=sn_base, out=o11, class=trt, var=age, test=par);
%qc_expect_var(ds=o11, var=_testv_, type=N, desc=C11 test statistic column exists);
%qc_expect_var(ds=o11, var=_testp_, type=N, desc=C11 p value column exists);
%qc_expect_var(ds=o11, var=_testm_, type=C, desc=C11 test method column exists);
%_qc_rows(ds=o11, where=%str(_statidx_=1 and _testm_='t test' and _testp_<0.001 and _testv_<0), expect=1, desc=C11 t test reported on first row);
%_qc_rows(ds=o11, where=%str(_statidx_>1 and _testm_=''), expect=4, desc=C11 test columns cleared on later rows);

/*----------------------------------------------------------------------------
 * CASE 12 : TEST=PAR with three groups - ANOVA
 *--------------------------------------------------------------------------*/
%qc_case(desc=12 parametric test for three groups);
%stat_summaryn(data=sn_3, out=o12, class=trt, var=x, test=par);
%qc_expect_nobs(ds=o12, expect=5, desc=C12 one row per statistic);
%qc_expect_var(ds=o12, var=trt3, type=C, desc=C12 third class column exists);
%_qc_rows(ds=o12, where=%str(_statidx_=1 and _testm_='ANOVA' and _testp_<0.001 and _testv_>30), expect=1, desc=C12 ANOVA reported on first row);
%_qc_rows(ds=o12, where=%str(_statidx_>1 and _testp_=.), expect=4, desc=C12 p value cleared on later rows);

/*----------------------------------------------------------------------------
 * CASE 13 : TEST=NPAR with two groups - Wilcoxon
 *--------------------------------------------------------------------------*/
%qc_case(desc=13 nonparametric test for two groups);
%stat_summaryn(data=sn_base, out=o13, class=trt, var=age, test=npar);
%_qc_rows(ds=o13, where=%str(_statidx_=1 and _testm_='Wilcoxon' and _testp_<0.01), expect=1, desc=C13 Wilcoxon test reported);
%_qc_rows(ds=o13, where=%str(_statidx_>1 and _testm_=''), expect=4, desc=C13 test columns cleared on later rows);

/*----------------------------------------------------------------------------
 * CASE 14 : TEST=NPAR with three groups - Kruskal-Wallis
 *--------------------------------------------------------------------------*/
%qc_case(desc=14 nonparametric test for three groups);
%stat_summaryn(data=sn_3, out=o14, class=trt, var=x, test=npar);
%_qc_rows(ds=o14, where=%str(_statidx_=1 and _testm_='Kruskal-Wallis' and _testp_<0.01), expect=1, desc=C14 Kruskal-Wallis test reported);

/*----------------------------------------------------------------------------
 * CASE 15 : TEST=AUTO - per variable normality decision
 *--------------------------------------------------------------------------*/
%qc_case(desc=15 automatic test selection);
%stat_summaryn(data=sn_auto, out=o15, class=trt, var=y x, test=auto);
%_qc_rows(ds=o15, where=%str(_varidx_=1 and _statidx_=1 and _testm_='t test'), expect=1, desc=C15 symmetric variable uses t test);
%_qc_rows(ds=o15, where=%str(_varidx_=2 and _statidx_=1 and _testm_='Wilcoxon'), expect=1, desc=C15 skewed variable uses Wilcoxon);
%_qc_rows(ds=o15, where=%str(_statidx_=1 and _testp_^=.), expect=2, desc=C15 both variables carry a p value);

/*----------------------------------------------------------------------------
 * CASE 16 : geometric statistics - non-positive values excluded
 *--------------------------------------------------------------------------*/
%qc_case(desc=16 geometric statistics);
%stat_summaryn(data=sn_gm, out=o16, var=x,
  statis=gm gm_lclm gm_uclm gm_clm gm_std gm_stddev gm_cv n nmiss);
%qc_expect_nobs(ds=o16, expect=9, desc=C16 one row per statistic);
%_qc_rows(ds=o16, where=%str(_statidx_=1 and _statnam_='GM' and trt0='2.8'), expect=1, desc=C16 geometric mean uses positive values only);
%_qc_rows(ds=o16, where=%str(_statidx_=2 and _statnam_='GM_LCLM' and trt0='0.7'), expect=1, desc=C16 geometric lower confidence limit);
%_qc_rows(ds=o16, where=%str(_statidx_=3 and _statnam_='GM_UCLM' and trt0='11.7'), expect=1, desc=C16 geometric upper confidence limit);
%_qc_rows(ds=o16, where=%str(_statidx_=4 and _statnam_='GM_CLM' and _statlab_='GM 95% CI' and trt0='0.7, 11.7'), expect=1, desc=C16 geometric confidence interval pair);
%_qc_rows(ds=o16, where=%str(_statidx_=5 and _statnam_='GM_STD' and trt0='2.8(2.45)'), expect=1, desc=C16 geometric mean and CV pair);
%_qc_rows(ds=o16, where=%str(_statidx_=6 and _statnam_='GM_STDDEV' and trt0='2.45'), expect=1, desc=C16 geometric standard deviation);
%_qc_rows(ds=o16, where=%str(_statidx_=7 and _statnam_='GM_CV' and trt0='110.78'), expect=1, desc=C16 geometric coefficient of variation);
%_qc_rows(ds=o16, where=%str(_statidx_=8 and _statnam_='N' and trt0='6'), expect=1, desc=C16 N counts non-missing values);
%_qc_rows(ds=o16, where=%str(_statidx_=9 and _statnam_='NMISS' and trt0='0'), expect=1, desc=C16 NMISS ignores non-positive values);

/*----------------------------------------------------------------------------
 * CASE 17 : RAWDECSOURCE=OVERALL and BY
 *--------------------------------------------------------------------------*/
%qc_case(desc=17 raw decimal source overall and by group);
%stat_summaryn(data=sn_dec, out=o17a, by=grp, var=x, rawdecsource=overall);
%stat_summaryn(data=sn_dec, out=o17b, by=grp, var=x, rawdecsource=by);
%_qc_rows(ds=o17a, where=%str(grp='A' and _statidx_=2 and trt0='2.000(1.0000)'), expect=1, desc=C17 overall source uses widest decimals for group A);
%_qc_rows(ds=o17a, where=%str(grp='B' and _statidx_=2 and trt0='2.250(1.0000)'), expect=1, desc=C17 overall source uses widest decimals for group B);
%_qc_rows(ds=o17b, where=%str(grp='A' and _statidx_=2 and trt0='2.0(1.00)'), expect=1, desc=C17 by source uses group A decimals);
%_qc_rows(ds=o17b, where=%str(grp='B' and _statidx_=2 and trt0='2.250(1.0000)'), expect=1, desc=C17 by source uses group B decimals);

/*----------------------------------------------------------------------------
 * CASE 18 : custom format on CLASS= - unobserved level reported
 *--------------------------------------------------------------------------*/
%qc_case(desc=18 custom class format levels);
%stat_summaryn(data=sn_fmt, out=o18, class=sex, var=age);
%qc_expect_nobs(ds=o18, expect=5, desc=C18 one row per statistic);
%qc_expect_var(ds=o18, var=trt3, type=C, desc=C18 unobserved level column created);
%_qc_rows(ds=o18, where=%str(_statidx_=1 and trt0='6(0)' and trt1='3(0)' and trt2='3(0)' and trt3='0(0)'), expect=1, desc=C18 counts for all format levels);
%_qc_rows(ds=o18, where=%str(_statidx_=2 and trt1='12.7(3.06)' and trt2='17.3(3.06)' and trt3='N/A(N/A)'), expect=1, desc=C18 unobserved level shows N/A);
%_qc_lbl(ds=o18, var=trt3, mac=_l18);
%qc_check_eq(actual=&_l18., expect=Unknown@(N=0), desc=C18 formatted label used for column);

/*----------------------------------------------------------------------------
 * CASE 19 : library qualified OUT=
 *--------------------------------------------------------------------------*/
%qc_case(desc=19 library qualified output dataset);
libname qcstat "&_QCRES_.";
%stat_summaryn(data=sn_base, out=qcstat.stat_summaryn_o19, class=trt, var=age);
%qc_expect_ds(ds=qcstat.stat_summaryn_o19, desc=C19 output created in permanent library);
%qc_expect_nobs(ds=qcstat.stat_summaryn_o19, expect=5, desc=C19 permanent output rows);
%_qc_rows(ds=qcstat.stat_summaryn_o19, where=%str(_statidx_=2 and trt0='20.0(6.63)' and trt1='14.0(3.16)'), expect=1, desc=C19 permanent output values);
libname qcstat clear;

/*----------------------------------------------------------------------------
 * CASE 20 : single class level forces TEST= to NONE
 *--------------------------------------------------------------------------*/
%qc_case(desc=20 single class level forces test to none);
%stat_summaryn(data=sn_one, out=o20, class=trt, var=x, test=par);
%qc_expect_nobs(ds=o20, expect=5, desc=C20 output rows);
%_qc_nov(ds=o20, var=_testv_, mac=_n20);
%qc_check_eq(actual=&_n20., expect=0, desc=C20 test columns dropped);
%_qc_rows(ds=o20, where=%str(_statidx_=2 and trt0='2.0(1.00)' and trt1='2.0(1.00)'), expect=1, desc=C20 overall statistics retained);

/*----------------------------------------------------------------------------
 * CASE 21 : CLASS= entirely missing - overall analysis
 *--------------------------------------------------------------------------*/
%qc_case(desc=21 class variable entirely missing);
%stat_summaryn(data=sn_misscls, out=o21, class=trt, var=x);
%qc_expect_nobs(ds=o21, expect=5, desc=C21 overall analysis rows);
%_qc_rows(ds=o21, where=%str(_statidx_=1 and trt0='4(0)' and trt1='4(0)'), expect=1, desc=C21 all records counted once);
%_qc_rows(ds=o21, where=%str(_statidx_=2 and trt1='2.5(1.29)'), expect=1, desc=C21 overall mean and SD);
%_qc_lbl(ds=o21, var=trt1, mac=_l21);
%qc_check_eq(actual=&_l21., expect=Overall@(N=4), desc=C21 overall column label);

/*----------------------------------------------------------------------------
 * CASE 22 : VAR= entirely missing
 *--------------------------------------------------------------------------*/
%qc_case(desc=22 analysis variable entirely missing);
%stat_summaryn(data=sn_missvar, out=o22, class=trt, var=x);
%qc_expect_nobs(ds=o22, expect=5, desc=C22 one row per statistic);
%_qc_rows(ds=o22, where=%str(_statidx_=1 and trt0='0(4)' and trt1='0(2)' and trt2='0(2)'), expect=1, desc=C22 N and NMISS for all-missing variable);
%_qc_rows(ds=o22, where=%str(_statidx_=2 and trt0='N/A(N/A)' and trt1='N/A(N/A)' and trt2='N/A(N/A)'), expect=1, desc=C22 mean and SD shown as N/A);
%_qc_rows(ds=o22, where=%str(_statidx_=5 and trt0='N/A, N/A'), expect=1, desc=C22 min and max shown as N/A);

/*----------------------------------------------------------------------------
 * CASE 23 : single observation
 *--------------------------------------------------------------------------*/
%qc_case(desc=23 single observation input);
%stat_summaryn(data=sn_single, out=o23, var=x);
%qc_expect_nobs(ds=o23, expect=5, desc=C23 one row per statistic);
%_qc_rows(ds=o23, where=%str(_statidx_=1 and trt0='1(0)' and trt1='1(0)'), expect=1, desc=C23 single record counted);
%_qc_rows(ds=o23, where=%str(_statidx_=2 and trt0='5.0(N/A)'), expect=1, desc=C23 missing standard deviation shown as N/A);
%_qc_rows(ds=o23, where=%str(_statidx_=4 and trt0='5.0, 5.0'), expect=1, desc=C23 single record quartiles);
%_qc_rows(ds=o23, where=%str(_statidx_=5 and trt0='5, 5'), expect=1, desc=C23 single record min and max);

/*----------------------------------------------------------------------------
 * CASE 24 : DEBUG=1 keeps intermediates, later DEBUG=0 removes them
 *--------------------------------------------------------------------------*/
%qc_case(desc=24 debug keeps and releases intermediate datasets);
%stat_summaryn(data=sn_base, out=o24, class=trt, var=age, debug=1);
%qc_check_eq(actual=%sysfunc(exist(work.stat_summaryn_dsin)), expect=1, desc=C24 dsin intermediate kept);
%qc_check_eq(actual=%sysfunc(exist(work.stat_summaryn_summary)), expect=1, desc=C24 summary intermediate kept);
%qc_check_eq(actual=%sysfunc(exist(work.stat_summaryn_final)), expect=1, desc=C24 final intermediate kept);
%stat_summaryn(data=sn_base, out=o24b, class=trt, var=age);
%qc_check_eq(actual=%sysfunc(exist(work.stat_summaryn_dsin)), expect=0, desc=C24 later DEBUG=0 removes dsin);
%qc_check_eq(actual=%sysfunc(exist(work.stat_summaryn_final)), expect=0, desc=C24 later DEBUG=0 removes final);

/*----------------------------------------------------------------------------
 * CASE 25 : MED_Q1_Q3 composite statistic
 *--------------------------------------------------------------------------*/
%qc_case(desc=25 median with quartiles composite);
%stat_summaryn(data=sn_med, out=o25, var=x, statis=med_q1_q3 median q1 q3);
%qc_expect_nobs(ds=o25, expect=4, desc=C25 one row per statistic);
%_qc_rows(ds=o25, where=%str(_statidx_=1 and _statnam_='MED_Q1_Q3' and _statlab_='Median(Q1,Q3)' and trt0='3.0(2.0, 4.0)'), expect=1, desc=C25 median and quartile pair);
%_qc_rows(ds=o25, where=%str(_statidx_=2 and trt0='3.0'), expect=1, desc=C25 median value);
%_qc_rows(ds=o25, where=%str(_statidx_=3 and trt0='2.0'), expect=1, desc=C25 first quartile);
%_qc_rows(ds=o25, where=%str(_statidx_=4 and trt0='4.0'), expect=1, desc=C25 third quartile);

/*----------------------------------------------------------------------------
 * CASE 26 : TEST=PAR with one observation per group - no test is computable
 *--------------------------------------------------------------------------*/
%qc_case(desc=26 one observation per group has no test);
%stat_summaryn(data=sn_n1, out=o26, class=trt, var=x, test=par);
%qc_expect_nobs(ds=o26, expect=5, desc=C26 output rows);
%_qc_rows(ds=o26, where=%str(_statidx_=1 and _testm_='N/A'), expect=1, desc=C26 method shown as N/A);
%_qc_rows(ds=o26, where=%str(_statidx_=1 and missing(_testp_)), expect=1, desc=C26 p value is missing);
%_qc_rows(ds=o26, where=%str(_statidx_>1 and _testm_=''), expect=4, desc=C26 test columns cleared on later rows);

%qc_end;
