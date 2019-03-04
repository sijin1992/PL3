#include <pthread.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <time.h>
#include <errno.h>

#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/wait.h>

#include "proto/cmd_login.pb.h"
#include "proto/cmd_pve.pb.h"


char server_ip[] = "10.10.1.153";
short port = 14080;
char password[] = "1";
const int MAX_THREAD = 400;

int g_run = 1;
const int MAX_BUF = 1024;

#pragma pack(push)
#pragma pack(1)
struct BIN_PRO_HEAD
{
    char magic[6];
    char useNetOrder;
    unsigned int packetLen;
    unsigned int cmd;
    int result;
    char name[32];
};
#pragma pack(pop)

void format_head(struct BIN_PRO_HEAD * head, const char *user)
{
    memcpy(head->magic, "BINPRO", 6);
    head->useNetOrder = 1;
    strncpy(head->name, user, 32);
    //head->name[strlen(user)] = NULL;
    head->result = htonl(0);
}

void fill_head(struct BIN_PRO_HEAD *head, unsigned int len, unsigned int cmd)
{
    int t_len = len;
    head->packetLen = htonl(t_len);
    head->cmd = htonl(cmd);
}

int _send(int s, const char *buf, int len)
{
    int ret;
    int max_num = 3;
    int sended = 0;
    while(sended < len)
    {   
        ret = write(s, buf + sended, len - sended);
        if(ret < 0)
        {
            if(--max_num > 0 && errno == EINTR)
                continue;
            if(errno == EPIPE)
            {
                return -2;
            }
            return -1;
        }
        else
        {
            sended += ret;
        }
    }
    return sended;
}

int _recv(int s, char *buf, int len)
{
    int ret = 0;
	int max_num = 3;
	int recived = 0;
	while(recived < len)
	{
		ret = read(s, buf + recived, len - recived);
        if(ret < 0)
		{
			if( --max_num > 0 && errno == EINTR)
				continue;
			else
			{
				return -1;
			}
		}
		else if(ret == 0)
		{
			return -2;
		}
		else
		{
			recived += ret;
		}
	}
	return recived;
}

int reconnect(int &s, int thread_idx)
{
    if(s > 0)
        close(s);
    s = socket(AF_INET, SOCK_STREAM, 0);
    if (s < 0)
    {
        printf("thread %d: socket create err\n", thread_idx);
        return -1;
    }
    struct in_addr addr;
    if(!inet_aton(server_ip, &addr))
    {
        printf("thread %d: inet_aton err\n", thread_idx);
        close(s);
        s = -1;
        return -1;
    }
    struct sockaddr_in sa;
    memset(&sa, 0, sizeof(sa));
    sa.sin_family = AF_INET;
    sa.sin_addr.s_addr = addr.s_addr;
    sa.sin_port = htons(port);
    if(connect(s, (struct sockaddr *)&sa, sizeof(sa)) < 0)
    {
        printf("thread %d: connect err\n", thread_idx);
        close(s);
        s = -1;
        return -1;
    }
    return 0;
}

int do_login(int s, char *buf, int len, char *recv_buf, int thread_idx)
{
    LoginReq r;
    r.ParseFromArray(buf + sizeof(BIN_PRO_HEAD), len - sizeof(BIN_PRO_HEAD));
    struct BIN_PRO_HEAD * head = (struct BIN_PRO_HEAD*)(void *)buf;
    //printf("thread %d, %d, %d, %s, %s\n", thread_idx, len, ntohl(head->packetLen), head->name, r.DebugString().c_str());
    int send_len = _send(s, buf, len);
    if(send_len != len) printf("thread %d, sendlen = %d, len = %d\n", thread_idx, send_len, len);
    if (send_len < 0)
        return send_len;
    int recv_len = _recv(s, recv_buf, sizeof(BIN_PRO_HEAD));
    if (recv_len < 0)
    {
        return recv_len;
        printf("thread %d: dologin recv1 %d(%d)\n", thread_idx, recv_len, sizeof(BIN_PRO_HEAD));
    }
    if(recv_len == sizeof(BIN_PRO_HEAD))
    {
        struct BIN_PRO_HEAD * head = (struct BIN_PRO_HEAD*)(void *)recv_buf;
        //printf("thread %d, %d, \n", thread_idx, ntohl(head->packetLen));
        int len1 = ntohl(head->packetLen) - sizeof(BIN_PRO_HEAD);
        if(len1 > 0)
        {
            recv_len = _recv(s, recv_buf + sizeof(BIN_PRO_HEAD), len1);
            if(recv_len == len1)
            {/*
                LoginResp resp;
                //printf("login %d\n", thread_idx);
                if(resp.ParseFromArray(recv_buf + sizeof(BIN_PRO_HEAD), recv_len))
                {
                    //printf("%d resp:%s\n", thread_idx, resp.DebugString().c_str());
                    //printf("thread %d: login success\n", thread_idx);
                }
                else
                {
                    printf("thread %d: recv %d, %d\n", thread_idx, len1, recv_len);
                }*/
            }
            else
            {
                printf("thread %d: dologin recv2 %d(%d)\n", thread_idx, recv_len, len1);
                return recv_len;
            }
        }
    }
    else
    {
        printf("thread %d: dologin recv1 %d(%d)\n", thread_idx, recv_len, sizeof(BIN_PRO_HEAD));
    }
    return 0;
}

int do_pve(int s, char *buf, int len, char *recv_buf, int thread_idx)
{
    int send_len = _send(s, buf, len);
    if(send_len != len) printf("thread %d, sendlen = %d, len = %d\n", thread_idx, send_len, len);
    if (send_len < 0)
        return send_len;
    int recv_len = _recv(s, recv_buf, sizeof(BIN_PRO_HEAD));
    if (recv_len < 0)
    {
        printf("thread %d: dopve recv1 %d(%d)\n", thread_idx, recv_len, sizeof(BIN_PRO_HEAD));
        return recv_len;
    }
    if(recv_len == sizeof(BIN_PRO_HEAD))
    {
        struct BIN_PRO_HEAD * head = (struct BIN_PRO_HEAD*)(void *)recv_buf;
        int len1 = ntohl(head->packetLen) - sizeof(BIN_PRO_HEAD);
        if(len1 > 0)
        {
            recv_len = _recv(s, recv_buf + sizeof(BIN_PRO_HEAD), len1);
            if(recv_len == len1)
            {/*
                PVE_RESP resp;
                //printf("pve %d\n", thread_idx);
                if(resp.ParseFromArray(recv_buf + sizeof(BIN_PRO_HEAD), recv_len))
                {
                    if(resp.result() == resp.OK)
                    {
                        //int win = resp.fight_rcd().preview().winner();
                        //if(win == 1)
                        //    printf("thread %d: win\n", thread_idx);
                        //else
                        //    printf("thread %d: lose\n", thread_idx);
                    }
                    //else
                        //printf("thread %d: fight fail\n", thread_idx);
                }
                else
                {
                    printf("thread %d: recv %d, %d\n", thread_idx, len1, recv_len);
                }*/
            }
            else
            {
                printf("thread %d: dopve recv2 %d(len1)\n", thread_idx, recv_len, len1);
                return recv_len;
            }
        }
    }
    else
    {
        printf("thread %d: dopve recv1 %d(%d)\n", thread_idx, recv_len, sizeof(BIN_PRO_HEAD));
    }
    return 0;
}

void *working_thread(void *args)
{
    long long tt = reinterpret_cast<long long>(args);
    int t = tt % 10000;
    int statue = 0;
    char *loginbuf = new(std::nothrow) char[MAX_BUF];
    if(loginbuf == NULL)  printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
    int login_len;
    char *pvebuf = new(std::nothrow) char[MAX_BUF];
    if(pvebuf == NULL)  printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
    int pve_len;
    char *recv_buf = new(std::nothrow) char[MAX_BUF * 10];
    if(recv_buf == NULL)  printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
    
    char name[12] = {0};
    sprintf(name, "robot%d", t + 1);
    {
        struct BIN_PRO_HEAD *head = (struct BIN_PRO_HEAD *)((void *)loginbuf);
        format_head(head, name);
        LoginReq req;
        req.set_user_name(name);
        req.set_key("1");
        req.set_server(0);
        req.set_platform(0);
        //printf("%d %s\n", t, req.DebugString().c_str());
        login_len = req.ByteSize() + sizeof(BIN_PRO_HEAD);
        if(!req.SerializeToArray(loginbuf + sizeof(BIN_PRO_HEAD), MAX_BUF - sizeof(BIN_PRO_HEAD)))
        {
            printf("thread %d: login.serialize to array err\n", t);
            return NULL;
        }
        fill_head(head, login_len, 4097);
        //printf("thread %d, login_len = %d\n", t, login_len);
        //printf("%s\n", req.DebugString().c_str());
    }
    {
        struct BIN_PRO_HEAD *head = (struct BIN_PRO_HEAD *)((void *)pvebuf);
        format_head(head, name);
        PVE_REQ req;
        req.set_stage_id(50010001);
        req.set_fortress_id(0);
		req.set_difficulty(1);
        pve_len = req.ByteSize() + sizeof(BIN_PRO_HEAD);
        if(!req.SerializeToArray(pvebuf + sizeof(BIN_PRO_HEAD), MAX_BUF - sizeof(BIN_PRO_HEAD)))
        {
            printf("thread %d: login.serialize to array err\n", t);
            return NULL;
        }
        fill_head(head, pve_len, 4608);
        //printf("%s\n", req.DebugString().c_str());
    }
    int s = -1;
    do{reconnect(s, t);}
    while(s < 0);

    if(do_login(s, loginbuf, login_len, recv_buf, t) == -2)
        statue = 1;//重连
    while(g_run)
    {
        if (statue == 1)
        {
            close(s);
            s = -1;
            do{reconnect(s, t);}
            while(s < 0);
            statue = 0;
            int tr = random()%3;
            sleep(tr);
            continue;
        }
        else
        {
            int tr = random()%100;
            if(tr < 20)
            {
                if(do_login(s, loginbuf, login_len, recv_buf, t) == -2)
                    statue = 1;//重连
            }
            else
            {
                if(do_pve(s, pvebuf, pve_len, recv_buf, t) == -2)
                    statue = 1;//重连
            }
            //tr = random()%2;
            sleep(2);
            continue;
        }
    }
    close(s);
    delete[] recv_buf;
    delete[] pvebuf;
    delete[] loginbuf;
    printf("thread %d: finish\n", t);
    return NULL;
}

void stop(int signo)
{
    g_run = 0;
}

int main()
{
    srandom(time(NULL));
    pthread_t tids[MAX_THREAD];
    pthread_attr_t attr[MAX_THREAD];
        
    signal(SIGINT, stop);
    
    for (int i = 0; i < MAX_THREAD; i++)
    {
        int ret = pthread_attr_init(&attr[i]);
        if(ret != 0)
            return -1;
        ret = pthread_attr_setstacksize(&attr[i], 204800);
        if(ret != 0)
            return -1;
        ret = pthread_create(&tids[i], &attr[i], working_thread, (void *)i);
        if(ret != 0)
        {
            printf("thread %d create error\n", i);
        }
    }
    for(int i = 0; i < MAX_THREAD; i++)
    {
        pthread_join(tids[i], NULL);
        pthread_attr_destroy(&attr[i]);
    }
    
    printf("finish\n");
	return 0;
}