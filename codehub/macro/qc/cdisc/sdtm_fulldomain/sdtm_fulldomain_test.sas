/*===============================================================================
 * sdtm_fulldomain_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %sdtm_fulldomain
 * File under test   : dev/cdisc/sdtm_fulldomain.sas
 * Coverage          : merge parent domain with SUPP qualifiers (numeric IDVAR),
 *                     parent-level qualifier (blank IDVAR), parent copied when
 *                     SUPP is empty / missing / a view / 0 obs / all subject
 *                     values missing, SUBJECT= parameter (default USUBJID,
 *                     SUBJID, multiple key variables), default parameter names
 *                     (PARENT=sdtm.&DOMAIN., SUPP=sdtm.supp&DOMAIN.,
 *                     OUT=&DOMAIN.), OUT= in another library, PARENT/SUPP
 *                     dataset options, in-place merge, QVAL length propagation,
 *                     variable labels, WORK cleanup.
 * Run               : qc/run_all.ps1  (or standalone batch, see README)
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
%include "&_QCQC_.\_framework\qc_sandbox.sas";
%include "&_QCDEV_VAR_.\var_exist.sas";
%include "&_QCDEV_VAR_.\var_attr.sas";
%include "&_QCDEV_VAR_.\var_coexist.sas";
%include "&_QCDEV_CDISC_.\sdtm_fulldomain.sas";

/* CASE 7 / 8 assign librefs under &_QCSB_., so the sandbox must exist first */
%qc_sandbox_reset;

%qc_begin(prog=sdtm_fulldomain_test, macro=sdtm_fulldomain);

/*----------------------------------------------------------------------------
 * Test data
 *   sdq_lb   : parent domain LB, sorted by USUBJID LBSEQ (documented contract)
 *   sdq_supp : SDTM.SUPPLB with a labeled QVAL, numeric IDVAR=LBSEQ
 * Note: QVAL carries a label here to exercise QLABEL -> variable label
 *       propagation.  The unlabeled-QVAL regression is covered separately by
 *       sdtm_fulldomain_bug_nolabel.sas.
 *--------------------------------------------------------------------------*/
data sdq_lb;
  length usubjid $10 lbcat $8 lbtestcd $8 lborres $10;
  usubjid='S01'; lbseq=1; lbcat='CHEM'; lbtestcd='ALT'; lborres='10'; output;
  usubjid='S01'; lbseq=2; lbcat='CHEM'; lbtestcd='AST'; lborres='20'; output;
  usubjid='S02'; lbseq=1; lbcat='HEMA'; lbtestcd='HGB'; lborres='13'; output;
run;

data sdq_supp;
  length usubjid $10 idvar $8 idvarval $8 qnam $8 qlabel $40 qval $20;
  label qval='Result or Finding in Original Units';
  usubjid='S01'; idvar='LBSEQ'; idvarval='1'; qnam='LBFAST'; qlabel='Fasting Status'; qval='Y'; output;
  usubjid='S01'; idvar='LBSEQ'; idvarval='1'; qnam='LBMETHOD'; qlabel='Method'; qval='ELISA'; output;
  usubjid='S01'; idvar='LBSEQ'; idvarval='2'; qnam='LBFAST'; qlabel='Fasting Status'; qval='N'; output;
  usubjid='S02'; idvar='LBSEQ'; idvarval='1'; qnam='LBFAST'; qlabel='Fasting Status'; qval='Y'; output;
run;

/*----------------------------------------------------------------------------
 * CASE 1 : basic merge, numeric IDVAR (LBSEQ), several QNAM values
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 merge numeric IDVAR LBSEQ);
%sdtm_fulldomain(domain=lb, parent=work.sdq_lb, supp=work.sdq_supp, out=work.sdq_full1);
%qc_expect_ds(ds=work.sdq_full1, desc=C1 output dataset created);
%qc_expect_nobs(ds=work.sdq_full1, expect=3, desc=C1 row count equals parent);
%qc_expect_var(ds=work.sdq_full1, var=LBFAST, type=C, desc=C1 LBFAST created as char);
%qc_expect_var(ds=work.sdq_full1, var=LBMETHOD, type=C, desc=C1 LBMETHOD created as char);
%qc_expect_len(ds=work.sdq_full1, var=LBFAST, expect=20, desc=C1 qualifier length = QVAL length);
%qc_expect_len(ds=work.sdq_full1, var=usubjid, expect=10, desc=C1 parent length untouched);

proc sql noprint;
  select lborres into :_c1_lb1 trimmed from work.sdq_full1 where usubjid='S01' and lbseq=2;
  select lbfast  into :_c1_bf1 trimmed from work.sdq_full1 where usubjid='S01' and lbseq=1;
  select lbfast  into :_c1_bf2 trimmed from work.sdq_full1 where usubjid='S01' and lbseq=2;
  select lbfast  into :_c1_bf3 trimmed from work.sdq_full1 where usubjid='S02' and lbseq=1;
  select lbmethod into :_c1_m1 trimmed from work.sdq_full1 where usubjid='S01' and lbseq=2;
  select count(*) into :_c1_nm from work.sdq_full1 where lbmethod is not missing;
quit;
%qc_check_eq(actual=&_c1_lb1., expect=20, desc=C1 parent value preserved);
%qc_check_eq(actual=&_c1_bf1., expect=Y, desc=C1 S01/1 LBFAST=Y);
%qc_check_eq(actual=&_c1_bf2., expect=N, desc=C1 S01/2 LBFAST=N);
%qc_check_eq(actual=&_c1_bf3., expect=Y, desc=C1 S02/1 LBFAST=Y);
%qc_check_eq(actual=&_c1_m1., expect=, desc=C1 S01/2 LBMETHOD missing);
%qc_check_eq(actual=&_c1_nm., expect=1, desc=C1 only one LBMETHOD non-missing);

/* variable label comes from QLABEL via IDLABEL */
%let _did=%sysfunc(open(work.sdq_full1));
%let _pos=%sysfunc(varnum(&_did.,LBFAST));
%let _lab=%sysfunc(varlabel(&_did.,&_pos.));
%let _rc=%sysfunc(close(&_did.));
%qc_check_eq(actual=&_lab., expect=Fasting Status, desc=C1 QLABEL becomes variable label);

/* WORK intermediate must be removed */
%qc_check_eq(actual=%sysfunc(exist(work.sdtm_fulldomain1)), expect=0, desc=C1 intermediate WORK dataset removed);

/*----------------------------------------------------------------------------
 * CASE 2 : parent-level qualifier, IDVAR blank -> merge on USUBJID only
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 blank IDVAR parent-level qualifier);
data sdq_suppblank;
  length usubjid $10 idvar $8 idvarval $8 qnam $8 qlabel $40 qval $20;
  label qval='Result or Finding in Original Units';
  usubjid='S01'; idvar=''; idvarval=''; qnam='LBCLSIG'; qlabel='Clinical Significance'; qval='N'; output;
  usubjid='S02'; idvar=''; idvarval=''; qnam='LBCLSIG'; qlabel='Clinical Significance'; qval='Y'; output;
run;
%sdtm_fulldomain(domain=lb, parent=work.sdq_lb, supp=work.sdq_suppblank, out=work.sdq_full2);
%qc_expect_nobs(ds=work.sdq_full2, expect=3, desc=C2 row count unchanged);
%qc_expect_var(ds=work.sdq_full2, var=LBCLSIG, type=C, desc=C2 LBCLSIG created);
proc sql noprint;
  select count(*) into :_c2_n from work.sdq_full2 where usubjid='S01' and lbclsig='N';
  select count(*) into :_c2_y from work.sdq_full2 where usubjid='S02' and lbclsig='Y';
quit;
%qc_check_eq(actual=&_c2_n., expect=2, desc=C2 S01 both rows get qualifier);
%qc_check_eq(actual=&_c2_y., expect=1, desc=C2 S02 row gets qualifier);

/*----------------------------------------------------------------------------
 * CASE 3 : SUPP exists but has 0 observations -> parent copied
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 SUPP with 0 observations copies parent);
data sdq_suppzero; set work.sdq_supp(obs=0); run;
%sdtm_fulldomain(domain=lb, parent=work.sdq_lb, supp=work.sdq_suppzero, out=work.sdq_full3);
%qc_expect_nobs(ds=work.sdq_full3, expect=3, desc=C3 row count equals parent);
/* output structure must be identical to the parent: no IDVAR/IDVARVAL leak */
%let _did=%sysfunc(open(work.sdq_lb));
%let _c3_pn=%sysfunc(attrn(&_did.,nvars));
%let _rc=%sysfunc(close(&_did.));
%let _did=%sysfunc(open(work.sdq_full3));
%let _c3_on=%sysfunc(attrn(&_did.,nvars));
%let _pos=%sysfunc(varnum(&_did.,LBFAST));
%let _c3_posid=%sysfunc(varnum(&_did.,IDVAR));
%let _c3_posval=%sysfunc(varnum(&_did.,IDVARVAL));
%let _rc=%sysfunc(close(&_did.));
%qc_check_eq(actual=&_c3_on., expect=&_c3_pn., desc=C3 variable count equals parent);
%qc_check_eq(actual=&_pos., expect=0, desc=C3 no qualifier variable added);
%qc_check_eq(actual=&_c3_posid., expect=0, desc=C3 IDVAR not added);
%qc_check_eq(actual=&_c3_posval., expect=0, desc=C3 IDVARVAL not added);
proc sql noprint;
  select lbtestcd into :_c3_v trimmed from work.sdq_full3 where usubjid='S01' and lbseq=1;
quit;
%qc_check_eq(actual=&_c3_v., expect=ALT, desc=C3 parent values preserved);

/*----------------------------------------------------------------------------
 * CASE 4 : SUPP parameter empty -> parent copied
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 empty SUPP parameter copies parent);
%sdtm_fulldomain(domain=lb, parent=work.sdq_lb, supp=, out=work.sdq_full4);
%qc_expect_nobs(ds=work.sdq_full4, expect=3, desc=C4 row count equals parent);
%qc_expect_var(ds=work.sdq_full4, var=lborres, desc=C4 parent variables present);
%let _did=%sysfunc(open(work.sdq_full4));
%let _pos=%sysfunc(varnum(&_did.,LBFAST));
%let _rc=%sysfunc(close(&_did.));
%qc_check_eq(actual=&_pos., expect=0, desc=C4 no qualifier variable added);

/*----------------------------------------------------------------------------
 * CASE 5 : SUBJECT=SUBJID instead of the default USUBJID
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 SUBJECT=SUBJID key);
data sdq_lb_subjid;
  length subjid $10 lbcat $8 lbtestcd $8 lborres $10;
  subjid='001'; lbseq=1; lbcat='CHEM'; lbtestcd='ALT'; lborres='10'; output;
  subjid='001'; lbseq=2; lbcat='CHEM'; lbtestcd='AST'; lborres='20'; output;
  subjid='002'; lbseq=1; lbcat='HEMA'; lbtestcd='HGB'; lborres='13'; output;
run;
data sdq_supp_subjid;
  length subjid $10 idvar $8 idvarval $8 qnam $8 qlabel $40 qval $20;
  label qval='Result or Finding in Original Units';
  subjid='001'; idvar='LBSEQ'; idvarval='2'; qnam='LBFAST'; qlabel='Fasting Status'; qval='N'; output;
  subjid='002'; idvar='LBSEQ'; idvarval='1'; qnam='LBFAST'; qlabel='Fasting Status'; qval='Y'; output;
run;
%sdtm_fulldomain(domain=lb, parent=work.sdq_lb_subjid, subject=subjid,
                 supp=work.sdq_supp_subjid, out=work.sdq_full5);
%qc_expect_nobs(ds=work.sdq_full5, expect=3, desc=C5 row count equals parent);
%qc_expect_var(ds=work.sdq_full5, var=LBFAST, type=C, desc=C5 qualifier variable created);
%qc_expect_var(ds=work.sdq_full5, var=SUBJID, type=C, desc=C5 SUBJID retained);
%let _did=%sysfunc(open(work.sdq_full5));
%let _pos=%sysfunc(varnum(&_did.,USUBJID));
%let _rc=%sysfunc(close(&_did.));
%qc_check_eq(actual=&_pos., expect=0, desc=C5 USUBJID not required when SUBJECT=SUBJID);
proc sql noprint;
  select lbfast into :_c5_v1 trimmed from work.sdq_full5 where subjid='001' and lbseq=2;
  select lbfast into :_c5_v2 trimmed from work.sdq_full5 where subjid='002' and lbseq=1;
quit;
%qc_check_eq(actual=&_c5_v1., expect=N, desc=C5 value matched on SUBJID+LBSEQ);
%qc_check_eq(actual=&_c5_v2., expect=Y, desc=C5 second subject matched);

/*----------------------------------------------------------------------------
 * CASE 6 : all SUPP USUBJID missing -> nothing to merge, parent copied
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 all SUPP USUBJID missing copies parent);
data sdq_suppmiss;
  length usubjid $10 idvar $8 idvarval $8 qnam $8 qlabel $40 qval $20;
  label qval='Result or Finding in Original Units';
  usubjid=''; idvar='LBSEQ'; idvarval='1'; qnam='LBFAST'; qlabel='Fasting Status'; qval='Y'; output;
run;
%sdtm_fulldomain(domain=lb, parent=work.sdq_lb, supp=work.sdq_suppmiss, out=work.sdq_full6);
%qc_expect_nobs(ds=work.sdq_full6, expect=3, desc=C6 row count equals parent);
%qc_expect_var(ds=work.sdq_full6, var=usubjid, type=C, desc=C6 parent structure kept);
%let _did=%sysfunc(open(work.sdq_full6));
%let _pos=%sysfunc(varnum(&_did.,LBFAST));
%let _rc=%sysfunc(close(&_did.));
%qc_check_eq(actual=&_pos., expect=0, desc=C6 no qualifier variable added);

/*----------------------------------------------------------------------------
 * CASE 7 : default parameter names, PARENT=sdtm.&DOMAIN.,
 *          SUPP=sdtm.supp&DOMAIN., OUT=&DOMAIN.
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 default parameter names via SDTM libref);
options dlcreatedir;
libname sdtm "&_QCSB_LIB_.";
data sdtm.lb;     set work.sdq_lb;   run;
data sdtm.supplb; set work.sdq_supp; run;
%sdtm_fulldomain(domain=lb);
%qc_expect_ds(ds=work.lb, desc=C7 default OUT=WORK.lb created);
%qc_expect_nobs(ds=work.lb, expect=3, desc=C7 row count equals parent);
%qc_expect_var(ds=work.lb, var=LBFAST, type=C, desc=C7 default SUPP was merged);
proc sql noprint;
  select lbfast into :_c7_v trimmed from work.lb where usubjid='S01' and lbseq=2;
quit;
%qc_check_eq(actual=&_c7_v., expect=N, desc=C7 value from default SUPP);
libname sdtm clear;

/*----------------------------------------------------------------------------
 * CASE 8 : OUT= dataset in another library
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 OUT in another library);
options dlcreatedir;
libname sdq2 "&_QCSB_LIB2_.";
%sdtm_fulldomain(domain=lb, parent=work.sdq_lb, supp=work.sdq_supp, out=sdq2.full8);
%qc_expect_ds(ds=sdq2.full8, desc=C8 output created in SDQ2);
%qc_expect_nobs(ds=sdq2.full8, expect=3, desc=C8 row count equals parent);
%qc_expect_var(ds=sdq2.full8, var=LBMETHOD, type=C, desc=C8 qualifier variable present);
%qc_check_eq(actual=%sysfunc(exist(work.sdtm_fulldomain1)), expect=0, desc=C8 intermediate removed);
libname sdq2 clear;

/*----------------------------------------------------------------------------
 * CASE 9 : all QNAM variables take the QVAL length; longer values preserved
 *--------------------------------------------------------------------------*/
%qc_case(desc=9 QVAL length propagation);
data sdq_supplen;
  length usubjid $10 idvar $8 idvarval $8 qnam $8 qlabel $40 qval $50;
  label qval='Result or Finding in Original Units';
  usubjid='S01'; idvar='LBSEQ'; idvarval='1'; qnam='LBFAST'; qlabel='Fasting Status'; qval='Y'; output;
  usubjid='S01'; idvar='LBSEQ'; idvarval='1'; qnam='LBCOMM'; qlabel='Comment'; qval='sample comment text'; output;
  usubjid='S01'; idvar='LBSEQ'; idvarval='2'; qnam='LBFAST'; qlabel='Fasting Status'; qval='N'; output;
run;
%sdtm_fulldomain(domain=lb, parent=work.sdq_lb, supp=work.sdq_supplen, out=work.sdq_full9);
%qc_expect_len(ds=work.sdq_full9, var=LBFAST, expect=50, desc=C9 all QNAM vars use QVAL length);
%qc_expect_len(ds=work.sdq_full9, var=LBCOMM, expect=50, desc=C9 new QNAM var length);
proc sql noprint;
  select lbcomm into :_c9_v trimmed from work.sdq_full9 where usubjid='S01' and lbseq=1;
quit;
%qc_check_eq(actual=&_c9_v., expect=sample comment text, desc=C9 long QVAL value preserved);

/*----------------------------------------------------------------------------
 * CASE 10 : PARENT= and SUPP= passed with dataset options (where=)
 *           Also exercises the new %var_coexist/%var_attr validation on a
 *           data set name that carries options.
 *--------------------------------------------------------------------------*/
%qc_case(desc=10 PARENT and SUPP dataset options);
%sdtm_fulldomain(domain=lb, parent=work.sdq_lb(where=(lbseq=1)),
                 supp=work.sdq_supp(where=(usubjid='S01' and idvarval='1')), out=work.sdq_full10);
%qc_expect_nobs(ds=work.sdq_full10, expect=2, desc=C10 row count equals filtered parent);
proc sql noprint;
  select lbfast into :_c10_1 trimmed from work.sdq_full10 where usubjid='S01' and lbseq=1;
  select lbmethod into :_c10_2 trimmed from work.sdq_full10 where usubjid='S01' and lbseq=1;
  select count(*) into :_c10_s02 from work.sdq_full10 where usubjid='S02' and lbfast is not missing;
quit;
%qc_check_eq(actual=&_c10_1., expect=Y, desc=C10 filtered SUPP applied with dataset option);
%qc_check_eq(actual=&_c10_2., expect=ELISA, desc=C10 second qualifier applied);
%qc_check_eq(actual=&_c10_s02., expect=0, desc=C10 filtered-out subject has no qualifier);

/*----------------------------------------------------------------------------
 * CASE 11 : in-place merge, OUT= equals PARENT=
 *--------------------------------------------------------------------------*/
%qc_case(desc=11 in-place merge OUT=PARENT);
data sdq_inplace; set work.sdq_lb; run;
%sdtm_fulldomain(domain=lb, parent=work.sdq_inplace, supp=work.sdq_supp, out=work.sdq_inplace);
%qc_expect_nobs(ds=work.sdq_inplace, expect=3, desc=C11 row count unchanged);
%qc_expect_var(ds=work.sdq_inplace, var=LBFAST, type=C, desc=C11 qualifier added in place);
proc sql noprint;
  select lbfast into :_c11_v trimmed from work.sdq_inplace where usubjid='S01' and lbseq=1;
quit;
%qc_check_eq(actual=&_c11_v., expect=Y, desc=C11 in-place value correct);

/*----------------------------------------------------------------------------
 * CASE 12 : multiple SUBJECT= key variables (USUBJID SUBJID)
 *           Records whose first SUBJECT variable is missing are filtered out
 *           by the transposed SUPP view.
 *--------------------------------------------------------------------------*/
%qc_case(desc=12 multiple SUBJECT variables);
data sdq_lb_2key;
  length usubjid $10 subjid $10 lbcat $8 lbtestcd $8 lborres $10;
  usubjid='S01'; subjid='001'; lbseq=1; lbcat='CHEM'; lbtestcd='ALT'; lborres='10'; output;
  usubjid='S01'; subjid='001'; lbseq=2; lbcat='CHEM'; lbtestcd='AST'; lborres='20'; output;
  usubjid='S02'; subjid='002'; lbseq=1; lbcat='HEMA'; lbtestcd='HGB'; lborres='13'; output;
run;
data sdq_supp_2key;
  length usubjid $10 subjid $10 idvar $8 idvarval $8 qnam $8 qlabel $40 qval $20;
  label qval='Result or Finding in Original Units';
  usubjid='';    subjid='003'; idvar='LBSEQ'; idvarval='1'; qnam='LBFAST'; qlabel='Fasting Status'; qval='Y'; output;
  usubjid='S01'; subjid='001'; idvar='LBSEQ'; idvarval='1'; qnam='LBFAST'; qlabel='Fasting Status'; qval='Y'; output;
  usubjid='S01'; subjid='001'; idvar='LBSEQ'; idvarval='2'; qnam='LBFAST'; qlabel='Fasting Status'; qval='N'; output;
  usubjid='S02'; subjid='002'; idvar='LBSEQ'; idvarval='1'; qnam='LBFAST'; qlabel='Fasting Status'; qval='Y'; output;
run;
%sdtm_fulldomain(domain=lb, parent=work.sdq_lb_2key, subject=USUBJID SUBJID,
                 supp=work.sdq_supp_2key, out=work.sdq_full12);
%qc_expect_nobs(ds=work.sdq_full12, expect=3, desc=C12 row count equals parent);
%qc_expect_var(ds=work.sdq_full12, var=LBFAST, type=C, desc=C12 qualifier variable created);
%qc_expect_var(ds=work.sdq_full12, var=SUBJID, type=C, desc=C12 second key variable retained);
proc sql noprint;
  select lbfast into :_c12_1 trimmed from work.sdq_full12 where usubjid='S01' and subjid='001' and lbseq=1;
  select lbfast into :_c12_2 trimmed from work.sdq_full12 where usubjid='S01' and subjid='001' and lbseq=2;
  select lbfast into :_c12_3 trimmed from work.sdq_full12 where usubjid='S02' and subjid='002' and lbseq=1;
  select count(*) into :_c12_orphan from work.sdq_full12 where subjid='003';
quit;
%qc_check_eq(actual=&_c12_1., expect=Y, desc=C12 first subject value);
%qc_check_eq(actual=&_c12_2., expect=N, desc=C12 first subject second record);
%qc_check_eq(actual=&_c12_3., expect=Y, desc=C12 second subject value);
%qc_check_eq(actual=&_c12_orphan., expect=0, desc=C12 missing first SUBJECT value filtered out);

/*----------------------------------------------------------------------------
 * CASE 13 : SUPP= points to a dataset that does not exist
 *           Expected behaviour: the parent domain is copied to OUT.
 *--------------------------------------------------------------------------*/
%qc_case(desc=13 non-existing SUPP copies parent);
%sdtm_fulldomain(domain=lb, parent=work.sdq_lb, supp=work.sdq_no_such_supp, out=work.sdq_full13);
%qc_expect_ds(ds=work.sdq_full13, desc=C13 output dataset created);
%qc_expect_nobs(ds=work.sdq_full13, expect=3, desc=C13 row count equals parent);
%qc_expect_var(ds=work.sdq_full13, var=lbtestcd, desc=C13 parent structure kept);
%let _did=%sysfunc(open(work.sdq_full13));
%let _pos=%sysfunc(varnum(&_did.,LBFAST));
%let _rc=%sysfunc(close(&_did.));
%qc_check_eq(actual=&_pos., expect=0, desc=C13 no qualifier variable added);
%qc_check_eq(actual=%sysfunc(exist(work.sdtm_fulldomain1)), expect=0, desc=C13 intermediate removed);
proc sql noprint;
  select lborres into :_c13_v trimmed from work.sdq_full13 where usubjid='S01' and lbseq=2;
quit;
%qc_check_eq(actual=&_c13_v., expect=20, desc=C13 parent value preserved);

/*----------------------------------------------------------------------------
 * CASE 14 : SUPP= is a VIEW.  EXIST() returns 0 for views, so it follows the
 *           same "SUPP not available" path and the parent is copied.
 *--------------------------------------------------------------------------*/
%qc_case(desc=14 SUPP as view copies parent);
proc sql;
  create view work.sdq_suppview as select * from work.sdq_supp;
quit;
%sdtm_fulldomain(domain=lb, parent=work.sdq_lb, supp=work.sdq_suppview, out=work.sdq_full14);
%qc_expect_nobs(ds=work.sdq_full14, expect=3, desc=C14 row count equals parent);
%qc_expect_var(ds=work.sdq_full14, var=lborres, desc=C14 parent variables present);
%let _did=%sysfunc(open(work.sdq_full14));
%let _pos=%sysfunc(varnum(&_did.,LBFAST));
%let _rc=%sysfunc(close(&_did.));
%qc_check_eq(actual=&_pos., expect=0, desc=C14 view SUPP not merged);
%qc_check_eq(actual=%sysfunc(exist(work.sdtm_fulldomain1)), expect=0, desc=C14 intermediate removed);

%qc_end;
