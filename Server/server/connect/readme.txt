1. �������ʹ��epoll tcp
2. �������ͨ������shm��mem_dequeue�봦����̽������ݡ�
   ���ݰ�=connection_info(fd+sessionID)+user_packet
3. user_packet�Ľ���Э�飬֧��a. �Զ��������Э�� b. �й̶���β��ʶ��Э�� c. �ֽ������ְܷ�
4. ���Դ��������ֱ�Ӱ��յ��İ�����

�������̣�connect��ͨ�����
cleint<->connect<->echologic 