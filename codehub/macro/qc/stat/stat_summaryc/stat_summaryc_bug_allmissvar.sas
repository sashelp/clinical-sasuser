/*==============================================================================
 * stat_summaryc_bug_allmissvar.sas - Bug regression: VAR= entirely missing produces no classified columns
 *==============================================================================
 * Macro under test : %stat_summaryc
 * Expected         : one total row per analysis variable with n(miss) counts,
 *                    e.g. trt1='0(2)' trt2='0(2)' trt0='0(4)'
 * Status           : OPEN 2026-11-01
 * Original defect  : PROC FREQ creates no crosstabfreqs output when every
 *                    VAR= value is missing; the following steps then issue
 *                    "File WORK.STAT_SUMMARYC_FREQS.DATA does not exist" and
 *                    the output keeps only the metadata variables
 * Fix              : skip the FREQ/percent step when the analysis variable has
 *                    no non-missing value and build the total row directly
 * Test passes when  the defect is fixed (run_all then reports FIXED)
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
%include "&_QCDEV_STAT_.\stat_summaryc.sas";

%qc_begin(prog=stat_summaryc_bug_allmissvar, macro=stat_summaryc);

%macro _qc_rows(ds=, where=, expect=1, desc=);
  %local rc;
  proc sql noprint;
    select count(*) into :rc from &ds. where &where.;
  quit;
  %qc_check_eq(actual=&rc., expect=&expect., desc=&desc.);
%mend _qc_rows;

/* analysis variable missing for every record; class A=2, B=2 */
data sc_missvar;
  length trt $1 sex $1;
  input trt $ sex $;
  datalines;
A .
B .
A .
B .
;
run;

%stat_summaryc(data=sc_missvar, out=ob2, class=trt, var=sex);

%qc_case(desc=1 total row reported when analysis variable is all missing);
%qc_expect_ds(ds=ob2, desc=C1 output dataset exists);
%qc_expect_nobs(ds=ob2, expect=1, desc=C1 one total row only);
%qc_expect_var(ds=ob2, var=trt1, type=C, desc=C1 class A column exists);
%_qc_rows(ds=ob2, where=_varlvl_='Total' and _statlab_='n(miss)' and trt1='0(2)' and trt2='0(2)' and trt0='0(4)', expect=1, desc=C1 total row n miss counts);

%qc_end;
