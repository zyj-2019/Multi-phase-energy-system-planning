%% Case4
% 修改购电上限：电网购电上限（参考的是50MW，可以多设置几个，看看差别大不大）
% 修改机组台数：机组装机限制
% 不同比例的可再生能源：修改不同比例的可再生能源修改renewable_goal，渗透率约束：取消注释（renewable_goal=0.5时，优化时间非常长）

%%    
yalmip('clear')
clc;
clear all;
tic
% a = 1; % 作图
a = 0; % 不作图
% b = 1; % 保存作图
b = 0; % 不保存作图

result_address = '/Users/zyj/Library/CloudStorage/OneDrive-共享的库-onedrive/mac_研二/项目/油气田项目/论文代码2024.12.16';
% 保存图片的位置
fig_address = '/Users/zyj/Library/CloudStorage/OneDrive-共享的库-onedrive/mac_研二/项目/油气田项目/论文代码2024.12.16';
stop_gap = 1E-4;
solve_time = 1E20;

%% %---输入参数（修改碳价） ---%
% 每度电的CO2排放量，碳减排限额缩减修改此参数 https://www.clpgroup.com/content/dam/clp-group/channels/sustainability/document/sustainability-report/2022/CLP_Climate_Related_Disclosures_Report_2022_tc.pdf.coredownload.pdf
% 2025年
CO2_cost = 100;  % 碳价
CO2 = 0.59; % 一度电产生多少kg的CO2(kgCO2/度电 = tCO2/MWh)

% % % 2030年
%CO2_cost = 172;  % 碳价
%CO2 = 0.426; % tCO2/MWh (0.5810)碳排放限额

% % 2035年
% CO2_cost = 307;  % 碳价
% CO2 = 0.296; % tCO2/MWh (0.5810)碳排放限额

% % 2040年
%CO2_cost = 528;  % 碳价
%CO2 = 0.189; % tCO2/MWh (0.5810)碳排放限额

% % 2045年
% CO2_cost = 860;  % 碳价
% CO2 = 0.107; % tCO2/MWh (0.5810)碳排放限额

% % 2050年
% CO2_cost = 1216;  % 碳价
% CO2 = 0.0437; % tCO2/MWh (0.5810)碳排放限额

% % 2055年
% CO2_cost = 1552;  % 碳价
% CO2 = 0.0118; % tCO2/MWh (0.5810)碳排放限额
 
%2060年
% CO2_cost = 1857;  % 碳价
% CO2 = 0; % tCO2/MWh (0.5810)碳排放限额


input_file      = 'output-avg.xlsx';  % 聚合代码的output文件就是规划的input
 
x               = 1;   % 第x天
n               = 6;   % 一共对n天进行优化
t_gas           = 5;   % 燃机的调度周期
t_E_2           = 15;   % 容量型储电调度周期 % 为什么没有t_E_1=1（因为功率型储能不需要调度周期）
t_H_s           = 5;
t_H_w           = 15;


t_onoff_OCGT    = 60;
t_onoff_CCGT    = 60;
t_onoff_WT      = 5;
t_onoff_EBe     = 5;
t_onoff_EBg     = 10;
t_onoff_HPg     = 5;
t_onoff_HPe     = 5;

% 电网参数
USD2CNY         = 7.2;
grid_price      = 0.2*1000/USD2CNY;     % 卖出价格（假设值，0.36~0.42元/千瓦时）（待确定）0.1562$/MWh
grid_limit      = 0;                  % 电网购电上限（假设值，MW）（总共191MW电负荷，燃机就有96MW装机，限制少了，可再生能源占比就会比较大）
t_grid          = 60;                   % 电网调度周期，单位：分钟

%% 优化目标
renewable_goal  = 0.5;                  % 修改不同比例的可再生能源
CO2_goal        = CO2;                  % CO2目标，碳减排限额缩减修改此参数，tCO2/MWh (0.5810)
grid_CO2        = 0.65;                 % 从电网购电的碳排放强度 tCO2/MWh  2020年文献："Planning multiple energy systems for low-carbon districts with high penetration of renewable energy: An empirical study in China"
gas2coal        = 1.885E-3;             % t/m^3   http://www.tanpaifang.com/tanjiliang/2022/0725/88926.html

%% ***经济参数(装机建设成本)***

% 燃料价格
LHV_gas         = 36.0065;              % 天然气低位热值，8600kCal=36.0065MJ/m^3
% 修改这个天然气价格的目的：并不是燃料成本（燃料成本就是用电开采啊这些的成本）。使用的天然气，本来是可以卖出去的，但是现在我自己使用了，所以总成本中的燃料成本应该算卖出去的价格
% price_gas       = 2.163;              % 天然气价格，$/m^3，数据来源https://cn.investing.com/commodities/natural-gas
price_gas       = 0.256;               % 天然气价格，$/m^3  1.64元/m^3
% price_gas         = 0.456;  % 参数稍微设置的高一点


% 燃机经济参数
invs_OCGT       = 2.48/USD2CNY*1E6;     % $/MW  2.48元/W
invs_CCGT       = 2.97/USD2CNY*1E6;     % $/MW
% invs_OCGT       = 1000000*1E6/USD2CNY;    % $/MW
% invs_CCGT       = 1000000*1E6/USD2CNY;    % $/MW

OM_fix_OCGT     = 35.53/USD2CNY*1E3;    % $/MW
OM_fix_CCGT     = 36.80/USD2CNY*1E3;    % $/MW
OM_var_OCGT     = 33.81/USD2CNY;        % $/MWh
OM_var_CCGT     = 14.49/USD2CNY;        % $/MWh
price_ramp_OCGT = 0.647;                % $/ΔMW
price_ramp_CCGT = 0.245;                % $/ΔMW
% price_onoff_OCGT= 0;                  % $/次
% price_onoff_CCGT= 0;                  % $/次
eta_GT        = 0.4;                  % 燃机的发电效率（简单循环，效率40%左右）

% 燃气吸收式热泵经济性参数
invs_HPg = 4.5/USD2CNY*1E6; % $/MW
OM_fix_HPg = 20/USD2CNY*1E3; % $/MW
OM_var_HPg = 15/USD2CNY; % $/MWh
price_ramp_HPg = 0.5; % $/ΔMW

% 燃气锅炉经济性参数
invs_EBg = 1.5/USD2CNY*1E6; % $/MW
OM_fix_EBg = 10/USD2CNY*1E3; % $/MW
OM_var_EBg = 12/USD2CNY; % $/MWh
price_ramp_EBg = 0.3; % $/ΔMW

% 电热泵经济性参数
invs_HPe = 3.8/USD2CNY*1E6; % $/MW
OM_fix_HPe = 17.66/USD2CNY*1E3; % $/MW
OM_var_HPe = 0/USD2CNY; % $/MWh
price_ramp_HPe = 0.6; % $/ΔMW

% 电锅炉经济性参数
invs_EBe = 1.1/USD2CNY*1E6; % $/MW
OM_fix_EBe = 13.76/USD2CNY*1E3; % $/MW
OM_var_EBe = 0/USD2CNY; % $/MWh
price_ramp_EBe = 0.2; % $/ΔMW

% 风光经济参数 可再生成本
invs_PV         = 4.8312/USD2CNY*1000000;   % $/MW（可修改）4000元/kW
invs_WT         = 7.0992/USD2CNY*1000000;   % $/MW（可修改）5000元/kW

OM_fix_PV       = 27.36/USD2CNY*1000;    
OM_fix_WT       = 165.66 /USD2CNY*1000;   
price_PV_cur    = 100;                % $/MW·h
price_WT_cur    = 100;                % $/MW·h
year_PV = 20;
year_WT = 20;
% price_dev     = 1000;                % 缺电惩罚
% price_resd    = 1;                   % 余电惩罚
price_ramp_PV   = 1;                   % $/ΔMW
price_ramp_WT   = 1;                   % $/ΔMW
% price_onoff_WT= 0;                   % $/次


% 功率型储电经济参数
invs_str_E_1    = 5.4432/USD2CNY*1000000;   % $/MWh
year_str_E_1    = 10;
OM_rate_E_1     = 230.4/USD2CNY*1000;  

% 容量型储电经济参数
invs_str_E_2    = 5.4432/USD2CNY*1000000;    
year_str_E_2    = 10;
OM_rate_E_2     = 230.4/USD2CNY*1000; 

price_ESS_change= 0.001;             % 电池状态变化惩罚

% 储蒸汽经济参数
invs_str_H_s    = 2/USD2CNY*1000000;   % $/MWh (假设值)
year_str_H_s    = 20;                 % 使用年限 (假设值)
OM_rate_H_s     = 0.15/USD2CNY*1000;  % 运营维护成本率 (假设值)
price_H_s_change  = 0.002;              % 状态变化惩罚 (假设值)

% 储热水经济参数
invs_str_H_w    = 0.36/USD2CNY*1000000;   % $/MWh (假设值)
year_str_H_w    = 20;                 % 使用年限 (假设值)
OM_rate_H_w     = 0.12/USD2CNY*1000;  % 运营维护成本率 (假设值)
price_H_w_change  = 0.0015;             % 状态变化惩罚 (假设值)


%% 碳减排目标
coal_CO2        = 2.493;             % tCO2/t 消耗一吨煤产生的CO2   https://www.tzixun.com.cn/11302.html
gas_CO2         = 1.33E-3*coal_CO2;  % t/m^3  消耗一立方米天然气产生的CO2   https://www.tzixun.com.cn/11302.html

%% 负荷需求
season = ['winter_cloud';'winter_sunny';'interm_cloud';'interm_sunny';'summer_cloud';'summer_sunny'];
length_day  = [];
index_day   = 0;
data        = [];
for i = x:1:x+n-1
    length_day  = [length_day,length(xlsread(input_file,['Day ',num2str(i)],'A2:M1441'))];   % 记录每个典型日的数组长度
    index_day   = [index_day,sum(length_day)];                                                  % 记录每一天在总时间序列的位置
    data        = [data;xlsread(input_file,['Day ',num2str(i)],'A2:M1441')];
end
DMD_E           = data(:,1);
P_WT_single     = data(:,3);   % 读取的第3列数据
P_PV_single     = data(:,4);
DMD_H           = data(:,2);   % 读取的第2列数据
t_resolution    = data(:,5);
% 买电价格
price_grid      = data(:,13);
price_grid      = price_grid*1000/USD2CNY;
Day             = floor(365/n)*ones(n,1); 
% Day             = [76;76;61;61;46;45];

% 去除输入数据中较小的数据，避免数值问题
for i = 1:1:length(t_resolution)
    if DMD_E(i) <= 1E-2
        DMD_E(i) = 0;
    end
    if DMD_H(i) <= 1E-2
        DMD_H(i) = 0;
    end
    if P_PV_single(i) <= 1E-2
        P_PV_single(i) = 0;
    end
    if P_WT_single(i) <= 1E-2
        P_WT_single(i) = 0;
    end
end

%% 判断时间分辨率与调度周期的大小关系
t       = length(t_resolution);
% 联合循环燃机(CCGT)调度周期
schedule_CCGT   = [];
i               = 1;
while i <= length(t_resolution)
    time = [];
    while sum(time) < t_gas
        time = [time; t_resolution(i)];
        i = i + 1;
    end
    schedule_CCGT = [schedule_CCGT, [time;zeros(t_gas-length(time),1)]]; % ramp_CCGT_opt的变量数
end
[row_CCGT,clm_CCGT] = size(schedule_CCGT);


% 容量型储电调度周期
schedule_ESS_2   = [];
i               = 1;
while i <= length(t_resolution)
    time = [];
    while sum(time) < t_E_2
        time = [time; t_resolution(i)];
        i = i + 1;
    end
    schedule_ESS_2 = [schedule_ESS_2, [time;zeros(t_E_2-length(time),1)]]; % ramp_CCGT_opt的变量数
end
[row_ESS_2,clm_ESS_2] = size(schedule_ESS_2);

% 储蒸汽调度周期
schedule_H_s   = [];
i               = 1;
while i <= length(t_resolution)
    time = [];
    while sum(time) < t_H_s
        time = [time; t_resolution(i)];
        i = i + 1;
    end
    schedule_H_s = [schedule_H_s, [time; zeros(t_H_s - length(time), 1)]];
end
[row_H_s, clm_H_s] = size(schedule_H_s);

% 储热水调度周期
schedule_H_w   = [];
i               = 1;
while i <= length(t_resolution)
    time = [];
    while sum(time) < t_H_w
        time = [time; t_resolution(i)];
        i = i + 1;
    end
    schedule_H_w = [schedule_H_w, [time; zeros(t_H_w - length(time), 1)]];
end
[row_H_w, clm_H_w] = size(schedule_H_w);


% 单循环燃机(OCGT)开关周期
index_day_onoff_OCGT = 0; % 记录开关机时间序列中每一个典型日的位置
onoff_OCGT  = [];
i           = 1;
while i <= length(t_resolution)
    time = [];
    while sum(time) < t_onoff_OCGT
        time = [time; t_resolution(i)];
        i = i + 1;
    end
    onoff_OCGT = [onoff_OCGT, [time;zeros(t_onoff_OCGT-length(time),1)]]; % on_CCGT_opt, off_CCGT_opt的变量数
    
    if mod(sum(onoff_OCGT(:)),1440) == 0 % 是否到了下一个典型日
        index_day_onoff_OCGT = [index_day_onoff_OCGT,size(onoff_OCGT,2)];
    end
end
[row_onoff_OCGT,clm_onoff_OCGT] = size(onoff_OCGT);
d_onoff_OCGT                    = (sum(onoff_OCGT~=0))'; % 一个开关周期内包含的时段数量

% 联合循环燃机(CCGT)开关周期
index_day_onoff_CCGT = 0; % 记录开关机时间序列中每一个典型日的位置
onoff_CCGT  = [];
i           = 1;
while i <= length(t_resolution)
    time = [];
    while sum(time) < t_onoff_CCGT
        time = [time; t_resolution(i)];
        i = i + 1;
    end
    onoff_CCGT = [onoff_CCGT, [time;zeros(t_onoff_CCGT-length(time),1)]]; % on_CCGT_opt, off_CCGT_opt的变量数
    
    if mod(sum(onoff_CCGT(:)),1440) == 0 % 是否到了下一个典型日
        index_day_onoff_CCGT = [index_day_onoff_CCGT,size(onoff_CCGT,2)];
    end
end
[row_onoff_CCGT,clm_onoff_CCGT] = size(onoff_CCGT);
d_onoff_CCGT                    = (sum(onoff_CCGT~=0))'; % 一个开关周期内包含的时段数量

% 风机开关周期
onoff_WT    = [];
i           = 1;
while i <= length(t_resolution)
    time = [];
    while sum(time) < t_onoff_WT
        time = [time; t_resolution(i)];
        i = i + 1;
    end
    onoff_WT = [onoff_WT, [time;zeros(t_onoff_WT-length(time),1)]]; % on_CCGT_opt, off_CCGT_opt的变量数
end
[row_onoff_WT,clm_onoff_WT] = size(onoff_WT);

% 热泵电(HPe)开关周期
index_day_onoff_HPe = 0;
onoff_HPe  = [];
i           = 1;
while i <= length(t_resolution)
    time = [];
    while sum(time) < t_onoff_HPe
        time = [time; t_resolution(i)];
        i = i + 1;
    end
    onoff_HPe = [onoff_HPe, [time;zeros(t_onoff_HPe-length(time),1)]];
    
    if mod(sum(onoff_HPe(:)),1440) == 0
        index_day_onoff_HPe = [index_day_onoff_HPe,size(onoff_HPe,2)];
    end
end
[row_onoff_HPe,clm_onoff_HPe] = size(onoff_HPe);
d_onoff_HPe                   = (sum(onoff_HPe~=0))';

% 热泵气(HPg)开关周期
index_day_onoff_HPg = 0;
onoff_HPg  = [];
i           = 1;
while i <= length(t_resolution)
    time = [];
    while sum(time) < t_onoff_HPg
        time = [time; t_resolution(i)];
        i = i + 1;
    end
    onoff_HPg = [onoff_HPg, [time;zeros(t_onoff_HPg-length(time),1)]];
    
    if mod(sum(onoff_HPg(:)),1440) == 0
        index_day_onoff_HPg = [index_day_onoff_HPg,size(onoff_HPg,2)];
    end
end
[row_onoff_HPg,clm_onoff_HPg] = size(onoff_HPg);
d_onoff_HPg                   = (sum(onoff_HPg~=0))';

% 电锅炉(EBe)开关周期
index_day_onoff_EBe = 0;
onoff_EBe  = [];
i           = 1;
while i <= length(t_resolution)
    time = [];
    while sum(time) < t_onoff_EBe
        time = [time; t_resolution(i)];
        i = i + 1;
    end
    onoff_EBe = [onoff_EBe, [time;zeros(t_onoff_EBe-length(time),1)]];
    
    if mod(sum(onoff_EBe(:)),1440) == 0
        index_day_onoff_EBe = [index_day_onoff_EBe,size(onoff_EBe,2)];
    end
end
[row_onoff_EBe,clm_onoff_EBe] = size(onoff_EBe);
d_onoff_EBe                   = (sum(onoff_EBe~=0))';

% 气锅炉(EBg)开关周期
index_day_onoff_EBg = 0;
onoff_EBg  = [];
i           = 1;
while i <= length(t_resolution)
    time = [];
    while sum(time) < t_onoff_EBg
        time = [time; t_resolution(i)];
        i = i + 1;
    end
    onoff_EBg = [onoff_EBg, [time;zeros(t_onoff_EBg-length(time),1)]];
    
    if mod(sum(onoff_EBg(:)),1440) == 0
        index_day_onoff_EBg = [index_day_onoff_EBg,size(onoff_EBg,2)];
    end
end
[row_onoff_EBg,clm_onoff_EBg] = size(onoff_EBg);
d_onoff_EBg                   = (sum(onoff_EBg~=0))';


%% 储能系统参数
% 功率型储电
eta_char_E_1    = 0.92;
eta_disc_E_1    = 0.92;
loss_E_1        = 0;
str_max_E_1     = 0.25;     % 储能倍率，最少需要x个小时充满能量
str_min_E_1     = 100;      % 最多需要x个小时充满能量，决定运行功率下限
cap_str_max_E_1 = 1E5;      % 储能容量上限
cap_str_min_E_1 = 0;
% 容量型储电
eta_char_E_2    = 0.9;
eta_disc_E_2    = 0.9;
loss_E_2        = 0;
str_max_E_2     = 2;        % 储能倍率，最少需要x个小时充满能量
str_min_E_2     = 100;      % 最多需要x个小时充满能量，决定运行功率下限
cap_str_max_E_2 = 1E5;      % % 储能容量上限
cap_str_min_E_2 = 0;

% 储蒸汽
eta_char_H_s    = 0.85;
eta_disc_H_s    = 0.85;
loss_H_s        = 0.001;
str_max_H_s     = 5;        % 储能倍率，最少需要x个小时充满能量
str_min_H_s     = 100;
cap_str_max_H_s = 1E4;
cap_str_min_H_s = 0;
% 储热水
eta_char_H_w    = 0.95;
eta_disc_H_w    = 0.95;
loss_H_w        = 0;
str_max_H_w     = 4;        % 储能倍率，最少需要x个小时充满能量
str_min_H_w     = 100;
cap_str_max_H_w = 1E4;
cap_str_min_H_w = 0;

%% 机组参数（单机容量）
% 单循环燃机(OCGT)
P_max_OCGT      = 5.5;
min_OCGT        = 0.3;
P_min_OCGT      = min_OCGT*P_max_OCGT;
ramp_max_OCGT   = P_max_OCGT * 0.1 * t_resolution;
max_on_OCGT     = 2;
max_off_OCGT    = 2;
eta_OCGT        = 0.368;
year_OCGT       = 30;

% 联合循环燃机(CCGT)
P_max_CCGT      = 48;
min_CCGT        = 0.2;
P_min_CCGT      = min_CCGT*P_max_CCGT;
ramp_max_CCGT   = P_max_CCGT * 0.05 * t_resolution;
max_on_CCGT     = 1;
max_off_CCGT    = 1;
eta_CCGT        = 0.569;
year_CCGT       = 30;

% 可再生机组
ramp_max_PV     = 0.1 * t_resolution;      % 10% P_instal_PV
ramp_max_WT     = 0.1 * t_resolution;      % 10% P_instal_WT
P_PV_max        = 1500;
P_WT_max        = 1500;


% 燃气吸收式热泵参数
Q_max_HPg = 4; % 单台燃气吸收式热泵最大功率 (MW)
min_HPg = 0.15; % 最小负荷率
Q_min_HPg = min_HPg * Q_max_HPg;
ramp_max_HPg = Q_max_HPg * 0.1 * t_resolution; % 最大爬坡速率 (MW/时间步长)
COP_HPg = 1.3; % 燃气吸收式热泵效率
year_HPg       = 20;

% 燃气加热炉参数
Q_max_EBg = 10; % 单台燃气加热炉最大功率 (MW)
min_EBg = 0.3; % 最小负荷率
Q_min_EBg = min_EBg * Q_max_EBg;
ramp_max_EBg = Q_max_EBg * 0.05 * t_resolution; % 最大爬坡速率 (MW/时间步长)
eta_EBg = 0.8; % 燃气锅炉效率
year_EBg       = 20;

% 电热泵参数
Q_max_HPe = 10; % 单台电热泵最大功率 (MW)
min_HPe = 0.1; % 最小负荷率
Q_min_HPe = min_HPe * Q_max_HPe;
ramp_max_HPe = Q_max_HPe * 0.1 * t_resolution; % 最大爬坡速率 (MW/时间步长)
COP_HPe = 3; % 电热泵的性能系数
year_HPe       = 20;

% 电锅炉参数
Q_max_EBe = 5; % 单台电加热炉最大功率 (MW)
min_EBe = 0.2; % 最小负荷率
Q_min_EBe = min_EBe * Q_max_EBe;
ramp_max_EBe = Q_max_EBe * 0.05 * t_resolution; % 最大爬坡速率 (MW/时间步长)
eta_EBe = 0.9; % 电锅炉效率
year_EBe       = 20;

% 其它参数
M               = 1E5;
I               = 0.1;
eta_conv        = 0.9;
m               = length(length_day);

% 现有机组
n_OCGT_exist    = 0;
% n_CCGT_exist    = 2; 
% n_HPg_exist     = 3;
% n_EBg_exist     = 36;  % 热负荷的最大值：380WM-12WM=368WM需要由燃气锅炉提供
% 全都更新换代
n_CCGT_exist    = 0; 
n_HPg_exist     = 0;
n_EBg_exist     = 0;  % 热负荷的最大值：380WM-12WM=368WM需要由燃气锅炉提供
n_HPe_exist     = 0;
n_EBe_exist     = 0;

%% %---优化变量 ---%
% 单循环燃机(OCGT)
n_OCGT          = intvar(1,1);  % 装机台数
o_OCGT          = intvar(clm_onoff_OCGT,1); % 每小时运行台数
P_OCGT          = sdpvar(t,1);
ramp_P_OCGT_opt = sdpvar(t,1);
ramp_OCGT_up    = sdpvar(t,1);
ramp_OCGT_dn    = sdpvar(t,1);
on_OCGT         = intvar(clm_onoff_OCGT,1); % 开机台数
off_OCGT        = intvar(clm_onoff_OCGT,1); % 关机台数

% 联合循环燃机(CCGT)
n_CCGT          = intvar(1,1);  % 装机台数
o_CCGT          = intvar(clm_onoff_CCGT,1); % 每小时运行台数
P_CCGT          = sdpvar(t,1);
ramp_P_CCGT_opt = sdpvar(clm_CCGT,1);
ramp_CCGT_up    = sdpvar(t,1);
ramp_CCGT_dn    = sdpvar(t,1);
on_CCGT         = intvar(clm_onoff_CCGT,1); % 开机台数
off_CCGT        = intvar(clm_onoff_CCGT,1); % 关机台数

% 燃气吸收式热泵
n_HPg = intvar(1, 1); % 装机台数
o_HPg = intvar(clm_onoff_HPg, 1); % 每天运行台数
Q_HPg = sdpvar(t, 1); % 每个时间步的发热功率
P_HPg = sdpvar(t, 1); % 输入功率
ramp_P_HPg_opt = sdpvar(clm_CCGT, 1); % 爬坡功率
ramp_HPg_up = sdpvar(t, 1); % 爬坡上升速率
ramp_HPg_dn = sdpvar(t, 1); % 爬坡下降速率
on_HPg = intvar(clm_onoff_HPg, 1); % 开机台数
off_HPg = intvar(clm_onoff_HPg, 1); % 关机台数

% 燃气锅炉
n_EBg = intvar(1, 1); % 装机台数
o_EBg = intvar(clm_onoff_EBg, 1); % 每天运行台数
Q_EBg = sdpvar(t, 1); % 每个时间步的发热功率
P_EBg = sdpvar(t, 1); % 输入功率
ramp_P_EBg_opt = sdpvar(clm_CCGT, 1); % 爬坡功率
ramp_EBg_up = sdpvar(t, 1); % 爬坡上升速率
ramp_EBg_dn = sdpvar(t, 1); % 爬坡下降速率
on_EBg = intvar(clm_onoff_EBg, 1); % 开机台数
off_EBg = intvar(clm_onoff_EBg, 1); % 关机台数

% 电热泵
n_HPe = intvar(1, 1); % 装机台数
o_HPe = intvar(clm_onoff_HPe, 1); % 每天运行台数
Q_HPe = sdpvar(t, 1); % 每个时间步的发热功率
P_HPe = sdpvar(t, 1); % 输入功率
ramp_P_HPe_opt = sdpvar(clm_CCGT, 1); % 爬坡功率
ramp_HPe_up = sdpvar(t, 1); % 爬坡上升速率
ramp_HPe_dn = sdpvar(t, 1); % 爬坡下降速率
on_HPe = intvar(clm_onoff_HPe, 1); % 开机台数
off_HPe = intvar(clm_onoff_HPe, 1); % 关机台数

% 电锅炉
n_EBe = intvar(1, 1); % 装机台数
o_EBe = intvar(clm_onoff_EBe, 1); % 每天运行台数
Q_EBe = sdpvar(t, 1); % 每个时间步的发热功率
P_EBe = sdpvar(t, 1); % 输入功率
ramp_P_EBe_opt = sdpvar(clm_CCGT, 1); % 爬坡功率
ramp_EBe_up = sdpvar(t, 1); % 爬坡上升速率
ramp_EBe_dn = sdpvar(t, 1); % 爬坡下降速率
on_EBe = intvar(clm_onoff_EBe, 1); % 开机台数
off_EBe = intvar(clm_onoff_EBe, 1); % 关机台数

% 光伏
P_PV_instal     = sdpvar(1,1);
P_PV_gen        = sdpvar(t,1);
P_PV_cur        = sdpvar(t,1);
ramp_PV_up      = sdpvar(t,1);
ramp_PV_dn      = sdpvar(t,1);
% 风电
P_WT_instal     = sdpvar(1,1);
P_WT_gen        = sdpvar(t,1);
P_WT_cur        = sdpvar(t,1);
% o_WT          = binvar(clm_onoff_WT,1);      % 风机是否运行
ramp_WT_up      = sdpvar(t,1);
ramp_WT_dn      = sdpvar(t,1);
P_dev_resd      = sdpvar(t,1);  % 卖出的电
P_dev_lack      = sdpvar(t,1);  % 买入的电

% 功率型储电
cap_str_E_1       = sdpvar(1,1);
P_str_char_E_1    = sdpvar(t,1);
P_str_disc_E_1    = sdpvar(t,1);
E_ini_E_1         = sdpvar(1,1);
E_str_E_1         = sdpvar(t+1,1);
P_char_max_opt_1  = sdpvar(t,1);
P_char_min_opt_1  = sdpvar(t,1);
P_disc_max_opt_1  = sdpvar(t,1);
P_disc_min_opt_1  = sdpvar(t,1);
% 容量型储电
cap_str_E_2       = sdpvar(1,1);
P_str_char_E_2    = sdpvar(t,1);
P_str_disc_E_2    = sdpvar(t,1);
P_str_char_E_2_opt= sdpvar(clm_ESS_2,1);
P_str_disc_E_2_opt= sdpvar(clm_ESS_2,1);
E_ini_E_2         = sdpvar(1,1);
E_str_E_2         = sdpvar(t+1,1);
P_char_max_opt_2  = sdpvar(t,1);
P_char_min_opt_2  = sdpvar(t,1);
P_disc_max_opt_2  = sdpvar(t,1);
P_disc_min_opt_2  = sdpvar(t,1);

% 储蒸汽 (H_s) 相关参数
cap_str_H_s       = sdpvar(1,1);
Q_str_char_H_s    = sdpvar(t,1);
Q_str_disc_H_s    = sdpvar(t,1);
Q_str_char_H_s_opt= sdpvar(clm_H_s,1);
Q_str_disc_H_s_opt= sdpvar(clm_H_s,1);
H_ini_H_s         = sdpvar(1,1);
H_str_H_s         = sdpvar(t+1,1);
Q_char_max_H_s    = sdpvar(t,1);
Q_char_min_H_s    = sdpvar(t,1);
Q_disc_max_H_s    = sdpvar(t,1);
Q_disc_min_H_s    = sdpvar(t,1);

% 储热水 (H_w) 相关参数
cap_str_H_w       = sdpvar(1,1);
Q_str_char_H_w    = sdpvar(t,1);
Q_str_disc_H_w    = sdpvar(t,1);
Q_str_char_H_w_opt= sdpvar(clm_H_w,1);
Q_str_disc_H_w_opt= sdpvar(clm_H_w,1);
H_ini_H_w         = sdpvar(1,1);
H_str_H_w         = sdpvar(t+1,1);
Q_char_max_H_w    = sdpvar(t,1);
Q_char_min_H_w    = sdpvar(t,1);
Q_disc_max_H_w    = sdpvar(t,1);
Q_disc_min_H_w    = sdpvar(t,1);

%% %---约束方程 ---%
Constraints     = [];
%% 装机约束
% Constraints = [Constraints, n_SPC >= n_SPC_exist];
% Constraints = [Constraints, n_UPC >= n_UPC_exist];
Constraints = [Constraints, n_OCGT ==0 ];                   % 删去OCGT

Constraints = [Constraints, n_CCGT >= n_CCGT_exist];

% 限制不允许建设新的燃气轮机
%Constraints = [Constraints, n_CCGT == n_CCGT_exist];

Constraints = [Constraints, n_EBe >= n_EBe_exist];
Constraints = [Constraints, n_EBg >= n_EBg_exist];
Constraints = [Constraints, n_HPe >= n_HPe_exist];
Constraints = [Constraints, n_HPg >= n_HPg_exist];


%% 机组运行范围计算
% Constraints = [Constraints, 0 <= o_SPC <= n_SPC];
% Constraints = [Constraints, 0 <= o_UPC <= n_UPC];
Constraints = [Constraints, 0 <= o_OCGT <= n_OCGT]; 
Constraints = [Constraints, 0 <= o_CCGT <= n_CCGT];
Constraints = [Constraints, 0 <= o_EBg <= n_EBg];
Constraints = [Constraints, 0 <= o_EBe <= n_EBe];
Constraints = [Constraints, 0 <= o_HPg <= n_HPg];
Constraints = [Constraints, 0 <= o_HPe <= n_HPe];


% for i = 1:1:n
%     Constraints = [Constraints, o_SPC(i)*P_min_SPC <= P_SPC(index_day(i)+1:index_day(i+1)) <= o_SPC(i)*P_max_SPC];
%     Constraints = [Constraints, o_UPC(i)*P_min_UPC <= P_UPC(index_day(i)+1:index_day(i+1)) <= o_UPC(i)*P_max_UPC];
% end
for j = 1:1:clm_onoff_OCGT
    Constraints = [Constraints, o_OCGT(j)*P_min_OCGT <= P_OCGT(sum(sum(onoff_OCGT(:,1:j-1)~=0))+1:sum(sum(onoff_OCGT(:,1:j)~=0))) <= o_OCGT(j)*P_max_OCGT];
end
for j = 1:1:clm_onoff_CCGT
    Constraints = [Constraints, o_CCGT(j)*P_min_CCGT <= P_CCGT(sum(sum(onoff_CCGT(:,1:j-1)~=0))+1:sum(sum(onoff_CCGT(:,1:j)~=0))) <= o_CCGT(j)*P_max_CCGT];
end

for j = 1:1:clm_onoff_EBg
    Constraints = [Constraints, o_EBg(j)*Q_min_EBg <= Q_EBg(sum(sum(onoff_EBg(:,1:j-1)~=0))+1:sum(sum(onoff_EBg(:,1:j)~=0))) <= o_EBg(j)*Q_max_EBg];
end

for j = 1:1:clm_onoff_EBe
    Constraints = [Constraints, o_EBe(j)*Q_min_EBe <= Q_EBe(sum(sum(onoff_EBe(:,1:j-1)~=0))+1:sum(sum(onoff_EBe(:,1:j)~=0))) <= o_EBe(j)*Q_max_EBe];
end

for j = 1:1:clm_onoff_HPg
    Constraints = [Constraints, o_HPg(j)*Q_min_HPg <= Q_HPg(sum(sum(onoff_HPg(:,1:j-1)~=0))+1:sum(sum(onoff_HPg(:,1:j)~=0))) <= o_HPg(j)*Q_max_HPg];
end

for j = 1:1:clm_onoff_HPe
    Constraints = [Constraints, o_HPe(j)*Q_min_HPe <= Q_HPe(sum(sum(onoff_HPe(:,1:j-1)~=0))+1:sum(sum(onoff_HPe(:,1:j)~=0))) <= o_HPe(j)*Q_max_HPe];
end


%% 启停约束
Constraints = [Constraints, on_OCGT(1) == 0];
Constraints = [Constraints, off_OCGT(1) == 0];
Constraints = [Constraints, on_OCGT >= 0];
Constraints = [Constraints, off_OCGT >= 0];
Constraints = [Constraints, o_OCGT(2:end) == o_OCGT(1:end-1) + on_OCGT(2:end) - off_OCGT(2:end)];
for i = 1:1:n
    Constraints = [Constraints, sum(on_OCGT(index_day_onoff_OCGT(i)+2:index_day_onoff_OCGT(i+1))) <= max_on_OCGT * n_OCGT];
    Constraints = [Constraints, sum(off_OCGT(index_day_onoff_OCGT(i)+2:index_day_onoff_OCGT(i+1))) <= max_off_OCGT * n_OCGT];
end

Constraints = [Constraints, on_CCGT(1) == 0];
Constraints = [Constraints, off_CCGT(1) == 0];
Constraints = [Constraints, on_CCGT >= 0];
Constraints = [Constraints, off_CCGT >= 0];
Constraints = [Constraints, o_CCGT(2:end) == o_CCGT(1:end-1) + on_CCGT(2:end) - off_CCGT(2:end)];
for i = 1:1:n
    Constraints = [Constraints, sum(on_CCGT(index_day_onoff_CCGT(i)+2:index_day_onoff_CCGT(i+1))) <= max_on_CCGT * n_CCGT];
    Constraints = [Constraints, sum(off_CCGT(index_day_onoff_CCGT(i)+2:index_day_onoff_CCGT(i+1))) <= max_off_CCGT * n_CCGT];
end

%% 爬坡约束
%-------------------- 爬坡速率计算 --------------------%
% ramp_SPC    = [P_SPC(2,:) - P_SPC(1,:); P_SPC(2:end,:) - P_SPC(1:end-1,:)];
% ramp_UPC    = [P_UPC(2,:) - P_UPC(1,:); P_UPC(2:end,:) - P_UPC(1:end-1,:)];
ramp_OCGT   = [P_OCGT(2,:) - P_OCGT(1,:); P_OCGT(2:end,:) - P_OCGT(1:end-1,:)];
ramp_CCGT   = [P_CCGT(2,:) - P_CCGT(1,:); P_CCGT(2:end,:) - P_CCGT(1:end-1,:)];
%-------------------- 各典型日之间爬坡约束放松 --------------------%
ramp_relax     = [];
% % o_SPC_scaled    = [];
% % o_UPC_scaled    = [];
for i = 1:1:n
    ramp_relax = [ramp_relax;M;zeros(length_day(i)-1,1)];
    % o_SPC_scaled = [o_SPC_scaled;o_SPC(i)*ones(length_day(i),1)];
    % o_UPC_scaled = [o_UPC_scaled;o_UPC(i)*ones(length_day(i),1)];
end
% %-------------------- 爬坡速率范围 --------------------%
% Constraints     = [Constraints, -ramp_max_SPC.*o_SPC_scaled - ramp_relax <= ramp_SPC <= ramp_max_SPC.*o_SPC_scaled + ramp_relax];
% Constraints     = [Constraints, -ramp_max_UPC.*o_UPC_scaled - ramp_relax <= ramp_UPC <= ramp_max_UPC.*o_UPC_scaled + ramp_relax];

k = 1;
for i = 1:1:clm_onoff_OCGT
    if prod(index_day_onoff_OCGT + 1 - i) == 0 % 判断是否进入下一个典型日
        Constraints     = [Constraints, -ramp_max_OCGT(k)*o_OCGT(i) - P_min_OCGT*off_OCGT(i) - M <= ramp_OCGT(k) <= ramp_max_OCGT(k)*o_OCGT(i) + P_min_OCGT*on_OCGT(i) + M];
    else
        Constraints     = [Constraints, -ramp_max_OCGT(k)*o_OCGT(i) - P_min_OCGT*off_OCGT(i) <= ramp_OCGT(k) <= ramp_max_OCGT(k)*o_OCGT(i) + P_min_OCGT*on_OCGT(i)];
    end
    j = 2;
    k = k + 1;
    while j <= row_onoff_OCGT  &&  onoff_OCGT(j,i) ~= 0
        Constraints     = [Constraints, -ramp_max_OCGT(k)*o_OCGT(i) <= ramp_OCGT(k) <= ramp_max_OCGT(k)*o_OCGT(i)];
        j = j + 1;
        k = k + 1;
    end
end

k = 1;
for i = 1:1:clm_onoff_CCGT
    if prod(index_day_onoff_CCGT + 1 - i) == 0 % 判断是否进入下一个典型日
        Constraints     = [Constraints, -ramp_max_CCGT(k)*o_CCGT(i) - P_min_CCGT*off_CCGT(i) - M <= ramp_CCGT(k) <= ramp_max_CCGT(k)*o_CCGT(i) + P_min_CCGT*on_CCGT(i) + M];
    else
        Constraints     = [Constraints, -ramp_max_CCGT(k)*o_CCGT(i) - P_min_CCGT*off_CCGT(i) <= ramp_CCGT(k) <= ramp_max_CCGT(k)*o_CCGT(i) + P_min_CCGT*on_CCGT(i)];
    end
    j = 2;
    k = k + 1;
    while j <= row_onoff_CCGT  &&  onoff_CCGT(j,i) ~= 0
        Constraints     = [Constraints, -ramp_max_CCGT(k)*o_CCGT(i) <= ramp_CCGT(k) <= ramp_max_CCGT(k)*o_CCGT(i)];
        j = j + 1;
        k = k + 1;
    end
end
%-------------------- 调度周期内爬坡速率不变 --------------------%
% ramp_SPC_1      = [];
% ramp_UPC_1      = [];
% for i = 1:1:clm_SPC
%     xxx = schedule_SPC(:,i);
%     ramp_SPC_1 = [ramp_SPC_1; ramp_P_SPC_opt(i) * xxx(xxx~=0)]; % 剔除schedule矩阵中的0元素
%     xxx = schedule_UPC(:,i);
%     ramp_UPC_1 = [ramp_UPC_1; ramp_P_UPC_opt(i) * xxx(xxx~=0)];
% end
% Constraints     = [Constraints, ramp_SPC_1 - ramp_relax <= ramp_SPC <= ramp_SPC_1 + ramp_relax];
% Constraints     = [Constraints, ramp_UPC_1 - ramp_relax <= ramp_UPC <= ramp_UPC_1 + ramp_relax];

ramp_CCGT_1      = [];
for i = 1:1:clm_CCGT
    xxx = schedule_CCGT(:,i);
    ramp_CCGT_1 = [ramp_CCGT_1; ramp_P_CCGT_opt(i) * xxx(xxx~=0)]; % 剔除schedule矩阵中的0元素
end
on_CCGT_scaled  = [];
off_CCGT_scaled = [];
for i = 1:1:clm_onoff_CCGT
    on_CCGT_scaled  = [on_CCGT_scaled; on_CCGT(i); zeros(sum(sum(onoff_CCGT(:,i)~=0))-1,1)];
    off_CCGT_scaled = [off_CCGT_scaled; off_CCGT(i); zeros(sum(sum(onoff_CCGT(:,i)~=0))-1,1)];
end
Constraints     = [Constraints, ramp_CCGT_1 - off_CCGT_scaled*P_min_CCGT - ramp_relax <= ramp_CCGT <= ramp_CCGT_1 + on_CCGT_scaled*P_min_CCGT + ramp_relax];


%-------------------- 上、下爬坡速率计算 --------------------%
% Constraints         = [Constraints,ramp_SPC_up >= 0];
% Constraints         = [Constraints,ramp_SPC_dn >= 0];
% Constraints         = [Constraints,ramp_SPC_up-ramp_SPC_dn == ramp_SPC];
% 
% Constraints         = [Constraints,ramp_UPC_up >= 0];
% Constraints         = [Constraints,ramp_UPC_dn >= 0];
% Constraints         = [Constraints,ramp_UPC_up-ramp_UPC_dn == ramp_UPC];

Constraints         = [Constraints,ramp_OCGT_up >= 0];
Constraints         = [Constraints,ramp_OCGT_dn >= 0];
Constraints         = [Constraints,ramp_OCGT_up-ramp_OCGT_dn == ramp_OCGT];

Constraints         = [Constraints,ramp_CCGT_up >= 0];
Constraints         = [Constraints,ramp_CCGT_dn >= 0];
Constraints         = [Constraints,ramp_CCGT_up-ramp_CCGT_dn == ramp_CCGT];


%% 可再生约束
%-------------------- 光伏计算 --------------------%
Constraints         = [Constraints, P_PV_instal <= P_PV_max];
P_PV_avail          = P_PV_instal * P_PV_single;
Constraints         = [Constraints, P_PV_avail == P_PV_gen + P_PV_cur];
Constraints         = [Constraints, P_PV_gen >= 0];
Constraints         = [Constraints, P_PV_cur >= 0];
% 爬坡计算
% Constraints         = [Constraints,0 <= ramp_PV_up <= ramp_max_PV*P_PV_instal + ramp_relax];
% Constraints         = [Constraints,0 <= ramp_PV_dn <= ramp_max_PV*P_PV_instal + ramp_relax];
Constraints         = [Constraints, ramp_PV_up >= 0];
Constraints         = [Constraints, ramp_PV_dn >= 0];
Constraints         = [Constraints,ramp_PV_up-ramp_PV_dn == [0;P_PV_gen(2:end)-P_PV_gen(1:end-1)]];
% 装机和发电约束
Constraints         = [Constraints, P_PV_gen <= P_PV_avail];


%-------------------- 风电计算 --------------------%
Constraints         = [Constraints, P_WT_instal <= P_WT_max];
P_WT_avail          = P_WT_instal * P_WT_single;
Constraints         = [Constraints, P_WT_avail == P_WT_gen + P_WT_cur];
Constraints         = [Constraints, P_WT_gen >= 0];
Constraints         = [Constraints, P_WT_cur >= 0];
% o_WT_scaled       = [];
% for i = 1:1:clm_onoff_WT   % 将 o_WT 转化到 P_WT_gen 的时间尺度
%     o_WT_scaled = [o_WT_scaled;ones(sum(onoff_WT(:,i)~=0),1)*o_WT(i,:)];
% end
% Constraints         = [Constraints, 0.05*P_WT_instal - (1-o_WT_scaled)*M <= P_WT_gen <= P_WT_avail + (1-o_WT_scaled)*M];
% Constraints         = [Constraints, -o_WT_scaled*M <= P_WT_gen <= o_WT_scaled*M];
% Constraints         = [Constraints, -o_WT_scaled*M <= P_WT_gen <= o_WT_scaled*M];
% 爬坡计算  出错：573-575 错误使用+-
Constraints         = [Constraints,0 <= ramp_WT_up <= ramp_max_WT*P_WT_instal + ramp_relax];
Constraints         = [Constraints,0 <= ramp_WT_dn <= ramp_max_WT*P_WT_instal + ramp_relax];
Constraints         = [Constraints,ramp_WT_up-ramp_WT_dn == [0;P_WT_gen(2:end)-P_WT_gen(1:end-1)]];
% 装机和发电约束
Constraints         = [Constraints, P_WT_gen <= P_WT_avail];


%% 储能约束
%-------------------- 功率型储能系统计算 --------------------%
% 出力范围计算
P_str_char_max_E_1  = cap_str_E_1 ./ str_max_E_1;
P_str_disc_max_E_1  = cap_str_E_1 ./ str_max_E_1;
P_str_char_min_E_1  = cap_str_E_1 ./ str_min_E_1;
P_str_disc_min_E_1  = cap_str_E_1 ./ str_min_E_1;
% 设计容量限制
Constraints = [Constraints, cap_str_E_1 >= cap_str_min_E_1];
Constraints = [Constraints, cap_str_E_1 <= cap_str_max_E_1];
% 出力范围约束
Constraints = [Constraints, P_char_max_opt_1 == P_str_char_max_E_1*ones(t,1)];
Constraints = [Constraints, P_disc_max_opt_1 == P_str_disc_max_E_1*ones(t,1)];

% 储能计算
Constraints = [Constraints, E_str_E_1(2:end) == (1-loss_E_1/60*t_resolution).*E_str_E_1(1:end-1) + (P_str_char_E_1*eta_char_E_1 - P_str_disc_E_1/eta_disc_E_1)/60.*t_resolution];

% 储能系统约束
Constraints = [Constraints, P_str_char_E_1 >= 0];
Constraints = [Constraints, P_str_disc_E_1 >= 0];
Constraints = [Constraints, 0.2*cap_str_E_1*ones(t+1,1) <= E_str_E_1 <= cap_str_E_1*ones(t+1,1)];

for i = 1:1:n+1
    Constraints = [Constraints, E_ini_E_1 == E_str_E_1(index_day(i)+1)];
end

Constraints = [Constraints, P_char_min_opt_1 <= P_str_char_E_1];
Constraints = [Constraints, P_char_max_opt_1 >= P_str_char_E_1];
Constraints = [Constraints, P_disc_min_opt_1 <= P_str_disc_E_1];
Constraints = [Constraints, P_disc_max_opt_1 >= P_str_disc_E_1];
%-------------------- 容量型储能系统计算 --------------------%
% 出力范围计算
P_str_char_max_E_2  = cap_str_E_2 ./ str_max_E_2;
P_str_disc_max_E_2  = cap_str_E_2 ./ str_max_E_2;
P_str_char_min_E_2  = cap_str_E_2 ./ str_min_E_2;
P_str_disc_min_E_2  = cap_str_E_2 ./ str_min_E_2;
% 设计容量限制
Constraints = [Constraints, cap_str_E_2 >= cap_str_min_E_2];
Constraints = [Constraints, cap_str_E_2 <= cap_str_max_E_2];
% 出力范围约束
Constraints = [Constraints, P_char_max_opt_2 == P_str_char_max_E_2*ones(t,1)];
Constraints = [Constraints, P_disc_max_opt_2 == P_str_disc_max_E_2*ones(t,1)];

% 储能计算
Constraints = [Constraints, E_str_E_2(2:end,:) == (1-loss_E_2/60*t_resolution).*E_str_E_2(1:end-1,:) + (P_str_char_E_2*eta_char_E_2 - P_str_disc_E_2/eta_disc_E_2)/60.*t_resolution];

% 储能系统约束
Constraints = [Constraints, P_str_char_E_2 >= 0];
Constraints = [Constraints, P_str_disc_E_2 >= 0];
Constraints = [Constraints, 0.2*cap_str_E_2*ones(t+1,1) <= E_str_E_2 <= cap_str_E_2*ones(t+1,1)];
% Constraints = [Constraints, P_str_disc_E_2.*P_str_char_E_2 == 0];

for i = 1:1:n+1
    Constraints = [Constraints, E_ini_E_2 == E_str_E_2(index_day(i)+1)];
end
% Constraints = [Constraints, E_str_E_2(index_day(1)+1) == E_str_E_2(index_day(2)+1)];
% Constraints = [Constraints, E_str_E_2(index_day(1)+1) == E_str_E_2(index_day(3)+1)];
% Constraints = [Constraints, E_str_E_2(index_day(1)+1) == E_str_E_2(index_day(4)+1)];
% Constraints = [Constraints, E_str_E_2(index_day(1)+1) == E_str_E_2(index_day(5)+1)];
% Constraints = [Constraints, E_str_E_2(index_day(1)+1) == E_str_E_2(index_day(6)+1)];
% Constraints = [Constraints, E_str_E_2(index_day(1)+1) == E_str_E_2(index_day(7))];

Constraints = [Constraints, P_char_min_opt_2 <= P_str_char_E_2];
Constraints = [Constraints, P_char_max_opt_2 >= P_str_char_E_2];
Constraints = [Constraints, P_disc_min_opt_2 <= P_str_disc_E_2];
Constraints = [Constraints, P_disc_max_opt_2 >= P_str_disc_E_2];

% t_E_2时间内功率不变
P_str_char_E_2_scaled  = [];
P_str_disc_E_2_scaled = [];
for i = 1:1:clm_ESS_2
    P_str_char_E_2_scaled = [P_str_char_E_2_scaled; P_str_char_E_2_opt(i)*ones(sum(sum(schedule_ESS_2(:,i)~=0)),1)];
    P_str_disc_E_2_scaled = [P_str_disc_E_2_scaled; P_str_disc_E_2_opt(i)*ones(sum(sum(schedule_ESS_2(:,i)~=0)),1)];
end
Constraints = [Constraints, P_str_char_E_2_scaled == P_str_char_E_2];
Constraints = [Constraints, P_str_disc_E_2_scaled == P_str_disc_E_2];

%-------------------- 储蒸汽系统计算 --------------------%
% 出力范围计算
Q_str_char_max_H_s  = cap_str_H_s ./ str_max_H_s;
Q_str_disc_max_H_s  = cap_str_H_s ./ str_max_H_s;
Q_str_char_min_H_s  = cap_str_H_s ./ str_min_H_s;
Q_str_disc_min_H_s  = cap_str_H_s ./ str_min_H_s;
% 设计容量限制
Constraints = [Constraints, cap_str_H_s >= cap_str_min_H_s];
Constraints = [Constraints, cap_str_H_s <= cap_str_max_H_s];
% 出力范围约束
Constraints = [Constraints, Q_char_max_H_s == Q_str_char_max_H_s*ones(t,1)];
Constraints = [Constraints, Q_disc_max_H_s == Q_str_disc_max_H_s*ones(t,1)];

% 储蒸汽计算
Constraints = [Constraints, H_str_H_s(2:end,:) == (1-loss_H_s/60*t_resolution).*H_str_H_s(1:end-1,:) + (Q_str_char_H_s*eta_char_H_s - Q_str_disc_H_s/eta_disc_H_s)/60.*t_resolution];

% 储蒸汽系统约束
Constraints = [Constraints, Q_str_char_H_s >= 0];
Constraints = [Constraints, Q_str_disc_H_s >= 0];
Constraints = [Constraints, 0.2*cap_str_H_s*ones(t+1,1) <= H_str_H_s <= cap_str_H_s*ones(t+1,1)];
% Constraints = [Constraints, Q_str_disc_H_s.*Q_str_char_H_s == 0];

for i = 1:1:n+1
    Constraints = [Constraints, H_ini_H_s == H_str_H_s(index_day(i)+1)];
end

Constraints = [Constraints, Q_char_min_H_s <= Q_str_char_H_s];
Constraints = [Constraints, Q_char_max_H_s >= Q_str_char_H_s];
Constraints = [Constraints, Q_disc_min_H_s <= Q_str_disc_H_s];
Constraints = [Constraints, Q_disc_max_H_s >= Q_str_disc_H_s];

% t_H_s时间内功率不变
Q_str_char_H_s_scaled  = [];
Q_str_disc_H_s_scaled = [];
for i = 1:1:clm_H_s
    Q_str_char_H_s_scaled = [Q_str_char_H_s_scaled; Q_str_char_H_s_opt(i)*ones(sum(sum(schedule_H_s(:,i)~=0)),1)];
    Q_str_disc_H_s_scaled = [Q_str_disc_H_s_scaled; Q_str_disc_H_s_opt(i)*ones(sum(sum(schedule_H_s(:,i)~=0)),1)];
end
Constraints = [Constraints, Q_str_char_H_s_scaled == Q_str_char_H_s];
Constraints = [Constraints, Q_str_disc_H_s_scaled == Q_str_disc_H_s];

%-------------------- 容量型储热水系统计算 --------------------%
% 出力范围计算
Q_str_char_max_H_w  = cap_str_H_w ./ str_max_H_w;
Q_str_disc_max_H_w  = cap_str_H_w ./ str_max_H_w;
Q_str_char_min_H_w  = cap_str_H_w ./ str_min_H_w;
Q_str_disc_min_H_w  = cap_str_H_w ./ str_min_H_w;
% 设计容量限制
Constraints = [Constraints, cap_str_H_w >= cap_str_min_H_w];
Constraints = [Constraints, cap_str_H_w <= cap_str_max_H_w];
% 出力范围约束
Constraints = [Constraints, Q_char_max_H_w == Q_str_char_max_H_w*ones(t,1)];
Constraints = [Constraints, Q_disc_max_H_w == Q_str_disc_max_H_w*ones(t,1)];

% 储热水计算
Constraints = [Constraints, H_str_H_w(2:end,:) == (1-loss_H_w/60*t_resolution).*H_str_H_w(1:end-1,:) + (Q_str_char_H_w*eta_char_H_w - Q_str_disc_H_w/eta_disc_H_w)/60.*t_resolution];

% 储热水系统约束
Constraints = [Constraints, Q_str_char_H_w >= 0];
Constraints = [Constraints, Q_str_disc_H_w >= 0];
Constraints = [Constraints, 0.2*cap_str_H_w*ones(t+1,1) <= H_str_H_w <= cap_str_H_w*ones(t+1,1)];
% Constraints = [Constraints, Q_str_disc_H_w.*Q_str_char_H_w == 0];

for i = 1:1:n+1
    Constraints = [Constraints, H_ini_H_w == H_str_H_w(index_day(i)+1)];
end

Constraints = [Constraints, Q_char_min_H_w <= Q_str_char_H_w];
Constraints = [Constraints, Q_char_max_H_w >= Q_str_char_H_w];
Constraints = [Constraints, Q_disc_min_H_w <= Q_str_disc_H_w];
Constraints = [Constraints, Q_disc_max_H_w >= Q_str_disc_H_w];

% t_H_w时间内功率不变
Q_str_char_H_w_scaled  = [];
Q_str_disc_H_w_scaled = [];
for i = 1:1:clm_H_w
    Q_str_char_H_w_scaled = [Q_str_char_H_w_scaled; Q_str_char_H_w_opt(i)*ones(sum(sum(schedule_H_w(:,i)~=0)),1)];
    Q_str_disc_H_w_scaled = [Q_str_disc_H_w_scaled; Q_str_disc_H_w_opt(i)*ones(sum(sum(schedule_H_w(:,i)~=0)),1)];
end
Constraints = [Constraints, Q_str_char_H_w_scaled == Q_str_char_H_w];
Constraints = [Constraints, Q_str_disc_H_w_scaled == Q_str_disc_H_w];



%% 电热泵和电锅炉的热电转化效率
Constraints = [Constraints, Q_HPe == P_HPe * COP_HPe];
Constraints = [Constraints, Q_EBe == P_EBe * eta_EBe];



%% 功率平衡
Constraints = [Constraints, DMD_E + P_dev_resd + P_str_char_E_1 + P_str_char_E_2 + P_EBe + P_HPe == P_OCGT + P_CCGT + P_PV_gen + P_WT_gen + P_str_disc_E_1 + P_str_disc_E_2 + P_dev_lack];
%Constraints = [Constraints, P_dev_resd >= 0];
% 不允许向电网卖电
Constraints = [Constraints, P_dev_resd == 0];
Constraints = [Constraints, P_dev_lack >= 0];
Constraints = [Constraints, P_dev_lack <= grid_limit]; % 购电上限

% Constraints = [Constraints, DMD_H <= Q_HPg + Q_EBg + Q_HPe + Q_EBe];
Constraints = [Constraints, DMD_H + Q_str_char_H_s + Q_str_char_H_w == Q_HPg + Q_EBg + Q_HPe + Q_EBe + Q_str_disc_H_s + Q_str_disc_H_w];

%% 可持续性约束
% 可再生渗透率
E_fossil        = (P_OCGT + P_CCGT).*t_resolution/60;  % P_dev_lack.*t_resolution P_dev_lack.*price_grid
E_renew         = (P_PV_gen + P_WT_gen).*t_resolution/60;
E_PV            = P_PV_avail.*t_resolution/60;
E_WT            = P_WT_avail.*t_resolution/60;
E_PV_cur        = P_PV_cur.*t_resolution/60;
E_WT_cur        = P_WT_cur.*t_resolution/60;
E_fossil_day    = [];
E_renew_day     = [];
E_PV_day        = [];
E_WT_day      = [];
E_PV_cur_day    = [];
E_WT_cur_day  = [];

% 燃料消耗计算（燃气轮机GT+天然气加热炉EBg+燃气吸收式热泵HPg）
gas_cum         = ((P_OCGT/eta_OCGT + P_CCGT/eta_CCGT + Q_EBg/eta_EBg + Q_HPg/COP_HPg).*t_resolution/60) * 3600 / LHV_gas;
E_DMD_E         = DMD_E.*t_resolution/60;
% coal_cum_day    = []; % 每日煤耗
gas_cum_day     = []; % 每日气耗
E_DMD_E_day     = [];

for i = 1:1:n
    E_fossil_day    = [E_fossil_day,sum(E_fossil(index_day(i)+1:index_day(i+1)))];
    E_renew_day     = [E_renew_day,sum(E_renew(index_day(i)+1:index_day(i+1)))];
    E_PV_day        = [E_PV_day,sum(E_PV(index_day(i)+1:index_day(i+1)))];
    E_WT_day      = [E_WT_day,sum(E_WT(index_day(i)+1:index_day(i+1)))];
    E_PV_cur_day    = [E_PV_cur_day,sum(E_PV_cur(index_day(i)+1:index_day(i+1)))];
    E_WT_cur_day  = [E_WT_cur_day,sum(E_WT_cur(index_day(i)+1:index_day(i+1)))];
    % coal_cum_day    = [coal_cum_day,sum(coal_cum(index_day(i)+1:index_day(i+1)))];
    gas_cum_day     = [gas_cum_day,sum(gas_cum(index_day(i)+1:index_day(i+1)))]; % 1×6，6天每天的天然气消耗量
    E_DMD_E_day     = [E_DMD_E_day,sum(E_DMD_E(index_day(i)+1:index_day(i+1)))];
end

% 渗透率约束
% Constraints = [Constraints, E_renew_day*Day >= renewable_goal * (E_fossil_day*Day + E_renew_day*Day)];

%% 碳排放约束
% 年总碳排放量  一年总共的碳排放量=燃烧天然气需要排放的CO2+电网的购电碳排放因子
CO2_total_year = (gas_cum_day * Day) * gas2coal * coal_CO2 + sum(P_dev_lack .* t_resolution) / 60 * grid_CO2 * 360;
% 约束：总的碳排放量应该在限额之内
% Constraints = [Constraints, CO2_total_year / 1E2 <= CO2_goal * (E_DMD_E_day*Day) / 1E2];
% 6天每天的CO2排放量（tCO2/MWh）
CO2_day     = (gas_cum_day*gas2coal*coal_CO2)./E_DMD_E_day;


%% 其他约束（debug使用）：机组装机限制
% Constraints = [Constraints, cap_str_E_1 == 0];
% Constraints = [Constraints, P_dev_lack == 0];
% Constraints = [Constraints, o_CCGT(:,2) == 1];
% Constraints = [Constraints, n_SPC == 0];
% Constraints = [Constraints, n_UPC == 1];
% Constraints = [Constraints, n_OCGT == 0];
% Constraints = [Constraints, n_CCGT == 1];

% 没有电热泵HPe，也没有建设电加热炉EBe
% Constraints = [Constraints, n_HPe == 0];
% Constraints = [Constraints, n_EBe == 0];

% Constraints = [Constraints, cap_str_E_2 == 607.704177884236];	
% Constraints = [Constraints, P_PV_instal == 0];
% Constraints = [Constraints, P_WT_instal == 0];
% Constraints = [Constraints, P_WT_cur == 0];
% Constraints = [Constraints, P_PV_cur == 0];

%% %--- 目标函数 ---%
%% 装机成本
A = I/(1-1/(1+I)^35);
cost_inv_OCGT   = (n_OCGT - n_OCGT_exist) * P_max_OCGT * invs_OCGT * A; % 30年，2025~2060不更新，只有初始投资成本
cost_inv_CCGT   = (n_CCGT - n_CCGT_exist) * P_max_CCGT * invs_CCGT * A *(1-0.03); % 30年，2025~2060不更新
cost_inv_PV     = invs_PV * P_PV_instal * A * ( 1+(1-0.03)^20/(1+I)^20 -0.03/(1+I)^20); % 20年，2025~2045~
cost_inv_WT     = invs_WT * P_WT_instal * A * ( 1+(1-0.03)^20/(1+I)^20 -0.03/(1+I)^20); % 20年，2025~2045~
cost_inv_EBg   = (n_EBg - n_EBg_exist) * Q_max_EBg * invs_EBg * A *( 1-0.03+(1-0.01)^20/(1+I)^20 -0.03/(1+I)^20); % 20年，2025~2045~
cost_inv_EBe   = (n_EBe - n_EBe_exist) * Q_max_EBe * invs_EBe * A *( 1+(1-0.01)^20/(1+I)^20 -0.03/(1+I)^20); % 20年，2025~2045~
cost_inv_HPg   = (n_HPg - n_HPg_exist) * Q_max_HPg * invs_HPg * A *( 1-0.03+(1-0.01)^20/(1+I)^20 -0.03/(1+I)^20); % 20年，2025~2045~
cost_inv_HPe   = (n_HPe - n_HPe_exist) * Q_max_HPe * invs_HPe * A *( 1+(1-0.01)^20/(1+I)^20 -0.03/(1+I)^20); % 20年，2025~2045~
cost_inv_str_E_1= invs_str_E_1 * P_str_char_max_E_1 * A *( 1+(1-0.15)^15/(1+I)^15 -0.03/(1+I)^15 +(1-0.15)^30/(1+I)^30 -0.03/(1+I)^30); % 15年，2025~2040~2055~
cost_inv_str_E_2= invs_str_E_2 * P_str_char_max_E_2 * A *( 1+(1-0.15)^15/(1+I)^15 -0.03/(1+I)^15 +(1-0.15)^30/(1+I)^30 -0.03/(1+I)^30); % 15年，2025~2040~2055~
cost_inv_str_H_s= invs_str_H_s * Q_str_char_max_H_s * A *( 1+(1-0.01)^20/(1+I)^20 -0.03/(1+I)^20); % 20年，2025~2045~
cost_inv_str_H_w= invs_str_H_w * Q_str_char_max_H_w * A *( 1+(1-0.01)^20/(1+I)^20 -0.03/(1+I)^20); % 20年，2025~2045~

% 总装机成本(本来是美元，现在×USD2CNY，单位是元)
cost_inv        = (cost_inv_OCGT + cost_inv_CCGT + cost_inv_str_E_1 + cost_inv_str_E_2 + cost_inv_PV + cost_inv_WT + cost_inv_EBg + cost_inv_EBe + cost_inv_HPg + cost_inv_HPe + cost_inv_str_H_s + cost_inv_str_H_w)*USD2CNY;

%% 燃料成本(单位是元)
cost_gas        = gas_cum_day * Day * price_gas;
cost_fuel       = cost_gas*USD2CNY; % 单位是元

%% 运维成本
% 固定运维成本
cost_OM_OCGT_fix    = n_OCGT*P_max_OCGT*OM_fix_OCGT;
cost_OM_CCGT_fix    = n_CCGT*P_max_CCGT*OM_fix_CCGT;
cost_OM_EBg_fix    = n_EBg*Q_max_EBg*OM_fix_EBg;
cost_OM_EBe_fix    = n_EBe*Q_max_EBe*OM_fix_EBe;
cost_OM_HPg_fix    = n_HPg*Q_max_HPg*OM_fix_HPg;
cost_OM_HPe_fix    = n_HPe*Q_max_HPe*OM_fix_HPe;

cost_OM_ESS_1_fix   = 0;
cost_OM_ESS_2_fix   = 0;

cost_OM_PV_fix      = P_PV_instal * OM_fix_PV;
cost_OM_WT_fix      = P_WT_instal * OM_fix_WT;
% 变动运维成本
cost_OM_OCGT_var    = P_OCGT.*t_resolution/60*OM_var_OCGT;
cost_OM_CCGT_var    = P_CCGT.*t_resolution/60*OM_var_CCGT;
cost_OM_EBg_var     = Q_EBg.*t_resolution/60*OM_var_EBg;
cost_OM_EBe_var     = Q_EBe.*t_resolution/60*OM_var_EBe;
cost_OM_HPg_var     = Q_HPg.*t_resolution/60*OM_var_HPg;
cost_OM_HPe_var     = Q_HPe.*t_resolution/60*OM_var_HPe;
cost_OM_ESS_1_var   = (P_str_char_E_1+P_str_disc_E_1).*t_resolution/60*OM_rate_E_1;
cost_OM_ESS_2_var   = (P_str_char_E_2+P_str_disc_E_2).*t_resolution/60*OM_rate_E_2;
cost_OM_H_s_var   = (Q_str_char_H_s+Q_str_disc_H_s).*t_resolution/60*OM_rate_H_s;
cost_OM_H_w_var   = (Q_str_char_H_w+Q_str_disc_H_w).*t_resolution/60*OM_rate_H_w;


cost_OM_PV_var      = (ramp_PV_up+ramp_PV_dn) / 1E4;
cost_OM_WT_var      = (ramp_WT_up+ramp_WT_dn) / 1E4;

cost_OM_OCGT_var_day    = [];
cost_OM_CCGT_var_day    = [];
cost_OM_EBg_var_day    = [];
cost_OM_EBe_var_day    = [];
cost_OM_HPg_var_day    = [];
cost_OM_HPe_var_day    = [];
cost_OM_ESS_1_var_day   = [];
cost_OM_ESS_2_var_day   = [];
cost_OM_H_s_var_day   = [];
cost_OM_H_w_var_day   = [];
cost_OM_PV_var_day      = [];
cost_OM_WT_var_day      = [];

for i = 1:1:n
    cost_OM_OCGT_var_day    = [cost_OM_OCGT_var_day,sum(cost_OM_OCGT_var(index_day(i)+1:index_day(i+1)))];
    cost_OM_CCGT_var_day    = [cost_OM_CCGT_var_day,sum(cost_OM_CCGT_var(index_day(i)+1:index_day(i+1)))];
    cost_OM_EBg_var_day     = [cost_OM_EBg_var_day,sum(cost_OM_EBg_var(index_day(i)+1:index_day(i+1)))];
    cost_OM_EBe_var_day     = [cost_OM_EBe_var_day,sum(cost_OM_EBe_var(index_day(i)+1:index_day(i+1)))];
    cost_OM_HPg_var_day     = [cost_OM_HPg_var_day,sum(cost_OM_HPg_var(index_day(i)+1:index_day(i+1)))];
    cost_OM_HPe_var_day     = [cost_OM_HPe_var_day,sum(cost_OM_HPe_var(index_day(i)+1:index_day(i+1)))];
    cost_OM_ESS_1_var_day   = [cost_OM_ESS_1_var_day,sum(cost_OM_ESS_1_var(index_day(i)+1:index_day(i+1)))];
    cost_OM_ESS_2_var_day   = [cost_OM_ESS_2_var_day,sum(cost_OM_ESS_2_var(index_day(i)+1:index_day(i+1)))];
    cost_OM_H_s_var_day     = [cost_OM_H_s_var_day,sum(cost_OM_H_s_var(index_day(i)+1:index_day(i+1)))];
    cost_OM_H_w_var_day     = [cost_OM_H_w_var_day,sum(cost_OM_H_w_var(index_day(i)+1:index_day(i+1)))];
    cost_OM_PV_var_day      = [cost_OM_PV_var_day,sum(cost_OM_PV_var(index_day(i)+1:index_day(i+1)))];
    cost_OM_WT_var_day      = [cost_OM_WT_var_day,sum(cost_OM_WT_var(index_day(i)+1:index_day(i+1)))];
end


% 总运维成本
cost_OM = (cost_OM_OCGT_fix + cost_OM_CCGT_fix + cost_OM_ESS_1_fix + cost_OM_ESS_2_fix + cost_OM_PV_fix + cost_OM_WT_fix + cost_OM_EBg_fix + cost_OM_EBe_fix + cost_OM_HPg_fix + cost_OM_HPe_fix + (cost_OM_OCGT_var_day + cost_OM_CCGT_var_day + cost_OM_ESS_1_var_day + cost_OM_ESS_2_var_day + cost_OM_H_s_var_day + cost_OM_H_w_var_day + cost_OM_PV_var_day + cost_OM_WT_var_day + cost_OM_EBg_var_day + cost_OM_EBe_var_day + cost_OM_HPg_var_day + cost_OM_HPe_var_day)*Day)*USD2CNY;

%% 爬坡成本
cost_ramp_OCGT_day      = [];
cost_ramp_CCGT_day      = [];
for i = 1:1:n
    cost_ramp_OCGT_day   = [cost_ramp_OCGT_day,sum(ramp_OCGT_up(index_day(i)+2:index_day(i+1)) + ramp_OCGT_dn(index_day(i)+2:index_day(i+1)))*price_ramp_OCGT]; % 去掉每天第一个爬坡，以免计入典型日之间的功率变化
    cost_ramp_CCGT_day   = [cost_ramp_CCGT_day,sum(ramp_CCGT_up(index_day(i)+2:index_day(i+1)) + ramp_CCGT_dn(index_day(i)+2:index_day(i+1)))*price_ramp_CCGT]; % 去掉每天第一个爬坡，以免计入典型日之间的功率变化
end
cost_ramp       = (cost_ramp_OCGT_day + cost_ramp_CCGT_day)*Day*USD2CNY;

%% 其余成本
% 买电成本
cost_buy = sum( (P_dev_lack .* price_grid) .*t_resolution/60 )*60;  % 每个时间步长的买电量乘以对应的买电价格(错误)
% cost_buy = sum(P_dev_lack)* 0.7933 *1000/USD2CNY; 
% 卖电收益
revenue_sell = sum(P_dev_resd.* t_resolution)* grid_price/60*60;  % 每个时间步长的卖电量乘以固定的卖电价格
% 净成本
cost_net = (cost_buy - revenue_sell)*USD2CNY;

cost_onoff      = sum(sum(on_OCGT + off_OCGT + on_CCGT + off_CCGT))*USD2CNY;
cost_cur        = (E_PV_cur_day*Day*price_PV_cur + E_WT_cur_day*Day*price_WT_cur)*USD2CNY;

%% 碳排放成本

% 各种能源技术单位碳排放
unit_OCGT_CO2   = 1/eta_OCGT/LHV_gas*3600*gas2coal*coal_CO2; 
unit_CCGT_CO2   = 1/eta_CCGT/LHV_gas*3600*gas2coal*coal_CO2; 
% 各种能源技术单位成本
unit_OCGT_cost  = 1/eta_OCGT*3600/LHV_gas*price_gas*USD2CNY; 
unit_CCGT_cost  = 1/eta_CCGT*3600/LHV_gas*price_gas*USD2CNY; 

% 计算燃煤和燃气轮机的发电量6天
% P_SPC_total = P_SPC' * t_resolution; % 未转化成h，还应该除以60，才是发电量MWh;每天的发电量还应该除以6
% P_SPC_day = P_SPC_total/360;
% 
% P_UPC_total = P_UPC' * t_resolution; % 未转化成h，还应该除以60，才是发电量MWh;每天的发电量还应该除以6
% P_UPC_day = P_UPC_total/360;

P_OCGT_total = P_OCGT' * t_resolution; % 未转化成h，还应该除以60，才是发电量MWh;每天的发电量还应该除以6
P_OCGT_day = P_OCGT_total/360;

P_CCGT_total = P_CCGT' * t_resolution; % 未转化成h，还应该除以60，才是发电量MWh;每天的发电量还应该除以6
P_CCGT_day = P_CCGT_total/360;

P_WT_total = P_WT_gen' * t_resolution; % 未转化成h，还应该除以60，才是发电量MWh;每天的发电量还应该除以6

P_PV_total = P_PV_gen' * t_resolution; % 未转化成h，还应该除以60，才是发电量MWh;每天的发电量还应该除以6

% 日均 总碳排放量（不包含购电的）还缺少
total_CO2_day = P_OCGT_day * unit_OCGT_CO2 + P_CCGT_day * unit_CCGT_CO2;

% 年总碳排放量CO2_total_year  年总发电量
cost_CO2 = (CO2_total_year - (P_CCGT_total + P_WT_total + P_PV_total) * CO2_goal) * CO2_cost;  % 单位元


%% 总成本(单位都是元)
cost = cost_inv + cost_fuel + cost_OM + cost_ramp + cost_onoff + cost_cur + cost_net + cost_CO2; 

% 单位为美元的cost（修改单位）
% cost = (cost_inv + cost_fuel + cost_OM + cost_ramp + cost_onoff + cost_cur + cost_net)/USD2CNY; 

%% %--- 优化 ---%
disp('Optimization started')
ops = sdpsettings('solver','gurobi');
% ops = sdpsettings('solver','gurobi','gurobi.ResultFile','MyFile.mps'); 
% ops = sdpsettings('solver','gurobi','gurobi.MIPGap',stop_gap,'gurobi.timelimit',solve_time);
% ops = sdpsettings('solver','gurobi','gurobi.DualReductions',0);
r = optimize(Constraints,cost,ops);
if r.problem ~= 0
	% 计算失败
	disp('error');
	% r.infoo_SPC       = value(o_SPC); 出错，注释掉
% o_UPC       = value(o_UPC);

	yalmiperror(r.problem)
end
disp(['———————— CO2 【',num2str(CO2),'】, 分辨率 【var】 优化结束，用时',num2str(toc),'秒 ————————']);

%% %---输出结果 ---%
%% 数据转化
n_OCGT      = value(n_OCGT);
n_CCGT      = value(n_CCGT);

o_OCGT      = value(o_OCGT);
o_CCGT      = value(o_CCGT);

on_OCGT     = value(on_OCGT);
off_OCGT    = value(off_OCGT);
on_CCGT     = value(on_CCGT);
off_CCGT    = value(off_CCGT);

P_OCGT      = value(P_OCGT);
P_CCGT      = value(P_CCGT);

ramp_P_OCGT_opt = value(ramp_P_OCGT_opt);
ramp_P_CCGT_opt = value(ramp_P_CCGT_opt);

ramp_OCGT   = value(ramp_OCGT);
ramp_CCGT   = value(ramp_CCGT);

P_dev_resd  = value(P_dev_resd);
P_dev_lack  = value(P_dev_lack);

P_PV_gen        = value(P_PV_gen);
P_PV_cur        = value(P_PV_cur);
P_PV_instal     = value(P_PV_instal);

P_WT_gen      = value(P_WT_gen);
P_WT_cur      = value(P_WT_cur);
P_WT_instal   = value(P_WT_instal);
% o_WT          = value(o_WT);

% 电池
P_str_char_E_1      = value(P_str_char_E_1);
P_str_disc_E_1      = value(P_str_disc_E_1);
E_str_E_1           = value(E_str_E_1);
SOC_E_1             = value(E_str_E_1 / cap_str_E_1);

P_str_char_E_2      = value(P_str_char_E_2);
P_str_disc_E_2      = value(P_str_disc_E_2);
E_str_E_2           = value(E_str_E_2);
SOC_E_2             = value(E_str_E_2 / cap_str_E_2);

P_str_char_min_E_1 = value(P_str_char_min_E_1);
P_str_char_max_E_1 = value(P_str_char_max_E_1);
P_str_disc_min_E_1 = value(P_str_disc_min_E_1);
P_str_disc_max_E_1 = value(P_str_disc_max_E_1);

P_str_char_min_E_2 = value(P_str_char_min_E_2);
P_str_char_max_E_2 = value(P_str_char_max_E_2);
P_str_disc_min_E_2 = value(P_str_disc_min_E_2);
P_str_disc_max_E_2 = value(P_str_disc_max_E_2);

cap_str_E_1     = value(cap_str_E_1);
cap_str_E_2     = value(cap_str_E_2);

% 储热
Q_str_char_H_s      = value(Q_str_char_H_s);
Q_str_disc_H_s      = value(Q_str_disc_H_s);
H_str_H_s           = value(H_str_H_s);
SOT_H_s             = value(H_str_H_s / cap_str_H_s);

Q_str_char_H_w      = value(Q_str_char_H_w);
Q_str_disc_H_w      = value(Q_str_disc_H_w);
H_str_H_w           = value(H_str_H_w);
SOT_H_w             = value(H_str_H_w / cap_str_H_w);

Q_str_char_max_H_s = value(Q_str_char_max_H_s);
Q_str_char_min_H_s = value(Q_str_char_min_H_s);
Q_str_disc_max_H_s = value(Q_str_disc_max_H_s);
Q_str_disc_min_H_s = value(Q_str_disc_min_H_s);

Q_str_char_max_H_w = value(Q_str_char_max_H_w);
Q_str_char_min_H_w = value(Q_str_char_min_H_w);
Q_str_disc_max_H_w = value(Q_str_disc_max_H_w);
Q_str_disc_min_H_w = value(Q_str_disc_min_H_w);
cap_str_H_s      = value(cap_str_H_s);
cap_str_H_w      = value(cap_str_H_w);

cost            = value(cost);
sum_P_red       = value(sum(sum(P_dev_resd) + sum(P_dev_lack)));
CO2_day         = round(value(CO2_day),4);

ramp_PV             = P_PV_gen(2:end,:) - P_PV_gen(1:end-1,:);
ramp_WT           = P_WT_gen(2:end,:) - P_WT_gen(1:end-1,:);
E_renew_day         = value(E_renew_day);
E_fossil_day        = value(E_fossil_day);

n_EBe      = value(n_EBe);
n_EBg      = value(n_EBg);
n_HPe      = value(n_HPe);
n_HPg      = value(n_HPg);

CO2_total_year = value(CO2_total_year); 


%% 重要结果输出
% 成本显示：总成本，运维成本，燃料消耗成本，购电成本，碳排放成本
a_result_cost  = value([cost/USD2CNY,cost_inv/USD2CNY,cost_OM/USD2CNY, cost_ramp/USD2CNY, cost_onoff/USD2CNY , cost_cur/USD2CNY ,cost_fuel/USD2CNY,cost_net/USD2CNY,cost_CO2/USD2CNY]); % 单位为美元

% 容量配置情况： 燃机    PV光伏    WT风电  功率型储能  容量型储能   电加热炉 燃气加热炉  电热泵     燃气热泵    储蒸汽    储热水
a_result_cap        = [ n_CCGT*P_max_CCGT, P_PV_instal, P_WT_instal,n_EBe*Q_max_EBe,n_EBg*Q_max_EBg,n_HPe*Q_max_HPe,n_HPg*Q_max_HPg,cap_str_E_1,cap_str_E_2,cap_str_H_s,cap_str_H_w];


% 可再生弃电率（消纳）
a_renewable_curtail     = value((E_PV_cur_day*Day + E_PV_cur_day*Day)/(E_PV_day*Day + E_WT_day*Day));
% 可再生装机占比
a_renewable_ratio_cap   = (P_PV_instal + P_WT_instal)/(n_OCGT*P_max_OCGT + n_CCGT*P_max_CCGT + P_PV_instal + P_WT_instal); % 可再生装机占比
% 可再生发电占比
a_renewable_ratio_gen   = value((E_renew_day*Day)/((E_fossil_day+E_renew_day)*Day)); 
% 技术指标情况：可再生能源利用率、可再生装机占比、可再生发电占比
a_result_Techindex =  [CO2_total_year/360,1-a_renewable_curtail,a_renewable_ratio_cap,a_renewable_ratio_gen];


a_ESS               = value(sum(sum(P_str_char_E_2.*P_str_disc_E_2)));
a_renew = [a_renewable_ratio_gen,a_renewable_ratio_cap,a_renewable_curtail];

E_str_char_E_1_day  = [];
E_str_disc_E_1_day  = [];
E_str_char_E_2_day  = [];
E_str_disc_E_2_day  = [];
for i = 1:1:n
    E_str_char_E_1_day  = [E_str_char_E_1_day,sum(P_str_char_E_1(index_day(i)+1:index_day(i+1)).*t_resolution(index_day(i)+1:index_day(i+1)))/60];
    E_str_disc_E_1_day  = [E_str_disc_E_1_day,sum(P_str_disc_E_1(index_day(i)+1:index_day(i+1)).*t_resolution(index_day(i)+1:index_day(i+1)))/60];
    E_str_char_E_2_day  = [E_str_char_E_2_day,sum(P_str_char_E_2(index_day(i)+1:index_day(i+1)).*t_resolution(index_day(i)+1:index_day(i+1)))/60];
    E_str_disc_E_2_day  = [E_str_disc_E_2_day,sum(P_str_disc_E_2(index_day(i)+1:index_day(i+1)).*t_resolution(index_day(i)+1:index_day(i+1)))/60];
end
a_str_round_1       = (E_str_char_E_1_day+E_str_disc_E_1_day)*Day / cap_str_E_1 / 2;
a_str_round_2       = (E_str_char_E_2_day+E_str_disc_E_2_day)*Day / cap_str_E_2 / 2;

a_ramp_OCGT         = value(cost_ramp_OCGT_day*Day/price_ramp_OCGT);
a_ramp_CCGT         = value(cost_ramp_CCGT_day*Day/price_ramp_CCGT);
a_ramp              = [a_ramp_OCGT,a_ramp_CCGT,a_str_round_1,a_str_round_2];

% 各种机组出力累计
a_P_OCGT        = cost_OM_OCGT_var_day*Day/OM_var_OCGT;
a_P_CCGT        = cost_OM_CCGT_var_day*Day/OM_var_CCGT;
a_P_PV          = E_PV_day*Day;
a_P_WT          = E_WT_day*Day;
a_POWER         = [a_P_OCGT,a_P_CCGT,a_P_PV,a_P_WT];



% eta_total   = sum(sum(DMD_E + DMD_H_inds + DMD_H_resd)*3600.*Day') ./ (sum(sum(coal_cons_CHPL + coal_cons_CHPS)*LHV_coal.*Day') + sum(sum(sum(P_str_char_E,3))*3600.*Day') - sum(sum(sum(P_str_disc_E,3))*3600.*Day'));
results = value([CO2_goal,a_ramp,NaN,a_result_cap,NaN,a_result_cost,NaN,a_renew,NaN,a_POWER]);


%% %--- 画图 ---%
if a == 1
    %% 电功率平衡
    for i = 1:1:n
        Time = [];
        for j = 1:1:length_day(i)
            Time = [Time;sum(t_resolution(index_day(i)+1:index_day(i)+j))/60];
        end

        figure(i) % 电能供应
        PP1 = [P_CCGT(index_day(i)+1:index_day(i+1)),P_PV_gen(index_day(i)+1:index_day(i+1)),P_WT_gen(index_day(i)+1:index_day(i+1)),P_str_disc_E_1(index_day(i)+1:index_day(i+1)),P_str_disc_E_2(index_day(i)+1:index_day(i+1)),P_dev_lack(index_day(i)+1:index_day(i+1))]; % 供能机组出力
        % PP1 = [P_OCGT(index_day(i)+1:index_day(i+1)),P_CCGT(index_day(i)+1:index_day(i+1)),P_PV_gen(index_day(i)+1:index_day(i+1)),P_WT_gen(index_day(i)+1:index_day(i+1)),P_str_disc_E_1(index_day(i)+1:index_day(i+1)),P_str_disc_E_2(index_day(i)+1:index_day(i+1)),P_dev_lack(index_day(i)+1:index_day(i+1))]; % 供能机组出力
        PP2 = [-P_str_char_E_1(index_day(i)+1:index_day(i+1)),-P_str_char_E_2(index_day(i)+1:index_day(i+1)),-P_EBe(index_day(i)+1:index_day(i+1)),-P_HPe(index_day(i)+1:index_day(i+1)),-P_dev_resd(index_day(i)+1:index_day(i+1))];                        % 耗能机组出力
        area(Time,PP1)
        hold on
        area(Time,PP2)
        hold on
        stairs(Time,DMD_E(index_day(i)+1:index_day(i+1)),'linewidth',2)
        hold on
        set(gca,'fontsize',24);         % 设置字号
        % set(gca,'XTick',[0.5:2:24.5])   % 设置x轴刻度
        legend('P_C_C_G_T','P_p_v','P_w_i_n_d','P_s_t_r_,_d_i_s_c_,_E_1','P_s_t_r_,_d_i_s_c_,_E_2','P_d_e_v_,_l_a_c_k','P_s_t_r_,_c_h_a_r_,_E_1','P_s_t_r_,_c_h_a_r_,_E_2','P_E_B_e','P_H_P_e','P_d_e_v_,_r_e_s_d','P_l_o_a_d');
        % legend('P_O_C_G_T','P_C_C_G_T','P_p_v','P_w_i_n_d','P_s_t_r_,_d_i_s_c_,_E_1','P_s_t_r_,_d_i_s_c_,_E_2','P_d_e_v_,_l_a_c_k','P_s_t_r_,_c_h_a_r_,_E_1','P_s_t_r_,_c_h_a_r_,_E_2','P_d_e_v_,_r_e_s_d','P_l_o_a_d');
        title('Electric Power')
        box on
        PP1 = value(PP1);
        PP2 = value(PP2);

        if b == 1
            fig_name = [fig_address,season(i,:),'_','power'];
            saveas(gcf,fig_name)
        end
    end
    Time_total = [];
    for i = 1:1:index_day(end)
        Time_total = [Time_total;sum(t_resolution(1:i))/60];
    end


    %% 热功率平衡
    for i = 1:1:n
        Time = [];
        for j = 1:1:length_day(i)
            Time = [Time;sum(t_resolution(index_day(i)+1:index_day(i)+j))/60];
        end

        figure(i+n) % 热能供应
        QQ1 = [Q_EBe(index_day(i)+1:index_day(i+1)),Q_EBg(index_day(i)+1:index_day(i+1)),Q_HPe(index_day(i)+1:index_day(i+1)),Q_HPg(index_day(i)+1:index_day(i+1)),Q_str_disc_H_s(index_day(i)+1:index_day(i+1)),Q_str_disc_H_w(index_day(i)+1:index_day(i+1))]; % 供能机组出力
        QQ2 = [-Q_str_char_H_s(index_day(i)+1:index_day(i+1)),-Q_str_char_H_w(index_day(i)+1:index_day(i+1))];        % 耗热机组出力
        area(Time,QQ1)
        hold on
        area(Time,QQ2)
        hold on
        stairs(Time,DMD_H(index_day(i)+1:index_day(i+1)),'linewidth',2)
        hold on
        set(gca,'fontsize',24);         % 设置字号
        % set(gca,'XTick',[0.5:2:24.5])   % 设置x轴刻度
        legend('Q_E_B_e','Q_E_B_g','Q_H_P_e','Q_H_P_g','Q_s_t_r_,_d_i_s_c_,_H_s','Q_s_t_r_,_d_i_s_c_,_H_w','Q_s_t_r_,_c_h_a_r_,_H_s','Q_s_t_r_,_c_h_a_r_,_H_w','H_l_o_a_d');
        title('Heat Power')
        box on
        QQ1 = value(QQ1);
        QQ2 = value(QQ2);

        if b == 1
            fig_name = [fig_address,season(i,:),'_','heat'];
            saveas(gcf,fig_name)
        end
    end
    Time_total = [];
    for i = 1:1:index_day(end)
        Time_total = [Time_total;sum(t_resolution(1:i))/60];
    end
    %% 可再生
    figure(n+7)
    subplot(2,1,1)
    plot(Time_total,P_PV_single*P_PV_instal)
    hold on
    plot(Time_total,P_PV_gen)
    for i = 1:1:n-1 % 加入每一天的分隔
        line([24*i,24*i],[0,P_PV_instal],'linestyle','--','Color',[0.5,0.5,0.5]);
    end
    title('PV')
    ylim([0,max(0.001,P_PV_instal)])

    subplot(2,1,2)
    plot(Time_total,P_WT_single*P_WT_instal)
    hold on
    plot(Time_total,P_WT_gen)
    for i = 1:1:n-1 % 加入每一天的分隔
        line([24*i,24*i],[0,P_WT_instal],'linestyle','--','Color',[0.5,0.5,0.5]);
    end
    title('WT')
    ylim([0,max(0.001,P_WT_instal)])

    if b == 1
        fig_name = [fig_address,'renewable'];
        saveas(gcf,fig_name)
    end
    %% 储电系统
    figure(n+8)
    subplot(2,1,1)
    % yyaxis left;
    if cap_str_E_1 ~= 0
        stairs(Time_total,P_str_char_E_1,'Color',[0,0.447,0.741])
        hold on
        stairs(Time_total,-P_str_disc_E_1,'-','Color',[0,0.447,0.741])
        hold on
        yyaxis right;
        plot([Time_total],SOC_E_1(1:end-1),'Color',[0.850,0.325,0.098])
        for i = 1:1:n-1 % 加入每一天的分隔
            line([24*i,24*i],[0.2,1],'linestyle','--','Color',[0.5,0.5,0.5]);
        end
        title('BESS1')
        xlim([0,144])
        ylim([0.2,1])
    end

    subplot(2,1,2)
    % yyaxis left;
    if cap_str_E_2 ~= 0
        stairs(Time_total,P_str_char_E_2,'Color',[0,0.447,0.741])
        hold on
        stairs(Time_total,-P_str_disc_E_2,'-','Color',[0,0.447,0.741])
        hold on
        yyaxis right;
        plot([Time_total],SOC_E_2(1:end-1),'Color',[0.850,0.325,0.098])
        for i = 1:1:n-1 % 加入每一天的分隔
            line([24*i,24*i],[0.2,1],'linestyle','--','Color',[0.5,0.5,0.5]);
        end
        title('BESS2')
        xlim([0,144])
        ylim([0.2,1])
    end
    if b == 1
        fig_name = [fig_address,'BESS'];
        saveas(gcf,fig_name)
    end

    % 储热系统
    figure(n+9)
    subplot(2,1,1)
    % yyaxis left;
    if cap_str_E_1 ~= 0
        stairs(Time_total,Q_str_char_H_s,'Color',[0,0.447,0.741])
        hold on
        stairs(Time_total,-Q_str_disc_H_s,'-','Color',[0,0.447,0.741])
        hold on
        yyaxis right;
        plot([Time_total],SOT_H_s(1:end-1),'Color',[0.850,0.325,0.098])
        for i = 1:1:n-1 % 加入每一天的分隔
            line([24*i,24*i],[0.2,1],'linestyle','--','Color',[0.5,0.5,0.5]);
        end
        title('TESS1')
        xlim([0,144])
        ylim([0.2,1])
    end

    subplot(2,1,2)
    % yyaxis left;
    if cap_str_E_2 ~= 0
        stairs(Time_total,Q_str_char_H_w,'Color',[0,0.447,0.741])
        hold on
        stairs(Time_total,-Q_str_disc_H_w,'-','Color',[0,0.447,0.741])
        hold on
        yyaxis right;
        plot([Time_total],SOT_H_w(1:end-1),'Color',[0.850,0.325,0.098])
        for i = 1:1:n-1 % 加入每一天的分隔
            line([24*i,24*i],[0.2,1],'linestyle','--','Color',[0.5,0.5,0.5]);
        end
        title('TESS2')
        xlim([0,144])
        ylim([0.2,1])
    end
    if b == 1
        fig_name = [fig_address,'TESS'];
        saveas(gcf,fig_name)
    end

end
%% %---写入excel ---%
% %% 高波动
% xlswrite('results.xlsx',NaN,'output1','A1:AR1441');
% i = 3;
% PP1         = [P_SPC(index_day(i)+1:index_day(i+1)),P_UPC(index_day(i)+1:index_day(i+1)),P_OCGT(index_day(i)+1:index_day(i+1)),P_CCGT(index_day(i)+1:index_day(i+1)),P_PV_gen(index_day(i)+1:index_day(i+1)),P_WT_gen(index_day(i)+1:index_day(i+1)),P_str_disc_E_1(index_day(i)+1:index_day(i+1)),P_str_disc_E_2(index_day(i)+1:index_day(i+1)),P_dev_lack(index_day(i)+1:index_day(i+1))]; % 供能机组出力
% PP2         = [-P_str_char_E_1(index_day(i)+1:index_day(i+1)),-P_str_char_E_2(index_day(i)+1:index_day(i+1)),-P_dev_resd(index_day(i)+1:index_day(i+1))];                        % 耗能机组出力
% Time_output = t_resolution(index_day(i)+1:index_day(i+1));
% 
% PP1_interp      = [];
% PP2_interp      = [];
% Time_interp     = [];
% for k = 1:1:length(Time_output)
%     PP1_interp      = [PP1_interp;ones(Time_output(k),1)*PP1(k,:)];
%     PP2_interp      = [PP2_interp;ones(Time_output(k),1)*PP2(k,:)];
%     Time_interp     = [Time_interp;ones(Time_output(k),1)*Time_output(k,:)];
% end
% 
% PP1_low = PP1_interp;
% PP2_low = PP2_interp;
% for k = 1:1:size(PP1_interp,1)
%     if Time_interp(k) ~= 60
%         PP1_low(k,:) = 0;
%         PP2_low(k,:) = 0;
%     end
% end
% PP1_mid = PP1_interp;
% PP2_mid = PP2_interp;
% for k = 1:1:size(PP1_interp,1)
%     if Time_interp(k) ~= 15
%         PP1_mid(k,:) = 0;
%         PP2_mid(k,:) = 0;
%     end
% end
% PP1_high = PP1_interp;
% PP2_high = PP2_interp;
% for k = 1:1:size(PP1_interp,1)
%     if Time_interp(k) ~= 1
%         PP1_high(k,:) = 0;
%         PP2_high(k,:) = 0;
%     end
% end
% 
% for k = 1:1:24
%     PP1_low((k-1)*60+2:k*60,:) = M;
%     PP2_low((k-1)*60+2:k*60,:) = M;
% end
% PP1_low(PP1_low == M) = [];
% PP2_low(PP2_low == M) = [];
% PP1_low = reshape(PP1_low,[24,size(PP1_interp,2)]);
% PP2_low = reshape(PP2_low,[24,size(PP2_interp,2)]);
% xlswrite('results.xlsx',[(0.5:1:24)',PP1_low,PP2_low],'output1','A2');
% 
% for k = 1:1:96
%     PP1_mid((k-1)*15+2:k*15,:) = M;
%     PP2_mid((k-1)*15+2:k*15,:) = M;
% end
% PP1_mid(PP1_mid == M) = [];
% PP2_mid(PP2_mid == M) = [];
% PP1_mid = reshape(PP1_mid,[96,size(PP1_interp,2)]);
% PP2_mid = reshape(PP2_mid,[96,size(PP2_interp,2)]);
% xlswrite('results.xlsx',[(0.125:0.25:24)',PP1_mid,PP2_mid],'output1','O2');
% 
% xlswrite('results.xlsx',[(1/120:1/60:24)',PP1_high,PP2_high],'output1','AC2');
% %% 低波动
% xlswrite('results.xlsx',NaN,'output2','A1:AR1441');
% i = 6;
% PP1         = [P_SPC(index_day(i)+1:index_day(i+1)),P_UPC(index_day(i)+1:index_day(i+1)),P_OCGT(index_day(i)+1:index_day(i+1)),P_CCGT(index_day(i)+1:index_day(i+1)),P_PV_gen(index_day(i)+1:index_day(i+1)),P_WT_gen(index_day(i)+1:index_day(i+1)),P_str_disc_E_1(index_day(i)+1:index_day(i+1)),P_str_disc_E_2(index_day(i)+1:index_day(i+1)),P_dev_lack(index_day(i)+1:index_day(i+1))]; % 供能机组出力
% PP2         = [-P_str_char_E_1(index_day(i)+1:index_day(i+1)),-P_str_char_E_2(index_day(i)+1:index_day(i+1)),-P_dev_resd(index_day(i)+1:index_day(i+1))];                        % 耗能机组出力
% Time_output = t_resolution(index_day(i)+1:index_day(i+1));
% 
% PP1_interp      = [];
% PP2_interp      = [];
% Time_interp     = [];
% for k = 1:1:length(Time_output)
%     PP1_interp      = [PP1_interp;ones(Time_output(k),1)*PP1(k,:)];
%     PP2_interp      = [PP2_interp;ones(Time_output(k),1)*PP2(k,:)];
%     Time_interp     = [Time_interp;ones(Time_output(k),1)*Time_output(k,:)];
% end
% 
% PP1_low = PP1_interp;
% PP2_low = PP2_interp;
% for k = 1:1:size(PP1_interp,1)
%     if Time_interp(k) ~= 60
%         PP1_low(k,:) = 0;
%         PP2_low(k,:) = 0;
%     end
% end
% PP1_mid = PP1_interp;
% PP2_mid = PP2_interp;
% for k = 1:1:size(PP1_interp,1)
%     if Time_interp(k) ~= 15
%         PP1_mid(k,:) = 0;
%         PP2_mid(k,:) = 0;
%     end
% end
% PP1_high = PP1_interp;
% PP2_high = PP2_interp;
% for k = 1:1:size(PP1_interp,1)
%     if Time_interp(k) ~= 1
%         PP1_high(k,:) = 0;
%         PP2_high(k,:) = 0;
%     end
% end
% 
% for k = 1:1:24
%     PP1_low((k-1)*60+2:k*60,:) = M;
%     PP2_low((k-1)*60+2:k*60,:) = M;
% end
% PP1_low(PP1_low == M) = [];
% PP2_low(PP2_low == M) = [];
% PP1_low = reshape(PP1_low,[24,size(PP1_interp,2)]);
% PP2_low = reshape(PP2_low,[24,size(PP2_interp,2)]);
% xlswrite('results.xlsx',[(0.5:1:24)',PP1_low,PP2_low],'output2','A2');
% 
% for k = 1:1:96
%     PP1_mid((k-1)*15+2:k*15,:) = M;
%     PP2_mid((k-1)*15+2:k*15,:) = M;
% end
% PP1_mid(PP1_mid == M) = [];
% PP2_mid(PP2_mid == M) = [];
% PP1_mid = reshape(PP1_mid,[96,size(PP1_interp,2)]);
% PP2_mid = reshape(PP2_mid,[96,size(PP2_interp,2)]);
% xlswrite('results.xlsx',[(0.125:0.25:24)',PP1_mid,PP2_mid],'output2','O2');
% 
% xlswrite('results.xlsx',[(1/120:1/60:24)',PP1_high,PP2_high],'output2','AC2');
%% %---写入excel ---%
% xlswrite('results.xlsx',CO2,'var',['A',num2str(ii+1)]);
% xlswrite('results.xlsx',results,'var',['B',num2str(ii+1)]);
% end