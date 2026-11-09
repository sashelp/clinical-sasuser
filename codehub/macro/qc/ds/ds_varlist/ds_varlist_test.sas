/*==============================================================================
 * ds_varlist_test.sas - Positive (functional) acceptance tests
 *==============================================================================
 * Macro under test : %ds_varlist
 * File under test   : dev/ds/ds_varlist.sas
 * Coverage          : all vars, TYPE=C / TYPE=N filters, PATTERN regex,
 *                     combined TYPE+PATTERN, empty filter values, result
 *                     order, no-match empty result, case handling.
 * Run               : qc/run_all.ps1 (or standalone batch)
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
%include "&_QCQC_.\_framework\qc_testdata.sas";
%include "&_QCDEV_DS_.\ds_varlist.sas";

%qc_begin(prog=ds_varlist_test, macro=ds_varlist);

%qc_data_mixed(ds=vl1);   /* char1, num1, num2, dt, big, pct  */
%qc_data_allchar(ds=vlc);
%qc_data_allnum(ds=vln);

/*----------------------------------------------------------------------------
 * CASE 1 : no filter -> all variables in dataset order
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 all variables returned);
%qc_check_eq(actual=%ds_varlist(data=vl1), expect=char1 num1 num2 dt big pct,
  desc=C1 all vars order);
%qc_check_eq(actual=%ds_varlist(data=vlc), expect=c1 c2 c3,
  desc=C1 all-char dataset);
%qc_check_eq(actual=%ds_varlist(data=vln), expect=n1 n2 n3,
  desc=C1 all-num dataset);

/*----------------------------------------------------------------------------
 * CASE 2 : TYPE=C
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 TYPE=C filter);
%qc_check_eq(actual=%ds_varlist(data=vl1,type=c), expect=char1,
  desc=C2 char vars only);

/*----------------------------------------------------------------------------
 * CASE 3 : TYPE=N
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 TYPE=N filter);
%qc_check_eq(actual=%ds_varlist(data=vl1,type=n), expect=num1 num2 dt big pct,
  desc=C3 num vars only);

/*----------------------------------------------------------------------------
 * CASE 4 : TYPE value case-insensitive
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 TYPE value case-insensitive);
%qc_check_eq(actual=%ds_varlist(data=vl1,type=C), expect=char1,
  desc=C4 uppercase C);
%qc_check_eq(actual=%ds_varlist(data=vl1,type=N), expect=num1 num2 dt big pct,
  desc=C4 uppercase N);
/*----------------------------------------------------------------------------
 * CASE 5 : TYPE empty is allowed (treated as no filter)
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 empty TYPE means no filter);
%qc_check_eq(actual=%ds_varlist(data=vl1,type=), expect=char1 num1 num2 dt big pct,
  desc=C5 empty type all vars);
/*----------------------------------------------------------------------------
 * CASE 6 : PATTERN filter - prefix
 *          Note: PATTERN is passed to prxparse() which requires delimiters,
 *          so use /^num/ form. This reflects how the macro actually works
 *          (the header just says "regular expression").
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 PATTERN prefix match);
%let _pat=%nrstr(/^num/);
%let _r=%ds_varlist(data=vl1,pattern=%superq(_pat));
%qc_check(cond=%bquote(&_r.)=%bquote(num1 num2), desc=C6 prefix ^num);

/*----------------------------------------------------------------------------
 * CASE 7 : PATTERN filter - suffix
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 PATTERN suffix match);
%let _pat=%nrstr(/1$/);
%let _r=%ds_varlist(data=vl1,pattern=%superq(_pat));
%qc_check(cond=%bquote(&_r.)=%bquote(char1 num1), desc=C7 suffix 1$ order);

/*----------------------------------------------------------------------------
 * CASE 8 : PATTERN filter - substring
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 PATTERN substring match);
%let _pat=%nrstr(/num/);
%let _r=%ds_varlist(data=vl1,pattern=%superq(_pat));
%qc_check(cond=%bquote(&_r.)=%bquote(num1 num2), desc=C8 substring num);

/*----------------------------------------------------------------------------
 * CASE 9 : combined TYPE=N and PATTERN
 *--------------------------------------------------------------------------*/
%qc_case(desc=9 combined TYPE and PATTERN);
data vl9;
  x1=1; x2=2; y1='a'; y2='b';
run;
%let _pat=%nrstr(/^x/);
%let _r=%ds_varlist(data=vl9,type=n,pattern=%superq(_pat));
%qc_check(cond=%bquote(&_r.)=%bquote(x1 x2), desc=C9 numeric vars with prefix x);

/*----------------------------------------------------------------------------
 * CASE 10 : result ORDER is dataset variable order, not alphabetical
 *--------------------------------------------------------------------------*/
%qc_case(desc=10 result order follows dataset order);
data vl10;
  zz=1; aa=2; mm=3;
run;
%qc_check_eq(actual=%ds_varlist(data=vl10), expect=zz aa mm,
  desc=C10 order as defined);
%let _pat=%nrstr(/^m/);
%let _r=%ds_varlist(data=vl10,pattern=%superq(_pat));
%qc_check(cond=%bquote(&_r.)=%bquote(mm), desc=C10 pattern single result);

/*----------------------------------------------------------------------------
 * CASE 11 : no match -> empty result
 *--------------------------------------------------------------------------*/
%qc_case(desc=11 no match returns empty);
%let _pat=%nrstr(/zzz_nomatch/);
%let _r=%ds_varlist(data=vl1,pattern=%superq(_pat));
%qc_check(cond=%bquote(&_r.)=%bquote(), desc=C11 empty result no match);
%qc_check_eq(actual=%ds_varlist(data=vlc,type=n), expect=,
  desc=C11 no numeric vars in all-char dataset);

/*----------------------------------------------------------------------------
 * CASE 12 : wide dataset (e.g. 50 vars) robustness
 *--------------------------------------------------------------------------*/
%qc_case(desc=12 wide dataset 50 vars);
%qc_data_wide(ds=vl12,n=50);
%qc_check_eq(actual=%ds_varlist(data=vl12,type=n), expect=v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14 v15 v16 v17 v18 v19 v20 v21 v22 v23 v24 v25 v26 v27 v28 v29 v30 v31 v32 v33 v34 v35 v36 v37 v38 v39 v40 v41 v42 v43 v44 v45 v46 v47 v48 v49 v50,
  desc=C12 all 50 numeric vars);

/*----------------------------------------------------------------------------
 * CASE 13 : library-qualified dataset
 *--------------------------------------------------------------------------*/
%qc_case(desc=13 library-qualified dataset);
libname qcwork "&_QCRES_.";
data qcwork.vl13;
  a=1; b='x';
run;
%qc_check_eq(actual=%ds_varlist(data=qcwork.vl13), expect=a b,
  desc=C13 qualified dataset all vars);

/*----------------------------------------------------------------------------
 * CASE 14 : (removed) SAS view is NOT supported by design -- DATA= accepts a
 *           dataset only. The contract is locked by the negative test
 *           ds_varlist_err_05.sas (view input must abort), not by a bug file.
 *--------------------------------------------------------------------------*/
%qc_end;