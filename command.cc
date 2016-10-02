
/*
 * CS252: Shell project
 *
 * Template file.
 * You will need to add more code here to execute the command table.
 *
 * NOTE: You are responsible for fixing any bugs this code may have!
 *
 */

#define GRN "\x1B[32m"
#define NRM "\x1B[0m"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <signal.h>
#include "command.h"

SimpleCommand::SimpleCommand()
{
	// Create available space for 5 arguments
	_numOfAvailableArguments = 5;
	_numOfArguments = 0;
	_arguments = (char **) malloc( _numOfAvailableArguments * sizeof( char * ) );
}

void
SimpleCommand::insertArgument( char * argument )
{
	if ( _numOfAvailableArguments == _numOfArguments  + 1 ) {
		// Double the available space
		_numOfAvailableArguments *= 2;
		_arguments = (char **) realloc( _arguments,
				  _numOfAvailableArguments * sizeof( char * ) );
	}
	
	_arguments[ _numOfArguments ] = argument;

	// Add NULL argument at the end
	_arguments[ _numOfArguments + 1] = NULL;
	
	_numOfArguments++;
}

Command::Command()
{
	// Create available space for one simple command
	_numOfAvailableSimpleCommands = 1;
	_simpleCommands = (SimpleCommand **)
		malloc( _numOfSimpleCommands * sizeof( SimpleCommand * ) );

	_numOfSimpleCommands = 0;
	_outFile = 0;
	_inFile = 0;
	_errFile = 0;
	_background = 0;
}

void
Command::insertSimpleCommand( SimpleCommand * simpleCommand )
{
	if ( _numOfAvailableSimpleCommands == _numOfSimpleCommands ) {
		_numOfAvailableSimpleCommands *= 2;
		_simpleCommands = (SimpleCommand **) realloc( _simpleCommands,
			 _numOfAvailableSimpleCommands * sizeof( SimpleCommand * ) );
	}
	
	_simpleCommands[ _numOfSimpleCommands ] = simpleCommand;
	_numOfSimpleCommands++;
}

void
Command:: clear()
{
	for ( int i = 0; i < _numOfSimpleCommands; i++ ) {
		for ( int j = 0; j < _simpleCommands[ i ]->_numOfArguments; j ++ ) {
			free ( _simpleCommands[ i ]->_arguments[ j ] );
		}
		
		free ( _simpleCommands[ i ]->_arguments );
		free ( _simpleCommands[ i ] );
	}

	if ( _outFile ) {
		free( _outFile );
	}

	if ( _inFile ) {
		free( _inFile );
	}

	if ( _errFile ) {
		free( _errFile );
	}

	_numOfSimpleCommands = 0;
	_outFile = 0;
	_inFile = 0;
	_errFile = 0;
	_background = 0;
}

void
Command::print()
{
	printf("\n\n");
	printf("              COMMAND TABLE                \n");
	printf("\n");
	printf("  #   Simple Commands\n");
	printf("  --- ----------------------------------------------------------\n");
	
	for ( int i = 0; i < _numOfSimpleCommands; i++ ) {
		printf("  %-3d ", i );
		for ( int j = 0; j < _simpleCommands[i]->_numOfArguments; j++ ) {
			printf("\"%s\" \t", _simpleCommands[i]->_arguments[ j ] );
		}
		printf("\n");
	}

	printf( "\n\n" );
	printf( "  Output       Input        Error        Background\n" );
	printf( "  ------------ ------------ ------------ ------------\n" );
	printf( "  %-12s %-12s %-12s %-12s\n", _outFile?_outFile:"default",
		_inFile?_inFile:"default", _errFile?_errFile:"default",
		_background?"YES":"NO");
	printf( "\n\n" );
	
}

void
Command::execute()
{
    //print();
    //Save default input, output, error
    int defaultin = dup(0);
    int defaultout = dup(1);
    int defaulterr = dup(2);
    int infd, outfd;
    int numPipes = _numOfSimpleCommands-1;
    int fdpipe[2*numPipes];
    int pid, status;

    //Don't do anything if there are no simple commands
    if (_numOfSimpleCommands == 0) {
        prompt();
        return;
    }

    for (int i = 0; i < numPipes; i++) {
        if (pipe(fdpipe + i*2) < 0) {
            fprintf(stderr, "PIPE ERROR\n");
        }
    }
    
    for (int i = 0; i < _numOfSimpleCommands; i++) {
        if (i == 0) {
            //Input File
            if (_inFile) {
                infd = open(_inFile, O_RDONLY);
                if (infd <= 0) {
                    printf("INPUT ERROR\n");
                    //return;
                }
                dup2(infd, 0);
                close(infd);
            }
        }

        //Last command
        if (i == _numOfSimpleCommands-1) {
            //Output File
            if (_outFile) {
                //Append to file
                if (_append) {
                    outfd = open(_outFile, O_WRONLY|O_APPEND);
                }

                //If file doesn't exist, create
                if (!_append || outfd <= 0) {
                    outfd = creat(_outFile, 0666);
                }

                if (outfd < 0) {
                    printf("OUTPUT ERROR\n");
                    //return;
                }
                dup2(outfd, 1);
                if (_errFile)
                    dup2(outfd, 2);
                close(outfd);
            }
        }

	// Print contents of Command data structure
	//print();

        //Fork
        if (!(pid = fork())) {
            //Child Process
            
            //Not the first command--must be piped to
            if (i > 0) {
                dup2(fdpipe[(i*2)-2], 0);
            }

            //Not the last command--must be piped from
            if (i < (_numOfSimpleCommands - 1)) {
                dup2(fdpipe[(i*2)+1],1);
            }

                //Close unnecessary fds
                for (int j = 0; j < 2*numPipes; j++)
                    close(fdpipe[j]);
                close(defaultin);
                close(defaultout);
                close(defaulterr);
                
                //Execute command
                
                execvp(_simpleCommands[i]->_arguments[0], _simpleCommands[i]->_arguments);
                printf("ERROR: Command not found.\n");
                //return;
        }
        //fprintf(stderr, "Process %d started\n", pid);
    }
        for (int j = 0; j < 2*numPipes; j++)
            close(fdpipe[j]);
        
        if(!_background)
            waitpid(pid, 0, 0);

	// Clear to prepare for next command
        dup2(defaultin, 0);
        dup2(defaultout, 1);
        dup2(defaulterr, 2);
        close(defaultin);
        close(defaultout);
        close(defaulterr);
	clear();
	
	// Print new prompt
	prompt();
}

// Shell implementation

void
Command::prompt()
{
    if (isatty(fileno(stdin))) {
	printf(GRN "> $ " NRM);
	fflush(stderr);
    }
}

Command Command::_currentCommand;
SimpleCommand * Command::_currentSimpleCommand;

int yyparse(void);

void Command::disp(int sig) {
    prompt();
    
}

main()
{
	struct sigaction sa;
        sa.sa_handler = Command::_currentCommand.disp;
        sigemptyset(&sa.sa_mask);
        sa.sa_flags = 0;

        if (sigaction(SIGINT, &sa, NULL)) {
            perror("sigaction");
            exit(2);
        }

        Command::_currentCommand.prompt();
	yyparse();
}

