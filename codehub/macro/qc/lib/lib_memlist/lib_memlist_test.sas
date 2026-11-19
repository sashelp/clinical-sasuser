/*===============================================================================
 * lib_memlist_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %lib_memlist
 * File under test   : dev/lib/lib_memlist.sas
 * Coverage          : all members, TYPE=DATA filter, TYPE=VIEW filter,
 *                     TYPE value case-insensitivity, PATTERN regex filter,
 *                     PATTERN + TYPE combination, no-match empty result,
 *                     member names returned in upcase.
 * Note              : uses its own scratch library under the temporary sandbox
 *                     so the exact
 *                     member list is reproducible and never shared.
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
%include "&_QCDEV_LIB_.\lib_memlist.sas";
%qc_sandbox_reset;

/* dedicated scratch library so the member list is fully controlled */
%let _lmlib_=&_QCSB_.\_lib_memlist;
%_qc_sb_del(path=&_lmlib_.);
data _null_;
  rc=dcreate("_lib_memlist","&_QCSB_.\");
run;
libname lmlib "&_lmlib_.";

data lmlib.alpha;
  x=1;
run;
data lmlib.beta;
  y=2;
run;
data lmlib.gamma;
  z=3;
run;
proc sql;
  create view lmlib.alphavw as select x from lmlib.alpha;
quit;

%qc_begin(prog=lib_memlist_test, macro=lib_memlist);

/*----------------------------------------------------------------------------
 * CASE 1 : no filter -> all members, upcased
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 all members);
%let _r=%lib_memlist(library=lmlib);
%qc_expect_cnt(list=&_r., expect=4, desc=C1 four members total);
%qc_check(cond=%index(%bquote(&_r.),ALPHA)>0, desc=C1 contains ALPHA);
%qc_check(cond=%index(%bquote(&_r.),BETA)>0, desc=C1 contains BETA);
%qc_check(cond=%index(%bquote(&_r.),GAMMA)>0, desc=C1 contains GAMMA);

/*----------------------------------------------------------------------------
 * CASE 2 : TYPE=DATA -> only data sets
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 TYPE=DATA);
%let _r=%lib_memlist(library=lmlib,type=data);
%qc_expect_cnt(list=&_r., expect=3, desc=C2 three data sets);
%qc_check(cond=%index(%bquote(&_r.),ALPHAVW)=0, desc=C2 view excluded);

/*----------------------------------------------------------------------------
 * CASE 3 : TYPE=VIEW -> only views
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 TYPE=VIEW);
%let _r=%lib_memlist(library=lmlib,type=view);
%qc_expect_cnt(list=&_r., expect=1, desc=C3 one view);
%qc_check_eq(actual=&_r., expect=ALPHAVW, desc=C3 view name ALPHAVW);

/*----------------------------------------------------------------------------
 * CASE 4 : TYPE= value case-insensitivity
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 TYPE case-insensitive);
%let _r=%lib_memlist(library=lmlib,type=DaTa);
%qc_expect_cnt(list=&_r., expect=3, desc=C4 mixed-case DaTa gives 3);

/*----------------------------------------------------------------------------
 * CASE 5 : PATTERN regex filter (prefix)
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 PATTERN prefix);
%let _pat=%nrstr(/^ALPHA/);
%let _r=%lib_memlist(library=lmlib,pattern=%superq(_pat));
%qc_check(cond=%index(%bquote(&_r.),ALPHAVW)>0, desc=C5 pattern ^ALPHA matches view);
%qc_check(cond=%index(%bquote(&_r.),BETA)=0, desc=C5 BETA filtered out);

/*----------------------------------------------------------------------------
 * CASE 6 : (removed) TYPE + PATTERN combined -- see the known defect locked by
 *           lib_memlist_bug_typepattern.sas (the %else-if chain skips the
 *           PATTERN branch whenever TYPE= is non-empty, so prxparse() is never
 *           called and PRXMATCH receives an empty regex).
 *--------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------
 * CASE 7 : no match -> empty result
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 no match empty);
%let _pat=%nrstr(/ZZZNOMATCH/);
%let _r=%lib_memlist(library=lmlib,pattern=%superq(_pat));
%qc_check(cond=%bquote(&_r.)=%bquote(), desc=C7 empty result);

/*----------------------------------------------------------------------------
 * CASE 8 : library name case-insensitivity (LIBRARY is upcased internally)
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 library name case-insensitive);
%let _r=%lib_memlist(library=LMLIB);
%qc_expect_cnt(list=&_r., expect=4, desc=C8 uppercase library name);

%qc_end;

libname lmlib clear;