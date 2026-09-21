function [J,sol] = NutrientOptimizationRAS(y1,y,param,Feed_Par,constraint_bounds,plot_solution,Eco_bounds)
    
    %% Parameters
    
    %Optimization Variables from top-level optimization
    q                   = y(1);
    CPGE_ratio          = y(2)/10;
    param.c_H_fish      = y(3);
    param.c_H_plants    = y(4);
    q_circ              = y(5);
    P_feed_setpoint     = y(6);
    
    %Results from steady-state solution of RAS
    c_TAN_BF            = y1(6);
    c_H_BF              = y1(9);
    
    %Parameters of chemicals
    %Bases
    base_identifiers                = param.base_identifiers;
    num_base                        = length(base_identifiers);
    base_indexes                    = 2*height(Feed_Par)+1:2*height(Feed_Par)+num_base;
    base_to_nutrient                = param.base_to_nutrient;
    base_to_additional_nutrients    = param.base_to_additional_nutrients;
    price_per_mole_base             = param.price_per_mole_base;
    carbon_per_mole_base            = param.carbon_per_mole_base;
    
    %Acids
    acid_identifiers                = param.acid_identifiers; 
    num_acid                        = length(acid_identifiers);
    acid_indexes                    = 2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid;
    acid_to_nutrient                = param.acid_to_nutrient;
    acid_to_additional_nutrients    = param.acid_to_additional_nutrients;
    price_per_mole_acid             = param.price_per_mole_acid;
    carbon_per_mole_acid            = param.carbon_per_mole_acid;

    %General Parameters
    Ca_P_ratio          = 1.33;
    MJ_to_kcal          = 239.006;
    Perc_to_gram        = 10;
    u_feed_min          = 0.001;
    max_ing             = 20;

    %References - dissolved nutrient concentrations in BT
    nutrients                       = ["Potassium (%)"; "Magnesium (%)"; "Phosphorus (%)"; "Calcium (%)"; "Sodium (%)"; "Chlorine (%)";"Sulfur (%)"];
    additional_nutrients_pH         = ["Alkalinity_fish";"Total_Carbon";"Nitrogen"];
    molar_mass_nutrients            = [39.0983 ;24.305 ;30.974 ;40.078 ;22.990 ;35.450 ;32.065 ]; % g/mol
    %Standard Hoagland solution; for Na+ und Cl- take the concentrations in freshwater as reference
    c_ref_NO3N                      = 210;
    if param.freshwater_source == 1
        nutrient_conc_in            = param.c_in_tap_hard_RASopt;
        nutrient_add_conc_in        = param.c_in_tap_hard_RASopt_add;
        nutrient_reference_plants   = [234 ;34 ;31 ;160 ;27  ;44  ;64 ];
    end
    if param.freshwater_source == 2
        nutrient_conc_in            = param.c_in_tap_soft_RASopt;
        nutrient_add_conc_in        = param.c_in_tap_soft_RASopt_add;
        nutrient_reference_plants   = [234 ;34 ;31 ;160 ;10.9 ;18.8 ;64 ];
    end
    if param.freshwater_source == 3
        nutrient_conc_in            = param.c_in_cond_RASopt;
        nutrient_add_conc_in        = param.c_in_cond_RASopt_add;
        nutrient_reference_plants   = [234 ;34 ;31 ;160 ;0    ;0    ;64 ];
    end
    num_ref = length(nutrient_reference_plants);
    
    %Empirical linear coefficients for dissolved nutrient releas of fish
    lin_fun_m_nutrients             = [1.3116  ;1.4162 ;0.2379 ;0      ;0      ;0      ;0      ];
    lin_fun_n_nutrients             = [-5.4117 ;-0.7287;-1.3023;0      ;0      ;0      ;4.9    ];
    
    %Weights - dissolved nutrient concentrations in BT 
    weight_reference                = zeros(length(nutrient_reference_plants),1);
    w_NO3N = 2 * 100 * 100000;
    nutrient_specific_weight        = 100000 * [1;1;1;1;1;1;1];
    for i = 1:length(nutrient_reference_plants)
        if nutrient_reference_plants(i) ~=0
            weight_reference(i)     = 1/nutrient_reference_plants(i).^2 * nutrient_specific_weight(i); 
        else
            %Weight if reference is equal to 0
            weight_reference(i)     = 10000/param.c_in_tap_soft_RASopt(i)^2 * nutrient_specific_weight(i); 
        end
    end
    
    %Feed formulation properties that are to be maximized
    nut_max_str = [];
    weight_max  = [];
    num_nut_max = length(nut_max_str);

    %Bounds for minimization
    Price_max   = Eco_bounds(1);
    Carbon_max  = Eco_bounds(2);
    Na_max      = Eco_bounds(3);
    Cl_max      = Eco_bounds(4);

    %Maximum content of sub-classes of ingredients
    Max_additives       = 0.05;
    Max_minerals        = 0.00;
    Max_VitPremix       = 0.01;
    Max_AminoAcidPremix = 0.01;

    %Feed formulation properties that are to be minimized
    nut_min_str = ["Sodium (%)"; "Chlorine (%)"; "Global warming - Including LUC & Peat (kg CO2eq/t)" ; "Price in USD/kg"];
    weight_min  = [1000/Na_max ; 1000/Cl_max   ; 1000/Carbon_max                                      ; 1000/Price_max   ]; 
    num_nut_min = length(nut_min_str);

    %Other weights
    w_CaP       = 2*10^5;
    w_DPDE      = 1000;
    w_P_feed    = 10^8;
    w_SC        = 10^8;

    %Grouping ingredients
    Additives               = [566:568 572:height(Feed_Par)];
    MineralMix_and_Salts    = [648:686 699 700 702 703]';
    VitaminMix              = [572:618]';
    AminoAcids              = [619:647 682:698 701 703]';

    %% Get bounds of dietary feed properties

    Feed_Par_ident  = string(Feed_Par.Properties.VariableNames)';
    row_constraints = zeros(height(constraint_bounds),1);
    constraints_str = strings(height(constraint_bounds),2); 
    
    ind_constr=1;
    for i = 1:height(constraint_bounds)  
        if(~isnan(constraint_bounds.("Value")(i)) && (strcmp(constraint_bounds.("Restriction Type")(i),'Minimum')==1 || strcmp(constraint_bounds.("Restriction Type")(i),'Maximum')==1))      
            constraints_str(ind_constr,1)   = string(constraint_bounds.("Specification")(i));
            constraints_str(ind_constr,2)   = string(constraint_bounds.("Restriction Type")(i));
            row_constraints(ind_constr)     = i;
            ind_constr                      = ind_constr + 1;
        end
    end
    row_constraints                         = row_constraints(1:ind_constr-1,1);
    constraints_str                         = constraints_str(1:ind_constr-1,:);
    for i = 1:length(constraints_str)
        if contains(constraints_str(i,1),'Fumonicin')==1
            constraints_str(i,1)            = 'Fumonisin (FUM)';
        end
    end
    
    column_number_constr                    = zeros(length(constraints_str),1);
    no_inds_constr                          = 1:length(constraints_str);
    num_match = 0;
    for i = 1:length(constraints_str)
        for j = 1:length(Feed_Par_ident)
            if contains(Feed_Par_ident(j),erase(constraints_str(i)," "))==1
                column_number_constr(i)     = j;
                no_inds_constr(i-num_match) = [];
                num_match                   = num_match + 1;
                break
            end
        end   
    end
    
    match = 0;
    if ~isempty(no_inds_constr)
        num_iterations=1;
        for i = no_inds_constr
            for j = 1:length(Feed_Par_ident)
                if contains(Feed_Par_ident(j),constraints_str(i))==1
                    column_number_constr(i)=j;
                    no_inds_constr(num_iterations)=[];
                    match=1;
                    break
                end
            end
            if match==1
                num_iterations=num_iterations-1;
            end
            num_iterations=num_iterations+1;
            match = 0;
        end
    end
    
    length(no_inds_constr)
    
    CP_ident = "Crude  Protein (%)";
    GE_ident = "Gross Energy -MJ (MJ/kg)";

    DP_ident = "Dig CP -fish (%)";
    DE_ident = "Dig GE (DE) - fish (kcal)";
    
    for i=1:length(constraints_str)
        if((strcmp(constraint_bounds.("Restriction Type")(i),'Ratio')==1 || strcmp(constraint_bounds.("Restriction Type")(i),'ratio')==1) && ~isnan(constraint_bounds.("Value")(i)))
            if strcmp(constraint_bounds.("Unit")(i),"g/MJ")==1
                DP_DE_ratio=constraint_bounds.("Value")(i);
            end
            if strcmp(constraint_bounds.("Unit")(i),"g/kcal")==1
                DP_DE_ratio=constraint_bounds.("Value")(i)*MJ_to_kcal;
            end
        end
    end

    %% Preparations for Objective Function - find correct columns in ingredient matrix 

    %Matrix columns of nutrients, which references are present in quadratic objectives
    obj_par_column_ident = [nutrients; CP_ident; GE_ident; DP_ident; DE_ident; nutrients];
    column_number_obj = zeros(length(obj_par_column_ident),1);
    for i = 1:length(obj_par_column_ident)
        for j = 1:length(Feed_Par_ident)
            if contains(Feed_Par_ident(j),obj_par_column_ident(i))==1
                column_number_obj(i)=j;
                break
            end
        end   
    end

    %Indexes of dietary mineral nutrients, which are present in quadratic objectives
    [~,Ind_Ca]  = max(contains(nutrients,"Calcium (%)"));
    [~,Ind_P]   = max(contains(nutrients,"Phosphorus (%)"));
    
    %Matrix columns of nutrients which are to be minimized
    min_column_ident = nut_min_str;
    column_number_min = zeros(length(min_column_ident),1);
    for i = 1:length(min_column_ident)
        for j = 1:length(Feed_Par_ident)
            if contains(Feed_Par_ident(j),min_column_ident(i))==1
                column_number_min(i)=j;
                break
            end
        end   
    end
    
    %Matrix columns of nutrients which are to be maximized
    max_column_ident = nut_max_str;
    column_number_max = zeros(length(max_column_ident),1);
    for i = 1:length(max_column_ident)
        for j = 1:length(Feed_Par_ident)
            if contains(Feed_Par_ident(j),max_column_ident(i))==1
                column_number_max(i)=j;
                break
            end
        end   
    end

    %% Set Optimization Variables
    
    %Binary variables assigned to every ingredient
    num_bin = height(Feed_Par);
    
    %Name all variables
    u_opt = strings(height(Feed_Par)+num_bin+num_base+num_acid,1);
    
    %Fish feed ingredients
    for i = 1:height(Feed_Par)
        u_opt(i) = strcat('u_ing_',num2str(i));
    end

    %Binary variables
    for i = height(Feed_Par)+1:height(Feed_Par)+num_bin
        u_opt(i) = strcat('y_ing_',num2str(i-height(Feed_Par)));
    end

    %Bases and acids
    for i = height(Feed_Par)+num_bin+1:height(Feed_Par)+num_bin+num_base
        u_opt(i) = strcat('u_base_',num2str(i-height(Feed_Par)-num_bin));
    end
    for i = height(Feed_Par)+num_bin+num_base+1:height(Feed_Par)+num_bin+num_base+num_acid
        u_opt(i) = strcat('u_acid_',num2str(i-height(Feed_Par)-num_bin-num_base));
    end

    %Nutrient states (both dietary and dissolved)
    x_opt = Feed_Par_ident(column_number_obj);
    
    %Soft constraint variables
    e_softcon = strings(num_ref+3,1);
    for i = 1:num_ref
        e_softcon(i) = strcat('e_softcon_',nutrients(i));
    end
    e_softcon(num_ref+1) = strcat('e_softcon_','Nitrate');
    e_softcon(num_ref+2) = strcat('e_softcon_','Price');
    e_softcon(num_ref+3) = strcat('e_softcon_','Carbon');
    
    %Resulting vector of variable names
    model.varnames = cellstr([u_opt;x_opt;additional_nutrients_pH;e_softcon]);
    
    %Specify the type of every variable (continous or binary)
    %Fish feed ingredients
    vartypes = strings(height(Feed_Par)+num_bin+num_base+num_acid,1);
    for i = 1:height(Feed_Par)
        vartypes(i)="C";
    end

    %Binary variables
    for i = height(Feed_Par)+1:height(Feed_Par)+num_bin
        vartypes(i)="I";
    end
    
    %Bases and acids
    for i = height(Feed_Par)+num_bin+1:height(Feed_Par)+num_bin+num_base
        vartypes(i)="C";
    end
    for i = height(Feed_Par)+num_bin+num_base+1:height(Feed_Par)+num_bin+num_base+num_acid
        vartypes(i)="C";
    end

    %Nutrient states (both dietary and dissolved)
    vartypes_x = strings(length(x_opt),1);
    for i = 1:length(x_opt)
        vartypes_x(i)="C";
    end
    %Alkalinty, TIC, Nitrate states
    vartypes_pH = strings(length(additional_nutrients_pH),1);
    for i=1:length(additional_nutrients_pH)
        vartypes_pH(i) = "C";
    end

    %Soft constraint variables
    vartypes_e_softcon = strings(num_ref+1+2,1);
    for i=1:num_ref+3
        vartypes_e_softcon(i) = "C";
    end

    %Resulting vector of variable types
    model.vtype = char([vartypes;vartypes_x;vartypes_pH;vartypes_e_softcon]);
    
    %% Set Constraints Ax >= b
    
    num_u = length(u_opt);
    num_x = length(x_opt);
    num_add = length(additional_nutrients_pH);
    
    %Constraint Matrix A
    A_con = zeros(2*num_bin+length(constraints_str)+16+4*num_ref+2*num_add+4+1+(num_ref+1)*2,num_u+num_x+num_add+(num_ref+1+2));
    
    %Right hand side b
    model.rhs = zeros(2*num_bin+length(constraints_str)+16+4*num_ref+2*num_add+4+1+(num_ref+1)*2,1);

    %Dietary nutrient constraints stated in ASNS file
    for i=1:length(constraints_str)
        par = Feed_Par{:,column_number_constr(i)};
        %Dietary nutrients with lower bound - hard constraint
        if(strcmp(constraints_str(i,2),"Minimum")==1)
            A_con(i,1:height(Feed_Par)) = par'; % >= min content
        %Dietary nutrients with upper bound
        else
            %Soft constraint of Price
            if strcmp(constraints_str(i,1),"Price in USD/kg")==1
                A_con(i,1:height(Feed_Par))=(-1)*par' * param.q_feed_stat;
                A_con(i,height(Feed_Par)+num_bin+1:height(Feed_Par)+num_bin+num_base+num_acid) = (-1) * [price_per_mole_base; price_per_mole_acid];
                A_con(i,num_u + num_x + num_add + num_ref + 1 + 1) = 1;
            %Soft constraint of Carbon footprint
            elseif strcmp(constraints_str(i,1),"Global warming - Including LUC & Peat (kg CO2eq/t)")==1 
                A_con(i,1:height(Feed_Par))=(-1)*par' * param.q_feed_stat;
                A_con(i,height(Feed_Par)+num_bin+1:height(Feed_Par)+num_bin+num_base+num_acid) = (-1)* [carbon_per_mole_base; carbon_per_mole_acid];
                A_con(i,num_u + num_x + num_add + num_ref + 1 + 2) = 1;
            %Hard constraints of nutritional Properties
            else
                A_con(i,1:height(Feed_Par))=(-1)*par'; % >= (-1) * max content
            end
        end
    end
    
    %Right hand side - bounds stated in ASNS file 
    for i = 1:length(constraints_str)
        if strcmp(constraint_bounds.("Restriction Type")(row_constraints(i)),'Maximum')==1
            if strcmp(constraints_str(i,1),"Price in USD/kg")==1
                model.rhs(i) = (-1) * constraint_bounds.("Value")(row_constraints(i)) * q;
            elseif strcmp(constraints_str(i,1),"Global warming - Including LUC & Peat (kg CO2eq/t)")==1 
                model.rhs(i) = (-1) * constraint_bounds.("Value")(row_constraints(i)) * q;
            else
                model.rhs(i) = (-1) * 0.99 * constraint_bounds.("Value")(row_constraints(i));
            end
        end
        if strcmp(constraint_bounds.("Restriction Type")(row_constraints(i)),'Minimum')==1
            model.rhs(i) = constraint_bounds.("Value")(row_constraints(i));
        end
    end
    
    %Set CPGE ratio specified by the top-level solver
    A_con(length(constraints_str)+1,1:height(Feed_Par)) = 1*(Feed_Par{:,column_number_obj(num_ref+2)}*CPGE_ratio - Feed_Par{:,column_number_obj(num_ref+1)}); % >= 0
    A_con(length(constraints_str)+2,1:height(Feed_Par)) = 1*(Feed_Par{:,column_number_obj(num_ref+1)} - Feed_Par{:,column_number_obj(num_ref+2)}*CPGE_ratio); % >= 0
    
    model.rhs(length(constraints_str)+1) = 0;
    model.rhs(length(constraints_str)+2) = 0;
    
    %All ingredients added up need to sum up to 1
    A_con(length(constraints_str)+3,1:height(Feed_Par)) = ones(1,height(Feed_Par)); % >= 1
    A_con(length(constraints_str)+4,1:height(Feed_Par)) = (-1) * ones(1,height(Feed_Par)); % >= -1
    
    model.rhs(length(constraints_str)+3) = 1;
    model.rhs(length(constraints_str)+4) = -1;
    
    %Max content of sub-categories of ingredients
    A_con(length(constraints_str)+5,Additives) = (-1) * ones(1,length(Additives)); % >= -max additives
    A_con(length(constraints_str)+6,MineralMix_and_Salts) = (-1) * ones(1,length(MineralMix_and_Salts)); % >= -max minerals
    A_con(length(constraints_str)+7,VitaminMix) = (-1) * ones(1,length(VitaminMix)); % >= -max vitamins
    A_con(length(constraints_str)+8,AminoAcids) = (-1) * ones(1,length(AminoAcids)); % >= -max aminoacids
    
    model.rhs(length(constraints_str)+5) = -Max_additives;
    model.rhs(length(constraints_str)+6) = -Max_minerals;
    model.rhs(length(constraints_str)+7) = -Max_VitPremix;
    model.rhs(length(constraints_str)+8) = -Max_AminoAcidPremix;
    
    %States GE and CP of fish food are mean of all ingredients 
    A_con(length(constraints_str)+9,1:height(Feed_Par))     = Feed_Par{:,column_number_obj(num_ref+1)};
    A_con(length(constraints_str)+9,num_u+num_ref+1)        = -1; 
    A_con(length(constraints_str)+10,1:height(Feed_Par))    = -Feed_Par{:,column_number_obj(num_ref+1)};
    A_con(length(constraints_str)+10,num_u+num_ref+1)       = +1; 
    A_con(length(constraints_str)+11,1:height(Feed_Par))    = Feed_Par{:,column_number_obj(num_ref+2)};
    A_con(length(constraints_str)+11,num_u+num_ref+2)       = -1;
    A_con(length(constraints_str)+12,1:height(Feed_Par))    = -Feed_Par{:,column_number_obj(num_ref+2)};
    A_con(length(constraints_str)+12,num_u+num_ref+2)       = +1; 
    
    model.rhs(length(constraints_str)+9)  = 0;
    model.rhs(length(constraints_str)+10) = 0;
    model.rhs(length(constraints_str)+11) = 0;
    model.rhs(length(constraints_str)+12) = 0;

    %States DE and DP of fish food are mean of all ingredients 
    A_con(length(constraints_str)+13,1:height(Feed_Par))    = Feed_Par.(DP_ident)*Perc_to_gram;
    A_con(length(constraints_str)+13,num_u+num_ref+3)       = -1; 
    A_con(length(constraints_str)+14,1:height(Feed_Par))    = -Feed_Par.(DP_ident)*Perc_to_gram;
    A_con(length(constraints_str)+14,num_u+num_ref+3)       = +1; 
    A_con(length(constraints_str)+15,1:height(Feed_Par))    = Feed_Par.(DE_ident)/MJ_to_kcal;
    A_con(length(constraints_str)+15,num_u+num_ref+4)       = -1;
    A_con(length(constraints_str)+16,1:height(Feed_Par))    = -Feed_Par.(DE_ident)/MJ_to_kcal;
    A_con(length(constraints_str)+16,num_u+num_ref+4)       = +1; 
    
    model.rhs(length(constraints_str)+13) = 0;
    model.rhs(length(constraints_str)+14) = 0;
    model.rhs(length(constraints_str)+15) = 0;
    model.rhs(length(constraints_str)+16) = 0;
    
    con_counter = length(constraints_str)+16;
    
    %Anorganic Nutrient Content of Fish feed is mean of all ingredients
    for i = 1:num_ref
        A_con(con_counter+2*i-1,1:height(Feed_Par))     = Feed_Par{:,column_number_obj(num_ref+4+i)};
        A_con(con_counter+2*i-1,num_u+num_ref+4+i)      = -1; 
        A_con(con_counter+2*i,1:height(Feed_Par))       = -Feed_Par{:,column_number_obj(num_ref+4+i)};
        A_con(con_counter+2*i,num_u+num_ref+4+i)        = +1; 
    end
    
    model.rhs(con_counter+1:con_counter+2*num_ref) = 0;
    
    con_counter = con_counter + 2*num_ref;
    
    %Calculation of nutrient concentrations for plants
    
    %Steady-state equations:
        %c_plants,i = c_tap,i + ( m_bar_feed * ( m_i * c_feed,i + n_i ) + m_base * c_base,i + m_acid * c_acid,i ) / V_in
        %c_plants,i - (m_bar_feed * m_i * c_feed,i - m_base * M_mol,i * c_base,i - m_acid * M_mol,i * c_acid,i) / V_in = c_tap,i + m_bar_feed * n_i / V_in
    for i = 1:num_ref
    
        %c_plants,i - (m_bar_feed * m_i * c_feed,i + m_base * M_mol,i * c_base,i + m_acid * M_mol,i * c_acid,i) / V_in >= c_tap,i + m_bar_feed * n_i / V_in
        %Nutrient mass from feed
        A_con(con_counter+(2*i-1),1:height(Feed_Par))                                                   = - (param.q_feed_stat * lin_fun_m_nutrients(i) * Perc_to_gram * Feed_Par{:,column_number_obj(i)})/q;
        %Nutrient mass from base
        A_con(con_counter+(2*i-1),2*height(Feed_Par)+1:2*height(Feed_Par)+num_base)                     = - base_to_nutrient(:,i) * molar_mass_nutrients(i)/q;
        %Nutrient mass from acid
        A_con(con_counter+(2*i-1),2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid)   = - acid_to_nutrient(:,i) * molar_mass_nutrients(i)/q;
        %Resulting nutrient
        A_con(con_counter+(2*i-1),num_u+i) = 1;
    
        %- c_plants,i + (m_bar_feed * m_i * c_feed,i - m_base * M_mol,i *c_base,i - m_acid * M_mol,i * c_acid,i) / V_in >= -(c_tap,i + m_bar_feed * n_i / V_in)
        %Nutrient mass from feed
        A_con(con_counter+(2*i),1:height(Feed_Par))                                                 = (param.q_feed_stat * lin_fun_m_nutrients(i) * Perc_to_gram * Feed_Par{:,column_number_obj(i)})/q;
        %Nutrient mass from base
        A_con(con_counter+(2*i),2*height(Feed_Par)+1:2*height(Feed_Par)+num_base)                   = base_to_nutrient(:,i) * molar_mass_nutrients(i)/q;
        %Nutrient mass from acid
        A_con(con_counter+(2*i),2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid) = acid_to_nutrient(:,i) * molar_mass_nutrients(i)/q;
        %Resulting nutrient
        A_con(con_counter+(2*i),num_u+i) = -1;
    end
    
    for i = 1:num_ref
    
        %c_plants,i - (m_bar_feed * m_i * c_feed,i - m_base * M_mol,i * c_base,i - m_acid * M_mol,i * c_acid,i) / V_in >= c_tap,i + m_bar_feed * n_i / V_in
        model.rhs(con_counter+(2*i-1))  = nutrient_conc_in(i) + param.q_feed_stat * lin_fun_n_nutrients(i)/q;
    
        %- c_plants,i + (m_bar_feed * m_i * c_feed,i - m_base * M_mol,i *c_base,i - m_acid * M_mol,i * c_acid,i) / V_in >= -(c_tap,i + m_bar_feed * n_i / V_in)
        model.rhs(con_counter+(2*i))    = -nutrient_conc_in(i) -(param.q_feed_stat * lin_fun_n_nutrients(i))/q;
    
    end
    
    con_counter = con_counter + 2*num_ref;
    
    %Calculation of additional nutrient states - c_alkalinity in fish tank, TIC in fish tank and nitrogen in plant tank
    
    nitrification_rate  = 1/14.0067 * param.max_flux_ammonia * c_TAN_BF/(c_TAN_BF + param.saturation_ammonia);
    K_2_tilde           = (param.K_5)/(param.c_H_fish_ex+ param.K_5);
    
    %Alkalinity in fish tank
    %c_in,alk*q_in + m_bar,feed*c_feed,alk + m_base*c_base,alk + k_nit*rate_nitrification - c_alk,fish*q_in = 0
    %c_alk,fish - m_base*c_base,alk/q_in = c_in,alk + m_bar,feed*c_feed,alk/q_in + k_nit*rate_nitrification/q_in    
    A_con(con_counter+1,2*height(Feed_Par)+1:2*height(Feed_Par)+num_base)   = -base_to_additional_nutrients(:,1)/q;
    A_con(con_counter+1,num_u+num_ref+4+Ind_P)                              = - param.q_feed_stat * K_2_tilde * 10 * lin_fun_m_nutrients(3)/molar_mass_nutrients(3)/q;
    A_con(con_counter+1,num_u+num_x+1)                                      = 1;
    model.rhs(con_counter+1) = nutrient_add_conc_in(1) + param.q_feed_stat/q * ((8.1007 * Perc_to_gram * CPGE_ratio - 143.85)/14.0067 + K_2_tilde*lin_fun_n_nutrients(3)/molar_mass_nutrients(3)) + (-2) * nitrification_rate/q;

    A_con(con_counter+2,2*height(Feed_Par)+1:2*height(Feed_Par)+num_base)   = base_to_additional_nutrients(:,1)/q;
    A_con(con_counter+2,num_u+num_ref+4+Ind_P)                              = param.q_feed_stat * K_2_tilde * 10 * lin_fun_m_nutrients(3)/molar_mass_nutrients(3)/q;
    A_con(con_counter+2,num_u+num_x+1)                                      = -1;
    model.rhs(con_counter+2) = -1* (nutrient_add_conc_in(1) + param.q_feed_stat/q * ((8.1007 * Perc_to_gram * CPGE_ratio - 143.85)/14.0067 + K_2_tilde*lin_fun_n_nutrients(3)/molar_mass_nutrients(3)) + (-2) * nitrification_rate/q);
    
    %TIC in fish tank
    %c_in,TIC*q_in + m_bar,feed*c_feed,TIC + m_base*c_base,TIC - k_degas * (k_pH*C_TIC,fish - c_CO2,eq) - c_TIC,fish*q_in = 0
    %(q_in + k_degas*k_pH)*c_TIC,fish - m_base*c_base,TIC = q_in*c_in,TIC + m_bar,feed*c_feed,TIC + k_degas * c_CO2,eq
    A_con(con_counter+3,2*height(Feed_Par)+1:2*height(Feed_Par)+num_base)   = -base_to_additional_nutrients(:,2);
    A_con(con_counter+3,num_u+num_x+2)                                      = q + q_circ - q_circ^2/(q_circ + param.degas_coefficient * 1/(1+param.K_1/c_H_BF+param.K_1*param.K_2/c_H_BF^2));
    model.rhs(con_counter+3) = q * nutrient_add_conc_in(2) + param.q_feed_stat * 480/44.009 + q_circ * param.degas_coefficient * param.CO2_eq/(q_circ + param.degas_coefficient * 1/(1+param.K_1/c_H_BF+param.K_1*param.K_2/c_H_BF^2));

    A_con(con_counter+4,2*height(Feed_Par)+1:2*height(Feed_Par)+num_base)   = base_to_additional_nutrients(:,2);
    A_con(con_counter+4,num_u+num_x+2)                                      = -1 * (q + q_circ - q_circ^2/(q_circ + param.degas_coefficient * 1/(1+param.K_1/c_H_BF+param.K_1*param.K_2/c_H_BF^2)));
    model.rhs(con_counter+4) = -1 * (q * nutrient_add_conc_in(2) + param.q_feed_stat * 480/44.009 + q_circ * param.degas_coefficient * param.CO2_eq/(q_circ + param.degas_coefficient * 1/(1+param.K_1/c_H_BF+param.K_1*param.K_2/c_H_BF^2)));
    
    %Nitrate in plant tank
    A_con(con_counter+5,2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid) = -14.0067*acid_to_additional_nutrients(:,3)/q;
    A_con(con_counter+5,num_u+num_x+3)                                                      = 1;
    model.rhs(con_counter+5) = nutrient_add_conc_in(3) + 14.0067*nitrification_rate/q;

    A_con(con_counter+6,2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid) = 14.0067*acid_to_additional_nutrients(:,3)/q;
    A_con(con_counter+6,num_u+num_x+3)                                                      = -1;
    model.rhs(con_counter+6) = -1* (nutrient_add_conc_in(3) + 14.0067*nitrification_rate/q);
    
    con_counter = con_counter + 6;

    %pH regulation
    %pH setpoint of fish
    K_1_tilde = (param.K_1*param.c_H_fish + 2*param.K_1*param.K_2)/(param.c_H_fish^2 + param.K_1*param.c_H_fish + param.K_1*param.K_2);
    K_2_tilde = (param.K_5)/(param.c_H_fish + param.K_5);
    
    % K1_tilde*c_TIC + K_2_tilde*(c_PO4_fish-m_H3PO4/V_in) -c_alk_fish = 0
    A_con(con_counter+1,num_u+num_x+1)                  = -1; %c_alk_fish
    A_con(con_counter+1,num_u+num_x+2)                  = K_1_tilde; %c_TIC_fish
    A_con(con_counter+1,num_u+3)                        = K_2_tilde/molar_mass_nutrients(3); %c_PO4_fish
    A_con(con_counter+1,2*height(Feed_Par)+num_base+1)  = -K_2_tilde/q; %m_H3PO4
    model.rhs(con_counter+1) = 0;

    A_con(con_counter+2,length(u_opt)+length(x_opt)+1)  = 1; %c_alk_fish
    A_con(con_counter+2,length(u_opt)+length(x_opt)+2)  = -K_1_tilde; %c_TIC_fish
    A_con(con_counter+2,num_u+3)                        = -K_2_tilde/molar_mass_nutrients(3); %c_PO4_fish
    A_con(con_counter+2,2*height(Feed_Par)+num_base+1)  = K_2_tilde/q; %m_H3PO4
    model.rhs(con_counter+2) = 0;
    
    %pH setpoint of plants
    K_1_tilde = (param.K_1*param.c_H_plants + 2*param.K_1*param.K_2)/(param.c_H_plants^2 + param.K_1*param.c_H_plants + param.K_1*param.K_2);
    K_2_tilde = (param.K_5)/(param.c_H_plants + param.K_5);
    
    %K1_tilde*c_TIC + K_2_tilde*c_PO4_plants -(c_alk_fish-HCl/V_in-H3PO4/V_in-HNO3/V_in) = 0
    A_con(con_counter+3,num_u+num_x+1)                                                      = -1; %c_alk_fish
    A_con(con_counter+3,num_u+num_x+2)                                                      = K_1_tilde; %c_TIC
    A_con(con_counter+3,num_u+3)                                                            = K_2_tilde/molar_mass_nutrients(3); %c_PO4_plants
    A_con(con_counter+3,2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid) = -acid_to_additional_nutrients(:,1)/q; %acids effect on alkalinity
    model.rhs(con_counter+3) = 0;

    A_con(con_counter+4,num_u+length(x_opt)+1) = 1; %c_alk_fish
    A_con(con_counter+4,num_u+length(x_opt)+2) = -K_1_tilde; %c_TIC
    A_con(con_counter+4,num_u+3) = -K_2_tilde/molar_mass_nutrients(3); %c_PO4_plants
    A_con(con_counter+4,2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid) = +acid_to_additional_nutrients(:,1)/q; %acids effect on alkalinity
    model.rhs(con_counter+4) = 0;

    con_counter = con_counter + 4;
    
    %Constraints regarding binary variables
    bin_index = 1;
    for i = 1:height(Feed_Par)
        A_con(con_counter+2*bin_index-1,i)                          = -1;
        A_con(con_counter+2*bin_index-1,height(Feed_Par)+bin_index) = -1;
        A_con(con_counter+2*bin_index,i)                            = 1;
        A_con(con_counter+2*bin_index,height(Feed_Par)+bin_index)   = 1;
        bin_index = bin_index+1;
    end
    
    model.rhs(con_counter+1:2:con_counter+2*num_bin) = -1;
    model.rhs(con_counter+2:2:con_counter+2*num_bin) = u_feed_min;
    
    con_counter = con_counter + 2*height(Feed_Par);
    
    %Soft Constraints of buffer tank concentrations
    for i = 1:num_ref
        %Nutrient
        A_con(con_counter+i, num_u + i)                             = 1;
        A_con(con_counter+num_ref+1+i, num_u + i)                   = -1;
        %Soft constraint error
        A_con(con_counter+i, num_u + num_x + num_add + i)           = 1;
        A_con(con_counter+num_ref+1+i, num_u + num_x + num_add + i) = 1;
        %Right hand side - bounds of concentrations
        if nutrient_reference_plants(i) == 0
            model.rhs(con_counter+i) = 0;
            model.rhs(con_counter+num_ref+1+i) = -param.c_in_tap_soft_RASopt(i);
        else
            model.rhs(con_counter+i) = nutrient_reference_plants(i)*0.75;
            if strcmp(nutrients(i),"Sulfur (%)") == 1 && param.freshwater_source == 1
                model.rhs(con_counter+num_ref+1+i) = -nutrient_reference_plants(i)*1.5;
            else
                model.rhs(con_counter+num_ref+1+i) = -nutrient_reference_plants(i)*1.25;
            end
        end
    end
    
    %Soft constraints for nitrate in buffer tank
    A_con(con_counter+num_ref+1,num_u + num_x + num_add) = 1;
    A_con(con_counter+2*(num_ref+1),num_u + num_x + num_add) = -1;
    A_con(con_counter+num_ref+1,num_u + num_x + num_add + num_ref + 1) = 1;
    A_con(con_counter+2*(num_ref+1),num_u + num_x + num_add + num_ref + 1) = 1;
    model.rhs(con_counter+num_ref+1) = c_ref_NO3N*0.95;
    model.rhs(con_counter+2*(num_ref+1)) = -c_ref_NO3N*1.05;

    con_counter = con_counter + 2*(num_ref+1);
    
    % Constraint to limit number of ingredients in the feed
    A_con(con_counter+1,height(Feed_Par)+1:2*height(Feed_Par)) = 1;
    model.rhs(con_counter+1) = height(Feed_Par)-max_ing;
    
    %% Set bounds
    
    model.lb = zeros(num_u+num_x+num_add+(num_ref+1+2),1);
    %Upper bound of feed ingredients is 1
    model.ub = ones(num_u+num_x+num_add+(num_ref+1+2),1);
    
    %Other inputs (Bases, Acids) and states (Concentrations) are not constrained by upper bounds 
    model.ub(2*height(Feed_Par)+1:2*height(Feed_Par)+num_base,1)                    = inf;
    model.ub(2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid,1)  = inf; 
    model.ub(num_u+1:num_u+num_x,1)                                                 = inf;
    model.ub(num_u+1:num_u+num_ref,1)                                               = inf;
    model.ub(num_u+num_ref+1:num_u+num_ref+2,1)                                     = inf;
    model.ub(num_u+num_ref+3:num_u+num_x)                                           = inf;
    model.ub(num_u+num_x+1:end,1)                                                   = inf;
    
    %% Set objective function
    
    %Linear objective
    linear_objective = zeros(num_u+num_x+num_add+(num_ref+1+2),1);
    
    %Nutrients to be maximized in fish fed - currently no nutrients are maximized
    for i = 1:num_nut_max
        nut_max = max(Feed_Par{:,column_number_max(i)});
        linear_objective(1:height(Feed_Par)) = linear_objective(1:height(Feed_Par)) - weight_max(i) * 100000/nut_max * Feed_Par{:,column_number_max(i)};
    end

    %Minimize ecological and economic impact of nutrient management and feed + minimize risk of NaCl accumulation by minimizing dietary Na and Cl content
    if param.cost_optimization == 1
        for i = num_nut_max+1:num_nut_min+num_nut_max
            %Carbon footprint
            if strcmp(nut_min_str(i),"Global warming - Including LUC & Peat (kg CO2eq/t)") == 1
                %Bases
                linear_objective(2*height(Feed_Par)+1:2*height(Feed_Par)+num_base)                      = linear_objective(2*height(Feed_Par)+1:2*height(Feed_Par)+num_base)  + weight_min(i-num_nut_max) * carbon_per_mole_base/q;
                %Acids
                linear_objective(2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid)    = linear_objective(2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid)  + weight_min(i-num_nut_max) * carbon_per_mole_acid/q;
                %Feed
                linear_objective(1:height(Feed_Par))                                                    = linear_objective(1:height(Feed_Par)) + weight_min(i-num_nut_max) * param.q_feed_stat * Feed_Par{:,column_number_min(i-num_nut_max)}/q;
            %Carbon footprint
            elseif strcmp(nut_min_str(i),"Price in USD/kg") == 1
                %Bases
                linear_objective(2*height(Feed_Par)+1:2*height(Feed_Par)+num_base)                      = linear_objective(2*height(Feed_Par)+1:2*height(Feed_Par)+num_base)  + weight_min(i-num_nut_max) * price_per_mole_base/q;
                %Acids
                linear_objective(2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid)    = linear_objective(2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid)  + weight_min(i-num_nut_max) * price_per_mole_acid/q;
                %Feed
                linear_objective(1:height(Feed_Par))                                                    = linear_objective(1:height(Feed_Par)) + weight_min(i-num_nut_max) * param.q_feed_stat * Feed_Par{:,column_number_min(i-num_nut_max)}/q;
            %Dietary Na and Cl content
            else
                linear_objective(1:height(Feed_Par))                                                    = linear_objective(1:height(Feed_Par)) + weight_min(i-num_nut_max) * Feed_Par{:,column_number_min(i-num_nut_max)};
            end
        end
    end
    
    %Soft constraints
    for i = 1:num_ref+1+2
        if i == num_ref+3
            linear_objective(num_u+num_x+num_add+i) = w_SC/Carbon_max;
        elseif i == num_ref+2
            linear_objective(num_u+num_x+num_add+i) = w_SC/Price_max;
        elseif i == num_ref+1
            linear_objective(num_u+num_x+num_add+i) = w_SC/c_ref_NO3N;
        else
            linear_objective(num_u+num_x+num_add+i) = w_SC/max(1,nutrient_reference_plants(i));
        end
    end

    %Quadrativ objective
    quadratic_objective = zeros(num_u+num_x+num_add+num_ref+1+2,num_u+num_x+num_add+num_ref+1+2);

    %Reference tracking: (c_i - c_ref)^2 = c_i^2 - 2c_i*c_ref + c_ref^2
    for i = 1:num_ref
        quadratic_objective(num_u+i,num_u+i)    = weight_reference(i)/num_ref;
        linear_objective(num_u+i)               = - 2 * weight_reference(i) * nutrient_reference_plants(i)/num_ref;
    end
    
    %Reference ratio tracking: (c_i - k*c_j)^2 = c_i^2 - 2*k*c_i*c_j + k^2*c_j^2   
    
    %Ca/P ratio
    quadratic_objective(num_u+num_ref+4+Ind_P,num_u+num_ref+4+Ind_P)    = w_CaP * Ca_P_ratio^2; 
    quadratic_objective(num_u+num_ref+4+Ind_P,num_u+num_ref+4+Ind_Ca)   = - w_CaP * Ca_P_ratio; 
    quadratic_objective(num_u+num_ref+4+Ind_Ca,num_u+num_ref+4+Ind_P)   = - w_CaP * Ca_P_ratio;
    quadratic_objective(num_u+num_ref+4+Ind_Ca,num_u+num_ref+4+Ind_Ca)  = w_CaP;
    
    %DP/DE ratio
    quadratic_objective(num_u+num_ref+3,num_u+num_ref+3)                = w_DPDE;
    quadratic_objective(num_u+num_ref+3,num_u+num_ref+4)                = - w_DPDE * DP_DE_ratio;
    quadratic_objective(num_u+num_ref+4,num_u+num_ref+3)                = - w_DPDE * DP_DE_ratio;
    quadratic_objective(num_u+num_ref+4,num_u+num_ref+4)                = w_DPDE * DP_DE_ratio^2;

    %P_feed
    quadratic_objective(num_u+num_ref+4+Ind_P,num_u+num_ref+4+Ind_P)    = w_P_feed;
    linear_objective(num_u+num_ref+4+Ind_P)                             = - 2* P_feed_setpoint*w_P_feed;
    
    %Nitrate in BT
    quadratic_objective(num_u+num_x+3,num_u+num_x+3)                    = 1/(c_ref_NO3N^2)  * w_NO3N;
    linear_objective(num_u+num_x+3)                                     = - 1/(c_ref_NO3N^2) * w_NO3N * c_ref_NO3N * 2;
     
    %% Solve optimization problem with gurobi
    
    %Constraints in gurobi model
    model.A = sparse(A_con);
    model.sense = '>';

    %Linear objective in gurobi model
    model.obj = linear_objective;
    
    %Quadratic objective in gurobi model
    model.Q = sparse(quadratic_objective);
    
    %Solver parameters
    params                  = struct;
    params.NumericFocus     = 3;
    params.MIPGap           = 1e-8;
    params.FeasibilityTol   = 1e-9;
    
    %Solve
    solution = gurobi(model, params);
    
    %Get solution
    sol      = solution.x;
    
    %Reconstruction of objective function value, because gurobi changes the problem in the presolve step
    J = 0;
    for i = 1:num_ref
        J = J + weight_reference(i)/num_ref * (sol(num_u+i) - nutrient_reference_plants(i))^2;
    end
    if param.cost_optimization == 1
        for i = num_nut_max+1:num_nut_min+num_nut_max
            if strcmp(nut_min_str(i),"Global warming - Including LUC & Peat (kg CO2eq/t)")==1
                J = J + weight_min(i-num_nut_max) * carbon_per_mole_base'*sol(2*height(Feed_Par)+1:2*height(Feed_Par)+num_base)/q;
                J = J + weight_min(i-num_nut_max) * carbon_per_mole_acid'*sol(2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid)/q;
                J = J + weight_min(i-num_nut_max) * Feed_Par{:,column_number_min(i-num_nut_max)}'* param.q_feed_stat *sol(1:height(Feed_Par))/q;
            elseif strcmp(nut_min_str(i),"Price in USD/kg")==1
                J = J + weight_min(i-num_nut_max) * price_per_mole_base'*sol(2*height(Feed_Par)+1:2*height(Feed_Par)+num_base)/q;
                J = J + weight_min(i-num_nut_max) * price_per_mole_acid'*sol(2*height(Feed_Par)+num_base+1:2*height(Feed_Par)+num_base+num_acid)/q;
                J = J + weight_min(i-num_nut_max) * Feed_Par{:,column_number_min(i-num_nut_max)}'* param.q_feed_stat *sol(1:height(Feed_Par))/q;
            else
                J = J + weight_min(i-num_nut_max) * Feed_Par{:,column_number_min(i-num_nut_max)}'*sol(1:height(Feed_Par));
            end
        end
    end
    J = J + 1/(c_ref_NO3N^2) * w_NO3N * (sol(num_u+num_x+3)-c_ref_NO3N)^2;

    for i = 1:num_ref+3
        if i==num_ref + 3
            J = J + w_SC*sol(num_u+num_x+num_add+i)/Carbon_max;
        elseif i==num_ref + 2
            J = J + w_SC*sol(num_u+num_x+num_add+i)/Price_max;
        elseif i==num_ref + 1
            J = J + w_SC*sol(num_u+num_x+num_add+i)/c_ref_NO3N;
        else
            J = J + w_SC*sol(num_u+num_x+num_add+i)/max(1,nutrient_reference_plants(i));
        end
    end
    
    %Added soft constraint for DPDE_Ratio
    DPDE_ratio = (sol(1:height(Feed_Par))'*Feed_Par.("Dig CP -fish (%)"))/(sol(1:height(Feed_Par))'*Feed_Par.("Dig GE (DE) - fish (kcal)"))*MJ_to_kcal*Perc_to_gram;
    if DPDE_ratio > 1.01*DP_DE_ratio
        J = J + 100* 10000*(1.01*DP_DE_ratio-DPDE_ratio)^2/(1.01*DP_DE_ratio);
    end
    if DPDE_ratio < 0.99*DP_DE_ratio
        J = J + 100* 10000*(0.99*DP_DE_ratio-DPDE_ratio)^2/(0.99*DP_DE_ratio);
    end

    %% Evalution and visualization of the optimization results
    
    if(plot_solution == 1)
        %Get optimization variables
        u_sol = solution.x;

        %Some dietary properties before rounding fractions of ingredients
        DP_DE_ratio = (u_sol(1:height(Feed_Par))'*Feed_Par.("Dig CP -fish (%)"))/(u_sol(1:height(Feed_Par))'*Feed_Par.("Dig GE (DE) - fish (kcal)"))*MJ_to_kcal*Perc_to_gram
        CP_GE_ratio = (u_sol(1:height(Feed_Par))'*Feed_Par.("Crude  Protein (%)"))/(u_sol(1:height(Feed_Par))'*Feed_Par.("Gross Energy -MJ (MJ/kg)"))*Perc_to_gram
        Ca          = (u_sol(1:height(Feed_Par))'*Feed_Par.("Calcium (%)"))
        PO          = u_sol(1:height(Feed_Par))'*Feed_Par.("Phosphorus (%)") 
        Ca_PO_ratio = (u_sol(1:height(Feed_Par))'*Feed_Par.("Calcium (%)"))/(u_sol(1:height(Feed_Par))'*Feed_Par.("Phosphorus (%)"))
        
        %Processing the solution
        u_sol(u_sol<0)      =0;
        u_sol_raw           = u_sol;
        u_sol               = ceil(u_sol*10000)/10000;
        for i = 1:height(Feed_Par)
            if u_sol(i)<0.00099
                u_sol(i)    =0;
            end
            if u_sol(i)>=0.00099 && u_sol(i)<0.001
                u_sol(i)    =0.001;
            end
        end
        sum_of_u                    = sum(u_sol(1:height(Feed_Par)));
        [max_val,ind_val]           = max(u_sol(1:height(Feed_Par)));
        u_sol(ind_val)              = max_val - (sum_of_u-1);
        check_if_correct_eliminated = sum(u_sol(1:height(Feed_Par)));

        %Some dietary properties before rounding fractions of ingredients
        DP_DE_ratio = (u_sol(1:height(Feed_Par))'*Feed_Par.("Dig CP -fish (%)"))/(u_sol(1:height(Feed_Par))'*Feed_Par.("Dig GE (DE) - fish (kcal)"))*239.006*10
        CP_GE_ratio = (u_sol(1:height(Feed_Par))'*Feed_Par.("Crude  Protein (%)"))/(u_sol(1:height(Feed_Par))'*Feed_Par.("Gross Energy -MJ (MJ/kg)"))*10
        Ca_PO_ratio = (u_sol(1:height(Feed_Par))'*Feed_Par.("Calcium (%)"))/(u_sol(1:height(Feed_Par))'*Feed_Par.("Phosphorus (%)"))

        %Plot the chosen ingredients
        ing_ind = find(u_sol(1:height(Feed_Par)));
        ing_use = nonzeros(u_sol(1:height(Feed_Par)));
        ing     = string(Feed_Par{ing_ind,2});
        figure(1)
        b1      = bar(1:length(ing_use),100 * ing_use);
        xtips1  = b1.XEndPoints;
        ytips1  = b1.YEndPoints;
        labels1 = string(b1.YData);
        text(xtips1,ytips1,labels1,'HorizontalAlignment','center','VerticalAlignment','bottom')
        xticks(1:1:length(ing_use))
        xticklabels(ing);
        grid on
        ylabel('Content of Ingredient in whole diet in %','FontSize',13)
        title('Ingredients used for the formulation of the fish diet','FontSize',13)
        ylim([0 50])
    
        %Calculate the resulting mineral nutrients in the feed
        opt_results = zeros(num_nut_max*2+1,1);
    
        for i = 1:num_ref
            nut_avg             = sum(Feed_Par{:,column_number_obj(i)})/height(Feed_Par);
            nut_max             = max(Feed_Par{:,column_number_obj(i)});
            opt_results(i*2-1)  = nut_avg;
            res_cont_nut_sol    = u_sol(1:height(Feed_Par))'*Feed_Par{:,column_number_obj(i)};
            opt_results(i*2)    = res_cont_nut_sol;
        end
    
        %Plot optimization results governed by the objective function    
        nut_str             = strings(2*length(nutrients),1);
        for i=1:length(nutrients)
            nut_str(2*i)    = nutrients(i);
            nut_str(2*i-1)  = strcat(nutrients(i)," - avg");
        end
        figure(2)
        b2      = bar(round(opt_results,2));
        xtips2  = b2.XEndPoints;
        ytips2  = b2.YEndPoints;
        labels2 = string(b2.YData);
        text(xtips2,ytips2,labels2,'HorizontalAlignment','center','VerticalAlignment','bottom')
        xticks(1:length(opt_results(1:end)))
        xticklabels(nut_str)
        grid on
        ylabel('Nutrient Content in % (equals 10g/kg)','FontSize',13)
        title('Nutrient Composition of the formulated fish diet - Nutrients that are important for plants','FontSize',13)
    
        %Check if the constraints are fullfiled by the processed solution
        results_constr          = zeros(length(constraints_str));
        for i=1:length(constraints_str)
             par                =Feed_Par{:,column_number_constr(i)};    
             results_constr(i)  =u_sol(1:height(Feed_Par))'*par;
        end
    
        num_constr_max = 0;
        num_constr_min = 0;
    
        for i = 1:length(constraints_str)
            if strcmp(constraint_bounds.("Restriction Type")(row_constraints(i)),'Maximum')==1
               num_constr_max                   = num_constr_max+1;
               res_constr_max(num_constr_max)   = results_constr(i)/constraint_bounds.("Value")(row_constraints(i));
            end
            if strcmp(constraint_bounds.("Restriction Type")(row_constraints(i)),'Minimum')==1
               num_constr_min                   = num_constr_min+1;
               res_constr_min(num_constr_min)   = results_constr(i)/constraint_bounds.("Value")(row_constraints(i));       
            end
        end
    
        str_max = strings(num_constr_max,1);
        str_min = strings(num_constr_min,1); 
        num_constr_max = 0;
        num_constr_min = 0;
        for i = 1:length(constraints_str)
            if strcmp(constraint_bounds.("Restriction Type")(row_constraints(i)),'Maximum')==1
               num_constr_max           = num_constr_max+1;
               str_max(num_constr_max)  = constraints_str(i);
            end
            if strcmp(constraint_bounds.("Restriction Type")(row_constraints(i)),'Minimum')==1
               num_constr_min           = num_constr_min+1;
               str_min(num_constr_min)  = constraints_str(i);   
            end
        end
    
        %Plot constraints
        figure(3)
        subplot(2,1,1)
        bar(100 * res_constr_max)
        hold on 
        plot(0:(length(res_constr_max)+1),100*ones(length(res_constr_max)+2,1),'-.','Color',[1 0 0 1],'LineWidth',1.5)
        xticks(1:length(res_constr_max))
        xticklabels(str_max)
        grid on
        ylabel({'Nutrient Content normalized';'by upper bound in %'},'FontSize',13)
        title('Content of Nutrients in formulated fish diet that are constrained by an upper bound','FontSize',13)
        ylim([0 120])
        legend({'Nutrient content','allowed maximum content'},'Location','northwest')
        subplot(2,1,2)
        bar(100 * res_constr_min)
        hold on 
        plot(0:(length(res_constr_min)+1),100*ones(length(res_constr_min)+2,1),'-.','Color',[1 0 0 1],'LineWidth',1.5)
        xticks(1:length(res_constr_min))
        xticklabels(str_min)
        ylim([0 200])
        grid on
        ylabel({'Nutrient Content normalized';'by lower bound in %'},'FontSize',13)
        title('Content of Nutrients in formulated fish diet that are constrained by a lower bound','FontSize',13)
        legend({'Nutrient content','allowed minimum content'},'Location','northwest')
        
        %Plot nutrient concentrations in BT (without nitrate)
        figure(4)
        b3 = bar(u_sol(num_u+1:num_u+num_ref));
        xtips3 = b3.XEndPoints;
        ytips3 = b3.YEndPoints;
        labels3 = string(b3.YData);
        text(xtips3,ytips3,labels3,'HorizontalAlignment','center','VerticalAlignment','bottom')
        xticks(1:num_ref)
        xticklabels(nutrients)
        grid on
        ylabel('Concentrations in mg/L','FontSize',13)
        title('Nutrient Concentrations in plant water','FontSize',13)
        
        %Plot consumption of acids and bases
        figure(5)
        b4 = bar(u_sol(2*height(Feed_Par)+1:2*height(Feed_Par)+num_base+num_acid));
        xtips4 = b4.XEndPoints;
        ytips4 = b4.YEndPoints;
        labels4 = string(b4.YData);
        text(xtips4,ytips4,labels4,'HorizontalAlignment','center','VerticalAlignment','bottom')
        xticks(1:num_base+num_acid)
        xticklabels([base_identifiers;acid_identifiers])
        grid on
        ylabel('Material use in mol','FontSize',13)
        title('Use of bases and acids','FontSize',13)
    end
    
end