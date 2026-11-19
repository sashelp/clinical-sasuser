/*===============================================================================
 * sdtm_epoch_err_03.sas - Negative test: SE= empty
 *===============================================================================
 * Macro under test : %sdtm_epoch
 * Expected         : abort cancel with "ERROR: Parameter SE= not specified."
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

data ae_neg;
  length usubjid $10 aestdtc $20;
  usubjid='S01'; aestdtc='2024-01-05'; output;
run;

%qc_begin(prog=sdtm_epoch_err_03, macro=sdtm_epoch);
%qc_case(desc=1 SE= empty must abort);
*EXPECTED_ERROR: ERROR: Parameter SE= not specified.;
%qc_abort_marker;
%sdtm_epoch(data=work.ae_neg, se=, dtc=aestdtc);
%qc_unexpected_continue;
