/*===============================================================================
 * file_attr_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %file_attr
 * File under test   : dev/file/file_attr.sas
 * Coverage          : FILENAME / RECFM / LRECL / FILESIZE / CRDTM / MODTM on a
 *                     known sandbox file, ATTR case-insensitivity, file size in
 *                     bytes.
 * Note              : this QC session runs on Windows (WIN), so the Windows
 *                     attribute set is exercised.
 * Run               : qc/run_all.ps1  (or standalone batch, see README)
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
%include "&_QCDEV_FILE_.\file_attr.sas";
%qc_sandbox_reset;

%qc_begin(prog=file_attr_test, macro=file_attr);

/* f1.txt contains "qc-sandbox-f1" = 13 bytes (no CRLF added by _qc_sb_mkfile) */
%let _file_=&_QCSB_TXT_.;
%qc_expect_file(file=&_file_., expect=1, desc=C0 sandbox f1 exists);

/*----------------------------------------------------------------------------
 * CASE 1 : FILENAME (returns the full path seen by SAS)
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 FILENAME);
%let _r=%file_attr(file=&_file_.,attr=filename);
%qc_check(cond=%bquote(&_r.)^=%bquote(), desc=C1 filename not empty);
%qc_check(cond=%index(%bquote(&_r.),f1.txt)>0, desc=C1 filename contains f1.txt);

/*----------------------------------------------------------------------------
 * CASE 2 : RECFM (record format)
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 RECFM);
%let _r=%file_attr(file=&_file_.,attr=recfm);
%qc_check_eq(actual=&_r., expect=V, desc=C2 recfm V);

/*----------------------------------------------------------------------------
 * CASE 3 : LRECL (record length, platform default)
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 LRECL);
%let _r=%file_attr(file=&_file_.,attr=lrecl);
%qc_check(cond=%bquote(&_r.)^=%bquote(), desc=C3 lrecl not empty);

/*----------------------------------------------------------------------------
 * CASE 4 : FILESIZE (15 bytes: "qc-sandbox-f1" + CRLF written by sandbox)
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 FILESIZE);
%let _r=%file_attr(file=&_file_.,attr=filesize);
%qc_check_eq(actual=&_r., expect=15, desc=C4 filesize 15 bytes);

/*----------------------------------------------------------------------------
 * CASE 5 : CRDTM and MODTM are non-empty strings
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 CRDTM and MODTM);
%let _r=%file_attr(file=&_file_.,attr=crdtm);
%qc_check(cond=%bquote(&_r.)^=%bquote(), desc=C5 crdtm not empty);
%let _r=%file_attr(file=&_file_.,attr=modtm);
%qc_check(cond=%bquote(&_r.)^=%bquote(), desc=C5 modtm not empty);

/*----------------------------------------------------------------------------
 * CASE 6 : ATTR= value is case-insensitive
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 ATTR case-insensitive);
%let _r=%file_attr(file=&_file_.,attr=FILENAME);
%qc_check(cond=%bquote(&_r.)^=%bquote(), desc=C6 uppercase FILENAME not empty);

%qc_end;