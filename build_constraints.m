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
%   1. 平衡约束：电力平衡和热力平衡
%   2. 容量约束：设备容量和功率限制
%   3. 运行约束：设备运行限制
%   4. 储能约束：储能设备运行约束

Constraints = [];

%% 提取常用参数
% 获取当前阶段的时间步数
if isfield(params.multistage, 'time_steps_per_stage') && length(params.multistage.time_steps_per_stage) >= stage
    current_stage_time_steps = params.multistage.time_steps_per_stage(stage);
else
    current_stage_time_steps = params.num_time_steps;
end

% 获取当前阶段的时间分辨率（小时）
if isfield(params, 'stage_time') && isfield(params.stage_time, 'resolution')
    current_stage_resolution = params.stage_time.resolution{stage} / 60; 
else
    current_stage_resolution = params.time.resolution / 60;
end

% 设备参数
% CCGT 参数
P_max_CCGT = params.technical.CCGT.P_max;
P_min_CCGT = params.technical.CCGT.min_load * P_max_CCGT;

% EBg (燃气电锅炉) 参数
Q_max_EBg = params.technical.EBg.Q_max;
Q_min_EBg = params.technical.EBg.min_load * Q_max_EBg;

% HPg (燃气热泵) 参数
Q_max_HPg = params.technical.HPg.Q_max;
Q_min_HPg = params.technical.HPg.min_load * Q_max_HPg;

% EBe (电锅炉) 参数
Q_max_EBe = params.technical.EBe.Q_max;
Q_min_EBe = params.technical.EBe.min_load * Q_max_EBe;
eta_EBe = params.technical.EBe.eta;

% HPe (电热泵) 参数
Q_max_HPe = params.technical.HPe.Q_max;
Q_min_HPe = params.technical.HPe.min_load * Q_max_HPe;
eta_HPe = params.technical.HPe.eta;

% 获取现有设备数量
instal_exist_CCGT = params.technical.CCGT.n_exist;
instal_exist_EBg = params.technical.EBg.n_exist;
instal_exist_HPg = params.technical.HPg.n_exist;
instal_exist_EBe = params.technical.EBe.n_exist;
instal_exist_HPe = params.technical.HPe.n_exist;

% 时间步与开关周期映射
% CCGT 映射
clm_onoff_CCGT = params.schedule.clm_onoff_CCGT;
steps_per_onoff_CCGT = params.schedule.steps_per_onoff_CCGT;
map_onoff_to_t_CCGT = create_onoff_map(steps_per_onoff_CCGT, current_stage_time_steps);

% EBg 映射
clm_onoff_EBg = params.schedule.clm_onoff_EBg;
steps_per_onoff_EBg = params.schedule.steps_per_onoff_EBg;
map_onoff_to_t_EBg = create_onoff_map(steps_per_onoff_EBg, current_stage_time_steps);

% HPg 映射
clm_onoff_HPg = params.schedule.clm_onoff_HPg;
steps_per_onoff_HPg = params.schedule.steps_per_onoff_HPg;
map_onoff_to_t_HPg = create_onoff_map(steps_per_onoff_HPg, current_stage_time_steps);

% EBe 映射
clm_onoff_EBe = params.schedule.clm_onoff_EBe;
steps_per_onoff_EBe = params.schedule.steps_per_onoff_EBe;
map_onoff_to_t_EBe = create_onoff_map(steps_per_onoff_EBe, current_stage_time_steps);

% HPe 映射
clm_onoff_HPe = params.schedule.clm_onoff_HPe;
steps_per_onoff_HPe = params.schedule.steps_per_onoff_HPe;
map_onoff_to_t_HPe = create_onoff_map(steps_per_onoff_HPe, current_stage_time_steps);

% 获取当前阶段的负荷和可再生能源数据
DMD_E_stage = params.stage_load.P{stage};
DMD_H_stage = params.stage_load.H{stage};
PV_potential_stage = params.stage_renewable.PV_potential{stage};
WT_potential_stage = params.stage_renewable.WT_potential{stage};

%% 1. 设备输入输出关系
% 电锅炉：电功率->热功率转换
Constraints = [Constraints, variables.EBe.Q(:, stage) == variables.EBe.P(:, stage) * eta_EBe];
% 电热泵：电功率->热功率转换
Constraints = [Constraints, variables.HPe.Q(:, stage) == variables.HPe.P(:, stage) * eta_HPe];

%% 2. 平衡约束
% 2.1 电功率平衡
power_supply = variables.CCGT.P(:, stage) + variables.PV.P(:, stage) + variables.WT.P(:, stage) + ...
               variables.ESS.P_disc(:, stage) + variables.grid.P_buy(:, stage) - variables.grid.P_sell(:, stage);
power_demand = DMD_E_stage + variables.ESS.P_char(:, stage) + variables.HPe.P(:, stage) + variables.EBe.P(:, stage);
% 电力平衡约束：供给 = 需求
Constraints = [Constraints, power_supply >= power_demand];

% 2.2 热功率平衡
heat_supply = variables.EBg.Q(:, stage) + variables.HPg.Q(:, stage) + variables.EBe.Q(:, stage) + ...
              variables.HPe.Q(:, stage) + variables.TES.P_disc(:, stage);
heat_demand = DMD_H_stage + variables.TES.P_char(:, stage);
% 热力平衡约束：供给 = 需求
Constraints = [Constraints, heat_supply >= heat_demand];

%% 3. 电网交互约束
% 电网购电非负
Constraints = [Constraints, variables.grid.P_buy(:, stage) >= 0];
% 电网售电非负（虽然这里设置为0)
Constraints = [Constraints, variables.grid.P_sell(:, stage) >= 0];
% 购电上限
Constraints = [Constraints, variables.grid.P_buy(:, stage) <= params.economic.grid_limit];
% 不允许卖电
Constraints = [Constraints, variables.grid.P_sell(:, stage) == 0];

%% 4. 设备容量和运行约束
% 4.1 CCGT 约束
% 装机数量约束：最优化装机数量 >= 已有装机数量
Constraints = [Constraints, variables.CCGT.n(stage) >= instal_exist_CCGT];
% 运行台数约束：运行台数 <= 装机数量
Constraints = [Constraints, variables.CCGT.o(:, stage) >= 0];
Constraints = [Constraints, variables.CCGT.o(:, stage) <= variables.CCGT.n(stage)];
% 出力范围约束：最小负荷 <= 出力 <= 最大负荷
for j = 1:clm_onoff_CCGT
    time_indices = map_onoff_to_t_CCGT{j};
    if ~isempty(time_indices)
        Constraints = [Constraints, ...
            variables.CCGT.o(j, stage) * P_min_CCGT <= variables.CCGT.P(time_indices, stage) <= variables.CCGT.o(j, stage) * P_max_CCGT];
    end
end

% 4.2 EBg 约束
Constraints = [Constraints, variables.EBg.n(stage) >= instal_exist_EBg];
Constraints = [Constraints, variables.EBg.o(:, stage) >= 0];
Constraints = [Constraints, variables.EBg.o(:, stage) <= variables.EBg.n(stage)];
for j = 1:clm_onoff_EBg
    time_indices = map_onoff_to_t_EBg{j};
    if ~isempty(time_indices)
        Constraints = [Constraints, ...
            variables.EBg.o(j, stage) * Q_min_EBg <= variables.EBg.Q(time_indices, stage) <= variables.EBg.o(j, stage) * Q_max_EBg];
    end
end

% 4.3 HPg 约束
Constraints = [Constraints, variables.HPg.n(stage) >= instal_exist_HPg];
Constraints = [Constraints, variables.HPg.o(:, stage) >= 0];
Constraints = [Constraints, variables.HPg.o(:, stage) <= variables.HPg.n(stage)];
for j = 1:clm_onoff_HPg
    time_indices = map_onoff_to_t_HPg{j};
    if ~isempty(time_indices)
        Constraints = [Constraints, ...
            variables.HPg.o(j, stage) * Q_min_HPg <= variables.HPg.Q(time_indices, stage) <= variables.HPg.o(j, stage) * Q_max_HPg];
    end
end

% 4.4 EBe 约束
Constraints = [Constraints, variables.EBe.n(stage) >= instal_exist_EBe];
Constraints = [Constraints, variables.EBe.o(:, stage) >= 0];
Constraints = [Constraints, variables.EBe.o(:, stage) <= variables.EBe.n(stage)];
for j = 1:clm_onoff_EBe
    time_indices = map_onoff_to_t_EBe{j};
    if ~isempty(time_indices)
        Constraints = [Constraints, ...
            variables.EBe.P(time_indices, stage) >= variables.EBe.o(j, stage) * Q_min_EBe / eta_EBe];
        Constraints = [Constraints, ...
            variables.EBe.P(time_indices, stage) <= variables.EBe.o(j, stage) * Q_max_EBe / eta_EBe];
    end
end

% 4.5 HPe 约束
Constraints = [Constraints, variables.HPe.n(stage) >= instal_exist_HPe];
Constraints = [Constraints, variables.HPe.o(:, stage) >= 0];
Constraints = [Constraints, variables.HPe.o(:, stage) <= variables.HPe.n(stage)];
for j = 1:clm_onoff_HPe
    time_indices = map_onoff_to_t_HPe{j};
    if ~isempty(time_indices)
        Constraints = [Constraints, ...
            variables.HPe.P(time_indices, stage) >= variables.HPe.o(j, stage) * Q_min_HPe / eta_HPe];
        Constraints = [Constraints, ...
            variables.HPe.P(time_indices, stage) <= variables.HPe.o(j, stage) * Q_max_HPe / eta_HPe];
    end
end

%% 5. 可再生能源约束
% 5.1 光伏发电约束
P_PV_avail = variables.PV.instal(stage) * PV_potential_stage;
Constraints = [Constraints, variables.PV.P(:, stage) >= 0];
Constraints = [Constraints, variables.PV.P(:, stage) <= P_PV_avail];

% 5.2 风力发电约束
P_WT_avail = variables.WT.instal(stage) * WT_potential_stage;
Constraints = [Constraints, variables.WT.P(:, stage) >= 0];
Constraints = [Constraints, variables.WT.P(:, stage) <= P_WT_avail];

%% 6. 储能约束
% 6.1 电储能约束
% 充放电功率非负
Constraints = [Constraints, variables.ESS.P_char(:, stage) >= 0];
Constraints = [Constraints, variables.ESS.P_disc(:, stage) >= 0];

% 充放电功率上限
P_char_max_ESS = variables.ESS.cap(stage) / params.technical.ESS.str_max;
P_disc_max_ESS = variables.ESS.cap(stage) / params.technical.ESS.str_max;
Constraints = [Constraints, variables.ESS.P_char(:, stage) <= P_char_max_ESS];
Constraints = [Constraints, variables.ESS.P_disc(:, stage) <= P_disc_max_ESS];

% SOC状态转移方程
current_stage_time_steps_real = double(real(current_stage_time_steps));
if current_stage_time_steps_real >= 1
    for idx = 1:current_stage_time_steps_real
        next_idx = idx + 1;
        if next_idx <= size(variables.ESS.SOC, 1)
            Constraints = [Constraints, ...
                variables.ESS.SOC(next_idx, stage) == variables.ESS.SOC(idx, stage) * (1 - params.technical.ESS.loss * current_stage_resolution) + ...
                (variables.ESS.P_char(idx, stage) * params.technical.ESS.eta_char - variables.ESS.P_disc(idx, stage) / params.technical.ESS.eta_disc) * current_stage_resolution];
        end
    end
end

% SOC上下限约束
Constraints = [Constraints, ...
    variables.ESS.SOC(:, stage) >= params.technical.ESS.cap_min_ratio * variables.ESS.cap(stage)];
Constraints = [Constraints, ...
    variables.ESS.SOC(:, stage) <= params.technical.ESS.cap_max_ratio * variables.ESS.cap(stage)];

% SOC周期性约束（允许小偏差）
soc_slack_ratio = 0.05;
soc_max_diff = soc_slack_ratio * variables.ESS.cap(stage);
[soc_rows, ~] = size(variables.ESS.SOC);
last_soc_idx = min(current_stage_time_steps + 1, soc_rows);
if last_soc_idx > 1
    Constraints = [Constraints, abs(variables.ESS.SOC(1, stage) - variables.ESS.SOC(last_soc_idx, stage)) <= soc_max_diff];
end

% 6.2 热储能约束
% 充放电功率非负
Constraints = [Constraints, variables.TES.P_char(:, stage) >= 0];
Constraints = [Constraints, variables.TES.P_disc(:, stage) >= 0];

% 充放电功率上限
P_char_max_TES = variables.TES.cap(stage) / params.technical.TES.str_max;
P_disc_max_TES = variables.TES.cap(stage) / params.technical.TES.str_max;
Constraints = [Constraints, variables.TES.P_char(:, stage) <= P_char_max_TES];
Constraints = [Constraints, variables.TES.P_disc(:, stage) <= P_disc_max_TES];

% SOT状态转移方程
if current_stage_time_steps_real >= 1
    for idx = 1:current_stage_time_steps_real
        next_idx = idx + 1;
        if next_idx <= size(variables.TES.SOT, 1)
            Constraints = [Constraints, ...
                variables.TES.SOT(next_idx, stage) == variables.TES.SOT(idx, stage) * (1 - params.technical.TES.loss * current_stage_resolution) + ...
                (variables.TES.P_char(idx, stage) * params.technical.TES.eta_char - variables.TES.P_disc(idx, stage) / params.technical.TES.eta_disc) * current_stage_resolution];
        end
    end
end

% SOT上下限约束
Constraints = [Constraints, ...
    variables.TES.SOT(:, stage) >= params.technical.TES.cap_min_ratio * variables.TES.cap(stage)];
Constraints = [Constraints, ...
    variables.TES.SOT(:, stage) <= params.technical.TES.cap_max_ratio * variables.TES.cap(stage)];

% SOT周期性约束（允许小偏差）
sot_slack_ratio = 0.05;
sot_max_diff = sot_slack_ratio * variables.TES.cap(stage);
[sot_rows, ~] = size(variables.TES.SOT);
last_sot_idx = min(current_stage_time_steps + 1, sot_rows);
if last_sot_idx > 1
    Constraints = [Constraints, abs(variables.TES.SOT(1, stage) - variables.TES.SOT(last_sot_idx, stage)) <= sot_max_diff];
end

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
        
        % 确保索引是实数标量并创建索引向量
        current_step_real = double(real(current_step));
        end_step_real = double(real(end_step));
        map{i} = current_step_real:end_step_real;
        
        current_step = end_step + 1;
        if current_step > total_steps
            break; % 所有步数已分配完毕
        end
    end
end