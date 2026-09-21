close all force

numNutrients = 8;
nutrients = {'$\mathrm{K^+}$','$\mathrm{Ca^{2+}}$','$\mathrm{SO_4}$-$\mathrm{S}$','$\mathrm{PO_4}$-$\mathrm{P}$','$\mathrm{NO_3}$-$\mathrm{N}$','$\mathrm{Mg^{2+}}$','$\mathrm{Na^{+}}$','$\mathrm{Cl^{-}}$'};
EUR_to_USD = 1.15;
cond = 0;

F = figure('Position',[100 300 1200 350],'Color',[1 1 1]);
%F = figure('Position',[100 300 1200 430],'Color',[1 1 1]);
ax0 = axes(F,"Units","normalized","Position",[0 0 1 1],'Layer','top');
ax0.Visible ="off";
ax0.YLim = ([0 350/430]);

%Switch cases by commenting/uncommenting

%K-Feed
% ratio_a = [292.5/234 200.0/160 49.0/64 29.1/31 209.8/210  38.8/34 11.2/10.9 1];
% ratio_b = [237.2/234 200.0/160 48.0/64 23.2500/31 200.1/210 42.5/34 12.3/10.9 1];
% Preis_a_chem =  2.8237;
% Preis_a_feed = 5.1763;
% Preis_a = Preis_a_chem + Preis_a_feed;
% Preis_b_chem = 1.7448;
% Preis_b_feed = 5.5662;
% Preis_b = Preis_b_chem + Preis_b_feed;
% Carbon_a_chem =  2.3605*1000;
% Carbon_a_feed = 5.1831*1000;
% Carbon_a = Carbon_a_chem + Carbon_a_feed;
% Carbon_b_chem = 1.4682*1000;
% Carbon_b_feed = 5.5735*1000;
% Carbon_b = Carbon_b_chem + Carbon_b_feed;
% % uicontrol("Style","text","parent",F,"String",{'Quality of nutrient solution and price/carbon footprint of nutrient management using the K-max feed'},"FontSize",14,"Fontweight","bold","Position",[0 317 1200 28],'BackgroundColor',[1 1 1])
% text(ax0,0.08, 0.77,{'Quality of nutrient solution and price/carbon footprint of nutrient management using the K-max feed'},"FontSize",16,"Fontweight","bold",'Interpreter','latex')

% % 
% % %P-Feed
% ratio_a = [250.6/234 175.2/160 61.1/64 30.6/31 210.0/210 35.1/34 11.0/10.9 1];
% ratio_b = [175.5000/234 200.0/160 48.0000/64 26.5/31 201.1/210 25.5/34 10.9/10.9 1];
% Preis_a_chem = 2.0100;
% Preis_a_feed = 5.8712;
% Preis_a = Preis_a_chem + Preis_a_feed;
% Preis_b_chem = 1.7172;
% Preis_b_feed = 5.3074;
% Preis_b = Preis_b_chem + Preis_b_feed;
% Carbon_a_chem = 1.3060*1000;
% Carbon_a_feed = 5.8043*1000;
% Carbon_a = Carbon_a_chem + Carbon_a_feed;
% Carbon_b_chem = 1.3470*1000;
% Carbon_b_feed = 5.2469*1000;
% Carbon_b = Carbon_b_chem + Carbon_b_feed;
% %uicontrol("Style","text","parent",F,"String",{'Quality of nutrient solution and price/carbon footprint of nutrient management using the P-max feed'},"FontSize",14,"Fontweight","bold","Position",[0 317 1200 28],'BackgroundColor',[1 1 1])
% text(ax0,0.08, 0.77,{'Quality of nutrient solution and price/carbon footprint of nutrient management using the P-max feed'},"FontSize",16,"Fontweight","bold",'Interpreter','latex')

% % 
% % % %Mg-Feed
% ratio_a = [292.5/234 200.0/160 49.2/64 29.2/31 209.8/210 38.8/34 11.2/10.9 1];
% ratio_b = [234.1/234 200.0/160 48.0/64 23.25/31 199.5/210 42.5000/34 12.25/10.9 1];
% Preis_a_chem = 3.2668;
% Preis_a_feed = 4.1597;
% Preis_a = Preis_a_chem + Preis_a_feed;
% Preis_b_chem = 2.0190;
% Preis_b_feed = 4.5967;
% Preis_b = Preis_b_chem + Preis_b_feed;
% Carbon_a_chem = 2.6679*1000;
% Carbon_a_feed = 4.1677*1000;
% Carbon_a = Carbon_a_chem + Carbon_a_feed;
% Carbon_b_chem = 1.6325*1000;
% Carbon_b_feed = 4.6055*1000;
% Carbon_b = Carbon_b_chem + Carbon_b_feed;
% % uicontrol("Style","text","parent",F,"String",{'Quality of nutrient solution and price/carbon footprint of nutrient management using the Mg-max feed'},"FontSize",14,"Fontweight","bold","Position",[0 317 1200 28],'BackgroundColor',[1 1 1])
% text(ax0,0.074, 0.77,{'Quality of nutrient solution and price/carbon footprint of nutrient management using the Mg-max feed'},"FontSize",16,"Fontweight","bold",'Interpreter','latex')

% % 
% % % %KPMg-Feed
% ratio_a = [292.5/234 200.0/160 51.2/64 29.4/31 209.8/210 38.2/34 11.1/10.9 1];
% ratio_b = [231.2/234 200.0/160 48.0/64 23.25/31 201.0/210 42.5/34 12.2/10.9 1];
% Preis_a_chem = 2.2755;
% Preis_a_feed = 5.0318;
% Preis_a = Preis_a_chem + Preis_a_feed;
% Preis_b_chem = 1.7384;
% Preis_b_feed = 4.9521;
% Preis_b = Preis_b_chem + Preis_b_feed;
% Carbon_a_chem = 1.7770*1000;
% Carbon_a_feed = 5.0394*1000;
% Carbon_a = Carbon_a_chem + Carbon_a_feed;
% Carbon_b_chem = 1.3718*1000;
% Carbon_b_feed =  4.9597*1000;
% Carbon_b = Carbon_b_chem + Carbon_b_feed;
% % uicontrol("Style","text","parent",F,"String",{'Quality of nutrient solution and price/carbon footprint of nutrient management using the KPMg-max feed'},"FontSize",14,"Fontweight","bold","Position",[0 317 1200 28],'BackgroundColor',[1 1 1])
% text(ax0,0.061, 0.77,{'Quality of nutrient solution and price/carbon footprint of nutrient management using the KPMg-max feed'},"FontSize",16,"Fontweight","bold",'Interpreter','latex')

% % % 
% % % % %Eco-Feed
% ratio_a = [ 258.5/234 182.3/160 58.8/64 30.4/31 209.9/210 35.7/34 11.0/10.9 1];
% ratio_b = [175.5/234 200.0/160 48.0/64 23.25/31 203.8/210 38.6/34 11.9/10.9 1];
% Preis_a_chem = 2.1633;
% Preis_a_feed = 2.8876;
% Preis_a = Preis_a_chem + Preis_a_feed;
% Preis_b_chem =1.7151;
% Preis_b_feed = 2.7512;
% Preis_b = Preis_b_chem + Preis_b_feed;
% Carbon_a_chem = 1.6208*1000;
% Carbon_a_feed = 3.1775*1000;
% Carbon_a = Carbon_a_chem + Carbon_a_feed;
% Carbon_b_chem = 1.4250*1000;
% Carbon_b_feed = 3.0274*1000;
% Carbon_b = Carbon_b_chem + Carbon_b_feed;
% % uicontrol("Style","text","parent",F,"String",{'Quality of nutrient solution and price/carbon footprint of nutrient management using the Eco-max feed'},"FontSize",14,"Fontweight","bold","Position",[0 317 1200 28],'BackgroundColor',[1 1 1])
% text(ax0,0.071, 0.77,{'Quality of nutrient solution and price/carbon footprint of nutrient management using the Eco-max feed'},"FontSize",16,"Fontweight","bold",'Interpreter','latex')

% %Auto-Feed hard tw
% ratio_a = [244.4/234 169.5/160 80.1/64 30.8/31 210.0/210 34.7/34 27.2/27.0 1];
% ratio_b = [249.7/234 175.5/160 79.6/64 30.4/31 210.0/210 35.1/34 27.4/27.0 1];
% Preis_a_chem = 2.9922;
% Preis_a_feed = 4.7737;
% Preis_a = Preis_a_chem + Preis_a_feed;
% Preis_b_chem = 3.1820;
% Preis_b_feed = 2.4384;
% Preis_b = Preis_b_chem + Preis_b_feed;
% Carbon_a_chem = 2.3321*1000;
% Carbon_a_feed = 6.6679*1000;
% Carbon_a = Carbon_a_chem + Carbon_a_feed;
% Carbon_b_chem = 2.5422*1000;
% Carbon_b_feed = 3.9220*1000;
% Carbon_b = Carbon_b_chem + Carbon_b_feed;
% %%uicontrol("parent",F,"Style","text","String",{'Quality of nutrient solution and price/carbon footprint of nutrient management using hard tap water'},"FontSize",14,"Fontweight","bold","Position",[0 325 1200 24],'BackgroundColor',[1 1 1],'HorizontalAlignment','center')
% text(ax0,0.105, 0.77,{'Quality of nutrient solution and price/carbon footprint of nutrient management using hard tap water'},"FontSize",16,"Fontweight","bold",'Interpreter','latex')

% % %Auto-Feed soft tw
% ratio_a = [234/234 160/160 64/64 31.0/31 210.0/210 34.0/34 10.9/10.9 1];
% ratio_b = [243.0/234 169.4/160 62.1/64 30.6/31 210.0/210 34.6/34 10.9/10.9 1];
% Preis_a_chem = 2.3886;
% Preis_a_feed = 4.7001;
% Preis_a = Preis_a_chem + Preis_a_feed;
% Preis_b_chem = 2.1551;
% Preis_b_feed = 2.7352;
% Preis_b = Preis_b_chem + Preis_b_feed;
% Carbon_a_chem = 1.6778*1000;
% Carbon_a_feed = 6.9306*1000;
% Carbon_a = Carbon_a_chem + Carbon_a_feed;
% Carbon_b_chem = 1.5816*1000;
% Carbon_b_feed = 4.2934*1000;
% Carbon_b = Carbon_b_chem + Carbon_b_feed;
% % uicontrol("Style","text","parent",F,"String",{'Quality of nutrient solution and price/carbon footprint of nutrient management using soft tap water'},"FontSize",14,"Fontweight","bold","Position",[0 317 1200 28],'BackgroundColor',[1 1 1])
% text(ax0,0.109, 0.77,{'Quality of nutrient solution and price/carbon footprint of nutrient management using soft tap water'},"FontSize",16,"Fontweight","bold",'Interpreter','latex')
% 
% % % %Auto-Feed cond w
cond = 1;
ratio_a = [234/234 160/160 64.1/64 31.0/31 210.0/210 34.0/34 0.0 0];
ratio_b = [247.2/234 173.2/160 61.1/64 30.5/31 210.0/210 34.9/34 0.0 0];
Preis_a_chem = 2.3727;
Preis_a_feed = 5.5785;
Preis_a = Preis_a_chem + Preis_a_feed;
Preis_b_chem = 2.4627;
Preis_b_feed = 3.7305;
Preis_b = Preis_b_chem + Preis_b_feed;
Carbon_a_chem = 1.4617*1000;
Carbon_a_feed = 7.5383*1000;
Carbon_a = Carbon_a_chem + Carbon_a_feed;
Carbon_b_chem = 1.7223*1000;
Carbon_b_feed = 5.3488*1000;
Carbon_b = Carbon_b_chem + Carbon_b_feed;
% uicontrol("Style","text","parent",F,"String",{'Quality of nutrient solution and price/carbon footprint of nutrient management using condensation water'},"FontSize",14,"Fontweight","bold","Position",[0 317 1200 28],'BackgroundColor',[1 1 1])
text(ax0,0.088, 0.77,{'Quality of nutrient solution and price/carbon footprint of nutrient management using condensation water'},"FontSize",16,"Fontweight","bold",'Interpreter','latex')

avg_error_a =round(sum(abs(ratio_a-1))/numNutrients,3);
avg_error_b =round(sum(abs(ratio_b-1))/numNutrients,3);
if cond == 1
    avg_error_a =round(sum(abs(ratio_a(1:end-2)-1))/(numNutrients-2),3);
    avg_error_b =round(sum(abs(ratio_b(1:end-2)-1))/(numNutrients-2),3);
end
add_rad = [0.15 0.15 0.15 0.26 0.28 0.15 0.15 0.15];


rad_max = 1.35;
theta = linspace(0, 2*pi, numNutrients+1);

colors = [108 166 205; 255 99 71; 155 205 155; 255 246 143; 176 226 255; 255 165 79; 205 105 201; 255 192 203]/255;

numArcPoints = 50;

%Nutrient solution quality - scenario (opt. a)
ax1 = axes("Parent",F);
ax1.Visible ="off";
ax1.Units ="pixels";
ax1.Position = [0 5 1.2*270 1.2*270];
ax1.NextPlot = "add";
text(ax0,0.142, 0.9,{'Resulting concentrations relative','to Hoagland reference for Opt. (a)'},"FontSize",16,"Fontweight","bold",'Interpreter','latex','HorizontalAlignment','center')
text(ax0,0.50, 0.9,{"Carbon footprint (left) and price (middle) of nutrient","management and average relative deviation","of nutrient concentrations (right)"},"FontSize",16,"Fontweight","bold",'Interpreter','latex','HorizontalAlignment','center')
text(ax0,0.860, 0.9,{'Resulting concentrations relative','to Hoagland reference for Opt. (b)'},"FontSize",16,"Fontweight","bold",'Interpreter','latex','HorizontalAlignment','center')
ax1.XLim = [-1.5 1.5];
ax1.YLim = [-1.5 1.5];

for i = 1:numNutrients
    if cond==1 && (i==7 || i == 8)
        r = max(1,1+0.25*ratio_a(i)/1.9);
    else
        r = min(ratio_a(i), rad_max);
    end
    theta_start = theta(i);
    theta_end = theta(i+1);
    if cond==1 &&i==7
        theta_start = theta_start + sin(0.1);
    end
    if cond==1 &&i==8
        theta_end = theta_end - sin(0.1);
    end

    arc_theta = linspace(theta_start, theta_end, numArcPoints);
    
    if cond==1 && (i==7 || i == 8)
        x_outer = r * cos(arc_theta)%+0.1*sin(2*pi-arc_theta);
        y_outer = r * sin(arc_theta)%-0.1*cos(2*pi-arc_theta);
        
        x_poly = [0.1, x_outer];
        y_poly = [-0.1, y_outer];
    
        fill(ax1,x_poly, y_poly, colors(i,:), 'EdgeColor', 'k')
    else
        x_outer = r * cos(arc_theta);
        y_outer = r * sin(arc_theta);
        
        x_poly = [0, x_outer];
        y_poly = [0, y_outer];
        
        fill(ax1,x_poly, y_poly, colors(i,:), 'EdgeColor', 'k') 

    end
    
    theta_mid = (theta_start + theta_end)/2;
    text_r = r*0.6;
    text_x = text_r * cos(theta_mid);
    text_y = text_r * sin(theta_mid);
    if cond==1 && (i==7 || i == 8)
        t = strcat('$', num2str(round(ratio_a(i),1)),'\, \mathrm{mg/L}$');
        text(ax1,text_x+0.03, text_y-0.03, t, ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', 'k','FontSize',12,"Rotation",360/2/pi*theta_mid,'Interpreter','latex')
    else
        t = strcat('$', num2str(round(ratio_a(i)*100)),'\mathrm{\%}$');
        text(ax1,text_x, text_y, t, ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', 'k','FontSize',12,'Interpreter','latex')
    end
end

plot(ax1,cos(linspace(0, 2*pi, 200)), sin(linspace(0, 2*pi, 200)), 'k--', 'LineWidth', 1.5)

for i = 1:numNutrients
    theta_mid = (theta(i)+theta(i+1))/2;
    if cond==1 && (i==7 || i == 8)
        r = max(1,1+0.25*ratio_a(i)/1.9);
    else
        r = min(ratio_a(i), rad_max);
    end
    text(ax1,max((r+add_rad(i)),1+add_rad(i))*cos(theta_mid), max((r+add_rad(i)),1+add_rad(i))*sin(theta_mid), nutrients{i}, ...
        'HorizontalAlignment', 'center', 'FontSize', 12,'Interpreter','latex')
end

%CO2 footprint scenario (opt. a) vs. scenario (opt. b)
axCO2 = axes("Parent",F);
axCO2.Units ="pixels";
axCO2.Position = [370 55 140 250];
axCO2.NextPlot = "add";
axCO2.XLim = [0.5 2.5];
axCO2.XTick = [1 2];
axCO2.YLim = [0 10];

bar_data = [round(Carbon_a/1000,2) round(Carbon_b/1000,2)];
bar_data1 = [round(Carbon_a_feed/1000,2) round(Carbon_b_feed/1000,2)];
plot(axCO2,0:4,9*ones(5,1),'LineWidth',2,'Color','k','LineStyle','--')
hb = bar(axCO2,bar_data);
hb(1).FaceColor ='flat';
hb1 = bar(axCO2,bar_data1);
hb1(1).FaceColor ='flat';
xtips1 = hb(1).XEndPoints;
ytips1 = hb(1).YEndPoints;
ytips1(1) = ytips1(1) + 0;
ytips1(2) = ytips1(2) ;
labels1 = string(hb(1).YData);
text(axCO2,xtips1,ytips1,labels1,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',12,'Interpreter','latex')
xtips2 = hb1(1).XEndPoints;
ytips2 = hb1(1).YEndPoints;
labels2 = string(hb1(1).YData);
text(axCO2,xtips2,ytips2,labels2,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',12,'Interpreter','latex')
hb.CData = [174 197 224; 236 159 145]/255;
hb1.CData = [68 119 178; 151 46 26]/255;
hb.BarWidth = 0.6;
hb1.BarWidth = 0.6;
set(axCO2, 'XTickLabel', {'Opt. (a)','Opt. (b)'},'FontSize',12,'TickLabelInterpreter','latex')
ylabel(axCO2,'$\mathrm{CO}_\mathrm{2,rel}$ in $\mathrm{kg/m^3}$ solution','Interpreter','latex')

%Relative average deviation scenario (opt. a) vs. scenario (opt. b)
ax2 = axes("Parent",F);
ax2.Units ="pixels";
ax2.Position = [760 55 140 250];
ax2.NextPlot = "add";
ax2.XLim = [0.5 2.5];
ax2.XTick = [1 2];
ax2.YLim = [0 25];

bar_data = [avg_error_a*100 avg_error_b*100];
hb = bar(ax2,bar_data);
hb(1).FaceColor ='flat';
xtips1 = hb(1).XEndPoints;
ytips1 = hb(1).YEndPoints;
labels1 = string(hb(1).YData);
text(ax2,xtips1,ytips1,labels1,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',12,'Interpreter','latex')
hb.CData = [174 197 224; 236 159 145]/255;
hb.BarWidth = 0.6;
set(ax2, 'XTickLabel', {'Opt. (a)','Opt. (b)'},'FontSize',12,'TickLabelInterpreter','latex')
ylabel(ax2,'$e_\mathrm{rel,conc}$ in $\mathrm{\%}$','Interpreter','latex')

%Price scenario (opt. a) vs. scenario (opt. b)
ax3 = axes("Parent",F);
ax3.Units ="pixels";
ax3.Position = [565 55 140 250];
ax3.NextPlot = "add";
ax3.XLim = [0.5 2.5];
ax3.XTick = [1 2];
ax3.YLim = [0 10];

plot(ax3,0:4,8*ones(5,1),'LineWidth',2,'Color','k','LineStyle','--')
bar_data = [round(Preis_a,2) round(Preis_b,2)];
hb = bar(ax3,bar_data);
hb(1).FaceColor ='flat';
xtips1 = hb(1).XEndPoints;
ytips1 = hb(1).YEndPoints;
ytips1(1) = ytips1(1) +0;
ytips1(2) = ytips1(2) +0.0;
labels1 = string(hb(1).YData);
text(ax3,xtips1,ytips1,labels1,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',12,'Interpreter','latex')
hb.CData = [174 197 224; 236 159 145]/255;
hb.BarWidth = 0.6;
set(ax3, 'XTickLabel', {'Opt. (a)','Opt. (b)'},'FontSize',12,'TickLabelInterpreter','latex')
ylabel(ax3,'$p_\mathrm{rel}$ in $\mathrm{USD/m^3}$ solution','Interpreter','latex')
bar_data1 = [round(Preis_a_feed,2) round(Preis_b_feed,2)];
hb1 = bar(ax3,bar_data1);
hb1(1).FaceColor ='flat';
xtips2 = hb1(1).XEndPoints;
ytips2 = hb1(1).YEndPoints;
labels2 = string(hb1(1).YData);
text(ax3,xtips2,ytips2,labels2,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',12,'Interpreter','latex')
hb1.CData = [68 119 178; 151 46 26]/255;
hb1.BarWidth = 0.6;
set(ax3, 'XTickLabel', {'Opt. (a)','Opt. (b)'},'FontSize',12,'TickLabelInterpreter','latex')
ylabel(ax3,'$p_\mathrm{rel}$ in $\mathrm{USD/m^3}$ solution','Interpreter','latex')
set(gca,'YTick',[0 2 4 6 10])

%Nutrient solution quality - scenario (opt. b)
ax4 = axes("Parent",F);
ax4.Visible ="off";
ax4.Units ="pixels";
ax4.Position = [890 5 1.2*270 1.2*270];
ax4.NextPlot = "add";
ax4.XLim = [-1.5 1.5];
ax4.YLim = [-1.5 1.5];

for i = 1:numNutrients
    if cond==1 && (i==7 || i == 8)
        r = max(1,1+0.25*ratio_b(i)/1.9);
    else
        r = min(ratio_b(i), rad_max);
    end
    
    theta_start = theta(i);
    theta_end = theta(i+1);
    
    if cond==1 &&i==7
        theta_start = theta_start + sin(0.1);
    end
    if cond==1 &&i==8
        theta_end = theta_end - sin(0.1);
    end

    arc_theta = linspace(theta_start, theta_end, numArcPoints);
    
    x_outer = r * cos(arc_theta);
    y_outer = r * sin(arc_theta);
    
    
    if cond==1 && (i==7 || i == 8)
        x_poly = [0.1, x_outer];
        y_poly = [-0.1, y_outer];
        fill(ax4,x_poly, y_poly, colors(i,:), 'EdgeColor', 'k')
    else
        x_poly = [0, x_outer];
        y_poly = [0, y_outer];
        fill(ax4,x_poly, y_poly, colors(i,:), 'EdgeColor', 'k')   
    end
    
    theta_mid = (theta_start + theta_end)/2;
    text_r = r*0.6;
    text_x = text_r * cos(theta_mid);
    text_y = text_r * sin(theta_mid);
    if cond==1 && (i==7 || i == 8)
        if i==8 || i== 7
            t = strcat('$',num2str(round(ratio_b(i),1)), '\, \mathrm{mg/L}$');
            text(ax4,text_x+0.03, text_y-0.03, t, ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', 'k','FontSize',12,"Rotation",360/2/pi*theta_mid,'Interpreter','latex')
        else
            t = strcat('$',num2str(round(ratio_b(i),1)), '\, \mathrm{mg/L}$');
            text(ax4,text_x-0.02, text_y+0.12, t, ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', 'k','FontSize',12,"Rotation",360/2/pi*theta_mid,'Interpreter','latex')
        end
    else
        t = strcat('$',num2str(round(ratio_b(i)*100)), '\mathrm{\%}$');
        text(ax4,text_x, text_y, t, ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', 'k','FontSize',12,'Interpreter','latex')
    end
end

plot(ax4,cos(linspace(0, 2*pi, 200)), sin(linspace(0, 2*pi, 200)), 'k--', 'LineWidth', 1.5)

for i = 1:numNutrients
    theta_mid = (theta(i)+theta(i+1))/2;
    if cond==1 && (i==7 || i == 8)
        r = max(1,1+0.25*ratio_b(i)/1.9);
    else
        r = min(ratio_b(i), rad_max);
    end
    text(ax4,max((r+add_rad(i)),1+add_rad(i))*cos(theta_mid), max((r+add_rad(i)),1+add_rad(i))*sin(theta_mid), nutrients{i}, ...
        'HorizontalAlignment', 'center', 'FontSize', 12,'Interpreter','latex')
end
hold off

hor_pos = 415;
vert_pos = 8; 

uicontrol("Parent",F,"Style","text","Position",[0+hor_pos 0+vert_pos 16 16],"BackgroundColor",[0 0 0]/255)
uicontrol("Parent",F,"Style","text","Position",[1+hor_pos 1+vert_pos 14 14],"BackgroundColor",[68 119 178]/255)
uicontrol("Parent",F,"Style","text","Position",[1+hor_pos 1+vert_pos 14 7],"BackgroundColor",[151 46 26]/255)
%uicontrol("Parent",F,"Style","text","Position",[19+hor_pos vert_pos-1 45 20],"String","feed","BackgroundColor",[1 1 1],'HorizontalAlignment','center',FontSize=14)
text(ax0,0.377, 0.03,'feed',"FontSize",15,"Fontweight","bold",'Interpreter','latex','HorizontalAlignment','center','BackgroundColor',[1 1 1])

uicontrol("Parent",F,"Style","text","Position",[85+hor_pos 0+vert_pos 16 16],"BackgroundColor",[0 0 0]/255)
uicontrol("Parent",F,"Style","text","Position",[86+hor_pos 1+vert_pos 14 14],"BackgroundColor",[174 197 224]/255)
uicontrol("Parent",F,"Style","text","Position",[86+hor_pos 1+vert_pos 14 7],"BackgroundColor",[236 159 145]/255)
text(ax0,0.494, 0.03,'feed + chemicals',"FontSize",15,"Fontweight","bold",'Interpreter','latex','HorizontalAlignment','center','BackgroundColor',[1 1 1])

%uicontrol("Parent",F,"Style","text","Position",[535 248 31 18],"BackgroundColor",[1 1 1],'HorizontalAlignment','center',FontSize=11)
text(ax0,0.295, 0.65,'max',"FontSize",11,"Fontweight","bold",'Interpreter','latex','HorizontalAlignment','center')
%uicontrol("Parent",F,"Style","text","Position",[340 275 31 16],"BackgroundColor",[1 1 1],'HorizontalAlignment','center',FontSize=11)
text(ax0,0.458, 0.591,'max',"FontSize",11,"Fontweight","bold",'Interpreter','latex','HorizontalAlignment','center','BackgroundColor',[1 1 1])