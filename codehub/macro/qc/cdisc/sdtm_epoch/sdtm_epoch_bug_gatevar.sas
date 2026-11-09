/*===============================================================================
 * sdtm_epoch_bug_gatevar.sas - Bug regression: mapping gated on hard-coded VSDTC
 *===============================================================================
 * Macro under test : %sdtm_epoch
 * Expected         : EPOCH is selected by the date variable named in DTC=, and
 *                    an unrelated VSDTC column must not affect the result
 * Status           : OPEN
 * Original defect  : the match block is controlled by a hard-coded "if vsdtc^=''"
 *                    test. DATA= without VSDTC leaves every record unmapped and
 *                    adds a spurious numeric VSDTC to OUT=, so the documented
 *                    DTC= contract is not met unless VSDTC happens to exist
 * Test passes when the defect is fixed (run_all then reports FIXED)
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

%qc_begin(prog=sdtm_epoch_bug_gatevar, macro=sdtm_epoch);

data se_bug;
  length usubjid $10 sestdtc seendtc $20 epoch $30;
  usubjid='S01'; sestdtc='2024-01-01'; seendtc='2024-01-15'; epoch='SCRN'; output;
  usubjid='S01'; sestdtc='2024-01-15'; seendtc='2024-02-01'; epoch='TRT';  output;
  usubjid='S01'; sestdtc='2024-02-01'; seendtc='2024-03-01'; epoch='FU';   output;
run;

/* case 1: documented use, DATA= has no VSDTC column */
data ae_bug1;
  length usubjid $10 ddtc $20;
  usubjid='S01'; seq=1; ddtc='2024-01-05'; output;
run;
%sdtm_epoch(data=work.ae_bug1, se=work.se_bug, dtc=ddtc, out=work.bug1_out);

%qc_case(desc=1 DTC-only mapping must not require VSDTC);
%qc_expect_ds(ds=work.bug1_out, desc=C1 output dataset created);
%qc_expect_colval(ds=work.bug1_out, var=epoch, where=usubjid='S01' and seq=1, expect=SCRN, desc=C1 event inside SCRN maps to SCRN);

/* case 2: VSDTC exists but is missing, DTC is populated */
data ae_bug2;
  length usubjid $10 ddtc vsdtc $20;
  usubjid='S01'; seq=1; ddtc='2024-01-05'; vsdtc=''; output;
run;
%sdtm_epoch(data=work.ae_bug2, se=work.se_bug, dtc=ddtc, out=work.bug2_out);

%qc_case(desc=2 missing VSDTC must not suppress DTC mapping);
%qc_expect_ds(ds=work.bug2_out, desc=C2 output dataset created);
%qc_expect_colval(ds=work.bug2_out, var=epoch, where=usubjid='S01' and seq=1, expect=SCRN, desc=C2 event inside SCRN maps to SCRN);

/* case 3: VSDTC points at another epoch, the range test must still use DTC */
data ae_bug3;
  length usubjid $10 ddtc vsdtc $20;
  usubjid='S01'; seq=1; ddtc='2024-01-05'; vsdtc='2024-02-05'; output;
run;
%sdtm_epoch(data=work.ae_bug3, se=work.se_bug, dtc=ddtc, out=work.bug3_out);

%qc_case(desc=3 unrelated VSDTC value must not redirect the match);
%qc_expect_ds(ds=work.bug3_out, desc=C3 output dataset created);
%qc_expect_colval(ds=work.bug3_out, var=epoch, where=usubjid='S01' and seq=1, expect=SCRN, desc=C3 event maps by DTC not by VSDTC);

%qc_end;
