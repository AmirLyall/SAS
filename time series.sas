title;
/* Input training csv files as SAS datasets */
data august_train_clean;
	infile 'C:\august_train_clean.csv'
		dlm="," DSD missover firstobs=2;
	input Date :yymmdd10. Time :3. Temperature :3. Obs :2.;
	format Date mmddyy10.;
run;
/* Input training csv files as SAS datasets */
data september_valid_clean;
	infile 'C:\september_valid_clean.csv'
		dlm="," DSD missover firstobs=2;
	input Date :yymmdd10. Time :3. Temperature :3.;
	format Date mmddyy10.;
run;
/* Checking cleanliness of data - there are 24 observations per day */
proc freq data=august_train_clean;
	tables date;
run;
/* Checking for stationarity and automatic model selection for a baseline */
proc arima data=august_train_clean plot=all;
	*identify var=Temperature nlag=72 stationarity=(adf=6 dlag=12);
	*identify var=Temperature(24) nlag=72 stationarity=(adf=6);
	identify var=Temperature(24) nlag=72 minic scan esacf P=(0:24) Q=(0:24);
	estimate p=1 q=(1 24) method=ML;
run;
quit;
/* Removing a deterministic difference and forecasting 1 day */
ODS output ResidualWNPlot=work.august_train_wn_determ;
proc arima data=august_train_clean plot=series(corr);
	identify var=Temperature nlag=72 stationarity=(adf=6 dlag=12) crosscorr=obs;
	estimate input=obs p=1 q=(1 24) method=ML;
	forecast lead=24 out=tempforecast_determ;
run;
quit; 
/* Removing stochastic difference of 24 for season and forecasting 1 day */
ODS output ResidualWNPlot=work.august_train_wn;
proc arima data=august_train_clean plot(unpack)=all;
	identify var=Temperature(24) stationarity=(adf=6);
	estimate p=1 q=(1 24) method=ml;
	forecast lead=24 out=tempforecast;
run;
quit;
/* Removing training observations so that only forecasted values remain */
data forecast (keep=forecast);
	set tempforecast;
	if _n_ <= 744 then delete;
run;
/* Calculating MAPE and MAE */
data temp_MAPE;
merge forecast september_valid_clean (rename=(temperature=actual)); 
	AE = abs(actual - forecast);
	APE = (abs(actual - forecast) / actual)*100;
run;
proc means data=temp_MAPE mean;
	var AE APE;
run;
title;
