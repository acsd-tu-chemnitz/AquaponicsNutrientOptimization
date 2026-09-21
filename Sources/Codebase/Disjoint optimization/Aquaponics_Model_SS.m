function xdot = Aquaponics_Model_SS(x,u,param) 
    
    xdot   = casadi.SX.zeros(param.number_of_states,1);
    
    INDEX = param.INDEX;
    u_in_FT = u(INDEX.u_in_FT_tap);
    u_circ_BF = u(INDEX.u_circ_BF);
    u_degas = u(INDEX.u_degas_coeff);

    c_ammonium_BF = x(INDEX.x_c_BF.Total_Ammonium);
    c_CO2         = x(INDEX.x_c_BF.Total_Carbon)*x(INDEX.x_c_BF.Hydrogen)^2/(x(INDEX.x_c_BF.Hydrogen)^2 + param.K_1*x(INDEX.x_c_BF.Hydrogen) + param.K_1*param.K_2);
    nitrification_rate = param.max_flux_ammonia * c_ammonium_BF/(param.saturation_ammonia + c_ammonium_BF);

    for i = 1:param.number_of_nutrients
        
        % Fish tank dynamics
        if(param.is_set_by_feed_content(i) == 1)            
            xdot(INDEX.x_c_FT.(param.nutrient_identifiers(i))) = 1/(param.V_FT+param.V_BF) * ( param.c_in(i) * u_in_FT + param.Feed_to_Nut(i,1) * param.q_feed_stat +  param.base_to_nutrient(i,:) * u(INDEX.u_Base.(param.base_identifiers(1)):INDEX.u_Base.(param.base_identifiers(end))) -u_in_FT * x(INDEX.x_c_FT.(param.nutrient_identifiers(i))));
        elseif(strcmp(param.nutrient_identifiers(i),"Total_Carbon")==1)
            xdot(INDEX.x_c_FT.(param.nutrient_identifiers(i))) = 1/(param.V_FT) * ( param.c_in(i) * u_in_FT + x(INDEX.x_c_BF.("Total_Carbon"))*u_circ_BF + param.Feed_to_Nut(i,1) * param.q_feed_stat - x(INDEX.x_c_FT.("Total_Carbon"))*u_in_FT - x(INDEX.x_c_FT.("Total_Carbon"))*u_circ_BF );
        elseif(strcmp(param.nutrient_identifiers(i),"Alkalinity")==1)
            xdot(INDEX.x_c_FT.(param.nutrient_identifiers(i))) = 1/param.V_FT * ( param.c_in(i) * u_in_FT +  param.Feed_to_Nut(i,1) * param.q_feed_stat + param.base_to_nutrient(i,:) * u(INDEX.u_Base.(param.base_identifiers(1)):INDEX.u_Base.(param.base_identifiers(end))) + u_circ_BF * x(INDEX.x_c_BF.(param.nutrient_identifiers(i)))  ...
                                                             - u_circ_BF * x(INDEX.x_c_FT.(param.nutrient_identifiers(i))) -u_in_FT * x(INDEX.x_c_FT.(param.nutrient_identifiers(i)))); 
        elseif(strcmp(param.nutrient_identifiers(i),"Sodium")==1 || strcmp(param.nutrient_identifiers(i),"Chloride")==1)    
            xdot(INDEX.x_c_FT.(param.nutrient_identifiers(i))) = 1/(param.V_FT+param.V_BF) * ( param.c_in(i) * u_in_FT +  param.base_to_nutrient(i,:) * u(INDEX.u_Base.(param.base_identifiers(1)):INDEX.u_Base.(param.base_identifiers(end))) -u_in_FT * x(INDEX.x_c_FT.(param.nutrient_identifiers(i))));
        elseif(strcmp(param.nutrient_identifiers(i),"Hydrogen")~=1)
            xdot(INDEX.x_c_FT.(param.nutrient_identifiers(i))) = 1/param.V_FT * ( param.c_in(i) * u_in_FT +  param.Feed_to_Nut(i,1) * param.q_feed_stat + u_circ_BF * x(INDEX.x_c_BF.(param.nutrient_identifiers(i))) +  param.base_to_nutrient(i,:) * u(INDEX.u_Base.(param.base_identifiers(1)):INDEX.u_Base.(param.base_identifiers(end))) ...
                                                             - u_circ_BF * x(INDEX.x_c_FT.(param.nutrient_identifiers(i))) - u_in_FT * x(INDEX.x_c_FT.(param.nutrient_identifiers(i))) );       
        end
        
        % Biofilter dynamics
        if (param.affected_by_nitrification(i) == 1)
            if(strcmp(param.nutrient_identifiers(i),"Alkalinity")==1) 
                xdot(INDEX.x_c_BF.(param.nutrient_identifiers(i))) = 1/param.V_BF * ( x(INDEX.x_c_FT.(param.nutrient_identifiers(i))) * u_circ_BF + param.nitrification_effect(i) * nitrification_rate - x(INDEX.x_c_BF.(param.nutrient_identifiers(i))) * u_circ_BF);
            elseif(strcmp(param.nutrient_identifiers(i),"Total_Carbon")==1) 
                xdot(INDEX.x_c_BF.(param.nutrient_identifiers(i))) = 1/param.V_BF * ( x(INDEX.x_c_FT.(param.nutrient_identifiers(i))) * u_circ_BF - u_degas * (c_CO2-param.CO2_eq) - x(INDEX.x_c_BF.(param.nutrient_identifiers(i))) * u_circ_BF);
            elseif(strcmp(param.nutrient_identifiers(i),"Hydrogen")~=1)
                xdot(INDEX.x_c_BF.(param.nutrient_identifiers(i))) = 1/param.V_BF * ( x(INDEX.x_c_FT.(param.nutrient_identifiers(i))) * u_circ_BF + param.nitrification_effect(i) * nitrification_rate - x(INDEX.x_c_BF.(param.nutrient_identifiers(i))) * u_circ_BF);
            end
        end

        % Buffer Tank dynamics
        if (strcmp(param.nutrient_identifiers(i),"Hydrogen")~=1 && strcmp(param.nutrient_identifiers(i),"Chloride")~=1)
            xdot(INDEX.x_c_BT.(param.nutrient_identifiers(i))) = 1/(param.V_BT) * ( u_in_FT * x(INDEX.x_c_FT.(param.nutrient_identifiers(i))) + param.acid_to_nutrient(i,:) * u(INDEX.u_Acid.(param.acid_identifiers(1)):INDEX.u_Acid.(param.acid_identifiers(end))) - u_in_FT * x(INDEX.x_c_BT.(param.nutrient_identifiers(i))));
        elseif(strcmp(param.nutrient_identifiers(i),"Chloride")==1) 
            xdot(INDEX.x_c_BT.(param.nutrient_identifiers(i))) = 1/(param.V_BT) * ( u_in_FT * param.c_in(i) + param.acid_to_nutrient(i,:) * u(INDEX.u_Acid.(param.acid_identifiers(1)):INDEX.u_Acid.(param.acid_identifiers(end))) - u_in_FT * x(INDEX.x_c_BT.(param.nutrient_identifiers(i))));    
        end
    end
    
end