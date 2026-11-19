/*==============================================================================
 * stat_countocc_test.sas - Positive (functional) acceptance tests
 *==============================================================================
 * Macro under test : %stat_countocc
 * File under test   : dev/stat/stat_countocc.sas
 * Dependencies      : %var_exist, %var_coexist, %ds_attr
 * Coverage          : subject / event counts, denominator handling, missing
 *                     class exclusion, missing code imputation (UNCODE=),
 *                     cumulative (_TOTAL_) rows, multi-variable capture
 *                     hierarchy, custom UNCODE= / TOTCODELAB=, PCTFMT=,
 *                     SORTCLASSNUM=, TEST=NONE / CHISQ / FISHER / AUTO,
 *                     single class level warning path, numeric CLASS=,
 *                     custom CLASS= / SUBJECT=, output labels, sort order,
 *                     library-qualified OUT=, intermediate cleanup,
 *                     CODE= truncation warnings (UNCODE= / TOTCODELAB=).
 *                     The 0-observation abort paths are negative tests
 *                     (stat_countocc_err_16 / err_17).
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
%include "&_QCDEV_STAT_.\stat_countocc.sas";

%qc_begin(prog=stat_countocc_test, macro=stat_countocc);

/* helper: read a variable label through PROC CONTENTS (selecting the LABEL
 * column of dictionary.columns by name returns no rows in this SAS release) */
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
 * Shared input data
 *   treatment A : S1..S5 (5 subjects, S1-S3 with events, S4-S5 without)
 *   treatment B : S6..S8 (3 subjects, all with events)
 *   S9 has missing treatment -> must be excluded from every denominator
 *   S2 has the same event twice  -> counts as 1 subject but 2 events
 *   S8 has a missing AEDECOD     -> imputed with UNCODE=
 *--------------------------------------------------------------------------*/
data adae;
  length usubjid $10 trt $3 aebodsys $20 aedecod $20;
  input usubjid $ trt $ aebodsys $ aedecod $;
  datalines;
S1 A SOC1 PT1
S2 A SOC2 PT2
S2 A SOC2 PT2
S3 A SOC2 PT3
S6 B SOC1 PT1
S7 B SOC1 PT2
S8 B SOC2 PT9
S8 B SOC3 .
;
run;
data adsl;
  length usubjid $10 trt $3;
  input usubjid $ trt $;
  datalines;
S1 A
S2 A
S3 A
S4 A
S5 A
S6 B
S7 B
S8 B
S9 .
;
run;

/*----------------------------------------------------------------------------
 * CASE 1 : two code variables, TEST=NONE - counts, percents, denominators,
 *          labels, cumulative rows, missing-code row, sort order, cleanup
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 two code variables counts percents labels and order);
%stat_countocc(data=adae, denom=adsl, out=r1, class=trt, code=aebodsys aedecod, test=none);

%qc_expect_ds(ds=r1, desc=C1 output dataset exists);
%qc_expect_nobs(ds=r1, expect=10, desc=C1 one row per code combination);
%qc_expect_var(ds=r1, var=aebodsys, type=C, desc=C1 aebodsys kept as char);
%qc_expect_var(ds=r1, var=aedecod, type=C, desc=C1 aedecod kept as char);
%qc_expect_var(ds=r1, var=ns0, type=N, desc=C1 ns0 numeric);
%qc_expect_var(ds=r1, var=nsp0, type=C, desc=C1 nsp0 char combined count and percent);
%qc_expect_var(ds=r1, var=nsp1, type=C, desc=C1 nsp1 char combined count and percent);
%qc_expect_var(ds=r1, var=nsp2, type=C, desc=C1 nsp2 char combined count and percent);
%qc_expect_len(ds=r1, var=nsp1, expect=20, desc=C1 nsp1 length 20);

proc sql noprint;
  select count(*) into :c1tot from r1
    where aebodsys='_TOTAL_' and aedecod='_TOTAL_'
      and ns0=6 and ne0=8 and ns1=3 and ne1=4 and ns2=3 and ne2=4
      and strip(put(np0,8.1))='75.0' and strip(put(np1,8.1))='60.0' and strip(put(np2,8.1))='100.0'
      and nsp0='6(75.0)' and nsp1='3(60.0)' and nsp2='3(100.0)';
  select count(*) into :c1soc1 from r1
    where aebodsys='SOC1' and aedecod='_TOTAL_'
      and ns0=3 and ne0=3 and ns1=1 and ne1=1 and ns2=2 and ne2=2
      and nsp1='1(20.0)' and nsp2='2(66.7)';
  select count(*) into :c1soc2 from r1
    where aebodsys='SOC2' and aedecod='_TOTAL_'
      and ns0=3 and ne0=4 and ns1=2 and ne1=3 and ns2=1 and ne2=1
      and nsp1='2(40.0)' and nsp2='1(33.3)';
  select count(*) into :c1soc3 from r1
    where aebodsys='SOC3' and aedecod='_TOTAL_'
      and ns0=1 and ns1=0 and ns2=1 and nsp1='0(0.0)' and nsp2='1(33.3)';
  select count(*) into :c1unc from r1
    where aebodsys='SOC3' and aedecod='UNCODED'
      and ns0=1 and ns1=0 and ns2=1 and ne2=1;
  select count(*) into :c1dup from r1
    where aebodsys='SOC2' and aedecod='PT2' and ns1=1 and ne1=2;
  select count(*) into :c1tmp from dictionary.tables
    where libname='WORK' and memname like 'STAT_COUNTOCC%';
quit;
%_qc_label(ds=r1, var=NS0, mac=c1lb0);
%_qc_label(ds=r1, var=NSP1, mac=c1lb1);


%qc_check_eq(actual=&c1tot., expect=1, desc=C1 grand total row counts and percents);
%qc_check_eq(actual=&c1soc1., expect=1, desc=C1 SOC1 total row);
%qc_check_eq(actual=&c1soc2., expect=1, desc=C1 SOC2 total row);
%qc_check_eq(actual=&c1soc3., expect=1, desc=C1 SOC3 total row with zero class A);
%qc_check_eq(actual=&c1unc., expect=1, desc=C1 missing code imputed as UNCODED);
%qc_check_eq(actual=&c1dup., expect=1, desc=C1 duplicate event counted once as subject);
%qc_check_eq(actual=&c1lb0., expect=Number of Subjects, desc=C1 label ns0);
%qc_check_eq(actual=&c1lb1., expect=Number and Percent of Subjects of A, desc=C1 label nsp1);
%qc_check_eq(actual=&c1tmp., expect=0, desc=C1 intermediate datasets removed);

data _null_;
  length _s $200;
  do until(_e);
    set r1 end=_e;
    _s=catx(' ', _s, cats(aebodsys, '/', aedecod));
  end;
  call symputx('c1seq', _s);
run;
%let c1exp=_TOTAL_/_TOTAL_ SOC1/_TOTAL_ SOC1/PT1 SOC1/PT2 SOC2/_TOTAL_ SOC2/PT2 SOC2/PT3 SOC2/PT9 SOC3/_TOTAL_ SOC3/UNCODED;
%qc_check_eq(actual=&c1seq., expect=&c1exp., desc=C1 total first uncoded last then by subjects);

/*----------------------------------------------------------------------------
 * CASE 2 : single code variable, default TEST= and default SUBJECT=USUBJID
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 single code variable with default TEST and SUBJECT);
%stat_countocc(data=adae, denom=adsl, out=r2, class=trt, code=aebodsys);

%qc_expect_nobs(ds=r2, expect=4, desc=C2 four rows for total and three levels);
%qc_expect_var(ds=r2, var=ns2, type=N, desc=C2 ns2 numeric);
data _null_;
  length _s $100;
  do until(_e);
    set r2 end=_e;
    _s=catx(' ', _s, aebodsys);
  end;
  call symputx('c2seq', _s);
run;
%let c2exp=_TOTAL_ SOC1 SOC2 SOC3;
%qc_check_eq(actual=&c2seq., expect=&c2exp., desc=C2 row order total first);

proc sql noprint;
  select count(*) into :c2 from r2
    where aebodsys='_TOTAL_'
      and ns0=6 and ne0=8 and ns1=3 and ne1=4 and ns2=3 and ne2=4
      and nsp1='3(60.0)' and nsp2='3(100.0)';
  select count(*) into :c2b from r2
    where aebodsys='SOC1' and ns1=1 and ns2=2 and nsp2='2(66.7)';
quit;
%qc_check_eq(actual=&c2., expect=1, desc=C2 total row counts);
%qc_check_eq(actual=&c2b., expect=1, desc=C2 SOC1 row counts);

/*----------------------------------------------------------------------------
 * CASE 3 : three code variables - cumulative hierarchy
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 three code variables cumulative hierarchy);
data ae3code;
  length usubjid $10 trt $3 soc $10 pt $10 sev $10;
  input usubjid $ trt $ soc $ pt $ sev $;
  datalines;
S1 A SOC1 PT1 MILD
S2 B SOC1 PT2 SEVERE
S3 A SOC2 PT3 MILD
;
run;
data dm3code;
  length usubjid $10 trt $3;
  input usubjid $ trt $;
  datalines;
S1 A
S2 B
S3 A
S4 B
;
run;
%stat_countocc(data=ae3code, denom=dm3code, out=r3, class=trt, code=soc pt sev);
%qc_expect_nobs(ds=r3, expect=9, desc=C3 nine rows for three level hierarchy);
data _null_;
  length _s $250;
  do until(_e);
    set r3 end=_e;
    _s=catx(' ', _s, cats(soc, '/', pt, '/', sev));
  end;
  call symputx('c3seq', _s);
run;
%let c3exp=_TOTAL_/_TOTAL_/_TOTAL_ SOC1/_TOTAL_/_TOTAL_ SOC1/PT1/_TOTAL_ SOC1/PT1/MILD SOC1/PT2/_TOTAL_ SOC1/PT2/SEVERE SOC2/_TOTAL_/_TOTAL_ SOC2/PT3/_TOTAL_ SOC2/PT3/MILD;
%qc_check_eq(actual=&c3seq., expect=&c3exp., desc=C3 hierarchy from total to detail);
proc sql noprint;
  select count(*) into :c3 from r3
    where soc='_TOTAL_' and pt='_TOTAL_' and sev='_TOTAL_'
      and ns0=3 and ns1=2 and ns2=1 and nsp0='3(75.0)' and nsp1='2(100.0)' and nsp2='1(50.0)';
  select count(*) into :c3b from r3
    where soc='SOC1' and pt='PT1' and sev='MILD' and ns1=1 and ne1=1;
quit;
%qc_check_eq(actual=&c3., expect=1, desc=C3 grand total row);
%qc_check_eq(actual=&c3b., expect=1, desc=C3 lowest level row);

/*----------------------------------------------------------------------------
 * CASE 4 : three class levels
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 three class levels);
data ae3arm;
  length usubjid $10 trt $3 cod $10;
  input usubjid $ trt $ cod $;
  datalines;
A1 A X
A2 A X
B1 B X
B2 B X
B3 B Y
C1 C X
;
run;
data dm3arm;
  length usubjid $10 trt $3;
  input usubjid $ trt $;
  datalines;
A1 A
A2 A
A3 A
A4 A
B1 B
B2 B
B3 B
C1 C
C2 C
;
run;
%stat_countocc(data=ae3arm, denom=dm3arm, out=r4, class=trt, code=cod);
%qc_expect_nobs(ds=r4, expect=3, desc=C4 total plus two code levels);
%qc_expect_var(ds=r4, var=ns3, type=N, desc=C4 third class statistic exists);
%qc_expect_var(ds=r4, var=nsp3, type=C, desc=C4 third class combined statistic exists);
proc sql noprint;
  select count(*) into :c4 from r4
    where cod='_TOTAL_'
      and ns0=6 and ns1=2 and ns2=3 and ns3=1
      and strip(put(np0,8.1))='66.7' and strip(put(np1,8.1))='50.0'
      and strip(put(np2,8.1))='100.0' and strip(put(np3,8.1))='50.0'
      and nsp3='1(50.0)';
quit;
%_qc_label(ds=r4, var=NS3, mac=c4lb)
%qc_check_eq(actual=&c4lb., expect=Number of Subjects of C, desc=C4 label of third class);
%qc_check_eq(actual=&c4., expect=1, desc=C4 three class counts and percents);

/*----------------------------------------------------------------------------
 * CASE 5 : numeric class variable
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 numeric class variable);
data aenum;
  length usubjid $10 pt $10;
  input usubjid $ sexn pt $;
  datalines;
N1 2 HEAD
N2 1 HEAD
N3 1 BODY
;
run;
data dmenum;
  length usubjid $10;
  input usubjid $ sexn;
  datalines;
N1 2
N2 1
N3 1
N4 2
;
run;
%stat_countocc(data=aenum, denom=dmenum, out=r5, class=sexn, code=pt);
%qc_expect_nobs(ds=r5, expect=3, desc=C5 numeric class accepted);
proc sql noprint;
  select count(*) into :c5 from r5
    where pt='_TOTAL_' and ns0=3 and ns1=2 and ns2=1
      and strip(put(np0,8.1))='75.0' and strip(put(np1,8.1))='100.0' and strip(put(np2,8.1))='50.0';
  select count(*) into :c5b from r5
    where pt='HEAD' and ns0=2 and ns1=1 and ns2=1;
quit;
%_qc_label(ds=r5, var=NS1, mac=c5lb);
%qc_check_eq(actual=&c5lb., expect=Number of Subjects of 1, desc=C5 numeric class label);
%qc_check_eq(actual=&c5., expect=1, desc=C5 numeric class counts);
%qc_check_eq(actual=&c5b., expect=1, desc=C5 numeric class level row);

/*----------------------------------------------------------------------------
 * CASE 6 : custom UNCODE= and TOTCODELAB=
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 custom UNCODE and TOTCODELAB);
%stat_countocc(data=adae, denom=adsl, out=r6, class=trt, code=aebodsys aedecod,
               uncode=NOTCODED, totcodelab=TOTAL);
%qc_expect_nobs(ds=r6, expect=10, desc=C6 row count unchanged);
proc sql noprint;
  select count(*) into :c6 from r6 where aebodsys='TOTAL' and aedecod='TOTAL';
  select count(*) into :c6b from r6 where aebodsys='SOC3' and aedecod='NOTCODED';
quit;
%qc_check_eq(actual=&c6., expect=1, desc=C6 custom total label);
%qc_check_eq(actual=&c6b., expect=1, desc=C6 custom uncoded label);

data _null_;
  length _s $200;
  do until(_e);
    set r6 end=_e;
    _s=catx(' ', _s, cats(aebodsys, '/', aedecod));
  end;
  call symputx('c6seq', _s);
run;
%let c6exp=TOTAL/TOTAL SOC1/TOTAL SOC1/PT1 SOC1/PT2 SOC2/TOTAL SOC2/PT2 SOC2/PT3 SOC2/PT9 SOC3/TOTAL SOC3/NOTCODED;
%qc_check_eq(actual=&c6seq., expect=&c6exp., desc=C6 custom labels keep total first uncoded last);

/*----------------------------------------------------------------------------
 * CASE 7 : PCTFMT= controls percent presentation
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 PCTFMT option);
%stat_countocc(data=adae, denom=adsl, out=r7, class=trt, code=aebodsys, pctfmt=8.2);
proc sql noprint;
  select count(*) into :c7 from r7
    where aebodsys='_TOTAL_'
      and nsp0='6(75.00)' and nsp1='3(60.00)' and nsp2='3(100.00)'
      and strip(put(np0,8.1))='75.0';
  select count(*) into :c7b from r7
    where aebodsys='SOC1' and nsp2='2(66.67)';
quit;
%qc_check_eq(actual=&c7., expect=1, desc=C7 pctfmt 8.2 applied to total row);
%qc_check_eq(actual=&c7b., expect=1, desc=C7 pctfmt 8.2 applied to subgroup);

/*----------------------------------------------------------------------------
 * CASE 8 : SORTCLASSNUM= selects the subgroup used for sorting
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 SORTCLASSNUM options);
%stat_countocc(data=adae, denom=adsl, out=r8a, class=trt, code=aebodsys, sortclassnum=1);
%stat_countocc(data=adae, denom=adsl, out=r8b, class=trt, code=aebodsys, sortclassnum=2);
data _null_;
  length _s $100;
  do until(_e);
    set r8a end=_e;
    _s=catx(' ', _s, aebodsys);
  end;
  call symputx('c8a', _s);
  _s='';
  do until(_e2);
    set r8b end=_e2;
    _s=catx(' ', _s, aebodsys);
  end;
  call symputx('c8b', _s);
run;
%let c8aexp=_TOTAL_ SOC2 SOC1 SOC3;
%let c8bexp=_TOTAL_ SOC1 SOC2 SOC3;
%qc_check_eq(actual=&c8a., expect=&c8aexp., desc=C8 sort by first class);
%qc_check_eq(actual=&c8b., expect=&c8bexp., desc=C8 sort by second class);

/*----------------------------------------------------------------------------
 * CASE 9 : TEST=CHISQ - statistics variables and values
 *--------------------------------------------------------------------------*/
%qc_case(desc=9 chi-square test option);
%stat_countocc(data=adae, denom=adsl, out=r9, class=trt, code=aebodsys, test=chisq);
%qc_expect_var(ds=r9, var=_testv_, type=N, desc=C9 statistic variable exists);
%qc_expect_var(ds=r9, var=_testp_, type=N, desc=C9 p value variable exists);
%qc_expect_var(ds=r9, var=_testm_, type=C, desc=C9 method variable exists);
proc sql noprint;
  select count(*) into :c9 from r9 where _testm_='Chisq';
  select count(*) into :c9b from r9
    where aebodsys='_TOTAL_' and strip(put(_testv_,8.4))='1.6000' and strip(put(_testp_,8.4))='0.2059';
  select count(*) into :c9c from r9
    where aebodsys='SOC2' and strip(put(_testv_,8.4))='0.0356' and strip(put(_testp_,8.4))='0.8504';
quit;
%_qc_label(ds=r9, var=_TESTV_, mac=c9lb);
%qc_check_eq(actual=&c9lb., expect=Statistics, desc=C9 statistic label);
%qc_check_eq(actual=&c9., expect=4, desc=C9 chi-square method on every row);
%qc_check_eq(actual=&c9b., expect=1, desc=C9 chi-square value of grand total row);
%qc_check_eq(actual=&c9c., expect=1, desc=C9 chi-square value of SOC2 row);

/*----------------------------------------------------------------------------
 * CASE 10 : TEST=FISHER - exact test, statistic is missing
 *--------------------------------------------------------------------------*/
%qc_case(desc=10 Fisher exact test option);
%stat_countocc(data=adae, denom=adsl, out=r10, class=trt, code=aebodsys, test=FISHER);
proc sql noprint;
  select count(*) into :c10 from r10 where _testm_='Fisher';
  select count(*) into :c10b from r10 where missing(_testv_);
  select count(*) into :c10c from r10
    where aebodsys='_TOTAL_' and strip(put(_testp_,8.4))='0.4643';
  select count(*) into :c10d from r10
    where aebodsys='SOC2' and strip(put(_testp_,8.4))='1.0000';
quit;
%qc_check_eq(actual=&c10., expect=4, desc=C10 Fisher method on every row);
%qc_check_eq(actual=&c10b., expect=4, desc=C10 Fisher statistic is missing);
%qc_check_eq(actual=&c10c., expect=1, desc=C10 Fisher p value of grand total row);
%qc_check_eq(actual=&c10d., expect=1, desc=C10 Fisher exact p equals 1);

/*----------------------------------------------------------------------------
 * CASE 11 : TEST=AUTO - falls back to Fisher on small tables, keeps Chisq
 *           when the chi-square assumptions hold
 *--------------------------------------------------------------------------*/
%qc_case(desc=11 automatic test selection);
%stat_countocc(data=adae, denom=adsl, out=r11a, class=trt, code=aebodsys, test=auto);
data ae_big;
  length usubjid $10 trt $3 cod $20;
  do i=1 to 100;
    usubjid=cats('A',i); trt='A';
    if i<=50 then do; cod='X'; output; end;
  end;
  do i=1 to 100;
    usubjid=cats('B',i); trt='B';
    if i<=80 then do; cod='X'; output; end;
  end;
run;
data dm_big;
  length usubjid $10 trt $3;
  do i=1 to 100; usubjid=cats('A',i); trt='A'; output; end;
  do i=1 to 100; usubjid=cats('B',i); trt='B'; output; end;
run;
%stat_countocc(data=ae_big, denom=dm_big, out=r11b, class=trt, code=cod, test=auto);
proc sql noprint;
  select count(*) into :c11a from r11a where _testm_='Fisher';
  select count(*) into :c11b from r11b where _testm_='Chisq' and strip(put(_testv_,8.4))='19.7802' and _testp_<0.001;
quit;
%qc_check_eq(actual=&c11a., expect=4, desc=C11 AUTO falls back to Fisher on small table);
%qc_check_eq(actual=&c11b., expect=2, desc=C11 AUTO keeps chi-square on large table);

/*----------------------------------------------------------------------------
 * CASE 12 : single class level with TEST=CHISQ - warning branch, no test vars
 *--------------------------------------------------------------------------*/
%qc_case(desc=12 single class level skips hypothesis test);
data ae_one;
  set ae3code;
  where trt='A';
run;
data dm_one;
  set dm3code;
  where trt='A';
run;
%stat_countocc(data=ae_one, denom=dm_one, out=r12, class=trt, code=soc, test=CHISQ);
%qc_expect_nobs(ds=r12, expect=3, desc=C12 result produced for single class level);
proc sql noprint;
  select count(*) into :c12v from dictionary.columns
    where libname='WORK' and memname='R12'
      and upcase(name) in ('_TESTV_','_TESTP_','_TESTM_');
  select count(*) into :c12 from r12
    where soc='_TOTAL_' and ns0=2 and ns1=2 and strip(put(np0,8.1))='100.0';
quit;
%qc_check_eq(actual=&c12v., expect=0, desc=C12 no test variables for single class level);
%qc_check_eq(actual=&c12., expect=1, desc=C12 counts still computed);

/*----------------------------------------------------------------------------
 * CASE 13 : custom CLASS= and SUBJECT=
 *--------------------------------------------------------------------------*/
%qc_case(desc=13 custom class and subject variables);
data ae_cs;
  length subjid $10 sex $1 pt $10;
  input subjid $ sex $ pt $;
  datalines;
01 M HEAD
02 F HEAD
02 F HEAD
03 F BODY
;
run;
data dm_cs;
  length subjid $10 sex $1;
  input subjid $ sex $;
  datalines;
01 M
02 F
03 F
04 M
;
run;
%stat_countocc(data=ae_cs, denom=dm_cs, out=r13, class=sex, code=pt, subject=subjid);
%qc_expect_nobs(ds=r13, expect=3, desc=C13 custom class and subject accepted);
data _null_;
  length _s $60;
  do until(_e);
    set r13 end=_e;
    _s=catx(' ', _s, pt);
  end;
  call symputx('c13seq', _s);
run;
%let c13exp=_TOTAL_ HEAD BODY;
%qc_check_eq(actual=&c13seq., expect=&c13exp., desc=C13 row order by subject counts);
proc sql noprint;
  select count(*) into :c13 from r13
    where pt='_TOTAL_' and ns0=3 and ns1=2 and ns2=1
      and strip(put(np1,8.1))='100.0' and strip(put(np2,8.1))='50.0';
  select count(*) into :c13b from r13
    where pt='BODY' and ns1=1 and ns2=0;
quit;
%_qc_label(ds=r13, var=NS1, mac=c13lb);
%qc_check_eq(actual=&c13lb., expect=Number of Subjects of F, desc=C13 class label from custom class);
%qc_check_eq(actual=&c13., expect=1, desc=C13 custom class and subject counts);
%qc_check_eq(actual=&c13b., expect=1, desc=C13 subject counted once despite two events);

/*----------------------------------------------------------------------------
 * CASE 14 : library-qualified OUT=
 *--------------------------------------------------------------------------*/
%qc_case(desc=14 library qualified OUT);
libname qcstat "&_QCRES_.";
%stat_countocc(data=adae, denom=adsl, out=qcstat.sc_lib, class=trt, code=aebodsys);
%qc_expect_ds(ds=qcstat.sc_lib, desc=C14 library qualified output exists);
%qc_expect_var(ds=qcstat.sc_lib, var=ns1, type=N, desc=C14 library qualified output structure);
%qc_expect_nobs(ds=qcstat.sc_lib, expect=4, desc=C14 library qualified output rows);

/*----------------------------------------------------------------------------
 * CASE 15 : denominator level order does not change the class mapping
 *--------------------------------------------------------------------------*/
%qc_case(desc=15 denominator physical order has no effect);
data adsl_rev;
  set adsl(where=(usubjid in ('S6','S7','S8','S9')))
      adsl(where=(usubjid in ('S1','S2','S3','S4','S5')));
run;
%stat_countocc(data=adae, denom=adsl_rev, out=r15, class=trt, code=aebodsys);
proc sql noprint;
  select count(*) into :c15 from r15
    where aebodsys='SOC1' and ns1=1 and ns2=2 and ne1=1 and ne2=2
      and nsp1='1(20.0)' and nsp2='2(66.7)';
  select count(*) into :c15b from r15
    where aebodsys='_TOTAL_' and nsp1='3(60.0)' and nsp2='3(100.0)';
quit;
%qc_check_eq(actual=&c15., expect=1, desc=C15 subgroup counts unchanged by denominator order);
%qc_check_eq(actual=&c15b., expect=1, desc=C15 total counts unchanged by denominator order);

/*----------------------------------------------------------------------------
 * CASE 16 : CODE= variable shorter than UNCODE= / TOTCODELAB= must warn
 *   SAS truncates the assigned text silently, which makes the total row
 *   unusable (it is no longer recognised as the _TOTAL_ level), so the macro
 *   reports a WARNING for each affected parameter.
 *--------------------------------------------------------------------------*/
%qc_case(desc=16 short CODE variable triggers truncation warnings);
data adae_short;
  length usubjid $10 trt $3 cod $5;
  usubjid='S1'; trt='A'; cod='X'; output;
  usubjid='S2'; trt='A'; cod='Y'; output;
run;
data adsl_short;
  length usubjid $10 trt $3;
  usubjid='S1'; trt='A'; output;
  usubjid='S2'; trt='A'; output;
run;
%let _zlog=%sysfunc(pathname(work))\qc_zero18.log;
proc printto log="&_zlog." new; run;
%stat_countocc(data=adae_short, denom=adsl_short, out=z18, class=trt, code=cod);
proc printto; run;
data _null_;
  _u=0; _t=0;
  infile "&_zlog." lrecl=32767 end=_e;
  do until(_e);
    input;
    if index(_infile_,'WARNING: Parameter UNCODE= greater than COD')>0 then _u+1;
    if index(_infile_,'WARNING: Parameter TOTCODELAB= greater than COD')>0 then _t+1;
  end;
  call symputx('_c18u',_u,'G');
  call symputx('_c18t',_t,'G');
run;
%qc_check(cond=%sysevalf(&_c18u.>=1), desc=C16 UNCODE truncation warning raised);
%qc_check(cond=%sysevalf(&_c18t.>=1), desc=C16 TOTCODELAB truncation warning raised);
%qc_expect_nobs(ds=z18, expect=3, desc=C16 result still produced);
proc sql noprint;
  select count(*) into :_c18tot from z18 where cod='_TOTA';
quit;
%qc_check_eq(actual=&_c18tot., expect=1, desc=C16 total level truncated to _TOTA);
data _null_;
  if filename('zq18','&_zlog.')=0 then do;
    _rc=fdelete('zq18');
    _rc=filename('zq18','');
  end;
run;

%qc_end;
