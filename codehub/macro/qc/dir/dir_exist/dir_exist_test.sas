/*===============================================================================
 * dir_exist_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %dir_exist
 * File under test   : dev/dir/dir_exist.sas
 * Dependencies     : none
 * Coverage         : existing / missing directories, nested directory, quoted
 *                    path dequoting, path supplied through a macro variable,
 *                    and a file path that must NOT be treated as a directory.
 * Note             : uses the per-program temporary sandbox built by
 *                    %qc_sandbox_reset; run_all.ps1 removes it after the run.
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
%qc_sandbox_reset;

%qc_begin(prog=dir_exist_test, macro=dir_exist);

/*----------------------------------------------------------------------------
 * CASE 1 : existing directories return 1
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 existing directory);
%let _r=%dir_exist(dir=&_QCSB_D1_.);
%qc_check_eq(actual=&_r., expect=1, desc=C1 d1 exists);
%let _r=%dir_exist(dir=&_QCSB_.);
%qc_check_eq(actual=&_r., expect=1, desc=C1 sandbox root exists);

/*----------------------------------------------------------------------------
 * CASE 2 : missing directory returns 0
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 missing directory);
%let _r=%dir_exist(dir=&_QCSB_.\no_such_dir_xyz);
%qc_check_eq(actual=&_r., expect=0, desc=C2 missing dir returns 0);

/*----------------------------------------------------------------------------
 * CASE 3 : nested directory returns 1
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 nested directory);
%let _r=%dir_exist(dir=&_QCSB_D1S1_.);
%qc_check_eq(actual=&_r., expect=1, desc=C3 nested sub1 exists);
%let _r=%dir_exist(dir=&_QCSB_D1S2_.);
%qc_check_eq(actual=&_r., expect=1, desc=C3 nested sub2 exists);

/*----------------------------------------------------------------------------
 * CASE 4 : quoted path is dequoted internally
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 quoted path);
%let _r=%dir_exist(dir="&_QCSB_D1_.");
%qc_check_eq(actual=&_r., expect=1, desc=C4 quoted d1 path exists);
%let _r=%dir_exist(dir="&_QCSB_.\no_such_dir_xyz");
%qc_check_eq(actual=&_r., expect=0, desc=C4 quoted missing path returns 0);

/*----------------------------------------------------------------------------
 * CASE 5 : path resolved from a macro variable
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 macro variable path);
%let _pv=&_QCSB_D2_.;
%let _r=%dir_exist(dir=&_pv.);
%qc_check_eq(actual=&_r., expect=1, desc=C5 macro variable d2 exists);

/*----------------------------------------------------------------------------
 * CASE 6 : a file path must return 0, not be treated as a directory
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 file path is not a directory);
%let _r=%dir_exist(dir=&_QCSB_TXT_.);
%qc_check_eq(actual=&_r., expect=0, desc=C6 file path returns 0);

%qc_end;
