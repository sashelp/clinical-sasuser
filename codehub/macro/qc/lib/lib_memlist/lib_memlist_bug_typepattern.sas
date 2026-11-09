/*===============================================================================
 * lib_memlist_bug_typepattern.sas - Regression test: TYPE= + PATTERN= together
 *===============================================================================
 * Defect       : in dev/lib/lib_memlist.sas the parameter checks form a single
 *                %ELSE IF chain:
 *                    %else %if %quote(&type.)^=%str() %then %do; ... %end;
 *                    %else %if %bquote(&pattern.)^=%str() %then %do;
 *                      %let pat=%sysfunc(prxparse(...));
 *                    %end;
 *                As soon as TYPE= is non-empty the first branch is taken, so the
 *                PATTERN branch is skipped and %let pat=... never executes.
 *                The core loop then calls prxmatch(&pat.,...) with an EMPTY
 *                pattern, producing:
 *                    ERROR: The regular expression passed to PRXMATCH contains
 *                           a syntax error.
 *                and the macro terminates without returning a member list.
 * Root cause   : PATTERN validation must not be an %ELSE branch of the TYPE
 *                check; both must be evaluated (two independent %IF blocks).
 * Expected     : (once fixed) TYPE=DATA + PATTERN= returns the filtered list
 * Current      : DEFECT - the call aborts / emits ERROR instead of filtering
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

/* dedicated scratch library with a fixed, known content */
%let _lmlib_=&_QCSB_.\_lib_memlist_bug;
%_qc_sb_del(path=&_lmlib_.);
data _null_;
  rc=dcreate("_lib_memlist_bug","&_QCSB_.\");
run;
libname lmb "&_lmlib_.";
data lmb.alpha; x=1; run;
data lmb.beta;  y=2; run;
proc sql;
  create view lmb.alphavw as select x from lmb.alpha;
quit;

%qc_begin(prog=lib_memlist_bug_typepattern, macro=lib_memlist);
%qc_case(desc=B1 TYPE plus PATTERN must return the filtered list);

%let _syscc_before=&syscc.;
%let _pat=%nrstr(/^ALPHA/);
%let _r=%lib_memlist(library=lmb,type=data,pattern=%superq(_pat));
%let _syscc_after=&syscc.;

/* a non-zero syscc means the macro raised an ERROR instead of filtering */
%qc_check_eq(actual=&_syscc_after., expect=&_syscc_before.,
  desc=B1 no ERROR raised for TYPE plus PATTERN);

/* expected result once fixed: only the data set ALPHA matches ^ALPHA in TYPE=DATA */
%qc_check_eq(actual=&_r., expect=ALPHA,
  desc=B1 TYPE=DATA with pattern ^ALPHA returns ALPHA);

%qc_end;

libname lmb clear;