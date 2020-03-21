# 分析当前系统各项服务启动时间及顺序
	a.列出各项启动占用的时间，但由于是并行启动，启动时间不决定启动完成先后
	systemd-analyze blame

	b.列出启动矢量图，用浏览器打开boot.svg文件  得到各service启动顺序
	systemd-analyze plot > boot.svg

	c.分析依赖关系
	systemctl list-dependencies seeed-voicecard.service