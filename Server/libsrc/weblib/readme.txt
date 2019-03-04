在QQ宠物cgi/fcgi开发的框架上改进的。
fcgi功能依赖fcgi-2.4.0 api

特性：
1.cgi/fcgi 通过宏定义确定编译的是cgi还是fcgi
2.url参数，cookie，环境变量 被框架类解析成std::map
3.提供模板输出功能
4.http body中的内容没有处理过