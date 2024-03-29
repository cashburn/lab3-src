
/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 */

%token	<string_val> WORD

%token 	NOTOKEN GREAT LESS NEWLINE PIPE GREATAND GREATGREAT GREATGREATAND AND ESCAPE

%union	{
		char   *string_val;
	}

%{
//#define yylex yylex
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <regex.h>
#include <dirent.h>
#include <sys/types.h>
#include <vector>
#include <algorithm>
#include "command.h"
#define MAXFILENAME 1024
using namespace std;
void yyerror(const char * s);
int yylex();
int isWildcard;
vector<char *> matchList;

void
yyerror(const char * s)
{
	fprintf(stderr,"%s\n", s);
        Command::_currentCommand.clear();
        Command::_currentCommand.prompt();
}

bool compFunc(const char * c1, const char * c2) {
	return strcmp(c1, c2) < 0;
}

void expandWildcard(char * pre, char * suf) {
	if (suf[0] == '\0') {
		matchList.push_back(strdup(pre));
		return;
	}

	if (strchr(suf, '*') != NULL || strchr(suf, '?') != NULL) {
		isWildcard = 1;
	}
	if (!isWildcard && pre == NULL) {
		Command::_currentSimpleCommand->insertArgument(strdup(suf));
		return;
	}

	char * s = strchr(suf, '/');
	char * component = (char *) calloc(MAXFILENAME, sizeof(char));
	if (s != NULL) {
		strncpy(component, suf, s-suf);
		suf = s + 1;
	}

	else {
		strcpy(component, suf);
		suf = suf + strlen(suf);
	}

	char newPrefix[MAXFILENAME];
	if (strchr(component, '*') == NULL && strchr(component, '?') == NULL) {
		if (pre == NULL && *component != '\0')
			sprintf(newPrefix, "%s", component);
		else if (*component != '\0')
			sprintf(newPrefix, "%s/%s", pre, component);
		if (*component != '\0')
			expandWildcard(newPrefix, suf);
		else
			expandWildcard((char *) "", suf);
		return;
	}

	char * a = component;
	char * reg = (char *) malloc(2*strlen(component)+10);
	char * r = reg;
	int backdot = 0;
	*r = '^';
	r++;
	while (*a) {
		if (*a == '*') {
			*r = '.';
			r++;
			*r = '*';
			r++;
		}
		else if (*a == '?') {
			*r = '.';
			r++;
		}
		else if (*a == '.') {
			*r = '\\';
			r++;
			*r = '.';
			r++;
			backdot = 1;
		}
		else {
			*r = *a;
			r++;
		}
		a++;
	}
	*r = '$';
	r++;
	*r = '\0';

	regex_t re;
	int result = regcomp(&re, reg, REG_EXTENDED|REG_NOSUB);
	if (result != 0) {
		perror("regex compile");
		return;
	}
	char * path;
	if (pre == NULL) {
		path = (char *) ".";
	}
	else if (*pre == '\0')
		path = (char *) "/";
	else
		path = pre;
	DIR * dir = opendir(path);
	if (dir == NULL) {
		//perror("opendir");
		return;
	}

	struct dirent * ent;

	regmatch_t match;
	while ((ent = readdir(dir)) != NULL) {
		if (regexec(&re, ent->d_name, 1, &match, 0) == 0) {
			if (backdot || (!backdot && *(ent->d_name) != '.')) {
				if (pre == NULL)
					sprintf(newPrefix, "%s", ent->d_name);
				else
					sprintf(newPrefix, "%s/%s", pre, ent->d_name);
				expandWildcard(newPrefix, suf);
			}
				//matchList.push_back(strdup(ent->d_name));
			//Command::_currentSimpleCommand->insertArgument(strdup(ent->d_name));
		}
	}
	closedir(dir);
	/*
	sort(matchList.begin(), matchList.end(), compFunc);
	for (vector<char *>::iterator it = matchList.begin(); it < matchList.end(); it++) {
		Command::_currentSimpleCommand->insertArgument(strdup(*it));
	}*/
}

void expandWildcardsIfNecessary(char * arg) {

	char * prefix = (char *) calloc(2*strlen(arg)+10, sizeof(char));
	expandWildcard(NULL, arg);
	if (isWildcard) {
		sort(matchList.begin(), matchList.end(), compFunc);
		for (vector<char *>::iterator it = matchList.begin(); it < matchList.end(); it++) {
			Command::_currentSimpleCommand->insertArgument(strdup(*it));
		}
	}
	isWildcard = 0;
	matchList.clear();

}

%}

%%

goal:
	command_list
	;

command_list:
        command_list command_line
        | command_line
        ;

command_line:
	pipe_list io_modifier_list background_opt NEWLINE {
		Command::_currentCommand.execute();
	}
	| NEWLINE
	| error NEWLINE { yyerrok; }
	;

pipe_list:
        pipe_list PIPE command_and_args
        | command_and_args
        ;

command_and_args:
	command_word argument_list {
		Command::_currentCommand.
			insertSimpleCommand( Command::_currentSimpleCommand );
	}
	;

argument_list:
	argument_list argument
	| /* can be empty */
	;

argument:
	WORD {
	       	expandWildcardsIfNecessary($1);\
	}
	;

command_word:
	WORD {

	       Command::_currentSimpleCommand = new SimpleCommand();
	       Command::_currentSimpleCommand->insertArgument( $1 );
	}
	;

io_modifier_list:
        io_modifier_list io_modifier
        | /*could be empty*/
        ;

io_modifier:
        GREAT WORD {
	    if (Command::_currentCommand._outFile == NULL)
                Command::_currentCommand._outFile = $2;
            else
                yyerror("ERROR: Ambiguous output redirect");
	}
	| LESS WORD {
                Command::_currentCommand._inFile = $2;
        }
        | GREATAND WORD {
                Command::_currentCommand._outFile = $2;
                Command::_currentCommand._errFile = strdup($2);
        }
        | GREATGREAT WORD {
                Command::_currentCommand._outFile = $2;
                Command::_currentCommand._append = 1;
        }
        | GREATGREATAND WORD {
                Command::_currentCommand._outFile = $2;
                Command::_currentCommand._errFile = strdup($2);
                Command::_currentCommand._append = 1;
        }
        ;

background_opt:
        AND {
                Command::_currentCommand._background = 1;
        }
        | /*empty*/
        ;

%%

/*void scan_string(const char* str)
{
    yy_switch_to_buffer(yy_scan_string(str));
}*/

#if 0
main()
{
	yyparse();
}
#endif
