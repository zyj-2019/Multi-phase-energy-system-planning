function Constraints = build_constraints(variables, params, stage)
% 构建优化模型的约束条件
%
% 输入参数：
%   variables: 包含所有优化变量的结构体
%   params: 包含所有系统参数和预处理数据的结构体
%   stage: 当前处理的阶段
%
% 输出参数：
%   Constraints: YALMIP 约束对象
%
% 约束类型：
%   1. 运行约束：每个阶段的运行约束
%   2. 容量约束：设备容量和功率限制
%   3. 平衡约束：电力平衡和热力平衡
%   4. 跨阶段约束：容量演化约束
%   5. 启停约束：设备启停逻辑
%   6. 储能约束：储能设备运行约束
%   7. 可持续性约束：碳排放等环境约束

Constraints = [];

%% 提取常用变量和参数
t = params.num_time_steps;
M = 1e5; % 大M，用于松弛约束或表示big-M方法

% 多阶段相关参数
num_stages = params.multistage.num_stages;
time_steps_per_stage = params.multistage.time_steps_per_stage;

% 获取当前阶段的时间步数
if isfield(params.multistage, 'time_steps_per_stage') && length(params.multistage.time_steps_per_stage) >= stage
    current_stage_time_steps = params.multistage.time_steps_per_stage(stage);
else
    current_stage_time_steps = t; % 如果没有指定，使用全局时间步数
end

% 时间相关参数
t_resolution_h = params.time.resolution / 60; % 小时为单位的时间分辨率
% 获取当前阶段的时间分辨率（如果存在阶段性数据）
if isfield(params, 'stage_time') && isfield(params.stage_time, 'resolution')
    current_stage_resolution = params.stage_time.resolution{stage} / 60; % 小时为单位
else
    current_stage_resolution = t_resolution_h; % 使用全局分辨率作为后备
end
index_day = params.time.index_day; % 每日结束索引
length_day = params.time.length_day; % 每日时间步数
Day_weight = params.time.Day_weight; % 每日权重 (天数)
n_days = params.input.n; % 总天数

% 设备参数
P_max_CCGT = params.technical.CCGT.P_max;
P_min_CCGT = params.technical.CCGT.min_load * P_max_CCGT;
eta_CCGT = params.technical.CCGT.eta;
ramp_rate_CCGT = params.technical.CCGT.ramp_rate; % 占额定功率比例
max_on_CCGT = params.technical.CCGT.max_on;
max_off_CCGT = params.technical.CCGT.max_off;
n_CCGT_exist = params.technical.CCGT.n_exist;

Q_max_EBg = params.technical.EBg.Q_max;
Q_min_EBg = params.technical.EBg.min_load * Q_max_EBg;
eta_EBg = params.technical.EBg.eta;
ramp_rate_EBg = params.technical.EBg.ramp_rate;
n_EBg_exist = params.technical.EBg.n_exist;


Q_max_HPg = params.technical.HPg.Q_max;
Q_min_HPg = params.technical.HPg.min_load * Q_max_HPg;
COP_HPg = params.technical.HPg.COP;
ramp_rate_HPg = params.technical.HPg.ramp_rate;
n_HPg_exist = params.technical.HPg.n_exist;

% 电锅炉是由电P转热Q,电转热有效率约束，需要定义热功率的最小和最大功率
Q_max_EBe = params.technical.EBe.Q_max;
Q_min_EBe = params.technical.EBe.min_load * Q_max_EBe;
eta_EBe = params.technical.EBe.eta;
ramp_rate_EBe = params.technical.EBe.ramp_rate;
n_EBe_exist = params.technical.EBe.n_exist;

% 电热泵是由电P转热Q,电转热有效率约束，需要定义热功率的最小和最大功率
Q_max_HPe = params.technical.HPe.Q_max;
Q_min_HPe = params.technical.HPe.min_load * Q_max_HPe;
eta_HPe = params.technical.HPe.eta;
ramp_rate_HPe = params.technical.HPe.ramp_rate;
n_HPe_exist = params.technical.HPe.n_exist;


% 开关周期维度和映射
clm_onoff_CCGT = params.schedule.clm_onoff_CCGT;
steps_per_onoff_CCGT = params.schedule.steps_per_onoff_CCGT;
map_onoff_to_t_CCGT = create_onoff_map(steps_per_onoff_CCGT, current_stage_time_steps); 

clm_onoff_EBg = params.schedule.clm_onoff_EBg;
steps_per_onoff_EBg = params.schedule.steps_per_onoff_EBg;
map_onoff_to_t_EBg = create_onoff_map(steps_per_onoff_EBg, current_stage_time_steps);

clm_onoff_HPg = params.schedule.clm_onoff_HPg;
steps_per_onoff_HPg = params.schedule.steps_per_onoff_HPg;
map_onoff_to_t_HPg = create_onoff_map(steps_per_onoff_HPg, current_stage_time_steps);

clm_onoff_EBe = params.schedule.clm_onoff_EBe;
steps_per_onoff_EBe = params.schedule.steps_per_onoff_EBe;
map_onoff_to_t_EBe = create_onoff_map(steps_per_onoff_EBe, current_stage_time_steps);

clm_onoff_HPe = params.schedule.clm_onoff_HPe;
steps_per_onoff_HPe = params.schedule.steps_per_onoff_HPe;
map_onoff_to_t_HPe = create_onoff_map(steps_per_onoff_HPe, current_stage_time_steps);

% 负荷
DMD_E = params.load.P;
DMD_H = params.load.H;

% 可再生能源潜力
PV_potential = params.renewable.PV_potential;
WT_potential = params.renewable.WT_potential;

% 储能参数
eta_char_ESS = params.technical.ESS.eta_char;
eta_disc_ESS = params.technical.ESS.eta_disc;
loss_ESS = params.technical.ESS.loss;
cap_min_ESS = params.technical.ESS.cap_min_ratio;
cap_max_ESS = params.technical.ESS.cap_max_ratio;

eta_char_TES = params.technical.TES.eta_char;
eta_disc_TES = params.technical.TES.eta_disc;
loss_TES = params.technical.TES.loss;
cap_min_TES = params.technical.TES.cap_min_ratio; 
cap_max_TES = params.technical.TES.cap_max_ratio; 


%% --- 各阶段运行约束 ---
% 获取当前阶段的负荷和可再生能源数据
DMD_E_stage = params.stage_load.P{stage};
DMD_H_stage = params.stage_load.H{stage};
PV_potential_stage = params.stage_renewable.PV_potential{stage};
WT_potential_stage = params.stage_renewable.WT_potential{stage};

% --- 电转热设备输入输出关系 ---
% 使用更清晰的约束表达方式
Constraints = [Constraints, variables.EBe.Q(:, stage) == variables.EBe.P(:, stage) * params.technical.EBe.eta];
Constraints = [Constraints, variables.HPe.Q(:, stage) == variables.HPe.P(:, stage) * params.technical.HPe.eta];

% --- 平衡约束 ---
% 1. 电功率平衡
% 需求侧: 电负荷 + 储电充电 + 电制热设备用电
% 供给侧: CCGT出力 + 可再生能源出力 + 储电放电 + 电网购电 - 电网售电
% 添加松弛变量以处理可能的不可行情况

% 计算更鲁棒的松弛变量上限
min_slack_limit = 5; % 最小松弛变量上限 (MW)
mean_demand = mean(DMD_E_stage);
max_demand = max(DMD_E_stage);
slack_limit = max([0.05 * max_demand, 0.1 * mean_demand, min_slack_limit]);

% 电力平衡约束
Constraints = [Constraints, variables.slack.elec_balance(:, stage) >= 0];
Constraints = [Constraints, variables.slack.elec_balance(:, stage) <= slack_limit];

% 使用更清晰的约束表达方式
power_supply = variables.CCGT.P(:, stage) + variables.PV.P(:, stage) + variables.WT.P(:, stage) + ...
               variables.ESS.P_disc(:, stage) + variables.grid.P_buy(:, stage) - variables.grid.P_sell(:, stage);
power_demand = DMD_E_stage + variables.ESS.P_char(:, stage) + variables.HPe.P(:, stage) + variables.EBe.P(:, stage);
Constraints = [Constraints, power_supply >= power_demand - variables.slack.elec_balance(:, stage)];

% 2. 热功率平衡
% 需求侧: 热负荷 + 热储能充电
% 供给侧: 各类供热设备 + 热储能放电
% 添加松弛变量以处理可能的不可行情况

% 计算更鲁棒的热力松弛变量上限
min_heat_slack_limit = 5; % 最小热力松弛变量上限 (MW)
mean_heat_demand = mean(DMD_H_stage);
max_heat_demand = max(DMD_H_stage);
heat_slack_limit = max([0.05 * max_heat_demand, 0.1 * mean_heat_demand, min_heat_slack_limit]);

% 热力平衡约束
Constraints = [Constraints, variables.slack.heat_balance(:, stage) >= 0];
Constraints = [Constraints, variables.slack.heat_balance(:, stage) <= heat_slack_limit];

% 使用更清晰的约束表达方式
heat_supply = variables.EBg.Q(:, stage) + variables.HPg.Q(:, stage) + variables.EBe.Q(:, stage) + ...
              variables.HPe.Q(:, stage) + variables.TES.P_disc(:, stage);
heat_demand = DMD_H_stage + variables.TES.P_char(:, stage);
Constraints = [Constraints, heat_supply >= heat_demand - variables.slack.heat_balance(:, stage)];

% 3. 电网交互约束
Constraints = [Constraints, variables.grid.P_buy(:, stage) >= 0];
Constraints = [Constraints, variables.grid.P_sell(:, stage) >= 0];
Constraints = [Constraints, variables.grid.P_buy(:, stage) <= params.economic.grid_limit];
% Constraints = [Constraints, variables.grid.P_sell(:, stage) == 0]; % 不允许卖电

%% --- 设备约束 ---
% --- CCGT 约束 ---
Constraints = [Constraints, variables.CCGT.P(:, stage) >= 0];

% 使用二进制变量表示是否有装机容量
bin_CCGT = binvar(1, 1);
% 修改约束，适用于连续容量变量
% 使用最小负荷率作为最小容量的默认值（如果没有明确定义min_cap）
min_cap_CCGT = 0.1; % 默认最小容量为0.1MW
max_cap_CCGT = params.technical.CCGT.P_max; % 最大容量
Constraints = [Constraints, variables.CCGT.n(stage) >= min_cap_CCGT * bin_CCGT]; % 如果bin_CCGT=1，则n(stage)>=min_cap
Constraints = [Constraints, variables.CCGT.n(stage) <= max_cap_CCGT * bin_CCGT]; % 如果bin_CCGT=0，则n(stage)=0
Constraints = [Constraints, variables.CCGT.P(:, stage) <= M * bin_CCGT]; % 如果bin_CCGT=0，则P=0

% 运行范围 (将开关周期的运行台数 o 映射到时间步 t) 
for j = 1:clm_onoff_CCGT
    time_indices = map_onoff_to_t_CCGT{j}; % 获取第j个开关周期对应的时间步索引
    Constraints = [Constraints, ...
        variables.CCGT.o(j, stage) * P_min_CCGT <= variables.CCGT.P(time_indices, stage) <= variables.CCGT.o(j, stage) * P_max_CCGT];
end

% 启停逻辑
Constraints = [Constraints, variables.CCGT.o(:, stage) >= 0]; % 运行台数非负
Constraints = [Constraints, variables.CCGT.on(:, stage) >= 0]; % 开机台数非负
Constraints = [Constraints, variables.CCGT.off(:, stage) >= 0]; % 关机台数非负
Constraints = [Constraints, variables.CCGT.on(1, stage) == 0]; % 初始无开机
Constraints = [Constraints, variables.CCGT.off(1, stage) == 0]; % 初始无关机
Constraints = [Constraints, variables.CCGT.o(:, stage) <= variables.CCGT.n(stage)]; % 运行数 <= 装机数

% CCGT 状态更新约束 - 使用循环方式实现
% 确保使用正确的循环上限：开关周期数量
for idx = 2:clm_onoff_CCGT
    % 设置索引为实数标量
    idx_real = double(real(idx));
    idx_prev = double(real(idx-1));
    
    % 单独添加每个开关周期的约束
    Constraints = [Constraints, ...
        variables.CCGT.o(idx_real, stage) == variables.CCGT.o(idx_prev, stage) + variables.CCGT.on(idx_real, stage) - variables.CCGT.off(idx_real, stage)];
end

% CCGT爬坡约束 - 使用更符合YALMIP特性的方式实现
% 获取当前阶段s的CCGT功率输出时间序列，并确保它是列向量
% 注意：variables.CCGT.P的维度是(t,s)，所以取第s列获取当前阶段的功率
P_CCGT_stage = variables.CCGT.P(:, stage);

% 获取当前阶段的时间步数
T_period = size(P_CCGT_stage, 1);
T_period_real = double(real(T_period));

% 定义一个名为ramp_CCGT_actual_stage的sdpvar列向量，用于存储当前阶段s的实际功率变化
ramp_CCGT_actual_stage = sdpvar(T_period_real, 1);

% 计算实际功率变化
if T_period_real > 1
    % 第一个时间步的爬坡计算 - 假设相对于零功率启动
    ramp_CCGT_actual_stage(1) = P_CCGT_stage(1);
    
    % 后续时间步的爬坡计算
    for idx = 2:T_period_real
        ramp_CCGT_actual_stage(idx) = P_CCGT_stage(idx) - P_CCGT_stage(idx-1);
    end
end

% 获取当前阶段的向上爬坡和向下爬坡变量，确保它们是列向量
ramp_up_stage = variables.CCGT.ramp_up(:, stage);
ramp_dn_stage = variables.CCGT.ramp_dn(:, stage);

% 添加非负约束
Constraints = [Constraints, ramp_up_stage >= 0];
Constraints = [Constraints, ramp_dn_stage >= 0];

% 设置爬坡实际值与上升下降变量关系
Constraints = [Constraints, ramp_up_stage - ramp_dn_stage == ramp_CCGT_actual_stage];

% 计算爬坡上限
ramp_max_CCGT_val = P_max_CCGT * ramp_rate_CCGT; % 每分钟爬坡量
% 使用当前阶段的时间分辨率
ramp_max_CCGT_ts = ramp_max_CCGT_val * current_stage_resolution * 60; % 每个时间步允许的最大爬坡量

% 设置爬坡总量约束（爬坡上升+爬坡下降）<= 最大爬坡变化量
% 这种表示方式允许同时限制上升和下降爬坡的绝对值总和
Constraints = [Constraints, ramp_up_stage + ramp_dn_stage <= ramp_max_CCGT_ts];

% --- EBg 约束 ---
Constraints = [Constraints, variables.EBg.Q(:, stage) >= 0];

% 使用二进制变量表示是否有装机容量
bin_EBg = binvar(1, 1);
% 修改约束，适用于连续容量变量
% 使用最小负荷率作为最小容量的默认值（如果没有明确定义min_cap）
min_cap_EBg = 0.1; % 默认最小容量为0.1MW
max_cap_EBg = Q_max_EBg; % 最大容量
Constraints = [Constraints, variables.EBg.n(stage) >= min_cap_EBg * bin_EBg]; % 如果bin_EBg=1，则n(stage)>=min_cap
Constraints = [Constraints, variables.EBg.n(stage) <= max_cap_EBg * bin_EBg]; % 如果bin_EBg=0，则n(stage)=0
Constraints = [Constraints, variables.EBg.Q(:, stage) <= M * bin_EBg]; % 如果bin_EBg=0，则Q=0

% 输出功率约束
for j = 1:clm_onoff_EBg
    time_indices = map_onoff_to_t_EBg{j};
    Constraints = [Constraints, variables.EBg.Q(time_indices, stage) <= Q_max_EBg * variables.EBg.o(j, stage)]; % 输出上限与台数相关
    Constraints = [Constraints, variables.EBg.Q(time_indices, stage) >= Q_min_EBg * variables.EBg.o(j, stage)]; % 输出下限与台数相关
end

% 开关机约束
Constraints = [Constraints, variables.EBg.o(:, stage) >= 0];
Constraints = [Constraints, variables.EBg.on(:, stage) >= 0];
Constraints = [Constraints, variables.EBg.off(:, stage) >= 0];
Constraints = [Constraints, variables.EBg.o(1, stage) == variables.EBg.on(1, stage)]; % 第一时间步的开机状态

Constraints = [Constraints, variables.EBg.o(:, stage) <= variables.EBg.n(stage)];

% EBg 爬坡约束 - 使用更符合YALMIP特性的方式实现
% 获取当前阶段s的EBg热功率输出时间序列
P_EBg_stage = variables.EBg.Q(:, stage);

% 获取当前阶段的时间步数
T_period = size(P_EBg_stage, 1);
T_period_real = double(real(T_period));

% 定义一个sdpvar列向量，用于存储当前阶段s的实际功率变化
ramp_EBg_actual_stage = sdpvar(T_period_real, 1);

% 计算实际功率变化
if T_period_real > 1
    % 第一个时间步的爬坡计算 - 假设相对于零功率启动
    ramp_EBg_actual_stage(1) = P_EBg_stage(1);
    
    % 后续时间步的爬坡计算
    for idx = 2:T_period_real
        ramp_EBg_actual_stage(idx) = P_EBg_stage(idx) - P_EBg_stage(idx-1);
    end
end

% 获取当前阶段的向上爬坡和向下爬坡变量，确保它们是列向量
ramp_up_stage = variables.EBg.ramp_up(:, stage);
ramp_dn_stage = variables.EBg.ramp_dn(:, stage);

% 添加非负约束
Constraints = [Constraints, ramp_up_stage >= 0];
Constraints = [Constraints, ramp_dn_stage >= 0];

% 设置爬坡实际值与上升下降变量关系
Constraints = [Constraints, ramp_up_stage - ramp_dn_stage == ramp_EBg_actual_stage];

% 计算爬坡上限
ramp_max_EBg_val = Q_max_EBg * ramp_rate_EBg; % 每分钟爬坡量
% 使用当前阶段的时间分辨率
ramp_max_EBg_ts = ramp_max_EBg_val * current_stage_resolution * 60; % 每个时间步允许的最大爬坡量

% 设置爬坡总量约束
Constraints = [Constraints, ramp_up_stage + ramp_dn_stage <= ramp_max_EBg_ts];

% --- HPg 约束 ---
Constraints = [Constraints, variables.HPg.Q(:, stage) >= 0];

% 使用二进制变量表示是否有装机容量
bin_HPg = binvar(1, 1);
% 修改约束，适用于连续容量变量
% 使用最小负荷率作为最小容量的默认值（如果没有明确定义min_cap）
min_cap_HPg = 0.1; % 默认最小容量为0.1MW
max_cap_HPg = Q_max_HPg; % 最大容量
Constraints = [Constraints, variables.HPg.n(stage) >= min_cap_HPg * bin_HPg]; % 如果bin_HPg=1，则n(stage)>=min_cap
Constraints = [Constraints, variables.HPg.n(stage) <= max_cap_HPg * bin_HPg]; % 如果bin_HPg=0，则n(stage)=0
Constraints = [Constraints, variables.HPg.Q(:, stage) <= M * bin_HPg]; % 如果bin_HPg=0，则Q=0

% 输出功率约束
for j = 1:clm_onoff_HPg
    time_indices = map_onoff_to_t_HPg{j};
    Constraints = [Constraints, variables.HPg.Q(time_indices, stage) <= Q_max_HPg * variables.HPg.o(j, stage)]; % 输出上限与台数相关
    Constraints = [Constraints, variables.HPg.Q(time_indices, stage) >= Q_min_HPg * variables.HPg.o(j, stage)]; % 输出下限与台数相关
end

% 开关机约束
Constraints = [Constraints, variables.HPg.o(:, stage) >= 0];
Constraints = [Constraints, variables.HPg.on(:, stage) >= 0];
Constraints = [Constraints, variables.HPg.off(:, stage) >= 0];
Constraints = [Constraints, variables.HPg.o(1, stage) == variables.HPg.on(1, stage)]; % 第一时间步的开机状态

Constraints = [Constraints, variables.HPg.o(:, stage) <= variables.HPg.n(stage)];

% HPg 爬坡约束 - 使用更符合YALMIP特性的方式实现
% 获取当前阶段s的HPg热功率输出时间序列
P_HPg_stage = variables.HPg.Q(:, stage);

% 获取当前阶段的时间步数
T_period = size(P_HPg_stage, 1);
T_period_real = double(real(T_period));

% 定义一个sdpvar列向量，用于存储当前阶段s的实际功率变化
ramp_HPg_actual_stage = sdpvar(T_period_real, 1);

% 计算实际功率变化
if T_period_real > 1
    % 第一个时间步的爬坡计算 - 假设相对于零功率启动
    ramp_HPg_actual_stage(1) = P_HPg_stage(1);
    
    % 后续时间步的爬坡计算
    for idx = 2:T_period_real
        ramp_HPg_actual_stage(idx) = P_HPg_stage(idx) - P_HPg_stage(idx-1);
    end
end

% 获取当前阶段的向上爬坡和向下爬坡变量，确保它们是列向量
ramp_up_stage = variables.HPg.ramp_up(:, stage);
ramp_dn_stage = variables.HPg.ramp_dn(:, stage);

% 添加非负约束
Constraints = [Constraints, ramp_up_stage >= 0];
Constraints = [Constraints, ramp_dn_stage >= 0];

% 设置爬坡实际值与上升下降变量关系
Constraints = [Constraints, ramp_up_stage - ramp_dn_stage == ramp_HPg_actual_stage];

% 计算爬坡上限
ramp_max_HPg_val = Q_max_HPg * ramp_rate_HPg; % 每分钟爬坡量
% 使用当前阶段的时间分辨率
ramp_max_HPg_ts = ramp_max_HPg_val * current_stage_resolution * 60; % 每个时间步允许的最大爬坡量

% 设置爬坡总量约束
Constraints = [Constraints, ramp_up_stage + ramp_dn_stage <= ramp_max_HPg_ts];

% --- EBe 约束 ---
Constraints = [Constraints, variables.EBe.P(:, stage) >= 0];

% 使用二进制变量表示是否有装机容量
bin_EBe = binvar(1, 1);
% 修改约束，适用于连续容量变量
% 使用最小负荷率作为最小容量的默认值（如果没有明确定义min_cap）
min_cap_EBe = 0.1; % 默认最小容量为0.1MW
max_cap_EBe = Q_max_EBe; % 最大容量
Constraints = [Constraints, variables.EBe.n(stage) >= min_cap_EBe * bin_EBe]; % 如果bin_EBe=1，则n(stage)>=min_cap
Constraints = [Constraints, variables.EBe.n(stage) <= max_cap_EBe * bin_EBe]; % 如果bin_EBe=0，则n(stage)=0
Constraints = [Constraints, variables.EBe.P(:, stage) <= M * bin_EBe]; % 如果bin_EBe=0，则P=0
Constraints = [Constraints, variables.EBe.Q(:, stage) <= M * bin_EBe]; % 如果bin_EBe=0，则Q=0

% 输出功率约束
for j = 1:clm_onoff_EBe
    time_indices = map_onoff_to_t_EBe{j};
    Constraints = [Constraints, variables.EBe.P(time_indices, stage) <= Q_max_EBe / eta_EBe * variables.EBe.o(j, stage)]; % 输出上限与台数相关
    Constraints = [Constraints, variables.EBe.P(time_indices, stage) >= Q_min_EBe / eta_EBe * variables.EBe.o(j, stage)]; % 输出下限与台数相关
end

% 开关机约束
Constraints = [Constraints, variables.EBe.o(:, stage) >= 0];
Constraints = [Constraints, variables.EBe.on(:, stage) >= 0];
Constraints = [Constraints, variables.EBe.off(:, stage) >= 0];
Constraints = [Constraints, variables.EBe.o(1, stage) == variables.EBe.on(1, stage)]; % 第一时间步的开机状态

Constraints = [Constraints, variables.EBe.o(:, stage) <= variables.EBe.n(stage)];

% EBe 爬坡约束 - 使用更符合YALMIP特性的方式实现
% 获取当前阶段s的EBe电功率输入时间序列（注意这里使用P而不是Q）
P_EBe_stage = variables.EBe.P(:, stage);

% 获取当前阶段的时间步数
T_period = size(P_EBe_stage, 1);
T_period_real = double(real(T_period));

% 定义一个sdpvar列向量，用于存储当前阶段s的实际功率变化
ramp_EBe_actual_stage = sdpvar(T_period_real, 1);

% 计算实际功率变化
if T_period_real > 1
    % 第一个时间步的爬坡计算 - 假设相对于零功率启动
    ramp_EBe_actual_stage(1) = P_EBe_stage(1);
    
    % 后续时间步的爬坡计算
    for idx = 2:T_period_real
        ramp_EBe_actual_stage(idx) = P_EBe_stage(idx) - P_EBe_stage(idx-1);
    end
end

% 获取当前阶段的向上爬坡和向下爬坡变量，确保它们是列向量
ramp_up_stage = variables.EBe.ramp_up(:, stage);
ramp_dn_stage = variables.EBe.ramp_dn(:, stage);

% 添加非负约束
Constraints = [Constraints, ramp_up_stage >= 0];
Constraints = [Constraints, ramp_dn_stage >= 0];

% 设置爬坡实际值与上升下降变量关系
Constraints = [Constraints, ramp_up_stage - ramp_dn_stage == ramp_EBe_actual_stage];

% 计算爬坡上限（注意是基于输入电功率计算）
ramp_max_EBe_val = Q_max_EBe * ramp_rate_EBe / eta_EBe; % 每分钟爬坡量
% 使用当前阶段的时间分辨率
ramp_max_EBe_ts = ramp_max_EBe_val * current_stage_resolution * 60; % 每个时间步允许的最大爬坡量

% 设置爬坡总量约束
Constraints = [Constraints, ramp_up_stage + ramp_dn_stage <= ramp_max_EBe_ts];

% --- HPe 约束 ---
Constraints = [Constraints, variables.HPe.P(:, stage) >= 0];  

% 使用二进制变量表示是否有装机容量
bin_HPe = binvar(1, 1);
% 修改约束，适用于连续容量变量
% 使用最小负荷率作为最小容量的默认值（如果没有明确定义min_cap）
min_cap_HPe = 0.1; % 默认最小容量为0.1MW
max_cap_HPe = Q_max_HPe; % 最大容量
Constraints = [Constraints, variables.HPe.n(stage) >= min_cap_HPe * bin_HPe]; % 如果bin_HPe=1，则n(stage)>=min_cap
Constraints = [Constraints, variables.HPe.n(stage) <= max_cap_HPe * bin_HPe]; % 如果bin_HPe=0，则n(stage)=0
Constraints = [Constraints, variables.HPe.P(:, stage) <= M * bin_HPe]; % 如果bin_HPe=0，则P=0
Constraints = [Constraints, variables.HPe.Q(:, stage) <= M * bin_HPe]; % 如果bin_HPe=0，则Q=0

% 决策变量约束
for j = 1:clm_onoff_HPe
    time_indices = map_onoff_to_t_HPe{j};
    Constraints = [Constraints, variables.HPe.P(time_indices, stage) <= Q_max_HPe / eta_HPe * variables.HPe.o(j, stage)]; % 输出上限与台数相关
    Constraints = [Constraints, variables.HPe.P(time_indices, stage) >= Q_min_HPe / eta_HPe * variables.HPe.o(j, stage)]; % 输出下限与台数相关
end

% 启停逻辑
Constraints = [Constraints, variables.HPe.o(:, stage) >= 0];
Constraints = [Constraints, variables.HPe.on(:, stage) >= 0];
Constraints = [Constraints, variables.HPe.off(:, stage) >= 0];
Constraints = [Constraints, variables.HPe.o(1, stage) == variables.HPe.on(1, stage)]; % 第一时间步的开机状态
Constraints = [Constraints, variables.HPe.o(:, stage) <= variables.HPe.n(stage)];

% HPe 状态更新约束
% 使用正确的循环上限：开关周期数量
for idx = 2:clm_onoff_HPe
    % 设置索引为实数标量
    idx_real = double(real(idx));
    idx_prev = double(real(idx-1));
    
    % 单独添加每个开关周期的约束
    Constraints = [Constraints, ...
        variables.HPe.o(idx_real, stage) == variables.HPe.o(idx_prev, stage) + variables.HPe.on(idx_real, stage) - variables.HPe.off(idx_real, stage)];
end

% HPe 爬坡约束 - 使用更符合YALMIP特性的方式实现
% 获取当前阶段s的HPe电功率输入时间序列（注意这里使用P而不是Q）
P_HPe_stage = variables.HPe.P(:, stage);

% 获取当前阶段的时间步数
T_period = size(P_HPe_stage, 1);
T_period_real = double(real(T_period));

% 定义一个sdpvar列向量，用于存储当前阶段s的实际功率变化
ramp_HPe_actual_stage = sdpvar(T_period_real, 1);

% 计算实际功率变化
if T_period_real > 1
    % 第一个时间步的爬坡计算 - 假设相对于零功率启动
    ramp_HPe_actual_stage(1) = P_HPe_stage(1);
    
    % 后续时间步的爬坡计算
    for idx = 2:T_period_real
        ramp_HPe_actual_stage(idx) = P_HPe_stage(idx) - P_HPe_stage(idx-1);
    end
end

% 获取当前阶段的向上爬坡和向下爬坡变量，确保它们是列向量
ramp_up_stage = variables.HPe.ramp_up(:, stage);
ramp_dn_stage = variables.HPe.ramp_dn(:, stage);

% 添加非负约束
Constraints = [Constraints, ramp_up_stage >= 0];
Constraints = [Constraints, ramp_dn_stage >= 0];

% 设置爬坡实际值与上升下降变量关系
Constraints = [Constraints, ramp_up_stage - ramp_dn_stage == ramp_HPe_actual_stage];

% 计算爬坡上限（注意是基于输入电功率计算）
ramp_max_HPe_val = Q_max_HPe * ramp_rate_HPe / eta_HPe; % 每分钟爬坡量
% 使用当前阶段的时间分辨率
ramp_max_HPe_ts = ramp_max_HPe_val * current_stage_resolution * 60; % 每个时间步允许的最大爬坡量

% 设置爬坡总量约束
Constraints = [Constraints, ramp_up_stage + ramp_dn_stage <= ramp_max_HPe_ts];

% --- 可再生能源约束 ---
% PV
P_PV_avail = variables.PV.instal(stage) * PV_potential_stage;
Constraints = [Constraints, variables.PV.P(:, stage) >= 0];
Constraints = [Constraints, variables.PV.P(:, stage) <= P_PV_avail]; % 出力不超过可用潜力

% PV 爬坡约束 - 使用更符合YALMIP特性的方式实现
% 获取当前阶段s的PV电功率输出时间序列
P_PV_stage = variables.PV.P(:, stage);

% 获取当前阶段的时间步数
T_period = size(P_PV_stage, 1);
T_period_real = double(real(T_period));

% 定义一个sdpvar列向量，用于存储当前阶段s的实际功率变化
ramp_PV_actual_stage = sdpvar(T_period_real, 1);

% 计算实际功率变化
if T_period_real > 1
    % 第一个时间步的爬坡计算 - 假设相对于零功率启动
    ramp_PV_actual_stage(1) = P_PV_stage(1);
    
    % 后续时间步的爬坡计算
    for idx = 2:T_period_real
        ramp_PV_actual_stage(idx) = P_PV_stage(idx) - P_PV_stage(idx-1);
    end
end

% 获取当前阶段的向上爬坡和向下爬坡变量，确保它们是列向量
ramp_up_stage = variables.PV.ramp_up(:, stage);
ramp_dn_stage = variables.PV.ramp_dn(:, stage);

% 添加非负约束
Constraints = [Constraints, ramp_up_stage >= 0];
Constraints = [Constraints, ramp_dn_stage >= 0];

% 设置爬坡实际值与上升下降变量关系
Constraints = [Constraints, ramp_up_stage - ramp_dn_stage == ramp_PV_actual_stage];

% 计算爬坡上限
ramp_max_PV_val = variables.PV.instal(stage) * params.technical.PV.ramp_rate; % 每分钟爬坡量
% 使用当前阶段的时间分辨率
ramp_max_PV_ts = ramp_max_PV_val * current_stage_resolution * 60; % 每个时间步允许的最大爬坡量

% 设置爬坡总量约束
Constraints = [Constraints, ramp_up_stage + ramp_dn_stage <= ramp_max_PV_ts];

% WT
P_WT_avail = variables.WT.instal(stage) * WT_potential_stage;
Constraints = [Constraints, variables.WT.P(:, stage) >= 0];
Constraints = [Constraints, variables.WT.P(:, stage) <= P_WT_avail]; % 出力不超过可用潜力

% WT 爬坡约束 - 使用更符合YALMIP特性的方式实现
% 获取当前阶段s的WT电功率输出时间序列
P_WT_stage = variables.WT.P(:, stage);

% 获取当前阶段的时间步数
T_period = size(P_WT_stage, 1);
T_period_real = double(real(T_period));

% 定义一个sdpvar列向量，用于存储当前阶段s的实际功率变化
ramp_WT_actual_stage = sdpvar(T_period_real, 1);

% 计算实际功率变化
if T_period_real > 1
    % 第一个时间步的爬坡计算 - 假设相对于零功率启动
    ramp_WT_actual_stage(1) = P_WT_stage(1);
    
    % 后续时间步的爬坡计算
    for idx = 2:T_period_real
        ramp_WT_actual_stage(idx) = P_WT_stage(idx) - P_WT_stage(idx-1);
    end
end

% 获取当前阶段的向上爬坡和向下爬坡变量，确保它们是列向量
ramp_up_stage = variables.WT.ramp_up(:, stage);
ramp_dn_stage = variables.WT.ramp_dn(:, stage);

% 添加非负约束
Constraints = [Constraints, ramp_up_stage >= 0];
Constraints = [Constraints, ramp_dn_stage >= 0];

% 设置爬坡实际值与上升下降变量关系
Constraints = [Constraints, ramp_up_stage - ramp_dn_stage == ramp_WT_actual_stage];

% 计算爬坡上限
ramp_max_WT_val = variables.WT.instal(stage) * params.technical.WT.ramp_rate; % 每分钟爬坡量
% 使用当前阶段的时间分辨率
ramp_max_WT_ts = ramp_max_WT_val * current_stage_resolution * 60; % 每个时间步允许的最大爬坡量

% 设置爬坡总量约束
Constraints = [Constraints, ramp_up_stage + ramp_dn_stage <= ramp_max_WT_ts];

% --- 储能约束 ---
% ESS (储电)
Constraints = [Constraints, variables.ESS.P_char(:, stage) >= 0];
Constraints = [Constraints, variables.ESS.P_disc(:, stage) >= 0];

% 充放电功率上限 (根据当前阶段的容量)
P_char_max_ESS = variables.ESS.cap(stage) / params.technical.ESS.str_max;
P_disc_max_ESS = variables.ESS.cap(stage) / params.technical.ESS.str_max;
Constraints = [Constraints, variables.ESS.P_char(:, stage) <= P_char_max_ESS];
Constraints = [Constraints, variables.ESS.P_disc(:, stage) <= P_disc_max_ESS];

% SOC 状态转移，用循环方式实现，避免NaN值问题
% 使用当前阶段的时间步数
current_stage_time_steps_real = double(real(current_stage_time_steps));
if current_stage_time_steps_real >= 1
    for idx = 1:current_stage_time_steps_real
        next_idx = idx + 1;
        % 添加状态转移方程，使用当前阶段的时间分辨率
        Constraints = [Constraints, ...
            variables.ESS.SOC(next_idx, stage) == variables.ESS.SOC(idx, stage) * (1 - params.technical.ESS.loss * current_stage_resolution) ... % 考虑自损耗
            + (variables.ESS.P_char(idx, stage) * params.technical.ESS.eta_char - variables.ESS.P_disc(idx, stage) / params.technical.ESS.eta_disc) * current_stage_resolution]; % 能量变化
    end
end

% SOC 上下限 SOC
Constraints = [Constraints, ...
    variables.ESS.SOC(:, stage) >= params.technical.ESS.cap_min_ratio * variables.ESS.cap(stage)]; % SOC 下限
Constraints = [Constraints, ...
    variables.ESS.SOC(:, stage) <= params.technical.ESS.cap_max_ratio * variables.ESS.cap(stage)]; % SOC 上限

% SOC 周期性约束 (松弛：允许整个周期始末SOC有一定差异)
% 使用松弛变量允许5%的差异
soc_slack_ratio = 0.05; % 允许5%的差异
soc_max_diff = soc_slack_ratio * variables.ESS.cap(stage);

% 使用当前阶段的时间步数确保索引正确
% 检查SOC变量的实际大小
[soc_rows, ~] = size(variables.ESS.SOC);

% 确保索引不会超出范围
last_soc_idx = min(current_stage_time_steps + 1, soc_rows);

% 添加周期性约束，使用正确的索引
Constraints = [Constraints, abs(variables.ESS.SOC(1, stage) - variables.ESS.SOC(last_soc_idx, stage)) <= soc_max_diff];

% TES (热储能)
Constraints = [Constraints, variables.TES.P_char(:, stage) >= 0];
Constraints = [Constraints, variables.TES.P_disc(:, stage) >= 0];

% 充放电功率上限 (根据当前阶段的容量)
P_char_max_TES = variables.TES.cap(stage) / params.technical.TES.str_max;
P_disc_max_TES = variables.TES.cap(stage) / params.technical.TES.str_max;
Constraints = [Constraints, variables.TES.P_char(:, stage) <= P_char_max_TES];
Constraints = [Constraints, variables.TES.P_disc(:, stage) <= P_disc_max_TES];

% SOT 状态转移，用循环方式实现，避免NaN值问题
% 使用当前阶段的时间步数
current_stage_time_steps_real = double(real(current_stage_time_steps));
if current_stage_time_steps_real >= 1
    for idx = 1:current_stage_time_steps_real
        next_idx = idx + 1;
        % 添加状态转移方程，使用当前阶段的时间分辨率
        Constraints = [Constraints, ...
            variables.TES.SOT(next_idx, stage) == variables.TES.SOT(idx, stage) * (1 - params.technical.TES.loss * current_stage_resolution) ... 
            + (variables.TES.P_char(idx, stage) * params.technical.TES.eta_char - variables.TES.P_disc(idx, stage) / params.technical.TES.eta_disc) * current_stage_resolution];
    end
end

% SOT 上下限
Constraints = [Constraints, ...
    variables.TES.SOT(:, stage) >= params.technical.TES.cap_min_ratio * variables.TES.cap(stage)];
Constraints = [Constraints, ...
    variables.TES.SOT(:, stage) <= params.technical.TES.cap_max_ratio * variables.TES.cap(stage)];

% SOT 周期性约束 (松弛：允许整个周期始末SOT有一定差异)
% 使用松弛变量允许5%的差异
sot_slack_ratio = 0.05; % 允许5%的差异
sot_max_diff = sot_slack_ratio * variables.TES.cap(stage);

% 使用当前阶段的时间步数确保索引正确
% 检查SOT变量的实际大小
[sot_rows, ~] = size(variables.TES.SOT);

% 确保索引不会超出范围
last_sot_idx = min(current_stage_time_steps + 1, sot_rows);

% 添加周期性约束，使用正确的索引
Constraints = [Constraints, abs(variables.TES.SOT(1, stage) - variables.TES.SOT(last_sot_idx, stage)) <= sot_max_diff];

%% --- 各类设备启停约束 ---
% 1. CCGT启停约束
% 每天最大启动次数约束
for day = 1:params.input.n
    % 确保day是实数标量
    day_real = double(real(day));
    day_start = (day_real-1)*24 + 1;  % 每天的开始时间步
    day_end = day_real*24;            % 每天的结束时间步
    
    % 确保索引是实数标量
    day_start = double(real(day_start));
    day_end = double(real(day_end));
    
    % 确保索引在有效范围内
    if day_end <= length(variables.CCGT.on(:, stage))
        Constraints = [Constraints;
            sum(variables.CCGT.on(day_start:day_end, stage)) <= params.schedule.CCGT.max_starts_per_day];
    else
        % 如果超出范围，只计算到最后一个时间步
        last_step = length(variables.CCGT.on(:, stage));
        last_step_real = double(real(last_step));
        Constraints = [Constraints;
            sum(variables.CCGT.on(day_start:last_step_real, stage)) <= params.schedule.CCGT.max_starts_per_day];
    end
end

% 最小持续运行时间约束
% 计算最小开启/关闭的【开关周期数】
% 假设params.schedule.t_onoff_CCGT是每个开关周期的固定分钟数
min_on_switching_periods_CCGT = ceil(params.schedule.CCGT.min_on_time / params.schedule.t_onoff_CCGT);
min_off_switching_periods_CCGT = ceil(params.schedule.CCGT.min_off_time / params.schedule.t_onoff_CCGT);

% 当前阶段典型周期的总开关周期数
clm_sw_CCGT = params.schedule.clm_onoff_CCGT;

% 最小持续运行时间约束
for sw_idx = 1:(clm_sw_CCGT - min_on_switching_periods_CCGT + 1)
    start_idx = double(real(sw_idx));
    end_idx = double(real(sw_idx + min_on_switching_periods_CCGT - 1));
    Constraints = [Constraints, sum(variables.CCGT.on(start_idx:end_idx, stage)) <= 1];
end

% 最小停机时间约束
for sw_idx = 1:(clm_sw_CCGT - min_off_switching_periods_CCGT + 1)
    % 确保索引是实数标量
    start_idx = double(real(sw_idx));
    end_idx = double(real(sw_idx + min_off_switching_periods_CCGT - 1));
    Constraints = [Constraints, ...
        sum(variables.CCGT.off(start_idx:end_idx, stage)) <= 1];
end

% 简化起见，这里只展示了CCGT的启停约束
% 其他设备（如EBg、HPg等）的启停约束可以类似添加

% 开关机约束
Constraints = [Constraints, variables.EBg.o(:, stage) >= 0];
Constraints = [Constraints, variables.EBg.on(:, stage) >= 0];
Constraints = [Constraints, variables.EBg.off(:, stage) >= 0];
Constraints = [Constraints, variables.EBg.o(1, stage) == variables.EBg.on(1, stage)]; % 第一时间步的开机状态

Constraints = [Constraints, variables.EBg.o(:, stage) <= variables.EBg.n(stage)];

% EBg 状态更新约束
% 使用正确的循环上限：开关周期数量
for idx = 2:clm_onoff_EBg
    % 设置索引为实数标量
    idx_real = double(real(idx));
    idx_prev = double(real(idx-1));
    
    % 单独添加每个开关周期的约束
    Constraints = [Constraints, ...
        variables.EBg.o(idx_real, stage) == variables.EBg.o(idx_prev, stage) + variables.EBg.on(idx_real, stage) - variables.EBg.off(idx_real, stage)];
end

% 开关机约束
Constraints = [Constraints, variables.HPg.o(:, stage) >= 0];
Constraints = [Constraints, variables.HPg.on(:, stage) >= 0];
Constraints = [Constraints, variables.HPg.off(:, stage) >= 0];
Constraints = [Constraints, variables.HPg.o(1, stage) == variables.HPg.on(1, stage)]; % 第一时间步的开机状态

Constraints = [Constraints, variables.HPg.o(:, stage) <= variables.HPg.n(stage)];

% HPg 状态更新约束
% 使用正确的循环上限：开关周期数量
for idx = 2:clm_onoff_HPg
    % 设置索引为实数标量
    idx_real = double(real(idx));
    idx_prev = double(real(idx-1));
    
    % 单独添加每个开关周期的约束
    Constraints = [Constraints, ...
        variables.HPg.o(idx_real, stage) == variables.HPg.o(idx_prev, stage) + variables.HPg.on(idx_real, stage) - variables.HPg.off(idx_real, stage)];
end

% 开关机约束
Constraints = [Constraints, variables.EBe.o(:, stage) >= 0];
Constraints = [Constraints, variables.EBe.on(:, stage) >= 0];
Constraints = [Constraints, variables.EBe.off(:, stage) >= 0];
Constraints = [Constraints, variables.EBe.o(1, stage) == variables.EBe.on(1, stage)]; % 第一时间步的开机状态

Constraints = [Constraints, variables.EBe.o(:, stage) <= variables.EBe.n(stage)];

% EBe 状态更新约束
% 使用正确的循环上限：开关周期数量
for idx = 2:clm_onoff_EBe
    % 设置索引为实数标量
    idx_real = double(real(idx));
    idx_prev = double(real(idx-1));
    
    % 单独添加每个开关周期的约束
    Constraints = [Constraints, ...
        variables.EBe.o(idx_real, stage) == variables.EBe.o(idx_prev, stage) + variables.EBe.on(idx_real, stage) - variables.EBe.off(idx_real, stage)];
end

% 启停逻辑
Constraints = [Constraints, variables.HPe.o(:, stage) >= 0];
Constraints = [Constraints, variables.HPe.on(:, stage) >= 0];
Constraints = [Constraints, variables.HPe.off(:, stage) >= 0];
Constraints = [Constraints, variables.HPe.o(1, stage) == variables.HPe.on(1, stage)]; % 第一时间步的开机状态
Constraints = [Constraints, variables.HPe.o(:, stage) <= variables.HPe.n(stage)];

% HPe 状态更新约束
% 使用正确的循环上限：开关周期数量
for idx = 2:clm_onoff_HPe
    % 设置索引为实数标量
    idx_real = double(real(idx));
    idx_prev = double(real(idx-1));
    
    % 单独添加每个开关周期的约束
    Constraints = [Constraints, ...
        variables.HPe.o(idx_real, stage) == variables.HPe.o(idx_prev, stage) + variables.HPe.on(idx_real, stage) - variables.HPe.off(idx_real, stage)];
end

%% --- 可持续性约束 ---
% % 1. 碳排放约束
% % 计算各种来源的能量 (MWh)
% E_CCGT_ts = variables.CCGT.P(:, stage) .* current_stage_resolution;
% E_EBg_ts = variables.EBg.Q(:, stage) .* current_stage_resolution;
% E_HPg_ts = variables.HPg.Q(:, stage) .* current_stage_resolution;
% E_buy_ts = variables.grid.P_buy(:, stage) .* current_stage_resolution;
% 
% % 计算总天然气消耗 (m^3)
% LHV_gas = params.environment.LHV_gas; % MJ/m^3
% Gas_cons_CCGT_ts = E_CCGT_ts .* 3600 ./ params.technical.CCGT.eta ./ LHV_gas;
% Gas_cons_EBg_ts = E_EBg_ts .* 3600 ./ params.technical.EBg.eta ./ LHV_gas;
% Gas_cons_HPg_ts = E_HPg_ts .* 3600 ./ params.technical.HPg.COP ./ LHV_gas;
% 
% % 年化总气耗 (m^3)
% Total_gas_cons = sum(Gas_cons_CCGT_ts + Gas_cons_EBg_ts + Gas_cons_HPg_ts) * sum(params.time.Day_weight);
% 
% % 计算年总碳排放 (tCO2)
% CO2_from_gas = Total_gas_cons * params.environment.gas_CO2;
% CO2_from_grid = sum(E_buy_ts) * params.environment.grid_CO2 * sum(params.time.Day_weight);
% Total_CO2_emission = CO2_from_gas + CO2_from_grid;
% 
% % 添加碳排放上限约束
% if isfield(params.environment, 'CO2_limit')
%     Constraints = [Constraints, Total_CO2_emission <= params.environment.CO2_limit];
% end

end

function map = create_onoff_map(steps_per_period, total_steps)
    % 创建从开关周期索引到时间步索引的映射
    map = cell(length(steps_per_period), 1);
    current_step = 1;
    for i = 1:length(steps_per_period)
        num_steps = steps_per_period(i);
        % 确保 num_steps 是有效的正整数
        if ~isnumeric(num_steps) || ~isscalar(num_steps) || num_steps <= 0 || round(num_steps) ~= num_steps
             error('steps_per_period 中的值必须是正整数');
        end
        end_step = current_step + num_steps - 1;
        if end_step > total_steps
            end_step = total_steps; % 防止超出总步数
            num_steps = end_step - current_step + 1; % 调整最后一个周期的步数
            if num_steps <= 0 % 如果 current_step 已经超出，则停止
                 map = map(1:i-1); % 只保留有效的部分
                 break;
            end
        end
        % 确保索引是实数标量
        current_step_real = double(real(current_step));
        end_step_real = double(real(end_step));
        % 创建索引向量
        map{i} = current_step_real:end_step_real;
        current_step = end_step + 1;
        if current_step > total_steps
            break; % 所有步数已分配完毕
        end
    end
end