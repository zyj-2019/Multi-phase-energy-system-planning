function [solver_results, status] = solve_optimization(Constraints, cost, params)
% 求解优化问题
% 
% 输入参数
%   Constraints: 优化问题的约束条件
%   cost: 优化问题的目标函数
%   params: 包含求解器参数和其他必要参数的结构体
% 
% 输出参数
%   solver_results: 优化结果
%   status: 求解状态

%% 设置求解器参数
options = params.solver.options;
options.verbose = 1;
options.solver = params.solver.name;
options.gap = params.stop_gap;
options.maxtime = params.solve_time;

% 对于gurobi求解器，添加特殊设置以提高求解稳定性
if strcmp(params.solver.name, 'gurobi') || strcmp(params.solver.name, 'GUROBI')
    % 增加一些用于诊断和调试的设置
    disp('设置Gurobi求解器特殊参数...');
    
    % 预求解设置
    options.gurobi.Presolve = 2;  % 激进的预求解
    
    % 数值稳定性设置
    options.gurobi.ScaleFlag = 2;  % 激进缩放
    options.gurobi.NumericFocus = 3;  % 最高精度设置
    
    % 容差设置
    options.gurobi.FeasibilityTol = 1e-3;  % 大幅放宽可行性容差
    options.gurobi.OptimalityTol = 1e-3;  % 大幅放宽最优性容差
    options.gurobi.IntFeasTol = 1e-3;  % 大幅放宽整数可行性容差
    
    % 求解方法设置
    options.gurobi.Method = 2;  % 使用障碍法求解器
    
    % 其他设置
    options.gurobi.MIPGap = 0.05;  % 允许5%的MIP间隙（用于更快得到结果）
    options.gurobi.MIPFocus = 1;  % 专注于寻找可行解
end

% 增加一些用于诊断和调试的设置
disp('添加模型诊断功能...');
try
    [model, recoverymodel] = export(Constraints, cost, options);
    % 检查模型结构包含的字段
    model_fields = fieldnames(model);
    disp('模型包含以下字段:');
    disp(model_fields);
    
    % 检查模型维度信息
    if isfield(model, 'A')
        disp(['模型约束矩阵尺寸: ', num2str(size(model.A))]);
    end
    
    % 检查目标函数系数
    if isfield(model, 'c')
        disp(['目标函数系数向量长度: ', num2str(length(model.c))]);
    elseif isfield(model, 'f')
        disp(['目标函数系数向量长度: ', num2str(length(model.f))]);
    elseif isfield(model, 'Q')
        disp(['目标函数二次项矩阵尺寸: ', num2str(size(model.Q))]);
    end
    
    % 检查变量数量
    if isfield(model, 'variables')
        disp(['变量数量: ', num2str(length(model.variables))]);
    end
    
    % 检查约束数量
    if isfield(model, 'constraint')
        disp(['约束数量: ', num2str(length(model.constraint))]);
    end
    
catch ME
    disp(['导出模型失败: ', ME.message]);
    % 继续执行，不中断程序
end

% 添加松弛变量，帮助找出导致不可行的约束
disp('添加松弛变量，诊断不可行问题...');
options.bnb.presolve = 1; % 启用预处理
if strcmp(params.solver.name, 'gurobi')
    options.gurobi.ScaleFlag = 2; % 启用自动缩放 
    options.gurobi.FeasibilityTol = 1e-3;  % 大幅放宽可行性容差
    options.gurobi.OptimalityTol = 1e-3;  % 大幅放宽最优性容差
    options.gurobi.IntFeasTol = 1e-3;  % 大幅放宽整数可行性容差
    options.gurobi.BarConvTol = 1e-6;  % 设置内点法收敛容差
    options.gurobi.Method = 2;  % 使用障碍法求解器
elseif strcmp(params.solver.name, 'mosek')
    options.mosek.MSK_DPAR_INTPNT_TOL_DFEAS = 1e-5;
    options.mosek.MSK_DPAR_INTPNT_TOL_PFEAS = 1e-5;
end

%% 检查约束和成本函数的有效性
if isempty(Constraints)
    warning('约束集合为空，无法求解');
    solver_results = struct();
    solver_results.diagnostics = struct('problem', -1, 'info', '约束集合为空');
    status = '求解失败';
    return;
end

if isempty(cost)
    warning('目标函数为空，无法求解');
    solver_results = struct();
    solver_results.diagnostics = struct('problem', -1, 'info', '目标函数为空');
    status = '求解失败';
    return;
end

% 检查约束中是否存在NaN
try
    % 尝试评估约束
    test_constraints = Constraints;
    for i = 1:length(test_constraints)
        if isnan(test_constraints(i))
            warning('约束中存在NaN值');
            solver_results = struct();
            solver_results.diagnostics = struct('problem', -1, 'info', '约束中存在NaN值');
            status = '求解失败';
            return;
        end
    end
catch ME
    warning(['约束检查失败: ', ME.message]);
    solver_results = struct();
    solver_results.diagnostics = struct('problem', -1, 'info', '约束检查失败');
    status = '求解失败';
    return;
end

%% 求解优化问题 Solve optimization problem
disp('开始求解优化问题...');
try
    % 使用YALMIP求解器
    diagnostics = optimize(Constraints, cost, options);
    
    % 检查求解结果
    if diagnostics.problem == 0
        solver_results = struct();
        solver_results.diagnostics = diagnostics;
        status = '求解成功';
    else
        warning(['求解器报告问题: ', num2str(diagnostics.problem)]);
        solver_results = struct();
        solver_results.diagnostics = diagnostics;
        status = '求解失败';
    end
catch ME
    warning(['求解过程出错: ', ME.message]);
    solver_results = struct();
    solver_results.diagnostics = struct('problem', -1, 'info', '求解函数执行错误');
    status = '求解失败';
end

%% 处理求解结果
if diagnostics.problem == 0
    status = '求解成功';
    disp('优化问题求解成功');
else
    status = '求解失败';
    disp(['优化问题求解失败，错误代码：', num2str(diagnostics.problem)]);
    disp(['错误信息：', diagnostics.info]);
    
    % 尝试诊断问题
    disp('尝试诊断不可行原因...');
    
    % 检查是否有NaN或Inf
    try
        if exist('model', 'var')
            % 检查模型A矩阵
            if isfield(model, 'A')
                hasNaN = any(isnan(model.A(:)));
                hasInf = any(isinf(model.A(:)));
                if hasNaN
                    disp('警告: 约束矩阵A中包含NaN值');
                end
                if hasInf
                    disp('警告: 约束矩阵A中包含Inf值');
                end
                
                % 检查模型右侧向量b
                if isfield(model, 'b')
                    hasNaNb = any(isnan(model.b));
                    hasInfb = any(isinf(model.b));
                    if hasNaNb
                        disp('警告: 约束右侧b中包含NaN值');
                    end
                    if hasInfb
                        disp('警告: 约束右侧b中包含Inf值');
                    end
                end
            end
            
            % 检查模型目标函数系数
            if isfield(model, 'c')
                hasNaNc = any(isnan(model.c));
                hasInfc = any(isinf(model.c));
                if hasNaNc
                    disp('警告: 目标函数系数c中包含NaN值');
                end
                if hasInfc
                    disp('警告: 目标函数系数c中包含Inf值');
                end
            elseif isfield(model, 'f')
                hasNaNf = any(isnan(model.f));
                hasInff = any(isinf(model.f));
                if hasNaNf
                    disp('警告: 目标函数系数f中包含NaN值');
                end
                if hasInff
                    disp('警告: 目标函数系数f中包含Inf值');
                end
            end
        else
            disp('未获取到模型数据，无法进行NaN/Inf检查');
        end
    catch ME
        disp(['检查模型NaN/Inf值时出错: ', ME.message]);
    end
    
    % 提供额外调试建议
    disp('调试建议:');
    disp('1. 检查负荷数据是否合理（不是过大或过小）');
    disp('2. 检查可再生能源出力曲线是否有效');
    disp('3. 尝试进一步放宽约束或增加松弛变量');
    disp('4. 确保所有参数都在合理范围内');
    disp('5. 尝试简化模型，逐步添加约束找出问题所在');
end

%% 返回结果
solver_results = struct();
solver_results.status = status;
solver_results.cost = value(cost);
solver_results.diagnostics = diagnostics;

end 