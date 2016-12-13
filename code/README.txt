To run the Citi Bike network simulator in MATLAB, first download Citi Bike trip data from
https://www.citibikenyc.com/system-data in .csv format.

1. Run simulation.m
2. Follow the pop-up windows to provide trip data for the initialization procedure, bike stations maximum 
capacity information (Bike Stations.csv), trip data of the month under interest (should be the month after the 
month used in the initialization procedure), and secify simulation time interval
3. Wait for the simulator to run (This might take 4 - 5 hours)
4. The results are generated in two seperate folders under your current work directory for a simulation run with
the incentives scheme and another without it
5. Use image2animation.m to convert the .png files you just generated to create awesome animations
6. To change the probability model used along with the incentives scheme, modify the section of code after line 
357 in simulator.m
***********************************************************************************************************************************
Known Bug
- If the .png files generated in simulator.m only have two dots, it is because there are a few stations in the
network have faulty longitude and latitude information. If this happens, stop the current run, open
new_network_data in your workspace and look for bike stations whose longitude and latitude are 0.0 (usually
around row 470). Modify line 386 in simulator.m to exclude these stations in the scatter plot function and 
everything should run soomthly.An example is shown on line 387. Once this issue is fixed, you can call the 
simulator function (see the last two lines in simulation.m) and continue the simulation.