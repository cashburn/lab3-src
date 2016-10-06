
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

