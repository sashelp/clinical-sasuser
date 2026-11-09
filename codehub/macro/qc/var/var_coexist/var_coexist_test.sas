/*==============================================================================
 * var_coexist_test.sas - Positive (functional) acceptance tests
 *==============================================================================
 * Macro under test : %var_coexist
 * File under test   : dev/var/var_coexist.sas
 * Coverage          : BOOLEAN / POSITION result types, all-exist / some-missing,
 *                     variable order independent, case insensitivity, single var,
 *                     library-qualified data, DATA= with (keep=) options,
 *                     usage as part of a logical condition, TYPE=ALL/C/N type
 *                     verification in both result types.
 * Run               : qc/run_all.ps1 (or standalone batch)
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
%include "&_QCDEV_VAR_.\var_coexist.sas";

%qc_begin(prog=var_coexist_test, macro=var_coexist);

/*----------------------------------------------------------------------------
 * CASE 1 : BOOLEAN, all variables exist -> 1
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 BOOLEAN all variables exist returns 1);
data vc1;
  x=1; y=2; z=3; w=4;
run;
%qc_check_eq(actual=%var_coexist(data=vc1,var=x y z w), expect=1,
  desc=C1 all exist BOOLEAN=1);
%qc_check_eq(actual=%var_coexist(data=vc1,var=x y z w,resulttype=boolean), expect=1,
  desc=C1 explicit BOOLEAN=1);

/*----------------------------------------------------------------------------
 * CASE 2 : BOOLEAN, some variable missing -> 0
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 BOOLEAN any missing returns 0);
%qc_check_eq(actual=%var_coexist(data=vc1,var=x z missing), expect=0,
  desc=C2 one missing BOOLEAN=0);
%qc_check_eq(actual=%var_coexist(data=vc1,var=nope x), expect=0,
  desc=C2 first missing BOOLEAN=0);

/*----------------------------------------------------------------------------
 * CASE 3 : POSITION, all exist -> 1
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 POSITION all exist returns 1);
%qc_check_eq(actual=%var_coexist(data=vc1,var=x y z w,resulttype=position), expect=1,
  desc=C3 all exist POSITION=1);

/*----------------------------------------------------------------------------
 * CASE 4 : POSITION, missing variable at ith place -> -i
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 POSITION returns -i for first missing at position i);
%let _r=%var_coexist(data=vc1,var=nope x y z,resulttype=position);
%qc_check_eq(actual=&_r., expect=-1,
  desc=C4 1st var missing -> -1);
%let _r=%var_coexist(data=vc1,var=x nope y z,resulttype=position);
%qc_check_eq(actual=&_r., expect=-2,
  desc=C4 2nd var missing -> -2);
%let _r=%var_coexist(data=vc1,var=x y nope z,resulttype=position);
%qc_check_eq(actual=&_r., expect=-3,
  desc=C4 3rd var missing -> -3);
%let _r=%var_coexist(data=vc1,var=x y z nope,resulttype=position);
%qc_check_eq(actual=&_r., expect=-4,
  desc=C4 4th var missing -> -4);
/*----------------------------------------------------------------------------
 * CASE 5 : variable ORDER should not matter
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 order independent);
%qc_check_eq(actual=%var_coexist(data=vc1,var=z w x y,resulttype=position), expect=1,
  desc=C5 shuffled order POSITION=1);

/*----------------------------------------------------------------------------
 * CASE 6 : variable name CASE insensitivity
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 variable names case insensitive);
%qc_check_eq(actual=%var_coexist(data=vc1,var=X Y Z W), expect=1,
  desc=C6 uppercase names BOOLEAN=1);

/*----------------------------------------------------------------------------
 * CASE 7 : single variable
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 single variable);
%qc_check_eq(actual=%var_coexist(data=vc1,var=x), expect=1,
  desc=C7 single exist BOOLEAN=1);
%qc_check_eq(actual=%var_coexist(data=vc1,var=solo), expect=0,
  desc=C7 single missing BOOLEAN=0);

/*----------------------------------------------------------------------------
 * CASE 8 : library-qualified dataset
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 library-qualified dataset);
libname qcwork "&_QCRES_.";
data qcwork.vc8;
  a=1; b=2;
run;
%qc_check_eq(actual=%var_coexist(data=qcwork.vc8,var=a b), expect=1,
  desc=C8 libname dataset all exist);
%qc_check_eq(actual=%var_coexist(data=qcwork.vc8,var=b c), expect=0,
  desc=C8 libname dataset missing one);

/*----------------------------------------------------------------------------
 * CASE 9 : DATA= with dataset options e.g. (keep=)  -> first token before '('
 *--------------------------------------------------------------------------*/
%qc_case(desc=9 dataset with member-options syntax);
%qc_check_eq(actual=%var_coexist(data=vc1(keep=x y),var=x y), expect=1,
  desc=C9 keep option subset all exist);
%qc_check_eq(actual=%var_coexist(data=vc1(keep=x),var=x z), expect=0,
  desc=C9 keep option subset missing z);

/*----------------------------------------------------------------------------
 * CASE 10 : RESULTTYPE value-case insensitivity
 *--------------------------------------------------------------------------*/
%qc_case(desc=10 resulttype case-insensitive);
%qc_check_eq(actual=%var_coexist(data=vc1,var=x y,resulttype=BOOLean), expect=1,
  desc=C10 mixed-case BOOLEAN);
%qc_check_eq(actual=%var_coexist(data=vc1,var=x y,resulttype=position), expect=1,
  desc=C10 lowercase position all exist);
%let _r=%var_coexist(data=vc1,var=nope x,resulttype=POSITION);
%qc_check_eq(actual=&_r., expect=-1,
  desc=C10 uppercase position missing);

/*----------------------------------------------------------------------------
 * CASE 11 : usable inside a macro %if %then %else (standard usage)
 *           (open-code %IF is not supported by SAS, so wrap in a macro)
 *--------------------------------------------------------------------------*/
%qc_case(desc=11 usable in conditional IF inside a macro);
%macro _qc_use_coexist(ds=,var=,expect_branch=);
  %if %var_coexist(data=&ds.,var=&var.) %then %do;
    %let branch=THEN;
  %end;
  %else %do;
    %let branch=ELSE;
  %end;
  %qc_check_eq(actual=&branch., expect=&expect_branch., desc=C11 branch chosen);
%mend _qc_use_coexist;

%_qc_use_coexist(ds=vc1,var=x y z w,expect_branch=THEN);
%_qc_use_coexist(ds=vc1,var=x zzz,expect_branch=ELSE);

/* also usable with %let capture */
%let _r = %var_coexist(data=vc1,var=x y z w);
%qc_check(cond=&_r.=1, desc=C11 captured return value 1);

/*----------------------------------------------------------------------------
 * CASE 12 : TYPE=ALL explicit
 *--------------------------------------------------------------------------*/
%qc_case(desc=12 TYPE ALL explicit);
%qc_check_eq(actual=%var_coexist(data=vc1,var=x y z w,type=ALL), expect=1,
  desc=C12 TYPE ALL all exist);
%qc_check_eq(actual=%var_coexist(data=vc1,var=x nope,type=ALL), expect=0,
  desc=C12 TYPE ALL missing var);

/*----------------------------------------------------------------------------
 * CASE 13 : TYPE=C, all listed variables must be character
 *--------------------------------------------------------------------------*/
%qc_case(desc=13 TYPE C);
data vc13;
  length c1 $5;
  c1='a'; n1=1;
run;
%qc_check_eq(actual=%var_coexist(data=vc13,var=c1,type=C), expect=1,
  desc=C13 char var matches C);
%qc_check_eq(actual=%var_coexist(data=vc13,var=n1,type=C), expect=0,
  desc=C13 num var fails C);
%qc_check_eq(actual=%var_coexist(data=vc13,var=c1 n1,type=C), expect=0,
  desc=C13 mixed vars fail C);
%qc_check_eq(actual=%var_coexist(data=vc13,var=c1 nope,type=C), expect=0,
  desc=C13 char plus missing fails C);
%qc_check_eq(actual=%var_coexist(data=vc13,var=C1,type=c), expect=1,
  desc=C13 lowercase type c);

/*----------------------------------------------------------------------------
 * CASE 14 : TYPE=N, all listed variables must be numeric
 *--------------------------------------------------------------------------*/
%qc_case(desc=14 TYPE N);
%qc_check_eq(actual=%var_coexist(data=vc13,var=n1,type=N), expect=1,
  desc=C14 num var matches N);
%qc_check_eq(actual=%var_coexist(data=vc13,var=c1,type=N), expect=0,
  desc=C14 char var fails N);
%qc_check_eq(actual=%var_coexist(data=vc1,var=x y z w,type=N), expect=1,
  desc=C14 all numeric match N);
%qc_check_eq(actual=%var_coexist(data=vc1,var=x y z w,type=n), expect=1,
  desc=C14 lowercase type n);

/*----------------------------------------------------------------------------
 * CASE 15 : POSITION reports -i for the first type mismatch
 *--------------------------------------------------------------------------*/
%qc_case(desc=15 POSITION type mismatch);
%let _r=%var_coexist(data=vc13,var=c1 n1,resulttype=POSITION,type=N);
%qc_check_eq(actual=&_r., expect=-1, desc=C15 1st var wrong type -> -1);
%let _r=%var_coexist(data=vc13,var=n1 c1,resulttype=POSITION,type=N);
%qc_check_eq(actual=&_r., expect=-2, desc=C15 2nd var wrong type -> -2);
%let _r=%var_coexist(data=vc13,var=n1 c1,resulttype=POSITION,type=C);
%qc_check_eq(actual=&_r., expect=-1, desc=C15 1st var wrong type for C -> -1);

%qc_end;