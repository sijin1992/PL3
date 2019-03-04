#include "mysql_table_wrapper.h"
#include "log/log.h"

CTableSelectResult::CTableSelectResult()
{
	reset();
}

CTableSelectResult::~CTableSelectResult()
{
	reset();
}

void CTableSelectResult::reset()
{
	mOffset = 0;
	ProtoEntryVector::iterator it = mEntries.begin();
	while( it != mEntries.end() )
	{
		ProtoEntry *pEntry = *it;
		delete pEntry;
		it++;
	}
	mEntries.clear();
}

bool CTableSelectResult::hasNextEntry()
{
	return mOffset < (int)mEntries.size();
}

bool CTableSelectResult::nextEntry(ProtoEntry &entry)
{
	if( !hasNextEntry() )
	{
		return false;
	}
	entry.CopyFrom(*mEntries[mOffset++]);
	return true;
}

void CTableSelectResult::addEntry(ProtoEntry *pEntry)
{
	mEntries.push_back(pEntry);
}

string CMysqlInsert::makeSqlByChip(const string &tableName, const ChipNameVector &chipNames, const ChipDataVector &chipDatas)
{
	int nameCount = (int)chipNames.size();
	int dataCount = (int)chipDatas.size();
	if( nameCount != dataCount )
	{
		LOG(LOG_DEBUG, "chipNames.size:%d!= chipDatas.size:%d", nameCount, dataCount);
		return "";
	}
	std::string sql = "insert into " + tableName + " ( ";
	for( int i = 0; i < nameCount; i++ )
	{
		sql += chipNames.at(i);
		if( i != nameCount - 1 )
		{
			sql += " , ";
		}
	}
	sql += " ) values ( ";
	for( int i = 0; i < dataCount; i++ )
	{
		sql += "'";
		sql += chipDatas.at(i);
		sql += "'";
		if( i != nameCount - 1 )
		{
			sql += " , ";
		}
	}
	sql += " ); ";

	return sql;
}

