
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
#define MAX_STR_CONST 4096

static  void yyunput (int c,char *buf_ptr  );

char string_buf[MAX_STR_CONST];
char * string_buf_ptr;

char subsh_buf[MAX_STR_CONST];
char * subsh_buf_ptr;

static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
    unput(c);
}

%}

%x QUOTE
%x BACKTICK

%%

\\.$    {
                yytext = yytext+sizeof(char);
        }

\\.     {
                yytext = yytext+sizeof(char);
                yymore();
        }

\"      {
                //yymore();
                string_buf_ptr = string_buf;
                BEGIN(QUOTE);
        }
`       {
                subsh_buf_ptr = subsh_buf;
                BEGIN(BACKTICK);
        }

\n 	{
		return NEWLINE;
	}

[ \t] 	{
		/* Discard spaces and tabs */
     	}	

"~"     {
                yylval.string_val = strdup(getenv("HOME"));
                return WORD;
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


[^`\\" \t\n][^\\ \t\n]*  {
		/* Assume that file names have only alpha chars */
                
                yylval.string_val = strdup(yytext);
                //printf("Word: %s\n", yytext);
		return WORD;
	}

<QUOTE>\"      {
                string_buf_ptr = '\0';
                //printf("The quoted string: %s\n", string_buf);
                yylval.string_val = strdup(string_buf);
                BEGIN(0);
                return WORD;
            }
    
<QUOTE>[^\\\n\"]+       {
                char * yptr = yytext;
                while (*yptr)
                    *string_buf_ptr++ = *yptr++;
                        }

<BACKTICK>[^\\\n`]+     {
                char * yptr = yytext;
                while (*yptr)
                    *subsh_buf_ptr++ = *yptr++;
                        }
<BACKTICK>`     {
                subsh_buf_ptr = '\0';
                printf("Command: %s\n", string_buf);
                char tmp[MAX_STR_CONST];
                readlink("/proc/self/exe", tmp, MAX_STR_CONST);
                int pid;
                if (!(pid = fork())) {
                    //Child Process
                     execvp(tmp, NULL);
                     exit(1);
                }
                
                BEGIN(0);
                return WORD;
                }
