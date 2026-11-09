/*===============================================================================
 * sdtm_fulldomain_bug_nolabel.sas - Bug regression: SUPP QVAL without a label
 *===============================================================================
 * Macro under test : %sdtm_fulldomain
 * Expected         : full domain built even when QVAL carries no label
 * Status           : FIXED 2026-10-29 - the merge now drops _LABEL_
 *                    conditionally (%var_coexist).  Kept as a regression test;
 *                    run_all reports FIXED while the test passes.
 * Original defect  : "2. Core processing" merged with
 *                    sdtm_fulldomain1(drop=_name_ _label_); PROC TRANSPOSE only
 *                    creates _LABEL_ when the transposed variable (QVAL) has a
 *                    label.  Without one, the DROP list is invalid:
 *                      ERROR: Variable _label_ in DROP/KEEP/RENAME list never
 *                             referenced
 *                    SAS stops the DATA step and OUT is left with 0 observations
 *                    (and WORK.SDTM_FULLDOMAIN1 is not deleted).
 * Fix              : drop _NAME_/_LABEL_ conditionally, e.g.
 *                    %if %var_exist(data=sdtm_fulldomain1,var=_LABEL_) %then ...
 *                    or use (drop=_name_ _label_ keep=...) equivalent built
 *                    from the actual metadata.
 * Test passes when  the defect is fixed (run_all then reports FIXED).
 *============================================================================*/

/*--- bootstrap: derive repo root from SYSIN, no absolute paths (qc_env.sas) ---*/
%let _qcboot_=%sysfunc(getoption(sysin));
%let _qcboot_=%substr(&_qcboot_.,1,%eval(%length(&_qcboot_.)-%length(%scan(&_qcboot_.,-1,%str(\\)))-1));
%let _qcboot_=%substr(&_qcboot_.,1,%eval(%length(&_qcboot_.)-%length(%scan(&_qcboot_.,-1,%str(\\)))-1));
%let _qcboot_=%substr(&_qcboot_.,1,%eval(%length(&_qcboot_.)-%length(%scan(&_qcboot_.,-1,%str(\\)))-1));
%include "&_qcboot_.\_framework\qc_env.sas";
%let _qcboot_=;
/*----------------------------------------------------------------------------*/

%include "&_QCFW_.";
%include "&_QCDEV_VAR_.\var_exist.sas";
%include "&_QCDEV_VAR_.\var_attr.sas";
%include "&_QCDEV_VAR_.\var_coexist.sas";
%include "&_QCDEV_CDISC_.\sdtm_fulldomain.sas";
%qc_begin(prog=sdtm_fulldomain_bug_nolabel, macro=sdtm_fulldomain);

data bug_lb;
  length usubjid $10 lbcat $8 lbtestcd $8 lborres $10;
  usubjid='S01'; lbseq=1; lbcat='CHEM'; lbtestcd='ALT'; lborres='10'; output;
  usubjid='S01'; lbseq=2; lbcat='CHEM'; lbtestcd='AST'; lborres='20'; output;
  usubjid='S02'; lbseq=1; lbcat='HEMA'; lbtestcd='HGB'; lborres='13'; output;
run;

/* identical SUPP, but QVAL has NO variable label */
data bug_supp_nolabel;
  length usubjid $10 idvar $8 idvarval $8 qnam $8 qlabel $40 qval $20;
  usubjid='S01'; idvar='LBSEQ'; idvarval='1'; qnam='LBFAST'; qlabel='Fasting Status'; qval='Y'; output;
  usubjid='S01'; idvar='LBSEQ'; idvarval='2'; qnam='LBFAST'; qlabel='Fasting Status'; qval='N'; output;
  usubjid='S02'; idvar='LBSEQ'; idvarval='1'; qnam='LBFAST'; qlabel='Fasting Status'; qval='Y'; output;
run;

%qc_case(desc=1 unlabeled QVAL must still produce a full domain);
%sdtm_fulldomain(domain=lb, parent=work.bug_lb, supp=work.bug_supp_nolabel, out=work.bug_full);
options obs=max;
%qc_expect_ds(ds=work.bug_full, desc=B1 output dataset exists);
%qc_expect_nobs(ds=work.bug_full, expect=3, desc=B1 row count equals parent);
%qc_expect_var(ds=work.bug_full, var=LBFAST, type=C, desc=B1 qualifier variable created);
%qc_expect_var(ds=work.bug_full, var=lbtestcd, desc=B1 parent variables kept);
%qc_check_eq(actual=%sysfunc(exist(work.sdtm_fulldomain1)), expect=0, desc=B1 intermediate removed);

%qc_end;
