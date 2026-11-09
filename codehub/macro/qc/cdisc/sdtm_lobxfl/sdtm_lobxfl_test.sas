/*===============================================================================
 * sdtm_lobxfl_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %sdtm_lobxfl
 * File under test   : dev/cdisc/sdtm_lobxfl.sas
 * Dependencies      : %var_exist, %var_coexist, %var_attr
 * Coverage          : baseline flag selection per subject and BY group, latest
 *                     eligible record, DTC on or before RFDTC, character
 *                     result exclusions, numeric missing exclusions, partial
 *                     ISO8601 dates, date-time values, missing DTC, subject
 *                     absent from DM, existing BLFL reset, default OUT,
 *                     zero-observation input, BY= omitted, multiple BY=
 *                     variables, RFDTC single/two/three-part forms,
 *                     SUBJECT= custom key, output attributes and cleanup
 * Run               : qc/run_all.ps1 -Macro sdtm_lobxfl
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
%include "&_QCDEV_VAR_.\var_attr.sas";
%include "&_QCDEV_CDISC_.\sdtm_lobxfl.sas";

%qc_begin(prog=sdtm_lobxfl_test, macro=sdtm_lobxfl);

/*----------------------------------------------------------------------------
 * Test data
 *   DM      : reference date of first study drug administration
 *   LBMAIN  : LB extract covering every documented selection rule
 *             S01 normal records before and after RFDTC
 *             S02 character result exclusions NA ND UK and blank
 *             S03 partial ISO date and date-time value
 *             S04 missing DTC and a tie on the latest DTC
 *             S05 all records after RFDTC
 *             S06 subject absent from DM
 *--------------------------------------------------------------------------*/
data dm;
  length USUBJID $10 RFXSTDTC $20;
  USUBJID='S01'; RFXSTDTC='2024-01-10';       output;
  USUBJID='S02'; RFXSTDTC='2024-01-10';       output;
  USUBJID='S03'; RFXSTDTC='2024-01-15';       output;
  USUBJID='S04'; RFXSTDTC='2024-01-10';       output;
  USUBJID='S05'; RFXSTDTC='2024-01-10';       output;
  USUBJID='S07'; RFXSTDTC='2024-01-15T08:00'; output;
run;

data lbmain;
  length USUBJID $10 LBTESTCD $8 LBDTC $20 LBORRES $8 VISIT $10;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-05';       LBORRES='10'; VISIT='V1'; output;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-08';       LBORRES='20'; VISIT='V2'; output;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-10';       LBORRES='25'; VISIT='V3'; output;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-12';       LBORRES='30'; VISIT='V4'; output;
  USUBJID='S01'; LBTESTCD='AST'; LBDTC='2024-01-08';       LBORRES='5';  VISIT='V2'; output;
  USUBJID='S02'; LBTESTCD='ALT'; LBDTC='2024-01-03';       LBORRES='NA'; VISIT='V1'; output;
  USUBJID='S02'; LBTESTCD='ALT'; LBDTC='2024-01-04';       LBORRES='';   VISIT='V1'; output;
  USUBJID='S02'; LBTESTCD='ALT'; LBDTC='2024-01-05';       LBORRES='ND'; VISIT='V2'; output;
  USUBJID='S02'; LBTESTCD='ALT'; LBDTC='2024-01-06';       LBORRES='UK'; VISIT='V2'; output;
  USUBJID='S02'; LBTESTCD='ALT'; LBDTC='2024-01-07';       LBORRES='40'; VISIT='V3'; output;
  USUBJID='S02'; LBTESTCD='ALT'; LBDTC='2024-01-09';       LBORRES='NA'; VISIT='V3'; output;
  USUBJID='S03'; LBTESTCD='ALT'; LBDTC='2024-01';          LBORRES='50'; VISIT='V1'; output;
  USUBJID='S03'; LBTESTCD='ALT'; LBDTC='2024-01-20';       LBORRES='60'; VISIT='V2'; output;
  USUBJID='S03'; LBTESTCD='AST'; LBDTC='2024-01-15T09:30'; LBORRES='7';  VISIT='V1'; output;
  USUBJID='S04'; LBTESTCD='ALT'; LBDTC='';                 LBORRES='80'; VISIT='V1'; output;
  USUBJID='S04'; LBTESTCD='ALT'; LBDTC='2024-01-02';       LBORRES='90'; VISIT='V1'; output;
  USUBJID='S04'; LBTESTCD='AST'; LBDTC='2024-01-02';       LBORRES='1';  VISIT='V1'; output;
  USUBJID='S04'; LBTESTCD='AST'; LBDTC='2024-01-02';       LBORRES='2';  VISIT='V1'; output;
  USUBJID='S05'; LBTESTCD='ALT'; LBDTC='2024-02-01';       LBORRES='11'; VISIT='V1'; output;
  USUBJID='S06'; LBTESTCD='ALT'; LBDTC='2024-01-01';       LBORRES='12'; VISIT='V1'; output;
run;

/*----------------------------------------------------------------------------
 * CASE 1 : basic flagging one baseline per subject and test
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 basic flagging and output structure);
%sdtm_lobxfl(data=work.lbmain, out=work.lbm_out, var=LBORRES, dtc=LBDTC,
              by=LBTESTCD, blfl=LOBXFL, subject=USUBJID,
              rfdtc=work.dm.rfxstdtc);
%qc_expect_ds(ds=work.lbm_out, desc=C1 output dataset created);
%qc_expect_nobs(ds=work.lbm_out, expect=20, desc=C1 row count equals input);
%qc_expect_var(ds=work.lbm_out, var=LOBXFL, type=C, desc=C1 BLFL is character);
%qc_expect_len(ds=work.lbm_out, var=LOBXFL, expect=1, desc=C1 BLFL length is one);
%qc_expect_var(ds=work.lbm_out, var=_RFdtc_, type=C, desc=C1 working RFDTC kept);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S01' and lbtestcd='ALT' and lbdtc='2024-01-10', expect=Y, desc=C1 latest eligible record flagged);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S01' and lbtestcd='ALT' and lbdtc='2024-01-12', expect=, desc=C1 record after RFDTC not flagged);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S01' and lbtestcd='AST' and lbdtc='2024-01-08', expect=Y, desc=C1 second test flagged independently);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S02' and lbtestcd='ALT' and lbdtc='2024-01-07', expect=Y, desc=C1 second subject flagged);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S01' and lbtestcd='ALT' and lbdtc='2024-01-05', expect=, desc=C1 earlier eligible record not flagged);
proc sql noprint;
  select count(*) into :_ny trimmed from work.lbm_out where LOBXFL='Y';
quit;
%qc_check_eq(actual=&_ny., expect=7, desc=C1 exactly one flag for each eligible group);

/*----------------------------------------------------------------------------
 * CASE 2 : character result exclusions
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 character result exclusions);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S02' and lbdtc='2024-01-03', expect=, desc=C2 NA excluded);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S02' and lbdtc='2024-01-04', expect=, desc=C2 blank excluded);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S02' and lbdtc='2024-01-05', expect=, desc=C2 ND excluded);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S02' and lbdtc='2024-01-06', expect=, desc=C2 UK excluded);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S02' and lbdtc='2024-01-09', expect=, desc=C2 excluded latest record does not take the flag);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S02' and lbdtc='2024-01-07', expect=Y, desc=C2 earlier non-missing record flagged);

/*----------------------------------------------------------------------------
 * CASE 3 : DTC on or before RFDTC and missing DTC
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 DTC boundary and missing DTC);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S01' and lbtestcd='ALT' and lbdtc='2024-01-10', expect=Y, desc=C3 DTC equal to RFDTC is eligible);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S04' and lbdtc='', expect=, desc=C3 missing DTC not eligible);

/*----------------------------------------------------------------------------
 * CASE 4 : subject not present in DM has no reference date
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 missing RFDTC for one subject);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S06', expect=, desc=C4 subject absent from DM not flagged);

/*----------------------------------------------------------------------------
 * CASE 5 : partial ISO8601 date and date-time value
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 partial date and date-time DTC);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S03' and lbtestcd='ALT' and lbdtc='2024-01', expect=Y, desc=C5 partial date eligible on common prefix);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S03' and lbtestcd='AST', expect=Y, desc=C5 same-day date-time value eligible);

/*----------------------------------------------------------------------------
 * CASE 6 : date-only DTC compared with a date-time RFDTC
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 date-only DTC against date-time RFDTC);
data lb_dt;
  length USUBJID $10 LBTESTCD $8 LBDTC $20 LBORRES $8;
  USUBJID='S07'; LBTESTCD='ALT'; LBDTC='2024-01-15'; LBORRES='1'; output;
  USUBJID='S07'; LBTESTCD='ALT'; LBDTC='2024-01-16'; LBORRES='2'; output;
run;
%sdtm_lobxfl(data=work.lb_dt, out=work.lbdt_out, var=LBORRES, dtc=LBDTC,
              by=LBTESTCD, blfl=LOBXFL, subject=USUBJID,
              rfdtc=work.dm.rfxstdtc);
%qc_expect_colval(ds=work.lbdt_out, var=LOBXFL, where=lbdtc='2024-01-15', expect=Y, desc=C6 date-only on RFDTC date flagged);
%qc_expect_colval(ds=work.lbdt_out, var=LOBXFL, where=lbdtc='2024-01-16', expect=, desc=C6 date-only after RFDTC date not flagged);

/*----------------------------------------------------------------------------
 * CASE 7 : numeric VAR missing and special missing values
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 numeric VAR missing values);
data lb_num;
  length USUBJID $10 LBTESTCD $8 LBDTC $20;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-01'; LBSTRESN=.;   output;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-02'; LBSTRESN=.A;  output;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-03'; LBSTRESN=0;   output;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-04'; LBSTRESN=.Z;  output;
run;
%sdtm_lobxfl(data=work.lb_num, out=work.lbn_out, var=LBSTRESN, dtc=LBDTC,
              by=LBTESTCD, blfl=LOBXFL, subject=USUBJID,
              rfdtc=work.dm.rfxstdtc);
%qc_expect_colval(ds=work.lbn_out, var=LOBXFL, where=lbdtc='2024-01-01', expect=, desc=C7 numeric missing excluded);
%qc_expect_colval(ds=work.lbn_out, var=LOBXFL, where=lbdtc='2024-01-02', expect=, desc=C7 special missing A excluded);
%qc_expect_colval(ds=work.lbn_out, var=LOBXFL, where=lbdtc='2024-01-04', expect=, desc=C7 special missing Z excluded);
%qc_expect_colval(ds=work.lbn_out, var=LOBXFL, where=lbdtc='2024-01-03', expect=Y, desc=C7 zero is a valid result);

/*----------------------------------------------------------------------------
 * CASE 8 : an existing BLFL variable is cleared before flagging
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 existing BLFL reset);
data lb_exist;
  length USUBJID $10 LBTESTCD $8 LBDTC $20 LBORRES $8 LOBXFL $1;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-05'; LBORRES='1'; LOBXFL='Y'; output;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-09'; LBORRES='2'; LOBXFL='Y'; output;
run;
%sdtm_lobxfl(data=work.lb_exist, out=work.lbe_out, var=LBORRES, dtc=LBDTC,
              by=LBTESTCD, blfl=LOBXFL, subject=USUBJID,
              rfdtc=work.dm.rfxstdtc);
%qc_expect_colval(ds=work.lbe_out, var=LOBXFL, where=lbdtc='2024-01-05', expect=, desc=C8 old flag cleared);
%qc_expect_colval(ds=work.lbe_out, var=LOBXFL, where=lbdtc='2024-01-09', expect=Y, desc=C8 new latest record flagged);

/*----------------------------------------------------------------------------
 * CASE 9 : default OUT equals DATA and writes in place
 *--------------------------------------------------------------------------*/
%qc_case(desc=9 default OUT in place);
data lb_ip; set work.lbmain; run;
%sdtm_lobxfl(data=work.lb_ip, var=LBORRES, dtc=LBDTC, by=LBTESTCD,
              blfl=LOBXFL, subject=USUBJID, rfdtc=work.dm.rfxstdtc);
%qc_expect_nobs(ds=work.lb_ip, expect=20, desc=C9 in place row count unchanged);
%qc_expect_var(ds=work.lb_ip, var=LOBXFL, type=C, desc=C9 flag added in place);
%qc_expect_colval(ds=work.lb_ip, var=LOBXFL, where=usubjid='S01' and lbtestcd='ALT' and lbdtc='2024-01-10', expect=Y, desc=C9 in place flag correct);

/*----------------------------------------------------------------------------
 * CASE 10 : zero-observation input
 *--------------------------------------------------------------------------*/
%qc_case(desc=10 zero observation input);
data lb_zero; set work.lbmain(obs=0); run;
%sdtm_lobxfl(data=work.lb_zero, out=work.lbz_out, var=LBORRES, dtc=LBDTC,
              by=LBTESTCD, blfl=LOBXFL, subject=USUBJID,
              rfdtc=work.dm.rfxstdtc);
%qc_expect_ds(ds=work.lbz_out, desc=C10 output created for empty input);
%qc_expect_nobs(ds=work.lbz_out, expect=0, desc=C10 output has zero rows);
%qc_expect_var(ds=work.lbz_out, var=LOBXFL, type=C, desc=C10 flag variable kept);

/*----------------------------------------------------------------------------
 * CASE 11 : BY= omitted derives one flag per subject
 *--------------------------------------------------------------------------*/
%qc_case(desc=11 BY omitted one flag per subject);
data lb_noby;
  length USUBJID $10 LBTESTCD $8 LBDTC $20 LBORRES $8;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-05'; LBORRES='1'; output;
  USUBJID='S01'; LBTESTCD='AST'; LBDTC='2024-01-08'; LBORRES='2'; output;
  USUBJID='S01'; LBTESTCD='BIL'; LBDTC='2024-01-06'; LBORRES='3'; output;
run;
%sdtm_lobxfl(data=work.lb_noby, out=work.lbnb_out, var=LBORRES, dtc=LBDTC,
              by=, blfl=LOBXFL, subject=USUBJID, rfdtc=work.dm.rfxstdtc);
%qc_expect_nobs(ds=work.lbnb_out, expect=3, desc=C11 row count equals input);
proc sql noprint;
  select count(*) into :_ny_nb trimmed from work.lbnb_out where LOBXFL='Y';
quit;
%qc_check_eq(actual=&_ny_nb., expect=1, desc=C11 only one record flagged per subject);
%qc_expect_colval(ds=work.lbnb_out, var=LOBXFL, where=lbtestcd='AST', expect=Y, desc=C11 latest record across tests flagged);

/*----------------------------------------------------------------------------
 * CASE 12 : multiple BY variables
 *--------------------------------------------------------------------------*/
%qc_case(desc=12 multiple BY variables);
data lb_mby;
  length USUBJID $10 LBTESTCD $8 VISIT $10 LBDTC $20 LBORRES $8;
  USUBJID='S01'; LBTESTCD='ALT'; VISIT='V1'; LBDTC='2024-01-02'; LBORRES='1'; output;
  USUBJID='S01'; LBTESTCD='ALT'; VISIT='V1'; LBDTC='2024-01-05'; LBORRES='2'; output;
  USUBJID='S01'; LBTESTCD='ALT'; VISIT='V2'; LBDTC='2024-01-08'; LBORRES='3'; output;
run;
%sdtm_lobxfl(data=work.lb_mby, out=work.lbmby_out, var=LBORRES, dtc=LBDTC,
              by=LBTESTCD VISIT, blfl=LOBXFL, subject=USUBJID,
              rfdtc=work.dm.rfxstdtc);
%qc_expect_colval(ds=work.lbmby_out, var=LOBXFL, where=visit='V1' and lbdtc='2024-01-05', expect=Y, desc=C12 first BY combination flagged);
%qc_expect_colval(ds=work.lbmby_out, var=LOBXFL, where=visit='V1' and lbdtc='2024-01-02', expect=, desc=C12 earlier record of first combination not flagged);
%qc_expect_colval(ds=work.lbmby_out, var=LOBXFL, where=visit='V2', expect=Y, desc=C12 second BY combination flagged);

/*----------------------------------------------------------------------------
 * CASE 13 : RFDTC one-part form is a variable of the input dataset
 *--------------------------------------------------------------------------*/
%qc_case(desc=13 RFDTC variable of the input dataset);
data lb_1p;
  length USUBJID $10 LBTESTCD $8 LBDTC $20 LBORRES $8 REFDTC $20;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-05'; LBORRES='1'; REFDTC='2024-01-06'; output;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-09'; LBORRES='2'; REFDTC='2024-01-06'; output;
run;
%sdtm_lobxfl(data=work.lb_1p, out=work.lb1p_out, var=LBORRES, dtc=LBDTC,
              by=LBTESTCD, blfl=LOBXFL, subject=USUBJID, rfdtc=REFDTC);
%qc_expect_colval(ds=work.lb1p_out, var=LOBXFL, where=lbdtc='2024-01-05', expect=Y, desc=C13 input variable reference flags the eligible record);
%qc_expect_colval(ds=work.lb1p_out, var=LOBXFL, where=lbdtc='2024-01-09', expect=, desc=C13 input variable reference excludes later record);

/*----------------------------------------------------------------------------
 * CASE 14 : RFDTC two-part form uses a WORK dataset
 *--------------------------------------------------------------------------*/
%qc_case(desc=14 RFDTC WORK dataset form);
data dm2;
  length USUBJID $10 RFXSTDTC $20;
  USUBJID='S08'; RFXSTDTC='2024-01-10'; output;
run;
data lb_2p;
  length USUBJID $10 LBTESTCD $8 LBDTC $20 LBORRES $8;
  USUBJID='S08'; LBTESTCD='ALT'; LBDTC='2024-01-09'; LBORRES='1'; output;
  USUBJID='S08'; LBTESTCD='ALT'; LBDTC='2024-01-12'; LBORRES='2'; output;
run;
%sdtm_lobxfl(data=work.lb_2p, out=work.lb2p_out, var=LBORRES, dtc=LBDTC,
              by=LBTESTCD, blfl=LOBXFL, subject=USUBJID, rfdtc=dm2.rfxstdtc);
%qc_expect_colval(ds=work.lb2p_out, var=LOBXFL, where=lbdtc='2024-01-09', expect=Y, desc=C14 two-part RFDTC accepts WORK dataset);
%qc_expect_colval(ds=work.lb2p_out, var=LOBXFL, where=lbdtc='2024-01-12', expect=, desc=C14 two-part RFDTC excludes later record);

/*----------------------------------------------------------------------------
 * CASE 15 : RFDTC three-part form uses a libref
 *--------------------------------------------------------------------------*/
%qc_case(desc=15 RFDTC libref dataset form);
libname qclib "%sysfunc(pathname(work))";
data qclib.dm3;
  length USUBJID $10 RFXSTDTC $20;
  USUBJID='S01'; RFXSTDTC='2024-01-10'; output;
run;
data lb_3p;
  length USUBJID $10 LBTESTCD $8 LBDTC $20 LBORRES $8;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-09'; LBORRES='1'; output;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-12'; LBORRES='2'; output;
run;
%sdtm_lobxfl(data=work.lb_3p, out=work.lb3p_out, var=LBORRES, dtc=LBDTC,
              by=LBTESTCD, blfl=LOBXFL, subject=USUBJID,
              rfdtc=qclib.dm3.rfxstdtc);
%qc_expect_colval(ds=work.lb3p_out, var=LOBXFL, where=lbdtc='2024-01-09', expect=Y, desc=C15 three-part RFDTC accepted);
%qc_expect_colval(ds=work.lb3p_out, var=LOBXFL, where=lbdtc='2024-01-12', expect=, desc=C15 three-part RFDTC excludes later record);
libname qclib clear;

/*----------------------------------------------------------------------------
 * CASE 16 : SUBJECT= uses a custom key variable
 *--------------------------------------------------------------------------*/
%qc_case(desc=16 custom SUBJECT variable);
data dm_s;
  length SUBJID $6 RFXSTDTC $20;
  SUBJID='001'; RFXSTDTC='2024-01-10'; output;
run;
data lb_s;
  length SUBJID $6 LBTESTCD $8 LBDTC $20 LBORRES $8;
  SUBJID='001'; LBTESTCD='ALT'; LBDTC='2024-01-09'; LBORRES='1'; output;
run;
%sdtm_lobxfl(data=work.lb_s, out=work.lbs_out, var=LBORRES, dtc=LBDTC,
              by=LBTESTCD, blfl=LOBXFL, subject=SUBJID, rfdtc=dm_s.rfxstdtc);
%qc_expect_nobs(ds=work.lbs_out, expect=1, desc=C16 custom key row count);
%qc_expect_colval(ds=work.lbs_out, var=LOBXFL, where=subjid='001', expect=Y, desc=C16 custom key subject matched and flagged);

/*----------------------------------------------------------------------------
 * CASE 17 : variable formats and labels survive the copy
 *--------------------------------------------------------------------------*/
%qc_case(desc=17 variable attributes preserved);
data lb_attr;
  length USUBJID $10 LBTESTCD $8 LBDTC $20 LBORRES $8;
  label LBORRES='Result or Test';
  format LBDTC $20.;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-05'; LBORRES='1'; output;
run;
%sdtm_lobxfl(data=work.lb_attr, out=work.lba_out, var=LBORRES, dtc=LBDTC,
              by=LBTESTCD, blfl=LOBXFL, subject=USUBJID,
              rfdtc=work.dm.rfxstdtc);
%qc_expect_fmt(ds=work.lba_out, var=LBDTC, expect=$20., desc=C17 LBDTC format preserved);
%qc_expect_len(ds=work.lba_out, var=LBDTC, expect=20, desc=C17 LBDTC length preserved);
proc sql noprint;
  select label into :_lbl trimmed from dictionary.columns
    where libname='WORK' and memname='LBA_OUT' and upcase(name)='LBORRES';
quit;
%qc_check_eq(actual=&_lbl., expect=Result or Test, desc=C17 LBORRES label preserved);

/*----------------------------------------------------------------------------
 * CASE 18 : tied latest DTC flags the last record in sort order
 *--------------------------------------------------------------------------*/
%qc_case(desc=18 tie on the latest DTC);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S04' and lbtestcd='AST' and lborres='2', expect=Y, desc=C18 last tied record flagged);
%qc_expect_colval(ds=work.lbm_out, var=LOBXFL, where=usubjid='S04' and lbtestcd='AST' and lborres='1', expect=, desc=C18 first tied record not flagged);

/*----------------------------------------------------------------------------
 * CASE 19 : DOMAIN defaults derive VAR DTC BY and BLFL names
 *--------------------------------------------------------------------------*/
%qc_case(desc=19 DOMAIN defaults);
data lb_dom;
  length USUBJID $10 LBTESTCD $8 LBDTC $20 LBORRES $8;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-05'; LBORRES='1'; output;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-09'; LBORRES='2'; output;
  USUBJID='S01'; LBTESTCD='AST'; LBDTC='2024-01-08'; LBORRES='3'; output;
run;
%sdtm_lobxfl(data=work.lb_dom, domain=LB, rfdtc=work.dm.rfxstdtc);
%qc_expect_var(ds=work.lb_dom, var=LBlobxfl, type=C, desc=C19 default BLFL name derived from DOMAIN);
%qc_expect_colval(ds=work.lb_dom, var=LBlobxfl, where=lbtestcd='ALT' and lbdtc='2024-01-09', expect=Y, desc=C19 default BY and VAR derive correct flag);
%qc_expect_colval(ds=work.lb_dom, var=LBlobxfl, where=lbtestcd='AST', expect=Y, desc=C19 default BY keeps test level grouping);

/*----------------------------------------------------------------------------
 * CASE 20 : WORK intermediates removed after the run
 *--------------------------------------------------------------------------*/
%qc_case(desc=20 WORK cleanup);
%qc_check_eq(actual=%sysfunc(exist(work.sdtm_lobxfl1)), expect=0, desc=C20 LOBXFL1 removed);
%qc_check_eq(actual=%sysfunc(exist(work.sdtm_lobxfl2)), expect=0, desc=C20 LOBXFL2 removed);

%qc_end;
