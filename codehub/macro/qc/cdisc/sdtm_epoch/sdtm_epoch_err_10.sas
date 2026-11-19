/*===============================================================================
 * sdtm_epoch_err_10.sas - Negative test: DATA= and SE= are the same dataset
 *===============================================================================
 * Macro under test : %sdtm_epoch
 * Expected         : abort cancel with "ERROR: Parameters DATA= and SE= refer
 *                    to the same dataset."
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

data se_same;
  length usubjid $10 sestdtc seendtc $20 epoch $30;
  usubjid='S01'; sestdtc='2024-01-01'; seendtc='2024-01-15'; epoch='SCRN'; output;
run;

%qc_begin(prog=sdtm_epoch_err_10, macro=sdtm_epoch);
%qc_case(desc=1 DATA= and SE= must not be the same dataset);
*EXPECTED_ERROR: ERROR: Parameters DATA= and SE= refer to the same dataset.;
%qc_abort_marker;
%sdtm_epoch(data=work.se_same, se=work.se_same, dtc=sestdtc, out=work.same_out);
%qc_unexpected_continue;
