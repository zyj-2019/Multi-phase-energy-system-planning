function main()
    
    % 设置路径
    addpath(genpath('./'));
    
    % 加载系统参数
    params = parameters();
    
    % 显示多阶段规划设置
    fprintf('多阶段规划设置：\n');
    fprintf('总阶段数：%d\n', params.multistage.num_stages);
    fprintf('每阶段时间步长：%d\n', params.num_time_steps);
    
    % 1. 定义全局变量（覆盖所有阶段）
    fprintf('\n定义全局变量...\n');
    all_variables = define_variables(params);
    
    % 添加跟踪每个阶段投资的设备容量的变量
    % 这些变量用于跟踪每个阶段投资的设备在后续阶段的存续情况
    num_stages = params.multistage.num_stages;
    
    % 初始化跟踪变量
    % 对于每种设备类型，创建一个矩阵，行表示投资阶段，列表示当前阶段
    % 例如：CCGT_capacity_tracking(i,j)表示在阶段i投资的CCGT在阶段j的剩余容量
    all_variables.tracking = struct();
    
    % 定义各种设备的容量跟踪变量
    all_variables.tracking.CCGT = intvar(num_stages, num_stages);
    all_variables.tracking.EBg = intvar(num_stages, num_stages);
    all_variables.tracking.HPg = intvar(num_stages, num_stages);
    all_variables.tracking.EBe = intvar(num_stages, num_stages);
    all_variables.tracking.HPe = intvar(num_stages, num_stages);
    all_variables.tracking.PV = sdpvar(num_stages, num_stages);
    all_variables.tracking.WT = sdpvar(num_stages, num_stages);
    all_variables.tracking.ESS = sdpvar(num_stages, num_stages);
    all_variables.tracking.TES = sdpvar(num_stages, num_stages);
    
    % 2. 构建全局约束
    fprintf('\n构建全局约束...\n');
    global_constraints = [];
    
    % 2.1 添加各阶段的运行约束
    for stage = 1:params.multistage.num_stages
        fprintf('添加第 %d 阶段的运行约束...\n', stage);
        stage_constraints = build_constraints(all_variables, params, stage);
        global_constraints = [global_constraints; stage_constraints];
    end
    
    % 2.2 添加跨阶段容量演化约束
    fprintf('\n添加跨阶段容量演化约束...\n');
    
    % 初始化容量跟踪变量 - 第一阶段
    % 现有容量（假设在规划开始前就存在）- 存储在(0,1)位置表示规划前的容量在第1阶段的情况
    all_variables.tracking.CCGT_exist = intvar(1, num_stages);
    all_variables.tracking.EBg_exist = intvar(1, num_stages);
    all_variables.tracking.HPg_exist = intvar(1, num_stages);
    all_variables.tracking.EBe_exist = intvar(1, num_stages);
    all_variables.tracking.HPe_exist = intvar(1, num_stages);
    all_variables.tracking.PV_exist = sdpvar(1, num_stages);
    all_variables.tracking.WT_exist = sdpvar(1, num_stages);
    all_variables.tracking.ESS_exist = sdpvar(1, num_stages);
    all_variables.tracking.TES_exist = sdpvar(1, num_stages);
    
    % 设置第一阶段的现有容量
    global_constraints = [global_constraints, all_variables.tracking.CCGT_exist(1) == params.technical.CCGT.n_exist];
    global_constraints = [global_constraints, all_variables.tracking.EBg_exist(1) == params.technical.EBg.n_exist];
    global_constraints = [global_constraints, all_variables.tracking.HPg_exist(1) == params.technical.HPg.n_exist];
    global_constraints = [global_constraints, all_variables.tracking.EBe_exist(1) == params.technical.EBe.n_exist];
    global_constraints = [global_constraints, all_variables.tracking.HPe_exist(1) == params.technical.HPe.n_exist];
    global_constraints = [global_constraints, all_variables.tracking.PV_exist(1) == params.technical.PV.instal_exist];
    global_constraints = [global_constraints, all_variables.tracking.WT_exist(1) == params.technical.WT.instal_exist];
    global_constraints = [global_constraints, all_variables.tracking.ESS_exist(1) == params.technical.ESS.cap_exist];
    global_constraints = [global_constraints, all_variables.tracking.TES_exist(1) == params.technical.TES.cap_exist];
    
    % 新增容量 - 第一阶段
    global_constraints = [global_constraints, all_variables.tracking.CCGT(1, 1) == all_variables.CCGT.n_new(1)];
    global_constraints = [global_constraints, all_variables.tracking.EBg(1, 1) == all_variables.EBg.n_new(1)];
    global_constraints = [global_constraints, all_variables.tracking.HPg(1, 1) == all_variables.HPg.n_new(1)];
    global_constraints = [global_constraints, all_variables.tracking.EBe(1, 1) == all_variables.EBe.n_new(1)];
    global_constraints = [global_constraints, all_variables.tracking.HPe(1, 1) == all_variables.HPe.n_new(1)];
    global_constraints = [global_constraints, all_variables.tracking.PV(1, 1) == all_variables.PV.instal_new(1)];
    global_constraints = [global_constraints, all_variables.tracking.WT(1, 1) == all_variables.WT.instal_new(1)];
    global_constraints = [global_constraints, all_variables.tracking.ESS(1, 1) == all_variables.ESS.cap_new(1)];
    global_constraints = [global_constraints, all_variables.tracking.TES(1, 1) == all_variables.TES.cap_new(1)];
    
    % 第一阶段总容量 = 现有容量 + 新增容量
    global_constraints = [global_constraints, all_variables.CCGT.n(1) == all_variables.tracking.CCGT_exist(1) + all_variables.tracking.CCGT(1, 1)];
    global_constraints = [global_constraints, all_variables.EBg.n(1) == all_variables.tracking.EBg_exist(1) + all_variables.tracking.EBg(1, 1)];
    global_constraints = [global_constraints, all_variables.HPg.n(1) == all_variables.tracking.HPg_exist(1) + all_variables.tracking.HPg(1, 1)];
    global_constraints = [global_constraints, all_variables.EBe.n(1) == all_variables.tracking.EBe_exist(1) + all_variables.tracking.EBe(1, 1)];
    global_constraints = [global_constraints, all_variables.HPe.n(1) == all_variables.tracking.HPe_exist(1) + all_variables.tracking.HPe(1, 1)];
    global_constraints = [global_constraints, all_variables.PV.instal(1) == all_variables.tracking.PV_exist(1) + all_variables.tracking.PV(1, 1)];
    global_constraints = [global_constraints, all_variables.WT.instal(1) == all_variables.tracking.WT_exist(1) + all_variables.tracking.WT(1, 1)];
    global_constraints = [global_constraints, all_variables.ESS.cap(1) == all_variables.tracking.ESS_exist(1) + all_variables.tracking.ESS(1, 1)];
    global_constraints = [global_constraints, all_variables.TES.cap(1) == all_variables.tracking.TES_exist(1) + all_variables.tracking.TES(1, 1)];
    
    % 后续阶段的容量关系和跟踪变量更新
    for s = 2:params.multistage.num_stages
        % 新增容量跟踪 - 当前阶段新增的容量
        global_constraints = [global_constraints, all_variables.tracking.CCGT(s, s) == all_variables.CCGT.n_new(s)];
        global_constraints = [global_constraints, all_variables.tracking.EBg(s, s) == all_variables.EBg.n_new(s)];
        global_constraints = [global_constraints, all_variables.tracking.HPg(s, s) == all_variables.HPg.n_new(s)];
        global_constraints = [global_constraints, all_variables.tracking.EBe(s, s) == all_variables.EBe.n_new(s)];
        global_constraints = [global_constraints, all_variables.tracking.HPe(s, s) == all_variables.HPe.n_new(s)];
        global_constraints = [global_constraints, all_variables.tracking.PV(s, s) == all_variables.PV.instal_new(s)];
        global_constraints = [global_constraints, all_variables.tracking.WT(s, s) == all_variables.WT.instal_new(s)];
        global_constraints = [global_constraints, all_variables.tracking.ESS(s, s) == all_variables.ESS.cap_new(s)];
        global_constraints = [global_constraints, all_variables.tracking.TES(s, s) == all_variables.TES.cap_new(s)];
        
        % 处理现有设备在当前阶段的退役情况
        % 检查是否在当前阶段需要退役现有设备
        if any(params.technical.CCGT.retire_in_stage == s)
            global_constraints = [global_constraints, all_variables.tracking.CCGT_exist(s) == 0];
        else
            global_constraints = [global_constraints, all_variables.tracking.CCGT_exist(s) == all_variables.tracking.CCGT_exist(1)];
        end
        
        if any(params.technical.EBg.retire_in_stage == s)
            global_constraints = [global_constraints, all_variables.tracking.EBg_exist(s) == 0];
        else
            global_constraints = [global_constraints, all_variables.tracking.EBg_exist(s) == all_variables.tracking.EBg_exist(1)];
        end
        
        if any(params.technical.HPg.retire_in_stage == s)
            global_constraints = [global_constraints, all_variables.tracking.HPg_exist(s) == 0];
        else
            global_constraints = [global_constraints, all_variables.tracking.HPg_exist(s) == all_variables.tracking.HPg_exist(1)];
        end
        
        if any(params.technical.EBe.retire_in_stage == s)
            global_constraints = [global_constraints, all_variables.tracking.EBe_exist(s) == 0];
        else
            global_constraints = [global_constraints, all_variables.tracking.EBe_exist(s) == all_variables.tracking.EBe_exist(1)];
        end
        
        if any(params.technical.HPe.retire_in_stage == s)
            global_constraints = [global_constraints, all_variables.tracking.HPe_exist(s) == 0];
        else
            global_constraints = [global_constraints, all_variables.tracking.HPe_exist(s) == all_variables.tracking.HPe_exist(1)];
        end
        
        if any(params.technical.PV.retire_in_stage == s)
            global_constraints = [global_constraints, all_variables.tracking.PV_exist(s) == 0];
        else
            global_constraints = [global_constraints, all_variables.tracking.PV_exist(s) == all_variables.tracking.PV_exist(1)];
        end
        
        if any(params.technical.WT.retire_in_stage == s)
            global_constraints = [global_constraints, all_variables.tracking.WT_exist(s) == 0];
        else
            global_constraints = [global_constraints, all_variables.tracking.WT_exist(s) == all_variables.tracking.WT_exist(1)];
        end
        
        if any(params.technical.ESS.retire_in_stage == s)
            global_constraints = [global_constraints, all_variables.tracking.ESS_exist(s) == 0];
        else
            global_constraints = [global_constraints, all_variables.tracking.ESS_exist(s) == all_variables.tracking.ESS_exist(1)];
        end
        
        if any(params.technical.TES.retire_in_stage == s)
            global_constraints = [global_constraints, all_variables.tracking.TES_exist(s) == 0];
        else
            global_constraints = [global_constraints, all_variables.tracking.TES_exist(s) == all_variables.tracking.TES_exist(1)];
        end
        
        % 更新前一阶段投资的设备在当前阶段的存续情况
        for invest_stage = 1:s-1
            % 检查是否需要退役
            % CCGT
            if params.multistage.retirement_matrix.CCGT(invest_stage, s) == 1
                % 如果需要退役，则该批次容量为0
                global_constraints = [global_constraints, all_variables.tracking.CCGT(invest_stage, s) == 0];
            else
                % 否则保持与上一阶段相同
                global_constraints = [global_constraints, all_variables.tracking.CCGT(invest_stage, s) == all_variables.tracking.CCGT(invest_stage, s-1)];
            end
            
            % EBg
            if params.multistage.retirement_matrix.EBg(invest_stage, s) == 1
                global_constraints = [global_constraints, all_variables.tracking.EBg(invest_stage, s) == 0];
            else
                global_constraints = [global_constraints, all_variables.tracking.EBg(invest_stage, s) == all_variables.tracking.EBg(invest_stage, s-1)];
            end
            
            % HPg
            if params.multistage.retirement_matrix.HPg(invest_stage, s) == 1
                global_constraints = [global_constraints, all_variables.tracking.HPg(invest_stage, s) == 0];
            else
                global_constraints = [global_constraints, all_variables.tracking.HPg(invest_stage, s) == all_variables.tracking.HPg(invest_stage, s-1)];
            end
            
            % EBe
            if params.multistage.retirement_matrix.EBe(invest_stage, s) == 1
                global_constraints = [global_constraints, all_variables.tracking.EBe(invest_stage, s) == 0];
            else
                global_constraints = [global_constraints, all_variables.tracking.EBe(invest_stage, s) == all_variables.tracking.EBe(invest_stage, s-1)];
            end
            
            % HPe
            if params.multistage.retirement_matrix.HPe(invest_stage, s) == 1
                global_constraints = [global_constraints, all_variables.tracking.HPe(invest_stage, s) == 0];
            else
                global_constraints = [global_constraints, all_variables.tracking.HPe(invest_stage, s) == all_variables.tracking.HPe(invest_stage, s-1)];
            end
            
            % PV
            if params.multistage.retirement_matrix.PV(invest_stage, s) == 1
                global_constraints = [global_constraints, all_variables.tracking.PV(invest_stage, s) == 0];
            else
                global_constraints = [global_constraints, all_variables.tracking.PV(invest_stage, s) == all_variables.tracking.PV(invest_stage, s-1)];
            end
            
            % WT
            if params.multistage.retirement_matrix.WT(invest_stage, s) == 1
                global_constraints = [global_constraints, all_variables.tracking.WT(invest_stage, s) == 0];
            else
                global_constraints = [global_constraints, all_variables.tracking.WT(invest_stage, s) == all_variables.tracking.WT(invest_stage, s-1)];
            end
            
            % ESS
            if params.multistage.retirement_matrix.ESS(invest_stage, s) == 1
                global_constraints = [global_constraints, all_variables.tracking.ESS(invest_stage, s) == 0];
            else
                global_constraints = [global_constraints, all_variables.tracking.ESS(invest_stage, s) == all_variables.tracking.ESS(invest_stage, s-1)];
            end
            
            % TES
            if params.multistage.retirement_matrix.TES(invest_stage, s) == 1
                global_constraints = [global_constraints, all_variables.tracking.TES(invest_stage, s) == 0];
            else
                global_constraints = [global_constraints, all_variables.tracking.TES(invest_stage, s) == all_variables.tracking.TES(invest_stage, s-1)];
            end
        end
        
        % 计算当前阶段的总容量 = 所有批次容量之和 + 现有容量
        % CCGT
        global_constraints = [global_constraints, all_variables.CCGT.n(s) == all_variables.tracking.CCGT_exist(s) + sum(all_variables.tracking.CCGT(:, s))];
        % EBg
        global_constraints = [global_constraints, all_variables.EBg.n(s) == all_variables.tracking.EBg_exist(s) + sum(all_variables.tracking.EBg(:, s))];
        % HPg
        global_constraints = [global_constraints, all_variables.HPg.n(s) == all_variables.tracking.HPg_exist(s) + sum(all_variables.tracking.HPg(:, s))];
        % EBe
        global_constraints = [global_constraints, all_variables.EBe.n(s) == all_variables.tracking.EBe_exist(s) + sum(all_variables.tracking.EBe(:, s))];
        % HPe
        global_constraints = [global_constraints, all_variables.HPe.n(s) == all_variables.tracking.HPe_exist(s) + sum(all_variables.tracking.HPe(:, s))];
        % PV
        global_constraints = [global_constraints, all_variables.PV.instal(s) == all_variables.tracking.PV_exist(s) + sum(all_variables.tracking.PV(:, s))];
        % WT
        global_constraints = [global_constraints, all_variables.WT.instal(s) == all_variables.tracking.WT_exist(s) + sum(all_variables.tracking.WT(:, s))];
        % ESS
        global_constraints = [global_constraints, all_variables.ESS.cap(s) == all_variables.tracking.ESS_exist(s) + sum(all_variables.tracking.ESS(:, s))];
        % TES
        global_constraints = [global_constraints, all_variables.TES.cap(s) == all_variables.tracking.TES_exist(s) + sum(all_variables.tracking.TES(:, s))];
    end
    
    % 2.3 添加容量约束
    fprintf('\n添加容量约束...\n');
    for s = 1:params.multistage.num_stages
        % 新增容量非负约束
        global_constraints = [global_constraints, all_variables.CCGT.n_new(s) >= 0];
        global_constraints = [global_constraints, all_variables.EBg.n_new(s) >= 0];
        global_constraints = [global_constraints, all_variables.HPg.n_new(s) >= 0];
        global_constraints = [global_constraints, all_variables.EBe.n_new(s) >= 0];
        global_constraints = [global_constraints, all_variables.HPe.n_new(s) >= 0];
        global_constraints = [global_constraints, all_variables.PV.instal_new(s) >= 0];
        global_constraints = [global_constraints, all_variables.WT.instal_new(s) >= 0];
        global_constraints = [global_constraints, all_variables.ESS.cap_new(s) >= 0];
        global_constraints = [global_constraints, all_variables.TES.cap_new(s) >= 0];
        
        % 容量上限约束
        global_constraints = [global_constraints, all_variables.CCGT.n(s) <= 10];
        global_constraints = [global_constraints, all_variables.EBg.n(s) <= 20];
        global_constraints = [global_constraints, all_variables.HPg.n(s) <= 20];
        global_constraints = [global_constraints, all_variables.EBe.n(s) <= 20];
        global_constraints = [global_constraints, all_variables.HPe.n(s) <= 20];
        global_constraints = [global_constraints, all_variables.PV.instal(s) <= params.technical.PV.P_max];
        global_constraints = [global_constraints, all_variables.WT.instal(s) <= params.technical.WT.P_max];
        global_constraints = [global_constraints, all_variables.ESS.cap(s) <= params.technical.ESS.cap_max];
        global_constraints = [global_constraints, all_variables.TES.cap(s) <= params.technical.TES.cap_max];
    end
    
    % 2.4 添加跨阶段储能约束
    fprintf('\n添加跨阶段储能约束...\n');
    for s = 2:params.multistage.num_stages
        % 电储能(ESS)跨阶段约束
        % 确保当前阶段的初始SOC等于上一阶段的最终SOC
        global_constraints = [global_constraints, ...
            all_variables.ESS.SOC(1, s) == all_variables.ESS.SOC(end, s-1)];
        
        % 热储能(TES)跨阶段约束
        % 确保当前阶段的初始SOT等于上一阶段的最终SOT
        global_constraints = [global_constraints, ...
            all_variables.TES.SOT(1, s) == all_variables.TES.SOT(end, s-1)];
    end
    
    % 3. 构建全局目标函数
    fprintf('\n构建全局目标函数...\n');
    % 初始化折现总成本
    discounted_total_cost = 0;
    stage_costs = struct();  % 存储各阶段的成本信息
    
    for stage = 1:params.multistage.num_stages
        % 计算当前阶段的折现因子
        % 假设成本发生在阶段中点
        years_to_midpoint = sum(params.multistage.years_per_stage(1:stage-1)) + params.multistage.years_per_stage(stage)/2;
        discount_factor = 1 / (1 + params.economic.I)^years_to_midpoint;
        
        % 构建当前阶段的目标函数
        [stage_objective, stage_cost_details] = build_objective(all_variables, params, stage);
        
        % 存储当前阶段的成本信息
        stage_costs(stage).nominal_cost = stage_objective;
        stage_costs(stage).discounted_cost = discount_factor * stage_objective;
        stage_costs(stage).discount_factor = discount_factor;
        stage_costs(stage).details = stage_cost_details;
        
        % 累加折现后的成本
        discounted_total_cost = discounted_total_cost + discount_factor * stage_objective;
    end
    
    % 4. 设置求解器选项
    options = sdpsettings('solver', 'gurobi', 'verbose', 2);
   
    % 5. 求解全局优化问题
    fprintf('\n开始求解多阶段优化问题...\n');
    fprintf('优化目标：最小化所有阶段折现后的总成本\n');
    sol = optimize(global_constraints, discounted_total_cost, options);
    
    % 6. 处理优化结果
    if sol.problem == 0
        fprintf('多阶段优化成功完成\n');
        
        % 存储结果
        results.variables = value(all_variables);
        results.objective = value(discounted_total_cost);
        results.stage_costs = stage_costs;
        
        % 计算并显示各阶段的成本信息
        fprintf('\n各阶段成本信息：\n');
        for stage = 1:params.multistage.num_stages
            fprintf('\n阶段 %d:\n', stage);
            fprintf('名义总成本: %.2f\n', value(stage_costs(stage).nominal_cost));
            fprintf('折现因子: %.4f\n', stage_costs(stage).discount_factor);
            fprintf('折现后成本: %.2f\n', value(stage_costs(stage).discounted_cost));
            
            % 显示详细的成本构成
            details = stage_costs(stage).details;
            fprintf('成本构成：\n');
            fprintf('  投资成本: %.2f\n', value(details.Total_CAPEX));
            fprintf('  燃料成本: %.2f\n', value(details.cost_fuel));
            fprintf('  运维成本: %.2f\n', value(details.Total_OPEX));
            fprintf('  爬坡成本: %.2f\n', value(details.cost_ramp));
            fprintf('  启停成本: %.2f\n', value(details.cost_onoff));
            fprintf('  电网交互成本: %.2f\n', value(details.cost_net));
            fprintf('  碳排放成本: %.2f\n', value(details.cost_CO2));
            fprintf('  弃电成本: %.2f\n', value(details.cost_curtail));
        end
        
        fprintf('\n总折现成本：%.2f\n', value(discounted_total_cost));
        
        % 保存结果
        save('optimization_results.mat', 'results', 'stage_costs');
        
        % 绘制结果
        plot_results(results, params);
    else
        fprintf('多阶段优化失败，错误代码：%d\n', sol.problem);
    end
end


%% update_stage_initial_conditions的函数定义
function update_stage_initial_conditions(params, stage, results)
    % 更新下一阶段的初始条件
    current_vars = results.stage(stage).variables;
    
    % 更新设备容量
    params.device.P_CCGT_max = current_vars.CCGT.n * params.device.P_CCGT_max;
    params.device.Q_EBg_max = current_vars.EBg.n * params.device.Q_EBg_max;
    params.device.Q_HPg_max = current_vars.HPg.n * params.device.Q_HPg_max;
    params.device.Q_EBe_max = current_vars.EBe.n * params.device.Q_EBe_max;
    params.device.Q_HPe_max = current_vars.HPe.n * params.device.Q_HPe_max;
    
    % 更新储能状态
    params.device.SOC_ESS_init = current_vars.ESS.SOC(end);
    params.device.SOT_TES_init = current_vars.TES.SOT(end);
end

function total_cost = calculate_total_cost(results, params)
    % 计算总成本
    total_cost = results.objective;
end

%% merge_stage_results的函数定义
function merged_results = merge_stage_results(results, params)
    % 合并各阶段结果
    merged_results = struct();
    
    % 合并时间序列数据
    total_steps = params.multistage.num_stages * params.num_time_steps;
    merged_results.P_CCGT = zeros(total_steps, 1);
    merged_results.P_PV = zeros(total_steps, 1);
    merged_results.P_WT = zeros(total_steps, 1);
    merged_results.Q_EBg = zeros(total_steps, 1);
    merged_results.Q_HPg = zeros(total_steps, 1);
    merged_results.Q_EBe = zeros(total_steps, 1);
    merged_results.Q_HPe = zeros(total_steps, 1);
    merged_results.SOC_ESS = zeros(total_steps + 1, 1);
    merged_results.SOT_TES = zeros(total_steps + 1, 1);
    
    % 填充数据
    for stage = 1:params.multistage.num_stages
        start_idx = (stage-1) * params.num_time_steps + 1;
        end_idx = stage * params.num_time_steps;
        
        stage_vars = results.stage(stage).variables;
        merged_results.P_CCGT(start_idx:end_idx) = stage_vars.CCGT.P;
        merged_results.P_PV(start_idx:end_idx) = stage_vars.PV.P;
        merged_results.P_WT(start_idx:end_idx) = stage_vars.WT.P;
        merged_results.Q_EBg(start_idx:end_idx) = stage_vars.EBg.Q;
        merged_results.Q_HPg(start_idx:end_idx) = stage_vars.HPg.Q;
        merged_results.Q_EBe(start_idx:end_idx) = stage_vars.EBe.Q;
        merged_results.Q_HPe(start_idx:end_idx) = stage_vars.HPe.Q;
        merged_results.SOC_ESS(start_idx:end_idx+1) = stage_vars.ESS.SOC;
        merged_results.SOT_TES(start_idx:end_idx+1) = stage_vars.TES.SOT;
    end
end

%% plot_results的函数定义
function plot_results(results, params)
    % 绘制结果
    figure('Name', '优化结果');
    
    % 电功率
    subplot(3,1,1);
    plot(results.P_CCGT, 'b-', 'LineWidth', 1.5);
    hold on;
    plot(results.P_PV, 'g-', 'LineWidth', 1.5);
    plot(results.P_WT, 'c-', 'LineWidth', 1.5);
    legend('CCGT', 'PV', 'WT');
    title('电功率');
    xlabel('时间步');
    ylabel('功率 (MW)');
    grid on;
    
    % 热功率
    subplot(3,1,2);
    plot(results.Q_EBg, 'r-', 'LineWidth', 1.5);
    hold on;
    plot(results.Q_HPg, 'm-', 'LineWidth', 1.5);
    plot(results.Q_EBe, 'y-', 'LineWidth', 1.5);
    plot(results.Q_HPe, 'k-', 'LineWidth', 1.5);
    legend('EBg', 'HPg', 'EBe', 'HPe');
    title('热功率');
    xlabel('时间步');
    ylabel('功率 (MW)');
    grid on;
    
    % 储能状态
    subplot(3,1,3);
    plot(results.SOC_ESS, 'b-', 'LineWidth', 1.5);
    hold on;
    plot(results.SOT_TES, 'r-', 'LineWidth', 1.5);
    legend('ESS', 'TES');
    title('储能状态');
    xlabel('时间步');
    ylabel('状态');
    grid on;
end

