/*===============================================================================
 * lib_zipvarlen_bug_delfmt.sas - Regression test: DELFMT= / DELINFMT= ignored
 *===============================================================================
 * Defect       : dev/lib/lib_zipvarlen.sas section 2.1 calls the per-dataset
 *                worker without forwarding its own DELFMT= / DELINFMT=:
 *                    call execute('%ds_zipvarlen(data='||memname||')');
 *                The inner %ds_zipvarlen therefore always runs with its default
 *                DELFMT=Y / DELINFMT=Y, replacing formats/informats with $n.
 *                even when the user asked DELFMT=N / DELINFMT=N.
 * Root cause   : missing delfmt=/delinfmt= forwarding in the call execute().
 * Expected     : (once fixed) %lib_zipvarlen(...,delfmt=n,delinfmt=n) keeps the
 *                original format $30.
 * Current      : DEFECT - the format is replaced by $3.
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
%include "&_QCDEV_DS_.\ds_attr.sas";
%include "&_QCDEV_DS_.\ds_varlist.sas";
%include "&_QCDEV_DS_.\ds_zipvarlen.sas";
%include "&_QCDEV_LIB_.\lib_zipvarlen.sas";
%qc_sandbox_reset;

/* dedicated scratch library */
%let _lzbug_=&_QCSB_.\_lib_zipvarlen_bug;
%_qc_sb_del(path=&_lzbug_.);
data _null_;
  rc=dcreate("_lib_zipvarlen_bug","&_QCSB_.\");
run;
libname lzb "&_lzbug_.";
data lzb.fmt;
  length c $30;
  c='abc';
  format c $30.;
run;

%qc_begin(prog=lib_zipvarlen_bug_delfmt, macro=lib_zipvarlen);
%qc_case(desc=B1 DELFMT=N must keep the original format);

%lib_zipvarlen(library=lzb,delfmt=n,delinfmt=n);

/* once fixed, the $30. format survives */
%qc_expect_fmt(ds=lzb.fmt, var=c, expect=$30., desc=B1 format kept with DELFMT=N);

%qc_end;

libname lzb clear;