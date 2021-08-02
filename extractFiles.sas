/******************************************************************************\
 * $Id$
 *
 * Name: extractFiles.sas
 *
 * Purpose: Idenitfy files to extract and merge into final SAS data set
 *
 * Author: Amir Lyall
 *
 * Input: &_INCOMINGR_PATH./Pull_Part*..txt
 *
 * Output: extract.textPulls
 *
 * Parameters: filepath, input filenames, output filename
 *
 * Dependencies/Assumptions: Files exist in infile area
 *
 * Usage: This program will loop through a list of text files, and parse out relevant variables
 *
\******************************************************************************/
/* Set standard varname option */
options validvarname=v7;

/* Set DQ locale */
%dqload(dqlocale=(enusa));

/* Loops through data pulls and imports as SAS datasets */
%let i=1;
%put &i;

%macro importFiles;
	%put &i;

	%do %until (&i=<number of files>);

		data work.textPull&i.;
		/* Set variable lengths */
			length variable $200;
		/* Set variable informats */
			informat datetime anydtdtm40.;
		/* Set variable formats */
			format datetime datetime.;
		/* Set textfile path, first observation on 2nd row, pipe-delimited */
			infile "&_INCOMINGR_PATH./Pull_Part&i..txt" firstobs=2 dsd dlm="|";
		/* Input variable names */
			input var1 var var3;
			FILE="textpull&i.";

		/* Correct a non-standard value in a specific file */
			%if &i.=1 %then
				%do;
					if var="12345" then var="123";
				%end;
		/* Fix missing "-" sign on values in raw data */
			if substr(var, 1, 1) ne "-" then		
				var_minus="-"||var_tmp;
			else
				var_minus=var_tmp;
			drop var_tmp;
		run;

	/* Convert selected character columns to numeric */
		data work.textPull&i.;
			set work.textPull&i.;
			var=input(var_tmp, ??32.);
			drop var_tmp;
		run;

		%let i=%eval(&i+1);
	%end;
	%put &i;
%mend importFiles;

%importFiles;

/* Get files to merge */
proc sql noprint;
	select compress(strip(libname||"."||memname)) into :textPulls separated by 
		" " from sashelp.vtable where upcase(strip(libname))="WORK" and 
		upcase(strip(memname)) contains "TEXTPULL" and nobs ne 0;
quit;

/* Output list of files to be merged */
%put &textPulls;

/* Merge files to create a master dataset */
data &extract..textPulls;
	set &textPulls;
run;