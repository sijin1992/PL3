#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>
#include <time.h>
#include <stdlib.h>

#include "tinyxml2.h"
using namespace tinyxml2;
#define MAX_BUF 10240

char g_buf[MAX_BUF];
int *g_knight[2] = {0};
int g_knight_len[2] = {0};
    
#define WRITEFILE(args...) \
    snprintf(g_buf, MAX_BUF, ##args);\
    fputs(g_buf, out)
int lead_skill[] = {110070001, 110070001, 110400001,110640001,110650001};

void cut_num_string(int *dest, size_t dest_len, char *src, size_t src_len)
{
    int num = 0;
    char *p = src;
    for(size_t i = 0; i < src_len; ++i)
    {
        assert(src[i] != NULL);
        if(src[i] == ',')
        {
            src[i] = '\0';
            dest[num++] = atoi(p);
            assert(num <= dest_len);
            p = src + i + 1;
        }
    }
    assert(src[src_len] == NULL);
    dest[num++] = atoi(p);
    assert(num <= dest_len);
    assert(num == dest_len);
}

int get_random(int *buf, int max, int num)
{
    for(int i = 0; i < num; i++)
    {
        bool success = false;
        while(!success)
        {
            int t = rand() % max;
            success = true;
            for (int j = 0; j < i; j++)
            {
                if (buf[j] == t)
                {
                    success = false;
                    break;
                }
            }
            if(success)
            {
                buf[i] = t;
                break;
            }
        }
    }
    return 0;
}

// 写入一行配置数据
int write_one_row(FILE *out, XMLElement *row, int row_idx)
{
    XMLElement *field = row->FirstChildElement();
    int robot_id = 0;           // Robot_ID
    char robot_name[32] = {0};  // Robot_Name
    int sex = 0;                // Player_Sex
    int star = 0;               // Player_Star
    int set = 2;                // Player_Set
    int knight[7] = {0};        // Hero_List
    char buf[128] = {0};
    int level = 30;
    
    assert(field);
    assert(strcmp(field->Name(), "Robot_ID") == 0);
    robot_id = atoi(field->GetText());
    assert(robot_id == row_idx);
    field = field->NextSiblingElement();
    
    assert(strcmp(field->Name(), "Robot_Name") == 0);
    strncpy(robot_name, field->GetText(), 32);
    field = field->NextSiblingElement();
    
    assert(strcmp(field->Name(), "Player_Sex") == 0);
    sex = atoi(field->GetText());
    assert(sex == 0 || sex == 1);
    field = field->NextSiblingElement();

    assert(strcmp(field->Name(), "Player_Star") == 0);
    star = atoi(field->GetText());
    assert(star >= 1 && star <= 6);
    field = field->NextSiblingElement();
    
    int fang[2];
    get_random(fang, g_knight_len[0], 2);
    int gong[4];
    get_random(gong, g_knight_len[1], 4);
    knight[0] = g_knight[0][fang[0]];
    knight[1] = 1;
    knight[2] = g_knight[0][fang[1]];
    knight[3] = g_knight[1][gong[0]];
    knight[4] = g_knight[1][gong[1]];
    knight[5] = g_knight[1][gong[2]];
    knight[6] = g_knight[1][gong[3]];

    
    
    char t_buf[2048] = {0};
    const char *tz = "{status = 1},";
    const char *te = "{status = 0},";
    char t_bufzw[10240] = {0};
    for (int i = 0; i < 7; i++)
    {
        if(knight[i] == 0)
            strncat(t_bufzw, te, strlen(te));
        else if(knight[i] == 1)
            strncat(t_bufzw, tz, strlen(tz));
        else
        {
            snprintf(t_buf, 2048,
            /*
            "            {\n"
            "                status = 2,knight = {\n"
            "                    guid = %d,\n"
            "                    id = %d,\n"
            "                    data = {\n"
            "                        level = %d,\n"
            "                        gong = {\n"
            "                            gong_list = {0,0,0,0,0,0},\n"
            "                            level = 1,\n"
            "                            add_neigong = 0,\n"
            "                            add_waigong = 0,\n"
            "                            add_qinggong = 0,\n"
            "                            add_qigong = 0,\n"
            "                            add_atk = 0,\n"
            "                            add_def = 0,\n"
            "                            add_hp = 0,\n"
            "                            add_speed = 0,\n"
            "                            add_mingzhong = 0,\n"
            "                            add_huibi = 0,\n"
            "                            add_baoji = 0,\n"
            "                            add_xiaojian = 0,\n"
            "                            add_zhaojia = 0,\n"
            "                            add_jibao = 0,\n"
            "                        },\n"
            "                        skill = {id = 0--[[skill%d]], level = %d},\n"
            "                        evolution = 0,\n"
            "                        pve2_sub_hp = 0,\n"
            "                    },\n"
            "                }\n"
            "            },\n",
            */
            "{"
            "status = 2,knight = {"
            "guid = %d,"
            "id = %d,"
            "data = {"
            "level = %d,"
            "gong = empty_gong,"
            "skill = {id = 0--[[skill%d]], level = %d},"
            "evolution = 0,"
            "},"
            "}"
            "},",
            i,knight[i],level, knight[i], level);
            strncat(t_bufzw, t_buf, strlen(t_buf));
        }
    }
    
    WRITEFILE("robot_list[%d] = "
        /*
        "    {\n"
        "        nickname = util.convert_encoding(\"%s\"),\n"
        "        lead = {\n"
        "            sex = %d,\n"
        "            star = %d,\n"
        "            level = %d,\n"
        "            equip_list = {\n"
        "                {star = 0, level = 0},\n"
        "                {star = 0, level = 0},\n"
        "                {star = 0, level = 0},\n"
        "                {star = 0, level = 0},\n"
        "                {star = 0, level = 0},\n"
        "                {star = 0, level = 0},\n"
        "                {star = 0, level = 0},\n"
        "                {star = 0, level = 0},\n"
        "            },\n"
        "            skill = {id = %d, level = %d},\n"
        "            evolution = 0,\n"
        "            pve2_sub_hp = 0,\n"
        "        },\n"
        "        zhenxing = {zhanwei_list = {\n"
        "%s\n"
        "        }},\n"
        "        PVP = {reputation = 0},\n"
        "        book_list = empty_list,\n"
        "        lover_list = empty_list,\n"
        "        --[[%dpower10]]\n"
        "        --[[%dpower30]]\n"
        "    },\n",
        */
        "{"
        "nickname = util.convert_encoding(\"%s\"),"
        "lead = {"
        "sex = %d,"
        "star = %d,"
        "level = %d,"
        "equip_list = equip_list,"
        "skill = {id = %d, level = %d},"
        "evolution = 0,"
        "},"
        "zhenxing = {zhanwei_list = {"
        "%s"
        "}},"
        "PVP = {reputation = %d},"
        "book_list = empty_list,"
        "lover_list = empty_list,"
        "--[[%dpower10]]"
        "--[[%dpower30]]"
        "}\n",
        robot_id,robot_name, sex,star, level,lead_skill[star - 1], level, t_bufzw, 3001 - robot_id, robot_id, robot_id);
    return 0;
}

int write_lua_file(FILE *out, XMLElement *root)
{
    XMLElement *row = root;
    
    WRITEFILE("local empty_list = {}\n"
        "local equip_list = {"
        "{star = 0, level = 0},"
        "{star = 0, level = 0},"
        "{star = 0, level = 0},"
        "{star = 0, level = 0},"
        "{star = 0, level = 0},"
        "{star = 0, level = 0},"
        "{star = 0, level = 0},"
        "{star = 0, level = 0}}\n"
        "local empty_gong = {"
        "gong_list = {0,0,0,0,0,0},"
        "level = 1,"
        "add_neigong = 0,"
        "add_waigong = 0,"
        "add_qinggong = 0,"
        "add_qigong = 0,"
        "add_atk = 0,"
        "add_def = 0,"
        "add_hp = 0,"
        "add_speed = 0,"
        "add_mingzhong = 0,"
        "add_huibi = 0,"
        "add_baoji = 0,"
        "add_xiaojian = 0,"
        "add_zhaojia = 0,"
        "add_jibao = 0,"
        "}\n"
        "local robot_list = {}\n");
    int row_num = 1;
    while(row)
    {
        if(write_one_row(out, row, row_num) != 0)
        {
            return -1;
        }
        row = row->NextSiblingElement();
        row_num++;
    }
    WRITEFILE("return robot_list");
    return 0;
}

int get_knight_pool(XMLElement *root)
{
    XMLElement *row = root;
    char buf[2048] = {0};
    int row_num = 0;
    while(row)
    {
        assert(row_num < 2);
        XMLElement *field = row->FirstChildElement();
        field = field->NextSiblingElement();
        field = field->NextSiblingElement();
        
        assert(strcmp(field->Name(), "Hero_Pool") == 0);
        strncpy(buf, field->GetText(), 2048);
        int len = 1;
        for(int i = 0; i < strlen(buf); i++)
        {
            assert(buf[i] != NULL);
            if(buf[i] == ',')
            {
                len++;
            }
        }
        g_knight_len[row_num] = len;
        g_knight[row_num] = new int[len];
        int num = 0;
        char *p = buf;
        int buf_len = strlen(buf);
        for(int i = 0; i < buf_len; i++)
        {
            assert(buf[i] != NULL);
            if(buf[i] == ',')
            {
                buf[i] = '\0';
                g_knight[row_num][num++] = atoi(p);
                assert(num <= len);
                p = buf + i + 1;
            }
        }
        g_knight[row_num][num++] = atoi(p);
        assert(num == len);
        row = row->NextSiblingElement();
        row_num++;
    }
    return 0;
}

int main(int argc, char **argv)
{
    srand((int)time(NULL));
    const char *xml_file_name = "Robot.x";
    const char *xml_knight_file = "Robot_Pool.x";
    const char *lua_file_name = "robot.lxx";
    {
        XMLDocument doc;
        doc.LoadFile(xml_knight_file);
        XMLElement *root = doc.FirstChildElement()->FirstChildElement();
        get_knight_pool(root);
    }
    
    // 读取xml文件
    XMLDocument doc;
    doc.LoadFile(xml_file_name);
    XMLElement *root = doc.FirstChildElement()->FirstChildElement();

    // 写入lua
    FILE *out = fopen(lua_file_name, "w");
    if(write_lua_file(out, root) != 0)
    {
        printf("err\n");
        exit(1);
    }
    fclose(out);

    return 0;
}