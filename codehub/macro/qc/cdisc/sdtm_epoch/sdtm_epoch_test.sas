/*===============================================================================
 * sdtm_epoch_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %sdtm_epoch
 * File under test   : dev/cdisc/sdtm_epoch.sas
 * Dependencies     : %var_exist, %var_coexist, %ds_attr
 * Coverage          : documented DTC-only mapping, output structure and variable
 *                     attributes, SESTDTC inclusive boundary, last SEENDTC,
 *                     missing last SEENDTC, event before first SESTDTC, event
 *                     after last SEENDTC, gap between epochs, date-time value,
 *                     partial ISO8601 date, subject isolation, default OUT,
 *                     zero-observation input, multiple SUBJECT variables,
 *                     unsorted SE input, existing EPOCH overwritten, cleanup
 * Run               : qc/run_all.ps1 -Macro sdtm_epoch
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

%qc_begin(prog=sdtm_epoch_test, macro=sdtm_epoch);

/*----------------------------------------------------------------------------
 * Test data
 *   se_ep  : standard SE extract, sorted by USUBJID SESTDTC
 *            S01 SCRN/TRT/FU, S02 SCRN/TRT with a missing last SEENDTC,
 *            S03 SCRN/TRT with a date gap
 *   ae_doc : documented use case, record date variable AESTDTC only
 *   av_ep  : same events plus a non-missing auxiliary VSDTC, used to observe
 *            the mapping rules independently of the current VSDTC gate defect
 *--------------------------------------------------------------------------*/
data se_ep;
  length usubjid $10 sestdtc seendtc $20 epoch $30;
  usubjid='S01'; sestdtc='2024-01-01'; seendtc='2024-01-15'; epoch='SCRN'; output;
  usubjid='S01'; sestdtc='2024-01-15'; seendtc='2024-02-01'; epoch='TRT';  output;
  usubjid='S01'; sestdtc='2024-02-01'; seendtc='2024-03-01'; epoch='FU';   output;
  usubjid='S02'; sestdtc='2024-02-10'; seendtc='2024-02-20'; epoch='SCRN'; output;
  usubjid='S02'; sestdtc='2024-02-20'; seendtc='';           epoch='TRT';  output;
  usubjid='S03'; sestdtc='2024-03-01'; seendtc='2024-03-10'; epoch='SCRN'; output;
  usubjid='S03'; sestdtc='2024-04-01'; seendtc='2024-04-10'; epoch='TRT';  output;
run;

data ae_doc;
  length usubjid $10 aestdtc $20;
  usubjid='S01'; seq=1; aestdtc='2024-01-01'; output;
  usubjid='S01'; seq=3; aestdtc='2024-01-15'; output;
  usubjid='S01'; seq=4; aestdtc='2024-02-05'; output;
  usubjid='S02'; seq=7; aestdtc='2024-02-12'; output;
run;

data av_ep;
  length usubjid $10 ddtc vsdtc $20;
  usubjid='S01'; seq=1;  ddtc='2024-01-01';       vsdtc=ddtc; output;
  usubjid='S01'; seq=2;  ddtc='2024-01-10';       vsdtc=ddtc; output;
  usubjid='S01'; seq=3;  ddtc='2024-01-15';       vsdtc=ddtc; output;
  usubjid='S01'; seq=4;  ddtc='2024-02-01';       vsdtc=ddtc; output;
  usubjid='S01'; seq=5;  ddtc='2024-03-01';       vsdtc=ddtc; output;
  usubjid='S01'; seq=6;  ddtc='2024-03-15';       vsdtc=ddtc; output;
  usubjid='S02'; seq=7;  ddtc='2024-02-15';       vsdtc=ddtc; output;
  usubjid='S02'; seq=8;  ddtc='2024-02-21';       vsdtc=ddtc; output;
  usubjid='S02'; seq=9;  ddtc='2024-02-10';       vsdtc=ddtc; output;
  usubjid='S03'; seq=10; ddtc='2024-03';          vsdtc=ddtc; output;
  usubjid='S03'; seq=11; ddtc='2024-04-05T09:30'; vsdtc=ddtc; output;
  usubjid='S03'; seq=12; ddtc='2024-02-01';       vsdtc=ddtc; output;
  usubjid='S03'; seq=13; ddtc='2024-03-15';       vsdtc=ddtc; output;
  usubjid='S04'; seq=14; ddtc='2024-01-05';       vsdtc=ddtc; output;
run;

/*----------------------------------------------------------------------------
 * CASE 1 : documented contract, mapping driven only by DTC=
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 documented DTC-only mapping);
%sdtm_epoch(data=work.ae_doc, se=work.se_ep, dtc=aestdtc, out=work.doc_out);
%qc_expect_ds(ds=work.doc_out, desc=C1 output dataset created);
%qc_expect_nobs(ds=work.doc_out, expect=4, desc=C1 row count equals input);
%qc_expect_colval(ds=work.doc_out, var=epoch, where=usubjid='S01' and seq=1, expect=SCRN, desc=C1 S01 event on first SESTDTC);
%qc_expect_colval(ds=work.doc_out, var=epoch, where=usubjid='S01' and seq=3, expect=TRT, desc=C1 S01 event on next SESTDTC);
%qc_expect_colval(ds=work.doc_out, var=epoch, where=usubjid='S01' and seq=4, expect=FU, desc=C1 S01 event in FU);
%qc_expect_colval(ds=work.doc_out, var=epoch, where=usubjid='S02' and seq=7, expect=SCRN, desc=C1 S02 event in SCRN);

/*----------------------------------------------------------------------------
 * CASE 2 : output structure and variable attributes
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 output structure and variable attributes);
%qc_expect_var(ds=work.doc_out, var=epoch, type=C, desc=C2 EPOCH is character);
%qc_expect_var(ds=work.doc_out, var=sestdtc, type=C, desc=C2 SESTDTC is character);
%qc_expect_var(ds=work.doc_out, var=seendtc, type=C, desc=C2 SEENDTC is character);
%qc_expect_len(ds=work.doc_out, var=epoch, expect=30, desc=C2 EPOCH keeps SE length);
%qc_expect_len(ds=work.doc_out, var=sestdtc, expect=20, desc=C2 SESTDTC keeps SE length);
%qc_expect_len(ds=work.doc_out, var=seendtc, expect=20, desc=C2 SEENDTC keeps SE length);
%qc_expect_var(ds=work.doc_out, var=aestdtc, type=C, desc=C2 input date variable retained);

/*----------------------------------------------------------------------------
 * CASE 3 : mapping rules, observed with a non-missing auxiliary VSDTC
 *          S01  on/inside SCRN, on TRT start, on FU start, on last SEENDTC,
 *               after last SEENDTC, S02 last SEENDTC missing, before first
 *               SESTDTC, date gap, date-time value, subject not in SE,
 *               missing event date
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 mapping rules on boundaries and gaps);
%sdtm_epoch(data=work.av_ep, se=work.se_ep, dtc=ddtc, out=work.rule_out);
%qc_expect_ds(ds=work.rule_out, desc=C3 output dataset created);
%qc_expect_nobs(ds=work.rule_out, expect=14, desc=C3 row count equals input);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S01' and seq=1, expect=SCRN, desc=C3 event on first SESTDTC maps to SCRN);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S01' and seq=2, expect=SCRN, desc=C3 event inside SCRN maps to SCRN);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S01' and seq=3, expect=TRT, desc=C3 event on TRT SESTDTC maps to TRT);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S01' and seq=4, expect=FU, desc=C3 event on FU SESTDTC maps to FU);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S01' and seq=5, expect=FU, desc=C3 event on last SEENDTC maps to FU);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S01' and seq=6, expect=, desc=C3 event after last SEENDTC stays unmapped);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S02' and seq=7, expect=SCRN, desc=C3 S02 event inside SCRN);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S02' and seq=8, expect=TRT, desc=C3 last SEENDTC missing keeps TRT);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S02' and seq=9, expect=SCRN, desc=C3 S02 event on first SESTDTC);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S03' and seq=11, expect=TRT, desc=C3 date-time value maps to TRT);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S03' and seq=12, expect=, desc=C3 event before first SESTDTC stays unmapped);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S03' and seq=13, expect=, desc=C3 event in the date gap stays unmapped);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S04' and seq=14, expect=, desc=C3 subject absent from SE stays unmapped);
%qc_expect_colval(ds=work.rule_out, var=sestdtc, where=usubjid='S01' and seq=3, expect=2024-01-15, desc=C3 mapped SESTDTC is the TRT start);
%qc_expect_colval(ds=work.rule_out, var=seendtc, where=usubjid='S01' and seq=3, expect=2024-02-01, desc=C3 mapped SEENDTC is the TRT end);

/*----------------------------------------------------------------------------
 * CASE 4 : partial ISO8601 date, month-level attribution as implemented
 *          a non-last epoch that ends inside the month stays blank; the last
 *          epoch, an epoch spanning the month, and a month spanning two epochs
 *          are attributed at month granularity
 *--------------------------------------------------------------------------*/
data se_part;
  length usubjid $10 sestdtc seendtc $20 epoch $30;
  usubjid='S01'; sestdtc='2024-03-01'; seendtc='2024-03-15'; epoch='SCRN'; output;
  usubjid='S02'; sestdtc='2024-02-01'; seendtc='2024-04-01'; epoch='TRT';  output;
  usubjid='S03'; sestdtc='2024-03-01'; seendtc='2024-03-31'; epoch='SCRN'; output;
  usubjid='S04'; sestdtc='2024-01-01'; seendtc='2024-03-10'; epoch='SCRN'; output;
  usubjid='S04'; sestdtc='2024-03-10'; seendtc='2024-04-01'; epoch='TRT';  output;
run;
data in_part;
  length usubjid $10 ddtc $20;
  usubjid='S01'; seq=1; ddtc='2024-03'; output;
  usubjid='S02'; seq=1; ddtc='2024-03'; output;
  usubjid='S03'; seq=1; ddtc='2024-03'; output;
  usubjid='S04'; seq=1; ddtc='2024-03'; output;
run;
%qc_case(desc=4 partial date month-level attribution);
%sdtm_epoch(data=work.in_part, se=work.se_part, dtc=ddtc, out=work.part_out);
%qc_expect_ds(ds=work.part_out, desc=C4 output dataset created);
%qc_expect_colval(ds=work.rule_out, var=epoch, where=usubjid='S03' and seq=10, expect=, desc=C4 non-last epoch ending in month stays blank);
%qc_expect_colval(ds=work.rule_out, var=sestdtc, where=usubjid='S03' and seq=10, expect=, desc=C4 non-last partial epoch leaves SESTDTC blank);
%qc_expect_colval(ds=work.part_out, var=epoch, where=usubjid='S01' and seq=1, expect=SCRN, desc=C4 last epoch ending in month maps to SCRN);
%qc_expect_colval(ds=work.part_out, var=epoch, where=usubjid='S02' and seq=1, expect=TRT, desc=C4 epoch spanning the month maps to TRT);
%qc_expect_colval(ds=work.part_out, var=epoch, where=usubjid='S03' and seq=1, expect=SCRN, desc=C4 whole month covered by one epoch maps to SCRN);
%qc_expect_colval(ds=work.part_out, var=epoch, where=usubjid='S04' and seq=1, expect=TRT, desc=C4 month crossing two epochs maps to the later epoch);

/*----------------------------------------------------------------------------
 * CASE 5 : subject isolation
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 subject isolation);
%qc_expect_colval(ds=work.rule_out, var=sestdtc, where=usubjid='S02' and seq=7, expect=2024-02-10, desc=C5 S02 uses its own SESTDTC);
%qc_expect_colval(ds=work.rule_out, var=seendtc, where=usubjid='S02' and seq=8, expect=, desc=C5 S02 uses its own SEENDTC);

/*----------------------------------------------------------------------------
 * CASE 6 : default OUT equals DATA, in-place mapping
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 default OUT equals DATA);
data av_ip; set work.av_ep; run;
%sdtm_epoch(data=work.av_ip, se=work.se_ep, dtc=ddtc);
%qc_expect_ds(ds=work.av_ip, desc=C6 in-place output exists);
%qc_expect_nobs(ds=work.av_ip, expect=14, desc=C6 in-place row count unchanged);
%qc_expect_var(ds=work.av_ip, var=epoch, type=C, desc=C6 EPOCH added in place);
%qc_expect_var(ds=work.av_ip, var=seq, type=N, desc=C6 input variables retained);
%qc_expect_colval(ds=work.av_ip, var=epoch, where=usubjid='S01' and seq=4, expect=FU, desc=C6 in-place mapping is correct);

/*----------------------------------------------------------------------------
 * CASE 7 : zero-observation input still creates a structured output
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 zero observation input);
data ae_zero; set work.av_ep(obs=0); run;
%sdtm_epoch(data=work.ae_zero, se=work.se_ep, dtc=ddtc, out=work.zero_out);
%qc_expect_ds(ds=work.zero_out, desc=C7 output dataset created for 0 obs input);
%qc_expect_nobs(ds=work.zero_out, expect=0, desc=C7 output has 0 observations);
%qc_expect_var(ds=work.zero_out, var=epoch, type=C, desc=C7 EPOCH variable kept);
%qc_expect_var(ds=work.zero_out, var=sestdtc, type=C, desc=C7 SESTDTC variable kept);

/*----------------------------------------------------------------------------
 * CASE 8 : multiple SUBJECT= key variables
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 multiple SUBJECT key variables);
data se_key;
  length usubjid $10 subjid $6 sestdtc seendtc $20 epoch $30;
  usubjid='S01'; subjid='001'; sestdtc='2024-01-01'; seendtc='2024-01-15'; epoch='SCRN'; output;
  usubjid='S01'; subjid='001'; sestdtc='2024-01-15'; seendtc='2024-02-01'; epoch='TRT';  output;
  usubjid='S02'; subjid='002'; sestdtc='2024-02-10'; seendtc='2024-02-20'; epoch='SCRN'; output;
run;
data ae_key;
  length usubjid $10 subjid $6 ddtc vsdtc $20;
  usubjid='S01'; subjid='001'; seq=1; ddtc='2024-01-05'; vsdtc=ddtc; output;
  usubjid='S01'; subjid='001'; seq=2; ddtc='2024-01-20'; vsdtc=ddtc; output;
  usubjid='S02'; subjid='002'; seq=1; ddtc='2024-02-12'; vsdtc=ddtc; output;
run;
%sdtm_epoch(data=work.ae_key, se=work.se_key, subject=USUBJID SUBJID,
             dtc=ddtc, out=work.key_out);
%qc_expect_nobs(ds=work.key_out, expect=3, desc=C8 row count equals input);
%qc_expect_var(ds=work.key_out, var=SUBJID, type=C, desc=C8 SUBJID retained);
%qc_expect_colval(ds=work.key_out, var=epoch, where=usubjid='S01' and subjid='001' and seq=1, expect=SCRN, desc=C8 first key subject first record);
%qc_expect_colval(ds=work.key_out, var=epoch, where=usubjid='S01' and subjid='001' and seq=2, expect=TRT, desc=C8 first key subject second record);
%qc_expect_colval(ds=work.key_out, var=epoch, where=usubjid='S02' and subjid='002' and seq=1, expect=SCRN, desc=C8 second key subject mapped);

/*----------------------------------------------------------------------------
 * CASE 9 : unsorted SE input, macro sorts internally
 *--------------------------------------------------------------------------*/
%qc_case(desc=9 unsorted SE input);
proc sort data=work.se_ep out=work.se_uns; by descending usubjid descending sestdtc; run;
%sdtm_epoch(data=work.av_ep, se=work.se_uns, dtc=ddtc, out=work.uns_out);
%qc_expect_nobs(ds=work.uns_out, expect=14, desc=C9 row count equals input);
%qc_expect_colval(ds=work.uns_out, var=epoch, where=usubjid='S01' and seq=4, expect=FU, desc=C9 mapping correct with unsorted SE);
%qc_expect_colval(ds=work.uns_out, var=epoch, where=usubjid='S02' and seq=7, expect=SCRN, desc=C9 second subject mapped correctly);

/*----------------------------------------------------------------------------
 * CASE 10 : an existing EPOCH variable in DATA is overwritten
 *--------------------------------------------------------------------------*/
%qc_case(desc=10 existing EPOCH overwritten);
data av_old;
  length usubjid $10 ddtc vsdtc epoch $20;
  set work.av_ep;
  epoch='OLD';
run;
%sdtm_epoch(data=work.av_old, se=work.se_ep, dtc=ddtc, out=work.old_out);
%qc_expect_colval(ds=work.old_out, var=epoch, where=usubjid='S01' and seq=4, expect=FU, desc=C10 existing EPOCH replaced by mapped value);
%qc_expect_colval(ds=work.old_out, var=epoch, where=usubjid='S01' and seq=6, expect=, desc=C10 unmapped record has blank EPOCH not OLD);

/*----------------------------------------------------------------------------
 * CASE 11 : WORK intermediate dataset removed
 *--------------------------------------------------------------------------*/
%qc_case(desc=11 WORK cleanup);
%qc_check_eq(actual=%sysfunc(exist(work.sdtm_epoch1)), expect=0, desc=C11 SDTM_EPOCH1 removed);

%qc_end;
