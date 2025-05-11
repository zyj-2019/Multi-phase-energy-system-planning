function plot_yearly_capacity_and_cost(results, params)
% 按年度展示装机和成本趋势，而不是按阶段
%
% 输入参数:
%   results: 包含优化结果的结构体
%   params: 包含系统参数的结构体

% 获取规划期相关参数
num_stages = params.multistage.num_stages;
years_per_stage = params.multistage.years_per_stage;
total_years = params.multistage.total_years;

% 获取起始年份和各阶段年份范围
start_year = params.multistage.stage_start_years(1); % 2026
end_year = params.multistage.stage_end_years(end);   % 2060

% 创建完整年份序列
years = start_year:end_year;

% --- 初始化各设备和成本的年度数据数组 ---
% 容量数据
CCGT_yearly = zeros(1, total_years);
PV_yearly = zeros(1, total_years);
WT_yearly = zeros(1, total_years);
ESS_yearly = zeros(1, total_years);
TES_yearly = zeros(1, total_years);

% 成本数据
CAPEX_yearly = zeros(1, total_years);
OPEX_yearly = zeros(1, total_years);
fuel_yearly = zeros(1, total_years);
grid_yearly = zeros(1, total_years);
CO2_yearly = zeros(1, total_years);
total_cost_yearly = zeros(1, total_years);

% --- 填充各年份的装机容量数据 ---
year_index = 1;

for stage = 1:num_stages
    stage_years = years_per_stage(stage);
    stage_capacity = struct();
    
    % 获取当前阶段的装机容量
    stage_capacity.CCGT = results.summary.CCGT_n(stage);
    stage_capacity.PV = results.summary.PV_instal(stage);
    stage_capacity.WT = results.summary.WT_instal(stage);
    stage_capacity.ESS = results.summary.ESS_cap(stage);
    stage_capacity.TES = results.summary.TES_cap(stage);
    
    % 获取成本数据（按年平均）
    if isfield(results.cost_details, 'stage') && length(results.cost_details.stage) >= stage
        stage_cost = results.cost_details.stage{stage};
        
        % 确保所有成本都是数值类型
        capex = double(value(stage_cost.Total_CAPEX)) / stage_years;
        opex = double(value(stage_cost.Total_OPEX)) / stage_years;
        fuel = double(value(stage_cost.cost_fuel)) / stage_years;
        net = double(value(stage_cost.cost_net)) / stage_years;
        co2 = double(value(stage_cost.cost_CO2)) / stage_years;
        
        % 计算年均总成本
        yearly_total = capex + opex + fuel + net + co2;
    else
        % 如果没有成本数据，设为0
        capex = 0;
        opex = 0;
        fuel = 0;
        net = 0;
        co2 = 0;
        yearly_total = 0;
    end
    
    % 确定设备退役年份（基于设备寿命）
    retire_years = struct();
    
    % 根据设备寿命标记特殊的退役年份
    if ~isempty(params.technical.WT.retire_in_stage) && any(params.technical.WT.retire_in_stage == stage)
        % 如果风电设备在当前阶段需要退役
        retire_years.WT = params.multistage.stage_start_years(stage);
    end
    
    if ~isempty(params.technical.PV.retire_in_stage) && any(params.technical.PV.retire_in_stage == stage)
        % 如果光伏设备在当前阶段需要退役
        retire_years.PV = params.multistage.stage_start_years(stage);
    end
    
    if ~isempty(params.technical.ESS.retire_in_stage) && any(params.technical.ESS.retire_in_stage == stage)
        % 如果储能设备在当前阶段需要退役
        retire_years.ESS = params.multistage.stage_start_years(stage);
    end
    
    % 填充该阶段中每一年的数据
    for y = 1:stage_years
        % 计算实际年份在数组中的位置
        current_year = start_year + year_index - 1;
        
        % 装机容量数据
        CCGT_yearly(year_index) = stage_capacity.CCGT;
        PV_yearly(year_index) = stage_capacity.PV;
        WT_yearly(year_index) = stage_capacity.WT;
        ESS_yearly(year_index) = stage_capacity.ESS;
        TES_yearly(year_index) = stage_capacity.TES;
        
        % 成本数据 - 通常第一年有投资成本，后续年份主要是运行成本
        if y == 1
            % 第一年包含投资成本
            CAPEX_yearly(year_index) = capex * stage_years; % 将总投资成本全部计入第一年
        else
            % 后续年份无投资成本
            CAPEX_yearly(year_index) = 0; 
        end
        
        % 其他年度成本保持一致
        OPEX_yearly(year_index) = opex;
        fuel_yearly(year_index) = fuel;
        grid_yearly(year_index) = net;
        CO2_yearly(year_index) = co2;
        
        % 计算年度总成本
        if y == 1
            total_cost_yearly(year_index) = CAPEX_yearly(year_index) + opex + fuel + net + co2;
        else
            total_cost_yearly(year_index) = opex + fuel + net + co2;
        end
        
        % 退役年份特殊处理 - 增加退役成本或标记
        if isfield(retire_years, 'WT') && current_year == retire_years.WT
            % 风电退役年份的特殊处理
            CAPEX_yearly(year_index) = CAPEX_yearly(year_index) + stage_capacity.WT * 0.1; % 假设退役成本为装机容量的10%
        end
        
        if isfield(retire_years, 'PV') && current_year == retire_years.PV
            % 光伏退役年份的特殊处理
            CAPEX_yearly(year_index) = CAPEX_yearly(year_index) + stage_capacity.PV * 0.1;
        end
        
        if isfield(retire_years, 'ESS') && current_year == retire_years.ESS
            % 储能退役年份的特殊处理
            CAPEX_yearly(year_index) = CAPEX_yearly(year_index) + stage_capacity.ESS * 0.05;
        end
        
        % 移至下一年
        year_index = year_index + 1;
    end
end

%% 创建可视化图表
figure('Name', '年度装机容量趋势', 'Position', [100, 100, 1200, 800]);

% 1. 发电设备容量年度趋势
subplot(2, 2, 1);
plot(years, CCGT_yearly, '-o', 'LineWidth', 2);
hold on;
plot(years, PV_yearly, '-s', 'LineWidth', 2);
plot(years, WT_yearly, '-^', 'LineWidth', 2);
hold off;
legend('CCGT (台)', 'PV (MW)', 'WT (MW)', 'Location', 'best');
xlabel('年份');
ylabel('装机容量');
title('发电设备年度装机容量趋势');
grid on;

% 2. 储能容量年度趋势
subplot(2, 2, 2);
plot(years, ESS_yearly, '-o', 'LineWidth', 2);
hold on;
plot(years, TES_yearly, '-s', 'LineWidth', 2);
hold off;
legend('电储能 (MWh)', '热储能 (MWh)', 'Location', 'best');
xlabel('年份');
ylabel('储能容量 (MWh)');
title('储能系统年度容量趋势');
grid on;

% 3. 年度成本细分趋势
subplot(2, 2, 3);
plot(years, CAPEX_yearly, '-o', 'LineWidth', 2);
hold on;
plot(years, OPEX_yearly, '-s', 'LineWidth', 2);
plot(years, fuel_yearly, '-^', 'LineWidth', 2);
plot(years, grid_yearly, '-*', 'LineWidth', 2);
plot(years, CO2_yearly, '-d', 'LineWidth', 2);
hold off;
legend('投资成本', '运维成本', '燃料成本', '电网成本', '碳成本', 'Location', 'best');
xlabel('年份');
ylabel('成本 ($)');
title('年度成本细分趋势');
grid on;

% 4. 总成本年度趋势
subplot(2, 2, 4);
plot(years, total_cost_yearly, '-o', 'LineWidth', 2);
hold on;
plot(years, cumsum(total_cost_yearly), '--', 'LineWidth', 2);
hold off;
legend('年度总成本', '累计总成本', 'Location', 'best');
xlabel('年份');
ylabel('成本 ($)');
title('年度总成本及累计成本趋势');
grid on;

% 标记关键的退役/决策年份
% 获取退役年份
retire_years = [];
for stage = 1:num_stages
    if stage > 1 % 第一阶段之后的阶段都可能有退役
        retire_years = [retire_years, params.multistage.stage_start_years(stage)];
    end
end

% 在所有子图上标记退役年份
for i = 1:4
    subplot(2, 2, i);
    for yr = retire_years
        if yr <= end_year && yr >= start_year
            % 找出年份在数组中的索引
            yr_idx = yr - start_year + 1;
            % 添加垂直线标记退役年份
            line([yr yr], ylim, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5);
            % 添加文本标记
            yl = ylim;
            text(yr, yl(2)*0.9, [num2str(yr) '年'], 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        end
    end
end

% 保存当前图像
if params.save_plot
    saveas(gcf, 'yearly_capacity_and_cost_trends.png');
    saveas(gcf, 'yearly_capacity_and_cost_trends.fig');
end

end 