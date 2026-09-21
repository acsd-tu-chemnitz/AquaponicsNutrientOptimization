clear variables
close all

%% Get Data from csv-files and assign Constraint Row to Parameter Column

currentFolder = pwd;
cd('..\..\..\Database\');

Feed_Par = readtable('FICD 2025-06-04.csv','VariableNamingRule','preserve');
Feed_Par.("Vitamin D (IU/kg)") = Feed_Par.("Vitamin D (IU/kg)").*0.025;
Additives = 572:height(Feed_Par);
Non_additives = 1:571;
Feed_Par.("Vitamin A (IU/kg)")(Additives) = Feed_Par.("Vitamin A (IU/kg)")(Additives).*0.0003;
Feed_Par.("Vitamin A (IU/kg)")(Non_additives) = Feed_Par.("Vitamin A (IU/kg)")(Non_additives).*0.0006;
constraint_bounds = readtable('ASNS_Clarias200500_DisjointOpt.csv','NumHeaderLines',3,'VariableNamingRule','preserve');
Ingredients = Feed_Par.Description;

cd(currentFolder);

% Evaluation of the Clarias feed recommended by IAFFD. Other commercial
% feeds can be evaluated too, but the structure should be the same as in
% 'PAFF_Clarias_200500.csv', atleast for the ingredient part. Furthermore
% all ingredients of the feed need to be present in the FICD.
Baseline_formulation = readtable('PAFF_Clarias_200500.csv','VariableNamingRule','preserve','NumHeaderLines',2);
num_ing=0;
ing_inclusion = Baseline_formulation.("Inclusion (%)");
while ~isnan(ing_inclusion(num_ing+1))
    num_ing=num_ing+1;
end

Baseline_formulation = Baseline_formulation(1:num_ing,:);

u_ing = zeros(height(Feed_Par),1);
for i = 1:height(Baseline_formulation)
    code = str2double(Baseline_formulation.("IAFFD Code"){i});
    ind = find(Feed_Par.Code==code);
    u_ing(ind) = Baseline_formulation.("Inclusion (%)")(i);
end

u_ing = u_ing/100;

%% Parameters

param.MJ_to_kcal = 239.006;

%% Mapping of Constraints

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

%% Plot results

% Plot the ingredients
ing_ind = find(u_ing(1:height(Feed_Par)));
ing_use = nonzeros(u_ing(1:height(Feed_Par)));
ing = string(Feed_Par{ing_ind,2});
figure(1)
b1 = bar(1:length(ing_use),100 * ing_use);
xtips1 = b1.XEndPoints;
ytips1 = b1.YEndPoints;
labels1 = string(b1.YData);
text(xtips1,ytips1,labels1,'HorizontalAlignment','center','VerticalAlignment','bottom')
xticks(1:1:length(ing_use))
xticklabels(ing);
grid on
ylabel('Content of Ingredient in whole diet in %','FontSize',13)
title('Ingredients used for the formulation of the fish diet','FontSize',13)
ylim([0 50])
    
% Calculate the resulting dietary nutrients that are either maximized or minimized

dietary_nutrients = ["Potassium (%)";"Magnesium (%)";"Phosphorus (%)";"Calcium (%)";"Sodium (%)"; "Chlorine (%)"];
num_nut = length(dietary_nutrients);
opt_results = zeros(num_nut*2,1);
    
for i = 1:num_nut
    nut_avg = sum(Feed_Par.(dietary_nutrients(i)))/height(Feed_Par);
    opt_results(i*2-1)=nut_avg;
    res_cont_nut_sol = u_ing(1:height(Feed_Par))'*Feed_Par.(dietary_nutrients(i));
    opt_results(i*2)= res_cont_nut_sol;
end

CO2_eq = u_ing(1:height(Feed_Par))'*Feed_Par.("Global warming - Including LUC & Peat (kg CO2eq/t)")

CP = Feed_Par.("Crude  Protein (%)")'*u_ing(1:height(Feed_Par));
GE = Feed_Par.("Gross Energy -MJ (MJ/kg)")'*u_ing(1:height(Feed_Par));
DP = Feed_Par.("Dig CP -fish (%)")'*u_ing(1:height(Feed_Par));
DE = Feed_Par.("Dig GE (DE) - fish (kcal)")'*u_ing(1:height(Feed_Par));

CPGE_ratio = CP/GE
DPDE_ratio = DP/DE * param.MJ_to_kcal
CaPO_ratio = Feed_Par.("Calcium (%)")'*u_ing(1:height(Feed_Par))/(Feed_Par.("Phosphorus (%)")'*u_ing(1:height(Feed_Par)))

% Plot dietary nutrient contents in derived feed formulation  
nut_str = strings(2*num_nut,1);
for i=1:num_nut
    nut_str(2*i)=dietary_nutrients(i);
    nut_str(2*i-1)=strcat(dietary_nutrients(i)," - avg");
end
figure(2)
b2 = bar(round(opt_results,2));
xtips2 = b2.XEndPoints;
ytips2 = b2.YEndPoints;
labels2 = string(b2.YData);
text(xtips2,ytips2,labels2,'HorizontalAlignment','center','VerticalAlignment','bottom')
xticks(1:length(opt_results))
xticklabels(nut_str)
grid on
ylabel('Nutrient Content in % (equals 10g/kg)','FontSize',13)
title('Nutrient Composition of the formulated fish diet - Nutrients that are important for plants','FontSize',13)

% check if the constraints are fullfiled by the processed solution

results_constr = zeros(length(constraints_str));
for i=1:length(constraints_str)
     par=Feed_Par{:,column_number_constr(i)};    
     results_constr(i)=u_ing(1:height(Feed_Par))'*par;
end
       
num_constr_max = 0;
num_constr_min = 0;

for i = 1:length(constraints_str)
    if strcmp(constraint_bounds.("Restriction Type")(row_constraints(i)),'Maximum')==1
       num_constr_max = num_constr_max+1;
       res_constr_max(num_constr_max)=results_constr(i)/constraint_bounds.("Value")(row_constraints(i));
    end
    if strcmp(constraint_bounds.("Restriction Type")(row_constraints(i)),'Minimum')==1
       num_constr_min = num_constr_min+1;
       res_constr_min(num_constr_min)=results_constr(i)/constraint_bounds.("Value")(row_constraints(i));       
    end
end

str_max = strings(num_constr_max,1);
str_min = strings(num_constr_min,1); 
num_constr_max = 0;
num_constr_min = 0;
for i = 1:length(constraints_str)
    if strcmp(constraint_bounds.("Restriction Type")(row_constraints(i)),'Maximum')==1
       num_constr_max = num_constr_max+1;
       str_max(num_constr_max) = constraints_str(i);
    end
    if strcmp(constraint_bounds.("Restriction Type")(row_constraints(i)),'Minimum')==1
       num_constr_min = num_constr_min+1;
       str_min(num_constr_min) = constraints_str(i);   
    end
end
str_max = [str_max(1:end-2);"Price";"Carbon Footprint"];

% Plot constraints
figure(3)
subplot(2,1,1)
bar(100 * res_constr_max)
hold on 
plot(0:(length(res_constr_max)+1),100*ones(length(res_constr_max)+2,1),'-.','Color',[1 0 0 1],'LineWidth',1.5)
xticks(1:length(res_constr_max))
xticklabels(str_max)
grid on
ylabel({'Nutrient Content normalized';'by upper bound in %'},'FontSize',13)
title('Content of Nutrients in fish diet constrained by an upper limit','FontSize',13)
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
title('Content of Nutrients in fish diet constrained by a lower limit','FontSize',13)
legend({'Nutrient content','allowed minimum content'},'Location','northwest')