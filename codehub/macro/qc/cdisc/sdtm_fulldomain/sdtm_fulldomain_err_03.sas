/*===============================================================================
 * sdtm_fulldomain_err_03.sas - Negative test: PARENT= dataset does not exist
 *===============================================================================
 * Macro under test : %sdtm_fulldomain
 * Expected         : abort cancel with "Dataset work.no_such_parent not exist."
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
%include "&_QCDEV_VAR_.\var_attr.sas";
%include "&_QCDEV_VAR_.\var_coexist.sas";
%include "&_QCDEV_CDISC_.\sdtm_fulldomain.sas";
%qc_begin(prog=sdtm_fulldomain_err_03, macro=sdtm_fulldomain);
%qc_case(desc=1 non-existing PARENT= must abort);
*EXPECTED_ERROR: Dataset work.no_such_parent not exist.;
%qc_abort_marker;
%sdtm_fulldomain(domain=lb, parent=work.no_such_parent);
%qc_unexpected_continue;
%qc_end;
