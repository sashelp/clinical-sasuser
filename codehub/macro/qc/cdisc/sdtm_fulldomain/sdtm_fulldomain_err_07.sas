/*===============================================================================
 * sdtm_fulldomain_err_07.sas - Negative test: SUPP missing a required variable
 *===============================================================================
 * Macro under test : %sdtm_fulldomain
 * Expected         : abort cancel with
 *                    "At least one of required variables(IDVAR IDVARVAL QVAL
 *                     QNAM QLABEL) not exist in SUPP dataset."
 * Scenario         : SUPP exists and has USUBJID but QLABEL is missing.
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
%qc_begin(prog=sdtm_fulldomain_err_07, macro=sdtm_fulldomain);
%qc_case(desc=1 SUPP missing required variable QLABEL must abort);

data _parent_ds;
  length usubjid $10;
  usubjid='S01';
run;

/* required QLABEL deliberately omitted */
data _supp_noqlab;
  length usubjid $10 idvar $8 idvarval $8 qnam $8 qval $20;
  usubjid='S01'; idvar='LBSEQ'; idvarval='1'; qnam='LBFAST'; qval='Y';
run;

*EXPECTED_ERROR: At least one of required variables(IDVAR IDVARVAL QVAL QNAM QLABEL) not exist in SUPP dataset.;
%qc_abort_marker;
%sdtm_fulldomain(domain=lb, parent=work._parent_ds, supp=work._supp_noqlab);
%qc_unexpected_continue;
%qc_end;
