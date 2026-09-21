Info on running the code:

- The script Main_Script.m needs to be executed to run the bilevel optimization
	- At the start of the script one can switch between the water sources and optimization scenarios presented in the associated article
	- Outputs are illustrated in figures and prompted in command window

- The function NutrientOptimizationRAS.m represents the bot-level nutrient management and feed formulation optimization, which is called in Main_Script.m

- The function fish_diet_maximization_P.m calculates the highest possible dietary phosphorus content

- The script Parameters.m contains the model parameters