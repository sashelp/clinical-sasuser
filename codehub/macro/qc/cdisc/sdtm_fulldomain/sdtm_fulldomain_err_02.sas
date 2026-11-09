/*===============================================================================
 * sdtm_fulldomain_err_02.sas - Negative test: PARENT= explicitly empty
 *===============================================================================
 * Macro under test : %sdtm_fulldomain
 * Expected         : abort cancel with "Parameter PARENT= not specified."
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
%qc_begin(prog=sdtm_fulldomain_err_02, macro=sdtm_fulldomain);
%qc_case(desc=1 PARENT= empty must abort);
*EXPECTED_ERROR: Parameter PARENT= not specified.;
%qc_abort_marker;
%sdtm_fulldomain(domain=lb, parent=);
%qc_unexpected_continue;
%qc_end;
