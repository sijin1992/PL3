#ifndef __URL_CODING_H__
#define __URL_CODING_H__

#include <string>

using namespace std;

/*! 
	\file url_coding.h
	\brief c++实现js中的escape和unescape函数

	RFC 1738 "...Only alphanumerics [0-9a-zA-Z], the special characters "$-_.+!*'()," [not including the quotes - ed], and reserved characters used for their reserved purposes may be used unencoded within a URL."

*/

class CUrlCoding
{
public:
/*!
	\fn  string escape(std::string input)
	\brief encode any characters not alphanum to %XX, like javascript EncodeURICompenent
	
	\param input string to escape
	\param use_unicode if true then encode char > 127 and the next to %uXXXX
	\return the escaped string
*/
	static string escape(std::string const& input, bool use_unicode=false);

/*!
	\fn  string unescape(std::string input)
	\brief decode %XX to characters，unescape %uXXXX to unicode characters
	
	\param input string to unescape
	\return the unescaped string
*/
	static string unescape(std::string const& input);

protected:
	static inline char HexCharVal(char c);
};

#endif

