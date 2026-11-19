/*===============================================================================
 * dir_memlist_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %dir_memlist
 * File under test   : dev/dir/dir_memlist.sas
 * Dependencies     : %dir_exist
 * Coverage         : depth-limited listing, record structure and variable
 *                    lengths, root record, file/directory classification,
 *                    EXT= filtering with case-insensitivity, no-match empty
 *                    result, MEMINFO=N/Y output columns, lowercase meminfo,
 *                    EXT plus MEMINFO combination, and an empty directory.
 * Note             : this QC session runs on Windows (WIN), so the Windows
 *                    member-info columns are exercised.
 * Run              : qc/run_all.ps1  (or standalone batch, see README)
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
%include "&_QCQC_.\_framework\qc_sandbox.sas";
%include "&_QCDEV_DIR_.\dir_exist.sas";
%include "&_QCDEV_DIR_.\dir_memlist.sas";
%qc_sandbox_reset;

%qc_begin(prog=dir_memlist_test, macro=dir_memlist);

/*----------------------------------------------------------------------------
 * CASE 1 : basic listing of d1 at depth 1 (root + 4 members)
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 basic listing depth 1);
%dir_memlist(dir=&_QCSB_D1_., out=work.ml_d1, maxdepth=1);
%qc_expect_nobs(ds=work.ml_d1, expect=5, desc=C1 five rows);
%qc_expect_colval(ds=work.ml_d1, var=path, where=depth=0, expect=&_QCSB_D1_., desc=C1 root path unquoted);
%qc_expect_colval(ds=work.ml_d1, var=type, where=depth=0, expect=Directory, desc=C1 root record is directory);
%qc_expect_colval(ds=work.ml_d1, var=type, where=name='f1.txt', expect=File, desc=C1 f1 classified as file);
%qc_expect_colval(ds=work.ml_d1, var=ext, where=name='f1.txt', expect=TXT, desc=C1 f1 ext upcased);
%qc_expect_len(ds=work.ml_d1, var=path, expect=1024, desc=C1 path length 1024);
%qc_expect_len(ds=work.ml_d1, var=name, expect=255, desc=C1 name length 255);
%qc_expect_len(ds=work.ml_d1, var=ext, expect=255, desc=C1 ext length 255);
%qc_expect_len(ds=work.ml_d1, var=type, expect=9, desc=C1 type length 9);
%qc_expect_var(ds=work.ml_d1, var=depth, type=N, desc=C1 depth is numeric);
%let _did=%sysfunc(open(work.ml_d1));
%let _novar=%sysfunc(varnum(&_did.,filesize));
%let _did=%sysfunc(close(&_did.));
%qc_check_eq(actual=&_novar., expect=0, desc=C1 meminfo N omits filesize);

/*----------------------------------------------------------------------------
 * CASE 2 : recursive listing of the sandbox at depth 2
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 recursive listing depth 2);
%dir_memlist(dir=&_QCSB_., out=work.ml_sb2, maxdepth=2);
%qc_expect_nobs(ds=work.ml_sb2, expect=10, desc=C2 ten rows);
%qc_expect_colval(ds=work.ml_sb2, var=depth, where=name='d1', expect=1, desc=C2 d1 at depth 1);
%qc_expect_colval(ds=work.ml_sb2, var=depth, where=name='f6.txt', expect=2, desc=C2 f6 at depth 2);
%qc_expect_colval(ds=work.ml_sb2, var=type, where=name='lib', expect=Directory, desc=C2 lib is directory);

/*----------------------------------------------------------------------------
 * CASE 3 : MAXDEPTH=1 stops before deeper files
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 depth boundary);
%dir_memlist(dir=&_QCSB_., out=work.ml_sb1, maxdepth=1);
%qc_expect_nobs(ds=work.ml_sb1, expect=5, desc=C3 five rows at depth 1);
proc sql noprint;
  select count(*) into :_c3 from work.ml_sb1 where name='f1.txt';
quit;
%qc_check_eq(actual=&_c3., expect=0, desc=C3 f1 excluded by depth 1);

/*----------------------------------------------------------------------------
 * CASE 4 : EXT= filter keeps only matching files
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 EXT filter);
%dir_memlist(dir=&_QCSB_., out=work.ml_txt, maxdepth=3, ext=txt);
%qc_expect_nobs(ds=work.ml_txt, expect=3, desc=C4 three txt rows);
proc sql noprint;
  select count(*) into :_c4 from work.ml_txt where ext^='TXT';
quit;
%qc_check_eq(actual=&_c4., expect=0, desc=C4 all rows ext TXT);
%qc_expect_colval(ds=work.ml_txt, var=depth, where=name='f3.txt', expect=3, desc=C4 f3 found at depth 3);

/*----------------------------------------------------------------------------
 * CASE 5 : EXT= value is case-insensitive
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 EXT case-insensitive);
%dir_memlist(dir=&_QCSB_., out=work.ml_txt2, maxdepth=3, ext=TxT);
%qc_expect_nobs(ds=work.ml_txt2, expect=3, desc=C5 mixed case TxT gives 3 rows);

/*----------------------------------------------------------------------------
 * CASE 6 : MEMINFO=Y adds Windows file info columns
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 MEMINFO Y file info);
%dir_memlist(dir=&_QCSB_D1_., out=work.ml_mi, maxdepth=1, meminfo=Y);
%qc_expect_nobs(ds=work.ml_mi, expect=5, desc=C6 five rows);
%qc_expect_var(ds=work.ml_mi, var=filesize, type=N, desc=C6 filesize is numeric);
%qc_expect_var(ds=work.ml_mi, var=modtm, type=N, desc=C6 modtm is numeric);
%qc_expect_var(ds=work.ml_mi, var=crdtm, type=N, desc=C6 crdtm is numeric);
%qc_expect_var(ds=work.ml_mi, var=recfm, type=C, desc=C6 recfm is character);
%qc_expect_var(ds=work.ml_mi, var=lrecl, type=N, desc=C6 lrecl is numeric);
%qc_expect_colval(ds=work.ml_mi, var=filesize, where=name='f1.txt', expect=15, desc=C6 f1 filesize 15);
%qc_expect_colval(ds=work.ml_mi, var=recfm, where=name='f1.txt', expect=V, desc=C6 f1 recfm V);
%qc_expect_fmt(ds=work.ml_mi, var=modtm, expect=E8601DT., desc=C6 modtm format E8601DT);
%qc_expect_len(ds=work.ml_mi, var=recfm, expect=8, desc=C6 recfm length 8);

/*----------------------------------------------------------------------------
 * CASE 7 : no extension match returns an empty dataset
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 no extension match);
%dir_memlist(dir=&_QCSB_., out=work.ml_none, maxdepth=3, ext=zzz);
%qc_expect_ds(ds=work.ml_none, desc=C7 result dataset exists);
%qc_expect_nobs(ds=work.ml_none, expect=0, desc=C7 zero rows);

/*----------------------------------------------------------------------------
 * CASE 8 : empty directory produces only the root record
 *--------------------------------------------------------------------------*/
%qc_case(desc=8 empty directory);
data _null_;
  rc=dcreate('_qc_dir_ml_empty',"&_QCRES_.");
run;
%dir_memlist(dir=&_QCRES_\_qc_dir_ml_empty, out=work.ml_empty, maxdepth=1);
%qc_expect_nobs(ds=work.ml_empty, expect=1, desc=C8 one root row);
%qc_expect_colval(ds=work.ml_empty, var=type, where=depth=0, expect=Directory, desc=C8 root is directory);
data _null_;
  rc=filename('_qcdm',"&_QCRES_\_qc_dir_ml_empty");
  rc2=fdelete('_qcdm');
  rc3=filename('_qcdm');
run;

/*----------------------------------------------------------------------------
 * CASE 9 : MEMINFO= value is case-insensitive
 *--------------------------------------------------------------------------*/
%qc_case(desc=9 MEMINFO case-insensitive);
%dir_memlist(dir=&_QCSB_D1_., out=work.ml_miy, maxdepth=1, meminfo=y);
%qc_expect_nobs(ds=work.ml_miy, expect=5, desc=C9 five rows);
%qc_expect_var(ds=work.ml_miy, var=filesize, type=N, desc=C9 lowercase y keeps filesize);

/*----------------------------------------------------------------------------
 * CASE 10 : EXT= and MEMINFO=Y combined
 *--------------------------------------------------------------------------*/
%qc_case(desc=10 EXT plus MEMINFO);
%dir_memlist(dir=&_QCSB_., out=work.ml_txtmi, maxdepth=3, ext=txt, meminfo=Y);
%qc_expect_nobs(ds=work.ml_txtmi, expect=3, desc=C10 three txt rows);
%qc_expect_colval(ds=work.ml_txtmi, var=filesize, where=name='f1.txt', expect=15, desc=C10 f1 filesize 15);

%qc_end;
