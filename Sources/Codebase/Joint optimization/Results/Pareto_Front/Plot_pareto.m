close all

y1 = load('new_ParetoVar_co2_usd.mat');
y2 = load('new_ParetoVar_nut_usd.mat');
y3 = load('new_ParetoVar_nut_co2.mat');
xq = min(y1.pareto_var(3,:))/1000:1e-4:max(y1.pareto_var(3,:))/1000;
yq = interp1(y1.pareto_var(3,:)/1000,y1.pareto_var(4,:),xq);
size_font = 24;
figure("Units","normalized","Position",[0 0.1 1 0.75])

%% Plot CO2 footprint vs. price

t = tiledlayout(1,3, 'Padding','compact','TileSpacing','loose');
sgtitle('\textbf{\quad \quad \quad Trade-offs between price,} $\mathbf{CO_2}$ \textbf{footprint and nutrient solution quality in the joint nutrient optimization}', 'FontSize', size_font, 'Interpreter', 'latex')
ax1 = axes("Position",[0.07 0.14 0.24 0.70]);
plot(ax1,xq,yq,'Linewidth',5,'Color',[0.3 0.3 0.3],'LineStyle','-.')
hold on

Color1 = [1 0 0];
Color2 = [1 1 0];

for i = 0:length(y1.pareto_var(3,:))-1
    Color = Color1 + (Color2-Color1)*i/(length(y1.pareto_var(3,:))-1);
    Color = min(1,Color);
    plot(ax1,y1.pareto_var(3,i+1)/1000,y1.pareto_var(4,i+1),'Linestyle','none','Marker','o','MarkerFaceColor',Color,'MarkerSize',20,'MarkerEdgeColor',[0 0 0],'LineWidth',4)
end
plot(ax1,5.2,4.2,'Linestyle','none','Marker','o','MarkerFaceColor',[1 1 0],'MarkerSize',20,'MarkerEdgeColor',[0 0 0],'LineWidth',4)
plot(ax1,5.2,4.1,'Linestyle','none','Marker','o','MarkerFaceColor',[1 0 0],'MarkerSize',20,'MarkerEdgeColor',[0 0 0],'LineWidth',4)
set(gca, 'FontSize', 20);
hold off
grid on
ylim([3.0 4.4])
xlim([3.8 8.0]);
xticks(4:1:9)

labels = {"$\omega_\mathrm{price} = 0$; $\omega_\mathrm{CO_2} = 1$","$\omega_\mathrm{price} = 1$; $\omega_\mathrm{CO_2} = 0$"};
xl = [5.4 5.4];
yl = [4.2 4.1];
for i = 1:2
    text(xl(i),yl(i),labels(i),'Fontweight','bold','Fontsize',size_font,'Interpreter','latex')
end
title({'\textbf{Carbon footprint versus}','\textbf{price}'},'FontSize',size_font,'Interpreter','latex')
xlabel({'Relative carbon footprint per','volume nutrient solution in $\mathrm{kg/m^3}$'},'FontSize',size_font,'Interpreter','latex')
ylabel({'Relative price per volume nutrient', 'solution in $\mathrm{USD/m^3}$'},'FontSize',size_font,'Interpreter','latex')

xq_min = min(y1.pareto_var(3,2:end-1))/1000:1e-4:max(y1.pareto_var(3,2:end-1))/1000;
yq_min = interp1(y1.pareto_var(3,2:end-1)/1000,y1.pareto_var(4,2:end-1),xq_min);

axInset1 = axes('Position',[0.15 0.28 0.15 0.2]); % [left bottom width height]
plot(axInset1, xq, yq,'Linewidth',3,'Color',[0.3 0.3 0.3],'LineStyle','-.');
hold on
for i = 1:length(y1.pareto_var(3,:))-2
    Color = Color1 + (Color2-Color1)*i/(length(y1.pareto_var(3,:))-1);
    Color = min(1,Color);
    plot(axInset1,y1.pareto_var(3,i+1)/1000,y1.pareto_var(4,i+1),'Linestyle','none','Marker','o','MarkerFaceColor',Color,'MarkerSize',15,'MarkerEdgeColor',[0 0 0],'LineWidth',3)
end
hold off
set(gca, 'FontSize', 18);
grid on
box on
xlim([4 5])
xticks(4:0.2:5)
ylim([3 4.2])
yticks(3.0:0.3:4.2)
axInset1.Box = 'on';

%% Plot nut vs. price

xq = min(y2.pareto_var(4,:)):1e-4:max(y2.pareto_var(4,:));
yq = interp1(y2.pareto_var(4,:),y2.pareto_var(1,:),xq);

ax2 = axes("Position",[0.41 0.14 0.24 0.70]);
plot(xq,yq,'Linewidth',5,'Color',[0.3 0.3 0.3],'LineStyle','-.')
hold on

Color1 = [1 0 0];
Color2 = [1 1 0];
%Color2 = [1 0 0];

for i = 0:length(y2.pareto_var(3,:))-1
    Color = Color1 + (Color2-Color1)*i/(length(y2.pareto_var(3,:))-1);
    Color = min(1,Color);
    plot(y2.pareto_var(4,i+1),y2.pareto_var(1,i+1),'Linestyle','none','Marker','o','MarkerFaceColor',Color,'MarkerSize',20,'MarkerEdgeColor',[0 0 0],'LineWidth',4)
end
plot(4.6,0.051,'Linestyle','none','Marker','o','MarkerFaceColor',[1 1 0],'MarkerSize',20,'MarkerEdgeColor',[0 0 0],'LineWidth',4)
plot(4.6,0.0465,'Linestyle','none','Marker','o','MarkerFaceColor',[1 0 0],'MarkerSize',20,'MarkerEdgeColor',[0 0 0],'LineWidth',4)
set(gca, 'FontSize', 20);
hold off
grid on
ylim([-0.002 0.06])
xlim([2.7 8])


labels = {"$\omega_\mathrm{nut} = 0$; $\omega_\mathrm{price} = 1$","$\omega_\mathrm{nut} = 1$; $\omega_\mathrm{price} = 0$"};
xl = [4.85 4.85];
yl = [0.051 0.0465];
for i = 1:2
    text(xl(i),yl(i),labels(i),'Fontweight','bold','Fontsize',size_font,'Interpreter','latex')
end
title({'\textbf{Price versus}', '\textbf{nutrient solution quality}'},'FontSize',size_font,'Interpreter','latex')
xlabel({'Relative price per volume nutrient', 'solution in $\mathrm{USD/m^3}$'},'Fontsize',size_font,'Interpreter','latex')
ylabel({'Weighted relative quadratic deviation','from reference solution'},'Interpreter','latex','Fontsize',size_font,'Interpreter','latex')

axInset2 = axes('Position',[0.47 0.28 0.15 0.2]); % [left bottom width height]
plot(axInset2, xq, yq,'Linewidth',3,'Color',[0.3 0.3 0.3],'LineStyle','-.');
hold on
for i = 1:length(y1.pareto_var(3,:))-2
    Color = Color1 + (Color2-Color1)*i/(length(y2.pareto_var(3,:))-1);
    Color = min(1,Color);
    plot(axInset2,y2.pareto_var(4,i+1),y2.pareto_var(1,i+1),'Linestyle','none','Marker','o','MarkerFaceColor',Color,'MarkerSize',15,'MarkerEdgeColor',[0 0 0],'LineWidth',3)
end
hold off
set(gca, 'FontSize', 18);
grid on
box on
xlim([3.1 4])
xticks(3.1:0.3:4)
ylim([-0.002 0.016])
yticks(0:0.004:0.016)

axInset2.LineWidth = 1;
axInset2.Box = 'on';

%% Plot nut vs. CO2 footprint

xq = min(y3.pareto_var(3,:)/1000):1e-4:max(y3.pareto_var(3,:)/1000);
yq = interp1(y3.pareto_var(3,:)/1000,y3.pareto_var(1,:),xq);

ax3 = axes("Position",[0.75 0.14 0.24 0.70]);
ax3.Box = "on";
plot(xq,yq,'Linewidth',5,'Color',[0.3 0.3 0.3],'LineStyle','-.')
hold on

Color1 = [1 0 0];
Color2 = [1 1 0];

for i = 0:length(y3.pareto_var(3,:))-1
    Color = Color1 + (Color2-Color1)*i/(length(y1.pareto_var(3,:))-1);
    Color = min(1,Color);
    plot(y3.pareto_var(3,i+1)/1000,y3.pareto_var(1,i+1),'Linestyle','none','Marker','o','MarkerFaceColor',Color,'MarkerSize',20,'MarkerEdgeColor',[0 0 0],'LineWidth',4)
end
plot(5.5,0.051,'Linestyle','none','Marker','o','MarkerFaceColor',[1 1 0],'MarkerSize',20,'MarkerEdgeColor',[0 0 0],'LineWidth',4)
plot(5.5,0.0465,'Linestyle','none','Marker','o','MarkerFaceColor',[1 0 0],'MarkerSize',20,'MarkerEdgeColor',[0 0 0],'LineWidth',4)
set(gca, 'FontSize', 20);
hold off
grid on
ylim([-0.002 0.06])
xlim([3.500 9.000]);


labels = {"$\omega_\mathrm{nut} = 0$; $\omega_\mathrm{CO_2} = 1$","$\omega_\mathrm{nut} = 1$; $\omega_\mathrm{CO_2} = 0$"};
xl = [5.75 5.75];
yl = [0.051 0.0465];
for i = 1:2
    text(xl(i),yl(i),labels(i),'Fontweight','bold','Fontsize',size_font,'Interpreter','latex')
end
title({'\textbf{Carbon footprint versus}', '\textbf{nutrient solution quality}'},'Fontsize',size_font,'Interpreter','latex')
xlabel({'Relative carbon footprint per','volume nutrient solution in $\mathrm{kg/m^3}$'},'Fontsize',size_font,'Interpreter','latex')
ylabel({'Weighted relative quadratic deviation',' from reference solution'},'Fontsize',size_font,'Interpreter','latex')

axInset3 = axes('Position',[0.81 0.28 0.15 0.2]); % [left bottom width height]
plot(axInset3, xq, yq,'Linewidth',3,'Color',[0.3 0.3 0.3],'LineStyle','-.');
hold on
for i = 1:length(y1.pareto_var(3,:))-2
    Color = Color1 + (Color2-Color1)*i/(length(y2.pareto_var(3,:))-1);
    Color = min(1,Color);
    plot(axInset3,y3.pareto_var(3,i+1)/1000,y3.pareto_var(1,i+1),'Linestyle','none','Marker','o','MarkerFaceColor',Color,'MarkerSize',15,'MarkerEdgeColor',[0 0 0],'LineWidth',3)
end
hold off
set(gca, 'FontSize', 18);
grid on
box on
xlim([4.2 5.4])
xticks(4.2:0.3:5.4)
ylim([-0.001 0.01])
yticks(0:0.002:0.01)