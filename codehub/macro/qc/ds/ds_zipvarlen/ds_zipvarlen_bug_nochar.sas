/*===============================================================================
 * ds_zipvarlen_bug_nochar.sas - Regression test: ERROR noise on no-char dataset
 *===============================================================================
 * Defect       : when the input dataset has NO character variables, %cvarlist
 *               resolves to an empty string and
 *                   %let cvarcount=%sysfunc(countw(&cvarlist.));
 *               is submitted as countw() with no argument, which makes SAS log
 *                   ERROR: Argument ... COUNTW ... too few
 *               The macro still finishes correctly (it falls through to the
 *               "contains none character variables" branch), so the defect is
 *               log pollution rather than a wrong result.
 * Root cause   : countw() must be guarded, e.g.
 *                   %if %bquote(&cvarlist.)^=%str() %then %let cvarcount=%sysfunc(countw(&cvarlist.));
 *                   %else %let cvarcount=0;
 * Expected     : (once fixed) no ERROR line in the log; the assertions below
 *                keep passing and the log becomes clean
 * Current      : DEFECT - assertions pass but an ERROR is emitted
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
%include "&_QCDEV_DS_.\ds_varlist.sas";
%include "&_QCDEV_DS_.\ds_zipvarlen.sas";

%qc_begin(prog=ds_zipvarlen_bug_nochar, macro=ds_zipvarlen);
%qc_case(desc=B1 numeric-only dataset must not emit ERROR);

data zvb1;
  n1=1; n2=2;
run;

/* reset the condition code, then run the macro under test */
%let _syscc_before=&syscc.;
%ds_zipvarlen(data=zvb1);
%let _syscc_after=&syscc.;

/* syscc becomes non-zero (1012 = ERROR) because countw() was called with no
 * argument: the defect is reproduced whenever the code is NOT 0/4 */
%qc_check_eq(actual=&_syscc_after., expect=&_syscc_before.,
  desc=B1 no ERROR raised by macro (syscc unchanged));

/* functional behaviour must stay correct in any case */
%qc_check_eq(actual=%ds_attr(data=zvb1,attr=nvars), expect=2,
  desc=B1 nvars unchanged);
%qc_check_eq(actual=%ds_attr(data=zvb1,attr=nobs), expect=1,
  desc=B1 nobs unchanged);
%qc_expect_len(ds=zvb1, var=n1, expect=8, desc=B1 numeric length untouched);

%qc_end;