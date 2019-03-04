lock
锁服务，key->timestamp,validtime

cache
key->val（变长，无结构）
仅提供get，set，del方法，需要内存copy
可选定时淘汰，可以先入先出的主动淘汰
使用hash_map + fixsize_allocator + timer + fifo构成

tcplinker---- dbsvr -------  mysql_helper*n --------- mysql
			---- tc_helper*n ------------- tokyo cabinet
dbsvr带lock 可选cache，主要的数据存储使用mysql
战斗录像存储数据丢失也无所谓，用tc（小缓存），内存资源留给dbsvr用
