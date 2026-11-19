/*==============================================================================
 * stat_rateci_test.sas - Positive (functional) acceptance tests
 *==============================================================================
 * Macro under test : %stat_rateci
 * File under test   : dev/stat/stat_rateci.sas
 * Dependencies      : %var_exist, %var_coexist, %ds_attr
 * Coverage          : single sample rate and confidence limits (EXACT / WALD /
 *                     WILSON / AC / BLAKER / JEFFREYS / LR / LOGIT / MIDP),
 *                     SMETHOD=ALL, pairwise rate difference with WALD /
 *                     NEWCOMBE / AC / MN / HA / EXACT, SMETHOD=NONE and
 *                     DMETHOD=NONE switches, 3 class levels, BY= processing
 *                     (one and two BY variables), custom format on VAR=,
 *                     missing response exclusion, numeric and character CLASS,
 *                     SALPHA / DALPHA, output structure / labels / lengths,
 *                     library-qualified OUT=, DEBUG= cleanup, LEVEL=N.
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

%qc_begin(prog=stat_rateci_test, macro=stat_rateci);

/* helper: read a variable label through PROC CONTENTS */
%macro _qc_label(ds=, var=, mac=);
  %global &mac.;
  proc contents data=&ds. out=_qc_meta noprint;
  run;
  data _null_;
    set _qc_meta;
    if upcase(name)=upcase("&var.") then call symputx("&mac.", label);
  run;
%mend _qc_label;

/*----------------------------------------------------------------------------
 * Shared input data (BY= study is a single level, so results equal the
 * ungrouped case):
 *   trt A : 20 subjects, 5 with resp=Y  -> 25.0 %
 *   trt B : 20 subjects, 11 with resp=Y -> 55.0 %
 *   by sex: A = 20.0 / 30.0, B = 50.0 / 60.0
 *--------------------------------------------------------------------------*/
data rates;
  length subj $12 study $2 trt $1 sex $1 resp $1;
  retain _k 0;
  input study $ trt $ sex $ resp $ n;
  do i=1 to n;
    _k+1;
    subj=cats(trt,sex,_k);
    output;
  end;
  drop n i;
datalines;
S1 A M Y 3
S1 A M N 7
S1 A F Y 2
S1 A F N 8
S1 B M Y 6
S1 B M N 4
S1 B F Y 5
S1 B F N 5
;
run;

/*----------------------------------------------------------------------------
 * CASE 1 : default SMETHOD=EXACT / DMETHOD=WALD - rate, exact confidence
 *          limit, pairwise Wald difference, output structure
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 default exact rate and Wald rate difference);
%stat_rateci(data=rates, out=r1, by=study, class=trt, var=resp, level=%str('Y'), debug=0);

%qc_expect_ds(ds=r1, desc=C1 output dataset exists);
%qc_expect_nobs(ds=r1, expect=4, desc=C1 two single rows and two difference rows);
%qc_expect_var(ds=r1, var=study, type=C, desc=C1 BY variable kept);
%qc_expect_var(ds=r1, var=trt, type=C, desc=C1 CLASS variable kept);
%qc_expect_var(ds=r1, var=ref_trt, type=C, desc=C1 reference class variable created);
%qc_expect_var(ds=r1, var=_method_, type=C, desc=C1 method variable character);
%qc_expect_var(ds=r1, var=_prop_, type=N, desc=C1 rate variable numeric);
%qc_expect_var(ds=r1, var=_alpha_, type=N, desc=C1 alpha variable numeric);
%qc_expect_var(ds=r1, var=_cl_l_, type=N, desc=C1 lower limit numeric);
%qc_expect_var(ds=r1, var=_cl_u_, type=N, desc=C1 upper limit numeric);
%qc_expect_var(ds=r1, var=_source_, type=C, desc=C1 source variable character);

proc sql noprint;
  select count(*) into :c1a from r1
    where trt='A' and missing(ref_trt) and _method_='Exact'
      and strip(put(_prop_,8.1))='25.0'
      and strip(put(_cl_l_,8.2))='8.66' and strip(put(_cl_u_,8.2))='49.10'
      and strip(put(_alpha_,8.2))='0.05' and _source_='PROC FREQ';
  select count(*) into :c1b from r1
    where trt='B' and missing(ref_trt) and _method_='Exact'
      and strip(put(_prop_,8.1))='55.0'
      and strip(put(_cl_l_,8.2))='31.53' and strip(put(_cl_u_,8.2))='76.94';
  select count(*) into :c1c from r1
    where trt='A' and ref_trt='B' and _method_='Wald'
      and strip(put(_prop_,8.1))='-30.0'
      and strip(put(_cl_l_,8.2))='-58.91' and strip(put(_cl_u_,8.2))='-1.09';
  select count(*) into :c1d from r1
    where trt='B' and ref_trt='A' and _method_='Wald'
      and strip(put(_prop_,8.1))='30.0'
      and strip(put(_cl_l_,8.2))='1.09' and strip(put(_cl_u_,8.2))='58.91';
quit;
%qc_check_eq(actual=&c1a., expect=1, desc=C1 class A exact rate and limit);
%qc_check_eq(actual=&c1b., expect=1, desc=C1 class B exact rate and limit);
%qc_check_eq(actual=&c1c., expect=1, desc=C1 difference A minus B and Wald limit);
%qc_check_eq(actual=&c1d., expect=1, desc=C1 difference B minus A and Wald limit);

/*----------------------------------------------------------------------------
 * CASE 2 : all nine single sample confidence limit types
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 nine single sample confidence limit types);
%stat_rateci(data=rates, out=r2, by=study, class=trt, var=resp, level=%str('Y'),
             smethod=WALD WILSON EXACT JEFFREYS AC BLAKER LR LOGIT MIDP,
             dmethod=NONE, debug=0);
%qc_expect_nobs(ds=r2, expect=18, desc=C2 nine methods for each of two classes);
data _null_;
  length _s $200;
  do until(_e);
    set r2 end=_e;
    if trt='A' then _s=catx(' ', _s, _method_);
  end;
  call symputx('c2seq', _s);
run;
%let c2exp=Agresti-Coull Blaker Exact Jeffreys Likelihood Ratio Logit Mid-p Wald Wilson;
%qc_check_eq(actual=&c2seq., expect=&c2exp., desc=C2 method names sorted and complete);
proc sql noprint;
  select count(*) into :c2n from dictionary.columns
    where libname='WORK' and memname='R2' and upcase(name)='REF_TRT';
  select count(*) into :c2v from r2
    where trt='A' and _method_='Blaker'
      and strip(put(_cl_l_,8.2))='10.41' and strip(put(_cl_u_,8.2))='47.40';
quit;
%qc_check_eq(actual=&c2n., expect=0, desc=C2 no reference variable when DMETHOD=NONE);
%qc_check_eq(actual=&c2v., expect=1, desc=C2 Blaker limit computed for class A);

/*----------------------------------------------------------------------------
 * CASE 3 : SMETHOD=ALL - requests every limit PROC FREQ computes in one call
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 smethod ALL option);
%stat_rateci(data=rates, out=r3, by=study, class=trt, var=resp, level=%str('Y'),
             smethod=ALL, dmethod=NONE, debug=0);
proc sql noprint;
  select count(*) into :c3ac from r3 where trt='A' and _method_='Agresti-Coull';
  select count(*) into :c3ex from r3 where trt='A' and _method_='Exact';
  select count(*) into :c3je from r3 where trt='A' and _method_='Jeffreys';
  select count(*) into :c3wa from r3 where trt='A' and _method_='Wald';
  select count(*) into :c3wi from r3 where trt='A' and _method_='Wilson';
quit;
%qc_check_eq(actual=&c3ac., expect=1, desc=C3 Agresti-Coull computed by ALL);
%qc_check_eq(actual=&c3ex., expect=1, desc=C3 Exact computed by ALL);
%qc_check_eq(actual=&c3je., expect=1, desc=C3 Jeffreys computed by ALL);
%qc_check_eq(actual=&c3wa., expect=1, desc=C3 Wald computed by ALL);
%qc_check_eq(actual=&c3wi., expect=1, desc=C3 Wilson computed by ALL);

/*----------------------------------------------------------------------------
 * CASE 4 : SMETHOD=NONE - only the pairwise rate difference is produced
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 smethod NONE keeps only rate difference);
%stat_rateci(data=rates, out=r4, by=study, class=trt, var=resp, level=%str('Y'),
             smethod=NONE, dmethod=WALD, debug=0);
%qc_expect_nobs(ds=r4, expect=2, desc=C4 only the two difference rows);
proc sql noprint;
  select count(*) into :c4s from r4 where missing(ref_trt);
  select count(*) into :c4d from r4
    where trt='A' and ref_trt='B' and strip(put(_prop_,8.1))='-30.0';
quit;
%qc_check_eq(actual=&c4s., expect=0, desc=C4 no single sample rows);
%qc_check_eq(actual=&c4d., expect=1, desc=C4 rate difference still computed);

/*----------------------------------------------------------------------------
 * CASE 5 : DMETHOD=NONE - only the single sample rate is produced
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 dmethod NONE keeps only single rate);
%stat_rateci(data=rates, out=r5, by=study, class=trt, var=resp, level=%str('Y'),
             smethod=WALD, dmethod=NONE, debug=0);
%qc_expect_nobs(ds=r5, expect=2, desc=C5 only the two single sample rows);
proc sql noprint;
  select count(*) into :c5n from dictionary.columns
    where libname='WORK' and memname='R5' and upcase(name)='REF_TRT';
  select count(*) into :c5v from r5
    where trt='A' and strip(put(_prop_,8.1))='25.0'
      and strip(put(_cl_l_,8.2))='6.02' and strip(put(_cl_u_,8.2))='43.98';
quit;
%qc_check_eq(actual=&c5n., expect=0, desc=C5 reference variable absent);
%qc_check_eq(actual=&c5v., expect=1, desc=C5 Wald rate limit of class A);

/*----------------------------------------------------------------------------
 * CASE 6 : six rate difference methods in one call
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 six rate difference methods in one call);
%stat_rateci(data=rates, out=r6, by=study, class=trt, var=resp, level=%str('Y'),
             smethod=NONE, dmethod=WALD NEWCOMBE AC MN HA EXACT, debug=0);
%qc_expect_nobs(ds=r6, expect=12, desc=C6 six methods for each ordered pair);
proc sql noprint;
  select count(*) into :c6n from r6 where trt='A' and ref_trt='B';
  select count(*) into :c6w from r6
    where trt='A' and ref_trt='B' and _method_='Wald'
      and strip(put(_cl_l_,8.2))='-58.91' and strip(put(_cl_u_,8.2))='-1.09';
  select count(*) into :c6nc from r6
    where trt='A' and ref_trt='B' and _method_='Newcombe'
      and strip(put(_cl_l_,8.2))='-53.64' and strip(put(_cl_u_,8.2))='0.18';
  select count(*) into :c6ac from r6
    where trt='A' and ref_trt='B' and _method_='Agresti-Caffo'
      and strip(put(_cl_l_,8.2))='-55.19' and strip(put(_cl_u_,8.2))='0.64';
  select count(*) into :c6ha from r6
    where trt='A' and ref_trt='B' and _method_='Hauck-Anderson'
      and strip(put(_cl_l_,8.2))='-62.16' and strip(put(_cl_u_,8.2))='2.16';
  select count(*) into :c6mn from r6
    where trt='A' and ref_trt='B' and _method_='Miettinen-Nurminen'
      and strip(put(_cl_l_,8.2))='-55.69' and strip(put(_cl_u_,8.2))='0.76';
quit;
%qc_check_eq(actual=&c6n., expect=6, desc=C6 six methods for pair A versus B);
%qc_check_eq(actual=&c6w., expect=1, desc=C6 Wald difference limit);
%qc_check_eq(actual=&c6nc., expect=1, desc=C6 Newcombe difference limit);
%qc_check_eq(actual=&c6ac., expect=1, desc=C6 Agresti-Caffo difference limit);
%qc_check_eq(actual=&c6ha., expect=1, desc=C6 Hauck-Anderson difference limit);
%qc_check_eq(actual=&c6mn., expect=1, desc=C6 Miettinen-Nurminen difference limit);

/*----------------------------------------------------------------------------
 * CASE 7 : three class levels produce every ordered pair
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 three class levels produce six ordered pairs);
data rates3;
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
S1 A Y 3
S1 A N 7
S1 B Y 5
S1 B N 5
S1 C Y 1
S1 C N 9
;
run;
%stat_rateci(data=rates3, out=r7, by=study, class=trt, var=resp, level=%str('Y'),
             smethod=NONE, dmethod=WALD, debug=0);
%qc_expect_nobs(ds=r7, expect=6, desc=C7 six ordered pairs for three classes);
data _null_;
  length _s $60;
  do until(_e);
    set r7 end=_e;
    _s=catx(' ', _s, cats(trt,ref_trt));
  end;
  call symputx('c7seq', _s);
run;
%let c7exp=AB AC BA BC CA CB;
%qc_check_eq(actual=&c7seq., expect=&c7exp., desc=C7 every ordered class pair present);
proc sql noprint;
  select count(*) into :c7m from r7 where _method_='Wald';
quit;
%qc_check_eq(actual=&c7m., expect=6, desc=C7 one Wald row per ordered pair);

/*----------------------------------------------------------------------------
 * CASE 8 : BY= variable with two levels (single sample rate only)
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 two BY levels single sample rate);
%stat_rateci(data=rates, out=r8, by=sex, class=trt, var=resp, level=%str('Y'),
             smethod=WALD, dmethod=NONE, debug=0);
%qc_expect_nobs(ds=r8, expect=4, desc=C8 one row per BY and CLASS combination);
proc sql noprint;
  select count(*) into :c8a from r8
    where sex='F' and trt='A' and strip(put(_prop_,8.1))='20.0'
      and strip(put(_cl_u_,8.2))='44.79';
  select count(*) into :c8b from r8
    where sex='F' and trt='B' and strip(put(_prop_,8.1))='50.0'
      and strip(put(_cl_l_,8.2))='19.01' and strip(put(_cl_u_,8.2))='80.99';
  select count(*) into :c8c from r8
    where sex='M' and trt='A' and strip(put(_prop_,8.1))='30.0'
      and strip(put(_cl_l_,8.2))='1.60' and strip(put(_cl_u_,8.2))='58.40';
  select count(*) into :c8d from r8
    where sex='M' and trt='B' and strip(put(_prop_,8.1))='60.0'
      and strip(put(_cl_l_,8.2))='29.64' and strip(put(_cl_u_,8.2))='90.36';
quit;
%qc_check_eq(actual=&c8a., expect=1, desc=C8 female class A rate);
%qc_check_eq(actual=&c8b., expect=1, desc=C8 female class B rate);
%qc_check_eq(actual=&c8c., expect=1, desc=C8 male class A rate);
%qc_check_eq(actual=&c8d., expect=1, desc=C8 male class B rate);

/*----------------------------------------------------------------------------
 * CASE 9 : two BY variables
 *--------------------------------------------------------------------------*/
%qc_case(desc=9 two BY variables);
%stat_rateci(data=rates, out=r9, by=study sex, class=trt, var=resp, level=%str('Y'),
             smethod=WALD, dmethod=NONE, debug=0);
%qc_expect_nobs(ds=r9, expect=4, desc=C9 one row per combination of two BY variables);
%qc_expect_var(ds=r9, var=study, type=C, desc=C9 first BY variable kept);
%qc_expect_var(ds=r9, var=sex, type=C, desc=C9 second BY variable kept);
proc sql noprint;
  select count(*) into :c9 from r9
    where study='S1' and sex='M' and trt='A' and strip(put(_prop_,8.1))='30.0';
quit;
%qc_check_eq(actual=&c9., expect=1, desc=C9 value under two BY variables);

/*----------------------------------------------------------------------------
 * CASE 10 : custom format on VAR= - LEVEL= refers to the formatted value
 *--------------------------------------------------------------------------*/
%qc_case(desc=10 custom format on analysis variable);
proc format;
  value $ynfmt 'Y'='Positive' 'N'='Negative';
run;
data fmtdata;
  set rates;
  format resp $ynfmt.;
run;
%stat_rateci(data=fmtdata, out=r10, by=study, class=trt, var=resp,
             level=%str('Positive'), smethod=WALD, dmethod=WALD, debug=0);
%qc_expect_nobs(ds=r10, expect=4, desc=C10 same structure with formatted level);
proc sql noprint;
  select count(*) into :c10a from r10
    where trt='A' and missing(ref_trt) and strip(put(_prop_,8.1))='25.0'
      and strip(put(_cl_l_,8.2))='6.02' and strip(put(_cl_u_,8.2))='43.98';
  select count(*) into :c10b from r10
    where trt='A' and ref_trt='B' and strip(put(_prop_,8.1))='-30.0';
quit;
%qc_check_eq(actual=&c10a., expect=1, desc=C10 formatted level rate and limit);
%qc_check_eq(actual=&c10b., expect=1, desc=C10 difference on formatted level);

/*----------------------------------------------------------------------------
 * CASE 11 : missing response values are excluded from the denominator
 *--------------------------------------------------------------------------*/
%qc_case(desc=11 missing response excluded from denominator);
data miss;
  set rates;
  if subj in ('AM1','BF31') then resp='';
run;
%stat_rateci(data=miss, out=r11, by=sex, class=trt, var=resp, level=%str('Y'),
             smethod=WALD, dmethod=NONE, debug=0);
%qc_expect_nobs(ds=r11, expect=4, desc=C11 all BY and CLASS combinations kept);
proc sql noprint;
  select count(*) into :c11a from r11
    where sex='M' and trt='A' and strip(put(_prop_,8.2))='22.22'
      and strip(put(_cl_u_,8.2))='49.38';
  select count(*) into :c11b from r11
    where sex='F' and trt='B' and strip(put(_prop_,8.2))='44.44'
      and strip(put(_cl_l_,8.2))='11.98' and strip(put(_cl_u_,8.2))='76.91';
  select count(*) into :c11c from r11
    where sex='F' and trt='A' and strip(put(_prop_,8.1))='20.0';
quit;
%qc_check_eq(actual=&c11a., expect=1, desc=C11 missing subject excluded from class A);
%qc_check_eq(actual=&c11b., expect=1, desc=C11 missing subject excluded from class B);
%qc_check_eq(actual=&c11c., expect=1, desc=C11 unaffected class keeps original denominator);

/*----------------------------------------------------------------------------
 * CASE 12 : variable labels and lengths of the output
 *--------------------------------------------------------------------------*/
%qc_case(desc=12 output labels and lengths);
%qc_expect_len(ds=r1, var=_method_, expect=200, desc=C12 method length 200);
%qc_expect_len(ds=r1, var=_source_, expect=200, desc=C12 source length 200);
%_qc_label(ds=r1, var=_prop_, mac=c12lp);
%_qc_label(ds=r1, var=_cl_l_, mac=c12ll);
%_qc_label(ds=r1, var=_cl_u_, mac=c12lu);
%qc_check_eq(actual=&c12lp., expect=Rate and Rate Difference, desc=C12 label of rate);
%qc_check_eq(actual=&c12ll., expect=Confidence Limit Lower, desc=C12 label of lower limit);
%qc_check_eq(actual=&c12lu., expect=Confidence Limit Upper, desc=C12 label of upper limit);

/*----------------------------------------------------------------------------
 * CASE 13 : SALPHA / DALPHA drive the confidence level per row
 *--------------------------------------------------------------------------*/
%qc_case(desc=13 SALPHA and DALPHA options);
%stat_rateci(data=rates, out=r13, by=study, class=trt, var=resp, level=%str('Y'),
             smethod=WALD, dmethod=WALD, salpha=0.1, dalpha=0.2, debug=0);
proc sql noprint;
  select count(*) into :c13a from r13
    where trt='A' and missing(ref_trt) and strip(put(_alpha_,8.2))='0.10'
      and strip(put(_cl_l_,8.2))='9.07' and strip(put(_cl_u_,8.2))='40.93';
  select count(*) into :c13b from r13
    where trt='A' and ref_trt='B' and strip(put(_alpha_,8.2))='0.20'
      and strip(put(_cl_l_,8.2))='-48.90' and strip(put(_cl_u_,8.2))='-11.10';
quit;
%qc_check_eq(actual=&c13a., expect=1, desc=C13 single rate uses SALPHA);
%qc_check_eq(actual=&c13b., expect=1, desc=C13 difference uses DALPHA);

/*----------------------------------------------------------------------------
 * CASE 14 : library qualified OUT=
 *--------------------------------------------------------------------------*/
%qc_case(desc=14 library qualified OUT);
libname qcstat "&_QCRES_.";
%stat_rateci(data=rates, out=qcstat.rateci_lib, by=study, class=trt, var=resp,
             level=%str('Y'), smethod=WALD, dmethod=WALD, debug=0);
%qc_expect_ds(ds=qcstat.rateci_lib, desc=C14 library qualified output exists);
%qc_expect_nobs(ds=qcstat.rateci_lib, expect=4, desc=C14 library qualified output rows);
%qc_expect_var(ds=qcstat.rateci_lib, var=_prop_, type=N, desc=C14 output structure kept);

/*----------------------------------------------------------------------------
 * CASE 15 : DEBUG= keeps or deletes the intermediate datasets
 *--------------------------------------------------------------------------*/
%qc_case(desc=15 DEBUG keeps intermediate datasets);
%stat_rateci(data=rates, out=r15, by=study, class=trt, var=resp, level=%str('Y'),
             smethod=WALD, dmethod=WALD, debug=1);
%qc_expect_ds(ds=stat_rateci_freq, desc=C15 frequency dataset kept when DEBUG=1);
%qc_expect_ds(ds=stat_rateci_single2, desc=C15 single sample dataset kept when DEBUG=1);
%qc_expect_ds(ds=stat_rateci_diff2, desc=C15 difference dataset kept when DEBUG=1);
%stat_rateci(data=rates, out=r15b, by=study, class=trt, var=resp, level=%str('Y'),
             smethod=WALD, dmethod=WALD, debug=0);
proc sql noprint;
  select count(*) into :c15x from dictionary.tables
    where libname='WORK' and memname like 'STAT_RATECI%';
quit;
%qc_check_eq(actual=&c15x., expect=0, desc=C15 intermediate datasets removed when DEBUG=0);

/*----------------------------------------------------------------------------
 * CASE 16 : LEVEL= selects the other response level (complementary rate)
 *--------------------------------------------------------------------------*/
%qc_case(desc=16 LEVEL option selects the other level);
%stat_rateci(data=rates, out=r16, by=sex, class=trt, var=resp, level=%str('N'),
             smethod=WALD, dmethod=NONE, debug=0);
%qc_expect_nobs(ds=r16, expect=4, desc=C16 four rows for level N);
proc sql noprint;
  select count(*) into :c16a from r16
    where sex='F' and trt='A' and strip(put(_prop_,8.1))='80.0'
      and strip(put(_cl_l_,8.2))='55.21' and strip(put(_cl_u_,8.2))='100.00';
  select count(*) into :c16b from r16
    where sex='F' and trt='B' and strip(put(_prop_,8.1))='50.0';
  select count(*) into :c16c from r16
    where sex='M' and trt='A' and strip(put(_prop_,8.1))='70.0'
      and strip(put(_cl_l_,8.2))='41.60' and strip(put(_cl_u_,8.2))='98.40';
  select count(*) into :c16d from r16
    where sex='M' and trt='B' and strip(put(_prop_,8.1))='40.0';
quit;
%qc_check_eq(actual=&c16a., expect=1, desc=C16 female class A at level N);
%qc_check_eq(actual=&c16b., expect=1, desc=C16 female class B at level N);
%qc_check_eq(actual=&c16c., expect=1, desc=C16 male class A at level N);
%qc_check_eq(actual=&c16d., expect=1, desc=C16 male class B at level N);

/*----------------------------------------------------------------------------
 * CASE 17 : numeric CLASS variable (numeric WHERE= branch for the pairs)
 *--------------------------------------------------------------------------*/
%qc_case(desc=17 numeric CLASS variable);
data numcls;
  set rates;
  trtn=ifn(trt='A',1,2);
  drop trt;
run;
%stat_rateci(data=numcls, out=r17, by=study, class=trtn, var=resp, level=%str('Y'),
             smethod=WALD, dmethod=WALD, debug=0);
%qc_expect_nobs(ds=r17, expect=4, desc=C17 numeric class accepted);
%qc_expect_var(ds=r17, var=trtn, type=N, desc=C17 numeric class variable kept);
%qc_expect_var(ds=r17, var=ref_trtn, type=N, desc=C17 numeric reference variable created);
proc sql noprint;
  select count(*) into :c17a from r17
    where trtn=1 and missing(ref_trtn) and strip(put(_prop_,8.1))='25.0';
  select count(*) into :c17d from r17
    where trtn=1 and ref_trtn=2 and strip(put(_prop_,8.1))='-30.0';
quit;
%qc_check_eq(actual=&c17a., expect=1, desc=C17 numeric class rate);
%qc_check_eq(actual=&c17d., expect=1, desc=C17 numeric class difference);

%qc_end;
