function results = process_results(variables, params, diagnosis)
% 处理优化结果
%
% 输入参数
%   variables: 包含所有优化变量的结构体
%   params: 包含系统参数和预测数据的结构体
%   diagnosis: YALMIP 优化求解的诊断信息
%
% 输出参数
%   results: 包含结果数据的结构体

results = struct();
results.diagnosis = diagnosis; % 存储 YALMIP 诊断信息

if diagnosis.problem == 0 % 优化求解成功时取值
    % 获取多阶段规划参数
    num_stages = params.multistage.num_stages;
    years_per_stage = params.multistage.years_per_stage;
    
    % 为各阶段结果创建结构体
    results.stages = cell(num_stages, 1);
    
    % 处理各阶段的结果
    for s = 1:num_stages
        results.stages{s} = struct();
        
        %% 获取设备容量配置结果
        results.stages{s}.CCGT.n = value(variables.CCGT.n(s));
        results.stages{s}.CCGT.n_new = value(variables.CCGT.n_new(s));
        results.stages{s}.EBg.n = value(variables.EBg.n(s)); 
        results.stages{s}.EBg.n_new = value(variables.EBg.n_new(s)); 
        results.stages{s}.HPg.n = value(variables.HPg.n(s)); 
        results.stages{s}.HPg.n_new = value(variables.HPg.n_new(s)); 
        results.stages{s}.EBe.n = value(variables.EBe.n(s)); 
        results.stages{s}.EBe.n_new = value(variables.EBe.n_new(s)); 
        results.stages{s}.HPe.n = value(variables.HPe.n(s)); 
        results.stages{s}.HPe.n_new = value(variables.HPe.n_new(s)); 
        results.stages{s}.PV.instal = value(variables.PV.instal(s));
        results.stages{s}.PV.instal_new = value(variables.PV.instal_new(s));
        results.stages{s}.WT.instal = value(variables.WT.instal(s));
        results.stages{s}.WT.instal_new = value(variables.WT.instal_new(s));
        results.stages{s}.ESS.cap = value(variables.ESS.cap(s));
        results.stages{s}.ESS.cap_new = value(variables.ESS.cap_new(s));
        results.stages{s}.TES.cap = value(variables.TES.cap(s));
        results.stages{s}.TES.cap_new = value(variables.TES.cap_new(s));

        %% 获取时间序列运行结果
        results.stages{s}.CCGT.P = value(variables.CCGT.P(:, s));
        results.stages{s}.EBg.Q = value(variables.EBg.Q(:, s)); 
        results.stages{s}.HPg.Q = value(variables.HPg.Q(:, s)); 
        results.stages{s}.EBe.Q = value(variables.EBe.Q(:, s)); 
        results.stages{s}.HPe.Q = value(variables.HPe.Q(:, s)); 
        results.stages{s}.EBe.P = value(variables.EBe.P(:, s)); 
        results.stages{s}.HPe.P = value(variables.HPe.P(:, s));
        results.stages{s}.PV.P = value(variables.PV.P(:, s));
        results.stages{s}.WT.P = value(variables.WT.P(:, s));
        results.stages{s}.ESS.P_char = value(variables.ESS.P_char(:, s));
        results.stages{s}.ESS.P_disc = value(variables.ESS.P_disc(:, s));
        results.stages{s}.ESS.SOC = value(variables.ESS.SOC(:, s));
        results.stages{s}.TES.P_char = value(variables.TES.P_char(:, s));
        results.stages{s}.TES.P_disc = value(variables.TES.P_disc(:, s));
        results.stages{s}.TES.SOT = value(variables.TES.SOT(:, s));
        results.stages{s}.grid.P_buy = value(variables.grid.P_buy(:, s));
        results.stages{s}.grid.P_sell = value(variables.grid.P_sell(:, s));

        %% 获取开关和状态变量结果
        results.stages{s}.CCGT.o = value(variables.CCGT.o(:, s));
        results.stages{s}.CCGT.on = value(variables.CCGT.on(:, s));
        results.stages{s}.CCGT.off = value(variables.CCGT.off(:, s));
        results.stages{s}.EBg.o = value(variables.EBg.o(:, s)); 
        results.stages{s}.EBg.on = value(variables.EBg.on(:, s)); 
        results.stages{s}.EBg.off = value(variables.EBg.off(:, s)); 
        results.stages{s}.HPg.o = value(variables.HPg.o(:, s)); 
        results.stages{s}.HPg.on = value(variables.HPg.on(:, s)); 
        results.stages{s}.HPg.off = value(variables.HPg.off(:, s)); 
        results.stages{s}.EBe.o = value(variables.EBe.o(:, s)); 
        results.stages{s}.EBe.on = value(variables.EBe.on(:, s)); 
        results.stages{s}.EBe.off = value(variables.EBe.off(:, s)); 
        results.stages{s}.HPe.o = value(variables.HPe.o(:, s)); 
        results.stages{s}.HPe.on = value(variables.HPe.on(:, s)); 
        results.stages{s}.HPe.off = value(variables.HPe.off(:, s));

        %% 获取爬坡和出力变量
        results.stages{s}.CCGT.ramp_up = value(variables.CCGT.ramp_up(:, s));
        results.stages{s}.CCGT.ramp_dn = value(variables.CCGT.ramp_dn(:, s));
        results.stages{s}.EBg.ramp_up = value(variables.EBg.ramp_up(:, s));
        results.stages{s}.EBg.ramp_dn = value(variables.EBg.ramp_dn(:, s)); 
        results.stages{s}.HPg.ramp_up = value(variables.HPg.ramp_up(:, s)); 
        results.stages{s}.HPg.ramp_dn = value(variables.HPg.ramp_dn(:, s));
        results.stages{s}.EBe.ramp_up = value(variables.EBe.ramp_up(:, s)); 
        results.stages{s}.EBe.ramp_dn = value(variables.EBe.ramp_dn(:, s));
        results.stages{s}.HPe.ramp_up = value(variables.HPe.ramp_up(:, s));
        results.stages{s}.HPe.ramp_dn = value(variables.HPe.ramp_dn(:, s)); 
        results.stages{s}.PV.ramp_up = value(variables.PV.ramp_up(:, s));
        results.stages{s}.PV.ramp_dn = value(variables.PV.ramp_dn(:, s));
        results.stages{s}.WT.ramp_up = value(variables.WT.ramp_up(:, s));
        results.stages{s}.WT.ramp_dn = value(variables.WT.ramp_dn(:, s));

        % 计算弃电量
        PV_potential = params.stage_renewable.PV_potential{s};
        WT_potential = params.stage_renewable.WT_potential{s};
        P_PV_avail = results.stages{s}.PV.instal .* PV_potential;
        P_WT_avail = results.stages{s}.WT.instal .* WT_potential;
        results.stages{s}.PV.curtail = P_PV_avail - results.stages{s}.PV.P;
        results.stages{s}.WT.curtail = P_WT_avail - results.stages{s}.WT.P;
        
        % 计算可再生能源的可用功率和弃电量
        results.stages{s}.PV.avail = value(variables.PV.instal(s)) .* PV_potential;
        results.stages{s}.WT.avail = value(variables.WT.instal(s)) .* WT_potential;

        % 计算弃电量
        results.stages{s}.PV.curtail = max(0, results.stages{s}.PV.avail - value(variables.PV.P(:, s)));
        results.stages{s}.WT.curtail = max(0, results.stages{s}.WT.avail - value(variables.WT.P(:, s)));
        
        %% 计算关键指标结果
        t_resolution_h = params.time.resolution / 60;
        annual_factor = sum(params.time.Day_weight);
        stage_factor = years_per_stage(s);
        LHV_gas = params.environment.LHV_gas;
        eta_CCGT = params.technical.CCGT.eta;
        eta_EBg = params.technical.EBg.eta;
        COP_HPg = params.technical.HPg.COP;

        E_CCGT_ts = results.stages{s}.CCGT.P .* t_resolution_h;
        E_EBg_ts = results.stages{s}.EBg.Q .* t_resolution_h;
        E_HPg_ts = results.stages{s}.HPg.Q .* t_resolution_h;

        Gas_cons_CCGT_ts = E_CCGT_ts .* 3600 ./ eta_CCGT ./ LHV_gas;
        Gas_cons_EBg_ts = E_EBg_ts .* 3600 ./ eta_EBg ./ LHV_gas;
        Gas_cons_HPg_ts = E_HPg_ts .* 3600 ./ COP_HPg ./ LHV_gas;
        results.stages{s}.annual_gas_cons = sum(Gas_cons_CCGT_ts + Gas_cons_EBg_ts + Gas_cons_HPg_ts) .* annual_factor .* stage_factor;

        E_buy_ts = results.stages{s}.grid.P_buy .* t_resolution_h;
        CO2_from_gas_annual = results.stages{s}.annual_gas_cons .* params.environment.gas_CO2;
        CO2_from_grid_annual = sum(E_buy_ts) .* params.environment.grid_CO2 .* annual_factor .* stage_factor;
        results.stages{s}.annual_co2_emission = CO2_from_gas_annual + CO2_from_grid_annual;
    end
    
    % 将第一阶段的数据复制到顶层，以保持向后兼容性
    fields_to_copy = fieldnames(results.stages{1});
    for i = 1:length(fields_to_copy)
        field = fields_to_copy{i};
        if isstruct(results.stages{1}.(field))
            results.(field) = results.stages{1}.(field);
        end
    end
    
    % 从build_objective获取成本信息
    [~, cost_details] = build_objective(variables, params);
    
    % 保存成本信息
    results.cost_details = cost_details;
    results.Total_CAPEX = cost_details.Total_CAPEX;
    results.cost_fuel = cost_details.cost_fuel;
    results.Total_OPEX = cost_details.Total_OPEX;
    results.cost_ramp = cost_details.cost_ramp;
    results.cost_onoff = cost_details.cost_onoff;
    results.cost_net = cost_details.cost_net;
    results.cost_CO2 = cost_details.cost_CO2;
    results.cost_curtail = cost_details.cost_curtail;
    
    % 汇总全规划期的资源配置
    results.summary = struct();
    
    % 正确方法：使用数组方式收集各阶段的数据
    % 初始化数组
    CCGT_n = zeros(1, num_stages);
    CCGT_n_new = zeros(1, num_stages);
    PV_instal = zeros(1, num_stages);
    PV_instal_new = zeros(1, num_stages);
    WT_instal = zeros(1, num_stages);
    WT_instal_new = zeros(1, num_stages);
    ESS_cap = zeros(1, num_stages);
    ESS_cap_new = zeros(1, num_stages);
    TES_cap = zeros(1, num_stages);
    TES_cap_new = zeros(1, num_stages);
    
    % 从每个阶段提取数据
    for s = 1:num_stages
        CCGT_n(s) = results.stages{s}.CCGT.n;
        CCGT_n_new(s) = results.stages{s}.CCGT.n_new;
        PV_instal(s) = results.stages{s}.PV.instal;
        PV_instal_new(s) = results.stages{s}.PV.instal_new;
        WT_instal(s) = results.stages{s}.WT.instal;
        WT_instal_new(s) = results.stages{s}.WT.instal_new;
        ESS_cap(s) = results.stages{s}.ESS.cap;
        ESS_cap_new(s) = results.stages{s}.ESS.cap_new;
        TES_cap(s) = results.stages{s}.TES.cap;
        TES_cap_new(s) = results.stages{s}.TES.cap_new;
    end
    
    % 将收集的数据存储到summary结构中
    results.summary.CCGT_n = CCGT_n;
    results.summary.CCGT_n_new = CCGT_n_new;
    results.summary.PV_instal = PV_instal;
    results.summary.PV_instal_new = PV_instal_new;
    results.summary.WT_instal = WT_instal;
    results.summary.WT_instal_new = WT_instal_new;
    results.summary.ESS_cap = ESS_cap;
    results.summary.ESS_cap_new = ESS_cap_new;
    results.summary.TES_cap = TES_cap;
    results.summary.TES_cap_new = TES_cap_new;
    
    % 计算全规划期碳排放
    annual_co2_emissions = zeros(num_stages, 1);
    for s = 1:num_stages
        annual_co2_emissions(s) = results.stages{s}.annual_co2_emission;
    end
    results.summary.annual_co2_emissions = annual_co2_emissions;
    results.summary.total_co2_emission = sum(annual_co2_emissions);
    
else
    warning('优化求解失败或未成功，无法获取有效结果');
    % 设置 NaN 默认值
    results.diagnosis = diagnosis;
end

end 