%% Clear variables, close figures, import casadi

clear variables;
close all;
import casadi.*;

check_MPC = 1;
%% Get model parameters

Parameters

%% Symbolic initialzation of optimization Variables

u           = SX.sym('u',param.number_of_inputs,1);
x           = SX.sym('x',param.number_of_states,1);

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

price_chemicals     = param.price_per_mole_base'*u(param.INDEX.u_Base.(param.base_identifiers(1)):param.INDEX.u_Base.(param.base_identifiers(end))) + param.price_per_mole_acid'*u(param.INDEX.u_Acid.(param.acid_identifiers(1)):param.INDEX.u_Acid.(param.acid_identifiers(end)));
carbon_chemicals    = param.carbon_per_mole_base'*u(param.INDEX.u_Base.(param.base_identifiers(1)):param.INDEX.u_Base.(param.base_identifiers(end))) + param.carbon_per_mole_acid'*u(param.INDEX.u_Acid.(param.acid_identifiers(1)):param.INDEX.u_Acid.(param.acid_identifiers(end)));
g_price             = price_chemicals + param.price_feed - param.whole_price * u(param.INDEX.u_in_FT_tap);
g_CO2               = carbon_chemicals + param.carbon_feed - param.whole_carbon * u(param.INDEX.u_in_FT_tap);

% Symbolic initialization of objective function
for k=1:param.number_of_nutrients
    if(strcmp(param.nutrient_identifiers(k),"Total_Ammonium")==1)
       J = J + param.w_TAN*(x(param.INDEX.x_c_FT.(param.nutrient_identifiers(k))))^2;
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

J1  = J;

J   = J +  param.w_pH * (x(INDEX.x_c_FT.Hydrogen)-param.c_H_fish_ref)^2;
J   = J +  param.w_pH * (x(INDEX.x_c_BT.Hydrogen)-param.c_H_BT_ref)^2;
J1  = J1 + param.w_eco/(param.whole_price)  * (param.price_feed + price_chemicals)/u(param.INDEX.u_in_FT_tap);
J1  = J1 + param.w_eco/(param.whole_carbon) * (param.carbon_feed + carbon_chemicals)/u(param.INDEX.u_in_FT_tap);

J1  = J1 + param.w_CO2/param.CO2_ref^2 * (x(INDEX.x_c_FT.Total_Carbon)/(1+param.K_1/x(INDEX.x_c_FT.Hydrogen) + param.K_1*param.K_2/x(INDEX.x_c_FT.Hydrogen)^2) - param.CO2_ref)^2;

g   = [g_dyn; g_pH; g_price; g_CO2];

y_opt       = [x; u];
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
x0_opt                          = [param.x0; u_opt];

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

%% Compare SS results with MPC

if check_MPC == 0
    return
end

%% MPC-setup

t_step_MPC  = 1;
t_step_data = 1;
N           = 51;  
K           = 4;
t_start     = 0;
t_end       = 380+N;
time        = t_start:t_step_data:t_end;
u_MPC       = SX.sym('u',param.number_of_inputs,N);
x_MPC       = SX.sym('x',param.number_of_states,(K+1)*N+1);
x_avg       = SX.sym('x_avg',param.number_of_states+param.number_of_inputs,1);
x_sum       = SX.zeros(param.number_of_states+param.number_of_inputs,1);
P           = SX.sym('P',param.number_of_states+param.number_of_inputs+N,1);
P_1         = SX.sym('P_1',1,1);

u_model     = SX.sym('u_model',param.number_of_inputs,1);
x_model     = SX.sym('x_model',param.number_of_states,1);
p_model     = SX.sym('p_model',1,1);

%% Symbolic calculation of right hand side of state dynamics

xdot = Aquaponics_Model_MPC( x_model, u_model,p_model, param);
dynamics=Function('dyn',{x_model,u_model,p_model}, {xdot});

state   = x_MPC(:,1);
J = 0;
J1 = 0;
g_coll  = [state-P(1:param.number_of_states)];
g_pH    = [];
u0_sym  = P(param.number_of_states+1:param.number_of_states+param.number_of_inputs);

for i=1:N
%start of loop

    state=x_MPC(:,(K+1)*(i-1)+1);
    state_next=x_MPC(:,(K+1)*i+1);
    input=u_MPC(:,i);
    P_1 = P(param.number_of_states+param.number_of_inputs+i);

    %state discretization via collocation (number of collocation-points is set by K
    for j = 1:K
        g_dyn_coll=0;
        for k = 0:K 
            a = 0; 
            for l = 0:K
                if l~=k
                    a_prod = 1/(param.Legendre_roots(K,k+1) - param.Legendre_roots(K,l+1));
                    for m = 0:K
                        if m~=l && m~=k
                            a_prod = a_prod * (param.Legendre_roots(K,j)-param.Legendre_roots(K,m+1))/(param.Legendre_roots(K,k+1)-param.Legendre_roots(K,m+1));
                        end
                    end
                    a = a + a_prod;
                end
            end
            g_dyn_coll = g_dyn_coll + a * x_MPC(:,(K+1)*i-(K-k))/t_step_MPC;
        end
        l = length(g_coll);
        g_coll = [g_coll;g_dyn_coll - dynamics(x_MPC(:,(K+1)*i-(K-j)),input,P_1)];
        g_coll = [g_coll(1:l+param.INDEX.x_c_FT.Chloride-1); g_coll(l+param.INDEX.x_c_FT.Chloride+1:l+param.INDEX.x_c_FT.Hydrogen-1); g_coll(l+param.INDEX.x_c_FT.Hydrogen+1:l+param.INDEX.x_c_BF.Hydrogen-1); g_coll(l+param.INDEX.x_c_BF.Hydrogen+1:l+param.INDEX.x_c_BT.Hydrogen-1); g_coll(l+param.INDEX.x_c_BT.Hydrogen+1:end)];
    end
    g_cont_coll = 0;
    for j = 0:K
        a_prod = 1;
        for k=0:K
            if j~= k
                a_prod = a_prod * (1-param.Legendre_roots(K,k+1))/(param.Legendre_roots(K,j+1)-param.Legendre_roots(K,k+1));
            end
        end
        g_cont_coll = g_cont_coll + a_prod * x_MPC(:,(K+1)*i-(K-j));
    end
    l = length(g_coll);
    g_coll = [g_coll; g_cont_coll-x_MPC(:,(K+1)*i+1)];
    g_coll = [g_coll(1:l+param.INDEX.x_c_FT.Chloride-1); g_coll(l+param.INDEX.x_c_FT.Chloride+1:l+param.INDEX.x_c_FT.Hydrogen-1); g_coll(l+param.INDEX.x_c_FT.Hydrogen+1:l+param.INDEX.x_c_BF.Hydrogen-1); g_coll(l+param.INDEX.x_c_BF.Hydrogen+1:l+param.INDEX.x_c_BT.Hydrogen-1); g_coll(l+param.INDEX.x_c_BT.Hydrogen+1:end)];
    
    % Objective function and additional constraints 
    for j = 1:K+1
        state_coll = x_MPC(:,(K+1)*(i-1)+1+j);
        for k=1:param.number_of_nutrients
            if(strcmp(param.nutrient_identifiers(k),"Total_Ammonium")==1)
               J = J + param.w_TAN/10/(N*(K+1))*(state_coll(param.INDEX.x_c_FT.(param.nutrient_identifiers(k)))-x_opt_tank(param.INDEX.x_c_FT.Total_Ammonium))^2; 
            elseif(strcmp(param.nutrient_identifiers(k),"Nitrate")==1)
               J = J + param.w_c_N/10/(N*(K+1))/(param.c_ref(k)^2)*(state_coll(param.INDEX.x_c_BT.(param.nutrient_identifiers(k)))-x_opt_tank(param.INDEX.x_c_BT.(param.nutrient_identifiers(k))))^2; 
            elseif(strcmp(param.nutrient_identifiers(k),"Alkalinity")~=1 && strcmp(param.nutrient_identifiers(k),"Total_Carbon")~=1 && strcmp(param.nutrient_identifiers(k),"Hydrogen")~=1 && strcmp(param.nutrient_identifiers(k),"Chloride")~=1 && strcmp(param.nutrient_identifiers(k),"Sodium")~=1)
               J = J + param.w_c/10/(N*(K+1))/(param.c_ref(k)^2)*(state_coll(param.INDEX.x_c_BT.(param.nutrient_identifiers(k)))-x_opt_tank(param.INDEX.x_c_BT.(param.nutrient_identifiers(k))))^2; 
            elseif(strcmp(param.nutrient_identifiers(k),"Sodium")==1 || strcmp(param.nutrient_identifiers(k),"Chloride")==1)
                if x_opt_tank(param.INDEX.x_c_BT.(param.nutrient_identifiers(k))) == 0 
                    c_ref_weight = param.c_in_tap(k);
                    J = J + param.w_c/10/(N*(K+1))/(c_ref_weight^2)*(state_coll(param.INDEX.x_c_BT.(param.nutrient_identifiers(k)))-c_ref_weight)^2; 
                else
                    J = J + param.w_c/10/(N*(K+1))/(param.c_ref(k)^2)*(state_coll(param.INDEX.x_c_BT.(param.nutrient_identifiers(k)))-x_opt_tank(param.INDEX.x_c_BT.(param.nutrient_identifiers(k))))^2; 
                end
            end
        end
    end
    if(i==1)
        for j=param.INDEX.u_in_FT_tap
           J = J+(1e+4)^2*(input(j)-u0_sym(j))^2/N/u_opt_tank(j)^2;
        end
    else
       for j=param.INDEX.u_in_FT_tap
           J = J+(1e+4)^2*(input(j)-u_MPC(j,i-1))^2/N/u_opt_tank(j)^2;
       end
    end

    for j = 1:K+1
        state_coll = x_MPC(:,(K+1)*(i-1)+1+j);
        g_pH        = [g_pH;state_coll(INDEX.x_c_FT.Alkalinity)- state_coll(INDEX.x_c_FT.Total_Carbon)*(param.K_1*state_coll(INDEX.x_c_FT.Hydrogen)+2*param.K_1*param.K_2)/(state_coll(INDEX.x_c_FT.Hydrogen)^2+param.K_1*state_coll(INDEX.x_c_FT.Hydrogen)+param.K_1*param.K_2) - state_coll(INDEX.x_c_FT.Phosphorus)*(param.K_5)/(state_coll(INDEX.x_c_FT.Hydrogen)+param.K_5)];
        g_pH        = [g_pH;state_coll(INDEX.x_c_BF.Alkalinity)- state_coll(INDEX.x_c_BF.Total_Carbon)*(param.K_1*state_coll(INDEX.x_c_BF.Hydrogen)+2*param.K_1*param.K_2)/(state_coll(INDEX.x_c_BF.Hydrogen)^2+param.K_1*state_coll(INDEX.x_c_BF.Hydrogen)+param.K_1*param.K_2) - state_coll(INDEX.x_c_FT.Phosphorus)*(param.K_5)/(state_coll(INDEX.x_c_BF.Hydrogen)+param.K_5)];
        g_pH        = [g_pH;state_coll(INDEX.x_c_BT.Alkalinity)- state_coll(INDEX.x_c_FT.Total_Carbon)*(param.K_1*state_coll(INDEX.x_c_BT.Hydrogen)+2*param.K_1*param.K_2)/(state_coll(INDEX.x_c_BT.Hydrogen)^2+param.K_1*state_coll(INDEX.x_c_BT.Hydrogen)+param.K_1*param.K_2) - state_coll(INDEX.x_c_BT.Phosphorus)*(param.K_5)/(state_coll(INDEX.x_c_BT.Hydrogen)+param.K_5)];
        J1          = J1 +  param.w_pH * (state_coll(INDEX.x_c_FT.Hydrogen)-param.c_H_fish_ref)^2;
        J1          = J1 +  param.w_pH * (state_coll(INDEX.x_c_BT.Hydrogen)-param.c_H_BT_ref)^2;
        J           = J  +  100 * 1000/(N*(K+1)) * (state_coll(INDEX.x_c_FT.Hydrogen)-x_opt_tank(INDEX.x_c_FT.Hydrogen))^2/x_opt_tank(INDEX.x_c_FT.Hydrogen)^2;
        J           = J  +  100 * 1000/(N*(K+1)) * (state_coll(INDEX.x_c_BT.Hydrogen)-x_opt_tank(INDEX.x_c_BT.Hydrogen))^2/x_opt_tank(INDEX.x_c_BT.Hydrogen)^2;
        x_sum(1:param.number_of_states,1) = x_sum(1:param.number_of_states,1) + state_coll;
    end
    for j = 1:param.number_of_inputs
        J = J + 1000 * (input(j)-u_opt_tank(j))^2/u_opt_tank(j)^2/N;
    end
    x_sum(param.number_of_states+1:end) = x_sum(param.number_of_states+1:end) + input;
end 
% Addtional term in objective function to check if the same concentrations and pH can be achieved for the dynamic simulation and for the SS optimization
for j = 1:param.number_of_inputs
    J = J + 1*10000*(x_avg(param.number_of_states+j)-u_opt_tank(j))^2/max(1e-6,u_opt_tank(j))^2;
end
J = J  +  10^2 * 10000 * (x_avg(INDEX.x_c_FT.Hydrogen)-x_opt_tank(INDEX.x_c_FT.Hydrogen))^2/x_opt_tank(INDEX.x_c_FT.Hydrogen)^2;
J = J  +  10^2 * 10000 * (x_avg(INDEX.x_c_BT.Hydrogen)-x_opt_tank(INDEX.x_c_BT.Hydrogen))^2/x_opt_tank(INDEX.x_c_BT.Hydrogen)^2;
for k=1:param.number_of_nutrients
    if(strcmp(param.nutrient_identifiers(k),"Total_Ammonium")==1)
       J = J + param.w_TAN*(x_avg(param.INDEX.x_c_FT.(param.nutrient_identifiers(k)))-x_opt_tank(param.INDEX.x_c_FT.Total_Ammonium))^2; 
    elseif(strcmp(param.nutrient_identifiers(k),"Nitrate")==1)
       J = J + param.w_c_N/(param.c_ref(k)^2)*(x_avg(param.INDEX.x_c_BT.(param.nutrient_identifiers(k)))-x_opt_tank(param.INDEX.x_c_BT.(param.nutrient_identifiers(k))))^2; 
    elseif(strcmp(param.nutrient_identifiers(k),"Alkalinity")~=1 && strcmp(param.nutrient_identifiers(k),"Total_Carbon")~=1 && strcmp(param.nutrient_identifiers(k),"Hydrogen")~=1 && strcmp(param.nutrient_identifiers(k),"Chloride")~=1 && strcmp(param.nutrient_identifiers(k),"Sodium")~=1)
       J = J + param.w_c/(param.c_ref(k)^2)*(x_avg(param.INDEX.x_c_BT.(param.nutrient_identifiers(k)))-x_opt_tank(param.INDEX.x_c_BT.(param.nutrient_identifiers(k))))^2; 
    elseif(strcmp(param.nutrient_identifiers(k),"Sodium")==1 || strcmp(param.nutrient_identifiers(k),"Chloride")==1)
        if x_opt_tank(param.INDEX.x_c_BT.(param.nutrient_identifiers(k))) == 0 
            c_ref_weight = param.c_in_tap(k);
            J = J + param.w_c/(c_ref_weight^2)*(x_avg(param.INDEX.x_c_BT.(param.nutrient_identifiers(k)))-c_ref_weight)^2; 
        else
            J = J + param.w_c/(param.c_ref(k)^2)*(x_avg(param.INDEX.x_c_BT.(param.nutrient_identifiers(k)))-x_opt_tank(param.INDEX.x_c_BT.(param.nutrient_identifiers(k))))^2; 
        end
    end
end
g_avg = [x_avg(1:param.number_of_states) - x_sum(1:param.number_of_states)/(N*(K+1)); x_avg(param.number_of_states+1:end)-x_sum(param.number_of_states+1:end)/N];

g   = [g_coll;g_pH;g_avg];
g1  = [g_coll;g_pH;g_avg];

y_opt       = [reshape(x_MPC,param.number_of_states*((K+1)*N+1),1);reshape(u_MPC,param.number_of_inputs*N,1);x_avg];
nlp_coll    = struct('f',J1,'x',y_opt,'g',g,'p',P);
nlp_coll1   = struct('f',J,'x',y_opt,'g',g1,'p',P);

opts                    = struct;
opts.ipopt.max_iter     = 2000;
opts.print_time         = 0;
opts.ipopt.print_level  = 5;

solver_coll     = nlpsol('solver','ipopt',nlp_coll,opts);
solver_coll1    = nlpsol('solver','ipopt',nlp_coll1,opts);

lbg     = zeros(length(g),1);
ubg     = zeros(length(g),1);
lbg1    = zeros(length(g1),1);
ubg1    = zeros(length(g1),1);
lbx     = 0*ones(length(y_opt),1);
ubx     = inf*ones(length(y_opt),1);

% lbx(((K+1)*N+1)*param.number_of_states+param.INDEX.u_circ_BF:param.number_of_inputs:((K+1)*N+1)*param.number_of_states + param.number_of_inputs*N)    = param.u_circ_BF_min;
% lbx(((K+1)*N+1)*param.number_of_states+param.INDEX.u_in_FT_tap:param.number_of_inputs:((K+1)*N+1)*param.number_of_states + param.number_of_inputs*N)  = param.u_in_FT_tap_min;
% ubx(((K+1)*N+1)*param.number_of_states+param.INDEX.u_circ_BF:param.number_of_inputs:((K+1)*N+1)*param.number_of_states + param.number_of_inputs*N)    = param.u_circ_BF_max;
% ubx(((K+1)*N+1)*param.number_of_states+param.INDEX.u_in_FT_tap:param.number_of_inputs:((K+1)*N+1)*param.number_of_states + param.number_of_inputs*N)  = param.u_in_FT_tap_max;

% lbx(param.INDEX.x_c_FT.Hydrogen:param.number_of_states:((K+1)*(N)+1)*param.number_of_states+1) = 10^-2.5;
% ubx(param.INDEX.x_c_FT.Hydrogen:param.number_of_states:((K+1)*(N)+1)*param.number_of_states+1) = 10^-0.5;
% lbx(param.INDEX.x_c_BF.Hydrogen:param.number_of_states:((K+1)*(N)+1)*param.number_of_states+1) = 10^-3;
% ubx(param.INDEX.x_c_BF.Hydrogen:param.number_of_states:((K+1)*(N)+1)*param.number_of_states+1) = 10^-0.5;
% lbx(param.INDEX.x_c_BT.Hydrogen:param.number_of_states:((K+1)*(N)+1)*param.number_of_states+1) = 10^-2;
% ubx(param.INDEX.x_c_BT.Hydrogen:param.number_of_states:((K+1)*(N)+1)*param.number_of_states+1) = 10^1;

u_opt                           = lbx(((K+1)*N+1)*param.number_of_states+1:((K+1)*N+1)*param.number_of_states+param.number_of_inputs);
u_opt(param.INDEX.u_circ_BF)    = ubx(((K+1)*N+1)*param.number_of_states+param.INDEX.u_circ_BF);
u_opt                           = u_opt_tank;
x_opt                           = [x_opt_tank(1:param.INDEX.x_c_FT.Chloride-1); param.c_in(param.INDEX.x_c_FT.Chloride); x_opt_tank(1:param.INDEX.x_c_FT.Chloride+1)];
x_opt                           = repmat(x_opt_tank,(K+1)*N+1,1);

for i=0:(t_end-t_step_MPC*N)/t_step_MPC
    
    p = [param.x0;u_opt;param.feed_per_day(i+1+120:i+N+120)];
    if i==0
        x0_opt = [x_opt;repmat(u_opt,N,1);x_opt_tank;u_opt_tank];
    else
        x0_opt = [full(sol1.x(param.number_of_states*(K+1)+1:param.number_of_states*(N*(K+1)+1)));full(sol1.x(param.number_of_states*(1+(N-1)*(K+1))+1:param.number_of_states*(N*(K+1)+1)));full(sol1.x(param.number_of_states*(N*(K+1)+1)+param.number_of_inputs+1:param.number_of_states*(N*(K+1)+1)+param.number_of_inputs*N));full(sol1.x(param.number_of_states*(N*(K+1)+1)+param.number_of_inputs*(N-1)+1:param.number_of_states*(N*(K+1)+1)+param.number_of_inputs*N));x_opt_tank;u_opt_tank];
    end
    
    % Solution of NLP
    sol1            = solver_coll1('x0',x0_opt,'lbx', lbx, 'ubx', ubx, 'lbg', lbg1, 'ubg', ubg1,'p',p);
    u_opt           = full(sol1.x(((K+1)*N+1)*param.number_of_states+1:((K+1)*N+1)*param.number_of_states+param.number_of_inputs));
    u_opt(u_opt<0)  = 0;
    x_opt           = full(sol1.x(1:((K+1)*N+1)*param.number_of_states));

    % Continous simulation
    simul.time  = i*t_step_MPC:t_step_data:(i+1)*t_step_MPC;
    simul.input = ones(param.number_of_inputs,length(simul.time)).*u_opt;
    simul.input = simul.input';
    z           = ones(1,length(simul.time)).*param.feed_per_day(120+i);
    z           = z';

    %[time,results] = ode45(@(time,results)Aquaponics_Model_SIM(results,interp1(simul.time, simul.input, time).',interp1(simul.time, z, time).',param),simul.time,param.x0);
    results=full(sol1.x((K+1)*param.number_of_states+1:(K+2)*param.number_of_states))';
    c_H = [results(param.INDEX.x_c_FT.Hydrogen); results(param.INDEX.x_c_BF.Hydrogen); results(param.INDEX.x_c_BT.Hydrogen)]; 
    %[~,c_H] = Aquaponics_Model_SIM(results(end,:)',simul.input(end,:)',z(end,:)',param);
    if(i==0)
        saved_results(i+1,1:length(param.x0))=param.x0;
        saved_results(i+2,1:param.number_of_states)=results(end,:);
        saved_inputs(i+1,1:length(u_opt))=u_opt;
        saved_pH(i+1,1:3) = c_H';
    else
        saved_results(i+2,1:param.number_of_states)=results(end,:);
        saved_inputs(i+1,1:length(u_opt))=u_opt;
        saved_pH(i+1,1:3) = c_H';
    end
    
    param.u0 = u_opt;
    param.x0 = results(end,:)';

end


%% Plots

plot(saved_results(:,param.INDEX.x_c_FT.Sulfate))
NO3_bar = mean(saved_results(100:100+5*51,param.INDEX.x_c_BT.Nitrate)*14.0067);
K_bar = mean(saved_results(100:100+5*51,param.INDEX.x_c_BT.Potassium)*39.0983);
P_bar = mean(saved_results(100:100+5*51,param.INDEX.x_c_BT.Phosphorus)*30.974);
Ca_bar = mean(saved_results(100:100+5*51,param.INDEX.x_c_BT.Calcium)*40.078);
Mg_bar = mean(saved_results(100:100+5*51,param.INDEX.x_c_BT.Magnesium)*24.305);
Na_bar = mean(saved_results(100:100+5*51,param.INDEX.x_c_BT.Sodium)*22.99);
Cl_bar = mean(saved_results(100:100+5*51,param.INDEX.x_c_BT.Chloride)*35.45);
S_bar = mean(saved_results(100:100+5*51,param.INDEX.x_c_BT.Sulfate)*32.065);
TIC_bar = mean(saved_results(100:100+5*51,param.INDEX.x_c_FT.Total_Carbon));
Alk_bar = mean(saved_results(100:100+5*51,param.INDEX.x_c_FT.Alkalinity));
Hyd_bar = mean(saved_results(100:100+5*51,param.INDEX.x_c_FT.Hydrogen));
Hyd_bar1 = mean(saved_results(100:100+5*51,param.INDEX.x_c_BT.Hydrogen));
Hyd_bar2 = mean(saved_results(100:100+5*51,param.INDEX.x_c_BF.Hydrogen));

U_in_bar = mean(saved_inputs(100:100+5*51,param.INDEX.u_in_FT_tap));
U_circ = mean(saved_inputs(100:100+5*51,param.INDEX.u_circ_BF));
U_base_NaOH = mean(saved_inputs(100:100+5*51,param.INDEX.u_Base.NaOH));
U_base_KOH = mean(saved_inputs(100:100+5*51,param.INDEX.u_Base.KOH));
U_base_MgOH2 = mean(saved_inputs(100:100+5*51,param.INDEX.u_Base.MgOH_2));
U_base_CaOH2 = mean(saved_inputs(100:100+5*51,param.INDEX.u_Base.CaOH_2));
U_acid_HCl = mean(saved_inputs(100:100+5*51,param.INDEX.u_Acid.HCl));
U_acid_H2SO4 = mean(saved_inputs(100:100+5*51,param.INDEX.u_Acid.H2SO4));
U_acid_HNO3 = mean(saved_inputs(100:100+5*51,param.INDEX.u_Acid.HNO3));
U_acid_H3PO4 = mean(saved_inputs(150:150+4*51-1,param.INDEX.u_Acid.H3PO4));

E_NO3 = (x_opt_tank(param.INDEX.x_c_BT.Nitrate)*param.Molar_Mass_nutrients(param.INDEX.x_c_FT.Nitrate)/NO3_bar-1)*100
E_K = (x_opt_tank(param.INDEX.x_c_BT.Potassium)*param.Molar_Mass_nutrients(param.INDEX.x_c_FT.Potassium)/K_bar-1)*100
E_P = (x_opt_tank(param.INDEX.x_c_BT.Phosphorus)*param.Molar_Mass_nutrients(param.INDEX.x_c_FT.Phosphorus)/P_bar-1)*100
E_Ca = (x_opt_tank(param.INDEX.x_c_BT.Calcium)*param.Molar_Mass_nutrients(param.INDEX.x_c_FT.Calcium)/Ca_bar-1)*100
E_Mg = (x_opt_tank(param.INDEX.x_c_BT.Magnesium)*param.Molar_Mass_nutrients(param.INDEX.x_c_FT.Magnesium)/Mg_bar-1)*100
E_Na = (x_opt_tank(param.INDEX.x_c_BT.Sodium)*param.Molar_Mass_nutrients(param.INDEX.x_c_FT.Sodium)/Na_bar-1)*100
E_Cl = (x_opt_tank(param.INDEX.x_c_BT.Chloride)*param.Molar_Mass_nutrients(param.INDEX.x_c_FT.Chloride)/Cl_bar-1)*100
E_S = (x_opt_tank(param.INDEX.x_c_BT.Sulfate)*param.Molar_Mass_nutrients(param.INDEX.x_c_FT.Sulfate)/S_bar-1)*100
E_TIC = (x_opt_tank(param.INDEX.x_c_FT.Total_Carbon)/TIC_bar-1)*100
E_alk = (x_opt_tank(param.INDEX.x_c_FT.Alkalinity)/Alk_bar-1)*100
E_hyd = (x_opt_tank(param.INDEX.x_c_FT.Hydrogen)/Hyd_bar-1)*100
E_hyd1 = (x_opt_tank(param.INDEX.x_c_BT.Hydrogen)/Hyd_bar1-1)*100
E_hyd2 = (x_opt_tank(param.INDEX.x_c_BF.Hydrogen)/Hyd_bar2-1)*100

E_u_in = (u_opt_tank(param.INDEX.u_in_FT_tap)/U_in_bar-1)*100
E_circ = (u_opt_tank(param.INDEX.u_circ_BF)/U_circ-1)*100
E_NaOH = (u_opt_tank(param.INDEX.u_Base.NaOH)/U_base_NaOH-1)*100
E_KOH = (u_opt_tank(param.INDEX.u_Base.KOH)/U_base_KOH-1)*100
E_MgOH2 = (u_opt_tank(param.INDEX.u_Base.MgOH_2)/U_base_MgOH2-1)*100
E_CaOH2 = (u_opt_tank(param.INDEX.u_Base.CaOH_2)/U_base_CaOH2-1)*100
E_HCl = (u_opt_tank(param.INDEX.u_Acid.HCl)/U_acid_HCl-1)*100
E_HNO3 = (u_opt_tank(param.INDEX.u_Acid.HNO3)/U_acid_HNO3-1)*100
E_H2SO4 = (u_opt_tank(param.INDEX.u_Acid.H2SO4)/U_acid_H2SO4-1)*100
E_H3PO4 = (u_opt_tank(param.INDEX.u_Acid.H3PO4)/U_acid_H3PO4-1)*100


u_opt_tank(param.INDEX.u_circ_BF)


%% plots

figure(1)
subplot(2,1,1)
stairs(saved_inputs(:,param.INDEX.u_circ_BF)/(param.V_FT+param.V_BF))
%stairs(saved_inputs(:,1))
subplot(2,1,2)
stairs(saved_inputs(:,param.INDEX.u_in_FT_tap)/(param.V_FT+param.V_BF))
%stairs(saved_inputs(:,2))

figure(2)
subplot(3,1,1)
stairs(saved_inputs(:,param.INDEX.u_Base.KOH)/1000)
grid on
xlim([0 360])
xlabel('Time in days','FontSize',11)
ylabel('u_{KOH} in mol/d','FontSize',11)
title('KOH input for pH regulation','FontSize',11)
%stairs(saved_inputs(:,3))
%subplot(2,1,2)
%stairs(saved_inputs(:,param.INDEX.u_Base.MgOH_2)*3600*24)
%stairs(saved_inputs(:,4))
subplot(3,1,2)
stairs(saved_inputs(:,param.INDEX.u_Base.CaOH_2)/1000)
grid on
xlim([0 360])
xlabel('Time in days','FontSize',11)
ylabel('u_{Ca(OH)_2} in mol/d','FontSize',11)
title('Ca(OH)_2 input for pH regulation','FontSize',11)
subplot(3,1,3)
stairs(saved_inputs(:,param.INDEX.u_Base.MgOH_2)/1000)
grid on
xlim([0 360])
xlabel('Time in days','FontSize',11)
ylabel('u_{Mg(OH)_2} in mol/d','FontSize',11)
title('Mg(OH)_2 input for pH regulation','FontSize',11)


figure(3)
plot(-log10(saved_pH(:,1)/10^6))
hold on
plot(-log10(saved_pH(:,2)/10^6))
plot(-log10(saved_pH(:,3)/10^6))

figure(4)

subplot(2,1,1)
plot(saved_results(:,param.INDEX.x_c_FT.Total_Ammonium))
subplot(2,1,2)
plot(saved_results(:,param.INDEX.x_c_FT.Nitrate))

figure(5)
plot(saved_results(:,param.INDEX.x_c_FT.Alkalinity))
hold on
plot(saved_results(:,param.INDEX.x_c_BF.Alkalinity))
plot(saved_results(:,param.INDEX.x_c_BT.Alkalinity))

figure(7)
subplot(2,2,1)
plot(saved_results(:,param.INDEX.x_c_BT.Nitrate)*62.0049*0.226)
hold on
plot(ones(60,1)*param.c_ref(param.INDEX.x_c_FT.Nitrate)*62.0049*0.226)
subplot(2,2,2)
plot(saved_results(:,param.INDEX.x_c_BT.Potassium)*39.0983)
hold on
plot(ones(60,1)*param.c_ref(param.INDEX.x_c_FT.Potassium)*39.0983)
subplot(2,2,3)
plot(saved_results(:,param.INDEX.x_c_BT.Magnesium)*24.305)
hold on
plot(ones(60,1)*param.c_ref(param.INDEX.x_c_FT.Magnesium)*24.305)
subplot(2,2,4)
plot(saved_results(:,param.INDEX.x_c_BT.Phosphorus)*30.974)
hold on
plot(ones(60,1)*param.c_ref(param.INDEX.x_c_FT.Phosphorus)*30.974)

figure(8)
plot(saved_results(:,5)*30.974)
hold on
stairs(saved_inputs(:,param.INDEX.u_in_FT_tap)/(param.V_FT+param.V_BF))
grid on

figure(9)
plot(saved_results(:,6)*40.078)

figure(10)
plot(saved_inputs(:,param.INDEX.u_degas_coeff))

figure(11)
stairs((2*saved_inputs(:,param.INDEX.u_Base.MgOH_2)+2*saved_inputs(:,param.INDEX.u_Base.CaOH_2)+saved_inputs(:,param.INDEX.u_Base.KOH)))