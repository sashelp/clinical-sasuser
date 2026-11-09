/*==============================================================================
 * qc_framework.sas - Macro Testing Framework
 *==============================================================================
 * Brief      : Lightweight SAS macro acceptance-test framework.
 *              Provides a uniform logging/assertion protocol so that each
 *              test file (positive or negative) emits machine-readable
 *              markers which are parsed by qc/run_all.ps1.
 *
 * Design rules
 *  - Positive tests : one file per macro, several %qc_case() blocks, and a
 *                     final %qc_end() which prints a QC_RESULT summary line.
 *  - Negative tests : one scenario per file.  The macro under test is invoked
 *                     and is EXPECTED to %abort cancel (or produce an ERROR).
 *                     Because %abort cancel stops the whole SAS session, each
 *                     negative scenario MUST run in its own SAS invocation.
 *                     The test file stores the expected error text in the
 *                     *EXPECTED_ERROR* comment so run_all.ps1 can verify that
 *                     the job died for the right reason.
 *
 * Protocol markers written to the SAS log
 *   #####QC_BEGIN prog=<prog> macro=<macro>
 *   #####QC_CASE n=<n> desc=<desc>
 *   #####QC_PASS  n=<n> desc=<desc>
 *   #####QC_FAIL  n=<n> desc=<desc> [info]
 *   #####QC_RESULT prog=<prog> macro=<macro> STATUS=PASS|FAIL ncase= npass= nfail=
 *   #####QC_ABORT_MARKER
 *   #####QC_UNEXPECTED_CONTINUE
 * History    : 2026-10-28, QC harness v1
 *============================================================================*/

%macro qc_begin(prog=, macro=);
  %global _qc_pass _qc_fail _qc_n _qc_prog _qc_macro;
  %let _qc_pass=0;
  %let _qc_fail=0;
  %let _qc_n=0;
  %let _qc_prog=&prog.;
  %let _qc_macro=&macro.;
  %put %str(#####)QC_BEGIN prog=&prog. macro=&macro.;
%mend qc_begin;

%macro qc_case(desc=);
  %let _qc_n=%eval(&_qc_n.+1);
  %put %str(#####)QC_CASE n=&_qc_n. desc=&desc.;
%mend qc_case;

/* qc_check : boolean / numeric expression, printed as PASS or FAIL */
%macro qc_check(cond=, desc=);
  %if %sysevalf(&cond.,boolean) %then %do;
    %let _qc_pass=%eval(&_qc_pass.+1);
    %put %str(#####)QC_PASS n=&_qc_n. desc=&desc.;
  %end;
  %else %do;
    %let _qc_fail=%eval(&_qc_fail.+1);
    %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc.;
  %end;
%mend qc_check;

/* qc_check_eq : text equality; both values are normalized (compbl+strip) and
 * compared. Because macro return values such as -1 would be misinterpreted
 * when placed directly inside a macro call, callers should first store the
 * macro return into a macro variable (e.g. %let r=%macro();) and pass &r.
 */
%macro qc_check_eq(actual=, expect=, desc=);
  %let _qc_a=%qsysfunc(strip(%qsysfunc(compbl(%bquote(&actual.)))));
  %let _qc_e=%qsysfunc(strip(%qsysfunc(compbl(%bquote(&expect.)))));
  %if %bquote(&_qc_a.)=%bquote(&_qc_e.) %then %do;
    %let _qc_pass=%eval(&_qc_pass.+1);
    %put %str(#####)QC_PASS n=&_qc_n. desc=&desc.;
  %end;
  %else %do;
    %let _qc_fail=%eval(&_qc_fail.+1);
    %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [actual=%bquote(&_qc_a.) expect=%bquote(&_qc_e.)];
  %end;
%mend qc_check_eq;

/* qc_expect_var : check var exists in ds, optionally with type C/N */
%macro qc_expect_var(ds=, var=, type=, desc=);
  %local _did _rc;
  %let _did=%sysfunc(open(&ds.));
  %if &_did.=0 %then %do;
    %let _qc_fail=%eval(&_qc_fail.+1);
    %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [dataset &ds. cannot be opened];
  %end;
  %else %do;
    %let _rc=%sysfunc(varnum(&_did.,&var.));
    %if &_rc.=0 %then %do;
      %let _qc_fail=%eval(&_qc_fail.+1);
      %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [var &ds..&var. not found];
    %end;
    %else %if %bquote(&type.)=%str() %then %do;
      %let _qc_pass=%eval(&_qc_pass.+1);
      %put %str(#####)QC_PASS n=&_qc_n. desc=&desc.;
    %end;
    %else %do;
      %local _qt;
      %let _qt=%sysfunc(vartype(&_did.,&_rc.));
      %if %upcase(&type.)=%bquote(&_qt.) %then %do;
        %let _qc_pass=%eval(&_qc_pass.+1);
        %put %str(#####)QC_PASS n=&_qc_n. desc=&desc.;
      %end;
      %else %do;
        %let _qc_fail=%eval(&_qc_fail.+1);
        %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [var type is &_qt., expected &type.];
      %end;
    %end;
    %let _rc=%sysfunc(close(&_did.));
  %end;
%mend qc_expect_var;
/* qc_expect_ds : check dataset exists */
%macro qc_expect_ds(ds=, desc=);
  %if %sysfunc(exist(&ds.)) %then %do;
    %let _qc_pass=%eval(&_qc_pass.+1);
    %put %str(#####)QC_PASS n=&_qc_n. desc=&desc.;
  %end;
  %else %do;
    %let _qc_fail=%eval(&_qc_fail.+1);
    %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [dataset &ds. not found];
  %end;
%mend qc_expect_ds;

/* qc_expect_nobs : check number of observations */
%macro qc_expect_nobs(ds=, expect=, desc=);
  %local _did _nobs;
  %let _did=%sysfunc(open(&ds.));
  %if &_did.=0 %then %do;
    %let _qc_fail=%eval(&_qc_fail.+1);
    %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [dataset &ds. cannot be opened];
  %end;
  %else %do;
    %let _nobs=%sysfunc(attrn(&_did.,nobs));
    %let _did=%sysfunc(close(&_did.));
    %if &_nobs.=&expect. %then %do;
      %let _qc_pass=%eval(&_qc_pass.+1);
      %put %str(#####)QC_PASS n=&_qc_n. desc=&desc.;
    %end;
    %else %do;
      %let _qc_fail=%eval(&_qc_fail.+1);
      %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [nobs=&_nobs., expect=&expect.];
    %end;
  %end;
%mend qc_expect_nobs;

/* qc_unexpected_continue : used by negative tests; reached only if the macro
 * under test did NOT abort -> test FAILED */
%macro qc_unexpected_continue;
  %let _qc_fail=%eval(&_qc_fail.+1);
  %put %str(#####)QC_UNEXPECTED_CONTINUE n=&_qc_n.;
%mend qc_unexpected_continue;

/* qc_abort_marker : printed right before the invocation that must abort */
%macro qc_abort_marker;
  %put %str(#####)QC_ABORT_MARKER n=&_qc_n.;
%mend qc_abort_marker;

/* qc_end : print summary line */
%macro qc_end;
  %local _status;
  %if &_qc_fail.=0 %then %let _status=PASS;
  %else                  %let _status=FAIL;
  %put %str(#####)QC_RESULT prog=&_qc_prog. macro=&_qc_macro. STATUS=&_status. ncase=&_qc_n. npass=&_qc_pass. nfail=&_qc_fail.;
  %put %str(#####)QC_END;
%mend qc_end;
/* qc_expect_len : check physical variable length (vlength) */
%macro qc_expect_len(ds=, var=, expect=, desc=);
  %local _did _pos _len;
  %let _did=%sysfunc(open(&ds.));
  %if &_did.=0 %then %do;
    %let _qc_fail=%eval(&_qc_fail.+1);
    %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [dataset &ds. cannot be opened];
  %end;
  %else %do;
    %let _pos=%sysfunc(varnum(&_did.,&var.));
    %if &_pos.=0 %then %do;
      %let _qc_fail=%eval(&_qc_fail.+1);
      %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [var &ds..&var. not found];
    %end;
    %else %do;
      %let _len=%sysfunc(varlen(&_did.,&_pos.));
      %if &_len.=&expect. %then %do;
        %let _qc_pass=%eval(&_qc_pass.+1);
        %put %str(#####)QC_PASS n=&_qc_n. desc=&desc.;
      %end;
      %else %do;
        %let _qc_fail=%eval(&_qc_fail.+1);
        %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [varlen=&_len., expected &expect.];
      %end;
    %end;
    %let _pos=%sysfunc(close(&_did.));
  %end;
%mend qc_expect_len;

/* qc_expect_fmt : check variable format (empty expect = expect NO format) */
%macro qc_expect_fmt(ds=, var=, expect=, desc=);
  %local _did _pos _fmt;
  %let _did=%sysfunc(open(&ds.));
  %if &_did.=0 %then %do;
    %let _qc_fail=%eval(&_qc_fail.+1);
    %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [dataset &ds. cannot be opened];
  %end;
  %else %do;
    %let _pos=%sysfunc(varnum(&_did.,&var.));
    %if &_pos.=0 %then %do;
      %let _qc_fail=%eval(&_qc_fail.+1);
      %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [var &ds..&var. not found];
    %end;
    %else %do;
      %let _fmt=%sysfunc(varfmt(&_did.,&_pos.));
      %if %bquote(%upcase(&_fmt.))=%bquote(%upcase(&expect.)) %then %do;
        %let _qc_pass=%eval(&_qc_pass.+1);
        %put %str(#####)QC_PASS n=&_qc_n. desc=&desc.;
      %end;
      %else %do;
        %let _qc_fail=%eval(&_qc_fail.+1);
        %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [varfmt=&_fmt., expected &expect.];
      %end;
    %end;
    %let _pos=%sysfunc(close(&_did.));
  %end;
%mend qc_expect_fmt;

/* qc_expect_file : check external file exists; expect=0 asserts NOT exist */
%macro qc_expect_file(file=, expect=1, desc=);
  %local _e;
  %let _e=%sysfunc(fileexist(&file.));
  %if &_e.=&expect. %then %do;
    %let _qc_pass=%eval(&_qc_pass.+1);
    %put %str(#####)QC_PASS n=&_qc_n. desc=&desc.;
  %end;
  %else %do;
    %let _qc_fail=%eval(&_qc_fail.+1);
    %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [fileexist=&_e., expected &expect.];
  %end;
%mend qc_expect_file;

/* qc_expect_dir : check directory exists; expect=0 asserts NOT exist.
 * Implemented with dopen() directly so the framework does not depend on
 * %dir_exist (the macro under test may be the very thing being validated). */
%macro qc_expect_dir(dir=, expect=1, desc=);
  %local _r _did;
  %let _r=0;
  %let _did=%sysfunc(dopen(%qsysfunc(dequote(&dir.))));
  %if &_did.^=0 %then %do;
    %let _r=1;
    %let _did=%sysfunc(dclose(&_did.));
  %end;
  %if &_r.=&expect. %then %do;
    %let _qc_pass=%eval(&_qc_pass.+1);
    %put %str(#####)QC_PASS n=&_qc_n. desc=&desc.;
  %end;
  %else %do;
    %let _qc_fail=%eval(&_qc_fail.+1);
    %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [dir_exists=&_r., expected &expect.];
  %end;
%mend qc_expect_dir;

/* qc_expect_cnt : number of white-space separated words in a list */
%macro qc_expect_cnt(list=, expect=, desc=);
  %local _c;
  %let _c=%sysfunc(countw(%bquote(&list.)));
  %if &_c.=&expect. %then %do;
    %let _qc_pass=%eval(&_qc_pass.+1);
    %put %str(#####)QC_PASS n=&_qc_n. desc=&desc.;
  %end;
  %else %do;
    %let _qc_fail=%eval(&_qc_fail.+1);
    %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [countw=&_c., expected &expect. list=&list.];
  %end;
%mend qc_expect_cnt;

/* qc_expect_colval : check a single numeric/char value in a dataset column */
%macro qc_expect_colval(ds=, var=, where=, expect=, desc=);
  %local _v;
  proc sql noprint;
    select &var. into :_v trimmed from &ds. %if %bquote(&where.)^=%str() %then %str(where &where.;);
  quit;
  %if %bquote(&_v.)=%bquote(&expect.) %then %do;
    %let _qc_pass=%eval(&_qc_pass.+1);
    %put %str(#####)QC_PASS n=&_qc_n. desc=&desc.;
  %end;
  %else %do;
    %let _qc_fail=%eval(&_qc_fail.+1);
    %put %str(#####)QC_FAIL n=&_qc_n. desc=&desc. [actual=&_v. expected=&expect.];
  %end;
%mend qc_expect_colval;

/*==============================================================================
 * End of qc_framework.sas
 *============================================================================*/

/*==============================================================================
 * End of qc_framework.sas
 *============================================================================*/