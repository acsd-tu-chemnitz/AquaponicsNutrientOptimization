%% Clear variables, close figures, import casadi

clear variables;
close all;
import casadi.*;

%% Get model parameters

Parameters

%% Symbolic initialzation of optimization Variables

u           = SX.sym('u',param.number_of_inputs,1);
x           = SX.sym('x',param.number_of_states,1);
e_NH4       = SX.sym('x',1,1);

u_model     = SX.sym('u_model',param.number_of_inputs,1);
x_model     = SX.sym('x_model',param.number_of_states,1);

%% Symbolic calculation of right hand side of state dynamics

xdot = Aquaponics_Model_SS( x_model, u_model, param);
dynamics=Function('dyn',{x_model,u_model}, {xdot});

%% Setting up the optimization problem

J = 0;

% Symbolic initialization of constraints
g_dyn = dynamics(x,u);
g_dyn = g_dyn([1:INDEX.x_c_FT.Chloride-1 INDEX.x_c_FT.Chloride+1:end]);

g_pH = x(INDEX.x_c_FT.Alkalinity)- x(INDEX.x_c_FT.Total_Carbon)*(param.K_1*x(INDEX.x_c_FT.Hydrogen)+2*param.K_1*param.K_2)/(x(INDEX.x_c_FT.Hydrogen)^2+param.K_1*x(INDEX.x_c_FT.Hydrogen)+param.K_1*param.K_2) - x(INDEX.x_c_FT.Phosphorus)*(param.K_5)/(x(INDEX.x_c_FT.Hydrogen)+param.K_5);
g_pH = [g_pH;x(INDEX.x_c_BF.Alkalinity)- x(INDEX.x_c_BF.Total_Carbon)*(param.K_1*x(INDEX.x_c_BF.Hydrogen)+2*param.K_1*param.K_2)/(x(INDEX.x_c_BF.Hydrogen)^2+param.K_1*x(INDEX.x_c_BF.Hydrogen)+param.K_1*param.K_2) - x(INDEX.x_c_FT.Phosphorus)*(param.K_5)/(x(INDEX.x_c_BF.Hydrogen)+param.K_5)];
g_pH = [g_pH;x(INDEX.x_c_BT.Alkalinity)- x(INDEX.x_c_FT.Total_Carbon)*(param.K_1*x(INDEX.x_c_BT.Hydrogen)+2*param.K_1*param.K_2)/(x(INDEX.x_c_BT.Hydrogen)^2+param.K_1*x(INDEX.x_c_BT.Hydrogen)+param.K_1*param.K_2) - x(INDEX.x_c_BT.Phosphorus)*(param.K_5)/(x(INDEX.x_c_BT.Hydrogen)+param.K_5)];

g_NH4 = x(INDEX.x_c_FT.Total_Ammonium) - e_NH4 - param.c_max_TAN; 

price_chemicals     = param.price_per_mole_base'*u(param.INDEX.u_Base.(param.base_identifiers(1)):param.INDEX.u_Base.(param.base_identifiers(end))) + param.price_per_mole_acid'*u(param.INDEX.u_Acid.(param.acid_identifiers(1)):param.INDEX.u_Acid.(param.acid_identifiers(end)));
carbon_chemicals    = param.carbon_per_mole_base'*u(param.INDEX.u_Base.(param.base_identifiers(1)):param.INDEX.u_Base.(param.base_identifiers(end))) + param.carbon_per_mole_acid'*u(param.INDEX.u_Acid.(param.acid_identifiers(1)):param.INDEX.u_Acid.(param.acid_identifiers(end)));
g_price             = price_chemicals + param.price_feed - param.whole_price * u(param.INDEX.u_in_FT_tap);
g_CO2               = carbon_chemicals + param.carbon_feed - param.whole_carbon * u(param.INDEX.u_in_FT_tap);

% Symbolic initialization of objective function
for k=1:param.number_of_nutrients
    if(strcmp(param.nutrient_identifiers(k),"Total_Ammonium")==1)
       %J = J + 100/(0.05)^2*(x(param.INDEX.x_c_FT.(param.nutrient_identifiers(k))))^2; %replaced by soft-constraint
    elseif(strcmp(param.nutrient_identifiers(k),"Nitrate")==1)
       J = J + param.w_c_N/(param.c_ref(k)^2)*(x(param.INDEX.x_c_BT.(param.nutrient_identifiers(k)))-param.c_ref(k))^2; 
    elseif(strcmp(param.nutrient_identifiers(k),"Alkalinity")~=1 && strcmp(param.nutrient_identifiers(k),"Total_Carbon")~=1 && strcmp(param.nutrient_identifiers(k),"Hydrogen")~=1 && strcmp(param.nutrient_identifiers(k),"Chloride")~=1 && strcmp(param.nutrient_identifiers(k),"Sodium")~=1)
       J = J + param.w_c/(param.c_ref(k)^2)*(x(param.INDEX.x_c_BT.(param.nutrient_identifiers(k)))-param.c_ref(k))^2; 
    elseif(strcmp(param.nutrient_identifiers(k),"Sodium")==1 || strcmp(param.nutrient_identifiers(k),"Chloride")==1)
        if param.c_ref(k) == 0 
            c_ref_weight = param.c_in_tap(k);
            J = J + param.w_c/(c_ref_weight^2)*(x(param.INDEX.x_c_BT.(param.nutrient_identifiers(k)))-c_ref_weight)^2; 
        else
            J = J + param.w_c/(param.c_ref(k)^2)*(x(param.INDEX.x_c_BT.(param.nutrient_identifiers(k)))-param.c_ref(k))^2; 
        end
    end
end

J   = J + param.w_TAN * (e_NH4)^2;
J1  = J;

J   = J +  param.w_pH * (x(INDEX.x_c_FT.Hydrogen)-param.c_H_fish_ref)^2;
J   = J +  param.w_pH * (x(INDEX.x_c_BT.Hydrogen)-param.c_H_BT_ref)^2;
J1  = J1 + param.w_eco/(param.whole_price)  * (param.price_feed + price_chemicals)/u(param.INDEX.u_in_FT_tap);
J1  = J1 + param.w_eco/(param.whole_carbon) * (param.carbon_feed + carbon_chemicals)/u(param.INDEX.u_in_FT_tap);

J1  = J1 + param.w_CO2/param.CO2_ref^2 * (x(INDEX.x_c_FT.Total_Carbon)/(1+param.K_1/x(INDEX.x_c_FT.Hydrogen) + param.K_1*param.K_2/x(INDEX.x_c_FT.Hydrogen)^2) - param.CO2_ref)^2;

g   = [g_dyn; g_pH; g_NH4; g_price; g_CO2];

y_opt       = [x; u; e_NH4];
nlp_coll    = struct('f',J,'x',y_opt,'g',g,'p',[]);
nlp_coll1   = struct('f',J1,'x',y_opt,'g',g,'p',[]);

%% Set up solver

opts=struct;
opts.ipopt.max_iter = 2000;
opts.print_time = 0;
opts.ipopt.print_level = 5;

solver_coll = nlpsol('solver','ipopt',nlp_coll,opts);
solver_coll1 = nlpsol('solver','ipopt',nlp_coll1,opts);

%% bounds of constraints and optimization variables

lbg = zeros(length(g),1);
ubg = zeros(length(g),1);

lbg(length(g_dyn)+length(g_pH)+1:end) = -inf;

lbx = 0*ones(length(y_opt),1);
ubx = inf*ones(length(y_opt),1);

lbx(param.number_of_states+param.INDEX.u_circ_BF)    = param.u_circ_BF_min;
lbx(param.number_of_states+param.INDEX.u_in_FT_tap)  = param.u_in_FT_tap_min;
ubx(param.number_of_states+param.INDEX.u_circ_BF)    = param.u_circ_BF_max;
ubx(param.number_of_states+param.INDEX.u_in_FT_tap)  = param.u_in_FT_tap_max;

lbx(INDEX.x_c_BT.Nitrate)       = param.lb_c_N_factor * param.c_ref(INDEX.x_c_FT.Nitrate);
lbx(INDEX.x_c_BT.Potassium)     = param.lb_c_factor * param.c_ref(INDEX.x_c_FT.Potassium);
lbx(INDEX.x_c_BT.Magnesium)     = param.lb_c_factor * param.c_ref(INDEX.x_c_FT.Magnesium);
lbx(INDEX.x_c_BT.Phosphorus)    = param.lb_c_factor * param.c_ref(INDEX.x_c_FT.Phosphorus);
lbx(INDEX.x_c_BT.Calcium)       = param.lb_c_factor * param.c_ref(INDEX.x_c_FT.Calcium);
lbx(INDEX.x_c_BT.Sodium)        = param.lb_c_factor * param.c_ref(INDEX.x_c_FT.Sodium);
lbx(INDEX.x_c_BT.Chloride)      = param.lb_c_factor * param.c_ref(INDEX.x_c_FT.Chloride);
lbx(INDEX.x_c_BT.Sulfate)       = param.lb_c_factor * param.c_ref(INDEX.x_c_FT.Sulfate);

ubx(INDEX.x_c_BT.Nitrate)       = param.ub_c_N_factor * param.c_ref(INDEX.x_c_FT.Nitrate);
ubx(INDEX.x_c_BT.Potassium)     = param.ub_c_factor * param.c_ref(INDEX.x_c_FT.Potassium);
ubx(INDEX.x_c_BT.Magnesium)     = param.ub_c_factor * param.c_ref(INDEX.x_c_FT.Magnesium);
ubx(INDEX.x_c_BT.Phosphorus)    = param.ub_c_factor * param.c_ref(INDEX.x_c_FT.Phosphorus);
ubx(INDEX.x_c_BT.Calcium)       = param.ub_c_factor * param.c_ref(INDEX.x_c_FT.Calcium);
ubx(INDEX.x_c_BT.Sodium)        = param.ub_c_factor * param.c_ref(INDEX.x_c_FT.Sodium);
ubx(INDEX.x_c_BT.Chloride)      = param.ub_c_factor * param.c_ref(INDEX.x_c_FT.Chloride);
ubx(INDEX.x_c_BT.Sulfate)       = param.ub_c_factor * param.c_ref(INDEX.x_c_FT.Sulfate);

%% 2-step solution of the optimization problem

% Define x0
u_opt                           = lbx(param.number_of_states+1:param.number_of_states+param.number_of_inputs);
u_opt(param.INDEX.u_circ_BF)    = ubx(param.number_of_states+param.INDEX.u_circ_BF);
x0_opt                          = [param.x0; u_opt; 1e-3];

% First step - find feasible pH
sol = solver_coll('x0', x0_opt, 'lbx', lbx, 'ubx', ubx, 'lbg', lbg, 'ubg', ubg);
x0 = full(sol.x);

% Set bounds for pH
lbx(INDEX.x_c_BF.Hydrogen) = param.c_H_BF_min;
lbx(INDEX.x_c_FT.Hydrogen) = param.c_H_FT_min;
lbx(INDEX.x_c_BT.Hydrogen) = param.c_H_BT_min;
ubx(INDEX.x_c_BF.Hydrogen) = param.c_H_BF_max;
ubx(INDEX.x_c_FT.Hydrogen) = param.c_H_FT_max;
ubx(INDEX.x_c_BT.Hydrogen) = param.c_H_BT_max;

% Second step - no pH tracking in objective function, but pH is bound through constraints now
sol1 = solver_coll1('x0', x0_opt, 'lbx', lbx, 'ubx', ubx, 'lbg', lbg, 'ubg', ubg);

% Solution of the optimization
u_opt_tank = full(sol1.x(param.number_of_states+1:param.number_of_states+param.number_of_inputs));
x_opt_tank = full(sol1.x(1:param.number_of_states));

%% Print solution

c_FT_ind_mass   = [INDEX.x_c_FT.Total_Ammonium INDEX.x_c_FT.Nitrate INDEX.x_c_FT.Potassium INDEX.x_c_FT.Magnesium INDEX.x_c_FT.Phosphorus INDEX.x_c_FT.Calcium INDEX.x_c_FT.Sulfate INDEX.x_c_FT.Sodium];
c_FT_ind_mol    = [INDEX.x_c_FT.Alkalinity INDEX.x_c_FT.Total_Carbon INDEX.x_c_FT.Phosphorus];
c_BF_ind1       = [INDEX.x_c_FT.Total_Ammonium INDEX.x_c_FT.Nitrate];
c_BF_ind        = [INDEX.x_c_BF.Total_Ammonium INDEX.x_c_BF.Nitrate INDEX.x_c_BF.Alkalinity];
c_BT_ind1       = [INDEX.x_c_FT.Total_Ammonium INDEX.x_c_FT.Nitrate INDEX.x_c_FT.Potassium INDEX.x_c_FT.Magnesium INDEX.x_c_FT.Phosphorus INDEX.x_c_FT.Calcium INDEX.x_c_FT.Sulfate INDEX.x_c_FT.Sodium INDEX.x_c_FT.Chloride];
c_BT_ind        = [INDEX.x_c_BT.Total_Ammonium INDEX.x_c_BT.Nitrate INDEX.x_c_BT.Potassium INDEX.x_c_BT.Magnesium INDEX.x_c_BT.Phosphorus INDEX.x_c_BT.Calcium INDEX.x_c_BT.Sulfate INDEX.x_c_BT.Sodium INDEX.x_c_BT.Chloride INDEX.x_c_BT.Alkalinity INDEX.x_c_BT.Total_Carbon];

c_FT_mass       = param.Molar_Mass_nutrients(c_FT_ind_mass) .* x_opt_tank(c_FT_ind_mass)    % [mg/L] = [g/m^3]
c_FT_mol        = x_opt_tank(c_FT_ind_mol)                                                  % [mmol/L] = [mol/m^3]

c_BF            = x_opt_tank(c_BF_ind)                                                      % [mmol/L] = [mol/m^3]

c_BT            = [param.Molar_Mass_nutrients(c_BT_ind1);1;1] .* x_opt_tank(c_BT_ind)       % [mg/L] = [g/m^3]

pH_FT           = -log10(x_opt_tank(INDEX.x_c_FT.Hydrogen)/1e+6)                            % [-]
pH_BF           = -log10(x_opt_tank(INDEX.x_c_BF.Hydrogen)/1e+6)                            % [-]
pH_BT           = -log10(x_opt_tank(INDEX.x_c_BT.Hydrogen)/1e+6)                            % [-]

V_in            = u_opt_tank(INDEX.u_in_FT_tap)                                             % [mol/day]
V_circ          = u_opt_tank(INDEX.u_circ_BF)                                               % [mol/day]
CaOH_2          = u_opt_tank(param.INDEX.u_Base.CaOH_2)                                     % [mol/day]
KOH             = u_opt_tank(param.INDEX.u_Base.KOH)                                        % [mol/day]
NaOH            = u_opt_tank(param.INDEX.u_Base.NaOH)                                       % [mol/day]
MgOH_2          = u_opt_tank(param.INDEX.u_Base.MgOH_2)                                     % [mol/day]
H3PO4           = u_opt_tank(param.INDEX.u_Acid.H3PO4)                                      % [mol/day]
HNO3            = u_opt_tank(param.INDEX.u_Acid.HNO3)                                       % [mol/day]
HCl             = u_opt_tank(param.INDEX.u_Acid.HCl)                                        % [mol/day]
H2SO4           = u_opt_tank(param.INDEX.u_Acid.H2SO4)                                      % [mol/day]

Price_chemicals     = (param.price_per_mole_base' * u_opt_tank(param.INDEX.u_Base.(param.base_identifiers(1)):param.INDEX.u_Base.(param.base_identifiers(end))) + param.price_per_mole_acid' * u_opt_tank(param.INDEX.u_Acid.(param.acid_identifiers(1)):param.INDEX.u_Acid.(param.acid_identifiers(end))) )/u_opt_tank(param.INDEX.u_in_FT_tap)
Price_feed          = param.price_feed/u_opt_tank(param.INDEX.u_in_FT_tap)
Carbon_chemicals    = (param.carbon_per_mole_base' * u_opt_tank(param.INDEX.u_Base.(param.base_identifiers(1)):param.INDEX.u_Base.(param.base_identifiers(end))) + param.carbon_per_mole_acid' * u_opt_tank(param.INDEX.u_Acid.(param.acid_identifiers(1)):param.INDEX.u_Acid.(param.acid_identifiers(end))) )/u_opt_tank(param.INDEX.u_in_FT_tap)
Carbon_feed         = param.carbon_feed/u_opt_tank(param.INDEX.u_in_FT_tap)
