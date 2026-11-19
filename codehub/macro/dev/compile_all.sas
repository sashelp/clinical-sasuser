/*Get path of current file*/
data _null_;
  mode=symget('sysprocessmode');
  if find(mode,'DMS') then file=sysget('sas_execfilepath');
  else if find(mode,'Server') then file=dequote(symget('_sasprogramfile'));
  call symputx('_thispath_',substr(file,1,findc(file,'/\','b')-1));
run;
%put %superq(_thispath_);


/*Complie all .sas file in the first sub directory*/
%inc "%superq(_thispath_)\dir\dir_exist.sas";
%inc "%superq(_thispath_)\dir\dir_memlist.sas";
%dir_memlist(dir=%superq(_thispath_),out=filelist,ext=sas,maxdepth=2);

option mcompilenote=noautocall;
data _null_;
  set filelist;
  where depth=2;
  call execute('%include "'||trim(path)||'";');
run;


/*Copy compiled SAS catalog file to &_thispath_.*/
libname machub "&_thispath_.";
proc copy in=work out=machub memtype=catalog;
  select sasmacr;
run;
