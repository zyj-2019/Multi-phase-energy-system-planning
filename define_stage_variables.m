function variables = define_stage_variables(params, stage)
    % 为单个阶段定义变量
    variables = struct();
    
    % 获取时间步长
    t = params.num_time_steps;
    
    % 开关周期维度
    clm_onoff_CCGT = params.schedule.clm_onoff_CCGT;
    clm_onoff_EBg = params.schedule.clm_onoff_EBg;
    clm_onoff_HPg = params.schedule.clm_onoff_HPg;
    clm_onoff_EBe = params.schedule.clm_onoff_EBe;
    clm_onoff_HPe = params.schedule.clm_onoff_HPe;
    
    % CCGT变量
    variables.CCGT.n = intvar(1, 1);          % 装机数量
    variables.CCGT.n_new = intvar(1, 1);      % 新增装机数量
    variables.CCGT.P = sdpvar(t, 1);          % 输出功率
    variables.CCGT.o = intvar(clm_onoff_CCGT, 1);   % 运行台数
    variables.CCGT.on = intvar(clm_onoff_CCGT, 1);  % 开机台数
    variables.CCGT.off = intvar(clm_onoff_CCGT, 1); % 关机台数
    variables.CCGT.ramp_up = sdpvar(t, 1);    % 爬坡上升
    variables.CCGT.ramp_dn = sdpvar(t, 1);    % 爬坡下降
    
    % PV变量
    variables.PV.instal = sdpvar(1, 1);       % 装机容量
    variables.PV.instal_new = sdpvar(1, 1);   % 新增装机容量
    variables.PV.P = sdpvar(t, 1);            % 出力
    variables.PV.P_cur = sdpvar(t, 1);        % 弃光功率
    variables.PV.ramp_up = sdpvar(t, 1);      % 爬坡上升
    variables.PV.ramp_dn = sdpvar(t, 1);      % 爬坡下降
    
    % WT变量
    variables.WT.instal = sdpvar(1, 1);       % 装机容量
    variables.WT.instal_new = sdpvar(1, 1);   % 新增装机容量
    variables.WT.P = sdpvar(t, 1);            % 出力
    variables.WT.P_cur = sdpvar(t, 1);        % 弃风功率
    variables.WT.ramp_up = sdpvar(t, 1);      % 爬坡上升
    variables.WT.ramp_dn = sdpvar(t, 1);      % 爬坡下降
    
    % 热设备变量 - EBg
    variables.EBg.n = intvar(1, 1);          % 装机数量
    variables.EBg.n_new = intvar(1, 1);      % 新增装机数量
    variables.EBg.Q = sdpvar(t, 1);          % 输出热功率
    variables.EBg.o = intvar(clm_onoff_EBg, 1);  % 运行台数
    variables.EBg.on = intvar(clm_onoff_EBg, 1); % 开机台数
    variables.EBg.off = intvar(clm_onoff_EBg, 1);% 关机台数
    variables.EBg.ramp_up = sdpvar(t, 1);    % 爬坡上升
    variables.EBg.ramp_dn = sdpvar(t, 1);    % 爬坡下降
    
    % 热设备变量 - HPg
    variables.HPg.n = intvar(1, 1);          % 装机数量
    variables.HPg.n_new = intvar(1, 1);      % 新增装机数量
    variables.HPg.Q = sdpvar(t, 1);          % 输出热功率
    variables.HPg.o = intvar(clm_onoff_HPg, 1);  % 运行台数
    variables.HPg.on = intvar(clm_onoff_HPg, 1); % 开机台数
    variables.HPg.off = intvar(clm_onoff_HPg, 1);% 关机台数
    variables.HPg.ramp_up = sdpvar(t, 1);    % 爬坡上升
    variables.HPg.ramp_dn = sdpvar(t, 1);    % 爬坡下降
    
    % 热设备变量 - EBe
    variables.EBe.n = intvar(1, 1);          % 装机数量
    variables.EBe.n_new = intvar(1, 1);      % 新增装机数量
    variables.EBe.Q = sdpvar(t, 1);          % 输出热功率
    variables.EBe.P = sdpvar(t, 1);          % 输入电功率
    variables.EBe.o = intvar(clm_onoff_EBe, 1);  % 运行台数
    variables.EBe.on = intvar(clm_onoff_EBe, 1); % 开机台数
    variables.EBe.off = intvar(clm_onoff_EBe, 1);% 关机台数
    variables.EBe.ramp_up = sdpvar(t, 1);    % 爬坡上升
    variables.EBe.ramp_dn = sdpvar(t, 1);    % 爬坡下降
    
    % 热设备变量 - HPe
    variables.HPe.n = intvar(1, 1);          % 装机数量
    variables.HPe.n_new = intvar(1, 1);      % 新增装机数量
    variables.HPe.Q = sdpvar(t, 1);          % 输出热功率
    variables.HPe.P = sdpvar(t, 1);          % 输入电功率
    variables.HPe.o = intvar(clm_onoff_HPe, 1);  % 运行台数
    variables.HPe.on = intvar(clm_onoff_HPe, 1); % 开机台数
    variables.HPe.off = intvar(clm_onoff_HPe, 1);% 关机台数
    variables.HPe.ramp_up = sdpvar(t, 1);    % 爬坡上升
    variables.HPe.ramp_dn = sdpvar(t, 1);    % 爬坡下降
    
    % 储能变量 - ESS
    variables.ESS.cap = sdpvar(1, 1);        % 容量
    variables.ESS.cap_new = sdpvar(1, 1);    % 新增容量
    variables.ESS.P_char = sdpvar(t, 1);     % 充电功率
    variables.ESS.P_disc = sdpvar(t, 1);     % 放电功率
    variables.ESS.SOC = sdpvar(t+1, 1);      % 荷电状态
    
    % 储能变量 - TES
    variables.TES.cap = sdpvar(1, 1);        % 容量
    variables.TES.cap_new = sdpvar(1, 1);    % 新增容量
    variables.TES.P_char = sdpvar(t, 1);     % 充热功率
    variables.TES.P_disc = sdpvar(t, 1);     % 放热功率
    variables.TES.SOT = sdpvar(t+1, 1);      % 储热状态
    
    % 电网交互变量
    variables.grid = struct();
    variables.grid.P_buy = sdpvar(t, 1);         % 购电功率
    variables.grid.P_sell = sdpvar(t, 1);        % 售电功率

    % 平衡约束松弛变量
    variables.slack = struct();
    variables.slack.elec_balance = sdpvar(t, 1); % 电力平衡松弛变量
    variables.slack.heat_balance = sdpvar(t, 1); % 热力平衡松弛变量
end 