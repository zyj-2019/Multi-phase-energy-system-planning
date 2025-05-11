function variables = define_variables(params)
% 定义优化变量 Define optimization variables
% 
% 输入参数：
%   params: 包含所有系统参数和预处理数据的结构体
% 
% 输出参数：
%   variables: 包含所有优化变量的结构体
%
% 变量维度说明：
%   t: 每个阶段的时间步数
%   s: 规划阶段数
%   clm_onoff_*: 各设备的开关周期数

%% 获取时间步长和开关周期维度
% 总时间步长 t 应由 parameters.m 计算得出并存储在 params.num_time_steps
if isfield(params, 'num_time_steps')
    t = params.num_time_steps;
else
    error('无法确定优化时间步长总数 t，请确保 params.num_time_steps 已在 parameters.m 中定义');
end

% 阶段数量 s 应由 parameters.m 计算得出并存储在 params.multistage.num_stages
if isfield(params, 'multistage') && isfield(params.multistage, 'num_stages')
    s = params.multistage.num_stages;
else
    error('无法确定规划阶段数量 s，请确保 params.multistage.num_stages 已在 parameters.m 中定义');
end

% 开关周期维度
if isfield(params, 'schedule') && isfield(params.schedule, 'clm_onoff_CCGT')
    clm_onoff_CCGT = params.schedule.clm_onoff_CCGT;
    clm_onoff_EBg = params.schedule.clm_onoff_EBg;
    clm_onoff_HPg = params.schedule.clm_onoff_HPg;
    clm_onoff_EBe = params.schedule.clm_onoff_EBe;
    clm_onoff_HPe = params.schedule.clm_onoff_HPe;
else
    error('无法获取开关周期维度 clm_onoff_...，请确保已在 parameters.m 中计算并存储');
end

%% 定义变量
variables = struct();

% 投资决策变量（阶段维度）
% 所有投资决策变量都是 s x 1 维的向量，表示每个阶段的决策

% 燃气轮机变量 (CCGT)
variables.CCGT = struct(); 
variables.CCGT.n = intvar(s, 1);                 % 各阶段装机数，投资决策变量 [s x 1]
variables.CCGT.n_new = intvar(s, 1);             % 各阶段新增装机数 [s x 1]
variables.CCGT.P = sdpvar(t, s);                 % 各阶段输出功率 [t x s]
variables.CCGT.o = intvar(clm_onoff_CCGT, s);    % 各阶段运行台数 [clm_onoff_CCGT x s]
variables.CCGT.on = intvar(clm_onoff_CCGT, s);   % 各阶段开机台数 [clm_onoff_CCGT x s]
variables.CCGT.off = intvar(clm_onoff_CCGT, s);  % 各阶段关机台数 [clm_onoff_CCGT x s]
variables.CCGT.ramp_up = sdpvar(t, s);           % 各阶段向上爬坡 [t x s]
variables.CCGT.ramp_dn = sdpvar(t, s);           % 各阶段向下爬坡 [t x s]

% 光伏变量
variables.PV = struct();
variables.PV.instal = sdpvar(s, 1);              % 各阶段装机容量 [s x 1]
variables.PV.instal_new = sdpvar(s, 1);          % 各阶段新增装机容量 [s x 1]
variables.PV.P = sdpvar(t, s);                   % 各阶段输出功率 [t x s]
variables.PV.ramp_up = sdpvar(t, s);             % 各阶段向上爬坡 [t x s]
variables.PV.ramp_dn = sdpvar(t, s);             % 各阶段向下爬坡 [t x s]

% 风电变量
variables.WT = struct();
variables.WT.instal = sdpvar(s, 1);              % 各阶段装机容量 [s x 1]
variables.WT.instal_new = sdpvar(s, 1);          % 各阶段新增装机容量 [s x 1]
variables.WT.P = sdpvar(t, s);                   % 各阶段输出功率 [t x s]
variables.WT.ramp_up = sdpvar(t, s);             % 各阶段向上爬坡 [t x s]
variables.WT.ramp_dn = sdpvar(t, s);             % 各阶段向下爬坡 [t x s]

% 燃气锅炉变量 (EBg)
variables.EBg = struct();
variables.EBg.n = intvar(s, 1);                  % 各阶段装机数 [s x 1]
variables.EBg.n_new = intvar(s, 1);              % 各阶段新增装机数 [s x 1]
variables.EBg.Q = sdpvar(t, s);                  % 各阶段输出功率 [t x s]
variables.EBg.o = intvar(clm_onoff_EBg, s);      % 各阶段运行台数 [clm_onoff_EBg x s]
variables.EBg.on = intvar(clm_onoff_EBg, s);     % 各阶段开机台数 [clm_onoff_EBg x s]
variables.EBg.off = intvar(clm_onoff_EBg, s);    % 各阶段关机台数 [clm_onoff_EBg x s]
variables.EBg.ramp_up = sdpvar(t, s);            % 各阶段向上爬坡 [t x s]
variables.EBg.ramp_dn = sdpvar(t, s);            % 各阶段向下爬坡 [t x s]

% 燃气吸收式热泵变量 (HPg)
variables.HPg = struct();
variables.HPg.n = intvar(s, 1);                  % 各阶段装机数 [s x 1]
variables.HPg.n_new = intvar(s, 1);              % 各阶段新增装机数 [s x 1]
variables.HPg.Q = sdpvar(t, s);                  % 各阶段输出功率 [t x s]
variables.HPg.o = intvar(clm_onoff_HPg, s);      % 各阶段运行台数 [clm_onoff_HPg x s]
variables.HPg.on = intvar(clm_onoff_HPg, s);     % 各阶段开机台数 [clm_onoff_HPg x s]
variables.HPg.off = intvar(clm_onoff_HPg, s);    % 各阶段关机台数 [clm_onoff_HPg x s]
variables.HPg.ramp_up = sdpvar(t, s);            % 各阶段向上爬坡 [t x s]
variables.HPg.ramp_dn = sdpvar(t, s);            % 各阶段向下爬坡 [t x s]

% 电锅炉变量 (EBe)
variables.EBe = struct();
variables.EBe.n = intvar(s, 1);                  % 各阶段装机数 [s x 1]
variables.EBe.n_new = intvar(s, 1);              % 各阶段新增装机数 [s x 1]
variables.EBe.Q = sdpvar(t, s);                  % 各阶段输出功率 [t x s]
variables.EBe.P = sdpvar(t, s);                  % 各阶段输入功率 [t x s]
variables.EBe.o = intvar(clm_onoff_EBe, s);      % 各阶段运行台数 [clm_onoff_EBe x s]
variables.EBe.on = intvar(clm_onoff_EBe, s);     % 各阶段开机台数 [clm_onoff_EBe x s]
variables.EBe.off = intvar(clm_onoff_EBe, s);    % 各阶段关机台数 [clm_onoff_EBe x s]
variables.EBe.ramp_up = sdpvar(t, s);            % 各阶段向上爬坡 [t x s]
variables.EBe.ramp_dn = sdpvar(t, s);            % 各阶段向下爬坡 [t x s]

% 电热泵变量 (HPe)
variables.HPe = struct();
variables.HPe.n = intvar(s, 1);                  % 各阶段装机数 [s x 1]
variables.HPe.n_new = intvar(s, 1);              % 各阶段新增装机数 [s x 1]
variables.HPe.Q = sdpvar(t, s);                  % 各阶段输出功率 [t x s]
variables.HPe.P = sdpvar(t, s);                  % 各阶段输入功率 [t x s]
variables.HPe.o = intvar(clm_onoff_HPe, s);      % 各阶段运行台数 [clm_onoff_HPe x s]
variables.HPe.on = intvar(clm_onoff_HPe, s);     % 各阶段开机台数 [clm_onoff_HPe x s]
variables.HPe.off = intvar(clm_onoff_HPe, s);    % 各阶段关机台数 [clm_onoff_HPe x s]
variables.HPe.ramp_up = sdpvar(t, s);            % 各阶段向上爬坡 [t x s]
variables.HPe.ramp_dn = sdpvar(t, s);            % 各阶段向下爬坡 [t x s]

% 储电变量 (ESS)
variables.ESS = struct();
variables.ESS.cap = sdpvar(s, 1);                % 各阶段储能容量 [s x 1]
variables.ESS.cap_new = sdpvar(s, 1);            % 各阶段新增储能容量 [s x 1]
variables.ESS.P_char = sdpvar(t, s);             % 各阶段储能充电功率 [t x s]
variables.ESS.P_disc = sdpvar(t, s);             % 各阶段储能放电功率 [t x s]
variables.ESS.SOC = sdpvar(t+1, s);              % 各阶段储能状态 [t+1 x s]

% 热储能变量 (TES)
variables.TES = struct();
variables.TES.cap = sdpvar(s, 1);                % 各阶段储能容量 [s x 1]
variables.TES.cap_new = sdpvar(s, 1);            % 各阶段新增储能容量 [s x 1]
variables.TES.P_char = sdpvar(t, s);             % 各阶段储能充电功率 [t x s]
variables.TES.P_disc = sdpvar(t, s);             % 各阶段储能放电功率 [t x s]
variables.TES.SOT = sdpvar(t+1, s);              % 各阶段储能状态 [t+1 x s]

% 电网变量
variables.grid = struct();
variables.grid.P_buy = sdpvar(t, s);             % 各阶段购电功率 [t x s]
variables.grid.P_sell = sdpvar(t, s);            % 各阶段售电功率 [t x s]

% 平衡约束松弛变量
variables.slack = struct();
variables.slack.elec_balance = sdpvar(t, s);     % 电力平衡松弛变量 [t x s]
variables.slack.heat_balance = sdpvar(t, s);     % 热力平衡松弛变量 [t x s]

% % 负荷变量 (不再在此处定义，从 params 获取)
% variables.load = struct();
% variables.load.P = params.load.P; % 从 params 结构体获取预处理的电负荷数据
% variables.load.H = params.load.H; % 从 params 结构体获取预处理的热负荷数据

% % 可再生能源潜力 (不再在此处定义，从 params 获取)
% variables.renewable = struct();
% variables.renewable.PV_potential = params.renewable.PV_potential; % 从 params 获取处理后的 PV 潜力
% variables.renewable.WT_potential = params.renewable.WT_potential; % 从 params 获取处理后的 WT 潜力

end 