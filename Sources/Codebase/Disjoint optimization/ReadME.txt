Info on running the code:

- The script FeedFormulation_Optimization.m calculates the optimal feed formulations
	- Outputs are illustrated in figures and prompted in the command window
	- Note that in the IAFFD database, the FICD headers are not always consistent with the specifications in the ASNS table, which may produce an error and necessitate manual adjustment of the FICD headers.

- The script Nutrient_pH_Optimization.m runs the optimal nutrient and pH management for a fixed feed formulation, the respective formulations can be adjusted in the parameter-script Parameters.m
	- Outputs are prompted in the command window

- The function Aquaponics_Model_SS.m contains the model equations