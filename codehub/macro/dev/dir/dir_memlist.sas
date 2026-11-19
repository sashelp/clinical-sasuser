/*
*Brief      : Get variable list of specified dataset
*Param(Req) : (DIR=)          Full directory
*Param(Opt) : (MAXDEPTH=1)    Maximum directory level
*Param(Opt) : (MEMINFO=N)     Require member info or not, following values are vaild:
              Y   : Require member info, including directory info(Linux only) and file
                    info(both Windows and Linux)
              N   : Doesn't require member info
*Param(Opt) : (OUT=_DATA_)    Output dataset
*Param(Opt) : (EXT=)          File extension to filter final result
*Detail     : SAS enviroment variables are supported to used in DIR= option
*NOTE       : OS enviroment variables are NOT supported to be used in DIR= option
*NOTE       : Only Windows and Linux OS are supported
*NOTE       : There is no need to enclose directory in quotation marks. Macro will 
              remove outer matching quotation marks even if you specified a pair
*NOTE       : Using SAS 9.4M7 unicode session, under Windows OS, finfo() and foptname()
              functions may fail at getting file info, which is a known bug of SAS.
*Usage      : See inner website
*Dependency : %dir_exist
*Version    : SAS 9.4M7
*History    : 2025-12-30, Luo Hao, Original version
*History    : 2026-11-02, Luo Hao, Add parameter compatibility: Allow passing a quoted value for dir= at runtime
*/
%macro dir_memlist(dir=,out=_data_,ext=,maxdepth=1,meminfo=N)/minoperator;
%local errtext sep depth _memexist_;

/*1. Exception capture and handling*/
%if %dir_exist(dir=&dir.)=0 %then %let errtext=ERROR: Directory %quote(&DIR.) not exist.;
%else %if %quote(&maxdepth.)=%str() %then %let errtext=ERROR: Parameter MAXDEPTH= not specified.;
%else %if %quote(&meminfo.)=%str() %then %let errtext=ERROR: Parameter MEMINFO= not specified.;
%else %if %index(&sysscp.,WIN)=0 and %index(&sysscp.,LIN)=0 %then %let errtext=ERROR: Macro &sysmacroname. called by unsupported operation system.;
%else %if (%qupcase(&meminfo.) in N Y)=0 %then %let errtext=ERROR: Parameter MEMINFO= has invalid value, expecting one of: N, Y.;
%else %if &maxdepth.=0 or %sysfunc(notdigit(&maxdepth.))>0 %then %let errtext=ERROR: Parameter MAXDEPTH= has invalid value, expecting positive integer.;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%if %index(&sysscp.,WIN) %then %let sep=\;
%else %if %index(&sysscp.,LIN) %then %let sep=/;

data _dir_memlist_main;
  attrib path   length=$1024 label='Path';
  attrib depth  length=8     label='Depth';
  attrib name   length=$255  label='Name';
  attrib ext    length=$255  label='Extension';
  attrib type   length=$9    label='Type';
  %if %upcase(&meminfo.)=Y %then %do;
    attrib filesize  length=8   label='File Size(Byte)';
    attrib modtm     length=8   label='Modified Time' format=e8601dt.;
    %if &sep.=%str(\) %then %do;
      attrib recfm       length=$8  label='RECFM';
      attrib lrecl       length=8   label='LRECL';
      attrib crdtm       length=8   label='Created Time' format=e8601dt.;
    %end;
    %else %if &sep.=%str(/) %then %do;
      attrib owner       length=$32  label='Owner';
      attrib groupname   length=$8   label='Group Name';
      attrib permission  length=$32  label='Permission';
    %end;
  %end;
  call missing(of _all_);
	path=%sysfunc(quote(%qsysfunc(dequote(&dir.)),%str(%')));
  depth=0;
  type='Directory';
run;

%let depth=0;
%do %until(&_memexist_.=0 or &depth.>&maxdepth.-1);
	%let depth=%eval(&depth.+1);

	data _dir_memlist_branch;
		set _dir_memlist_main(where=(depth=&depth.-1)) end=_eof_;

		_fref_=filename('_dummy_',path);
		_did_=dopen('_dummy_');
		if _did_^=0 then do;
      %*Get directory info(Linux only);
      %if %upcase(&meminfo.)=Y and &sep.=%str(/) %then %do; %*See %dir_attr for the 2nd argument of doptname();
        owner       =dinfo(_did_,doptname(_did_,2));
        groupname   =dinfo(_did_,doptname(_did_,3));
        permission  =dinfo(_did_,doptname(_did_,4));
      %end;
      %*Done;

  		depth=&depth.;
  		_dir_=path;
      _memexist_+1;
  		do _n_=1 to dnum(_did_);
        name=dread(_did_,_n_);
  			path=trim(_dir_)||"&sep."||name;

        %*Get file info;
        _fref2_=filename('_dummy2_',path);
        _fid_=fopen('_dummy2_');
        if _fid_^=0 then do;
          type='File';
          if find(name,'.','t') then ext=upcase(scan(name,-1,'.'));
          %if %upcase(&meminfo.)=Y and &sep.=%str(\) %then %do; %*Windows, See %file_attr for the 2nd argument of foptname();
            if symget('ext')='' or upcase(symget('ext'))=ext then do;
              recfm     =finfo(_fid_,foptname(_fid_,2));
              lrecl     =input(finfo(_fid_,foptname(_fid_,3)),best32.);
              filesize  =input(finfo(_fid_,foptname(_fid_,4)),best32.);
              modtm     =input(finfo(_fid_,foptname(_fid_,5)),nldatm200.);
              crdtm     =input(finfo(_fid_,foptname(_fid_,6)),nldatm200.);
            end;
          %end;
          %else %if %upcase(&meminfo.)=Y and &sep.=%str(/) %then %do; %*Linux, See %file_attr for the 2nd argument of foptname();
            if symget('ext')='' or upcase(symget('ext'))=ext then do;
              filesize    =input(finfo(_fid_,foptname(_fid_,2)),best32.);
              modtm       =input(finfo(_fid_,foptname(_fid_,3)),nldatm200.);
              owner       =finfo(_fid_,foptname(_fid_,4));
              groupname   =finfo(_fid_,foptname(_fid_,5));
              permission  =finfo(_fid_,foptname(_fid_,6));
            end;
          %end;
          _fid_=fclose(_fid_);
        end;
        else type='Directory';

				output;
        ext='';
        %if %upcase(&meminfo.)=Y and &sep.=%str(\) %then %str(call missing(of filesize--crdtm););
        %else %if %upcase(&meminfo.)=Y and &sep.=%str(/) %then %str(call missing(of filesize--permission););
			end;
			_did_=dclose(_did_);
		end;
		if _eof_ then call symputx('_memexist_',(_memexist_>0));
	run;

	proc append data=_dir_memlist_branch(drop=_:) base=_dir_memlist_main;
	run;
%end;

data &out.;
  set _dir_memlist_main;
  %if %quote(&ext.)^=%str() %then %str(where ext=%tslit(%upcase(&ext.)););
run;

/*3. Exit and clean workspace*/
proc delete data=_dir_memlist_main _dir_memlist_branch;
run;
%mend;
