/*===============================================================================
 * var_nlevel_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %var_nlevel
 * File under test   : dev/var/var_nlevel.sas
 * Dependencies      : %var_exist
 * Coverage          : default and explicit INCLUDEMISSING=N, INCLUDEMISSING=Y
 *                     for character and numeric variables including special
 *                     missing values, empty and all-missing input, single and
 *                     many levels, trailing and leading blanks, case sensitivity,
 *                     special characters, formats, library-qualified input,
 *                     DATA= member options, use in %if, input preservation.
 * Run               : qc/run_all.ps1  (or standalone batch, see README)
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
%include "&_QCQC_.\_framework\qc_sandbox.sas";
%include "&_QCDEV_VAR_.\var_exist.sas";
%include "&_QCDEV_VAR_.\var_nlevel.sas";
%qc_sandbox_reset;

%qc_begin(prog=var_nlevel_test, macro=var_nlevel);

data nl1;
  length c1 $10;
  c1='A'; n1=1; output;
  c1='B'; n1=2; output;
  c1='A'; n1=2; output;
  c1='C'; n1=3; output;
  c1=''; n1=.; output;
run;

/*----------------------------------------------------------------------------
 * CASE 1 : default INCLUDEMISSING=N excludes missing values
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 default excludes missing);
%let _r=%var_nlevel(data=nl1,var=c1);
%qc_check_eq(actual=&_r., expect=3, desc=C1 char 3 non-missing levels);
%let _r=%var_nlevel(data=nl1,var=n1);
%qc_check_eq(actual=&_r., expect=3, desc=C1 num 3 non-missing levels);

/*----------------------------------------------------------------------------
 * CASE 2 : explicit INCLUDEMISSING=N and lowercase value
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 explicit N and lowercase);
%let _r=%var_nlevel(data=nl1,var=c1,includemissing=N);
%qc_check_eq(actual=&_r., expect=3, desc=C2 explicit N char);
%let _r=%var_nlevel(data=nl1,var=n1,includemissing=n);
%qc_check_eq(actual=&_r., expect=3, desc=C2 lowercase n num);

/*----------------------------------------------------------------------------
 * CASE 3 : INCLUDEMISSING=Y counts character missing as one level
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 char missing included);
%let _r=%var_nlevel(data=nl1,var=c1,includemissing=Y);
%qc_check_eq(actual=&_r., expect=4, desc=C3 char 3 levels plus missing);
data nl3;
  length c1 $5;
  c1=''; output;
  c1=' '; output;
run;
%let _r=%var_nlevel(data=nl3,var=c1,includemissing=N);
%qc_check_eq(actual=&_r., expect=0, desc=C3 all-missing char excluded);
%let _r=%var_nlevel(data=nl3,var=c1,includemissing=Y);
%qc_check_eq(actual=&_r., expect=1, desc=C3 all-missing char one level);

/*----------------------------------------------------------------------------
 * CASE 4 : INCLUDEMISSING=Y counts numeric missing codes separately
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 num missing codes included);
data nl4;
  n1=1; output;
  n1=1.0; output;
  n1=.; output;
  n1=.A; output;
  n1=.A; output;
  n1=._; output;
  n1=.Z; output;
  n1=2; output;
run;
%let _r=%var_nlevel(data=nl4,var=n1,includemissing=N);
%qc_check_eq(actual=&_r., expect=2, desc=C4 num non-missing levels);
%let _r=%var_nlevel(data=nl4,var=n1,includemissing=Y);
%qc_check_eq(actual=&_r., expect=6, desc=C4 num missing codes as levels);

/*----------------------------------------------------------------------------
 * CASE 5 : empty input returns 0
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 empty dataset);
data nl5;
  if 0;
  length c1 $5;
  x=1;
run;
%let _r=%var_nlevel(data=nl5,var=x);
%qc_check_eq(actual=&_r., expect=0, desc=C5 empty num returns 0);
%let _r=%var_nlevel(data=nl5,var=c1,includemissing=Y);
%qc_check_eq(actual=&_r., expect=0, desc=C5 empty char with Y returns 0);

/*----------------------------------------------------------------------------
 * CASE 6 : single level
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 single level);
data nl6;
  x=5; output;
  x=5.0; output;
run;
%let _r=%var_nlevel(data=nl6,var=x);
%qc_check_eq(actual=&_r., expect=1, desc=C6 single numeric level);

/*----------------------------------------------------------------------------
 * CASE 7 : trailing blanks are ignored and leading blanks are significant
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 blanks and case);
data nl7;
  length c1 $10;
  c1='A'; output;
  c1='A '; output;
  c1='A  '; output;
  c1=' A'; output;
  c1='a'; output;
run;
%let _r=%var_nlevel(data=nl7,var=c1);
%qc_check_eq(actual=&_r., expect=3, desc=C7 trailing blanks merged leading kept);

/*----------------------------------------------------------------------------
 * CASE 8 : special characters are compared as plain text
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 special characters);
data nl8;
  length c1 $20;
  c1='A|B'; output;
  c1='A'||byte(37)||'B'; output;
  c1='A'||byte(38)||'B'; output;
  c1="A'B"; output;
  c1='A"B'; output;
  c1='#M#A'; output;
  c1=byte(37); output;
  c1=byte(38); output;
  c1="'"; output;
  c1='"'; output;
run;
%let _r=%var_nlevel(data=nl8,var=c1);
%qc_check_eq(actual=&_r., expect=10, desc=C8 ten distinct special values);

/*----------------------------------------------------------------------------
 * CASE 9 : formats do not affect the level count
 *--------------------------------------------------------------------------*/
%qc_case(desc=9 formats ignored);
data nl9;
  n1=1; output;
  n1=2; output;
  n1=3; output;
run;
proc format;
  value nl9fmt
    low-<2 = 'L'
    2-high = 'H';
run;
data nl9;
  set nl9;
  format n1 nl9fmt.;
run;
%let _r=%var_nlevel(data=nl9,var=n1);
%qc_check_eq(actual=&_r., expect=3, desc=C9 formatted num 3 raw levels);
proc format;
  value $nl9cfmt
    'A','B' = 'X'
    other   = 'Y';
run;
data nl9c;
  length c1 $1;
  c1='A'; output;
  c1='B'; output;
  c1='C'; output;
  format c1 $nl9cfmt.;
run;
%let _r=%var_nlevel(data=nl9c,var=c1);
%qc_check_eq(actual=&_r., expect=3, desc=C9 formatted char 3 raw levels);

/*----------------------------------------------------------------------------
 * CASE 10 : many levels
 *--------------------------------------------------------------------------*/
%qc_case(desc=10 many levels);
data nl10;
  do i=1 to 50;
    x=i;
    output;
  end;
run;
%let _r=%var_nlevel(data=nl10,var=x);
%qc_check_eq(actual=&_r., expect=50, desc=C10 fifty levels);

/*----------------------------------------------------------------------------
 * CASE 11 : library-qualified input and DATA= member options
 *--------------------------------------------------------------------------*/
%qc_case(desc=11 library and dataset options);
%let _qclibdir_=&_QCSB_.\_var_nlevel_lib;
%_qc_sb_del(path=&_qclibdir_.);
data _null_;
  rc=dcreate("_var_nlevel_lib","&_QCSB_.\");
run;
libname qcnl "&_qclibdir_.";
data qcnl.nl11;
  do i=1 to 4;
    c1='L'||put(i,1.);
    output;
  end;
run;
%let _r=%var_nlevel(data=qcnl.nl11,var=c1);
%qc_check_eq(actual=&_r., expect=4, desc=C11 libname qualified levels);
libname qcnl clear;
%let _qclibdir_=;
%let _r=%var_nlevel(data=nl1(keep=c1),var=c1);
%qc_check_eq(actual=&_r., expect=3, desc=C11 dataset keep option levels);

/*----------------------------------------------------------------------------
 * CASE 12 : usable inside a macro %if and as a %let value
 *--------------------------------------------------------------------------*/
%qc_case(desc=12 usable in macro conditional);
%macro _qc_use_nlevel(ds=,var=,cut=,expect_branch=);
  %if %var_nlevel(data=&ds.,var=&var.) > &cut. %then %let branch=THEN;
  %else %let branch=ELSE;
  %qc_check_eq(actual=&branch., expect=&expect_branch., desc=C12 branch chosen);
%mend _qc_use_nlevel;
%_qc_use_nlevel(ds=nl1,var=c1,cut=2,expect_branch=THEN);
%_qc_use_nlevel(ds=nl6,var=x,cut=1,expect_branch=ELSE);

/*----------------------------------------------------------------------------
 * CASE 13 : input dataset is not modified
 *--------------------------------------------------------------------------*/
%qc_case(desc=13 input preserved);
%qc_expect_nobs(ds=nl1, expect=5, desc=C13 input nobs unchanged);

%qc_end;
