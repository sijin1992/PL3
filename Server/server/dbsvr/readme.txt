lock
������key->timestamp,validtime

cache
key->val���䳤���޽ṹ��
���ṩget��set��del��������Ҫ�ڴ�copy
��ѡ��ʱ��̭�����������ȳ���������̭
ʹ��hash_map + fixsize_allocator + timer + fifo����

tcplinker---- dbsvr -------  mysql_helper*n --------- mysql
			---- tc_helper*n ------------- tokyo cabinet
dbsvr��lock ��ѡcache����Ҫ�����ݴ洢ʹ��mysql
ս��¼��洢���ݶ�ʧҲ����ν����tc��С���棩���ڴ���Դ����dbsvr��
