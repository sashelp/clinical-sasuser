/*===============================================================================
 * sdtm_lobxfl_bug_compile.sas - Bug regression: baseline flag statement not generated
 *===============================================================================
 * Macro under test : %sdtm_lobxfl
 * Expected         : a normal call creates the flag variable and flags the
 *                    latest eligible record of each subject-by-test group
 * Status           : OPEN 2026-11-07 - one source defect still blocks every call
 *                    (the surplus %END reported earlier was removed at 21:40)
 * Original defect  : dev/cdisc/sdtm_lobxfl.sas lines 130-131 emit the flag
 *                    statement through
 *                    %str(if last.%scan(&by.,-1,%str( )) then &blfl.='Y';);
 *                    the blank delimiter inside %STR is lost while the text
 *                    is compiled, the generated statement becomes
 *                    "if last. then LOBXFL='Y';" and SAS reports
 *                    "ERROR: 宏函数 %SCAN 的参数过少" followed by ERROR 22-322.
 *                    The DATA step sdtm_lobxfl2 stops, so no record is flagged
 *                    and the output dataset keeps a blank BLFL for every row.
 * Fix              : derive the last BY variable (or the last SUBJECT variable
 *                    when BY= is blank) into a local macro variable and emit
 *                    the IF statement without nesting %SCAN inside %STR
 * Test passes when  the defect is fixed (run_all then reports FIXED).
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
%include "&_QCDEV_VAR_.\var_attr.sas";
%include "&_QCDEV_CDISC_.\sdtm_lobxfl.sas";

%qc_begin(prog=sdtm_lobxfl_bug_compile, macro=sdtm_lobxfl);

data dm_bug;
  length USUBJID $10 RFXSTDTC $20;
  USUBJID='S01'; RFXSTDTC='2024-01-10'; output;
run;
data lb_bug;
  length USUBJID $10 LBTESTCD $8 LBDTC $20 LBORRES $8;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-05'; LBORRES='10'; output;
  USUBJID='S01'; LBTESTCD='ALT'; LBDTC='2024-01-09'; LBORRES='20'; output;
run;

%qc_case(desc=1 baseline flag is created for a normal call);
%sdtm_lobxfl(data=work.lb_bug, out=work.lbbug_out, var=LBORRES, dtc=LBDTC,
              by=LBTESTCD, blfl=LOBXFL, subject=USUBJID,
              rfdtc=work.dm_bug.rfxstdtc);
%qc_expect_ds(ds=work.lbbug_out, desc=B1 output dataset created);
%qc_expect_var(ds=work.lbbug_out, var=LOBXFL, type=C, desc=B1 flag variable created);
%qc_expect_colval(ds=work.lbbug_out, var=LOBXFL, where=lbdtc='2024-01-09', expect=Y, desc=B1 latest eligible record flagged);

%qc_end;
