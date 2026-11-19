/*===============================================================================
 * sdtm_lobxfl_err_01.sas - Negative test: DATA= empty
 *===============================================================================
 * Macro under test : %sdtm_lobxfl
 * Expected         : abort cancel with "ERROR: Parameter DATA= not specified."
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

data dm_neg;
  length USUBJID $10 RFXSTDTC $20;
  USUBJID='S01'; RFXSTDTC='2024-01-10'; output;
run;
data lb_neg;
  length USUBJID $10 LBTESTCD $8 LBDTC $20 LBORRES $8;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-05'; LBORRES='10'; output;
run;

%qc_begin(prog=sdtm_lobxfl_err_01, macro=sdtm_lobxfl);
%qc_case(desc=1 DATA= empty must abort);
*EXPECTED_ERROR: ERROR: Parameter DATA= not specified.;
%qc_abort_marker;
%sdtm_lobxfl(data=, out=work.lb_neg_out, var=LBORRES, dtc=LBDTC,
              by=LBTESTCD, blfl=LOBXFL, subject=USUBJID,
              rfdtc=work.dm_neg.rfxstdtc);
%qc_unexpected_continue;
