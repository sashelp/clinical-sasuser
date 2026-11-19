/*==============================================================================
 * qc_env.sas - Central path configuration for the QC harness
 *==============================================================================
 * All test programs include this file first. It defines the root paths so that
 * individual test files do not hard-code absolute paths.
 *
 * The library root is derived from the running test program (SYSIN), so no
 * absolute path is hard-coded and the library can be moved or synced across
 * machines without editing this file.
 *============================================================================*/
%global _QCROOT_ _QCDEV_ _QCQC_;
/* test programs live at <Macro>\qc\<theme>\<macro>\<program>.sas */
%let _QCROOT_=%sysfunc(getoption(sysin));
%if %superq(_QCROOT_)=%str() %then %do;
  %put ERROR: SYSIN is not set; cannot derive the macro library root.;
  %abort cancel;
%end;
%let _QCROOT_=%sysfunc(dequote(%superq(_QCROOT_)));
%let _QCROOT_=%substr(%superq(_QCROOT_),1,%eval(%length(%superq(_QCROOT_))-%length(%scan(%superq(_QCROOT_),-1,%str(\)))-1));
%let _QCROOT_=%substr(%superq(_QCROOT_),1,%eval(%length(%superq(_QCROOT_))-%length(%scan(%superq(_QCROOT_),-1,%str(\)))-1));
%let _QCROOT_=%substr(%superq(_QCROOT_),1,%eval(%length(%superq(_QCROOT_))-%length(%scan(%superq(_QCROOT_),-1,%str(\)))-1));
%let _QCROOT_=%substr(%superq(_QCROOT_),1,%eval(%length(%superq(_QCROOT_))-%length(%scan(%superq(_QCROOT_),-1,%str(\)))-1));
%let _QCDEV_=&_QCROOT_.\dev;
%let _QCQC_=&_QCROOT_.\qc;
%if %sysfunc(fileexist("&_QCQC_.\_framework\qc_env.sas"))=0 %then %do;
  %put ERROR: Derived library root "&_QCROOT_." is invalid: &_QCQC_.\_framework\qc_env.sas not found.;
  %abort cancel;
%end;

/* framework file */
%let _QCFW_=&_QCQC_.\_framework\qc_framework.sas;

/* results directory used by positive tests that need a persistent libname */
%let _QCRES_=&_QCQC_.\_results;

/* dev directories that hold the macros under test (mirror of dev layout) */
%let _QCDEV_VAR_=&_QCDEV_.\var;
%let _QCDEV_DS_=&_QCDEV_.\ds;
%let _QCDEV_DIR_=&_QCDEV_.\dir;
%let _QCDEV_LIB_=&_QCDEV_.\lib;
%let _QCDEV_FILE_=&_QCDEV_.\file;
%let _QCDEV_STAT_=&_QCDEV_.\stat;
%let _QCDEV_CDISC_=&_QCDEV_.\cdisc;
%let _QCDEV_REPORT_=&_QCDEV_.\report;
%let _QCDEV_LOG_=&_QCDEV_.\log;
%let _QCDEV_BE_=&_QCDEV_.\be;
%let _QCDEV_OPENSOURCE_=&_QCDEV_.\opensource;

/* sandbox: temporary container; each test program gets its own sub-directory
 * (created by %qc_sandbox_reset, removed by run_all.ps1 after the program) */
%let _QCSBTMP_=&_QCQC_.\_sandbox_tmp;
%let _QCSB_=&_QCSBTMP_.\_unset;
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