python 安装模块numpy遇到无法卸载的情况的解决办法

python在安装seaborn的时候，需要更新numpy模块，但是更新失败，输出下面的错误：


　　Cannot uninstall 'numpy'. It is a distutils installed project and thus we ca

查了一下，有的网友说可以关闭Mac的SIP，但是由于操作系统版本较低，没能奏效。

最终使用的解决办法比较简单。

执行

　　site.getsitepackages()

输出

　　['/System/Library/Frameworks/Python.framework/Versions/2.7/Extras/lib/python', '/Library/Python/2.7/site-packages']

把涉及到的numpy文件夹都删掉，再次执行

　　pip install numpy

安装成功

　　Installing collected packages: numpy
　　Successfully installed numpy-1.15.1
