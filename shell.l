
/*
 *
 * CS-252 Fall 2013
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{

#include <string.h>
#include "y.tab.h"

static  void yyunput (int c,char *buf_ptr  );

const char * strrep(char * str, char * orig, char * rep) {
    int len = strlen(orig);
    static char buffer[len];
    char * p;

    if (!(p = strstr(str, orig)))
        return str;

    strncpy(buffer, str, p-str);
    buffer[p-str] = '\0';
    sprintf(buffer+(p-str), "%s%s", rep, p+len);

    return buffer;
}

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
                
                yylval.string_val = strrep(yytext, "\\", "");
                printf("Word: %s\n", yytext);
		return WORD;
	}

