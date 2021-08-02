/******************************************************************************\
 * $Id$
 *
 * Name: stageFiles.sas
 *
 * Purpose: Apply data cleansing and transformations
 *
 * Author: Amir Lyall
 *
 * Input: &_EXTRACT_PATH./textPulls.sas
 *
 * Output: stage.textPulls
 *
 * Parameters: filepath, input filenames, output filename
 *
 * Dependencies/Assumptions: Files exist in extract area
 *
 * Usage: This program will apply regular expressions, create new features, and aggregate data for reporting/modeling
 *
\******************************************************************************/
/* Set standard varname option */
options validvarname=v7;

/* Set DQ locale */
%dqload(dqlocale=(enusa));

/* Obtain final dataset for analysis */
data work.stageRegex;
	set &extract..textPulls (where=(/*Subset records based on desired criteria */
	strip(upcase(var1))="VALUE" and not 
	  /* Remove values of A, B, C, "?" and "*" using regular expressions
		prxmatch("/A|B|C|\?|\*/", strip(upcase(var1))) and
		/*  IDs for var of interest */
		upcase(strip(var1name)) in ('NAME1', 'NAME2', 'NAME3')));
	dataSource="Datasource1";

	/* If var1= ‘X’ then perform these changes */
	if prxmatch("/X/", strip(upcase(var1))) then
		var1value=value2;
			else
				do;
					putlog "Error: value does not match replacement criteria.";
				end;
		end;

/* Create date variables of interest */
	month=month(datepart(start_date));
	week=week(datepart(start_date));
	quarter=qtr(datepart(start_date));
	year=year(datepart(start_date));
	date=datepart(start_date);
	weekday=weekday(datepart(start_date));
	format date date9. month mn_name. weekday wkd.;
run;

/* Example of an include macro */
%add_additional_vars_for_reports(stageRegex, outputDataName);

/* Get list of column names from table using SQL syntax */
proc sql;
	select name into :sorted_cols separated by ' ' from dictionary.columns where 
		compress(upcase(libname))='WORK' and 
		compress(upcase(memname))='outputDataName' order by upcase(name);
quit;

/* Sort by column names alphabetically */
data &stage..stagedPulls;
	retain &sorted_cols;
	set work.outputDataName;
run;