# python性能分析
## 分析代码段
import cProfile
cProfile.run("directory_manager.get_directories_details()", filename="result.out", sort="cumulative")

## 分析脚本
python -m cProfile del.py

python -m cProfile -o del.out del.py

# 结果查看

## 方法一
import pstats
p = pstats.Stats("result.out")
p.strip_dirs().sort_stats("cumulative", "name").print_stats(0.5)

python -c "import pstats; p=pstats.Stats('del.out'); p.sort_stats('time').print_stats()"
    calls, cumulative, file, line, module, name, nfl, pcalls, stdname, time


## 方法二
>python -m pstats result.out
Welcome to the profile statistics browser.
result.out% help


