/*===============================================================================
 * ds_zipvarlen_test.sas - Positive (functional) acceptance tests
 *===============================================================================
 * Macro under test : %ds_zipvarlen
 * File under test   : dev/ds/ds_zipvarlen.sas
 * Dependency        : %ds_attr, %ds_varlist
 * Coverage          : shrink char length to max used value, default format /
 *                     informat replacement with $n., DELFMT=N / DELINFMT=N keep
 *                     original attributes, numeric vars untouched, 0-observation
 *                     dataset becomes char(1), dataset without char vars is a
 *                     no-op.
 * Note              : the macro MODIFIES the input dataset irreversibly, so
 *                     every case builds its own throw-away dataset.
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
%include "&_QCDEV_DS_.\ds_attr.sas";
%include "&_QCDEV_DS_.\ds_varlist.sas";
%include "&_QCDEV_DS_.\ds_zipvarlen.sas";

%qc_begin(prog=ds_zipvarlen_test, macro=ds_zipvarlen);

/*----------------------------------------------------------------------------
 * CASE 1 : shrink lengths to the maximum value actually used
 *--------------------------------------------------------------------------*/
%qc_case(desc=1 shrink char length to max used);
data zv1;
  length c1 $20 c2 $50;
  c1='abc'; c2='hello';
  n1=1;
run;
%ds_zipvarlen(data=zv1);
%qc_expect_len(ds=zv1, var=c1, expect=3, desc=C1 c1 shrunk to 3);
%qc_expect_len(ds=zv1, var=c2, expect=5, desc=C1 c2 shrunk to 5);
%qc_expect_len(ds=zv1, var=n1, expect=8, desc=C1 numeric var untouched);
%qc_expect_nobs(ds=zv1, expect=1, desc=C1 observation preserved);

/*----------------------------------------------------------------------------
 * CASE 2 : default DELFMT=Y replaces format with $n.
 *--------------------------------------------------------------------------*/
%qc_case(desc=2 default DELFMT replaces format);
data zv2;
  length c1 $20;
  c1='abc';
  format c1 $20.;
run;
%ds_zipvarlen(data=zv2);
%qc_expect_len(ds=zv2, var=c1, expect=3, desc=C2 c1 shrunk to 3);
%qc_expect_fmt(ds=zv2, var=c1, expect=$3., desc=C2 format replaced by $3.);

/*----------------------------------------------------------------------------
 * CASE 3 : DELFMT=N keeps the original format
 *--------------------------------------------------------------------------*/
%qc_case(desc=3 DELFMT=N keeps format);
data zv3;
  length c1 $20;
  c1='abc';
  format c1 $20.;
run;
%ds_zipvarlen(data=zv3,delfmt=n,delinfmt=n);
%qc_expect_len(ds=zv3, var=c1, expect=3, desc=C3 c1 shrunk to 3);
%qc_expect_fmt(ds=zv3, var=c1, expect=$20., desc=C3 original format kept);

/*----------------------------------------------------------------------------
 * CASE 4 : multi-observation dataset uses the longest value
 *--------------------------------------------------------------------------*/
%qc_case(desc=4 max length across observations);
data zv4;
  length c1 $40;
  c1='a'; output;
  c1='abcdefghij'; output;
run;
%ds_zipvarlen(data=zv4);
%qc_expect_len(ds=zv4, var=c1, expect=10, desc=C4 c1 shrunk to longest 10);
%qc_expect_nobs(ds=zv4, expect=2, desc=C4 both observations kept);

/*----------------------------------------------------------------------------
 * CASE 5 : 0-observation dataset -> every char var becomes char(1)
 *--------------------------------------------------------------------------*/
%qc_case(desc=5 zero observation dataset);
data zv5;
  length c1 $20 c2 $30;
  if 0;
  c1='x'; c2='y';
run;
%ds_zipvarlen(data=zv5);
%qc_expect_len(ds=zv5, var=c1, expect=1, desc=C5 c1 becomes char 1);
%qc_expect_len(ds=zv5, var=c2, expect=1, desc=C5 c2 becomes char 1);
%qc_expect_nobs(ds=zv5, expect=0, desc=C5 still 0 observations);

/*----------------------------------------------------------------------------
 * CASE 6 : dataset without char variables is a no-op
 *--------------------------------------------------------------------------*/
%qc_case(desc=6 dataset without char variables);
data zv6;
  n1=1; n2=2;
run;
%ds_zipvarlen(data=zv6);
%qc_check_eq(actual=%ds_attr(data=zv6,attr=nvars), expect=2, desc=C6 nvars unchanged);
%qc_check_eq(actual=%ds_attr(data=zv6,attr=nobs), expect=1, desc=C6 nobs unchanged);
%qc_expect_len(ds=zv6, var=n1, expect=8, desc=C6 numeric untouched);

/*----------------------------------------------------------------------------
 * CASE 7 : already optimal length is left as is
 *--------------------------------------------------------------------------*/
%qc_case(desc=7 already optimal length);
data zv7;
  length c1 $3;
  c1='abc';
run;
%ds_zipvarlen(data=zv7);
%qc_expect_len(ds=zv7, var=c1, expect=3, desc=C7 length stays 3);

%qc_end;