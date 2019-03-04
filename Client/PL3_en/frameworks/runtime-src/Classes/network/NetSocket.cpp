/*
 NetSocket.h: interface for the NetSocket class.
 */


#include "NetSocket.h"
#include "stdio.h"


#ifdef WIN32  
#include <fstream>
#pragma comment(lib, "wsock32") 

#else
#include <sys/uio.h>
#include <fstream>

#include <unistd.h>
#include <fcntl.h>
#endif  


NetSocket::NetSocket(SOCKET sock)  
{  
    m_socket = sock;  
}  

NetSocket::~NetSocket()  
{
    
    Close();
}  

NetSocket& NetSocket::operator = (SOCKET s)  
{  
    m_socket = s;  
    return (*this);  
}  

NetSocket::operator SOCKET ()  
{  
    return m_socket;  
}  


bool NetSocket::Initialize(int protocol){
    
    if (!_NetStartUp(1,1))
        return false;
    
    if (protocol == NETWORK_PROTOCOL_UDP){
        
        m_socket = socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP);
        
    }else{
        
        m_socket = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
    }
    
    if(m_socket == INVALID_SOCKET)
    {
        return false;
    }
    SetNonBlocking();
    
#if defined(CC_TARGET_OS_IPHONE)
    int set = 1;
    setsockopt(m_socket, SOL_SOCKET, SO_NOSIGPIPE, (void*)&set, sizeof(int));
#endif
    return true;
}

bool NetSocket::SetNonBlocking()
{
    /* set to nonblocking mode */
    u_long arg;
    arg = 1;
    int ret;
    ret = IOCTLSOCKET(m_socket,FIONBIO,&arg);
    if (ret == SOCKET_ERROR)
    {
        printf("SetNonBlocking Failed,IOCTLSOCKET = %d\n",ret);
        return false;
    }
    else
    {
        return true;
    }
}


bool NetSocket::CanRead()
{
    fd_set readfds;
    timeval timeout;
    
    timeout.tv_sec=0;
    timeout.tv_usec=0;
    FD_ZERO(&readfds);
    FD_SET(m_socket,&readfds);
    int ret = select(FD_SETSIZE,&readfds,NULL,NULL,&timeout);
    if(ret > 0 && FD_ISSET(m_socket,&readfds))
        return true;
    else
        return false;
}

bool NetSocket::CanWrite()
{
    fd_set writefds;
    timeval timeout;
    
    timeout.tv_sec=0;
    timeout.tv_usec=0;
    FD_ZERO(&writefds);
    FD_SET(m_socket,&writefds);
    int ret = select(FD_SETSIZE,NULL,&writefds,NULL,&timeout);
    if(ret > 0 && FD_ISSET(m_socket,&writefds))
        return true;
    else 
        return false;
}

bool NetSocket::HasExcept()
{
    fd_set exceptfds;
    timeval timeout;
    
    timeout.tv_sec=0;
    timeout.tv_usec=0;
    FD_ZERO(&exceptfds);
    FD_SET(m_socket,&exceptfds);
    int ret = select(FD_SETSIZE,NULL,NULL,&exceptfds,&timeout);
    if(ret > 0 && FD_ISSET(m_socket,&exceptfds))
        return true;
    else 
        return false;
}

int NetSocket::ConnectNonb(const struct sockaddr *saptr, socklen_t salen, int nsec)
{
    int flags, n, error;
    socklen_t   len;
    fd_set  rset, wset;
    struct timeval  tval;

#ifndef WIN32  
    flags = fcntl(m_socket, F_GETFL, 0);
    fcntl(m_socket, F_SETFL, flags | O_NONBLOCK);
#endif
    
    error = 0;
    if ((n = connect(m_socket, (struct sockaddr *) saptr, salen)) < 0) {
        if (errno != EINPROGRESS) {
            goto done;
        }
    }
    /* Do whatever we want while the connect is taking place. */
    if (n == 0)
        goto done;    /* connect completed immediately */
    
    FD_ZERO(&rset);
    FD_SET(m_socket, &rset);
    wset = rset;
    tval.tv_sec = nsec;
    tval.tv_usec = 0;
    
    if ( (n = select(m_socket+1, &rset, &wset, NULL, nsec ? &tval : NULL)) == 0) {
		Close();        /* timeout */
        errno = ETIMEDOUT;
        goto done;
    }
    
    if (FD_ISSET(m_socket, &rset) || FD_ISSET(m_socket, &wset)) {
        len = sizeof(error);
        if (getsockopt(m_socket, SOL_SOCKET, SO_ERROR, (char*)&error, &len) < 0) {
            goto done;            /* Solaris pending error */
        }
    } else{
        printf("error:connect_nonb");
    }
    
done:
#ifndef WIN32 
    fcntl(m_socket, F_SETFL, flags);    /* restore file status flags */
#endif
    if (error) {
		Close();        /* just in case */
        errno = error;
        return(-1);
    }
    return(0);
}


int NetSocket::TcpConnect(const char*ip, int port, int sec)
{
    int ret;
    
    char strIP[100];
    
    sprintf(strIP,"%s",ip);
    
    char strPort[100];
    sprintf(strPort,"%d",port);
    
    struct addrinfo *ailist, *aip;
    struct addrinfo hint;
    struct sockaddr_in *sinp;

    int err;
    char seraddr[INET_ADDRSTRLEN];
    short serport;
    
    hint.ai_family = 0;
    hint.ai_socktype = SOCK_STREAM;
    hint.ai_flags = AI_CANONNAME;
    hint.ai_protocol = 0;
    hint.ai_addrlen = 0;
    hint.ai_addr = NULL;
    hint.ai_canonname = NULL;
    hint.ai_next = NULL;
    if ((err = getaddrinfo(strIP, strPort, &hint, &ailist)) != 0) {
        printf("getaddrinfo error: %s\n", gai_strerror(err));
        return SOCKET_ERROR;
    }
    bool isConnectOk = false;
    printf("getaddrinfo ok\n");
    for (aip = ailist; aip != NULL; aip = aip->ai_next) {
        
        sinp = (struct sockaddr_in *)aip->ai_addr;
        if (inet_ntop(sinp->sin_family, &sinp->sin_addr, seraddr, INET_ADDRSTRLEN) != NULL)
        {
            printf("server address is %s\n", seraddr);
        }
        serport = ntohs(sinp->sin_port);
        printf("server port is %d\n", serport);
        if ((m_socket = socket(aip->ai_family, SOCK_STREAM, 0)) < 0) {
            printf("create socket failed: %s\n", strerror(errno));
            isConnectOk = false;
            continue;
        }
        printf("create socket ok\n");
        if (aip->ai_addr->sa_family == AF_INET) {
            ret = ConnectNonb(aip->ai_addr, sizeof(struct sockaddr_in), sec);
        }else if(aip->ai_addr->sa_family == AF_INET6){
            ret = ConnectNonb(aip->ai_addr, sizeof(struct sockaddr_in6), sec);
        }

        if(ret < 0){
            printf("can't connect to %s: %s\n", strIP, strerror(errno));
            isConnectOk = false;
            continue;
        }
        isConnectOk = true;
        break;
    }
    freeaddrinfo(ailist);
    
    if (isConnectOk) {
        return 0;
    }
    return SOCKET_ERROR;
}


bool NetSocket::Connect(const char* ip, unsigned short port)  
{

//    struct sockaddr_in svraddr;
//    svraddr.sin_family = AF_INET;  
//    svraddr.sin_addr.s_addr = inet_addr(ip);  
//    svraddr.sin_port = htons(port);  
//    int ret = connect(m_socket, (struct sockaddr*)&svraddr, sizeof(svraddr));
    int ret = TcpConnect(ip, port, 10);
    if ( ret == SOCKET_ERROR ) {
        int err = GETERROR;
        if (err != CONN_INPRROGRESS)
        {
            printf("Socket connect error = %d\n",err);
            return false;
        }
    }
#ifndef WIN32
    signal(SIGPIPE, SIG_IGN);
#endif

    return true;
}

bool NetSocket::SetReuseAddr(bool reuse)
{
#ifndef WIN32
    /* only useful in linux */
    int opt = 0;
    unsigned int len = sizeof(opt);
    
    if(reuse) opt = 1;
    if(setsockopt(m_socket,SOL_SOCKET,SO_REUSEADDR,
                  (const void*)&opt,len)==SOCKET_ERROR)
    {
        return false;
    }
    else
    {
        return true;
    }
#endif
    return true;
}

bool NetSocket::Bind(const char *ip,unsigned short port)
{  
    SOCKADDR_IN addrLocal;
    addrLocal.sin_family=AF_INET;
    addrLocal.sin_port=htons(port);
    if(ip && strcmp(ip,"localhost")!=0)
    {
        addrLocal.sin_addr.s_addr=inet_addr(ip);
    }
    else
    {
        addrLocal.sin_addr.s_addr=htonl(INADDR_ANY);
    }
    
    
    if(bind(m_socket,(SOCKADDR *)&addrLocal,sizeof(addrLocal))==SOCKET_ERROR)
    {
        printf("Bind socket error\n");
        return false;
    }
    return true;
}  
//for server  
bool NetSocket::Listen(int backlog)  
{  
    int ret = listen(m_socket, backlog);  
    if ( ret == SOCKET_ERROR ) {  
        return false;  
    }  
    return true;  
}  

bool NetSocket::Accept(NetSocket& s, char* fromip)  
{  
    struct sockaddr_in cliaddr;  
    socklen_t addrlen = sizeof(cliaddr);  
    SOCKET sock = accept(m_socket, (struct sockaddr*)&cliaddr, &addrlen);  
    if ( sock == SOCKET_ERROR ) {  
        return false;  
    }  
    
    s = sock;  
    if ( fromip != NULL )  
        sprintf(fromip, "%s", inet_ntoa(cliaddr.sin_addr));  
    
    return true;  
}  



/*
 * return value
 * =  0 send failed
 * >  0	bytes send
 * = -1 net dead
 */
int NetSocket::Send(const char* buf, int len, int flags)  
{
    if (!CanWrite()) return 0;
    
    int ret;
    /*
     in linux be careful of SIGPIPE
     */
    ret = send(m_socket,buf,len,flags);
    if (ret==SOCKET_ERROR)
    {
        int err=GETERROR;
        if (err==WSAEWOULDBLOCK) return 0;
        return -1;
    }
    return ret;
}  

/*
 * return value
 * =  0 recv failed
 * >  0	bytes recv
 * = -1 net dead
 */
int NetSocket::Recv(char* buf, int len, int flags)  
{  
    if (CanRead()==false)
        return 0;
    
    int ret;
    /* in linux be careful of SIGPIPE */
    ret = recv(m_socket,buf,len,flags);
    
    if (ret==0)
    {
        /* remote closed */
        return -1;
    }
    
    if (ret==SOCKET_ERROR)
    {
        int err=GETERROR;
        if (err!=WSAEWOULDBLOCK)
        {
            return -1;
        }
    }
    return ret;
}


unsigned long NetSocket::Readv(VBuff * vbuffs, int count) {

	if (!CanRead()) {
		return 0;
	}
	int ret = 0;
	unsigned long recvLen = 0;

#ifdef WIN32
	WSABUF vec[2];
	vec[0].buf = vbuffs[0].buff;
	vec[0].len = vbuffs[0].len;
	vec[1].buf = vbuffs[1].buff;
	vec[1].len = vbuffs[1].len;

	unsigned long flags = 0;
	ret = WSARecv(m_socket, vec, count, &recvLen, &flags, NULL, NULL);
#else

	struct iovec vec[2];
	vec[0].iov_base = vbuffs[0].buff;
	vec[0].iov_len = vbuffs[0].len;
	vec[1].iov_base = vbuffs[1].buff;
	vec[1].iov_len = vbuffs[1].len;

	ret = ::readv(m_socket, vec, count);
	if (ret == 0)
	{
		/* remote closed */
		printf("remote closed!\n");
		return -1;
	}
    recvLen = ret;
#endif

	

	if (ret == SOCKET_ERROR)
	{
		int err = GETERROR;
		if (err != WSAEWOULDBLOCK)
		{
			return -1;
		}
	}

	return recvLen;
}




void NetSocket::Reset()
{
    m_socket = INVALID_SOCKET;
}

bool NetSocket::Close()
{
    if (m_socket == INVALID_SOCKET)
        return false;
	CLOSESOCKET(m_socket);
    

	int ret = 0;
	int times = 3;
	if (m_socket >= 0)
	{
		while (times--)
		{
			if ((ret = CLOSESOCKET(m_socket)) == 0 || errno != EINTR)
				break;
		}
	}

	if (ret < 0) {
#ifdef WIN32
		printf("socket close fail %d", errno);
#else
		printf("socket close fail %d(%s)", errno, hstrerror(errno));
#endif
	}
	else {
		Reset();
	}


    
    
    
    _NetCleanUp();
    return true;
}  

int NetSocket::GetError()  
{  
#ifdef WIN32  
    return (WSAGetLastError());  
#else  
    return (errno);  
#endif  
}  

bool NetSocket::DnsParse(const char* domain, char* ip)  
{  
    struct hostent* p;  
    if ( (p = gethostbyname(domain)) == NULL )  
        return false;  
    
    sprintf(ip,   
            "%u.%u.%u.%u",  
            (unsigned char)p->h_addr_list[0][0],   
            (unsigned char)p->h_addr_list[0][1],   
            (unsigned char)p->h_addr_list[0][2],   
            (unsigned char)p->h_addr_list[0][3]);  
    
    return true;  
} 

bool NetSocket::_NetStartUp(int VersionHigh,int VersionLow)
{
#ifdef WIN32
    WORD wVersionRequested;
    WSADATA wsaData;
    int err;
    
    wVersionRequested = MAKEWORD(VersionHigh,VersionLow);
    err=WSAStartup(wVersionRequested, &wsaData);
    
    /* startup failed */
    if (err!=0)
    {
		printf("WSAStartup error");
        WSACleanup();
        return false;
    }
    
    /* version error */
    if (LOBYTE(wsaData.wVersion)!= VersionLow ||
        HIBYTE(wsaData.wVersion)!= VersionHigh )
    {
		printf("WSAStartup version error");
        WSACleanup();
        return false;
    }
	printf("WSAStartup ok");
#endif
    return true;
}

bool NetSocket::_NetCleanUp()
{
#ifdef WIN32
    WSACleanup();
	printf("WSACleanup ok");
#endif
    return true;
}
