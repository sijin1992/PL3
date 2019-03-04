#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "tinyxml2.h"
using namespace tinyxml2;
#define MAX_NAME_LEN 32
#define MAX_BUF 1024

#define TOUPPER(args...) \
    snprintf(temp_buf, MAX_BUF, ##args);\
    toupper(temp_buf)
    
#define WRITEFILE(args...) \
    snprintf(g_buf, MAX_BUF, ##args);\
    fputs(g_buf, out)

const char *g_module_name;
char g_config_name[MAX_NAME_LEN];
char g_buf[MAX_BUF];

struct idx_struct
{
    int id;
    int width;
};
idx_struct *g_idx_struct;       // idx分析结构
int g_idx_struct_len = 0;

enum
{
    INT = 0,
    STRING = 1,
};
struct field_struct
{
    char name[32];
    int data_type;
    int num;        // 单项为1,复合项为最大数
};
field_struct *g_field_struct;   // 列分析结构
int g_field_num = 0;

int g_row_num = 0;              // 配置行总数

bool g_need_cut = true;         // 是否需要分割','隔开的字符串

bool is_int(char *str, size_t len)
{
    for(size_t i = 0; i < len; ++i)
    {
        if(str[i] < '0' || str[i] > '9')
            return false;
    }
    return true;
}

int get_sub_num(char *str, size_t len, char **tag)
{
    int num = 1;
    tag[0] = str;
    for(size_t i = 0; i < len; ++i)
    {
        if(str[i] == ',')
        {
            tag[num] = &str[i + 1];
            num++;
            str[i] = 0;
        }
    }
    return num;
}

// 分析id列构成
int parse_idx_struct(const char *idx_format)
{
    size_t len = strlen(idx_format);
    for(int i = 0; i < len; ++i)
    {
        if(idx_format[i] >= 'a' && idx_format[i] < 'z')
        g_idx_struct_len ++;
    }
    g_idx_struct = (idx_struct *)malloc(sizeof(idx_struct) * g_idx_struct_len);
    int t = 0;
    g_idx_struct[t].width = 0;
    for(int i = 0; i < len; ++i)
    {
        if(idx_format[i] >= 'a' && idx_format[i] < 'z')
        {
            g_idx_struct[t].id = idx_format[i] - 'a';
            t++;
        }
        else
        {
            g_idx_struct[t].width = idx_format[i] - '0';
        }
    }
    int total_width = 0;
    for(int i = g_idx_struct_len - 1; i >= 0; --i)
    {
        t = 1;
        for(int j = 0; j < total_width; ++j)
            t *= 10;
        total_width += g_idx_struct[i].width;
        g_idx_struct[i].width = t;
    }
    return 0;
}

// 分析列信息，得到列名，列类型等信息
int parse_field_struct(XMLElement *row)
{
    XMLElement *field = row->FirstChildElement();
    while(field)
    {
        g_field_num++;
        field = field->NextSiblingElement();
    }
    g_field_struct = (field_struct *)malloc(sizeof(field_struct) * g_field_num);
    field = row->FirstChildElement();
    int i = 0;
    char buf[MAX_BUF];
    while(field)
    {
        snprintf(g_field_struct[i].name, 32, field->Name());
        strncpy(buf, field->GetText(), MAX_BUF - 1);
        buf[MAX_BUF - 1] = 0;
        if(is_int(buf, strlen(buf)))
        {
            g_field_struct[i].data_type = INT;
            g_field_struct[i].num = 1;
        }
        else
        {
            if(g_need_cut)
            {
                char *t[300];
                int n = get_sub_num(buf, strlen(buf), t);
                if (n == 1)
                {
                    g_field_struct[i].data_type = STRING;
                    g_field_struct[i].num = 1;
                }
                else
                {
                    g_field_struct[i].data_type = INT;
                    g_field_struct[i].num = n;
                }
            }
            else
            {
                g_field_struct[i].data_type = STRING;
                g_field_struct[i].num = 1;
            }
        }
        ++i;
        field = field->NextSiblingElement();
    }
    
    // 然后从第二行开始，逐行验证数据结构
    row = row->NextSiblingElement();
    while(row)
    {
        field = row->FirstChildElement();
        int i = 0;
        while(field)
        {
            strncpy(buf, field->GetText(), MAX_BUF - 1);
            buf[MAX_BUF - 1] = 0;
            if(!is_int(buf, strlen(buf)))
            {
                if(g_need_cut)
                {
                    char *t[300];
                    int n = get_sub_num(buf, strlen(buf), t);
                    if (n == 1)
                    {
                        if(g_field_struct[i].data_type == INT && g_field_struct[i].num == 1)
                        {
                            g_field_struct[i].data_type = STRING;
                            g_field_struct[i].num = 1;
                        }
                    }
                    else
                    {
                        if(g_field_struct[i].data_type == INT && g_field_struct[i].num > 1)
                        {
                            g_field_struct[i].num = g_field_struct[i].num > n ?g_field_struct[i].num:n;
                        }
                        else
                        {
                            g_field_struct[i].data_type = INT;
                            g_field_struct[i].num = n;
                        }
                    }
                }
                else
                {
                    g_field_struct[i].data_type = STRING;
                    g_field_struct[i].num = 1;
                }
            }
            ++i;
            field = field->NextSiblingElement();
        }
        row = row->NextSiblingElement();
    }
    
    for(int i = 0; i < g_field_num; ++i)
    {
        printf("%d: %s %s %d\n",i + 1, g_field_struct[i].name, g_field_struct[i].data_type == STRING?"str":"int", g_field_struct[i].num);
    }
    return 0;
}

// 写入一行配置数据
int write_one_row(FILE *out, XMLElement *row, int row_idx)
{
    XMLElement *field = row->FirstChildElement();
    // 生成id
    int id = 0;
    int j = 0;      // field 索引标识
    int temp = 0;
    int k = 0;      // 处理了几项idx_struct
    while(field)
    {
        for(int i = 0; i < g_idx_struct_len; i++)
        {
            if(g_idx_struct[i].id == j)
            {
                if(field->QueryIntText(&temp) == XML_SUCCESS)
                {
                    id += temp * g_idx_struct[i].width;
                    j++;
                    break;
                }
                else
                    return -1;
            }
        }
        if(j == g_idx_struct_len)
            break;
        j++;
        field = field->NextSiblingElement();
    }
    
    char value[MAX_BUF];
    
    WRITEFILE("%s[\"index\"][%d] = %d\n", g_config_name, row_idx, id);
    WRITEFILE("%s[%d] = {}\n", g_config_name, id);
    field = row->FirstChildElement();
    j = 0;
    while(field)
    {
        if(g_field_struct[j].data_type == INT)
        {
            if(g_field_struct[j].num == 1)
            {
                if(field->QueryIntText(&temp) == XML_SUCCESS)
                    snprintf(value, MAX_BUF, "%s", field->GetText());
                else
                    return -1;
                WRITEFILE("\t%s[%d][\"%s\"] = %s\n", g_config_name, id,
                    field->Name(), value);
            }
            else
            {
                char *t[300];
                strncpy(value, field->GetText(), MAX_BUF - 1);
                value[MAX_BUF - 1] = 0;
                int n = get_sub_num(value, MAX_BUF, t);
                if(n > g_field_struct[j].num)
                    g_field_struct[j].num = n;
                WRITEFILE("\t%s[%d][\"%s\"] = {}\n", g_config_name, id, field->Name());
                for(int i = 0; i < n; ++i)
                {
                    WRITEFILE("\t\t%s[%d][\"%s\"][%d] = %d\n", g_config_name, id,
                        field->Name(), i + 1, atoi(t[i]));
                }
            }
        }
        else
        {
            WRITEFILE("\t%s[%d][\"%s\"] = \"%s\"\n", g_config_name, id,
                field->Name(), field->GetText());
        }
        
        
        j++;
        field = field->NextSiblingElement();
    }
    WRITEFILE("\t%s[%d][\"real_idx\"] = %d\n\n", g_config_name, id, row_idx);
    return 0;
}

int write_lua_file(FILE *out, XMLElement *root)
{
    XMLElement *row = root;
    
    WRITEFILE("%s = {}\n%s[\"index\"] = {}\n", g_config_name, g_config_name);
    while(row)
    {
        ++g_row_num;
        if(write_one_row(out, row, g_row_num) != 0)
        {
            return -1;
        }
        row = row->NextSiblingElement();
    }
    WRITEFILE("\n%s[\"len\"] = %d\n", g_config_name, g_row_num);
    //function *.get_data_by_idx()
    WRITEFILE("\nfunction %s.get_data_by_idx(i)\n"
        "\tif %s[i] == nil then return nil\n"
        "\telse\n"
        "\t\tlocal temp = \"\"\n", g_config_name, g_config_name);
    for(int i = 0; i < g_field_num; i++)
    {
        if(i > 0)
        {
            WRITEFILE("\t\ttemp = temp..\";\"\n");
        }
        if(g_field_struct[i].num == 1)
        {
            WRITEFILE("\t\ttemp = temp..%s[i].%s\n",g_config_name, g_field_struct[i].name);
        }
        else
        {
            WRITEFILE("\t\tfor k,v in ipairs(%s[i].%s) do temp = temp..v..\",\" end\n", g_config_name, g_field_struct[i].name);
            WRITEFILE("\t\t\ttemp = string.sub(temp, 1, -2)\n");
        }
    }
    WRITEFILE("\t\ttemp = temp..\";\"..%s[i].real_idx\n",g_config_name);
    WRITEFILE("\t\treturn temp\n\tend\nend\n\n");
    //function *.get_data_by_real_idx()
    WRITEFILE("function %s.get_data_by_real_idx(i)\n"
        "\tif %s.index[i] == nil then return nil\n"
        "\telse\n"
        "\t\treturn %s.get_data_by_idx(%s.index[i])\n"
        "\tend\nend\n",
        g_config_name, g_config_name, g_config_name, g_config_name);
    return 0;
}

void toupper(char *data)
{
    char *p = data;
    while(*p != '\0')
    {
        *p = toupper(*p);
        p++;
    }
}

int write_cpp_file(FILE *out)
{
    char temp_buf[MAX_BUF];
    TOUPPER("__%s_h__", g_config_name);
    WRITEFILE("#ifndef %s\n#define %s\n"
        "#include \"lua_config_wrap.h\"\n\n", temp_buf, temp_buf);
    TOUPPER("%s_len", g_config_name);
    WRITEFILE("#define %s %d\n\n", temp_buf, g_row_num);
    for(int i = 0; i < g_field_num; ++i)
    {
        TOUPPER("conf_%s_%s", g_module_name, g_field_struct[i].name);
        WRITEFILE("#define %s %d\n", temp_buf, i);
    }
    WRITEFILE("\nclass %s_data{\n"
        "private:\n"
        "\tchar *buf;\n\tchar *field[%d];\n\tbool _is_valid;\n"
        "public:\n\tint real_idx;\n", g_module_name, g_field_num + 1);
    for(int i = 0; i < g_field_num; ++i)
    {
        switch(g_field_struct[i].data_type)
        {
        case INT:
            if(g_field_struct[i].num == 1)
            {
                WRITEFILE("\tint %s;\n", g_field_struct[i].name);
            }
            else
            {
                WRITEFILE("\tint %s[%d];\n", g_field_struct[i].name, g_field_struct[i].num);
            }
            break;
        case STRING:
            WRITEFILE("\tchar *%s;\n", g_field_struct[i].name);
            break;
        }
    }
    
    WRITEFILE("public:\n\tinline %s_data();\n\tinline ~%s_data();\n"
        "\tinline bool is_valid() {return _is_valid;}\n"
        "\tinline bool get_data_by_idx(int idx);\n"
        "\tinline bool get_data_by_real_idx(int idx);\n"
        "\tinline bool get_first() {return get_data_by_real_idx(1);}\n"
        "\tinline bool get_next(){\n"
        "\t\tif(_is_valid) if(++real_idx > %d) _is_valid = false;\n"
        "\t\treturn (_is_valid && get_data_by_real_idx(real_idx));\n\t}\n"
        "\tinline bool get_prev(){\n"
        "\t\tif(_is_valid) if(--real_idx < 1) _is_valid = false;\n"
        "\t\treturn (_is_valid && get_data_by_real_idx(real_idx));\n\t}\n"
        "\tinline bool get_end() {return get_data_by_real_idx(%d);}\n"
        "private:\n\tinline int fill_data();\n", g_module_name, g_module_name, g_row_num, g_row_num);
    WRITEFILE("};\n\n");
    // 实际实现
    // 构造函数
    WRITEFILE("%s_data::%s_data(){\n\tbuf = NULL;\n\t_is_valid = false;\n}\n\n",g_module_name,g_module_name);
    // 析构函数
    WRITEFILE("%s_data::~%s_data(){\n\tif(buf != NULL) free(buf);\n}\n\n",g_module_name,g_module_name);
    // bool get_data_by_idx()
    WRITEFILE("bool %s_data::get_data_by_idx(int idx){\n"
        "\t_is_valid = false;\n"
        "\tif(buf != NULL) {free(buf); buf = NULL;}\n"
        "\tif(get_config_data_by_id(\"%s\", idx, &buf) != 0) return false;\n"
        "\tif(cut_config_data(buf, field, %d, \"%s\") != 0) return false;\n"
        "\tif(fill_data() != 0) return false;\n"
        "\t_is_valid = true;\n"
        "\treturn true;\n}\n\n",
        g_module_name, g_config_name, g_field_num + 1, g_module_name);
    // bool get_data_by_real_idx()
    WRITEFILE("bool %s_data::get_data_by_real_idx(int idx){\n"
        "\t_is_valid = false;\n"
        "\tif(buf != NULL) {free(buf); buf = NULL;}\n"
        "\tif(get_config_data_by_real_id(\"%s\", idx, &buf) != 0) return false;\n"
        "\tif(cut_config_data(buf, field, %d, \"%s\") != 0) return false;\n"
        "\tif(fill_data() != 0) return false;\n"
        "\t_is_valid = true;\n"
        "\treturn true;\n}\n\n",
        g_module_name, g_config_name, g_field_num + 1, g_module_name);
    // int fill_data()
    WRITEFILE("int %s_data::fill_data(){\n",
        g_module_name);
    for(int i = 0; i < g_field_num; ++i)
    {
        if(g_field_struct[i].num == 1)
        {
            if(g_field_struct[i].data_type == INT)
            {
                WRITEFILE("\t%s = atoi(field[%d]);\n", g_field_struct[i].name, i);
            }
            else
            {
                WRITEFILE("\t%s = field[%d];\n", g_field_struct[i].name, i);
            }
        }
        else
        {
            WRITEFILE("\tif(cut_sub_data(%s, %d, field[%d]) != 0) return -1;\n", g_field_struct[i].name, g_field_struct[i].num, i);
        }
    }
    WRITEFILE("\treal_idx = atoi(field[%d]);\n", g_field_num);
    WRITEFILE("\treturn 0;\n}\n\n");
    
    fputs("\n#endif\n", out);
    return 0;
}

int main(int argc, char **argv)
{
    if(argc < 2 || argc > 4)
    {
        printf("argc err\n");
        exit(1);
    }
    g_module_name = argv[1];
    snprintf(g_config_name, MAX_NAME_LEN, "%s_conf", g_module_name);
    char file_name[MAX_NAME_LEN];
    if(argc >= 3)
        g_need_cut = atoi(argv[2]) == 0 ? false : true;
    if(argc == 4)
        parse_idx_struct(argv[3]);
    else
        parse_idx_struct("a");
    // 读取xml文件
    snprintf(file_name, MAX_NAME_LEN, "%s.xml", g_module_name);
    XMLDocument doc;
    doc.LoadFile(file_name);
    XMLElement *root = doc.FirstChildElement()->FirstChildElement();

    // 先分析所有field
    parse_field_struct(root);

    // 写入lua
    snprintf(file_name, MAX_NAME_LEN, "%s.lua", g_module_name);
    FILE *out = fopen(file_name, "w");
    if(write_lua_file(out, root) != 0)
    {
        printf("%s err\n", g_module_name);
        exit(1);
    }
    fclose(out);

    // 写入h文件
    snprintf(file_name, MAX_NAME_LEN, "%s.h", g_config_name);
    out = fopen(file_name, "w");
    if(write_cpp_file(out) != 0)
    {
        printf("%s err\n", g_module_name);
        exit(1);
    }
    fclose(out);

    return 0;
}