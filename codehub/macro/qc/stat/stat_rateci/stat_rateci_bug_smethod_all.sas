/*==============================================================================
 * stat_rateci_bug_smethod_all.sas - Bug regression: SMETHOD=ALL omits Blaker
 *==============================================================================
 * Macro under test : %stat_rateci
 * Expected         : SMETHOD=ALL also computes the Blaker interval, as stated
 *                    in the macro header ("ALL: Requests AC, BLAKER, EXACT,
 *                    JEFFREYS, WALD and WILSON confidence limits")
 * Status           : FIXED 2026-10-30 - ALL expanded to AC BLAKER EXACT JEFFREYS LR LOGIT MIDP WALD WILSON
 * Original defect  : SMETHOD=ALL is forwarded as "cl=(ALL)"; in PROC FREQ the
 *                    ALL keyword expands to Agresti-Coull, Exact, Jeffreys,
 *                    Wald and Wilson only, so the Blaker row requested by the
 *                    macro documentation is silently missing
 * Fix              : expand ALL explicitly, e.g.
 *                    cl=(AC BLAKER EXACT JEFFREYS WALD WILSON)
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
%include "&_QCDEV_VAR_.\var_exist.sas";
%include "&_QCDEV_VAR_.\var_coexist.sas";
%include "&_QCDEV_DS_.\ds_attr.sas";
%include "&_QCDEV_STAT_.\stat_rateci.sas";

data rates;
  length subj $12 study $2 trt $1 resp $1;
  retain _k 0;
  input study $ trt $ resp $ n;
  do i=1 to n;
    _k+1;
    subj=cats(trt,_k);
    output;
  end;
  drop n i;
datalines;
S1 A Y 5
S1 A N 15
S1 B Y 11
S1 B N 9
;
run;

%qc_begin(prog=stat_rateci_bug_smethod_all, macro=stat_rateci);

%qc_case(desc=1 SMETHOD ALL must include the Blaker interval);
%stat_rateci(data=rates, out=bug3, by=study, class=trt, var=resp, level=%str('Y'),
             smethod=ALL, dmethod=NONE, debug=0);
proc sql noprint;
  select count(*) into :b1bk from bug3 where trt='A' and _method_='Blaker';
quit;
%qc_check_eq(actual=&b1bk., expect=1, desc=B1 Blaker interval present for class A);

%qc_end;
