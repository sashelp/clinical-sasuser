/*===============================================================================
 * sdtm_epoch_bug_trtepochdefault.sas - Bug regression: TRTEPOCH= documented default
 *===============================================================================
 * Macro under test : %sdtm_epoch
 * Expected         : TRTEPOCH= is documented as optional with default "TREATMENT",
 *                    so a call without TRTEPOCH= maps the boundary to TREATMENT
 * Status           : OPEN 2026-11-09 - signature has trtepoch= with no default
 * Original defect  : Header says *Param(Opt) : (TRTEPOCH="TREATMENT") but
 *                    %macro declares trtepoch=, so the call aborts with
 *                    "ERROR: Parameter TRTEPOCH= not specified."
 * Fix              : either set trtepoch="TREATMENT" in the %macro statement,
 *                    or change the header to Param(Req) with no default
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
%include "&_QCDEV_VAR_.\var_coexist.sas";
%include "&_QCDEV_DS_.\ds_attr.sas";
%include "&_QCDEV_CDISC_.\sdtm_epoch.sas";

data ae_def;
  length usubjid $10 aestdtc $20;
  usubjid='S01'; aestdtc='2024-02-01'; output;
run;
data se_def;
  length usubjid $10 sestdtc seendtc $20 epoch $30;
  usubjid='S01'; sestdtc='2024-01-01'; seendtc='2024-01-15'; epoch='SCRN';      output;
  usubjid='S01'; sestdtc='2024-01-15'; seendtc='2024-02-01'; epoch='TREATMENT'; output;
  usubjid='S01'; sestdtc='2024-02-01'; seendtc='2024-03-01'; epoch='FU';        output;
run;

%qc_begin(prog=sdtm_epoch_bug_trtepochdefault, macro=sdtm_epoch);
%qc_case(desc=1 documented default TREATMENT applied at boundary);
%sdtm_epoch(data=work.ae_def, se=work.se_def, dtc=aestdtc, out=work.def_out);
%qc_expect_colval(ds=work.def_out, var=epoch, where=usubjid='S01', expect=TREATMENT, desc=boundary uses documented default TREATMENT);
%qc_end;
