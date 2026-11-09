/*==============================================================================
 * qc_sandbox.sas - Per-program, per-session temporary sandbox
 *==============================================================================
 * Every test program gets its OWN temporary root:
 *     qc\_sandbox_tmp\<test-program-name>_<SYSJOBID>\
 * so no program can see or depend on another program's files, and a rerun
 * never inherits leftovers from an earlier session.
 *
 * %qc_sandbox_reset() only BUILDS the tree; it does not delete anything in the
 * SAS session (terminal commands are not allowed in .sas programs and SAS
 * FDELETE cannot remove a non-empty directory). run_all.ps1 removes
 * qc\_sandbox_tmp after every test program, so each program ends with no
 * temporary sandbox left behind. Standalone runs leave a uniquely named
 * directory that cannot affect later runs.
 *
 * Tree created under the per-program root (path macro variables in qc_env.sas)
 *     d1\      f1.txt  f2.sas   sub1\ (f3.txt f4.log)   sub2\ (f5.csv)
 *     d2\      f6.txt
 *     lib\     SAS library used by lib_* tests (contents built by the test)
 *     lib2\    second SAS library
 *============================================================================*/

/* delete a file or an empty directory by full path; failures are ignored */
%macro _qc_sb_del(path=);
  data _null_;
    rc=filename('_qcsb_',"&path.");
    if rc=0 then do;
      del=fdelete('_qcsb_');
      rc2=filename('_qcsb_');
    end;
  run;
%mend _qc_sb_del;

/* create one directory level under parent; "already exists" is ignored */
%macro _qc_sb_mkdir(name=,parent=);
  data _null_;
    rc=dcreate("&name.","&parent.");
  run;
%mend _qc_sb_mkdir;

/* create a small text file */
%macro _qc_sb_mkfile(path=,content=qc);
  data _null_;
    file "&path.";
    put "&content.";
  run;
%mend _qc_sb_mkfile;

/* build this program's temporary sandbox from scratch */
%macro qc_sandbox_reset;
  %global _QCSBPROG_ _QCSBRUN_ _QCSB_ _QCSB_D1_ _QCSB_D1S1_ _QCSB_D1S2_ _QCSB_D2_
          _QCSB_LIB_ _QCSB_LIB2_ _QCSB_TXT_ _QCSB_SAS_ _QCSB_TXT3_
          _QCSB_LOG_ _QCSB_CSV_ _QCSB_TXT6_;
  %local _qcfile_;

  /* derive the per-program, per-session root from SYSIN and SYSJOBID */
  %let _qcfile_=%scan(%sysfunc(getoption(sysin)),-1,%str(/\));
  %let _QCSBPROG_=%scan(&_qcfile_.,1,%str(.));
  %if %quote(&_QCSBPROG_.)=%str() %then %let _QCSBPROG_=_default;
  %let _QCSBRUN_=&sysjobid.;
  %if %quote(&_QCSBRUN_.)=%str() %then %let _QCSBRUN_=0;

  %let _QCSB_=&_QCSBTMP_.\&_QCSBPROG_._&_QCSBRUN_.;
  %let _QCSB_D1_=&_QCSB_.\d1;
  %let _QCSB_D1S1_=&_QCSB_.\d1\sub1;
  %let _QCSB_D1S2_=&_QCSB_.\d1\sub2;
  %let _QCSB_D2_=&_QCSB_.\d2;
  %let _QCSB_LIB_=&_QCSB_.\lib;
  %let _QCSB_LIB2_=&_QCSB_.\lib2;
  %let _QCSB_TXT_=&_QCSB_.\d1\f1.txt;
  %let _QCSB_SAS_=&_QCSB_.\d1\f2.sas;
  %let _QCSB_TXT3_=&_QCSB_.\d1\sub1\f3.txt;
  %let _QCSB_LOG_=&_QCSB_.\d1\sub1\f4.log;
  %let _QCSB_CSV_=&_QCSB_.\d1\sub2\f5.csv;
  %let _QCSB_TXT6_=&_QCSB_.\d2\f6.txt;

  /* build the directory tree */
  %_qc_sb_mkdir(name=_sandbox_tmp,parent=&_QCQC_.);
  %_qc_sb_mkdir(name=&_QCSBPROG_._&_QCSBRUN_.,parent=&_QCSBTMP_.);
  %_qc_sb_mkdir(name=d1,   parent=&_QCSB_.);
  %_qc_sb_mkdir(name=d2,   parent=&_QCSB_.);
  %_qc_sb_mkdir(name=lib,  parent=&_QCSB_.);
  %_qc_sb_mkdir(name=lib2, parent=&_QCSB_.);
  %_qc_sb_mkdir(name=sub1, parent=&_QCSB_.\d1);
  %_qc_sb_mkdir(name=sub2, parent=&_QCSB_.\d1);

  /* build the files */
  %_qc_sb_mkfile(path=&_QCSB_TXT_.,  content=qc-sandbox-f1);
  %_qc_sb_mkfile(path=&_QCSB_SAS_,   content=*qc-sandbox-f2;);
  %_qc_sb_mkfile(path=&_QCSB_TXT3_., content=qc-sandbox-f3);
  %_qc_sb_mkfile(path=&_QCSB_LOG_,   content=qc-sandbox-f4);
  %_qc_sb_mkfile(path=&_QCSB_CSV_,   content=qc-sandbox-f5);
  %_qc_sb_mkfile(path=&_QCSB_TXT6_., content=qc-sandbox-f6);

%mend qc_sandbox_reset;

/*==============================================================================
 * End of qc_sandbox.sas
 *============================================================================*/
