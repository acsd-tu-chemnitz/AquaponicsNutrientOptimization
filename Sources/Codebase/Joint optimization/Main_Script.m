close all
clear variables
import casadi.*;

%% Load parameters
Parameters

%% prohibit plotting during iterations
plot_solution = 0;

%% Load results of previous optimization

%If use_previous_results == true, program skips iteration and uses know y_opt_up
use_previous_results = true;
if(use_previous_results)
    results = load('Results/Case_2_0_Final.mat');
    y_opt_up = results.y_opt_up;
end

%% Choose Freshwater source and optimization scenario
param.freshwater_source               = 2; %Switch: 1 - hard tap water; 2 - soft tap water; 3 - condensation water
param.cost_optimization               = 0; %Switch: 0 - (opt. a); 1 - (opt. b)

%% Data for feed optimization

currentFolder = pwd;
cd('..\..\Database\')

%Get feed ingredient parameters from FICD file
Feed_Par                                        = readtable('FICD 2025-06-04.csv','VariableNamingRule','preserve');
Feed_Par.("Vitamin D (IU/kg)")                  = Feed_Par.("Vitamin D (IU/kg)").*0.025;
Additives                                       = 572:height(Feed_Par);
Non_additives                                   = 1:571;
Feed_Par.("Vitamin A (IU/kg)")(Additives)       = Feed_Par.("Vitamin A (IU/kg)")(Additives).*0.0003;
Feed_Par.("Vitamin A (IU/kg)")(Non_additives)   = Feed_Par.("Vitamin A (IU/kg)")(Non_additives).*0.0006;

%Get bounds for nutrients/antinutrients for ASNS file
constraint_bounds_feed                          = readtable('ASNS_Clarias200500_JointOpt.csv','NumHeaderLines',3,'VariableNamingRule','preserve');

Price_max   = constraint_bounds_feed.Value(find(strcmp(constraint_bounds_feed.Specification,'Price in USD/kg')));
Carbon_max  = constraint_bounds_feed.Value(find(strcmp(constraint_bounds_feed.Specification,'Global warming - Including LUC & Peat (kg CO2eq/t)')));
Na_max      = constraint_bounds_feed.Value(find(strcmp(constraint_bounds_feed.Specification,'Sodium')));
Na_max      = max(Na_max);
Cl_max      = constraint_bounds_feed.Value(find(strcmp(constraint_bounds_feed.Specification,'Chlorine')));
Cl_max = max(Cl_max);
Eco_bounds  = [Price_max; Carbon_max; Na_max; Cl_max];

cd(currentFolder)

%% Set upper and lower bounds and starting values of y_opt_up

P_feed_min = [];
P_feed_max = [];
for i=1:length(constraint_bounds_feed.Value)
        if((strcmp(constraint_bounds_feed.("Restriction Type")(i),'Ratio')==1 || strcmp(constraint_bounds_feed.("Restriction Type")(i),'ratio')==1) && ~isnan(constraint_bounds_feed.("Value")(i)))
            if strcmp(constraint_bounds_feed.("Unit")(i),"g/MJ")==1
                DP_DE_ratio=constraint_bounds_feed.("Value")(i);
            end
            if strcmp(constraint_bounds_feed.("Unit")(i),"g/kcal")==1
                DP_DE_ratio=constraint_bounds_feed.("Value")(i)*239.006;
            end
        end
        if strcmp(constraint_bounds_feed.("Specification")(i),'Phosphorus') == 1 && strcmp(constraint_bounds_feed.("Restriction Type")(i),'Minimum') == 1
            P_feed_min = constraint_bounds_feed.("Value")(i);
        end
        if strcmp(constraint_bounds_feed.("Specification")(i),'Phosphorus') == 1 && strcmp(constraint_bounds_feed.("Restriction Type")(i),'Maximum') == 1
            P_feed_max = constraint_bounds_feed.("Value")(i);
        end
end

%Lower bounds
q_min           = 0.06*(param.V_FT+param.V_BF);
c_H_min_fish    = 10^-1.5; %10^-6 mol/L -> pH = 7.5
c_H_min_plants  = 10^0;    %10^-6 mol/L -> pH = 6
CPGE_min        = 20;
q_circ_min      = 12*(param.V_BF+param.V_FT);
if isempty(P_feed_min)
    P_feed_min  = 0;
end
y_min_up        = [q_min,CPGE_min,c_H_min_fish,c_H_min_plants,q_circ_min,P_feed_min];

%Upper bounds
q_max           = 0.2*(param.V_FT+param.V_BF);
c_H_max_fish    = 10^-1;    %10^-6 mol/L -> pH = 7
c_H_max_plants  = 10^0.5; %10^-6 mol/L -> pH = 5.5
CPGE_max         = 23;
q_circ_max      = 96*(param.V_BF+param.V_FT);
if isempty(P_feed_max)
    %Get maximum P from P-Maximization problem
    P_feed_max  = fish_diet_maximization_P(Feed_Par,constraint_bounds_feed,param,CPGE_min/10,CPGE_max/10);
end
y_max_up        = [q_max,CPGE_max,c_H_max_fish,c_H_max_plants,q_circ_max,P_feed_max*0.9];

%Starting values
q_0             = 0.1*(param.V_FT+param.V_BF);
c_H_0_fish      = 10^-1 -1e-6;
c_H_0_plants    = 10^0 + 1e-6;
CPGE_0          = 2.15;
q_circ_0        = 48*(param.V_BF+param.V_FT);
P_feed_0        = P_feed_max/2 + P_feed_min/2;
y_0             = [q_0;CPGE_0;c_H_0_fish;c_H_0_plants;q_circ_0;P_feed_0];

%% Set up steady-state equations of nitrogen, alkalinity, TIC cycle in RAS

%Nitrate, Ammonium, TIC and alkalinity concentration in freshwater
if param.freshwater_source == 1
    c_in = param.c_in_tap_hard_N;
    c_in_add = param.c_in_tap_hard_RASopt_add;
end
if param.freshwater_source == 2
    c_in = param.c_in_tap_soft_N;
    c_in_add = param.c_in_tap_soft_RASopt_add;
end
if param.freshwater_source == 3
    c_in = param.c_in_cond_N;
    c_in_add = param.c_in_cond_RASopt_add;
end


%Symbolic initialzation of optimization Variables
x           = SX.sym('x',9,1); %1...c_NO3-N_FT 2...c_TAN_FT 3...c_TIC_FT 4...c_alk_FT 5...c_NO3-N_BF 6...c_TAN_BF 7...c_TIC_BF 8...c_alk_BF 9...c_H_BF
u           = SX.sym('u',2,1); %1...m_OH 2... k_La
par         = SX.sym('q',5,1); %1...q_in 2...CPGE_ratio %3...c_H_FT %4...q_circ %5... c_feed_PO4
J = 0;

%Calculate phosphorus excretion for given c_feed_PO4
m_feed_PO4 =  (0.2379*10*par(5)-1.3023)/30.974;
%Calculate resulting phosphorus cocentration in fish tank
c_PO4_FT_mmol = param.q_feed_stat*m_feed_PO4/par(1);

%Calculate ammonium excretion for given CPGE_ratio
feed_to_N = 8.1007 * par(2) - 143.85;

%Steady-state equations for nitrate NO3-N and ammonium TAN in FT and BF
g_nit =     [par(1)*(c_in(1)-x(1)) + par(4)*(x(5)-x(1)) ; par(1)*(c_in(2)-x(2)) + par(4)*(x(6)-x(2)) + param.q_feed_stat*feed_to_N; par(4)*(x(1)-x(5))+param.max_flux_ammonia*x(6)/(param.saturation_ammonia+x(6)); par(4)*(x(2)-x(6))-param.max_flux_ammonia*x(6)/(param.saturation_ammonia+x(6))];
%Steady-state equations for alkalinity in FT and BF
g_alk =     [par(1)*(c_in_add(1)-x(4)) + par(4)*(x(8)-x(4)) + param.q_feed_stat*(feed_to_N/14.0067 + m_feed_PO4* (param.K_5)/(param.c_H_fish_ex + param.K_5)) + u(1); par(4)*(x(4)-x(8)) - 2*param.max_flux_ammonia/14.0067*x(6)/(param.saturation_ammonia+x(6))];
%pH equality constraint in FT
g_hyd_FT =  [x(4) - (param.K_5)/(par(3) + param.K_5)*c_PO4_FT_mmol - (param.K_1*par(3) + 2*param.K_1*param.K_2)/(par(3)^2 + param.K_1*par(3) + param.K_1*param.K_2)*x(3)];
%pH equality constraint in BF
g_hyd_BF =  [x(8) - (param.K_5)/(x(9) + param.K_5)*c_PO4_FT_mmol - (param.K_1*x(9) + 2*param.K_1*param.K_2)/(x(9)^2 + param.K_1*x(9) + param.K_1*param.K_2)*x(7)];
%Steady-state equations for TIC in FT and BF
g_TIC =     [par(1)*(c_in_add(2)-x(3)) + par(4)*(x(7)-x(3)) + param.q_feed_stat*(480/44.009); par(4)*(x(3)-x(7)) - u(2)*(x(7)/(1+param.K_1/x(9)+param.K_1*param.K_2/x(9)^2)-param.CO2_eq)];

%Resulting vector of equality constraints
g_1 =       [g_nit;g_alk;g_hyd_FT;g_hyd_BF;g_TIC];

%Track reference CO2 concentration - Note: could also be implemented as equality constrained, since this is the only term in the objective 
%function and m_OH, k_La are unconstrained CO2,ref will always be achieved
J = J + 10000 * (x(3)/(1 + param.K_1/par(3) + param.K_1*param.K_2/par(3)^2)-13.5/44.009)^2;

%Vector of optimization variables
y_opt = [x;u];

%Bounds
y_max = inf*ones(11,1);
y_min = zeros(11,1);

%Struct of optimization problem
nlp_nit    = struct('f',J,'x',y_opt,'g',g_1,'p',par);

%Initialize optimizatio problem
solver_nit = nlpsol('solver','ipopt',nlp_nit);

%Bounds for equality constraints g(y) = 0
lbg_Nopt = zeros(10,1);
ubg_Nopt = zeros(10,1);


%% Set up and solve bilevel optimization problem

options = optimoptions('fmincon', ...
    'Algorithm','interior-point', ...
    'FiniteDifferenceType','central',...
    'Display','final-detailed','ObjectiveLimit',0); 

obj = @(y) NutrientOptimizationRAS_main(y,solver_nit,y_min,y_max,param,Feed_Par,constraint_bounds_feed,c_in_add,plot_solution,lbg_Nopt,ubg_Nopt,Eco_bounds);
problem = createOptimProblem('fmincon','objective',obj,'x0',y_0,'lb',y_min_up,'ub',y_max_up,'options',options);
gs = GlobalSearch('PlotFcn','gsplotbestf','StartPointsToRun','bounds','BasinRadiusFactor',0.9);
if(~use_previous_results)
    [y_opt_up,f] = run(gs,problem);
end
%% Illustrate results

%Switch plot_solution to show results in bar charts
plot_solution = 1;

%Solve steady-state equations of nitrogen, alkalinity, TIC cycle in RAS
N_sol = solver_nit('x0',[210 1 c_in_add(2) c_in_add(1) 210 0.8 c_in_add(2) c_in_add(1) 10^-0.9 5 200], 'lbx', y_min, 'ubx', y_max, 'lbg', lbg_Nopt, 'ubg', lbg_Nopt, 'p',y_opt_up([1:3 5:6]));

%Get degas coefficient
param.degas_coefficient = full(N_sol.x(11));

%Solve feed formulation + nutrient + pH management problem
[J,sol] = NutrientOptimizationRAS(full(N_sol.x),y_opt_up,param,Feed_Par,constraint_bounds_feed,plot_solution,Eco_bounds);

base_use            = sol(2*height(Feed_Par)+1:2*height(Feed_Par)+length(param.base_identifiers));
acid_use            = sol(2*height(Feed_Par)+1+length(param.base_identifiers):2*height(Feed_Par)+length(param.base_identifiers)+length(param.acid_identifiers));

Preis_pro_1000L     = ((base_use'*param.price_per_mole_base + acid_use' * param.price_per_mole_acid) + param.q_feed_stat *Feed_Par.("Price in USD/kg")'*sol(1:height(Feed_Par)))/y_opt_up(1)
Carbon              = (base_use'*param.carbon_per_mole_base + acid_use' * param.carbon_per_mole_acid + param.q_feed_stat * Feed_Par.("Global warming - Including LUC & Peat (kg CO2eq/t)")'*sol(1:height(Feed_Par)))/y_opt_up(1)

Price_chem          = (base_use'*param.price_per_mole_base + acid_use' * param.price_per_mole_acid)/y_opt_up(1)
Carbon_chem         = (base_use'*param.carbon_per_mole_base + acid_use' * param.carbon_per_mole_acid)/y_opt_up(1)
Price_feed          = param.q_feed_stat *Feed_Par.("Price in USD/kg")'*sol(1:height(Feed_Par))/y_opt_up(1)
Carbon_feed         = param.q_feed_stat * Feed_Par.("Global warming - Including LUC & Peat (kg CO2eq/t)")'*sol(1:height(Feed_Par))/y_opt_up(1)

Price_feed_kg       = Feed_Par.("Price in USD/kg")'*sol(1:height(Feed_Par))
Carbon_feed_kg      = Feed_Par.("Global warming - Including LUC & Peat (kg CO2eq/t)")'*sol(1:height(Feed_Par))

pH_FT               = -log10(y_opt_up(3)/10^6)
pH_BT               = -log10(y_opt_up(4)/10^6)
c_NO3_BT            = sol(end-10)
C_TAN_FT            = full(N_sol.x(2))

k_La                = full(N_sol.x(11))
V_circ              = y_opt_up(5)
V_in                = y_opt_up(1)
C_CO2_FT            = full(N_sol.x(3))*44.01/(1+param.K_1/y_opt_up(3) + param.K_1*param.K_2/y_opt_up(3)^2)

%% Briefly check implementation

CPGE_ratio          = (10 * Feed_Par.("Crude  Protein (%)")'*sol(1:height(Feed_Par)))/(Feed_Par.("Gross Energy -MJ (MJ/kg)")'*sol(1:height(Feed_Par)));
K_diet              = 10 * Feed_Par.("Potassium (%)")'*sol(1:height(Feed_Par));
P_diet              = 10 * Feed_Par.("Phosphorus (%)")'*sol(1:height(Feed_Par));
c_PO_ref            = 10 * y_opt_up(end);
Mg_diet             = 10 * Feed_Par.("Magnesium (%)")'*sol(1:height(Feed_Par));

if param.freshwater_source == 1
    c_in = param.c_in_tap_hard_RASopt;
elseif param.freshwater_source == 2
    c_in = param.c_in_tap_soft_RASopt;
else
    c_in = param.c_in_cond_RASopt;
end

K_BT                = ((1.3116 * K_diet - 5.4117) * param.q_feed_stat + sol(2*height(Feed_Par)+2)*39.0983)/y_opt_up(1)+c_in(1)
P_BT                = ((0.2379 * P_diet - 1.3023) * param.q_feed_stat + sol(2*height(Feed_Par)+5)*30.974)/y_opt_up(1) + c_in(3)

m_OH                = full(N_sol.x(10))
m_OH_gur            = 2 * sol(2*height(Feed_Par)+1) + sol(2*height(Feed_Par)+2) + sol(2*height(Feed_Par)+3) + 2 * sol(2*height(Feed_Par)+4)

%% Function call for top-level optimization with fmincon()

function J = NutrientOptimizationRAS_main(y,solver_nit,y_min,y_max,param,Feed_Par,constraint_bounds_feed,c_in_add,plot_solution,lbg_Nopt,ubg_Nopt,Eco_bounds)
    %Solve steady-state equations of nitrogen, alkalinity, TIC cycle in RAS
    sol = solver_nit('x0',[210 1 c_in_add(2) c_in_add(1) 210 0.8 c_in_add(2) c_in_add(1) 10^-0.9 5 200], 'lbx', y_min, 'ubx', y_max, 'lbg', lbg_Nopt, 'ubg', ubg_Nopt, 'p',y([1:3 5:6]));
    y1 = full(sol.x);
    
    %Get degas coefficient
    param.degas_coefficient = y1(11,1);

    c_TAN_FT = full(sol.x(2));
    
    %Solve feed formulation + nutrient + pH management problem
    [J,~] = NutrientOptimizationRAS(y1,y,param,Feed_Par,constraint_bounds_feed,plot_solution,Eco_bounds);
    
    %Penalize c_TAN_FT(y_opt_up) >= 1mg/L
    if (c_TAN_FT >= 1)
        J = J + 10000 * (c_TAN_FT-1)^2; 
    end
end
