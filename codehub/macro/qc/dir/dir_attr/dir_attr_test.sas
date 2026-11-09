/*===============================================================================
 * dir_attr_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %dir_attr
 * File under test   : dev/dir/dir_attr.sas
 * Dependencies     : %dir_exist
 * Coverage         : NMEMS counts for the sandbox root, d1, d2 and a nested
 *                    folder, DIRECTORY full path, ATTR value case-insensitivity,
 *                    quoted DIR dequoting, and an empty directory returning 0.
 * Note             : this QC session runs on Windows (WIN), so only DIRECTORY
 *                    and NMEMS are valid attributes.
 * Run              : qc/run_all.ps1  (or standalone batch, see README)
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
%include "&_QCDEV_DIR_.\dir_exist.sas";
%include "&_QCDEV_DIR_.\dir_attr.sas";
%qc_sandbox_reset;

%qc_begin(prog=dir_attr_test, macro=dir_attr);

/*----------------------------------------------------------------------------
 * CASE 1 : NMEMS of sandbox d1 equals 4
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 NMEMS of sandbox d1);
%let _r=%dir_attr(dir=&_QCSB_D1_.,attr=NMEMS);
%qc_check_eq(actual=&_r., expect=4, desc=C1 d1 has 4 members);

/*----------------------------------------------------------------------------
 * CASE 2 : NMEMS of sandbox d2 equals 1
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 NMEMS of sandbox d2);
%let _r=%dir_attr(dir=&_QCSB_D2_.,attr=NMEMS);
%qc_check_eq(actual=&_r., expect=1, desc=C2 d2 has 1 member);

/*----------------------------------------------------------------------------
 * CASE 3 : NMEMS of the sandbox root equals 4
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 NMEMS of sandbox root);
%let _r=%dir_attr(dir=&_QCSB_.,attr=NMEMS);
%qc_check_eq(actual=&_r., expect=4, desc=C3 sandbox root has 4 members);

/*----------------------------------------------------------------------------
 * CASE 4 : DIRECTORY returns the full directory path
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 DIRECTORY attribute);
%let _r=%dir_attr(dir=&_QCSB_D1_.,attr=DIRECTORY);
%qc_check_eq(actual=&_r., expect=&_QCSB_D1_., desc=C4 d1 full path returned);

/*----------------------------------------------------------------------------
 * CASE 5 : ATTR value is case-insensitive
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 ATTR value case-insensitive);
%let _r=%dir_attr(dir=&_QCSB_D1_.,attr=nMems);
%qc_check_eq(actual=&_r., expect=4, desc=C5 lowercase nMems works);
%let _r=%dir_attr(dir=&_QCSB_D1_.,attr=Directory);
%qc_check_eq(actual=&_r., expect=&_QCSB_D1_., desc=C5 mixed case Directory works);

/*----------------------------------------------------------------------------
 * CASE 6 : quoted DIR is dequoted internally
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 quoted DIR value);
%let _r=%dir_attr(dir="&_QCSB_D1_.",attr=NMEMS);
%qc_check_eq(actual=&_r., expect=4, desc=C6 quoted d1 path dequoted);

/*----------------------------------------------------------------------------
 * CASE 7 : NMEMS of a nested folder
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 NMEMS of nested sub1);
%let _r=%dir_attr(dir=&_QCSB_D1S1_.,attr=NMEMS);
%qc_check_eq(actual=&_r., expect=2, desc=C7 sub1 has 2 members);

/*----------------------------------------------------------------------------
 * CASE 8 : NMEMS of an empty directory equals 0
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 NMEMS of empty directory);
data _null_;
  rc=dcreate('_qc_dir_attr_empty',"&_QCRES_.");
run;
%let _r=%dir_attr(dir=&_QCRES_\_qc_dir_attr_empty,attr=NMEMS);
%qc_check_eq(actual=&_r., expect=0, desc=C8 empty directory has 0 members);
data _null_;
  rc=filename('_qcda',"&_QCRES_\_qc_dir_attr_empty");
  rc2=fdelete('_qcda');
  rc3=filename('_qcda');
run;

%qc_end;
