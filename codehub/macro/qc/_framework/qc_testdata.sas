/*==============================================================================
 * qc_testdata.sas - Shared test-data builders
 *==============================================================================
 * Provides small dataset builders used by several test programs.
 *============================================================================*/

/* builder: standard mixed dataset with formats */
%macro qc_data_mixed(ds=);
  data &ds.;
    length char1 $20;
    char1='abc';
    num1=1;
    num2=2.5;
    dt=mdy(1,15,2024);
    format dt date9.;
    big=1234567890.12;
    format big comma14.2;
    pct=0.123;
    format pct percent8.2;
  run;
%mend qc_data_mixed;

/* builder: dataset with only character variables */
%macro qc_data_allchar(ds=);
  data &ds.;
    length c1 $10 c2 $20 c3 $5;
    c1='x'; c2='yy'; c3='zzz';
  run;
%mend qc_data_allchar;

/* builder: dataset with only numeric variables */
%macro qc_data_allnum(ds=);
  data &ds.;
    n1=1; n2=2; n3=3.14;
  run;
%mend qc_data_allnum;

/* builder: wide dataset with N vars v1..vN */
%macro qc_data_wide(ds=,n=);
  data &ds.;
    %do i=1 %to &n.;
      v&i.=&i.;
    %end;
  run;
%mend qc_data_wide;