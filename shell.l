
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

char esc_buf[MAX_STR_CONST];
char * esc_buf_ptr;

int backptr;

static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
    unput(c);
}

char * rmbackslash(char * s) {
    char * src = s;
    char * dest = (char *) malloc(sizeof(s));
    char * dest1 = dest;
    while (*src) {
        if (*src != '\\') {
            *dest1 = *src;
            dest1++;
        }
        src++;
    }
    *dest1 = '\0';
    return dest;
}

%}

%x QUOTE
%x BACKTICK
%x BACK

%%

\\      {
                BEGIN(BACK);
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


[^`" \\\t\n][^ \t\n]*  {
		/* Assume that file names have only alpha chars */
                
                if (esc_buf_ptr == NULL) {
                    esc_buf_ptr = esc_buf;
                }
                char * yptr = yytext;
                int done = 1;
                int count = 0;
                while (*yptr) {
                    if (*yptr == '\\') {
                        BEGIN(BACK);
                        done = 0;
                        count++;
                        yptr++;
                        if (*yptr) {
                            yyless(count);
                        }
                        yptr--;
                        break;
                    }
                    else
                        *esc_buf_ptr = *yptr;
                    esc_buf_ptr++;
                    yptr++;
                    count++;
                }

                if (done) {
                    yylval.string_val = strdup(esc_buf);
                //printf("Word: %s\n", yytext);
                    esc_buf_ptr = esc_buf;
                    while (*esc_buf_ptr) {
                        *esc_buf_ptr = '\0';
                        esc_buf_ptr++;
                    }
                    esc_buf_ptr = esc_buf;
		    return WORD;
                }
	}

<BACK>.\n   {
                    if (esc_buf_ptr != esc_buf) {
                        yylval.string_val = strdup(esc_buf);
                        unput('\n');
                        BEGIN(0);
                    }
                        return WORD;
            }

<BACK>.     {
                    char * yptr = yytext;
                    *esc_buf_ptr = *yptr;
                    esc_buf_ptr++;
                    BEGIN(0);
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

<QUOTE>\\n  *string_buf_ptr++ = '\n';
<QUOTE>\\t  *string_buf_ptr++ = '\t';
<QUOTE>\\r  *string_buf_ptr++ = '\r';
<QUOTE>\\b  *string_buf_ptr++ = '\b';
<QUOTE>\\f  *string_buf_ptr++ = '\f';
<QUOTE>\\(.|\n)  *string_buf_ptr++ = yytext[1];

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
