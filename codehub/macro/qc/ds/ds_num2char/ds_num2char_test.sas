/*==============================================================================
 * ds_num2char_test.sas - Positive (functional) acceptance tests
 *==============================================================================
 * Macro under test : %ds_num2char
 * File under test   : dev/ds/ds_num2char.sas
 * Dependencies      : %var_coexist, %ds_varlist (documented in macro header)
 * Coverage          : basic conversion, VALUE=FORMATTED / INTERNAL,
 *                     MISSING=NULL / ASIS, partial conversion, labels/formats,
 *                     variable order, OUT= different name, OUT= DATA= inline,
 *                     OUT= library-qualified, single obs, wide dataset, all
 *                     numeric vars, keep non-numeric untouched.
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
%include "&_QCQC_.\_framework\qc_testdata.sas";
%include "&_QCDEV_VAR_.\var_coexist.sas";
%include "&_QCDEV_DS_.\ds_varlist.sas";
%include "&_QCDEV_DS_.\ds_num2char.sas";

%qc_begin(prog=ds_num2char_test, macro=ds_num2char);

/*----------------------------------------------------------------------------
 * CASE 1 : basic conversion - numeric -> char, values preserved
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 basic conversion to char preserving values);
data n2c1;
  length c1 $10;
  c1='keep';
  n1=123;
  n2=-45.6;
  n3=7.89;
run;
%ds_num2char(data=n2c1,out=n2c1out,var=n1 n2 n3);
%qc_expect_ds(ds=n2c1out, desc=C1 output dataset exists);
%qc_expect_var(ds=n2c1out, var=n1, type=C, desc=C1 n1 now char);
%qc_expect_var(ds=n2c1out, var=n2, type=C, desc=C1 n2 now char);
%qc_expect_var(ds=n2c1out, var=n3, type=C, desc=C1 n3 now char);
%qc_expect_var(ds=n2c1out, var=c1, type=C, desc=C1 c1 untouched);
%qc_expect_nobs(ds=n2c1out, expect=1, desc=C1 one observation);

/* verify converted values */
data _null_;
  set n2c1out;
  call symputx('v1',strip(n1));
  call symputx('v2',strip(n2));
  call symputx('v3',strip(n3));
run;
%qc_check_eq(actual=&v1., expect=123, desc=C1 n1 value '123');
%qc_check_eq(actual=&v2., expect=-45.6, desc=C1 n2 value '-45.6');
%qc_check_eq(actual=&v3., expect=7.89, desc=C1 n3 value '7.89');
/*----------------------------------------------------------------------------
 * CASE 2 : FORMATTED conversion with a date format
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 FORMATTED uses assigned format like date9.);
%qc_data_mixed(ds=n2c2);   /* dt has date9. format */
%ds_num2char(data=n2c2,out=n2c2out,var=dt);
data _null_;
  set n2c2out;
  call symputx('vdt',strip(dt));
run;
%qc_check_eq(actual=&vdt., expect=15JAN2024, desc=C2 date9 formatted value);
%qc_expect_var(ds=n2c2out, var=dt, type=C, desc=C2 dt now char);

/*----------------------------------------------------------------------------
 * CASE 3 : INTERNAL conversion ignores format
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 INTERNAL uses internal value);
%ds_num2char(data=n2c2,out=n2c2int,var=dt,value=internal);
data _null_;
  set n2c2int;
  call symputx('vdt',strip(dt));
run;
%qc_check_eq(actual=&vdt., expect=23390, desc=C3 date internal raw 23390);

/*----------------------------------------------------------------------------
 * CASE 4 : MISSING=NULL  -> missing becomes empty string
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 MISSING=NULL turns missing into empty char);
data n2c4;
  a=.;
  b=.A;
  c=5;
run;
%ds_num2char(data=n2c4,out=n2c4out,var=a b c);
proc sql noprint;
  select count(*) into :nm_a from n2c4out where a='';
  select count(*) into :nm_b from n2c4out where b='';
  select count(*) into :nm_c from n2c4out where c='5';
quit;
%qc_check_eq(actual=&nm_a., expect=1, desc=C4 a converted to empty);
%qc_check_eq(actual=&nm_b., expect=1, desc=C4 b(.A) converted to empty);
%qc_check_eq(actual=&nm_c., expect=1, desc=C4 c=5 preserved);

/*----------------------------------------------------------------------------
 * CASE 5 : MISSING=ASIS  -> missing keeps its formatted text
 *          Note: vvalue() renders special missing .A as 'A' (no dot),
 *          and regular missing as '.'.
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 MISSING=ASIS keeps formatted missing text);
%ds_num2char(data=n2c4,out=n2c4asis,var=a b c,missing=asis);
proc sql noprint;
  select count(*) into :na_a from n2c4asis where a='.';
  select count(*) into :na_b from n2c4asis where b='A';
  select count(*) into :na_c from n2c4asis where c='5';
quit;
%qc_check_eq(actual=&na_a., expect=1, desc=C5 a asis '.' );
%qc_check_eq(actual=&na_b., expect=1, desc=C5 b asis 'A');
%qc_check_eq(actual=&na_c., expect=1, desc=C5 c asis '5');
/*----------------------------------------------------------------------------
 * CASE 6 : label retained after conversion (checked via proc contents)
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 label retained after conversion);
data n2c6;
  n9=100;
  label n9='My Label';
run;
%ds_num2char(data=n2c6,out=n2c6out,var=n9);
proc contents data=n2c6out out=n2c6meta noprint;
run;
data _null_;
  set n2c6meta;
  if upcase(name)='N9';
  call symputx('c6label',strip(label));
run;
%put ##### C6_DEBUG_LABEL=&c6label.;
%qc_check_eq(actual=&c6label., expect=My Label, desc=C6 label preserved);

/*----------------------------------------------------------------------------
 * CASE 7 : partial conversion - only selected numeric var converted
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 partial conversion keeps other numeric unaffected);
data n2c7;
  n1=1; n2=2; n3=3;
run;
%ds_num2char(data=n2c7,out=n2c7out,var=n1);
%qc_expect_var(ds=n2c7out, var=n1, type=C, desc=C7 n1 char);
%qc_expect_var(ds=n2c7out, var=n2, type=N, desc=C7 n2 still num);
%qc_expect_var(ds=n2c7out, var=n3, type=N, desc=C7 n3 still num);

/*----------------------------------------------------------------------------
 * CASE 8 : all numeric vars converted (via %ds_varlist type=n)
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 convert all numeric vars);
%ds_num2char(data=n2c7,out=n2c7all,var=%ds_varlist(data=n2c7,type=n));
%qc_expect_var(ds=n2c7all, var=n1, type=C, desc=C8 n1 char);
%qc_expect_var(ds=n2c7all, var=n2, type=C, desc=C8 n2 char);
%qc_expect_var(ds=n2c7all, var=n3, type=C, desc=C8 n3 char);

/*----------------------------------------------------------------------------
 * CASE 9 : OUT= same as DATA= (in-place conversion)
 *--------------------------------------------------------------------------*/
%qc_case(desc=9 in-place conversion OUT=DATA=);
data inplace;
  a=1; b=2; c=3;
run;
%ds_num2char(data=inplace,out=inplace,var=a b c);
%qc_expect_var(ds=inplace, var=a, type=C, desc=C9 a char in place);
%qc_expect_var(ds=inplace, var=b, type=C, desc=C9 b char in place);
%qc_expect_var(ds=inplace, var=c, type=C, desc=C9 c char in place);
/*----------------------------------------------------------------------------
 * CASE 10 : OUT= library-qualified dataset
 *--------------------------------------------------------------------------*/
%qc_case(desc=10 OUT= library-qualified);
libname qcwork "&_QCRES_.";
data n2c10;
  n=10;
run;
%ds_num2char(data=n2c10,out=qcwork.n2c10out,var=n);
%qc_expect_var(ds=qcwork.n2c10out, var=n, type=C, desc=C10 libname out n char);
%qc_expect_ds(ds=qcwork.n2c10out, desc=C10 libname out exists);

/*----------------------------------------------------------------------------
 * CASE 11 : empty dataset (0 obs) structure-only conversion
 *--------------------------------------------------------------------------*/
%qc_case(desc=11 convert on 0-observation dataset);
data n2c11;
  n=1;
run;
data n2c11;
  set n2c11;
  where 0;
run;
%ds_num2char(data=n2c11,out=n2c11out,var=n);
%qc_expect_var(ds=n2c11out, var=n, type=C, desc=C11 n char in empty ds);

/*----------------------------------------------------------------------------
 * CASE 12 : wide numeric dataset, multiple vars
 *--------------------------------------------------------------------------*/
%qc_case(desc=12 many numeric vars at once);
%qc_data_wide(ds=n2c12,n=10);
%ds_num2char(data=n2c12,out=n2c12out,var=%ds_varlist(data=n2c12,type=n));
%qc_expect_var(ds=n2c12out, var=v1, type=C, desc=C12 v1 char);
%qc_expect_var(ds=n2c12out, var=v10, type=C, desc=C12 v10 char);
%qc_expect_nobs(ds=n2c12out, expect=1, desc=C12 one obs);

/*----------------------------------------------------------------------------
 * CASE 13 : mixed char/numeric; converted numeric go after original vars
 *          (macro doc: variable order differs, converted vars go last)
 *--------------------------------------------------------------------------*/
%qc_case(desc=13 variable order after conversion);
data n2c13;
  z1=100; a9=200; c9='x';
run;
%ds_num2char(data=n2c13,out=n2c13out,var=z1 a9);
%qc_expect_var(ds=n2c13out, var=z1, type=C, desc=C13 z1 char);
%qc_expect_var(ds=n2c13out, var=a9, type=C, desc=C13 a9 char);
%qc_expect_var(ds=n2c13out, var=c9, type=C, desc=C13 c9 char);
proc sql noprint;
  select count(*) into :n13 from dictionary.columns
    where libname='WORK' and memname='N2C13OUT';
quit;
%qc_check_eq(actual=&n13., expect=3, desc=C13 total 3 vars in output);

/*----------------------------------------------------------------------------
 * CASE 14 : special missing values with FORMATTED + ASIS  (.A .D status)
 *          Note: vvalue() renders .A as 'A' and .D as 'D'
 *--------------------------------------------------------------------------*/
%qc_case(desc=14 special missing with ASIS);
data n2c14;
  a=.; b=.A; c=.D;
run;
%ds_num2char(data=n2c14,out=n2c14out,var=a b c,value=formatted,missing=asis);
proc sql noprint;
  select count(*) into :sa from n2c14out where a='.';
  select count(*) into :sb from n2c14out where b='A';
  select count(*) into :sc from n2c14out where c='D';
quit;
%qc_check_eq(actual=&sa., expect=1, desc=C14 formatted asis a='.' );
%qc_check_eq(actual=&sb., expect=1, desc=C14 formatted asis b='A');
%qc_check_eq(actual=&sc., expect=1, desc=C14 formatted asis c='D');

%qc_end;