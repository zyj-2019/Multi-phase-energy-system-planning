function visualize_results(results, cost, params)
% 可视化优化结果
%
% 输入参数：
%   results: 包含数值结果的结构体
%   params: 包含所有系统参数和预处理数据的结构体
%
% 注意：
% 该文件已经进行了简化，移除了单阶段图表的绘制，仅保留多阶段规划图表。
% 如需单阶段图表，请参考原始版本。

if ~isfield(results, 'diagnosis') || results.diagnosis.problem ~= 0
    disp('优化未成功求解，无法生成结果图。');
    return;
end

%% 提取需要的数据
% 时间轴
t = params.num_time_steps;
t_resolution_h = params.time.resolution / 60;
Time_total = cumsum([0; t_resolution_h(1:t-1)]); % 累积小时数

% 负荷
DMD_E = params.load.P;
DMD_H = params.load.H;

% 运行结果
P_CCGT = results.CCGT.P;
P_PV = results.PV.P;
P_WT = results.WT.P;
Q_EBg = results.EBg.Q;
Q_HPg = results.HPg.Q;
Q_EBe = results.EBe.Q;  % 电锅炉输出热功率
Q_HPe = results.HPe.Q;  % 电热泵输出热功率
P_EBe = results.EBe.P;  % 电锅炉输入功率
P_HPe = results.HPe.P;  % 电热泵输入功率
P_ESS_char = results.ESS.P_char;
P_ESS_disc = results.ESS.P_disc;
SOC_ESS = results.ESS.SOC;
P_TES_char = results.TES.P_char;
P_TES_disc = results.TES.P_disc;
SOC_TES = results.TES.SOT;
P_buy = results.grid.P_buy;
P_sell = results.grid.P_sell;

% %% 绘图
% figure_count = 1;
% 
% % --- 1. 电功率平衡图 ---
% figure(figure_count); figure_count = figure_count + 1;
% hold on;
% 
% % 创建堆叠面积图（供应侧）
% area_supply_handles = area(Time_total, [results.CCGT.P, results.PV.P, results.WT.P, results.ESS.P_disc, results.grid.P_buy]);
% 
% % 创建堆叠面积图（需求侧，除了负荷）
% area_demand_handles = area(Time_total, [-results.EBe.P, -results.HPe.P, -results.ESS.P_char, -results.grid.P_sell]);
% 
% % 绘制负荷曲线（正半轴）
% plot(Time_total, params.load.P, 'r-', 'LineWidth', 1.5);
% 
% % 保持原来的颜色设置
% set(area_supply_handles(1), 'FaceColor', [0.57 0.24 0.59]); % CCGT
% set(area_supply_handles(2), 'FaceColor', [0.929, 0.361, 0.271]); % PV
% set(area_supply_handles(3), 'FaceColor', [0.294, 0.384, 0.969]); % WT
% set(area_supply_handles(4), 'FaceColor', [0.835, 0.561, 0.200]); % ESS Discharge
% set(area_supply_handles(5), 'FaceColor', [0.7 0.7 0.7]); % Grid Buy
% 
% set(area_demand_handles(1), 'FaceColor', [0.9290 0.6940 0.1250]); % EBe
% set(area_demand_handles(2), 'FaceColor', [0.522, 0.710, 0.714]); % HPe
% set(area_demand_handles(3), 'FaceColor', [0.329, 0.620, 0.329]); % ESS Charge
% set(area_demand_handles(4), 'FaceColor', [0.220, 0.341, 0.141]); % Grid Sell
% 
% % 添加图例
% legend_handles = [area_supply_handles, area_demand_handles, plot(Time_total, params.load.P, 'r-', 'LineWidth', 1.5)];
% legend_labels = {'CCGT', 'PV', 'WT', 'ESS Discharge', 'Grid Buy', 'EBe', 'HPe', 'ESS Charge', 'Grid Sell', 'Load'};
% legend(legend_handles, legend_labels, 'Location', 'eastoutside');
% 
% % 设置x轴标签
% xlabel('Time (h)');
% ylabel('Power (MW)');
% title('Electric Power Balance');
% grid on;
% 
% % 设置x轴范围和刻度
% xlim([0 144]);
% xticks(0:24:144);
% xticklabels({'0', '24', '48', '72', '96', '120', '144'});
% 
% % 获取y轴范围
% y_limits = ylim;
% 
% % 添加天数标记
% for i = 1:6
%     text(i*24-12, y_limits(1), ['Day ', num2str(i)], ...
%         'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
% end
% 
% % --- 2. 热功率平衡图 ---
% figure(figure_count); figure_count = figure_count + 1;
% hold on;
% 
% % 定义自定义颜色
% colors_supply_h = [
%     0.318, 0.706, 0.918;   % EBg
%     0.741, 0.537, 0.518;   % HPg
%     0.945, 0.800, 0.341;   % EBe
%     0.522, 0.710, 0.714;   % HPe
%     0.835, 0.561, 0.200;   % TES Discharge
% ];
% 
% colors_demand_h = [
%     0.5 0.5 0.5    % TES Charge - 灰色
% ];
% 
% QQ_supply = [Q_EBg, Q_HPg, Q_EBe, Q_HPe, P_TES_disc];
% QQ_demand = [P_TES_char];
% 
% % 计算累积供应量
% QQ_supply_cum = cumsum(QQ_supply, 2);
% 
% % 绘制供应侧（正半轴，叠加显示）
% for i = size(QQ_supply, 2):-1:1
%     if i == 1
%         area_supply_handles_h(i) = area(Time_total, QQ_supply_cum(:,i), 'FaceColor', colors_supply_h(i,:));
%     else
%         area_supply_handles_h(i) = area(Time_total, QQ_supply_cum(:,i), 'FaceColor', colors_supply_h(i,:));
%         hold on;
%     end
% end
% 
% % 绘制需求侧（负半轴）
% for i = 1:size(QQ_demand, 2)
%     area_demand_handles_h(i) = area(Time_total, -QQ_demand(:,i), 'FaceColor', colors_demand_h(i,:));
% end
% 
% % 绘制负荷曲线
% load_handle = plot(Time_total, DMD_H, 'r-', 'LineWidth', 1.5);
% hold off;
% 
% % 添加图例
% legend_handles = [area_supply_handles_h, area_demand_handles_h, load_handle];
% legend_labels = {'EBg', 'HPg', 'EBe', 'HPe', 'TES Discharge', 'TES Charge', 'Load'};
% legend(legend_handles, legend_labels, 'Location', 'eastoutside');
% 
% % 设置x轴标签
% xlabel('Time (h)');
% ylabel('Heat (MW)');
% title('Heat Power Balance');
% grid on;
% 
% % 设置x轴范围和刻度
% xlim([0 144]);
% xticks(0:24:144);
% xticklabels({'0', '24', '48', '72', '96', '120', '144'});
% 
% % 获取y轴范围
% y_limits = ylim;
% 
% % 添加天数标记
% for i = 1:6
%     text(i*24-12, y_limits(1), ['Day ', num2str(i)], ...
%         'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
% end
% 
% % --- 3. 储能状态图 --- (假设不变)
% figure(figure_count); figure_count = figure_count + 1;
% subplot(2,1,1);
% yyaxis left;
% stairs(Time_total, P_ESS_char, 'b-');
% hold on;
% stairs(Time_total, -P_ESS_disc, 'b--');
% ylabel('Power (MW)');
% yyaxis right;
% plot(Time_total, SOC_ESS(1:t)./results.ESS.cap, 'r-', 'LineWidth', 1.5); % 绘制 SOC 比例
% ylabel('SOC');
% hold off;
% title('Electric Storage (ESS)');
% legend('Charge', 'Discharge', 'SOC');
% xlabel('Time (hours)');
% grid on;
% 
% subplot(2,1,2);
% yyaxis left;
% stairs(Time_total, P_TES_char, 'b-');
% hold on;
% stairs(Time_total, -P_TES_disc, 'b--');
% ylabel('Power (MW)');
% yyaxis right;
% plot(Time_total, SOC_TES(1:t)./results.TES.cap, 'r-', 'LineWidth', 1.5);
% ylabel('SOT');
% hold off;
% title('Thermal Storage (TES)');
% legend('Charge', 'Discharge', 'SOT');
% xlabel('Time (hours)');
% grid on;
% 
% % --- 4. 可再生能源出力与弃电图 --- (假设不变)
% figure(figure_count); figure_count = figure_count + 1;
% subplot(2,1,1);
% P_PV_avail = results.PV.instal * params.renewable.PV_potential;
% plot(Time_total, P_PV_avail, 'k--', 'LineWidth', 1); % 可用功率
% hold on;
% area(Time_total, results.PV.P, 'FaceColor', 'y', 'EdgeColor', 'none'); % 发电量
% area(Time_total, results.PV.curtail, 'FaceColor', 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.5); % 弃电量
% hold off;
% title('PV Generation and Curtailment');
% xlabel('Time (hours)');
% ylabel('Power (MW)');
% legend('Available', 'Generation', 'Curtailment');
% grid on;
% 
% subplot(2,1,2);
% P_WT_avail = results.WT.instal * params.renewable.WT_potential;
% plot(Time_total, P_WT_avail, 'k--', 'LineWidth', 1);
% hold on;
% area(Time_total, results.WT.P, 'FaceColor', 'b', 'EdgeColor', 'none');
% area(Time_total, results.WT.curtail, 'FaceColor', 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.5);
% hold off;
% title('Wind Generation and Curtailment');
% xlabel('Time (hours)');
% ylabel('Power (MW)');
% legend('Available', 'Generation', 'Curtailment');
% grid on;
% 
% 
% % --- 5. 设备容量配置柱状图 --- 
% figure(figure_count); figure_count = figure_count + 1;
% capacities = [
%     results.CCGT.n * params.technical.CCGT.P_max, ...
%     results.PV.instal, ...
%     results.WT.instal, ...
%     results.EBg.n * params.technical.EBg.Q_max, ... % 新增 EBg 容量
%     results.HPg.n * params.technical.HPg.Q_max, ... % 新增 HPg 容量
%     results.EBe.n * params.technical.EBe.Q_max, ... % 新增 EBe 容量
%     results.HPe.n * params.technical.HPe.Q_max, ... % 新增 HPe 容量
%     results.ESS.cap, ... % 容量单位 MWh
%     results.TES.cap  ... % 容量单位 MWh
% ];
% cap_labels = {'CCGT (MW)', 'PV (MW)', 'WT (MW)', 'EBg (MW)', 'HPg (MW)', 'EBe (MW)', 'HPe (MW)', 'ESS (MWh)', 'TES (MWh)'};
% bar(capacities);
% set(gca, 'xticklabel', cap_labels);
% ylabel('Capacity');
% title('Installed Capacities');
% grid on;
% ylim([0 2000]); % 设置y轴上限为2000MW



%% 导出数据到Excel
% 1. 创建数据表格
% 设备装机数据
capacity_headers = {'CCGT装机容量', 'PV装机容量', 'WT装机容量', 'EBe装机容量', 'EBg装机容量', 'HPe装机容量', 'HPg装机容量', 'ESS装机容量', 'TES装机容量'};
capacity_values = {
    results.CCGT.n * params.technical.CCGT.P_max, ...
    results.PV.instal, ...
    results.WT.instal, ...
    results.EBe.n * params.technical.EBe.Q_max, ...
    results.EBg.n * params.technical.EBg.Q_max, ...
    results.HPe.n * params.technical.HPe.Q_max, ...
    results.HPg.n * params.technical.HPg.Q_max, ...
    results.ESS.cap, ...
    results.TES.cap
};

% 成本数据
cost_headers = {'投资成本', '运维成本', '爬坡成本', '启停成本', '燃料成本', '电网交互成本', '碳排放成本', '弃电成本', '总成本'};
cost_values = {
    results.Total_CAPEX, ...
    results.Total_OPEX, ...
    results.cost_ramp, ...
    results.cost_onoff, ...
    results.cost_fuel, ...
    results.cost_net, ...
    results.cost_CO2, ...
    results.cost_curtail, ...
    sum([results.Total_CAPEX, results.Total_OPEX, results.cost_ramp, ...
         results.cost_onoff, results.cost_fuel, results.cost_net, ...
         results.cost_CO2, results.cost_curtail])
};

% 碳排放数据
% 计算年碳排放量
% 1. 计算燃气设备的碳排放
gas_emission_CCGT = sum(results.CCGT.P .* t_resolution_h) * params.input.annual_factor / params.technical.CCGT.eta * params.environment.gas_CO2;
gas_emission_EBg = sum(results.EBg.Q .* t_resolution_h) * params.input.annual_factor / params.technical.EBg.eta * params.environment.gas_CO2;
gas_emission_HPg = sum(results.HPg.Q .* t_resolution_h) * params.input.annual_factor / params.technical.HPg.COP * params.environment.gas_CO2;

% 2. 计算电网购电的碳排放
grid_emission = sum(results.grid.P_buy .* t_resolution_h) * params.input.annual_factor * params.environment.grid_CO2;

% 3. 计算总碳排放量
total_CO2_emission = gas_emission_CCGT + gas_emission_EBg + gas_emission_HPg + grid_emission;

emission_headers = {'年碳排放量'};
emission_values = {
    total_CO2_emission
};

% 可再生能源数据
% 计算总装机容量
total_capacity = results.CCGT.n * params.technical.CCGT.P_max + ...
                results.PV.instal + results.WT.instal ;

% 计算可再生能源装机容量
re_capacity = results.PV.instal + results.WT.instal;

% 计算可再生能源发电量
re_generation = sum(results.PV.P .* t_resolution_h + results.WT.P .* t_resolution_h) * params.input.annual_factor;

% 计算总发电量
total_generation = sum(results.CCGT.P .* t_resolution_h + ...
                      results.PV.P .* t_resolution_h + ...
                      results.WT.P .* t_resolution_h) * params.input.annual_factor;

% 计算可再生能源利用率
re_utilization = re_generation / (sum(results.PV.instal * params.renewable.PV_potential .* t_resolution_h + ...
                                    results.WT.instal * params.renewable.WT_potential .* t_resolution_h) * params.input.annual_factor) * 100;

re_headers = {'可再生能源装机占比', '可再生能源发电量占比', '可再生能源利用率'};
re_values = {
    re_capacity/total_capacity*100, ...
    re_generation/total_generation*100, ...
    re_utilization
};

% 2. 写入Excel文件
filename = 'optimization_results.xlsx';

% 写入装机容量数据
writecell(capacity_headers, filename, 'Sheet', 1, 'Range', 'A1');
writecell(capacity_values, filename, 'Sheet', 1, 'Range', 'A2');

% 写入成本数据
writecell(cost_headers, filename, 'Sheet', 1, 'Range', 'A3');
writecell(cost_values, filename, 'Sheet', 1, 'Range', 'A4');

% 写入碳排放数据
writecell(emission_headers, filename, 'Sheet', 1, 'Range', 'A5');
writecell(emission_values, filename, 'Sheet', 1, 'Range', 'A6');

% 写入可再生能源数据
writecell(re_headers, filename, 'Sheet', 1, 'Range', 'A7');
writecell(re_values, filename, 'Sheet', 1, 'Range', 'A8');

disp('数据已导出到 optimization_results.xlsx');

%% 只绘制多阶段规划结果
if isfield(results, 'stages') && isfield(params, 'multistage')
    % 绘制多阶段规划结果
    plot_multistage_results(results, params);
    
    % 添加按年份展示的装机和成本趋势图
    plot_yearly_capacity_and_cost(results, params);
else
    disp('没有多阶段规划结果，无法生成多阶段图表。');
    
    % 提示用户已简化图表
    disp('已简化可视化，仅保留多阶段图表。');
end

end