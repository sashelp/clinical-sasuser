/*===============================================================================
 * var_exist_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %var_exist
 * File under test   : dev/var/var_exist.sas
 * Coverage          : existing / missing variable return 1 / 0, single and
 *                     multi-observation data, character and numeric vars,
 *                     case insensitivity, library-qualified input, DATA= with
 *                     member options, usable in %if and %let, TYPE=ALL/C/N
 *                     type verification.
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
%qc_sandbox_reset;

%qc_begin(prog=var_exist_test, macro=var_exist);

data ve1;
  length c1 $10;
  c1='abc'; n1=1; n2=2.5;
run;

/*----------------------------------------------------------------------------
 * CASE 1 : existing variables return 1
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 existing variables);
%let _r=%var_exist(data=ve1,var=c1);
%qc_check_eq(actual=&_r., expect=1, desc=C1 char var exists);
%let _r=%var_exist(data=ve1,var=n1);
%qc_check_eq(actual=&_r., expect=1, desc=C1 num var exists);
%let _r=%var_exist(data=ve1,var=n2);
%qc_check_eq(actual=&_r., expect=1, desc=C1 decimal num var exists);

/*----------------------------------------------------------------------------
 * CASE 2 : missing variables return 0 (not an error)
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 missing variables);
%let _r=%var_exist(data=ve1,var=nosuchvar);
%qc_check_eq(actual=&_r., expect=0, desc=C2 absent var returns 0);
%let _r=%var_exist(data=ve1,var=c2);
%qc_check_eq(actual=&_r., expect=0, desc=C2 similar name returns 0);

/*----------------------------------------------------------------------------
 * CASE 3 : variable name case insensitivity
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 case insensitive);
%let _r=%var_exist(data=ve1,var=C1);
%qc_check_eq(actual=&_r., expect=1, desc=C3 uppercase name matches);
%let _r=%var_exist(data=ve1,var=N2);
%qc_check_eq(actual=&_r., expect=1, desc=C3 uppercase numeric matches);

/*----------------------------------------------------------------------------
 * CASE 4 : observation count independent (multi obs / zero obs)
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 observation count independent);
data ve4;
  x=1; output; x=2; output; x=3; output;
run;
%let _r=%var_exist(data=ve4,var=x);
%qc_check_eq(actual=&_r., expect=1, desc=C4 3-obs dataset var exists);
data ve4b;
  if 0; x=1;
run;
%let _r=%var_exist(data=ve4b,var=x);
%qc_check_eq(actual=&_r., expect=1, desc=C4 0-obs dataset var exists);

/*----------------------------------------------------------------------------
 * CASE 5 : library-qualified dataset
 *          Uses its own dedicated scratch library under the temporary sandbox
 *          so it never
 *          shares filesystem state with other test programs.
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 library-qualified dataset);
%let _qclibdir_=&_QCSB_.\_var_exist_lib;
%_qc_sb_del(path=&_qclibdir_.);
data _null_;
  rc=dcreate("_var_exist_lib","&_QCSB_.\");
run;
libname qclib "&_qclibdir_.";
data qclib.ve5;
  a=1; b='x';
run;
%let _r=%var_exist(data=qclib.ve5,var=a);
%qc_check_eq(actual=&_r., expect=1, desc=C5 libname qualified exists);
%let _r=%var_exist(data=qclib.ve5,var=zz);
%qc_check_eq(actual=&_r., expect=0, desc=C5 libname qualified missing);
libname qclib clear;
%let _qclibdir_=;

/*----------------------------------------------------------------------------
 * CASE 6 : DATA= with dataset options e.g. (keep=)
 *          var_exist strips the (...) suffix before checking existence via
 *          %qscan(&data.,1,()).
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 dataset with member options);
%let _r=%var_exist(data=ve1(keep=n1),var=n1);
%qc_check_eq(actual=&_r., expect=1, desc=C6 kept var exists);
%let _r=%var_exist(data=ve1(keep=n1),var=c1);
%qc_check_eq(actual=&_r., expect=0, desc=C6 dropped var missing);

/*----------------------------------------------------------------------------
 * CASE 7 : usable inside a macro %if and as a %let value
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 usable in macro conditional);
%macro _qc_use_vexist(ds=,var=,expect_branch=);
  %if %var_exist(data=&ds.,var=&var.) %then %let branch=THEN;
  %else %let branch=ELSE;
  %qc_check_eq(actual=&branch., expect=&expect_branch., desc=C7 branch chosen);
%mend _qc_use_vexist;
%_qc_use_vexist(ds=ve1,var=c1,expect_branch=THEN);
%_qc_use_vexist(ds=ve1,var=nope,expect_branch=ELSE);

/*----------------------------------------------------------------------------
 * CASE 8 : TYPE=ALL explicit
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 TYPE ALL explicit);
%let _r=%var_exist(data=ve1,var=c1,type=ALL);
%qc_check_eq(actual=&_r., expect=1, desc=C8 TYPE ALL char var);
%let _r=%var_exist(data=ve1,var=nosuchvar,type=ALL);
%qc_check_eq(actual=&_r., expect=0, desc=C8 TYPE ALL missing var);

/*----------------------------------------------------------------------------
 * CASE 9 : TYPE=C only character variable matches
 *--------------------------------------------------------------------------*/
%qc_case(desc=9 TYPE C);
%let _r=%var_exist(data=ve1,var=c1,type=C);
%qc_check_eq(actual=&_r., expect=1, desc=C9 char var matches C);
%let _r=%var_exist(data=ve1,var=n1,type=C);
%qc_check_eq(actual=&_r., expect=0, desc=C9 num var fails C);
%let _r=%var_exist(data=ve1,var=N2,type=C);
%qc_check_eq(actual=&_r., expect=0, desc=C9 uppercase num fails C);
%let _r=%var_exist(data=ve1,var=c2,type=C);
%qc_check_eq(actual=&_r., expect=0, desc=C9 missing var fails C);
%let _r=%var_exist(data=ve1,var=c1,type=c);
%qc_check_eq(actual=&_r., expect=1, desc=C9 lowercase type c);

/*----------------------------------------------------------------------------
 * CASE 10 : TYPE=N only numeric variable matches
 *--------------------------------------------------------------------------*/
%qc_case(desc=10 TYPE N);
%let _r=%var_exist(data=ve1,var=n1,type=N);
%qc_check_eq(actual=&_r., expect=1, desc=C10 num var matches N);
%let _r=%var_exist(data=ve1,var=n2,type=N);
%qc_check_eq(actual=&_r., expect=1, desc=C10 decimal num matches N);
%let _r=%var_exist(data=ve1,var=c1,type=N);
%qc_check_eq(actual=&_r., expect=0, desc=C10 char var fails N);
%let _r=%var_exist(data=ve1,var=nosuchvar,type=N);
%qc_check_eq(actual=&_r., expect=0, desc=C10 missing var fails N);
%let _r=%var_exist(data=ve1,var=n1,type=n);
%qc_check_eq(actual=&_r., expect=1, desc=C10 lowercase type n);

%qc_end;