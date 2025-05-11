function [Objective, cost_details] = build_objective(variables, params, stage)
% 构建优化模型的目标函数 (单阶段成本，不含折现)
%
% 输入参数：params 是 parameters.m 的输出
%   variables: 包含所有优化变量的结构体
%   params: 包含所有系统参数和预处理数据的结构体
%   stage: 当前阶段编号
%
% 输出参数：
%   Objective: YALMIP 目标函数表达式（未折现的阶段总成本）
%   cost_details: 包含各项成本明细的结构体

%% 提取常用变量和参数
I = params.economic.I; % 折现率
USD2CNY = params.economic.USD2CNY;

% 多阶段相关参数
num_stages = params.multistage.num_stages;
years_per_stage = params.multistage.years_per_stage;

% 初始化各阶段成本存储
cost_details = struct();

% 时间相关参数
t_resolution_h = params.time.resolution / 60; % 小时为单位
Day_weight = params.time.Day_weight;  % [60,60,60,60,60,60]
n_days = params.input.n;
annual_hours = sum(Day_weight) * 24; % 年化小时数 (基于典型日权重)
annual_factor = 60; % 年化因子 (基于典型日权重)等于365/n

% 当前阶段的阶段因子 (将典型日扩展为阶段总年数)
stage_factor = years_per_stage(stage); 

% 价格参数 - 当前阶段
% 天然气价格 ($/m^3)
price_gas = params.economic.price_gas; % 假设天然气价格在不同阶段保持不变
LHV_gas = params.environment.LHV_gas; % MJ/m^3

% 电网价格 ($/MWh) - 考虑阶段因子
price_grid_buy = params.stage_economic.grid_buy_price{stage}; % 当前阶段的购电价
price_grid_sell = params.economic.grid_price * params.multistage.grid_price_factor(stage); % 当前阶段的售电价

% 碳价 ($/tCO2) - 考虑阶段因子
CO2_cost = params.economic.stage_CO2_cost(stage); % 当前阶段的碳价

% 设备参数 - CCGT
P_max_CCGT = params.technical.CCGT.P_max;
eta_CCGT = params.technical.CCGT.eta;
year_CCGT = params.technical.CCGT.year;
invs_CCGT = params.economic.invs_CCGT; % 单位: $/MW
OM_fix_CCGT = params.economic.OM_fix_CCGT; % 单位: $/MW/year
OM_var_CCGT = params.economic.OM_var_CCGT; % 单位: $/MWh
price_ramp_CCGT = params.economic.price_ramp_CCGT; % $/ΔMW
n_CCGT_exist = params.technical.CCGT.n_exist;

% 设备参数 - PV
year_PV = params.technical.PV.year;
invs_PV = params.economic.invs_PV; % $/MW
OM_fix_PV = params.economic.OM_fix_PV; % $/MW/year
price_ramp_PV = params.economic.price_ramp_PV; % $/ΔMW (可能为0)

% 设备参数 - WT
year_WT = params.technical.WT.year;
invs_WT = params.economic.invs_WT; % $/MW
OM_fix_WT = params.economic.OM_fix_WT; % $/MW/year
price_ramp_WT = params.economic.price_ramp_WT; % $/ΔMW (可能为0)

% 设备参数 - EBg
Q_max_EBg = params.technical.EBg.Q_max;
eta_EBg = params.technical.EBg.eta;
year_EBg = params.technical.EBg.year;
invs_EBg = params.economic.invs_EBg; % $/MW
OM_fix_EBg = params.economic.OM_fix_EBg; % $/MW/year
OM_var_EBg = params.economic.OM_var_EBg; % $/MWh
price_ramp_EBg = params.economic.price_ramp_EBg; % $/ΔMW
n_EBg_exist = params.technical.EBg.n_exist;

% 设备参数 - HPg
Q_max_HPg = params.technical.HPg.Q_max;
COP_HPg = params.technical.HPg.COP;
year_HPg = params.technical.HPg.year;
invs_HPg = params.economic.invs_HPg; % $/MW
OM_fix_HPg = params.economic.OM_fix_HPg; % $/MW/year
OM_var_HPg = params.economic.OM_var_HPg; % $/MWh
price_ramp_HPg = params.economic.price_ramp_HPg; % $/ΔMW
n_HPg_exist = params.technical.HPg.n_exist;

% 设备参数 - EBe
Q_max_EBe = params.technical.EBe.Q_max;
eta_EBe = params.technical.EBe.eta;
year_EBe = params.technical.EBe.year;
invs_EBe = params.economic.invs_EBe; % $/MW
OM_fix_EBe = params.economic.OM_fix_EBe; % $/MW/year
OM_var_EBe = params.economic.OM_var_EBe; % $/MWh
price_ramp_EBe = params.economic.price_ramp_EBe; % $/ΔMW
n_EBe_exist = params.technical.EBe.n_exist;

% 设备参数 - HPe
Q_max_HPe = params.technical.HPe.Q_max;
eta_HPe = params.technical.HPe.eta;
year_HPe = params.technical.HPe.year;
invs_HPe = params.economic.invs_HPe; % $/MW
OM_fix_HPe = params.economic.OM_fix_HPe; % $/MW/year
OM_var_HPe = params.economic.OM_var_HPe; % $/MWh
price_ramp_HPe = params.economic.price_ramp_HPe; % $/ΔMW
n_HPe_exist = params.technical.HPe.n_exist;

% 设备参数 - ESS (储电)
year_ESS = params.technical.ESS.year;
invs_ESS_cap = params.economic.invs_str_E_1; % $/MWh (假设用E1的)
invs_ESS_power = 0; % 假设无功率成本? 或需补充
OM_var_ESS = params.economic.OM_var_E_1; % $/MWh (假设用E1的)
OM_fix_ESS = params.economic.OM_fix_E_1;
ESS_exist = 0;

% 设备参数 - TES (储热)
year_TES = params.technical.TES.year;
invs_TES_cap = params.economic.invs_str_H_s; % $/MWh (假设用储蒸汽H_s的)
invs_TES_power = 0; % 假设无功率成本? 或需补充
OM_var_TES = params.economic.OM_var_H_s; % $/MWh (假设用储蒸汽H_s的)
OM_fix_TES = params.economic.OM_fix_H_s; % $/MWh (假设用储蒸汽H_s的)
TES_exist = 0;

% 启停成本 ($/次)
price_onoff_CCGT = params.economic.price_onoff_CCGT; % 假设存在
price_onoff_EBg = params.economic.price_onoff_EBg;   % 假设存在
price_onoff_HPg = params.economic.price_onoff_HPg;   % 假设存在
price_onoff_EBe = params.economic.price_onoff_EBe;   % 假设存在
price_onoff_HPe = params.economic.price_onoff_HPe;   % 假设存在

% 弃电成本 ($/MWh)
price_PV_cur = params.economic.price_PV_cur; % 假设存在
price_WT_cur = params.economic.price_WT_cur; % 假设存在

%% --- 计算当前阶段各部分成本 ---

% 1. 投资成本 (当前阶段的新增投资)
% 计算各种设备的新增投资
cost_inv_CCGT = variables.CCGT.n_new(stage) * P_max_CCGT * invs_CCGT;
cost_inv_PV = variables.PV.instal_new(stage) * invs_PV;
cost_inv_WT = variables.WT.instal_new(stage) * invs_WT;
cost_inv_EBg = variables.EBg.n_new(stage) * Q_max_EBg * invs_EBg;
cost_inv_HPg = variables.HPg.n_new(stage) * Q_max_HPg * invs_HPg;
cost_inv_EBe = variables.EBe.n_new(stage) * Q_max_EBe * invs_EBe;
cost_inv_HPe = variables.HPe.n_new(stage) * Q_max_HPe * invs_HPe;
cost_inv_ESS = variables.ESS.cap_new(stage) * invs_ESS_cap;
cost_inv_TES = variables.TES.cap_new(stage) * invs_TES_cap;

Total_CAPEX = cost_inv_CCGT + cost_inv_PV + cost_inv_WT + cost_inv_EBg + cost_inv_HPg + cost_inv_EBe + cost_inv_HPe + cost_inv_ESS + cost_inv_TES;

% 2. 燃料成本 (当前阶段)
% 计算各设备时间序列的能量输出 (MWh)
E_CCGT_ts = variables.CCGT.P(:, stage) .* t_resolution_h;
E_EBg_ts = variables.EBg.Q(:, stage) .* t_resolution_h;
E_HPg_ts = variables.HPg.Q(:, stage) .* t_resolution_h;
E_buy_ts = variables.grid.P_buy(:, stage) .* t_resolution_h;

% 计算各设备时间序列的气耗 (m^3)
Gas_cons_CCGT_ts = E_CCGT_ts .* 3600 ./ eta_CCGT ./ LHV_gas;
Gas_cons_EBg_ts = E_EBg_ts .* 3600 ./ eta_EBg ./ LHV_gas;
Gas_cons_HPg_ts = E_HPg_ts .* 3600 ./ COP_HPg ./ LHV_gas;
% 阶段总气耗成本 ($)
cost_fuel = sum(Gas_cons_CCGT_ts + Gas_cons_EBg_ts + Gas_cons_HPg_ts) * price_gas * annual_factor * stage_factor;

% 3. 运维成本 (当前阶段 OPEX)
% 固定运维成本 ($/stage)
% 总装机容量 * 单位固定运维成本 * 阶段年数
cost_OM_fix = (variables.CCGT.n(stage) * P_max_CCGT * OM_fix_CCGT + ...
              variables.PV.instal(stage) * OM_fix_PV + ...
              variables.WT.instal(stage) * OM_fix_WT + ...
              variables.EBg.n(stage) * Q_max_EBg * OM_fix_EBg + ...
              variables.HPg.n(stage) * Q_max_HPg * OM_fix_HPg + ...
              variables.EBe.n(stage) * Q_max_EBe * OM_fix_EBe + ...
              variables.HPe.n(stage) * Q_max_HPe * OM_fix_HPe + ...
              variables.ESS.cap(stage) * OM_fix_ESS + ...
              variables.TES.cap(stage) * OM_fix_TES) * stage_factor;

% 可变运维成本 ($/stage)
% 总发电/供热量 * 单位变动运维成本 * 阶段年数
ESS_throughput = sum(variables.ESS.P_char(:, stage) .* t_resolution_h + ...
                    variables.ESS.P_disc(:, stage) .* t_resolution_h);
TES_throughput = sum(variables.TES.P_char(:, stage) .* t_resolution_h + ...
                    variables.TES.P_disc(:, stage) .* t_resolution_h);

cost_OM_var = (sum(E_CCGT_ts) * OM_var_CCGT + ...
              sum(E_EBg_ts) * OM_var_EBg + ...
              sum(E_HPg_ts) * OM_var_HPg + ...
              ESS_throughput * OM_var_ESS + ... % 基于吞吐量
              TES_throughput * OM_var_TES ... % 基于吞吐量
             ) * annual_factor * stage_factor;

Total_OPEX = cost_OM_fix + cost_OM_var;

% 4. 爬坡成本 (当前阶段)
% 总爬坡量 * 单位爬坡成本 * 阶段年数
cost_ramp = (sum(variables.CCGT.ramp_up(:, stage) + variables.CCGT.ramp_dn(:, stage)) * price_ramp_CCGT + ...
            sum(variables.EBg.ramp_up(:, stage) + variables.EBg.ramp_dn(:, stage)) * price_ramp_EBg + ...
            sum(variables.HPg.ramp_up(:, stage) + variables.HPg.ramp_dn(:, stage)) * price_ramp_HPg + ...
            sum(variables.EBe.ramp_up(:, stage) + variables.EBe.ramp_dn(:, stage)) * price_ramp_EBe + ...
            sum(variables.HPe.ramp_up(:, stage) + variables.HPe.ramp_dn(:, stage)) * price_ramp_HPe) * annual_factor * stage_factor; % price_ramp 是 $/ΔMW

% 5. 启停成本 (当前阶段)
% 总启停次数 * 单位启停成本 * 阶段年数
cost_onoff = (sum(variables.CCGT.on(:, stage) + variables.CCGT.off(:, stage)) * price_onoff_CCGT + ...
             sum(variables.EBg.on(:, stage) + variables.EBg.off(:, stage)) * price_onoff_EBg + ...
             sum(variables.HPg.on(:, stage) + variables.HPg.off(:, stage)) * price_onoff_HPg + ...
             sum(variables.EBe.on(:, stage) + variables.EBe.off(:, stage)) * price_onoff_EBe + ...
             sum(variables.HPe.on(:, stage) + variables.HPe.off(:, stage)) * price_onoff_HPe ...
            ) * annual_factor * stage_factor;

% 6. 电网交互成本 (当前阶段)
% 注意：确保向量和标量乘法的正确处理
% 创建grid_buy_energy向量，用于存储每个时间步的购电能量成本
grid_buy_energy = variables.grid.P_buy(:, stage) .* price_grid_buy .* t_resolution_h;
grid_sell_energy = variables.grid.P_sell(:, stage) .* price_grid_sell .* t_resolution_h;

cost_grid_buy = sum(grid_buy_energy) * annual_factor * stage_factor;
revenue_grid_sell = sum(grid_sell_energy) * annual_factor * stage_factor;
cost_net = cost_grid_buy - revenue_grid_sell;

% 7. 碳排放成本 (当前阶段)
% 计算总发电量 (MWh) - 使用元素级乘法
Total_CCGT_gen_annual = sum(E_CCGT_ts) * annual_factor * stage_factor;
% 计算允许的碳排放限额 (tCO2)
CO2_allowance = Total_CCGT_gen_annual * params.environment.CO2_CCGT;  % 碳排放限额系数

% 计算总碳排放 (tCO2)
CO2_from_gas = sum(Gas_cons_CCGT_ts + Gas_cons_EBg_ts + Gas_cons_HPg_ts) * annual_factor * stage_factor;
CO2_from_grid = sum(E_buy_ts) * params.environment.grid_CO2 * annual_factor * stage_factor;
Total_CO2_emission = CO2_from_gas + CO2_from_grid;

% 碳排放成本 (超过限额部分)
cost_CO2 = max(0, Total_CO2_emission - CO2_allowance) * CO2_cost;

% 8. 弃风弃光惩罚成本 (当前阶段)
% 计算可用功率 - 使用元素级乘法
P_PV_avail_ts = params.stage_renewable.PV_potential{stage} .* variables.PV.instal(stage);
P_WT_avail_ts = params.stage_renewable.WT_potential{stage} .* variables.WT.instal(stage);

% 计算弃电量 (确保非负)
PV_curtail_ts = max(0, P_PV_avail_ts - variables.PV.P(:, stage));
WT_curtail_ts = max(0, P_WT_avail_ts - variables.WT.P(:, stage));

% 计算弃电能量 - 使用元素级乘法
PV_curtail_energy = PV_curtail_ts .* t_resolution_h;
WT_curtail_energy = WT_curtail_ts .* t_resolution_h;

% 总弃电量 * 单位弃电成本 * 阶段年数
cost_curtail = (sum(PV_curtail_energy) * price_PV_cur + ...
               sum(WT_curtail_energy) * price_WT_cur ...
              ) * annual_factor * stage_factor;

% 9. 松弛变量惩罚成本 (当前阶段)
% 对电力和热力平衡松弛变量进行高额惩罚
slack_penalty_factor = 1e6; % 非常高的惩罚因子
cost_elec_slack = sum(variables.slack.elec_balance(:, stage)) * slack_penalty_factor;
cost_heat_slack = sum(variables.slack.heat_balance(:, stage)) * slack_penalty_factor;

% 计算当前阶段总成本（不含折现）
Objective = Total_CAPEX + cost_fuel + Total_OPEX + cost_ramp + cost_onoff + cost_net + cost_CO2 + cost_curtail + cost_elec_slack + cost_heat_slack;

% 存储当前阶段的详细成本信息（不含折现）
cost_details = struct();
cost_details.Total_CAPEX = Total_CAPEX;
cost_details.cost_fuel = cost_fuel;
cost_details.Total_OPEX = Total_OPEX;
cost_details.cost_ramp = cost_ramp;
cost_details.cost_onoff = cost_onoff;
cost_details.cost_net = cost_net;
cost_details.cost_CO2 = cost_CO2;
cost_details.cost_curtail = cost_curtail;
cost_details.cost_elec_slack = cost_elec_slack;
cost_details.cost_heat_slack = cost_heat_slack;
cost_details.Total_Cost = Objective;  % 添加总成本字段
cost_details.CO2_emission = Total_CO2_emission;
end