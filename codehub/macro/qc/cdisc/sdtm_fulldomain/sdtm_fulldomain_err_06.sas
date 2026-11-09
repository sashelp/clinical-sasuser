/*===============================================================================
 * sdtm_fulldomain_err_06.sas - Negative test: SUBJECT= variable not in SUPP
 *===============================================================================
 * Macro under test : %sdtm_fulldomain
 * Expected         : abort cancel with
 *                    "At least one of SUBJECT= variables does not exist in
 *                     SUPP dataset."
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
%qc_begin(prog=sdtm_fulldomain_err_06, macro=sdtm_fulldomain);
%qc_case(desc=1 SUBJECT= variable missing from SUPP must abort);

data _parent_ds;
  length usubjid $10;
  usubjid='S01';
run;

/* SUPP has the structural variables but no USUBJID */
data _supp_nosubj;
  length idvar $8 idvarval $8 qnam $8 qlabel $40 qval $20;
  idvar='LBSEQ'; idvarval='1'; qnam='LBFAST'; qlabel='Fasting Status'; qval='Y';
run;

*EXPECTED_ERROR: At least one of SUBJECT= variables does not exist in SUPP dataset.;
%qc_abort_marker;
%sdtm_fulldomain(domain=lb, parent=work._parent_ds, supp=work._supp_nosubj);
%qc_unexpected_continue;
%qc_end;
