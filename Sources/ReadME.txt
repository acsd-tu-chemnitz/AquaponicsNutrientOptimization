Code and Database for "Optimization of fish feed formulation and pH regulation in on-demand coupled aquaponic systems: A model-based framework for sustainable nutrient and water management"

This repository contains the external datasets as well as the codebase for the optimization of nutrient concentrations in aquaponic systems.

The database contains the following data:
	- The ASNS and FICD file from the IAFFD used for the optimization of dietary nutrients in fish feed*
	- Data on the prices of fish feed ingredients
	- Data on the prices and carbon footprints of chemicals
	- A detailed version of the production plan for batch rearing of fish

The codebase contains the following software:
	- The disjoint optimization framework, which contains:
		- Feed formulation optimization problem 
		- Optimal nutrient management for a fixed feed
		- Evaluation of the nutrient contents of commercial feed, e.g., the PAFF feed from the IAFFD website
		- The validation of the steady-state approximation	
	- The joint optimization framework

The optimizations were implemented using the following software:
	- disjoint optimization:
		- Matlab 2024a
		- CasADi v3.6.6
	- joint optimization:
		- Matlab 2024a
		- CasADi v3.6.6
		- Gurobi v11.0.3

*Note: The authors do not take credit for the ASNS and FICD files as original research data. Both files were downloaded from the website of the International Aquaculture Feed Formulation Database (IAFFD) and serve as basis for calculating the feed formulations in this study. 
Reference: IAFFD (2025). International Aquaculture Feed Formulation Database (IAFFD). https://www.iaffd.com/index.html. Accessed: 2025-06-04.		


	 