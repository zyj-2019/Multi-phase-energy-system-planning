function params = parameters()
% 输出参数：
%   params: 包含所有系统参数的结构体

%% 基本设置
params.plot_flag = 1;           % 是否绘制图表
params.save_plot = 0;           % 是否保存图表
params.stop_gap = 1E-4;         % 优化停止条件
params.solve_time = 1E20;       % 最大求解时间


% 预先初始化输入参数结构体
params.input = struct();
params.input.file = 'output-avg.xlsx';  % 输入数据文件
params.input.x = 1;  % 开始天数
params.input.n = 6;  % 优化天数
params.input.annual_factor = 365/params.input.n; % 年转换因子，从6天的数据转化成一年的数据

%% 多阶段规划的时间序列数据
% 各阶段可再生能源潜力增长率
params.input.renewable_growth_rate = [1.0, 1.0, 1.0, 1.0, 1.0];
% 各阶段负荷增长率
params.input.load_growth_rate = ones(1, 5);  % 初始化为1，表示所有阶段负荷保持不变


%% 经济参数 - 在最前面定义，以便后续使用
params.economic = struct();
params.economic.USD2CNY = 7.2;                                  % 美元兑人民币汇率
params.economic.annual_CO2_price_growth_rate = 0.05;            % 碳价年增长率 5%
params.economic.annual_grid_price_growth_rate = 0.02;           % 电价年增长率 2%
params.economic.base_CO2_price = 100;                           % 基准碳价 $/tCO2
params.economic.base_grid_price_factor = 1.0;                   % 基准电价因子
params.economic.CO2_cost = params.economic.base_CO2_price;      % 基准碳价 $/tCO2
params.economic.price_gas = 0.256;                              % 天然气价格, $/m^3
params.economic.grid_price = 0.2*1000/params.economic.USD2CNY;  % 电网售出价格 $/MWh
params.economic.grid_limit = 1000;                              % 购电上限，MW
params.economic.I = 0.1;                                        % 折现率

%% 技术参数（提前初始化，以便计算阶段划分）
params.technical = struct();

% CCGT参数
params.technical.CCGT = struct(...
    'P_max', 48, ...            % 额定功率，MW
    'eta', 0.569, ...           % 效率
    'eta_h', 0.3, ...           % 热效率，假设为30%
    'min_load', 0.2, ...        % 最小负荷率 (占额定功率比例)
    'ramp_rate', 0.05, ...      % 爬坡速率(占额定功率比例/min)
    'max_on', 1, ...            % 最大开机时间/天
    'max_off', 1, ...           % 最大关机时间/天
    'year', 30, ...             % 使用年限
    'n_exist', 0, ...           % 是否存在
    'retire_in_stage', []);     % 需要退役的阶段，将在多阶段规划中计算

% PV参数
params.technical.PV = struct(...
    'P_max', 5000, ...          % 上限功率，MW
    'ramp_rate', 0.1, ...       % 爬坡速率(占额定功率比例/min)
    'year', 25, ...             % 使用年限
    'instal_exist', 0, ...      % 是否存在
    'retire_in_stage', []);     % 需要退役的阶段，将在多阶段规划中计算

% WT参数
params.technical.WT = struct(...
    'P_max', 5000, ...          % 上限功率，MW
    'ramp_rate', 0.1, ...       % 爬坡速率(占额定功率比例/min)
    'year', 20, ...             % 使用年限
    'instal_exist', 0, ...      % 是否存在
    'retire_in_stage', []);     % 需要退役的阶段，将在多阶段规划中计算

% EBg参数
params.technical.EBg = struct(...
    'Q_max', 10, ...            % 额定功率，MW
    'eta', 0.8, ...             % 效率
    'min_load', 0.3, ...        % 最小负荷率 (占额定功率比例)
    'ramp_rate', 0.05, ...      % 爬坡速率(占额定功率比例/min)
    'year', 20, ...             % 使用年限
    'n_exist', 0, ...           % 是否存在
    'retire_in_stage', []);     % 需要退役的阶段，将在多阶段规划中计算

% HPg参数
params.technical.HPg = struct(...
    'Q_max', 4, ...             % 额定功率，MW
    'COP', 1.3, ...             % COP
    'min_load', 0.15, ...       % 最小负荷率 (占额定功率比例)
    'ramp_rate', 0.1, ...       % 爬坡速率(占额定功率比例/min)
    'year', 20, ...             % 使用年限
    'n_exist', 0, ...           % 是否存在
    'retire_in_stage', []);     % 需要退役的阶段，将在多阶段规划中计算

% EBe参数
params.technical.EBe = struct(...
    'Q_max', 5, ...             % 额定功率，MW
    'eta', 0.9, ...             % 效率
    'min_load', 0.2, ...        % 最小负荷率 (占额定功率比例)
    'ramp_rate', 0.05, ...      % 爬坡速率(占额定功率比例/min)
    'year', 20, ...             % 使用年限
    'n_exist', 0, ...           % 是否存在
    'retire_in_stage', []);     % 需要退役的阶段，将在多阶段规划中计算

% HPe参数
params.technical.HPe = struct(...
    'Q_max', 10, ...            % 额定功率，MW
    'eta', 3, ...               % 效率
    'min_load', 0.1, ...        % 最小负荷率 (占额定功率比例)
    'ramp_rate', 0.1, ...       % 爬坡速率(占额定功率比例/min)
    'year', 20, ...             % 使用年限
    'n_exist', 0, ...           % 是否存在
    'retire_in_stage', []);     % 需要退役的阶段，将在多阶段规划中计算

% ESS参数
params.technical.ESS = struct(...
    'P_max', 10000, ...           % 最大功率 (MW)
    'eta_char', 0.92, ...       % 充电效率
    'eta_disc', 0.92, ...       % 放电效率
    'loss', 0, ...              % 损失率
    'str_max', 0.25, ...        % 储能倍率，最少需要0.25个小时充满能量，决定运行功率上限
    'str_min', 100, ...         % 储能倍率，最多需要100个小时充满能量，决定运行功率下限
    'cap_min_ratio', 0, ...     % SOC下限比例
    'cap_max_ratio', 1.0, ...   % SOC上限比例
    'cap_max', 1E5, ...         % 规划容量上限 MW
    'cap_min', 0, ...           % 规划容量下限 MW
    'year', 15, ...             % 使用年限
    'cap_exist', 0, ...         % 已有容量 MWh
    'retire_in_stage', []);     % 需要退役的阶段，将在多阶段规划中计算

% TES参数
params.technical.TES = struct(...
    'P_max', 10000, ...           % 最大功率 (MW)
    'eta_char', 0.85, ...       % 充电效率
    'eta_disc', 0.85, ...       % 放电效率
    'loss', 0.001, ...          % 损失率
    'str_max', 5, ...           % 最大存储率，决定运行功率上限
    'str_min', 100, ...         % 最小存储率，决定运行功率下限
    'cap_min_ratio', 0, ...     % SOT下限比例
    'cap_max_ratio', 1.0, ...   % SOT上限比例
    'cap_max', 1E4, ...         % 规划容量上限 MW
    'cap_min', 0, ...           % 规划容量下限 MW
    'year', 20, ...             % 使用年限
    'cap_exist', 0, ...         % 已有容量 MWh
    'retire_in_stage', []);     % 需要退役的阶段，将在多阶段规划中计算



%% 多阶段规划参数设置
params.multistage = struct();

% 规划期限设置
start_year = 2026;  % 第一批设备投产年份
end_year = 2030;    % 规划终止年份
planning_horizon = end_year - start_year + 1;  % 规划期限总年数

% 收集所有设备的寿命
all_lifetimes = [
    params.technical.CCGT.year;  % 30年
    params.technical.PV.year;    % 25年
    params.technical.WT.year;    % 20年
    params.technical.EBg.year;   % 20年
    params.technical.HPg.year;   % 20年
    params.technical.EBe.year;   % 20年
    params.technical.HPe.year;   % 20年
    params.technical.ESS.year;   % 15年
    params.technical.TES.year;   % 20年
];

% 找出唯一的寿命值并按升序排列
unique_lifetimes = sort(unique(all_lifetimes));

% 计算每个设备类型的更新年份
all_boundaries = [start_year];  % 初始包含起始年

% 对每种设备寿命，计算规划期内的所有更新年份
for i = 1:length(unique_lifetimes)
    lifetime = unique_lifetimes(i);
    current_year = start_year + lifetime;  % 第一次更新年份
    
    % 只要仍在规划期内，就继续添加更新年份
    while current_year <= end_year
        all_boundaries = [all_boundaries, current_year];
        current_year = current_year + lifetime;  % 下一次更新年份
    end
end

% 添加结束年份，如果不存在
if all_boundaries(end) ~= end_year
    all_boundaries = [all_boundaries, end_year];
end

% 去除重复项并排序
stage_boundaries = sort(unique(all_boundaries));

% 计算规划阶段数量
params.multistage.num_stages = length(stage_boundaries) - 1;
num_stages = params.multistage.num_stages;

% 创建阶段年份数组
params.multistage.stage_start_years = stage_boundaries(1:end-1);
params.multistage.stage_end_years = stage_boundaries(2:end) - 1;

% 确保最后一个阶段的结束年份正确
if params.multistage.stage_end_years(end) < end_year
    params.multistage.stage_end_years(end) = end_year;
end

% 计算各阶段年数
params.multistage.years_per_stage = params.multistage.stage_end_years - params.multistage.stage_start_years + 1;

% 记录阶段时间信息，方便查看
params.multistage.stage_periods = cell(num_stages, 1);
for s = 1:num_stages
    params.multistage.stage_periods{s} = sprintf('%d-%d', params.multistage.stage_start_years(s), params.multistage.stage_end_years(s));
end

params.multistage.total_years = sum(params.multistage.years_per_stage); % 总规划年限

% 计算各阶段的碳价和电价因子（基于年增长率）
params.multistage.CO2_price = zeros(1, num_stages);
params.multistage.grid_price_factor = zeros(1, num_stages);

for s = 1:num_stages
    % 计算该阶段开始年份距离起始年的年数
    years_from_start = params.multistage.stage_start_years(s) - start_year;
    
    % 根据年增长率计算该阶段的碳价和电价因子
    params.multistage.CO2_price(s) = params.economic.base_CO2_price * (1 + params.economic.annual_CO2_price_growth_rate)^years_from_start;
    params.multistage.grid_price_factor(s) = params.economic.base_grid_price_factor * (1 + params.economic.annual_grid_price_growth_rate)^years_from_start;
end

% 输出各阶段的碳价和电价因子，用于调试
disp('各阶段价格计算结果:');
for s = 1:num_stages
    disp(['阶段 ', num2str(s), ' (', params.multistage.stage_periods{s}, '): 碳价 = ', num2str(params.multistage.CO2_price(s), '%.2f'), ' $/tCO2, 电价因子 = ', num2str(params.multistage.grid_price_factor(s), '%.2f')]);
end


%% 跟踪每个阶段投资的设备在哪个阶段需要退役
% 这是一个矩阵，行表示投资阶段，列表示退役阶段
params.multistage.retirement_matrix = struct();

% 计算每种设备的退役矩阵
% 对于每种设备，计算在阶段i投资的设备将在哪个阶段j退役
for device_type = {'CCGT', 'PV', 'WT', 'EBg', 'HPg', 'EBe', 'HPe', 'ESS', 'TES'}
    device = device_type{1};
    lifetime = params.technical.(device).year;
    
    % 初始化退役矩阵为零矩阵
    retire_matrix = zeros(num_stages, num_stages);
    
    % 计算每个阶段投资的设备何时退役
    for invest_stage = 1:num_stages
        invest_year = params.multistage.stage_start_years(invest_stage);
        retire_year = invest_year + lifetime;
        
        % 找出退役年份对应的阶段
        for retire_stage = invest_stage+1:num_stages
            if retire_year >= params.multistage.stage_start_years(retire_stage) && ...
               retire_year <= params.multistage.stage_end_years(retire_stage)
                retire_matrix(invest_stage, retire_stage) = 1;
                break;
            end
        end
    end
    
    % 存储该设备类型的退役矩阵
    params.multistage.retirement_matrix.(device) = retire_matrix;
end

% 重新计算每种设备的retire_in_stage，使其与retirement_matrix保持一致
% 清空之前计算的结果
params.technical.CCGT.retire_in_stage = [];
params.technical.PV.retire_in_stage = [];
params.technical.WT.retire_in_stage = [];
params.technical.EBg.retire_in_stage = [];
params.technical.HPg.retire_in_stage = [];
params.technical.EBe.retire_in_stage = [];
params.technical.HPe.retire_in_stage = [];
params.technical.ESS.retire_in_stage = [];
params.technical.TES.retire_in_stage = [];

% 基于退役矩阵来设置retire_in_stage，包含所有可能的退役阶段
for device_type = {'CCGT', 'PV', 'WT', 'EBg', 'HPg', 'EBe', 'HPe', 'ESS', 'TES'}
    device = device_type{1};
    retire_matrix = params.multistage.retirement_matrix.(device);
    
    % 收集所有退役阶段
    all_retire_stages = [];
    for invest_stage = 1:num_stages
        retire_stages = find(retire_matrix(invest_stage, :));
        all_retire_stages = [all_retire_stages, retire_stages];
    end
    
    % 去重并排序
    params.technical.(device).retire_in_stage = sort(unique(all_retire_stages));
end

% 输出各设备的退役阶段号和对应年份，用于调试
disp('设备退役阶段计算结果:');
if ~isempty(params.technical.CCGT.retire_in_stage)
    retire_years_CCGT = params.multistage.stage_start_years(params.technical.CCGT.retire_in_stage);
    disp(['CCGT(30年) 在阶段 ', mat2str(params.technical.CCGT.retire_in_stage), ' 退役，对应年份: ', mat2str(retire_years_CCGT)]);
else
    disp('CCGT(30年) 在规划期内不需要退役');
end

if ~isempty(params.technical.PV.retire_in_stage)
    retire_years_PV = params.multistage.stage_start_years(params.technical.PV.retire_in_stage);
    disp(['PV(25年) 在阶段 ', mat2str(params.technical.PV.retire_in_stage), ' 退役，对应年份: ', mat2str(retire_years_PV)]);
else
    disp('PV(25年) 在规划期内不需要退役');
end

if ~isempty(params.technical.WT.retire_in_stage)
    retire_years_WT = params.multistage.stage_start_years(params.technical.WT.retire_in_stage);
    disp(['WT(20年) 在阶段 ', mat2str(params.technical.WT.retire_in_stage), ' 退役，对应年份: ', mat2str(retire_years_WT)]);
else
    disp('WT(20年) 在规划期内不需要退役');
end

if ~isempty(params.technical.EBg.retire_in_stage)
    retire_years_EBg = params.multistage.stage_start_years(params.technical.EBg.retire_in_stage);
    disp(['EBg(20年) 在阶段 ', mat2str(params.technical.EBg.retire_in_stage), ' 退役，对应年份: ', mat2str(retire_years_EBg)]);
else
    disp('EBg(20年) 在规划期内不需要退役');
end

if ~isempty(params.technical.HPg.retire_in_stage)
    retire_years_HPg = params.multistage.stage_start_years(params.technical.HPg.retire_in_stage);
    disp(['HPg(20年) 在阶段 ', mat2str(params.technical.HPg.retire_in_stage), ' 退役，对应年份: ', mat2str(retire_years_HPg)]);
else
    disp('HPg(20年) 在规划期内不需要退役');
end

if ~isempty(params.technical.EBe.retire_in_stage)
    retire_years_EBe = params.multistage.stage_start_years(params.technical.EBe.retire_in_stage);
    disp(['EBe(20年) 在阶段 ', mat2str(params.technical.EBe.retire_in_stage), ' 退役，对应年份: ', mat2str(retire_years_EBe)]);
else
    disp('EBe(20年) 在规划期内不需要退役');
end

if ~isempty(params.technical.HPe.retire_in_stage)
    retire_years_HPe = params.multistage.stage_start_years(params.technical.HPe.retire_in_stage);
    disp(['HPe(20年) 在阶段 ', mat2str(params.technical.HPe.retire_in_stage), ' 退役，对应年份: ', mat2str(retire_years_HPe)]);
else
    disp('HPe(20年) 在规划期内不需要退役');
end

if ~isempty(params.technical.ESS.retire_in_stage)
    retire_years_ESS = params.multistage.stage_start_years(params.technical.ESS.retire_in_stage);
    disp(['ESS(15年) 在阶段 ', mat2str(params.technical.ESS.retire_in_stage), ' 退役，对应年份: ', mat2str(retire_years_ESS)]);
else
    disp('ESS(15年) 在规划期内不需要退役');
end

if ~isempty(params.technical.TES.retire_in_stage)
    retire_years_TES = params.multistage.stage_start_years(params.technical.TES.retire_in_stage);
    disp(['TES(20年) 在阶段 ', mat2str(params.technical.TES.retire_in_stage), ' 退役，对应年份: ', mat2str(retire_years_TES)]);
else
    disp('TES(20年) 在规划期内不需要退役');
end



% 多阶段规划的时间序列数据
% 我们假设所有阶段使用相同的典型日数据，但可以针对不同阶段设置负荷增长率
% 如果输入的负荷增长率数组长度不足，则扩展它
% 确保负荷增长率数组长度与阶段数一致
if length(params.input.load_growth_rate) ~= num_stages
    params.input.load_growth_rate = ones(1, num_stages);  % 重新设置为正确长度
end

% 展示负荷增长率计算结果
disp(['各阶段负荷增长率(保持不变): ', mat2str(params.input.load_growth_rate, 3)]);

% 如果输入的可再生能源增长率数组长度不足，则扩展它
if length(params.input.renewable_growth_rate) < num_stages
    original_length = length(params.input.renewable_growth_rate);
    % 扩展可再生能源增长率数组，使用最后一个值填充
    last_value = params.input.renewable_growth_rate(end);
    params.input.renewable_growth_rate = [params.input.renewable_growth_rate, ...
                                         last_value * ones(1, num_stages - original_length)];
elseif length(params.input.renewable_growth_rate) > num_stages
    % 如果数组过长，则截断
    params.input.renewable_growth_rate = params.input.renewable_growth_rate(1:num_stages);
end


%% 环境参数
params.environment = struct();
params.environment.CO2_CCGT = 0.3288;   % 燃气机组的碳排放基准值，tCO2/MWh
params.environment.grid_CO2 = 1.0472;   % 电网的碳排放强度，tCO2/MWh
params.environment.gas_CO2 = 0.002;     % 天然气的碳排放强度，tCO2/m^3
params.environment.LHV_gas = 36.0065;   % 天然气的低热值，MJ/m^3


% 价格在多阶段中的变化（根据年增长率计算）
for s = 1:params.multistage.num_stages
    params.economic.stage_CO2_cost(s) = params.multistage.CO2_price(s);
    params.economic.stage_grid_price(s) = params.economic.grid_price * params.multistage.grid_price_factor(s);
    % 可以添加其他价格变化，如天然气价格等
end

% --- 燃气轮机 (CCGT) 经济参数 ---
params.economic.invs_CCGT = 2.97/params.economic.USD2CNY*1E6;       % 单位投资成本，$/MW
params.economic.OM_fix_CCGT = 36.80/params.economic.USD2CNY*1E3;    % 单位固定运维成本，$/MW/year
params.economic.OM_var_CCGT = 14.49/params.economic.USD2CNY;        % 单位可变运维成本，$/MWh
params.economic.price_ramp_CCGT = 0.245;                            % 单位爬坡成本，$/ΔMW
params.economic.price_onoff_CCGT = 0;                               % 单位启停成本，$/次，无法估算，不记录
% 一个典型 CCGT 厂址的启动成本约为 15,000 美元，并假设厂址容量为 600 兆瓦（基于行业平均值）。

% --- 光伏 (PV) 经济参数 ---
params.economic.invs_PV = 4.8312/params.economic.USD2CNY*1E6;       % 单位投资成本，$/MW
params.economic.OM_fix_PV = 27.36/params.economic.USD2CNY*1E3;      % 单位固定运维成本，$/MW/year
params.economic.OM_var_PV = 0/params.economic.USD2CNY;              % 单位可变运维成本，$/MWh
params.economic.price_ramp_PV = 0;                                  % 单位爬坡成本，$/ΔMW
params.economic.price_onoff_PV = 0;                                 % 单位启停成本，0$/次
params.economic.price_PV_cur = 100;                                 % 单位弃光惩罚，$/MWh

% --- 风电 (WT) 经济参数 ---
params.economic.invs_WT = 7.0992/params.economic.USD2CNY*1E6;       % 单位投资成本，$/MW
params.economic.OM_fix_WT = 165.66 /params.economic.USD2CNY*1E3;    % 单位固定运维成本，$/MW/year
params.economic.OM_var_WT = 0/params.economic.USD2CNY;              % 单位可变运维成本，$/MWh
params.economic.price_ramp_WT = 0;                                  % 单位爬坡成本，$/ΔMW
params.economic.price_onoff_WT = 0;                                 % 单位启停成本，0$/次
params.economic.price_WT_cur = 100;                                 % 单位弃风惩罚，$/MWh

% --- 燃气锅炉 (EBg) 经济参数 ---
params.economic.invs_EBg = 1.5/params.economic.USD2CNY*1E6;         % 单位投资成本，$/MW
params.economic.OM_fix_EBg = 10/params.economic.USD2CNY*1E3;        % 单位固定运维成本，$/MW/year
params.economic.OM_var_EBg = 12/params.economic.USD2CNY;            % 单位可变运维成本，$/MWh
params.economic.price_ramp_EBg = 0.5;                               % 单位爬坡成本，$/ΔMW
params.economic.price_onoff_EBg = 0;                                % 单位启停成本，$/次

% --- 燃气吸收式热泵 (HPg) 经济参数 ---
params.economic.invs_HPg = 4.5/params.economic.USD2CNY*1E6;         % 单位投资成本，$/MW
params.economic.OM_fix_HPg = 20/params.economic.USD2CNY*1E3;        % 单位固定运维成本，$/MW/year
params.economic.OM_var_HPg = 15/params.economic.USD2CNY;            % 单位可变运维成本，$/MWh
params.economic.price_ramp_HPg = 0.5;                               % 单位爬坡成本，$/ΔMW
params.economic.price_onoff_HPg = 0;                                % 单位启停成本，$/次

% --- 电锅炉 (EBe) 经济参数 ---
params.economic.invs_EBe = 1.1/params.economic.USD2CNY*1E6;         % 单位投资成本，$/MW
params.economic.OM_fix_EBe = 13.76/params.economic.USD2CNY*1E3;     % 单位固定运维成本，$/MW/year
params.economic.OM_var_EBe = 0/params.economic.USD2CNY;             % 单位可变运维成本，$/MWh
params.economic.price_ramp_EBe = 0.2;                               % 单位爬坡成本，$/ΔMW
params.economic.price_onoff_EBe = 0;                                % 单位启停成本，$/次

% --- 电热泵 (HPe) 经济参数 ---
params.economic.invs_HPe = 3.8/params.economic.USD2CNY*1E6;         % 单位投资成本，$/MW
params.economic.OM_fix_HPe = 17.66/params.economic.USD2CNY*1E3;     % 单位固定运维成本，$/MW/year
params.economic.OM_var_HPe = 0/params.economic.USD2CNY;             % 单位可变运维成本，$/MWh
params.economic.price_ramp_HPe = 0.2;                               % 单位爬坡成本，$/ΔMW
params.economic.price_onoff_HPe = 0;                                % 单位启停成本，$/次

% --- 能量存储 (ESS - 假设功率型 E1 参数) 经济参数 ---
params.economic.invs_str_E_1 = 5.4432/params.economic.USD2CNY*1E6;   % 单位投资成本，$/MWh 
params.economic.OM_fix_E_1 = 230.4/params.economic.USD2CNY*1E3;      % 单位固定运维成本，$/MWh
params.economic.OM_var_E_1 = 0/params.economic.USD2CNY*1E3;          % 单位变动运维成本，$/MWh
params.economic.price_ESS_change = 0.001;                            % 电池状态惩罚，$/MWh

% --- 热储能 (TES - 假设蒸汽储能 H_s 参数) 经济参数 ---
params.economic.invs_str_H_s = 2/params.economic.USD2CNY*1E6;       % 单位投资成本，$/MWh 
params.economic.OM_fix_H_s = 0.15/params.economic.USD2CNY*1E3;      % 单位固定运维成本，$/MWh
params.economic.OM_var_H_s = 0/params.economic.USD2CNY*1E3;         % 单位变动运维成本，$/MWh
params.economic.price_H_s_change  = 0.002;                          % 热储能状态惩罚，$/MWh


%% 加载时间序列数据
input_file = params.input.file;
x = params.input.x;
n = params.input.n;
USD2CNY = params.economic.USD2CNY;

length_day  = [];
index_day   = 0;
data        = [];
for i = x:1:x+n-1
    sheet_name = ['Day ',num2str(i)];
    try
        current_data = xlsread(input_file, sheet_name, 'A2:M1441');
        if isempty(current_data)
            warning('Sheet %s 为空或无法读取。', sheet_name);
            continue; % 跳过这个空sheet
        end
        length_day  = [length_day, size(current_data, 1)];
        index_day   = [index_day, sum(length_day)];
        data        = [data; current_data];
    catch ME
        warning('无法读取 Sheet %s: %s', sheet_name, ME.message);
        % 可以选择停止执行或跳过此sheet
        % error('无法读取必要的输入数据。');
    end
end

if isempty(data)
    error('未能从 %s 加载任何数据。', input_file);
end

DMD_E           = data(:,1);
P_WT_single     = data(:,3);   % 单位风机出力
P_PV_single     = data(:,4);   % 单位光伏出力
DMD_H           = data(:,2);
t_resolution    = data(:,5);   % 时间分辨率 (分钟)
price_grid_buy  = data(:,13) * 1000 / USD2CNY ; % 电网购电价格，$/MWh

% 为多阶段规划准备不同阶段的负荷和可再生能源时间序列
num_stages = params.multistage.num_stages;
t = length(t_resolution); % 一个代表期的总时间步数

% 为每个阶段创建负荷和可再生能源数据 
for s = 1:num_stages
    % 应用负荷增长率到电热负荷
    params.stage_load.P{s} = DMD_E * params.input.load_growth_rate(s);
    params.stage_load.H{s} = DMD_H * params.input.load_growth_rate(s);
    
    % 应用可再生能源潜力增长率
    params.stage_renewable.PV_potential{s} = P_PV_single * params.input.renewable_growth_rate(s);
    params.stage_renewable.WT_potential{s} = P_WT_single * params.input.renewable_growth_rate(s);
    
    % 电网购电价格（根据阶段价格因子）
    params.stage_economic.grid_buy_price{s} = price_grid_buy * params.multistage.grid_price_factor(s);
end

% 存储基本时间序列数据（兼容现有代码）
params.load.P = DMD_E;
params.load.H = DMD_H;
params.renewable.PV_potential = P_PV_single;
params.renewable.WT_potential = P_WT_single;
params.time.resolution = t_resolution;
params.economic.grid_buy_price = price_grid_buy;

% 数据清理
for i = 1:1:length(t_resolution)
    if DMD_E(i) <= 1E-2, DMD_E(i) = 0; end
    if DMD_H(i) <= 1E-2, DMD_H(i) = 0; end
    if P_PV_single(i) <= 1E-2, P_PV_single(i) = 0; end
    if P_WT_single(i) <= 1E-2, P_WT_single(i) = 0; end
end

% 计算总时间步长
t = length(t_resolution); % n天的总的变时间分辨率数据
params.num_time_steps = t;
params.multistage.time_steps_per_stage = t; % 每个阶段使用相同的时间步数

% 存储天数相关信息
Day = floor(365/n)*ones(n,1);
params.time.Day_weight = Day;
params.time.index_day = index_day;   % 每日在时间序列中的结束索引
params.time.length_day = length_day; % 每日包含的时间步数量

%% 调度周期（主要是CCGT、EBg、HPg、TES的调度周期）
params.schedule = struct();
params.schedule.t_gas = 5;      % 燃气设备调度周期（分钟）
params.schedule.t_H_s = 5;      % 热储能调度周期，分钟
params.schedule.t_grid = 60;    % 电网调度周期，分钟

% CCGT的调度参数
params.schedule.CCGT = struct();
params.schedule.CCGT.max_starts_per_day = 2;    % 每天最大启动次数
params.schedule.CCGT.min_on_time = 30;          % 最小持续运行时间（分钟）
params.schedule.CCGT.min_off_time = 30;         % 最小停机时间（分钟）
params.schedule.CCGT.ramp_relax = 1e-3;         % 爬坡松弛量
% EBg的调度参数
params.schedule.EBg = struct();
params.schedule.EBg.max_starts_per_day = 5;    % 每天最大启动次数
params.schedule.EBg.min_on_time = 30;          % 最小持续运行时间（分钟）
params.schedule.EBg.min_off_time = 30;         % 最小停机时间（分钟）
params.schedule.EBg.ramp_relax = 1e-3;         % 爬坡松弛量
% HPg的调度参数
params.schedule.HPg = struct();
params.schedule.HPg.max_starts_per_day = 5;    % 每天最大启动次数
params.schedule.HPg.min_on_time = 30;          % 最小持续运行时间（分钟）
params.schedule.HPg.min_off_time = 30;         % 最小停机时间（分钟）
params.schedule.HPg.ramp_relax = 1e-3;         % 爬坡松弛量
% TES的调度参数
params.schedule.TES = struct();
params.schedule.TES.max_starts_per_day = 5;    % 每天最大启动次数
params.schedule.TES.min_on_time = 30;          % 最小持续运行时间（分钟）
params.schedule.TES.min_off_time = 30;         % 最小停机时间（分钟）
params.schedule.TES.ramp_relax = 1e-3;         % 爬坡松弛量


%% 计算开关周期相关维度
% 目的：在实际运行中，某些设备（如燃气锅炉、热泵等）不能频繁启停，需要设定最小启停周期（如10分钟、1小时等）来保护设备
% 这些周期可能与数据的时间分辨率不一致，因此需要计算每个开关周期包含的原始时间步数量，适应不同的时间分辨率
% 开关周期
params.schedule.t_onoff_CCGT = 60;  % 燃气轮机开关周期，分钟
params.schedule.t_onoff_EBg = 10;   % 燃气锅炉开关周期，分钟
params.schedule.t_onoff_HPg = 5;    % 燃气吸收式热泵开关周期，分钟
params.schedule.t_onoff_EBe = 1;    % 电锅炉开关周期，分钟
params.schedule.t_onoff_HPe = 1;    % 电热泵开关周期，分钟


% 燃气轮机（CCGT）的开关周期计算
i = 1; % 重置计数器
onoff_CCGT = [];
while i <= t
    time_accum = 0;
    steps_in_period = 0;
    while time_accum < params.schedule.t_onoff_CCGT && i <= t
        time_accum = time_accum + t_resolution(i);
        steps_in_period = steps_in_period + 1;
        i = i + 1;
    end
    onoff_CCGT = [onoff_CCGT, steps_in_period];
end
params.schedule.clm_onoff_CCGT = length(onoff_CCGT); % 开关变量的列数
params.schedule.steps_per_onoff_CCGT = onoff_CCGT; % 每个开关周期包含的原始时间步数

% 燃气锅炉 (EBg) 开关周期计算
onoff_EBg = [];
i = 1;
while i <= t
    time_accum = 0;
    steps_in_period = 0;
    while time_accum < params.schedule.t_onoff_EBg && i <= t
        time_accum = time_accum + t_resolution(i);
        steps_in_period = steps_in_period + 1;
        i = i + 1;
    end
    % 记录该周期包含的原始时间步数量 (可能不足一个完整周期)
    onoff_EBg = [onoff_EBg, steps_in_period]; 
end
params.schedule.clm_onoff_EBg = length(onoff_EBg); % 开关变量的列数
params.schedule.steps_per_onoff_EBg = onoff_EBg; % 每个开关周期包含的原始时间步数

% 燃气吸收式热泵 (HPg) 开关周期计算
i = 1; % 重置计数器
onoff_HPg = [];
while i <= t
    time_accum = 0;
    steps_in_period = 0;
    while time_accum < params.schedule.t_onoff_HPg && i <= t
        time_accum = time_accum + t_resolution(i);
        steps_in_period = steps_in_period + 1;
        i = i + 1;
    end
    onoff_HPg = [onoff_HPg, steps_in_period];
end
params.schedule.clm_onoff_HPg = length(onoff_HPg); % 开关变量的列数
params.schedule.steps_per_onoff_HPg = onoff_HPg; % 每个开关周期包含的原始时间步数

% 电锅炉 (EBe) 开关周期计算
i = 1; % 重置计数器
onoff_EBe = [];
while i <= t
    time_accum = 0;
    steps_in_period = 0;    
    while time_accum < params.schedule.t_onoff_EBe && i <= t
        time_accum = time_accum + t_resolution(i);
        steps_in_period = steps_in_period + 1;
        i = i + 1;
    end
    onoff_EBe = [onoff_EBe, steps_in_period];
end 
params.schedule.clm_onoff_EBe = length(onoff_EBe); % 开关变量的列数
params.schedule.steps_per_onoff_EBe = onoff_EBe; % 每个开关周期包含的原始时间步数

% 电热泵 (HPe) 开关周期计算
i = 1; % 重置计数器
onoff_HPe = [];
while i <= t
    time_accum = 0;
    steps_in_period = 0;
    while time_accum < params.schedule.t_onoff_HPe && i <= t
        time_accum = time_accum + t_resolution(i);
        steps_in_period = steps_in_period + 1;
        i = i + 1;
    end
    onoff_HPe = [onoff_HPe, steps_in_period];
end
params.schedule.clm_onoff_HPe = length(onoff_HPe); % 开关变量的列数
params.schedule.steps_per_onoff_HPe = onoff_HPe; % 每个开关周期包含的原始时间步数


%% 求解器设置
params.solver = struct();
params.solver.name = 'gurobi';  % 求解器名称
params.solver.options = sdpsettings('solver', params.solver.name, 'verbose', 1); % 增加 verbose
% 可以添加更多 Gurobi 选项，例如：
% params.solver.options.gurobi.MIPGap = params.stop_gap;
% params.solver.options.gurobi.TimeLimit = params.solve_time;

end 