-----------------------------------------------------------------------------------------------------------
## Project : GG3.1 系统模块压力测试
-----------------------------------------------------------------------------------------------------------
#### 工程简介
-----------------------------------------------------------------------------------------------------------
本工程通过实现桂冠系统每个模块功能项压力测试监控，从而达到被验证模块功能可靠稳定的目的。
工程操作系统环境为ubuntu的16.04 LTS。
整个工程目录结构主要由bin、etc、lib、log等目录及执行文件构成，各目录与文件的说明详见下节的目录结构描述。
-----------------------------------------------------------------------------------------------------------
#### 目录结构描述
-----------------------------------------------------------------------------------------------------------
Directory description
-----------------------------------------------------------------------------------------------------------
GG31_SYSTEM/                    # 主目录
├── bin                         # 业务层目录，存放各个测试内容文件
│   ├── monitor_cpu.sh		# 压力测试：Cpu监控，监控项包含CPU占用率、CPU频率与温度
│   ├── monitor_gpu.sh		# 压力测试：Gpu监控，监控项包含GPU占用率、GPU频率
│   ├── monitor_iperf.sh	# 压力测试：Iperf监控，监控项支持master端与slave端服务端切换
│   ├── monitor_net.sh		# 压力测试：Net监控，监控项支持IP与域名切换
│   ├── monitor_temp.sh		# 压力测试：Temp监控
│   ├── monitor_module		# 模块目录
│   	├── monitor_apu.sh	# 压力测试: Apu监控，监控项支持常电状态正常与异常模式（秒级与毫秒级异常）升级
│   	├── monitor_can.sh	# 压力测试: Can监控，监控项包含BCAN、PCAN、CAN3、CAN4状态
│   	├── monitor_cdu.sh	# 压力测试: Cdu监控，监控项包含Video0与Video1节点摄像头数据下载状态
│   	├── monitor_dgps.sh	# 压力测试: Dgps监控，监控项包含dgps帧数状态
│   	├── monitor_dsi.sh	# 压力测试: Dsi监控，监控项包含Dsi显示状态
│   	├── monitor_ssd.sh	# 压力测试: Ssd监控，监控项包含ssd读写速度状态
│   	└── monitor_system.sh	# 压力测试: System监控，监控项包含GG3.1硬件、软件、系统状态等
│   └── statistic_error.sh	# 结果统计：异常搜索，结果统计
├── etc  	                # 配置目录，目录中的模块文件定义了业务层运行时所需的各类常量、函数、配置项
│   ├── common.sh               # 公共常量：各类常量
│   ├── function.sh             # 公共函数：各类函数
│   ├── install_deb.sh          # 依赖包函数：安装包函数
│   └── search_exception.txt    # 遍历异常：遍历每项功能测试结果统计输出
├── lib   			# 共享库，存放安装包、公共执行文件
│   ├── deb_package		# 共享库: 依赖安装包
│   ├── file_attached		# 共享库：公共执行文件
│   	├── file_cron		# 共享库: 定时服务
│   	└── file_gpu		# 共享库: GPU执行文件
│   └── html_attached		# 共享库：HTML配置文件
├── log                         # 日志目录，用于存放各类监控内容日志
│   ├── check_apu		# 日志: Apu项测试过程记录日志
│   	├── abnormal		# 日志: Apu异常记录日志
│   	└── normal		# 日志: Apu正常记录日志
│   ├── check_can		# 日志: Can项测试过程记录日志
│   ├── check_cdu		# 日志: Cdu项测试过程记录日志
│   ├── check_dgps		# 日志: Dgps测试过程记录日志
│   ├── check_dsi		# 日志: Dsi测试过程记录日志
│   ├── check_gpu		# 日志: Gpu测试过程记录日志
│   ├── check_iperf		# 日志: Iperf测试过程记录日志
│   ├── check_monitor		# 日志: System测试过程记录日志
│   ├── check_network		# 日志: Net测试过程记录日志
│   ├── check_ssd		# 日志: Ssd测试过程记录日志
│   ├── check_statistic		# 日志: 遍历Error&统计结果日志
│   ├── check_temp		# 日志: Temp测试过程记录日志
│   └── roll_back.txt		# 日志: 回卷记录日志
├── opt                         # 服务目录：服务配置与使能脚本
│   ├── service_script		# 服务: 配置脚本
│   └── service_system		# 服务: 系统服务
├── run.sh   			# 测试启动文件，按需启动执行测试内容
├── config.json              	# 配置JSON：模块参数配置项
└── README.md                   # 工程说明文件
-----------------------------------------------------------------------------------------------------------
#### 使用说明 
-----------------------------------------------------------------------------------------------------------
1、config.json文件说明：
	"delay_time":2,				# 功能项测试循环等待时间间隔
	"roll_back":20,				# 数据回滚阀值，当check_statistic路径下日志数量超过阀值进行回滚
	"para_apu":{				# Apu项参数配置
		"apu_cycle":2,			# Apu测试循环次数
		"apu_file_mode":2,		# Apu升级固件类型，1:e100; 2:e100w
		"apu_upgrade_mode":2,		# Apu升级模式，1:正常; 2:异常
		"apu_image":{
			"show_switch":1,	# Apu测试结果html回放开关
			"show_interval":5	# Apu测试结果html回放循环间隔
		},		
		"apu_abnormal":{
			"fail_times":2,		# Apu异常连续升级失败次数
			"time_mode":2,		# Apu异常升级模式，1:秒级; 2:毫秒级
			"mil_time":"0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9",
			"sec_time":"1,2,3,4,5,6,7,8,9,10"
		}
	},
	"para_can":{				# Can项参数配置
		"can_cycle":1000,		# Can测试循环次数
		"can_mode":0,			# Can测试模式，1:GUI模式; 2:命令行模式
		"can_image":{
			"show_switch":1,	# Can测试结果html回放开关
			"show_interval":5	# Can测试结果html回放循环间隔
		}
	},
	"para_cpu":{				# Cpu项参数配置
		"cpu_cycle":1000,		# Cpu测试循环次数
		"cpu_image":{
			"show_switch":1,	# Cpu测试结果html回放开关
			"show_interval":5	# Cpu测试结果html回放循环间隔
		},
		"cpu_stress":{
			"core_num_master":3,	# Master端CPU内核数
			"core_num_slave":3,	# Slave端CPU内核数
			"time_num":1,		# Stress执行时间量
			"time_unit":"d"		# Stress执行时间单位
		}
	},
	"para_cdu":{				# Cdu项参数配置
		"cdu_cycle":1000,		# Cdu测试循环次数
		"cdu_image":{
			"show_switch":1,	# Cdu测试结果html回放开关
			"show_interval":5	# Cdu测试结果html回放循环间隔
		},
		"cdu_video":{
			"video0_num":1,		# Video0节点连接摄像头数量
			"video1_num":2		# Video1节点连接摄像头数量
		}
	},
	"para_dgps":{				# Dgps项参数配置
		"dgps_cycle":1000,		# Dgps测试循环次数
		"dgps_uos":"uisee_0715",	# Dgps测试依赖UOS包名称
		"dgps_image":{
			"show_switch":1,	# Dgps测试结果html回放开关
			"show_interval":5	# Dgps测试结果html回放循环间隔
		}
	},
	"para_dsi":{				# Dsi项参数配置
		"dsi_cycle":1000,		# Dsi测试循环次数
		"dsi_image":{
			"show_switch":1,	# Dsi测试结果html回放开关
			"show_interval":5	# Dsi测试结果html回放循环间隔
		}
	},
	"para_gpu":{				# Gpu项参数配置
		"gpu_cycle":1000,		# Gpu测试循环次数
		"gpu_uos":"uisee_0715",		# Gpu测试依赖UOS包名称
		"gpu_image":{
			"show_switch":1,	# Gpu测试结果html回放开关
			"show_interval":5	# Gpu测试结果html回放循环间隔
		}
	},
	"para_net":{				# Net项参数配置
		"ping_cycle":1000,		# Net测试循环次数
		"ping_image":{
			"show_switch":1,	# Net测试结果html回放开关
			"show_interval":5	# Net测试结果html回放循环间隔
		},
		"ping_package":{
			"ping_mode":1,		# Ping包测试模式，1:IP; 2:域名
			"ping_ip":"8.8.8.8",	# Ping包对象-IP
			"ping_domain":"www.baidu.com",	# Ping包对象-域名
			"ping_num":5,		# Ping包数量
			"ping_time":1		# Ping包时间间隔
		}
	},
	"para_iperf":{				# Iperf项参数配置
		"iperf_mode":2,			# Iperf测试模式（服务端），1:Master端; 2:Slave端
		"iperf_image":{
			"show_switch":1,	# Iperf测试结果html回放开关
			"show_interval":5	# Iperf测试结果html回放循环间隔
		}
	},
	"para_ssd":{				# Ssd项参数配置
		"ssd_cycle":1000,		# Ssd测试循环次数
		"ssd_type":"/dev/nvme0n1",	# Ssd硬件类型
		"ssd_mounted":"/home/worker/disk",	# Ssd硬盘挂载地址
		"ssd_image":{
			"show_switch":1,	# Ssd测试结果html回放开关
			"show_interval":5	# Ssd测试结果html回放循环间隔
		},
		"ssd_cpu":{
			"core_num":3,		# Ssd测试终端CPU占用内核数
			"time_num":1,		# Ssd测试终端CPU测试时间数量
			"time_unit":"d"		# Ssd测试终端CPU测试时间单位
		},
		"ssd_dd":{
			"dd_bs":"M",		# Ssd测试写入单位
			"dd_count":10		# Ssd测试写入数量
		}
	},
	"para_statistic":{			# Statistic项参数配置
		"statistic_image":{
			"cron_md5sum":"7f8d0e011f68d2d923ccf2dfbcf2fa58", # crontab文件MD5值 
			"mail_switch":0,	# 邮件使能开关
			"rollback_threshold":20,# 回卷阀值
			"show_switch":1		# Statistic测试结果html回放开关
			}
		},
	"para_temp":{				# Temp项参数配置
		"temp_cycle":1000,		# Temp测试循环次数
		"temp_mode":0,			# Temp测试模式，0:低温; 1:常温; 2:高温
		"temp_image":{
			"show_switch":1,	# Temp测试结果html回放开关
			"show_interval":5	# Temp测试结果html回放循环间隔
		}
	}
2、测试环境准备：
	0）将测试文件GG31_SYSTEM/拷贝至桂冠3.1 master端主目录/home/worker/路径；
	1）根据config.json文件配置项参数说明，按需配置
3、执行测试：
	切换路径GG31_SYSTEM/文件下，即可执行每个单元的测试项。其中，各个测试项的监控指令如下：
	执行指令：./run.sh 1		# 表示执行Apu测试监控；
	执行指令：./run.sh 2		# 表示执行Can测试监控；
	执行指令：./run.sh 3		# 表示执行Cdu测试监控；
	执行指令：./run.sh 4		# 表示执行Cpu测试监控；
	执行指令：./run.sh 5		# 表示执行Dgps测试监控；
	执行指令：./run.sh 6		# 表示执行Dsi测试监控；
	执行指令：./run.sh 7		# 表示执行GPu测试监控；
	执行指令：./run.sh 8		# 表示执行Iperf测试监控；
	执行指令：./run.sh 9		# 表示执行Net测试监控；
	执行指令：./run.sh 10		# 表示执行Ssd测试监控；
	执行指令：./run.sh 11		# 表示执行Temp测试监控；	
	执行指令：./run.sh 12		# 表示执行System测试监控；
4、遍历异常：
	执行指令：./run.sh 13
	该指令用于多次上下电或多次重复测试执行，单项功能日志路径产生多个日志文件，便于快速获取统计执行结果状态。
5、测试记录：
	测试项过程与结果统计日志存储于GG31_SYSTEM/log/路径，测试单元项日志文件目录以check_unitname命令，同时以本次执行开始的时间"yyyy-dd-mm-HH-MM-SS"命名作为日志存储子目录。
-----------------------------------------------------------------------------------------------------------
