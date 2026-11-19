/*==============================================================================
 * stat_summaryn_bug_gmlabel.sas - Bug regression: GM_LCLM and GM_UCLM expose internal variable names as labels
 *==============================================================================
 * Macro under test : %stat_summaryn
 * Expected         : _STATLAB_ for GM_LCLM and GM_UCLM carries a readable label
 *                    (no internal name such as __stat_GM_LCLM)
 * Status           : OPEN
 * Original defect  : STATIS=GM_LCLM or GM_UCLM produces _statlab_ values
 *                    "__stat_GM_LCLM" and "__stat_GM_UCLM" because the LABEL
 *                    statement assigns labels to __stat_gm_clm but not to
 *                    __stat_gm_lclm / __stat_gm_uclm (dev/stat/stat_summaryn.sas
 *                    lines 391-399)
 * Fix              : Add label __stat_gm_lclm='GM 95% CI Lower' and
 *                    __stat_gm_uclm='GM 95% CI Upper' in the LABEL statement
 * Test passes when  the defect is fixed (run_all then reports FIXED)
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
%include "&_QCDEV_DS_.\ds_attr.sas";
%include "&_QCDEV_STAT_.\stat_summaryn.sas";

%qc_begin(prog=stat_summaryn_bug_gmlabel, macro=stat_summaryn);

data sn_bug_gm;
  input x;
  datalines;
1
2
4
8
;
run;

%stat_summaryn(data=sn_bug_gm, out=bugout, var=x, statis=gm gm_lclm gm_uclm);

data _null_;
  set bugout end=_eof_;
  if _statnam_='GM_LCLM' and index(upcase(_statlab_),'__STAT_')>0 then call symputx('_badlclm','1');
  if _statnam_='GM_UCLM' and index(upcase(_statlab_),'__STAT_')>0 then call symputx('_baduclm','1');
  if _eof_ then do;
    if not symexist('_badlclm') then call symputx('_badlclm','0');
    if not symexist('_baduclm') then call symputx('_baduclm','0');
  end;
run;

%qc_case(desc=1 geometric lower limit label is readable);
%qc_check_eq(actual=&_badlclm., expect=0, desc=B1 GM_LCLM label must not expose internal name);

%qc_case(desc=2 geometric upper limit label is readable);
%qc_check_eq(actual=&_baduclm., expect=0, desc=B2 GM_UCLM label must not expose internal name);

%qc_end;
