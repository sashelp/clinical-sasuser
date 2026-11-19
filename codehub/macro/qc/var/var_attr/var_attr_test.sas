/*===============================================================================
 * var_attr_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %var_attr
 * File under test   : dev/var/var_attr.sas
 * Dependency        : %var_exist
 * Coverage          : NUM / NAME / TYPE / LENGTH / FORMAT / INFORMAT / LABEL
 *                     attributes, ATTR value case-insensitivity, attribute on
 *                     char and numeric variables.
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
%include "&_QCDEV_VAR_.\var_exist.sas";
%include "&_QCDEV_VAR_.\var_attr.sas";

%qc_begin(prog=var_attr_test, macro=var_attr);

data va1;
  length char1 $20;
  char1='abc';
  num1=1;
  num2=2.5;
  dt=mdy(1,15,2024);
  format dt date9.;
  pct=0.123;
  format pct percent8.2;
  label num1='Obs Number' char1='Char One';
run;

/*----------------------------------------------------------------------------
 * CASE 1 : NUM returns variable position
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 NUM position);
%let _r=%var_attr(data=va1,var=char1,attr=num);
%qc_check_eq(actual=&_r., expect=1, desc=C1 char1 position 1);
%let _r=%var_attr(data=va1,var=num1,attr=num);
%qc_check_eq(actual=&_r., expect=2, desc=C1 num1 position 2);
%let _r=%var_attr(data=va1,var=pct,attr=num);
%qc_check_eq(actual=&_r., expect=5, desc=C1 pct position 5);

/*----------------------------------------------------------------------------
 * CASE 2 : NAME returns variable name
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 NAME);
%let _r=%var_attr(data=va1,var=char1,attr=name);
%qc_check_eq(actual=&_r., expect=char1, desc=C2 name char1);

/*----------------------------------------------------------------------------
 * CASE 3 : TYPE returns C / N
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 TYPE);
%let _r=%var_attr(data=va1,var=char1,attr=type);
%qc_check_eq(actual=&_r., expect=C, desc=C3 char1 type C);
%let _r=%var_attr(data=va1,var=num1,attr=type);
%qc_check_eq(actual=&_r., expect=N, desc=C3 num1 type N);

/*----------------------------------------------------------------------------
 * CASE 4 : LENGTH returns physical length
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 LENGTH);
%let _r=%var_attr(data=va1,var=char1,attr=length);
%qc_check_eq(actual=&_r., expect=20, desc=C4 char1 length 20);
%let _r=%var_attr(data=va1,var=num2,attr=length);
%qc_check_eq(actual=&_r., expect=8, desc=C4 num2 length 8);

/*----------------------------------------------------------------------------
 * CASE 5 : FORMAT returns assigned format
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 FORMAT);
%let _r=%var_attr(data=va1,var=dt,attr=format);
%qc_check_eq(actual=&_r., expect=DATE9., desc=C5 dt format date9);
%let _r=%var_attr(data=va1,var=pct,attr=format);
%qc_check_eq(actual=&_r., expect=PERCENT8.2, desc=C5 pct format percent);

/*----------------------------------------------------------------------------
 * CASE 6 : INFORMAT returns assigned informat (default none)
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 INFORMAT);
%let _r=%var_attr(data=va1,var=num1,attr=informat);
%qc_check_eq(actual=&_r., expect=, desc=C6 num1 no informat);

/*----------------------------------------------------------------------------
 * CASE 7 : LABEL returns variable label
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 LABEL);
%let _r=%var_attr(data=va1,var=num1,attr=label);
%qc_check_eq(actual=&_r., expect=Obs Number, desc=C7 num1 label);
%let _r=%var_attr(data=va1,var=char1,attr=label);
%qc_check_eq(actual=&_r., expect=Char One, desc=C7 char1 label);

/*----------------------------------------------------------------------------
 * CASE 8 : ATTR= value is case-insensitive
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 ATTR case-insensitive);
%let _r=%var_attr(data=va1,var=num1,attr=NUM);
%qc_check_eq(actual=&_r., expect=2, desc=C8 uppercase NUM);
%let _r=%var_attr(data=va1,var=char1,attr=Type);
%qc_check_eq(actual=&_r., expect=C, desc=C8 mixed-case Type);

%qc_end;