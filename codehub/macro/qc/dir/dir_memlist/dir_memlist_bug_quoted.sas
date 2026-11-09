/*===============================================================================
 * dir_memlist_bug_quoted.sas - Bug regression: quoted DIR= is not dequoted
 *===============================================================================
 * Macro under test : %dir_memlist
 * Expected         : with DIR="...", the root path and member paths are unquoted
 *                    and files are classified as File
 * Status           : OPEN 2026-11-02 - dequote() is not applied to DIR=
 * Original defect  : the root row keeps the surrounding double quotes; every
 *                    member path is built on the quoted root, fopen() fails and
 *                    all members are typed Directory
 * Fix              : apply %qsysfunc(dequote(&dir.)) before creating the root row
 * Test passes when  the defect is fixed (run_all then reports FIXED).
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
%include "&_QCDEV_DIR_.\dir_memlist.sas";
%qc_sandbox_reset;

%qc_begin(prog=dir_memlist_bug_quoted, macro=dir_memlist);

%dir_memlist(dir="&_QCSB_D1_.", out=work.ml_quoted, maxdepth=1);

%qc_case(desc=1 quoted DIR dequoted in root path);
%qc_expect_colval(ds=work.ml_quoted, var=path, where=depth=0, expect=&_QCSB_D1_., desc=Q1 root path unquoted);

%qc_case(desc=2 quoted DIR members classified correctly);
%qc_expect_colval(ds=work.ml_quoted, var=type, where=name='f1.txt', expect=File, desc=Q2 f1 is file);
%qc_expect_colval(ds=work.ml_quoted, var=path, where=name='f1.txt', expect=&_QCSB_D1_.\f1.txt, desc=Q3 member path unquoted);

%qc_end;
