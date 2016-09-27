
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

%token 	NOTOKEN GREAT LESS NEWLINE PIPE GREATAND GREATGREAT GREATGREATAND AND

%union	{
		char   *string_val;
	}

%{
//#define yylex yylex
#include <stdio.h>
#include <string.h>
#include "command.h"
void yyerror(const char * s);
int yylex();

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

	       Command::_currentSimpleCommand->insertArgument( $1 );\
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

void
yyerror(const char * s)
{
	fprintf(stderr,"%s\n", s);
        Command::_currentCommand.clear();
        Command::_currentCommand.prompt();
}

#if 0
main()
{
	yyparse();
}
#endif
