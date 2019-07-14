This folder is devoted to v-dukut's internship project Automated SQL instance configuration optimization in Cloud Lifter Perf team.

You'll find different classes that imitates benchmark infrastructure. It's purpose is to compare different
configuration that is running on same benchmark configuration. 

If u want to reuse it you need to change:   
1. Configuration/benchmark_configs.json file (info here is for all of your runs)
2. Configuration/instances.json file (list your instances here + take care that you are using instances stored in Benchmark DB)
3. Configuration/config_parameters_constraints.json (correspond to CAS action Set-ManagedServerConfigurationParameters + take care that for
	parameters that need to be equals for one run, you set proper equals value in json file)
4. Configuration/property_parameters_constraints.json (correspond to CAS action Set-ManagedServerPropertyOverride + take care that for
	parameters that need to be equals for one run, you set proper equals value in json file + set correct type for each override (“Instance”, “Database” or “SloRgMapping”)+
	change Property_Overrides class if you set anything but overrides for primary for slo property bag overrides)
5. In random_scheduler script change targeted Kusto cluster
6. If you are changing 3. or 4, you need to change Result class for your own purposes
7. random_scheduler.py script schedule and gets results for your runs. You might want to change number of your runs stored in
LIMIT_BENCHMARK_RUNS variables
8. Change loss function as you wish
9. Rename existing Plots, Results, Log folders to old versions 


Steps:
1. execute random_scheduler.py script. You may find your Plots, Results and Logs.
	You are interested in the most recent plot and result file
2. execute fit.py with any result file as you wish as cmd parameter. Example: python fit.py success0619160648.csv,
	it will update your data with additional columns that represents weights for approximation for loss function
	and it will be exported to *name_of_your_file* + 'weighted'
3. execute python optimize.py  *name_of_your_file* + 'weighted', to find regions where function approximation has its minima,
	this script tells you about good points for your parameters
4. if you want to plot your resultse execute python plot_results_from_csv.csv *name of your file*