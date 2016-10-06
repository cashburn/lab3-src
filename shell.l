
/*
 *
 * CS-252 Fall 2013
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{

#include <iostream>
#include <string>
#include "y.tab.h"

static  void yyunput (int c,char *buf_ptr  );

bool replace(std::string& str, const std::string& from, const std::string& to) {
        size_t start_pos = str.find(from);
            if(start_pos == std::string::npos)
                        return false;
                            str.replace(start_pos, from.length(), to);
                                return true;
}

/*char * strrep(char * str, char * orig, char * rep) {
    int len = strlen(orig);
    char buffer[len];
    char * p;

    if (!(p = strstr(str, orig)))
        return str;

    strncpy(buffer, str, p-str);
    buffer[p-str] = '\0';
    sprintf(buffer+(p-str), "%s%s", rep, p+len);

    return buffer;
}*/

void myunputc(int c) {
    unput(c);
}

%}

%%


\n 	{
		return NEWLINE;
	}

[ \t] 	{
		/* Discard spaces and tabs */
     	}
        
">" 	{
		return GREAT;
	}

"|"     {
                return PIPE;
        }

"<"     {
                return LESS;
        }

"&"     {
                return AND;
        }

">>"    {
                return GREATGREAT;
        }

">&"    {
                return GREATAND;
        }

">>&"   {
                return GREATGREATAND;
        }


[^ \t\n][^ \t\n]*  {
		/* Assume that file names have only alpha chars */
                
                yylval.string_val = strdup(yytext);
                printf("Word: %s\n", yytext);
		return WORD;
	}

