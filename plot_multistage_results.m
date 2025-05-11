function plot_multistage_results(results, params)
% 可视化多阶段规划结果
%
% 输入参数:
%   results: 包含优化结果的结构体
%   params: 包含系统参数的结构体

% 检查输入
if ~isfield(results, 'stages') || ~isfield(params, 'multistage')
    error('需要多阶段规划结果和参数');
end

num_stages = params.multistage.num_stages;
years_per_stage = params.multistage.years_per_stage;
planning_years = sum(years_per_stage);

% 创建横坐标标签 - 规划年份
x_years = zeros(num_stages, 1);
for s = 1:num_stages
    if s == 1
        x_years(s) = years_per_stage(1);
    else
        x_years(s) = x_years(s-1) + years_per_stage(s);
    end
end

%% 1. 设备容量规划结果
figure('Name', '多阶段设备容量规划结果', 'Position', [100, 100, 1200, 800]);

% 使用原有颜色方案
colors_power = struct();
colors_power.CCGT = [0.57, 0.24, 0.59];       % CCGT - 紫色
colors_power.PV = [0.929, 0.361, 0.271];      % PV - 红色
colors_power.WT = [0.294, 0.384, 0.969];      % WT - 蓝色

colors_heat = struct();
colors_heat.EBg = [0.318, 0.706, 0.918];      % EBg - 浅蓝色
colors_heat.HPg = [0.741, 0.537, 0.518];      % HPg - 粉色
colors_heat.EBe = [0.945, 0.800, 0.341];      % EBe - 浅黄色
colors_heat.HPe = [0.522, 0.710, 0.714];      % HPe - 青色

colors_storage = struct();
colors_storage.ESS = [0.835, 0.561, 0.200];   % ESS - 橙色
colors_storage.TES = [0.5, 0.5, 0.5];         % TES - 灰色

% 1.1 发电设备容量
subplot(2, 3, 1);
power_data = [results.summary.CCGT_n * params.technical.CCGT.P_max; results.summary.PV_instal; results.summary.WT_instal]';
h = bar(power_data, 'stacked');
colors_power_array = [colors_power.CCGT; colors_power.PV; colors_power.WT];
for i = 1:3
    set(h(i), 'FaceColor', colors_power_array(i,:));
end
legend('CCGT', 'PV', 'WT', 'Location', 'northwest');
xlabel('规划阶段');
ylabel('装机容量 (MW)');
title('各阶段发电设备装机容量');
set(gca, 'XTickLabel', x_years);
grid on;

% 1.2 供热设备容量
subplot(2, 3, 2);
heat_data = zeros(num_stages, 4);
% 收集所有阶段的供热设备容量
for s = 1:num_stages
    heat_data(s, 1) = results.stages{s}.EBg.n * params.technical.EBg.Q_max;  % EBg
    heat_data(s, 2) = results.stages{s}.HPg.n * params.technical.HPg.Q_max;  % HPg
    heat_data(s, 3) = results.stages{s}.EBe.n * params.technical.EBe.Q_max;  % EBe
    heat_data(s, 4) = results.stages{s}.HPe.n * params.technical.HPe.Q_max;  % HPe
end
h = bar(heat_data, 'stacked');
colors_heat_array = [colors_heat.EBg; colors_heat.HPg; colors_heat.EBe; colors_heat.HPe];
for i = 1:4
    set(h(i), 'FaceColor', colors_heat_array(i,:));
end
legend('EBg', 'HPg', 'EBe', 'HPe', 'Location', 'northwest');
xlabel('规划阶段');
ylabel('装机容量 (MW)');
title('各阶段供热设备装机容量');
set(gca, 'XTickLabel', x_years);
grid on;

% 1.3 储能设备容量
subplot(2, 3, 3);
storage_data = [results.summary.ESS_cap; results.summary.TES_cap]';
h = bar(storage_data, 'stacked');
colors_storage_array = [colors_storage.ESS; colors_storage.TES];
for i = 1:2
    set(h(i), 'FaceColor', colors_storage_array(i,:));
end
legend('电储能 (MWh)', '热储能 (MWh)', 'Location', 'northwest');
xlabel('规划阶段');
ylabel('储能容量 (MWh)');
title('各阶段储能容量');
set(gca, 'XTickLabel', x_years);
grid on;

% 1.4 新增发电设备容量
subplot(2, 3, 4);
power_new_data = [results.summary.CCGT_n_new * params.technical.CCGT.P_max; results.summary.PV_instal_new; results.summary.WT_instal_new]';
h = bar(power_new_data, 'stacked');
for i = 1:3
    set(h(i), 'FaceColor', colors_power_array(i,:));
end
legend('CCGT新增', 'PV新增', 'WT新增', 'Location', 'northwest');
xlabel('规划阶段');
ylabel('新增装机容量 (MW)');
title('各阶段新增发电设备容量');
set(gca, 'XTickLabel', x_years);
grid on;

% 1.5 新增供热设备容量
subplot(2, 3, 5);
heat_new_data = zeros(num_stages, 4);
if isfield(results.summary, 'EBg_n_new')
    for s = 1:num_stages
        heat_new_data(s, 1) = results.summary.EBg_n_new(s) * params.technical.EBg.Q_max;  % EBg
        heat_new_data(s, 2) = results.summary.HPg_n_new(s) * params.technical.HPg.Q_max;  % HPg
        heat_new_data(s, 3) = results.summary.EBe_n_new(s) * params.technical.EBe.Q_max;  % EBe
        heat_new_data(s, 4) = results.summary.HPe_n_new(s) * params.technical.HPe.Q_max;  % HPe
    end
end
h = bar(heat_new_data, 'stacked');
for i = 1:4
    set(h(i), 'FaceColor', colors_heat_array(i,:));
end
legend('EBg新增', 'HPg新增', 'EBe新增', 'HPe新增', 'Location', 'northwest');
xlabel('规划阶段');
ylabel('新增装机容量 (MW)');
title('各阶段新增供热设备装机容量');
set(gca, 'XTickLabel', x_years);
grid on;

% 1.6 新增储能容量
subplot(2, 3, 6);
storage_new_data = [results.summary.ESS_cap_new; results.summary.TES_cap_new]';
h = bar(storage_new_data, 'stacked');
for i = 1:2
    set(h(i), 'FaceColor', colors_storage_array(i,:));
end
legend('电储能新增 (MWh)', '热储能新增 (MWh)', 'Location', 'northwest');
xlabel('规划阶段');
ylabel('新增储能容量 (MWh)');
title('各阶段新增储能容量');
set(gca, 'XTickLabel', x_years);
grid on;

%% 2. 成本结果分析
figure('Name', '多阶段成本结果分析', 'Position', [120, 120, 1200, 800]);

% 2.1 各阶段总成本
subplot(2, 2, 1);
total_costs = zeros(num_stages, 1);
if isfield(results.cost_details, 'stage_costs')
    total_costs = results.cost_details.stage_costs;
else
    % 如果没有预计算的stage_costs，则计算每个阶段的总成本
    for s = 1:num_stages
        if isfield(results.cost_details, 'stage') && length(results.cost_details.stage) >= s
            stage_cost = results.cost_details.stage{s};
            total_costs(s) = stage_cost.Total_CAPEX + stage_cost.cost_fuel + ...
                stage_cost.Total_OPEX + stage_cost.cost_ramp + stage_cost.cost_onoff + ...
                stage_cost.cost_net + stage_cost.cost_CO2 + stage_cost.cost_curtail;
        end
    end
end
bar(total_costs);
xlabel('规划阶段');
ylabel('总成本 (万元)');
title('各阶段总成本');
set(gca, 'XTickLabel', x_years);
grid on;

% 2.2 资本成本和运行成本占比
subplot(2, 2, 2);
capex = zeros(num_stages, 1);
opex = zeros(num_stages, 1);

if isfield(results.cost_details, 'CAPEX_stages') && isfield(results.cost_details, 'OPEX_stages')
    % 如果已有预计算的数据
    capex = results.cost_details.CAPEX_stages;
    opex = results.cost_details.OPEX_stages;
else
    % 否则从stage单元格数组中提取
    for s = 1:num_stages
        if isfield(results.cost_details, 'stage') && length(results.cost_details.stage) >= s
            capex(s) = results.cost_details.stage{s}.Total_CAPEX;
            opex(s) = results.cost_details.stage{s}.Total_OPEX;
        end
    end
end

bar([capex, opex], 'stacked');
legend('CAPEX', 'OPEX', 'Location', 'northwest');
xlabel('规划阶段');
ylabel('成本 (万元)');
title('各阶段资本成本和运行成本');
set(gca, 'XTickLabel', x_years);
grid on;

% 2.3 碳排放
subplot(2, 2, 3);
bar(results.summary.annual_co2_emissions);
xlabel('规划阶段');
ylabel('CO2排放量 (吨)');
title('各阶段年均碳排放量');
set(gca, 'XTickLabel', x_years);
grid on;

% 2.4 累计总成本
subplot(2, 2, 4);
cumulative_cost = cumsum(total_costs);
plot(1:num_stages, cumulative_cost, '-o', 'LineWidth', 2);
xlabel('规划阶段');
ylabel('累计成本 (万元)');
title('累计总成本');
set(gca, 'XTickLabel', x_years);
grid on;

%% 3. 第一阶段典型日运行曲线
figure('Name', '第一阶段典型日运行曲线', 'Position', [140, 140, 1200, 800]);

% 获取第一阶段数据
stage1 = results.stages{1};
hours = 1:24; % 假设24小时

% 定义电力和热力相关颜色
colors_elec = struct();
colors_elec.CCGT = [0.57, 0.24, 0.59];      % 紫色
colors_elec.PV = [0.929, 0.361, 0.271];     % 红色
colors_elec.WT = [0.294, 0.384, 0.969];     % 蓝色
colors_elec.ESS_disc = [0.835, 0.561, 0.200]; % 橙色
colors_elec.Grid_buy = [0.7, 0.7, 0.7];     % 灰色
colors_elec.EBe = [0.9290, 0.6940, 0.1250]; % 黄色
colors_elec.HPe = [0.522, 0.710, 0.714];    % 青色
colors_elec.ESS_char = [0.329, 0.620, 0.329]; % 绿色
colors_elec.Grid_sell = [0.220, 0.341, 0.141]; % 深绿色

colors_heat = struct();
colors_heat.EBg = [0.318, 0.706, 0.918];    % 浅蓝色
colors_heat.HPg = [0.741, 0.537, 0.518];    % 粉色
colors_heat.EBe = [0.945, 0.800, 0.341];    % 浅黄色
colors_heat.HPe = [0.522, 0.710, 0.714];    % 青色
colors_heat.TES_disc = [0.835, 0.561, 0.200]; % 橙色
colors_heat.TES_char = [0.5, 0.5, 0.5];     % 灰色

% 3.1 电力供需平衡
subplot(2, 2, 1);
hold on;
plot(hours, stage1.grid.P_buy(1:24), 'LineWidth', 1.5, 'Color', colors_elec.Grid_buy);
plot(hours, stage1.grid.P_sell(1:24), 'LineWidth', 1.5, 'Color', colors_elec.Grid_sell);
plot(hours, stage1.CCGT.P(1:24), 'LineWidth', 1.5, 'Color', colors_elec.CCGT);
plot(hours, stage1.PV.P(1:24), 'LineWidth', 1.5, 'Color', colors_elec.PV);
plot(hours, stage1.WT.P(1:24), 'LineWidth', 1.5, 'Color', colors_elec.WT);
plot(hours, stage1.ESS.P_disc(1:24), 'LineWidth', 1.5, 'Color', colors_elec.ESS_disc);
plot(hours, -stage1.ESS.P_char(1:24), 'LineWidth', 1.5, 'Color', colors_elec.ESS_char);
plot(hours, -stage1.EBe.P(1:24), 'LineWidth', 1.5, 'Color', colors_elec.EBe);
plot(hours, -stage1.HPe.P(1:24), 'LineWidth', 1.5, 'Color', colors_elec.HPe);
hold off;
legend('电网购电', '电网售电', 'CCGT', 'PV', 'WT', 'ESS放电', 'ESS充电', 'EBe', 'HPe', 'Location', 'eastoutside');
xlabel('小时');
ylabel('功率 (MW)');
title('第一阶段典型日电力供需平衡');
grid on;

% 3.2 热力供需平衡
subplot(2, 2, 2);
hold on;
plot(hours, stage1.CCGT.P(1:24) * params.technical.CCGT.eta_h / params.technical.CCGT.eta, 'LineWidth', 1.5, 'Color', colors_elec.CCGT);
plot(hours, stage1.EBg.Q(1:24), 'LineWidth', 1.5, 'Color', colors_heat.EBg);
plot(hours, stage1.HPg.Q(1:24), 'LineWidth', 1.5, 'Color', colors_heat.HPg);
plot(hours, stage1.EBe.Q(1:24), 'LineWidth', 1.5, 'Color', colors_heat.EBe);
plot(hours, stage1.HPe.Q(1:24), 'LineWidth', 1.5, 'Color', colors_heat.HPe);
plot(hours, stage1.TES.P_disc(1:24), 'LineWidth', 1.5, 'Color', colors_heat.TES_disc);
plot(hours, -stage1.TES.P_char(1:24), 'LineWidth', 1.5, 'Color', colors_heat.TES_char);
hold off;
legend('CCGT热', 'EBg', 'HPg', 'EBe', 'HPe', 'TES放热', 'TES蓄热', 'Location', 'eastoutside');
xlabel('小时');
ylabel('热功率 (MW)');
title('第一阶段典型日热力供需平衡');
grid on;

% 3.3 电储能运行状态
subplot(2, 2, 3);
yyaxis left;
stairs(hours, stage1.ESS.P_char(1:24), 'Color', colors_elec.ESS_char, 'LineWidth', 1.5);
hold on;
stairs(hours, -stage1.ESS.P_disc(1:24), 'Color', colors_elec.ESS_disc, 'LineWidth', 1.5, 'LineStyle', '--');
ylabel('功率 (MW)');
yyaxis right;
plot(hours, stage1.ESS.SOC(1:24)./results.stages{1}.ESS.cap, 'r-', 'LineWidth', 1.5);
ylabel('SOC');
hold off;
legend('充电功率', '放电功率', 'SOC', 'Location', 'best');
xlabel('小时');
title('第一阶段典型日电储能运行状态');
grid on;

% 3.4 热储能运行状态
subplot(2, 2, 4);
yyaxis left;
stairs(hours, stage1.TES.P_char(1:24), 'Color', colors_heat.TES_char, 'LineWidth', 1.5);
hold on;
stairs(hours, -stage1.TES.P_disc(1:24), 'Color', colors_heat.TES_disc, 'LineWidth', 1.5, 'LineStyle', '--');
ylabel('功率 (MW)');
yyaxis right;
plot(hours, stage1.TES.SOT(1:24)./results.stages{1}.TES.cap, 'r-', 'LineWidth', 1.5);
ylabel('SOT');
hold off;
legend('充热功率', '放热功率', 'SOT', 'Location', 'best');
xlabel('小时');
title('第一阶段典型日热储能运行状态');
grid on;

%% 4. 多阶段电力系统结构演变
figure('Name', '多阶段电力系统结构演变', 'Position', [160, 160, 1200, 800]);

% 将颜色转换为数组，便于后续索引
colors_power_array = [colors_power.CCGT; colors_power.PV; colors_power.WT];
colors_heat_array = [colors_heat.EBg; colors_heat.HPg; colors_heat.EBe; colors_heat.HPe];
colors_storage_array = [colors_storage.ESS; colors_storage.TES];

% 4.1 电力系统装机占比变化
for s = 1:num_stages
    subplot(3, num_stages, s);
    labels = {'CCGT', 'PV', 'WT'};
    capacities = [results.stages{s}.CCGT.n * params.technical.CCGT.P_max, results.stages{s}.PV.instal, results.stages{s}.WT.instal];
    p = pie(capacities);
    % 设置饼图颜色
    for i = 1:length(labels)
        set(p(2*i-1), 'FaceColor', colors_power_array(i,:));
    end
    title(['第', num2str(s), '阶段发电装机占比']);
    legend(labels, 'Location', 'southoutside', 'Orientation', 'horizontal');
end

% 4.2 供热系统装机占比变化
for s = 1:num_stages
    subplot(3, num_stages, s + num_stages);
    labels = {'EBg', 'HPg', 'EBe', 'HPe'};
    capacities = [
        results.stages{s}.EBg.n * params.technical.EBg.Q_max,
        results.stages{s}.HPg.n * params.technical.HPg.Q_max,
        results.stages{s}.EBe.n * params.technical.EBe.Q_max,
        results.stages{s}.HPe.n * params.technical.HPe.Q_max
    ];
    p = pie(capacities);
    % 设置饼图颜色
    for i = 1:length(labels)
        set(p(2*i-1), 'FaceColor', colors_heat_array(i,:));
    end
    title(['第', num2str(s), '阶段供热装机占比']);
    legend(labels, 'Location', 'southoutside', 'Orientation', 'horizontal');
end

% 4.3 储能系统容量变化
for s = 1:num_stages
    subplot(3, num_stages, s + 2*num_stages);
    labels = {'电储能', '热储能'};
    capacities = [results.stages{s}.ESS.cap, results.stages{s}.TES.cap];
    p = pie(capacities);
    % 设置饼图颜色
    for i = 1:length(labels)
        set(p(2*i-1), 'FaceColor', colors_storage_array(i,:));
    end
    title(['第', num2str(s), '阶段储能容量占比']);
    legend(labels, 'Location', 'southoutside', 'Orientation', 'horizontal');
end

end 