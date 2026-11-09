/*===============================================================================
 * lib_zipvarlen_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %lib_zipvarlen
 * File under test   : dev/lib/lib_zipvarlen.sas
 * Dependency        : %ds_zipvarlen
 * Coverage          : library-wide shrink to the max used length across data
 *                     sets, per-dataset shrink, DELFMT=N keeps formats, numeric
 *                     variables untouched, all-character-free library is a no-op.
 * Note              : the macro MODIFIES the whole library irreversibly, so each
 *                     case builds a throw-away library under the temporary
 *                     sandbox.
 * Note              : SUPP_POLICY=FDA (default) means "per current dataset"
 *                     (implemented by calling %ds_zipvarlen on every member),
 *                     while the joint pass excludes SUPP* datasets.
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
%include "&_QCDEV_DS_.\ds_attr.sas";
%include "&_QCDEV_DS_.\ds_varlist.sas";
%include "&_QCDEV_DS_.\ds_zipvarlen.sas";
%include "&_QCDEV_LIB_.\lib_zipvarlen.sas";
%qc_sandbox_reset;

/*==============================================================================
 * helper: build a small, known library at <sandbox>\<libref>
 *============================================================================*/
%macro _qc_build_lzl(libref=);
  %let _lzdir_=&_QCSB_.\&libref.;
  %_qc_sb_del(path=&_lzdir_.);
  data _null_;
    rc=dcreate("&libref.", "&_QCSB_.\");
  run;
  libname &libref. "&_lzdir_.";
%mend _qc_build_lzl;

%qc_begin(prog=lib_zipvarlen_test, macro=lib_zipvarlen);

/*----------------------------------------------------------------------------
 * CASE 1 : two datasets with the same char variable name -- FDA policy (default)
 *          sets the length to the longest value across NON-SUPP data sets in
 *          the library (the joint pass in section 2.2), so both data sets end
 *          up with the shared maximum.
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 library-wide shrink);
%_qc_build_lzl(libref=lz1);

data lz1.ds1;
  length name $40 code $20;
  name='ab'; code='x';
run;
data lz1.ds2;
  length name $40 code $20;
  name='abcdef'; code='yz';
run;
%lib_zipvarlen(library=lz1);
%qc_expect_len(ds=lz1.ds1, var=name, expect=6,  desc=C1 ds1 name shared max 6);
%qc_expect_len(ds=lz1.ds1, var=code, expect=2,  desc=C1 ds1 code shared max 2);
%qc_expect_len(ds=lz1.ds2, var=name, expect=6,  desc=C1 ds2 name stays 6);
%qc_expect_len(ds=lz1.ds2, var=code, expect=2,  desc=C1 ds2 code stays 2);
%qc_expect_nobs(ds=lz1.ds1, expect=1, desc=C1 ds1 observation kept);
%qc_expect_nobs(ds=lz1.ds2, expect=1, desc=C1 ds2 observation kept);
libname lz1 clear;

/*----------------------------------------------------------------------------
 * CASE 2 : numeric variables are never touched
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 numeric untouched);
%_qc_build_lzl(libref=lz2);
data lz2.num;
  length c $30;
  c='abc'; n1=1; n2=2.5;
run;
%lib_zipvarlen(library=lz2);
%qc_expect_len(ds=lz2.num, var=c,  expect=3, desc=C2 char shrunk to 3);
%qc_expect_len(ds=lz2.num, var=n1, expect=8, desc=C2 n1 still numeric length 8);
%qc_expect_len(ds=lz2.num, var=n2, expect=8, desc=C2 n2 still numeric length 8);
libname lz2 clear;

/*----------------------------------------------------------------------------
 * CASE 3 : DELFMT=N / DELINFMT=N keep the original format / informat
 *          (the parameter is forwarded to the inner %ds_zipvarlen call;
 *          regression is locked by lib_zipvarlen_bug_delfmt.sas)
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 DELFMT=N keeps format);
%_qc_build_lzl(libref=lz3);
data lz3.fmt;
  length c $30;
  c='abc';
  format c $30.;
run;
%lib_zipvarlen(library=lz3,delfmt=n,delinfmt=n);
%qc_expect_len(ds=lz3.fmt, var=c, expect=3, desc=C3 length shrunk to 3);
%qc_expect_fmt(ds=lz3.fmt, var=c, expect=$30., desc=C3 format kept with DELFMT=N);
libname lz3 clear;

/*----------------------------------------------------------------------------
 * CASE 4 : library with only numeric variables is left unchanged
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 numeric-only library no-op);
%_qc_build_lzl(libref=lz4);
data lz4.onlynum;
  a=1; b=2;
run;
%lib_zipvarlen(library=lz4);
%qc_check_eq(actual=%ds_attr(data=lz4.onlynum,attr=nvars), expect=2,
  desc=C4 nvars unchanged);
%qc_expect_nobs(ds=lz4.onlynum, expect=1, desc=C4 observation kept);
libname lz4 clear;

%qc_end;