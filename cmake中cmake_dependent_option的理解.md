include(CMakeDependentOption)
# second option depends on the value of the first
cmake_dependent_option(
    MAKE_STATIC_LIBRARY "Compile sources into a static library" OFF
    "USE_LIBRARY" ON
    )
# third option depends on the value of the first
cmake_dependent_option(
    MAKE_SHARED_LIBRARY "Compile sources into a shared library" ON
    "USE_LIBRARY" ON
    )

# cmake_dependent_option(<option> "<help_text>" <value> <depends> <force>)
    option值的依赖depends
-   当depends的值为true时, option对用户可见, option的初始值为value. 
    当然用户可以通过cmake -D option=OFF进行修改
-   当depends的值为false时, opton对用户不可见时, 本地变量option被设置为force, 
    用户对option的任何修改值都被保留(INTERNAL类型), 以备将来depends为true时使用 

//Compile sources into a shared library
MAKE_SHARED_LIBRARY:INTERNAL=OFF
//Compile sources into a static library
MAKE_STATIC_LIBRARY:INTERNAL=OFF
