/*==============================================================================
 * stat_rateci_bug_riskdifflevel.sas - Bug regression: rate difference uses the wrong level
 *==============================================================================
 * Macro under test : %stat_rateci
 * Expected         : every risk difference equals
 *                    rate(CLASS=) - rate(ref CLASS=) at the LEVEL= requested
 * Status           : OPEN
 * Original defect  : 2.3.2 computes "column=&levelnumber." once from the first
 *                    two observations of stat_rateci_pairwise, but PROC FREQ
 *                    with ORDER=DATA builds the column order from the row
 *                    order of each BY group. When one class lists its VAR=
 *                    values in the opposite order, the difference of that pair
 *                    is computed for the other level, so the sign or the value
 *                    is wrong while no error is reported
 * Fix              : force a stable column order before PROC FREQ, e.g. sort
 *                    stat_rateci_pairwise by _pair_ &BY. and a flag that puts
 *                    the LEVEL= row first for every class, so column= always
 *                    points to the requested level
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

%qc_begin(prog=stat_rateci_bug_riskdifflevel, macro=stat_rateci);

data rates;
  length subj $12 study $2 trt $1 sex $1 resp $1;
  retain _k 0;
  input study $ trt $ sex $ resp $ n;
  do i=1 to n;
    _k+1;
    subj=cats(trt,sex,_k);
    output;
  end;
  drop n i;
datalines;
S1 A M Y 3
S1 A M N 7
S1 A F Y 2
S1 A F N 8
S1 B M Y 6
S1 B M N 4
S1 B F Y 5
S1 B F N 5
;
run;

/*----------------------------------------------------------------------------
 * CASE 1 : two class levels, two BY levels
 *   sex=F : A 20 % B 50 %  -> A-B = -30  (correctly reported)
 *   sex=M : A 30 % B 60 %  -> A-B = -30  (macro reports +30 for A-B)
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 difference must equal rate of CLASS minus rate of ref CLASS);
%stat_rateci(data=rates, out=b1, by=sex, class=trt, var=resp, level=%str('Y'),
             smethod=WALD, dmethod=WALD, debug=0);
proc sql noprint;
  select count(*) into :b1bad from b1 d, b1 sa, b1 sb
    where not missing(d.ref_trt)
      and missing(sa.ref_trt) and missing(sb.ref_trt)
      and sa.sex=d.sex and sb.sex=d.sex
      and sa.trt=d.trt and sb.trt=d.ref_trt
      and abs(d._prop_ - (sa._prop_ - sb._prop_))>0.01;
quit;
%qc_check_eq(actual=&b1bad., expect=0, desc=B1 no pair reported at the wrong level);

/*----------------------------------------------------------------------------
 * CASE 2 : three class levels in one BY group
 *   A 30 % B 50 % C 10 % -> B-A must be +20 and B-C must be +40
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 three class levels keep the same level orientation);
data rates3;
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
S1 A Y 3
S1 A N 7
S1 B Y 5
S1 B N 5
S1 C Y 1
S1 C N 9
;
run;
%stat_rateci(data=rates3, out=b2, by=study, class=trt, var=resp, level=%str('Y'),
             smethod=WALD, dmethod=WALD, debug=0);
proc sql noprint;
  select count(*) into :b2bad from b2 d, b2 sa, b2 sb
    where not missing(d.ref_trt)
      and missing(sa.ref_trt) and missing(sb.ref_trt)
      and sa.study=d.study and sb.study=d.study
      and sa.trt=d.trt and sb.trt=d.ref_trt
      and abs(d._prop_ - (sa._prop_ - sb._prop_))>0.01;
quit;
%qc_check_eq(actual=&b2bad., expect=0, desc=B2 no pair reported at the wrong level);

%qc_end;
