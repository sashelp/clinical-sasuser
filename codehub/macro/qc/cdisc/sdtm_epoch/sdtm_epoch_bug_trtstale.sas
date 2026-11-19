/*===============================================================================
 * sdtm_epoch_bug_trtstale.sas - Bug regression: stale TRT values when unmatched
 *===============================================================================
 * Macro under test : %sdtm_epoch
 * Expected         : an event outside every SE interval stays unmapped, even
 *                    when the treatment EPOCH is the last SE record
 * Status           : OPEN 2026-11-09 - TRTEPOCH= boundary branch added
 * Original defect  : the TRTEPOCH branch has no final else call missing(), so a
 *                    non-matching TRT record leaves its SESTDTC/SEENDTC/EPOCH in
 *                    the PDV; when it is the last record the event is mapped to
 *                    TRT although DTC is in a gap or before the first SESTDTC
 * Fix              : add else call missing(sestdtc,seendtc,epoch) at the end of
 *                    the if epoch=&trtepoch. do block
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

data se_stale;
  length usubjid $10 sestdtc seendtc $20 epoch $30;
  usubjid='S01'; sestdtc='2024-01-01'; seendtc='2024-01-15'; epoch='SCRN'; output;
  usubjid='S01'; sestdtc='2024-02-01'; seendtc='2024-02-15'; epoch='TRT';  output;
run;
data in_stale;
  length usubjid $10 ddtc $20;
  usubjid='S01'; seq=1; ddtc='2024-01-20'; output;
  usubjid='S01'; seq=2; ddtc='2023-12-01'; output;
run;

%qc_begin(prog=sdtm_epoch_bug_trtstale, macro=sdtm_epoch);
%sdtm_epoch(data=work.in_stale, se=work.se_stale, dtc=ddtc, trtepoch="TRT", out=work.stale_out);

%qc_case(desc=1 DTC in the gap must stay unmapped);
%qc_expect_ds(ds=work.stale_out, desc=C1 output dataset created);
%qc_expect_colval(ds=work.stale_out, var=epoch, where=usubjid='S01' and seq=1, expect=, desc=C1 gap event has blank EPOCH);
%qc_expect_colval(ds=work.stale_out, var=sestdtc, where=usubjid='S01' and seq=1, expect=, desc=C1 gap event has blank SESTDTC);

%qc_case(desc=2 DTC before first SESTDTC must stay unmapped);
%qc_expect_colval(ds=work.stale_out, var=epoch, where=usubjid='S01' and seq=2, expect=, desc=C2 early event has blank EPOCH);

%qc_end;
