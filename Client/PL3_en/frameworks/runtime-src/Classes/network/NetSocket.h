/*
 NetSocket.h: interface for the NetSocket class.
 */

#ifndef _NetSocket_H_  
#define _NetSocket_H_  

#ifdef WIN32  
    /*
    for windows
    */
	
	#include <winsock2.h>
	#include <ws2tcpip.h>
	#include<windows.h>
	

    #define GETERROR			WSAGetLastError()
    #define CLOSESOCKET(s)		closesocket(s)
    #define IOCTLSOCKET(s,c,a)  ioctlsocket(s,c,a)
    #define CONN_INPRROGRESS	WSAEWOULDBLOCK
    #ifndef socklen_t			// python already define socklen_t...
        typedef int socklen_t;
    #endif
#else
    /*
	for linux
	*/
    #include <sys/time.h>
    #include <stddef.h>
    #include <unistd.h>
    #include <stdlib.h>
    #include <sys/wait.h>

    #include <sys/socket.h>
    #include <netinet/in.h>  
    #include <sys/ioctl.h>
    #include <netdb.h> 
    #include <sys/errno.h>
    //#include <fcntl.h>
    //#include <sys/stat.h>
    //#include <sys/types.h>
    #include <arpa/inet.h>  

    typedef int SOCKET;
    typedef sockaddr_in			SOCKADDR_IN;
    typedef sockaddr			SOCKADDR;
    #define INVALID_SOCKET	    (-1)
    #define SOCKET_ERROR        (-1)
    #define GETERROR			errno
    #define WSAEWOULDBLOCK		EWOULDBLOCK
    #define CLOSESOCKET(s)		shutdown(s, SHUT_RDWR)
    #define IOCTLSOCKET(s,c,a)  ioctl(s,c,a)
    #define CONN_INPRROGRESS	EINPROGRESS
#endif

const int NETWORK_PROTOCOL_UDP	=	1;
const int NETWORK_PROTOCOL_TCP	=	2;

class NetSocket {
    
public:  
    NetSocket(SOCKET sock = INVALID_SOCKET);  
    ~NetSocket();  
    
    bool Initialize(int protocol = 0);
    
    bool SetNonBlocking();
    
    bool CanRead();
    bool CanWrite();
    bool HasExcept();
    
    // Connect socket  
    bool Connect(const char* ip, unsigned short port);  
//#region server
    
    bool SetReuseAddr(bool reuse);
    
    // Bind socket  
    bool Bind(const char *ip,unsigned short port);
    
    // Listen socket  
    bool Listen(int backlog = 5);   
    
    // Accept socket  
    bool Accept(NetSocket& s, char* fromip = NULL);  
//#endregion  
    
    // Send socket  
    int Send(const char* buf, int len, int flags = 0);  
    
    // Recv socket  
    int Recv(char* buf, int len, int flags = 0);

	struct VBuff {
		char * buff;
		unsigned long len;
	};

	unsigned long Readv(VBuff * vbuffs, int count);

    void Reset();
    
    // Close socket  
    bool Close();
    
    // Get errno  
    int GetError();
    
    // Domain parse  
    static bool DnsParse(const char* domain, char* ip);  
    
    NetSocket& operator = (SOCKET s);  
    
    operator SOCKET ();
    
    int ConnectNonb(const struct sockaddr *saptr, socklen_t salen, int nsec);
    int TcpConnect(const char*ip, int port, int sec);
private:
    bool _NetStartUp(int VersionHigh,int VersionLow);
    bool _NetCleanUp();
    
    SOCKET m_socket;
    
};  

#endif  
