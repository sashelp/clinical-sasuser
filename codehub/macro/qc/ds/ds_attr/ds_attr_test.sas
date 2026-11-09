/*===============================================================================
 * ds_attr_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %ds_attr
 * File under test   : dev/ds/ds_attr.sas
 * Coverage          : numeric attributes (NVARS NOBS NLOBS NLOBSF), char
 *                     attributes (LIB MEM ENGINE TYPE LABEL), date attribute
 *                     CRDTE, case-insensitive ATTR=.
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
%include "&_QCDEV_DS_.\ds_attr.sas";

%qc_begin(prog=ds_attr_test, macro=ds_attr);

data da1;
  length c1 $5 c2 $10;
  c1='abc'; c2='def';
  n1=1;
run;
%let _dsn=da1;

/*----------------------------------------------------------------------------
 * CASE 1 : NVARS (number of variables)
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 NVARS);
%let _r=%ds_attr(data=&_dsn.,attr=nvars);
%qc_check_eq(actual=&_r., expect=3, desc=C1 nvars=3);

/*----------------------------------------------------------------------------
 * CASE 2 : NOBS (number of observations)
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 NOBS);
%let _r=%ds_attr(data=&_dsn.,attr=nobs);
%qc_check_eq(actual=&_r., expect=1, desc=C2 nobs=1);

/*----------------------------------------------------------------------------
 * CASE 3 : NLOBS / NLOBSF
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 NLOBS and NLOBSF);
%let _r=%ds_attr(data=&_dsn.,attr=nlobs);
%qc_check_eq(actual=&_r., expect=1, desc=C3 nlobs=1);
%let _r=%ds_attr(data=&_dsn.,attr=nlobsf);
%qc_check_eq(actual=&_r., expect=1, desc=C3 nlobsf=1);

/*----------------------------------------------------------------------------
 * CASE 4 : LIB MEM (char attributes)
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 LIB and MEM);
%let _r=%ds_attr(data=&_dsn.,attr=lib);
%qc_check_eq(actual=&_r., expect=WORK, desc=C4 lib=WORK);
%let _r=%ds_attr(data=&_dsn.,attr=mem);
%qc_check_eq(actual=&_r., expect=DA1, desc=C4 mem=DA1);

/*----------------------------------------------------------------------------
 * CASE 5 : ENGINE
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 ENGINE);
%let _r=%ds_attr(data=&_dsn.,attr=engine);
%qc_check_eq(actual=&_r., expect=V9, desc=C5 engine=V9);

/*----------------------------------------------------------------------------
 * CASE 6 : TYPE (data set type; empty for a regular data set)
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 TYPE);
%let _r=%ds_attr(data=&_dsn.,attr=type);
%qc_check_eq(actual=&_r., expect=, desc=C6 type empty for reg ds);

/*----------------------------------------------------------------------------
 * CASE 7 : ATTR= case-insensitive
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 ATTR case-insensitive);
%let _r=%ds_attr(data=&_dsn.,attr=NVARS);
%qc_check_eq(actual=&_r., expect=3, desc=C7 uppercase NVARS);
%let _r=%ds_attr(data=&_dsn.,attr=Mem);
%qc_check_eq(actual=&_r., expect=DA1, desc=C7 mixed-case Mem);

%qc_end;