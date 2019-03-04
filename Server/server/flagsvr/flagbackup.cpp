/*
* 通过读写二进制文件备份和恢复flag shm数据
* 
*/
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h> 
#include <string.h>
#include "flag_svr_def.h"
#include <string>
#include "ini/ini_file.h"
#include <errno.h>
#include <dirent.h>
#include <stdlib.h>

using namespace std;
CShmHashMap<FLAG_SERVER_UNIT, USER_NAME_BYTE, UserByteHashType> gFlagMap;

#define BACKUP_FLAG_MAX_DATA_PER_FILE 1024*1024*1024
#define BACKUP_FILE_MAGIC_HEAD_STR "FLAG_BACKUP\n"
#define BACKUP_FILE_MAGIC_HEAD_LEN 16
#define BACKUP_FILE_PRE "flagbackup"

int gWriteSpeedPerSec;
int gOnlyShow=0;

//写文件的上下文
int seq = 0;
int bytecount = 0;
int fd = -1;
int writecount = 0;
int outputcount = 0;

int check_dir(const char* path)
{
	struct stat statbuf;
	int ret = stat(path, &statbuf);
	if(ret != 0)
	{
		if(errno == ENOENT)
		{
			//mkdir
			ret = mkdir(path, 0777);
			if(ret != 0)
			{
				cout << "mkdir=" << errno << " " << strerror(errno) << endl;
				return -1;
			}
		}
		else
		{
			cout << "stat=" << errno << " " << strerror(errno) << endl;
			return -1;
		}
	}
	else
	{
		if(!S_ISDIR(statbuf.st_mode))
		{
			cout << path << " not dir" << endl;
			return -1;
		}
	}

	return 0;
}

int writebytes(const char* dir, const char* data, int datalen)
{	
	if(fd < 0 || bytecount+datalen > BACKUP_FLAG_MAX_DATA_PER_FILE)
	{
		char sfile[1024] = {0};
		if(fd < 0)
		{
			cout << "fd < 0 so open "BACKUP_FILE_PRE"."<< seq << endl;
			seq = 0;
		}
		else
		{
			close(fd);
			++seq;
			cout << "bytecount(" << bytecount << ") + datalen(" << datalen << ") > " 
				<< BACKUP_FLAG_MAX_DATA_PER_FILE << " open "BACKUP_FILE_PRE"." << seq << endl;
		}
		
		snprintf(sfile, sizeof(sfile), "%s/"BACKUP_FILE_PRE".%d", dir, seq);
		
		fd = open(sfile, O_WRONLY | O_CREAT| O_TRUNC, 0666);
		if(fd < 0)
		{
			cout << "open file "<< sfile << " for write fail " << errno << " " << strerror(errno) << endl; 
			LOG(LOG_ERROR, "open file %s for write fail %d(%s)", sfile, errno, strerror(errno));
			return -1;
		}

		//write magic head
		char head[BACKUP_FILE_MAGIC_HEAD_LEN] = {0};
		snprintf(head, sizeof(head), "%s", BACKUP_FILE_MAGIC_HEAD_STR);
		if(write(fd, head, sizeof(head))<0)
		{
			cout << "write " << sizeof(head) << " bytes to "<< sfile << " fail " << errno << " " << strerror(errno) << endl; 
			LOG(LOG_ERROR, "write %lu bytes to %s  fail %d(%s)", sizeof(head), sfile, errno, strerror(errno));
		}
	}

	if(++writecount > gWriteSpeedPerSec/100) //10ms一个单位
	{
		writecount = 0;
		usleep(10000);
	}

	if(write(fd, data, datalen) < 0)
	{
		cout << "write " << datalen << " bytes fail " << errno << " " << strerror(errno) << endl; 
		LOG(LOG_ERROR, "write %d bytes  fail %d(%s)", datalen, errno, strerror(errno));
		return -1;
	}
	
	bytecount+=datalen;
	
	return 0;}

int readfile(const char* pdir, const char* sfilename)
{	char sfile[1024];
	snprintf(sfile, sizeof(sfile), "%s/%s", pdir, sfilename);
	int readfd = open(sfile, O_RDONLY);
	if(readfd < 0)
	{
		cout << "open file "<< sfile << " for read fail " << errno << " " << strerror(errno) << endl; 
		LOG(LOG_ERROR, "open file %s for read fail %d(%s)", sfile, errno, strerror(errno));
		return -1;
	}

	char headbuff[BACKUP_FILE_MAGIC_HEAD_LEN]={0};
	int readlen = read(readfd, headbuff, sizeof(headbuff));
	if(readlen < 0)
	{
		cout << "read " << sizeof(headbuff) << " bytes from "<< sfile << " fail " << errno << " " << strerror(errno) << endl; 
		LOG(LOG_ERROR, "read %lu bytes from %s  fail %d(%s)", sizeof(headbuff), sfile, errno, strerror(errno));
		close(readfd);
		return -1;
	}
	else if(readlen != sizeof(headbuff))
	{
		cout << "read " << sizeof(headbuff) << " bytes from "<< sfile << " but only get " << readlen << endl;
		LOG(LOG_ERROR, "read %lu bytes from %s  but only get %d", sizeof(headbuff), sfile, readlen);
		close(readfd);
		return -1;
	}

	if(strncmp(headbuff, BACKUP_FILE_MAGIC_HEAD_STR, sizeof(headbuff))!=0)
	{		cout << "file head is not " << BACKUP_FILE_MAGIC_HEAD_STR;
		LOG(LOG_ERROR, "file head is not %s", BACKUP_FILE_MAGIC_HEAD_STR);
		close(readfd);
		return -1;
	}

	char databuff[sizeof(USER_NAME_BYTE)+sizeof(FLAG_SERVER_UNIT)];
	USER_NAME_BYTE tmpuser;
	FLAG_SERVER_UNIT tmpunit;
	int inputcount=0;
	bool fail = false;
	while(true)
	{
		readlen = read(readfd, databuff, sizeof(databuff));
		if(readlen < 0)
		{
			cout << "read " << sizeof(headbuff) << " bytes from "<< sfile << " fail " << errno << " " << strerror(errno) << endl; 
			LOG(LOG_ERROR, "read %lu bytes from %s  fail %d(%s)", sizeof(databuff), sfile, errno, strerror(errno));
			fail = true;
			break;
		}
		else if(readlen == 0)
		{
			break;
		}
		else if(readlen != sizeof(databuff))
		{
			cout << "read " << sizeof(headbuff) << " bytes from "<< sfile << " but only get " << readlen << endl;
			LOG(LOG_ERROR, "read %lu bytes from %s  but only get %d", sizeof(databuff), sfile, readlen);
			fail=true;
			break;
		}

		memcpy(&tmpuser, databuff, sizeof(tmpuser));
		memcpy(&tmpunit, databuff+sizeof(tmpuser), sizeof(tmpunit));

		if(gOnlyShow)
		{
			USER_NAME username;
			username.frombyte(tmpuser);
			cout << "read user(" << username.str() << ") ";
			cout << "data{level:" << tmpunit.level << ",boxexist:" << (int)tmpunit.boxexist << ",boxlevel:" 
				<< (int)tmpunit.boxlevel << ",boxendtime:" << tmpunit.boxendtime << "}" << endl;
		}
		else
		{
			if(gFlagMap.get_map()->set_node(tmpuser, tmpunit) < 0)
			{
				USER_NAME username;
				username.frombyte(tmpuser);
				cout << "set user(" << username.str() << ") fail " << gFlagMap.get_map()->m_err.errstrmsg << endl;
				LOG(LOG_ERROR, "set user(%s) fail %s", username.str(), gFlagMap.get_map()->m_err.errstrmsg);
				continue;
			}
		}

		inputcount++;
	}

	cout << "read " << sfile << " input count=" << inputcount << " fail=" << fail << endl;
	LOG(LOG_INFO, "read %s input count=%d fail=%d", sfile, inputcount, fail);
	close(readfd);
	if(fail)
		return -1;
	return 0;
}

class CFlagBackupVisitor:public CHashMapVisitor<USER_NAME_BYTE, FLAG_SERVER_UNIT>
{
	public:
		virtual ~CFlagBackupVisitor(){}
		inline void set_dir(const char* cdir)
		{
			dir = cdir;
		}
		
		int call(const TYPE_KEY& key, TYPE_VAL& val, int callTimes)
		{
			outputcount = callTimes;
			memcpy(buff, &key, sizeof(key));
			memcpy(buff+sizeof(key), &val, sizeof(val));
			
			if(gOnlyShow)
			{
				USER_NAME username;
				username.frombyte(key);
				cout << "write user(" << username.str() << ") ";
				cout << "data{level:" << val.level << ",boxexist:" << (int)val.boxexist << ",boxlevel:" 
					<< (int)val.boxlevel << ",boxendtime:" << val.boxendtime << "}" << endl;
				return 0;
			}
			else
			{
				return writebytes(dir.c_str(), buff, sizeof(buff));
			}
		}

	public:
		string dir;
		char buff[sizeof(TYPE_KEY)+sizeof(TYPE_VAL)];
};

int main(int argc, char** argv)
{
	if(argc < 3)
	{
		cout << argv[0] << " cmd[output|input] configfile [onlycout=0]" << endl;
		return -1;
	}

	
	if(argc > 3)
	{
		gOnlyShow = atoi(argv[3]);
	}

	string cmd = argv[1];

	CIniFile oIni(argv[2]);
	if(!oIni.IsValid())
	{
		cout << "read ini " << argv[2] << "fail" << endl;
		return 0;
	}

	//open log
	LOG_CONFIG logConf(oIni, "BACKUP");
	logConf.debug(cout);
	LOG_CONFIG_SET(logConf);
	cout << "log open=" << LOG_OPEN_DEFAULT(NULL) << " " << LOG_GET_ERRMSGSTRING << endl;

	//backup dir
	char thedir[512] = {0};
	if(oIni.GetString("BACKUP","DIR", "", thedir, sizeof(thedir))!=0)
	{
		cout << "BACKUP.DIR not found" << endl;
		return 0;
	}

	if(oIni.GetInt("BACKUP","WRITE_PER_SECOND", 0, &gWriteSpeedPerSec)!=0)
	{
		cout << "BACKUP.WRITE_PER_SECOND not found" << endl;
		return 0;
	}
	
	if(check_dir(thedir) != 0)
	{
		cout << "check dir " << thedir << " fail" << endl;
		return 0;
	}

	//遍历visitor
	CFlagBackupVisitor visitor;
	visitor.set_dir(thedir);
	
	//不需要强行format
	int ret = gFlagMap.init(oIni, "FLAG_SVR", 0);
	if(ret != 0)
	{
		cout << "gFlagMap.init fail" << endl;
		return 0;
	}


	if(cmd == "output")
	{
		//读出
		ret = gFlagMap.get_map()->for_used_data(&visitor);
		cout << "output ret=" << ret << ", output count=" << outputcount << endl;
		LOG(LOG_INFO, "output ret=%d output count=%d", ret, outputcount);
		if(fd >= 0)
			close(fd);
	}
	else if(cmd == "input")
	{
		DIR* pdir = opendir(thedir);
		if(ret < 0)
		{
			cout << "opendir(" << thedir << ")=" << errno << " " << strerror(errno) << endl;
			return -1;
		}

		while(true)
		{
			struct dirent * p = readdir(pdir);
			if(p == NULL)
			{
				break;
			}

			if(sizeof(p->d_name) < strlen(BACKUP_FILE_PRE) || strncmp(p->d_name, BACKUP_FILE_PRE, strlen(BACKUP_FILE_PRE))!=0)
			{
				cout << "file name: " << p->d_name << " not backup file" << endl;
			}
			else
			{
				cout << "input file " << p->d_name << " to shm" << endl;
				if(readfile(thedir, p->d_name) != 0)
					break;
			}
		}

		closedir(pdir);
	}
	else
	{
		cout << "invalid cmd " << cmd << endl;
	}
	
	return 0;
}

