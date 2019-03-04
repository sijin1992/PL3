1. 接入进程使用epoll tcp
2. 接入进程通过基于shm的mem_dequeue与处理进程交换数据。
   数据包=connection_info(fd+sessionID)+user_packet
3. user_packet的解析协议，支持a. 自定义二进制协议 b. 有固定结尾标识的协议 c. 字节流不管分包
4. 测试处理进程是直接把收到的包返回

测试流程，connect是通用组件
cleint<->connect<->echologic 