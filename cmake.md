# cmake -S . -B build

	该命令是跨平台的，使用了-S和-B为CLI选项。-S(默认不需要指定，只要给出路径就行）表示当前目录中搜索根CMakeLists.txt文件。-B build告诉CMake在一个名为build的目录中生成所有的文件


	Makefile: make将运行指令来构建项目。
	CMakefile：包含临时文件的目录，CMake用于检测操作系统、编译器等。此外，根据所选的生成器，它还包含特定的文件。
	cmake_install.cmake：处理安装规则的CMake脚本，在项目安装时使用。
	CMakeCache.txt：如文件名所示，CMake缓存。CMake在重新运行配置时使用这个文件

#  cmake --build build --target help

	all(或Visual Studio generator中的ALL_BUILD)是默认目标，将在项目中构建所有目标。
	clean，删除所有生成的文件。
	rebuild_cache，将调用CMake为源文件生成依赖(如果有的话)。
	edit_cache，这个目标允许直接编辑缓存。

#  cmake --build build (构建，跨平台命令)


# 变量CMAKE_INSTALL_PREFIX： cmake 内置变量，用于指定 cmake 执行 install 目标时，安装的路径前缀
	1、在执行 cmake 时指定
	cmake -DCMAKE_INSTALL_PREFIX=<你想要安装的路径>
	2、设置 CMAKE_INSTALL_PREFIX 变量
	SET(CMAKE_INSTALL_PREFIX /usr/local)

	在设置完 install 的安装目录之后，执行 install 时可以通过 DESTINATION 直接指定安装目录之下的目录
    install(TARGETS cls_numops DESTINATION lib}) // 安装到/usr/local/lib目录
    上述的 install 函数是在 cmake 、make 之后，执行 make install 命令时才运行的

 
 # CMake中INSTALL_RPATH与BUILD_RPATH问题

	用readelf -d分析两种环境下生成的path： readelf -d /usr/lib64/libbrpc.so
	简单地说，在搜索app的间接依赖库时，RPATH起作用，但RUNPATH不起作用。
	在使用RUNPATH的情况下，很可能还要再配合LD_LIBRARY_PATH一块使用
	最好使用RPATH，这样就不用依赖LD_LIBRARY_PATH了
	但是，如何控制生成RPATH还是RUNPATH？
	链接时使用–enable-new-dtags可以固定生成RUNPATH，使用–disable-new-dtags可以固定生成RPATH。
	set_target_properties(XXX  LINK_FLAGS "-Wl,--disable-new-dtags")


# CMake build之后消除RPATH

	set(CMAKE_SKIP_RPATH TRUE)
	set(CMAKE_SKIP_BUILD_RPATH TRUE)
	set(CMAKE_SKIP_INSTALL_RPATH TRUE)

# make install下CMake是如何处理RPATH的？

	CMake为了方便用户的安装，默认在make install之后会自动remove删除掉相关的RPATH，这个时候你再去查看exe的RPATH，已经发现没有这个字段了。
	因此，当每次make install之后，我们进入到安装路径下执行相关exe的时候，就会发现此时的exe已经找不到相关的库路径了，因为它的RPATH已经被CMake给去除了。

# 如何让CMake能够在install的过程中写入相关RPATH，并且该RPATH不能使当初build的时候的RPATH呢？

	CMAKE_INSTALL_RPATH这个全局变量和INSTALL_RPATH这个target属性

	set(CMAKE_INSTALL_RPATH ${CMAKE_INSTALL_PREFIX}/lib)
	需要注意的是，这个变量是全局变量，意味着你所有的target的RPATH都会在install的时候被写成这个(包括myexe和不需要RPATH的share_lib)

	set_target_properties(${PROJECT_NAME} PROPERTIES 
      INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib" 
      LINK_FLAGS "-Wl,--disable-new-dtags")
    这样就可以保证只针对当前的target进行make install的时候RPATH的写入了

# 如何让RPATH寻找相对路径
	set_target_properties(${PROJECT_NAME} PROPERTIES 
    INSTALL_RPATH "$ORIGIN/../lib" 
    LINK_FLAGS "-Wl,--disable-new-dtags")

    在GCC中有个变量可以获得程序当前路径，即：$ORIGIN
	当希望使用相对位置寻找.so文件，就需要利用$ORIGIN设置RPATH

	set_target_properties(${PROJECT_NAME} PROPERTIES 
    INSTALL_RPATH "$ORIGIN/../lib;/other/lib/path" 
    LINK_FLAGS "-Wl,--disable-new-dtags")

    多个路径之间使用冒号“:”隔开




# cmake相关：sudo make install后的卸载

- 如果要把install了的文件删掉，部分package提供了uninstall命令，就能很快删掉install
	make uninstall
- 如果没有提供uninstall，查看build文件夹里有没有install_mainfest.txt这个文件，有的话可以这么删除install
	xargs rm < install_manifest.txt
- 如果也没有install_manifest.txt，那就可以再install一遍，把install结果写日志里，然后对应着删除install
	make install > install.log 2>&1




