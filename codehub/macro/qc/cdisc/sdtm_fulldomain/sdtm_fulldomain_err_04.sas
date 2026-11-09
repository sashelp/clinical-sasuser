/*===============================================================================
 * sdtm_fulldomain_err_04.sas - Negative test: PARENT= is a VIEW
 *===============================================================================
 * Macro under test : %sdtm_fulldomain
 * Expected         : abort cancel with "Dataset work.parent_view not exist."
 * Purpose          : lock the documented contract that only SAS data sets are
 *                    accepted (views are reported as non-existing), matching
 *                    %var_exist / %var_coexist / %ds_varlist / %ds_num2char.
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
%qc_begin(prog=sdtm_fulldomain_err_04, macro=sdtm_fulldomain);
%qc_case(desc=1 PARENT= as view must abort);

data _parent_ds;
  length usubjid $10;
  usubjid='S01';
run;
proc sql;
  create view work.parent_view as select * from work._parent_ds;
quit;

*EXPECTED_ERROR: Dataset work.parent_view not exist.;
%qc_abort_marker;
%sdtm_fulldomain(domain=lb, parent=work.parent_view);
%qc_unexpected_continue;
%qc_end;
