#ifndef __MYSQL_TABLE_WRAPPER_H__
#define __MYSQL_TABLE_WRAPPER_H__

#include <iostream>
#include <string.h>
#include <sstream>
#include "ini/ini_file.h"
#include "proto/logoutReq.pb.h"

using namespace std;

typedef ::google::protobuf::Message ProtoEntry;

typedef vector<ProtoEntry*> ProtoEntryVector;


class CTableSelectResult
{
public:
	CTableSelectResult();
	~CTableSelectResult();
	void reset();
	bool hasNextEntry();
	bool nextEntry(ProtoEntry &entry);
	void addEntry(ProtoEntry *pEntry);
protected:
	ProtoEntryVector mEntries;
	int mOffset;
};

typedef vector<string> ChipNameVector;
typedef vector<string> ChipDataVector;
class CMysqlEntry
{
public:
	CMysqlEntry(ProtoEntry &entry):mEntry(entry){}
	virtual ~CMysqlEntry(){}
	virtual int fillEntryChip(const string &chipName, const string &chipData) = 0;
	ProtoEntry &getEntry(){ return mEntry; }
	virtual int getChipNameVector(ChipNameVector &names) = 0;
	virtual int getChipDataVector(ChipDataVector &datas) = 0;
protected:
	ProtoEntry &mEntry;
};

class CMysqlSelect
{
public:
	virtual ~CMysqlSelect(){}
	virtual string getSql() const{ return ""; }
};

class CMysqlInsert
{
public:
	virtual ~CMysqlInsert(){}
	virtual string makeSql(ProtoEntry &entry){ return ""; }
	static string makeSqlByChip(const string &tableName, const ChipNameVector &chipNames, const ChipDataVector &chipDatas);
};

class CMysqlUpdate
{
public:
	virtual ~CMysqlUpdate(){}
	virtual string makeSql(ProtoEntry &entry){ return ""; }
};

enum TableType
{
	TT_LogDeposit,
	TT_LogBindInfo,
	TT_LogBattleCheat,
	TT_LogMarketSell,
	TT_LogUserInfo,
	TT_LogIssueInfo,
};

class CMysqlTableWrapper
{
public:
	CMysqlTableWrapper(TableType tt){ mTableType = tt; }
	inline TableType getTableType(){ return mTableType; }
	virtual ~CMysqlTableWrapper(){}
	virtual int init() = 0;
	virtual int update(time_t nowTime) = 0;
	virtual int tableSelect(CTableSelectResult &result, CMysqlSelect &select ) = 0;
	virtual int tableInsert(ProtoEntryVector &entries, CMysqlInsert &insert ) = 0;
	virtual int tableUpdate(ProtoEntryVector &entries, CMysqlUpdate &update ) = 0;
protected:
	TableType mTableType;
};

#endif 

