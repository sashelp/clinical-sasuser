/*===============================================================================
 * sdtm_lobxfl_err_02.sas - Negative test: input dataset does not exist
 *===============================================================================
 * Macro under test : %sdtm_lobxfl
 * Expected         : abort cancel with "ERROR: Dataset work.no_ds not exist."
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

%qc_begin(prog=sdtm_lobxfl_err_02, macro=sdtm_lobxfl);
%qc_case(desc=1 nonexistent input dataset must abort);
*EXPECTED_ERROR: ERROR: Dataset work.no_ds not exist.;
%qc_abort_marker;
%sdtm_lobxfl(data=work.no_ds, out=work.lb_neg_out, var=LBORRES, dtc=LBDTC,
              by=LBTESTCD, blfl=LOBXFL, subject=USUBJID,
              rfdtc=work.dm_neg.rfxstdtc);
%qc_unexpected_continue;
