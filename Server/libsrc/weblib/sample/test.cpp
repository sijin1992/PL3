#include "weball.h"

class TestApp: public webapp
{
private:
	void outputmap(string name, map<string, string>& themap)
	{
		WEBOUT << name << " total " << themap.size() << ":<br>" << endl;
		map<string, string>::iterator  it = themap.begin();   
  		for(; it!=themap.end(); ++it)
		{
			WEBOUT << it->first << "=" << it->second << "<br>" << endl; 
		}
	}

public:
	void head()
	{
		WEBOUT << CHttpRespHead::HtmlHead();
	}

	int process()
	{
		WEBOUT << "run times " << m_iSerialNo << "<br>" << endl;
		outputmap("m_param", m_param);
		outputmap("m_cookie", m_cookie);
		outputmap("m_env", m_env);
		return 0;
	}
};

int main(int argc, char** argv)
{
	TestApp theApp;
	theApp.set_maxno(10000);
	theApp.set_program_name(argv[0]);
	theApp.run();
	return 0;
}

