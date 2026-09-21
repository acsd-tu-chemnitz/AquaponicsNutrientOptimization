function [P_max] = fish_diet_maximization_P(Feed_Par,constraint_bounds,param,CPGE_min,CPGE_max)   
    %% Parameters

    MJ_to_kcal       = 239.006;
    Ca_P_ratio       = 1.33;
    
    %% Preparations for Constraints - map columns of FICD to nutrient requirements in ASNS
    
    Additives = [566:568 572:height(Feed_Par)];
    MineralMix_and_Salts = [648:686 699 700 702 703]';
    VitaminMix = [572:617 618]';
    AminoAcids = [619:647 682:698 701 703]';
    
    Feed_Par_ident = string(Feed_Par.Properties.VariableNames)';
    row_constraints = zeros(height(constraint_bounds),1);
    constraints_str = strings(height(constraint_bounds),2); 
    
    ind_constr=1;
    for i = 1:height(constraint_bounds)  
        if(~isnan(constraint_bounds.("Value")(i)) && (strcmp(constraint_bounds.("Restriction Type")(i),'Minimum')==1 || strcmp(constraint_bounds.("Restriction Type")(i),'Maximum')==1))      
            constraints_str(ind_constr,1) = string(constraint_bounds.("Specification")(i));
            constraints_str(ind_constr,2) = string(constraint_bounds.("Restriction Type")(i));
            row_constraints(ind_constr)=i;
            ind_constr=ind_constr + 1;
        end
    end
    row_constraints = row_constraints(1:ind_constr-1,1);
    constraints_str = constraints_str(1:ind_constr-1,:);
    for i = 1:length(constraints_str)
        if contains(constraints_str(i,1),'Fumonicin')==1
            constraints_str(i,1) = 'Fumonisin (FUM)';
        end
    end
    
    column_number_constr=zeros(length(constraints_str),1);
    no_inds_constr = 1:length(constraints_str);
    num_match = 0;
    for i = 1:length(constraints_str)
        for j = 1:length(Feed_Par_ident)
            if contains(Feed_Par_ident(j),erase(constraints_str(i)," "))==1
                column_number_constr(i)=j;
                no_inds_constr(i-num_match)=[];
                num_match = num_match +1;
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
    
    DP_ident = "Dig CP -fish (%)";
    DE_ident = "Dig GE (DE) - fish (kcal)";
    CP_ident = "Crude  Protein (%)";
    GE_ident = "Gross Energy -MJ (MJ/kg)";
    
    for i=1:length(constraints_str)
        if((strcmp(constraint_bounds.("Restriction Type")(i),'Ratio')==1 || strcmp(constraint_bounds.("Restriction Type")(i),'ratio')==1) && ~isnan(constraint_bounds.("Value")(i)))
            if strcmp(constraint_bounds.("Unit")(i),"g/MJ")==1
                DP_DE_ratio=constraint_bounds.("Value")(i)/MJ_to_kcal;
            end
            if strcmp(constraint_bounds.("Unit")(i),"g/kcal")==1
                DP_DE_ratio=constraint_bounds.("Value")(i);
            end
        end
    end
    
    % upper and lower bounds of DPDE ratio
    ratio_max = DP_DE_ratio/10*1.01;
    ratio_min = DP_DE_ratio/10*0.99;
    
    % Identify column of DP, DE, CP and GE in FICD - belong ratios that are affected by constraints
    ratio_par_column_ident = [DP_ident; DE_ident; CP_ident; GE_ident];
    column_number_ratio_const = zeros(length(ratio_par_column_ident),1);
    
    for i = 1:length(ratio_par_column_ident)
        for j = 1:length(Feed_Par_ident)
            if contains(Feed_Par_ident(j),ratio_par_column_ident(i))==1
                column_number_ratio_const(i)=j;
                break
            end
        end   
    end
    
    %% Preparations for Objective Function
    
    % Dietary nutrient contents to maximized
    nut_max_str = ["Potassium (%)";"Magnesium (%)";"Phosphorus (%)";"Calcium (%)"];
    weight_max = [0;0;100;0];
    num_nut_max = length(nut_max_str);
    
    % Find column of nutrients that are to be maximized
    column_number_max = zeros(length(nut_max_str),1);
    for i = 1:length(nut_max_str)
        for j = 1:length(Feed_Par_ident)
            if contains(Feed_Par_ident(j),nut_max_str(i))==1
                column_number_max(i)=j;
                break
            end
        end   
    end
    
    % Dietary nutrient contents to minimized + Price and Carbon Footprint of feed
    nut_min_str = ["Sodium (%)"; "Chlorine (%)";"Price in USD/kg";"Global warming - Including LUC & Peat (kg CO2eq/t)";"Zeralenone (ZON)"];
    weight_min = [0;0;0;0;0];
    num_nut_min = length(nut_min_str);
    
    column_number_min = zeros(length(nut_min_str),1);
    for i = 1:length(nut_min_str)
        for j = 1:length(Feed_Par_ident)
            if contains(Feed_Par_ident(j),nut_min_str(i))==1
                column_number_min(i)=j;
                break
            end
        end   
    end
    
    % Identify column of Ca, PO4-P, CP and GE in FICD - ratios that are affected by quadratic terms in the objective function
    DP_ident = "Dig CP -fish (%)";
    DE_ident = "Dig GE (DE) - fish"; 
    
    obj_par_column_ident = ["Phosphorus (%)";"Calcium (%)"; DP_ident; DE_ident];
    column_number_obj = zeros(length(obj_par_column_ident),1);
    
    for i = 1:length(obj_par_column_ident)
        for j = 1:length(Feed_Par_ident)
            if contains(Feed_Par_ident(j),obj_par_column_ident(i))==1
                column_number_obj(i)=j;
                break
            end
        end   
    end
    
    %% Preparations for Binary Variables
    
    num_bin = height(Feed_Par);
    
    %% Set Optimization Variables
    
    u_opt = strings(height(Feed_Par)+num_bin,1);
    x_opt = [Feed_Par_ident(column_number_ratio_const(1));Feed_Par_ident(column_number_ratio_const(2));Feed_Par_ident(column_number_ratio_const(3));Feed_Par_ident(column_number_ratio_const(4));Feed_Par_ident(column_number_obj(1));Feed_Par_ident(column_number_obj(2))];
    for i = 1:height(Feed_Par)
        u_opt(i) = strcat('u_opt_',num2str(i));
    end
    for i = height(Feed_Par)+1:length(u_opt)
        u_opt(i) = strcat('y_opt_',num2str(i-height(Feed_Par)));
    end
    model.varnames = cellstr([u_opt;x_opt]);
    
    vartypes = strings(height(Feed_Par)+num_bin,1);
    for i = 1:height(Feed_Par)
        vartypes(i)="C";
    end
    for i = height(Feed_Par)+1:length(vartypes)
        vartypes(i)="I";
    end
    vartypes_x = strings(length(x_opt),1);
    for i = 1:length(x_opt)
        vartypes_x(i)="C";
    end
    model.vtype = char([vartypes;vartypes_x]);
    
    %% Set Constraints
    
    % Limits given in ASNS
    A_con = zeros(2*num_bin+length(constraints_str)+16+1,height(Feed_Par)+num_bin+4);
    model.rhs = zeros(2*num_bin+length(constraints_str)+16+1,1);
    for i=1:length(constraints_str)
        par=Feed_Par{:,column_number_constr(i)};
        if(strcmp(constraints_str(i,2),"Minimum")==1)
            A_con(i,1:height(Feed_Par))=par'; % >= min content
        else
            A_con(i,1:height(Feed_Par))=(-1)*par'; % >= (-1) * max content
        end
    end
    for i = 1:length(constraints_str)
        if strcmp(constraint_bounds.("Restriction Type")(row_constraints(i)),'Maximum')==1
            model.rhs(i)= (-1) * 0.99 * constraint_bounds.("Value")(row_constraints(i));
        end
        if strcmp(constraint_bounds.("Restriction Type")(row_constraints(i)),'Minimum')==1
            model.rhs(i) = constraint_bounds.("Value")(row_constraints(i));
        end
    end
    con_counter = length(constraints_str);
    
    % DPDE and CPGE-Ratio Limits
    
    A_con(con_counter+1,1:height(Feed_Par)) = Feed_Par.("Crude  Protein (%)")' - CPGE_min*Feed_Par.("Gross Energy -MJ (MJ/kg)")';
    A_con(con_counter+2,1:height(Feed_Par)) = - Feed_Par.("Crude  Protein (%)")' + CPGE_max*Feed_Par.("Gross Energy -MJ (MJ/kg)")';
    A_con(con_counter+3,1:height(Feed_Par)) = Feed_Par{:,column_number_ratio_const(2)}*ratio_max-Feed_Par{:,column_number_ratio_const(1)}; % >= 0
    A_con(con_counter+4,1:height(Feed_Par)) = Feed_Par{:,column_number_ratio_const(1)}-Feed_Par{:,column_number_ratio_const(2)}*ratio_min; % >= 0
    model.rhs(con_counter+1:con_counter+4) = 0;
    
    con_counter = con_counter + 4;
    
    % All ingredients fraction sum up to 1
    A_con(con_counter+1,1:height(Feed_Par)) = ones(1,height(Feed_Par)); % >= 1
    A_con(con_counter+2,1:height(Feed_Par)) = (-1) * ones(1,height(Feed_Par)); % >= -1
    model.rhs(con_counter+1) = 1;
    model.rhs(con_counter+2) = -1;
    
    % Maximum fraction of specified ingredient classes
    A_con(con_counter+3,Additives) = (-1) * ones(1,length(Additives)); % >= -max additives
    A_con(con_counter+4,MineralMix_and_Salts) = (-1) * ones(1,length(MineralMix_and_Salts)); % >= -max minerals
    A_con(con_counter+5,VitaminMix) = (-1) * ones(1,length(VitaminMix)); % >= -max vitamins
    A_con(con_counter+6,AminoAcids) = (-1) * ones(1,length(AminoAcids)); % >= -max aminoacids
    model.rhs(con_counter+3) = -0.05;
    model.rhs(con_counter+4) = 0;
    model.rhs(con_counter+5) = -0.01;
    model.rhs(con_counter+6) = -0.01;
    
    % Equality constraints for the initialization of additional optimization variable, which occur in quadratic objective terms --> keep Q as sparse as possible
    A_con(con_counter+7,1:height(Feed_Par)) = Feed_Par{:,column_number_ratio_const(3)};
    A_con(con_counter+7,2*height(Feed_Par)+3) = -1; 
    A_con(con_counter+8,1:height(Feed_Par)) = -Feed_Par{:,column_number_ratio_const(3)};
    A_con(con_counter+8,2*height(Feed_Par)+3) = +1; 
    A_con(con_counter+9,1:height(Feed_Par)) = Feed_Par{:,column_number_ratio_const(4)};
    A_con(con_counter+9,2*height(Feed_Par)+4) = -1; 
    A_con(con_counter+10,1:height(Feed_Par)) = -Feed_Par{:,column_number_ratio_const(4)};
    A_con(con_counter+10,2*height(Feed_Par)+4) = +1; 
    A_con(con_counter+11,1:height(Feed_Par)) = Feed_Par{:,column_number_obj(1)};
    A_con(con_counter+11,2*height(Feed_Par)+5) = -1; 
    A_con(con_counter+12,1:height(Feed_Par)) = -Feed_Par{:,column_number_obj(1)};
    A_con(con_counter+12,2*height(Feed_Par)+5) = +1; 
    A_con(con_counter+13,1:height(Feed_Par)) = Feed_Par{:,column_number_obj(2)};
    A_con(con_counter+13,2*height(Feed_Par)+6) = -1; 
    A_con(con_counter+14,1:height(Feed_Par)) = -Feed_Par{:,column_number_obj(2)};
    A_con(con_counter+14,2*height(Feed_Par)+6) = +1; 
    model.rhs(con_counter+7) = 0;
    model.rhs(con_counter+8) = 0;
    model.rhs(con_counter+9) = 0;
    model.rhs(con_counter+10) = 0;
    model.rhs(con_counter+11) = 0;
    model.rhs(con_counter+12) = 0;
    model.rhs(con_counter+13) = 0;
    model.rhs(con_counter+14) = 0;
    
    con_counter = con_counter + 14;
    
    % Binary constraints
    bin_index = 1;
    for i = 1:height(Feed_Par)
        A_con(con_counter+2*bin_index-1,i) = -1;
        A_con(con_counter+2*bin_index-1,height(Feed_Par)+bin_index) = -1;
        A_con(con_counter+2*bin_index,i) = 1;
        A_con(con_counter+2*bin_index,height(Feed_Par)+bin_index) = 1;
        bin_index = bin_index+1;
    end
    model.rhs(con_counter+1:2:con_counter+2*height(Feed_Par)) = -1;
    model.rhs(con_counter+2:2:con_counter+2*height(Feed_Par)) = 0.001;
    con_counter = con_counter + 2*height(Feed_Par);
    
    % Maximum number of ingredients
    A_con(con_counter+1,height(Feed_Par)+1:2*height(Feed_Par)) = 1;
    model.rhs(con_counter+1) = height(Feed_Par)-20;
    
    model.A = sparse(A_con);
    model.sense = '>';
    %% Set Bounds
    
    model.lb = zeros(height(Feed_Par)+num_bin+length(x_opt),1);
    model.ub = ones(height(Feed_Par)+num_bin+length(x_opt),1); 
    model.ub(2*height(Feed_Par)+1:end,1) = inf; 
    
    %% Set Objective Function
    
    % Initialize linear and quadratic objective
    linear_objective = zeros(length(u_opt)+length(x_opt),1);
    quadratic_objective = zeros(length(u_opt)+length(x_opt),length(u_opt)+length(x_opt));
    
    % Dietary nutrients to be maximized
    nut_max = 0;
    for i = 1:num_nut_max
        if model.rhs(length(constraints_str)+6,1)==0
            for j = 1:height(Feed_Par)
                if Feed_Par{j ,column_number_max(i)}>= nut_max && ~ismember(j,MineralMix_and_Salts)
                    nut_max = Feed_Par{j ,column_number_max(i)};
                end
            end
        else
            nut_max = max(Feed_Par{:,column_number_max(i)});
        end
        linear_objective(1:height(Feed_Par)) = linear_objective(1:height(Feed_Par)) - weight_max(i) * 100/nut_max * Feed_Par{:,column_number_max(i)};
    end
    
    % Dietary nutrients and other properties to be minimized
    nut_avg = 0;
    for i = 1:num_nut_min
        if model.rhs(length(constraints_str)+6,1)==0
            for j = 1:height(Feed_Par)
                if ~ismember(j,MineralMix_and_Salts)
                    nut_avg = nut_avg + Feed_Par{j ,column_number_min(i)};
                end
            end
            nut_avg = nut_avg/(height(Feed_Par)-length(MineralMix_and_Salts));
        else
            nut_avg = sum(Feed_Par{:,column_number_min(i)})/height(Feed_Par);
        end
        linear_objective(1:height(Feed_Par)) = linear_objective(1:height(Feed_Par)) + weight_min(i) * 100/nut_avg * Feed_Par{:,column_number_min(i)};
    end
    
    % Tracking of CaPO ratio
    quadratic_objective(2*height(Feed_Par)+5,2*height(Feed_Par)+5) = 10000/(Ca_P_ratio)^2 * Ca_P_ratio^2;
    quadratic_objective(2*height(Feed_Par)+5,2*height(Feed_Par)+6) = 10000/(Ca_P_ratio)^2 * (-1)*Ca_P_ratio;
    quadratic_objective(2*height(Feed_Par)+6,2*height(Feed_Par)+5) = 10000/(Ca_P_ratio)^2 * (-1)*Ca_P_ratio;
    quadratic_objective(2*height(Feed_Par)+6,2*height(Feed_Par)+6) = 10000/(Ca_P_ratio)^2;
    
    model.obj = linear_objective;
    model.Q = sparse(quadratic_objective);
    
    %% Solve Optimization Problem with Gurobi
    params = struct;
    params.NumericFocus = 3;
    params.MIPGap = 1e-8;
    params.FeasibilityTol = 1e-9;
    
    solution = gurobi(model);

    u_sol = solution.x;

    P_max = u_sol(1:height(Feed_Par))'*Feed_Par{:,column_number_max(3)};

end
