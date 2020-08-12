# windows

1. keyed windows 可以提高并行度
2. non-keyed windows

## 窗口生命周期：

1. 当第一个元素到达时，就创建窗口，当时间经历了窗口时间段加上用户设置的延迟后，窗口就销毁(全局窗口不销毁)

2. 