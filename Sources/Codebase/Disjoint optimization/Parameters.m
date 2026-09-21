%% Set struct that contains all parameters and indexes of relevant variables

param                           = struct;
INDEX                           = struct;

%% Choice of scenario

param.feed_case = 5;
param.eco_opt   = 1;

%% Set identifiers and number of states and inputs as well as reference profile

param.nutrient_identifiers      = ["Total_Ammonium"; "Nitrate"; "Potassium"; "Magnesium"; "Phosphorus"; "Calcium"; "Sulfate"; "Sodium"; "Chloride"; "Hydrogen";"Alkalinity";"Total_Carbon"];
param.Molar_Mass_nutrients      = [14.0067         ; 14.0067  ; 39.0983    ; 24.305     ; 30.974      ; 40.078   ; 32.065   ; 22.99   ; 35.45     ; 1         ; 14.0067    ; 44.01]; % [g/mol] = [mg/mmol]
param.M_CO2                     = 44.01;                                                                                                                                             % [g/mol] = [mg/mmol]
param.c_ref                     = [0               ; 0.21     ; 0.234      ; 0.034      ; 0.031       ; 0.16     ; 0.064    ; 0.0109  ; 0.0188    ; 0         ; 0          ; 0]./param.Molar_Mass_nutrients * 1000; % [mmol/L] = [mol/m^3]
param.CO2_ref                   = 13.5/param.M_CO2;                                                                                                                                                                 % [mmol/L] = [mol/m^3]
param.c_H_fish_ref              = 10^-1.2;                                                                                                                                                                          % [umol/L] = [mmol/m^3]
param.c_H_BT_ref                = 10^0.2;                                                                                                                                                                           % [umol/L] = [mmol/m^3]

for i=1:length(param.nutrient_identifiers)
    INDEX.nutrient.(param.nutrient_identifiers(i))=i;
end
param.number_of_nutrients       = length(param.nutrient_identifiers);
param.affected_by_nitrification = [1; 1; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1];
param.is_set_by_feed_content    = [0; 0; 1; 1; 1; 1; 1; 0; 0; 0; 0; 0];

%% Set bases

param.base_identifiers          = ["KOH";"NaOH";"CaOH_2";"MgOH_2"];
param.base_to_nutrient          = [0 0 0 0; 0 0 0 0; 1 0 0 0; 0 0 0 1 ; 0 0 0 0; 0 0 1 0; 0 0 0 0; 0 1 0 0; 0 0 0 0; 0 0 0 0; 1 1 2 2; 0 0 0 0];
param.number_of_bases           = length(param.base_identifiers);
param.price_per_mole_base       = [0.195; 0.147; 0.063; 0.318];
param.carbon_per_mole_base      = [0.092; 0.052; 0.091; 0.185];

%% Set acids

param.acid_identifiers          = ["H3PO4";"HNO3";"HCl";"H2SO4"];
param.acid_to_nutrient          = [0 0 0 0; 0 1 0 0; 0 0 0 0; 0 0 0 0; 1 0 0 0; 0 0 0 0; 0 0 0 1; 0 0 0 0; 0 0 1 0; 0 0 0 0; -1  -1 -1 -2; 0 0 0 0];
param.number_of_acids           = length(param.acid_identifiers);
param.price_per_mole_acid       = [0.475; 0.412; 0.384; 0.362];
param.carbon_per_mole_acid      = [0.692; 0.379; 0.108; 0.014];

%% Set freshwater sources

param.c_in_tap_soft             = [0.00/14.0067; 7.2/14.0067; 1.9/39.0983; 3.8/24.305; 0.00/30.974; 25.1/40.078; 20/32.065; 10.9/22.99; 18.8/35.45; 10^-1.9; 0.9; 0.9227];      % [mmol/L] = [mol/m^3]
param.c_in_cond                 = [ 0          ; 0          ; 0          ; 0         ; 0          ; 0          ; 0        ; 0         ; 0         ; 10^0.5 ; 0  ; 1.375e-2];    % [mmol/L] = [mol/m^3]
param.c_in = param.c_in_tap_soft;

%% Feeding plan for batch rearing of Clarias

param.feed_per_day              = [0.141 0.153 0.168 0.183 0.199 0.217 0.235 0.255 0.276 0.297 0.319 0.343 0.367 0.393 0.419 0.445 0.472 0.500 0.529 0.558 0.588 0.617 0.648 0.679 0.713 ...
                                   0.747 0.781 0.816 0.851 0.887 0.923 0.958 0.994 1.031 1.066 1.099 1.133 1.164 1.198 1.231 1.259 1.290 1.315 1.343 1.371 1.396 1.420 1.443 1.464 1.483 ...
                                   0.000 1.604 1.630 1.655 1.691 1.727 1.756 1.792 1.828 1.863 1.898 1.924 1.958 1.991 2.032 2.072 2.112 2.151 2.190 2.229 2.268 2.306 2.342 2.378 2.424 ...
                                   2.471 2.518 2.565 2.612 2.658 2.704 2.749 2.794 2.838 2.894 2.949 3.000 3.054 3.103 3.156 3.207 3.253 3.301 3.344 3.390 3.434 3.477 3.518 3.557 3.594 ...	
                                   3.629 0.000 3.746 3.786 3.825 3.876 3.926 3.968 4.033 4.082 4.130 4.177 4.216 4.261 4.306 4.357 4.426 4.476 4.526 4.575 4.623 4.690 4.737 4.781 4.826 ...	
                                   4.878 4.933 4.987 5.061 4.804 4.855 4.594 4.643 4.691 4.738 4.796 4.552 4.605 4.342 4.392 4.445 4.508 4.554 4.281 4.323 4.052 4.096 4.144 4.185 4.224 ...
                                   3.933 3.968 0.000 3.746 3.786 3.825 3.876 3.926 3.968 4.033 4.082 4.130 4.177 4.216 4.261 4.306 4.357 4.426 4.476 4.526 4.575 4.623 4.690 4.737 4.781 ...
                                   4.826 4.878 4.933 4.987 5.061 4.804 4.855 4.594 4.643 4.691 4.738 4.796 4.552 4.605 4.342 4.392 4.445 4.508 4.554 4.281 4.323 4.052 4.096 4.144 4.185 ...
                                   4.224 3.933 3.968 0.000 3.746 3.786 3.825 3.876 3.926 3.968 4.033 4.082 4.130 4.177 4.216 4.261 4.306 4.357 4.426 4.476 4.526 4.575 4.623 4.690 4.737 ...
                                   4.781 4.826 4.878 4.933 4.987 5.061 4.804 4.855 4.594 4.643 4.691 4.738 4.796 4.552 4.605 4.342 4.392 4.445 4.508 4.554 4.281 4.323 4.052 4.096 4.144 ...
                                   4.185 4.224 3.933 3.968 0.000 3.746 3.786 3.825 3.876 3.926 3.968 4.033 4.082 4.130 4.177 4.216 4.261 4.306 4.357 4.426 4.476 4.526 4.575 4.623 4.690 ...
                                   4.737 4.781 4.826 4.878 4.933 4.987 5.061 4.804 4.855 4.594 4.643 4.691 4.738 4.796 4.552 4.605 4.342 4.392 4.445 4.508 4.554 4.281 4.323 4.052 4.096 ...
                                   4.144 4.185 4.224 3.933 3.968 0.000 3.746 3.786 3.825 3.876 3.926 3.968 4.033 4.082 4.130 4.177 4.216 4.261 4.306 4.357 4.426 4.476 4.526 4.575 4.623 ...	
                                   4.690 4.737 4.781 4.826 4.878 4.933 4.987 5.061 4.804 4.855 4.594 4.643 4.691 4.738 4.796 4.552 4.605 4.342 4.392 4.445 4.508 4.554 4.281 4.323 4.052 ...	
                                   4.096 4.144 4.185 4.224 3.933 3.968 0.000 3.746 3.786 3.825 3.876 3.926 3.968 4.033 4.082 4.130 4.177 4.216 4.261 4.306 4.357 4.426 4.476 4.526 4.575 ...
                                   4.623 4.690 4.737 4.781 4.826 4.878 4.933 4.987 5.061 4.804 4.855 4.594 4.643 4.691 4.738 4.796 4.552 4.605 4.342 4.392 4.445 4.508 4.554 4.281 4.323 ...	
                                   4.052 4.096 4.144 4.185 4.224 3.933 3.968 0.000 3.746 3.786 3.825 3.876 3.926 3.968 4.033 4.082 4.130 4.177 4.216 4.261 4.306 4.357 4.426 4.476 4.526 ...	
                                   4.575 4.623 4.690 4.737 4.781 4.826 4.878 4.933 4.987 5.061 4.804 4.855 4.594 4.643 4.691 4.738 4.796 4.552 4.605 4.342 4.392 4.445 4.508 4.554 4.281 ...
                                   4.323 4.052 4.096 4.144 4.185 4.224 3.933 3.968 0.000 3.746 3.786 3.825 3.876 3.926 3.968 4.033 4.082 4.130 4.177 4.216 4.261 4.306 4.357 4.426 4.476 ...	
                                   4.526 4.575 4.623 4.690 4.737 4.781 4.826 4.878 4.933 4.987 5.061 4.804 4.855 4.594 4.643 4.691 4.738 4.796 4.552 4.605 4.342 4.392 4.445 4.508 4.554 ...	
                                   4.281 4.323 4.052 4.096 4.144 4.185 4.224 3.933 3.968 0.000 3.746 3.786 3.825 3.876 3.926 3.968 4.033 4.082 4.130 4.177 4.216 4.261 4.306 4.357 4.426 ...	
                                   4.476 4.526 4.575 4.623 4.690 4.737 4.781 4.826 4.878 4.933 4.987 5.061 4.804 4.855 4.594 4.643 4.691 4.738 4.796 4.552 4.605 4.342 4.392 4.445 4.508 ...
                                   4.554 4.281 4.323 4.052 4.096 4.144 4.185 4.224 3.933 3.968 0.000 3.746 3.786 3.825 3.876 3.926 3.968 4.033 4.082 4.130 4.177 4.216 4.261 4.306 4.357 ...
                                   4.426 4.476 4.526 4.575 4.623 4.690 4.737 4.781 4.826 4.878 4.933 4.987 5.061 4.804 4.855 4.594 4.643 4.691 4.738 4.796 4.552 4.605 4.342 4.392 4.445 ...
                                   4.508 4.554 4.281 4.323 4.052 4.096 4.144 4.185 4.224 3.933 3.968 0.000 3.746 3.786 3.825 3.876 3.926 3.968 4.033 4.082 4.130 4.177 4.216 4.261 4.306 ...
                                   4.357 4.426 4.476 4.526 4.575 4.623 4.690 4.737 4.781 4.826 4.878 4.933 4.987 5.061 4.804 4.855 4.594 4.643 4.691 4.738 4.796 4.552 4.605 4.342 4.392 ...	
                                   4.445 4.508 4.554 4.281 4.323 4.052 4.096 4.144 4.185 4.224 3.933 3.968 0.000 3.605 3.633 3.658 3.693 3.726 3.751 3.798 3.827 3.855 3.880 3.897 3.919 ...	
                                   3.939 3.964 4.007 4.031 4.054 4.075 4.095 4.132 4.149 4.164 4.177 4.199 4.220 4.240 4.279 3.988 4.003 3.707 3.720 3.732 3.743 3.765 3.486 3.507 3.208 ...	
                                   3.228 3.247 3.278 3.296 2.991 3.008 2.708 2.725 2.748 2.764 2.780 2.469 2.484 0.000 2.141 2.156 2.170 2.185 2.198 2.212 2.241 2.254 2.267 2.280 2.292 ...	
                                   2.304 2.315 2.325 2.354 2.365 2.375 2.385 2.394 2.422 2.431 2.439 2.447 2.455 2.462 2.468 2.496 2.192 2.197 1.890 1.894 1.897 1.899 1.901 1.604 1.605 ...
                                   1.288 1.289 1.289 1.302 1.302 0.979 0.979 0.662 0.661 0.667 0.667 0.666 0.339 0.339 0.000]'; % [g/day]

% Average feed input in (approximated) steady-state
param.q_feed_stat = mean(param.feed_per_day(153:203));

%% Choice of fish feed

if param.feed_case == 1
    param.price_feed = 0.99* param.q_feed_stat;
    param.carbon_feed = 991.3/1000 * param.q_feed_stat;
    param.Feed_Content_Nutrient    = [ 21.7 0 16.5 4.0 13.9 0 4.9 0 0 0 21.7 480]';
end
if param.feed_case == 2
    param.price_feed = 1.00* param.q_feed_stat;
    param.carbon_feed = 988.6/1000 * param.q_feed_stat;
    param.Feed_Content_Nutrient    = [ 21.8 0 7.4 2.8 26.5 0 4.9 0 0 0 21.8 480]';
end
if param.feed_case == 3
    param.price_feed = 0.99* param.q_feed_stat;
    param.carbon_feed = 991.9/1000 * param.q_feed_stat;
    param.Feed_Content_Nutrient    = [ 22.5 0 9.5 6.4 11.8 0 4.9 0 0 0 22.5 480]';
end
if param.feed_case == 4
    param.price_feed = 0.99* param.q_feed_stat;
    param.carbon_feed = 991.5/1000 * param.q_feed_stat;
    param.Feed_Content_Nutrient    = [ 22.2 0 14.0 5.3 19.2 0 4.9 0 0 0 22.2 480]';
end
if param.feed_case == 5
    param.price_feed = 0.51* param.q_feed_stat;
    param.carbon_feed = 561.2/1000 * param.q_feed_stat;
    param.Feed_Content_Nutrient    = [ 22.2 0 7.2 2.3 8.9 0 4.9 0 0 0 22.2 480]';
end
param.whole_price = 8;
param.whole_carbon = 9;

%% System parameters

param.V_FT                      = 3.600;                                                                                    % [m^3]                                                                                     
param.V_BF                      = 2*0.900;                                                                                  % [m^3]                                                      
param.V_BT                      = 1.000;                                                                                    % [m^3]                                                      
param.Area_per_Vol_BF           = 600;                                                                                      % [m^2/m^3]   
param.saturation_ammonia        = 1/14.0067;                                                                                % [mmol/L] = [mol/m^3]
param.max_flux_amm_per_surf     = 1.00;                                                                                     % [g/(m^2*day)];
param.max_flux_ammonia          = param.max_flux_amm_per_surf* (0.5*param.V_BF) *param.Area_per_Vol_BF/14.0067; % [mol/day]
param.nitrification_effect      = [-1; 1; 0; 0; 0; 0; 0; 0; 0; 0; -2; 0];                                                   % [-]
param.K_1                       = 10^(-6.3+6);                                                                              % [umol/L] = [mmol/m^3] % Equilibrium concentrations and c_H scaled to umol/L
param.K_2                       = 10^(-10.3+6);                                                                             % [umol/L] = [mmol/m^3]
param.K_5                       = 10^(-7.2+6);                                                                              % [umol/L] = [mmol/m^3]
param.c_H_fish_ex               = 10^-1;                                                                                    % [umol/L] = [mmol/m^3]
param.CO2_eq                    = 1.375e-2;                                                                                 % [mmol/L] = [mol/m^3]    

%% Dietary feed content of nutrient to dissolved nutrient release - Shaw2024

param.Feed_to_Water_Content_Poly      = [8.1007 -143.85; 0 0; 1.3116 -5.4117; 1.4162 -0.7287; 0.2379 -1.3023; 0 0; 1 0; 0 0; 0 0; 0 0; 8.1007 -143.85; 1 0];
param.Feed_to_Nut                     = zeros(param.number_of_nutrients,1);
for i=1:param.number_of_nutrients
    param.Feed_to_Nut(i,:)            = polyval(param.Feed_to_Water_Content_Poly(i,:),param.Feed_Content_Nutrient(i));    
end
param.Feed_to_Nut                     = param.Feed_to_Nut./param.Molar_Mass_nutrients;  % [mmol/g_feed] = [mol/kg_feed]
param.Feed_to_Nut(INDEX.nutrient.Alkalinity,:) = param.Feed_to_Nut(INDEX.nutrient.Total_Ammonium) + param.K_5/(param.K_5+10^-1)*param.Feed_to_Nut(INDEX.nutrient.Phosphorus); % [mmol/g_feed] = [mol/kg_feed]                                 

%% INDEX mapping

% mapping of states
param.number_of_states          = 2*param.number_of_nutrients + sum(param.affected_by_nitrification); 
for i=1:param.number_of_nutrients
    INDEX.x_c_FT.(param.nutrient_identifiers(i))  = i;
end
j=1;
for i=1:param.number_of_nutrients    
    if(param.affected_by_nitrification(i)==1)
        INDEX.x_c_BF.(param.nutrient_identifiers(i))  = j + param.number_of_nutrients;
        j=j+1;
    end
end
for i=1:param.number_of_nutrients    
    INDEX.x_c_BT.(param.nutrient_identifiers(i))  = i + param.number_of_nutrients + sum(param.affected_by_nitrification);
end

% mapping of inputs
param.number_of_inputs          = param.number_of_bases + param.number_of_acids + 3;
INDEX.u_circ_BF                 = 1;
INDEX.u_in_FT_tap               = 2;
for i=1:param.number_of_bases
    INDEX.u_Base.(param.base_identifiers(i)) = i + INDEX.u_in_FT_tap;
end
for i=1:param.number_of_acids
    INDEX.u_Acid.(param.acid_identifiers(i)) = i+param.number_of_bases + INDEX.u_in_FT_tap;
end
INDEX.u_degas_coeff = param.number_of_bases + param.number_of_acids + INDEX.u_in_FT_tap + 1;

% Save INDEX in param struct
param.INDEX = INDEX;

%% Starting values for states

x0_BF = [];
ind_alkalinity_bf = sum(param.affected_by_nitrification(1:param.INDEX.nutrient.Alkalinity-1))+1;
for i=1:length(param.affected_by_nitrification)
    if param.affected_by_nitrification(i)~=0
        x0_BF=[x0_BF;param.c_in(i)];
    end
end
param.x0                        = [param.c_in; x0_BF; param.c_in];

%% Set parameters for optimization

% bounds
param.u_circ_BF_max     = 4 * 24 * (param.V_FT+param.V_BF); % [m^3/day]
param.u_circ_BF_min     = 0;                                % [m^3/day]
param.u_in_FT_tap_max   = 0.2 * (param.V_FT+param.V_BF);    % [m^3/day]
param.u_in_FT_tap_min   = 0.06 * (param.V_FT+param.V_BF);   % [m^3/day]

param.ub_c_factor       = 1.25; % [-]
param.lb_c_factor       = 0.75; % [-]
param.ub_c_N_factor     = 1.1;  % [-]
param.lb_c_N_factor     = 0.9;  % [-]

param.c_H_BF_max        = 10^-0.8;  % [umol/L] = [mmol/m^3]
param.c_H_BF_min        = 10^-2;    % [umol/L] = [mmol/m^3]
param.c_H_FT_max        = 10^-1;    % [umol/L] = [mmol/m^3]
param.c_H_FT_min        = 10^-1.5;  % [umol/L] = [mmol/m^3]
param.c_H_BT_max        = 10^0.5;   % [umol/L] = [mmol/m^3]
param.c_H_BT_min        = 10^0;     % [umol/L] = [mmol/m^3]

param.c_max_TAN         = 1/param.Molar_Mass_nutrients(param.INDEX.nutrient.Total_Ammonium); %[mmol/L] = [mol/m^3]

% weights
param.w_c_N = 10^5;
param.w_c   = 100;
param.w_TAN = 10^3/(param.c_max_TAN/10)^2;
param.w_pH  = 10^6;
param.w_CO2 = 10^5;


if param.eco_opt == 1
    param.w_eco = 5 * 10^3;
else
    param.w_eco = 0;
end