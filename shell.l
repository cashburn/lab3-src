
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
#include <sys/wait.h>
#include <sys/types.h>
#include <pwd.h>
#include <unistd.h>
#include "y.tab.h"
#include "command.h"
#define MAX_STR_CONST 4096

//Line Editor
char * read_line();

int mygetc(FILE * f) {
    static char *p;
    char ch;

    if (!isatty(0)) {
        return getc(f);
    }

    if (p==NULL || *p == 0) {
        char * s = read_line();
        p = s;
    }

    ch = *p;
    p++;

    return ch;
}

#undef getc
#define getc(f) mygetc(f)



static  void yyunput (int c,char *buf_ptr  );

char string_buf[MAX_STR_CONST];
char * string_buf_ptr;

char subsh_output[MAX_STR_CONST];
char subsh_buf[MAX_STR_CONST];
char * subsh_buf_ptr;

char esc_buf[MAX_STR_CONST];
char * esc_buf_ptr;

int backptr;

static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
    unput(c);
}

void insertarg(char * arg) {
    char * newarg = strdup(arg);
    char * s = newarg;
    while (*s != '\0') {
        if (*s == ' ' || *s == '\n' || *s == '\t') {
            *s = '\0';
            Command::_currentSimpleCommand->insertArgument(strdup(newarg));
            newarg = s + 1;
        }
        s++;
    }
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

void scan_string(const char* str)
{
    yy_switch_to_buffer(yy_scan_string(str));
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
"`"       {
                subsh_buf_ptr = subsh_buf;
                char * tmpptr = subsh_output;
                while (*tmpptr) {
                    *tmpptr = '\0';
                    tmpptr++;
                }
                tmpptr = subsh_buf;
                while (*tmpptr) {
                    *tmpptr = '\0';
                    tmpptr++;
                }
                BEGIN(BACKTICK);
        }

$\{[^ \t\n\{\}]*\}   {
                char * beg = yytext + 2;
                char * s = beg;
                char tmp[MAX_STR_CONST];\
                char * t = tmp;
                while (*s != '}') {
                    *t = *s;
                    t++;
                    s++;
                }
                *t = '\0';
                char * env = getenv(tmp);
                if (env != NULL)
                    yylval.string_val = strdup(env);
                return WORD;
        }

\n 	{
		return NEWLINE;
	}

[ \t] 	{
		/* Discard spaces and tabs */
     	}

~[^ \t\n]*  {
                if (yytext[1] == '\0') {
                    yylval.string_val = strdup(getenv("HOME"));
                }
                else if (yytext[1] == '/') {
                    char tmp[MAX_STR_CONST];
                    sprintf(tmp, "%s%s", getenv("HOME"), yytext + 1);
                    yylval.string_val = strdup(tmp);
                }
                else {
                    
                    char * end = strchr(yytext+1, '/');
                    struct passwd * pwname = NULL;
                    if (end != NULL) {
                        char tmp[MAX_STR_CONST];
                        char * s = yytext+1;
                        strncpy(tmp, yytext+1, end-(yytext+1));
                        pwname = getpwnam(tmp);
                        if (pwname != NULL) {
                            sprintf(tmp, "%s%s", pwname->pw_dir, end);
                            yylval.string_val = strdup(tmp);
                            return WORD;
                        }
                    }
                    else
                        pwname = getpwnam(yytext+1);
                    if (pwname == NULL) {
                        yylval.string_val = strdup(getenv("HOME"));
                        return WORD;
                    }
                    yylval.string_val = strdup(pwname->pw_dir);
                }
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

<BACK>.[ \t\n]   {
                        *esc_buf_ptr = *yytext;
                        yylval.string_val = strdup(esc_buf);
                        esc_buf_ptr = esc_buf;
                        while (*esc_buf_ptr) {
                            *esc_buf_ptr = '\0';
                            esc_buf_ptr++;
                        }
                        esc_buf_ptr = esc_buf;
                        yyless(1);
                        BEGIN(0);
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
                //printf("Command: %s\n", subsh_buf);
                char tmp[MAX_STR_CONST];
                readlink("/proc/self/exe", tmp, MAX_STR_CONST);

                sprintf(tmp, "%s -c \"%s\"", tmp, subsh_buf);
                FILE * fp;
                int status;
                fp = popen(tmp, "r");
                if (fp == NULL) {
                    perror("popen");
                    exit(1);
                }

                char temp[MAX_STR_CONST];
                while (fgets(temp, MAX_STR_CONST, fp) != NULL) {
                    //printf("%s\n", temp);
                    insertarg(temp);
                }
                    //Command::_currentSimpleCommand->insertArgument(strdup(temp));
                    //sprintf(subsh_output, "%s%s", subsh_output, temp);
                //yylval.string_val = strdup(subsh_output);

                //status = pclose(fp);
                /*if (status == -1) {
                    perror("pclose");
                    exit(1);
                }*/

                /*if (!(pid = fork())) {
                    //Child Process
                    //printf("Inside the child\n");
                    //execlp("/bin/echo", "echo", "this is a test", NULL);
                    printf("This should be out of the string\n");
                    freopen("/dev/null", "a", stdout);
                    setbuf(stdout, subsh_output);
                    printf("This should be in the string\n");
                     execlp(tmp, "shell", "-c", subsh_buf, NULL);
                     perror("exec");

                }
                waitpid(pid, 0, 0);
                */

                BEGIN(0);
                //return WORD;
                }
