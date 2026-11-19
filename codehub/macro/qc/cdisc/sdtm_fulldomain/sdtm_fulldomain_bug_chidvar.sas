/*===============================================================================
 * sdtm_fulldomain_bug_chidvar.sas - Bug regression: character IDVAR fails
 *===============================================================================
 * Macro under test : %sdtm_fulldomain
 * Expected         : a SUPP qualifier whose IDVAR points at a CHARACTER parent
 *                    variable (e.g. AESPID) is merged onto the parent record
 * Status           : FIXED 2026-10-29 - the key is converted only when the
 *                    parent variable type is N (%var_attr); character keys are
 *                    taken from IDVARVAL.  Kept as a regression test.
 * Original defect  : "2. Core processing" always executed
 *                      &idvar.=input(idvarval,best.);
 *                    which re-created the parent key as NUMERIC.  For a
 *                    character IDVAR the MERGE then failed:
 *                      ERROR: Variable aespid has been defined as both
 *                             character and numeric
 *                    OUT was created with 0 observations and no values.
 * Fix              : look up the type of &idvar. in PARENT (%var_attr) and only
 *                    convert IDVARVAL when the parent variable is numeric;
 *                    otherwise keep IDVARVAL as the character merge key.
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
%qc_begin(prog=sdtm_fulldomain_bug_chidvar, macro=sdtm_fulldomain);

data bug_ae;
  length usubjid $10 aeterm $20 aespid $8;
  usubjid='S01'; aeseq=1; aeterm='Headache'; aespid='1'; output;
  usubjid='S01'; aeseq=2; aeterm='Nausea'; aespid='2'; output;
run;

data bug_supp_ae;
  length usubjid $10 idvar $8 idvarval $8 qnam $8 qlabel $40 qval $20;
  label qval='Result or Finding in Original Units';
  usubjid='S01'; idvar='AESPID'; idvarval='1'; qnam='AESEV'; qlabel='Severity'; qval='MILD'; output;
run;

%qc_case(desc=1 character IDVAR must merge);
%sdtm_fulldomain(domain=ae, parent=work.bug_ae, supp=work.bug_supp_ae, out=work.bug_full);
options obs=max;
%qc_expect_ds(ds=work.bug_full, desc=B1 output dataset exists);
%qc_expect_nobs(ds=work.bug_full, expect=2, desc=B1 row count equals parent);
%qc_expect_var(ds=work.bug_full, var=AESEV, type=C, desc=B1 qualifier variable created);
%qc_expect_var(ds=work.bug_full, var=aespid, type=C, desc=B1 parent key keeps character type);

%qc_end;
