/*===============================================================================
 * sdtm_epoch_err_11.sas - Negative test: DTC= empty
 *===============================================================================
 * Macro under test : %sdtm_epoch
 * Expected         : abort cancel with "ERROR: Parameter DTC= not specified."
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
data se_neg;
  length usubjid $10 sestdtc seendtc $20 epoch $30;
  usubjid='S01'; sestdtc='2024-01-01'; seendtc='2024-01-15'; epoch='SCRN'; output;
run;

%qc_begin(prog=sdtm_epoch_err_11, macro=sdtm_epoch);
%qc_case(desc=1 DTC= empty must abort);
*EXPECTED_ERROR: ERROR: Parameter DTC= not specified.;
%qc_abort_marker;
%sdtm_epoch(data=work.ae_neg, se=work.se_neg, dtc=);
%qc_unexpected_continue;
