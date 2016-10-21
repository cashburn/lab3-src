/*
 * CS354: Operating Systems. 
 * Purdue University
 * Example that shows how to read one line with simple editing
 * using raw terminal.
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <vector>

#define MAX_BUFFER_LINE 2048
using namespace std;
void tty_raw_mode(void);

// Buffer where line is stored
int line_length;;
char line_buffer[MAX_BUFFER_LINE];

// Simple history array
// This history does not change. 
// Yours have to be updated.
int history_index = -1;
vector<char *> history;
int history_searching = 0;
int cursor;

void read_line_print_usage()
{
  char * usage = (char *) "\n"
    " ctrl-?       Print usage\n"
    " Backspace    Deletes last character\n"
    " up arrow     See last command in the history\n";

  write(1, usage, strlen(usage));
}

/* 
 * Input a line with some basic editing.
 */
char * read_line() {

  // Set terminal in raw mode
  tty_raw_mode();

  line_length = 0;
  cursor = line_length;
  char * s = line_buffer;
  while (*s) {
    *s = 0;
    s++;
  }

  // Read one line until enter is typed
  while (1) {

    // Read one character in raw mode.
    char ch;
    read(0, &ch, 1);
    //printf("Char: %d\n", ch);

    if (ch==10) {
      // <Enter> was typed. Return line
      history.push_back(strndup(line_buffer, line_length));
      history_index = history.size() - 1;

      // Print newline
      write(1,&ch,1);

      break;
    }
    else if (ch == 31) {
      // ctrl-?
      read_line_print_usage();
      line_buffer[0]=0;
      break;
    }
    else if (ch == 8 || ch == 127) {
      // <backspace> was typed. Remove previous character read.
      if (line_length == 0 || cursor == 0)
          continue;
      
      for (int i = cursor; i < line_length; i++) {
          line_buffer[i-1] = line_buffer[i];
      }
      
      // Remove one character from buffer
      line_length--;
      cursor--;
      
      //printf("%d\n", ch);
      // Go back one character
      ch = 8;
      write(1,&ch,1);

      // Write a space to erase the last character read
      ch = ' ';
      write(1,&ch,1);

      // Go back one character
      ch = 8;
      write(1,&ch,1);

      
      for (int i = cursor; i < line_length; i++) {
        ch = line_buffer[i];
        write(1, &ch, 1);
      }

      ch = ' ';
      write(1, &ch, 1);

      ch = 8;
      write(1, &ch, 1);

      for (int i = cursor; i < line_length; i++) {
        ch = 27;
        write(1, &ch, 1);
        ch = 91;
        write(1, &ch, 1);
        ch = 68;
        write(1, &ch, 1);
      }
    }
    else if (ch == 4) {
      // <delete> was typed. Remove current character read.
      if (line_length == 0 || cursor == 0)
          continue;
      
      for (int i = cursor+1; i < line_length; i++) {
          line_buffer[i-1] = line_buffer[i];
      }
      
      // Remove one character from buffer
      line_length--;
      
      // Write a space to erase the last character read
      ch = ' ';
      write(1,&ch,1);

      // Go back one character
      ch = 8;
      write(1,&ch,1);

      
      for (int i = cursor; i < line_length; i++) {
        ch = line_buffer[i];
        write(1, &ch, 1);
      }

      ch = ' ';
      write(1, &ch, 1);

      ch = 8;
      write(1, &ch, 1);

      for (int i = cursor; i < line_length; i++) {
        ch = 27;
        write(1, &ch, 1);
        ch = 91;
        write(1, &ch, 1);
        ch = 68;
        write(1, &ch, 1);
      }
    }


    else if (ch==27) {
      // Escape sequence. Read two chars more
      //
      // HINT: Use the program "keyboard-example" to
      // see the ascii code for the different chars typed.
      //
      char ch1; 
      char ch2;
      read(0, &ch1, 1);
      read(0, &ch2, 1);
      //printf("%d\n", history_index);
      if (ch1==91 && ch2==65) {
	// Up arrow. Print next line in history.
        if (history.size() < 1 || (history_index < 1))
            continue;

	// Erase old line
	// Print backspaces
	int i = 0;
	for (i =0; i < line_length; i++) {
	  ch = 8;
	  write(1,&ch,1);
	}

	// Print spaces on top
	for (i =0; i < line_length; i++) {
	  ch = ' ';
	  write(1,&ch,1);
	}

	// Print backspaces
	for (i =0; i < line_length; i++) {
	  ch = 8;
	  write(1,&ch,1);
	}	

	if (!history_searching) {
            history_index++;
            history_searching = 1;
        }
        // Copy line from history
	strcpy(line_buffer, history[--history_index]);
	line_length = strlen(line_buffer);
        cursor = line_length;
	// echo line
	write(1, line_buffer, line_length);
      }

      if (ch1==91 && ch2==66) {
        // Down arrow. Print previous line in history.

        if (history_index + 2 > history.size())
            continue;
	// Erase old line
	// Print backspaces
	int i = 0;
	for (i =0; i < line_length; i++) {
	  ch = 8;
	  write(1,&ch,1);
	}

	// Print spaces on top
	for (i =0; i < line_length; i++) {
	  ch = ' ';
	  write(1,&ch,1);
	}

	// Print backspaces
	for (i =0; i < line_length; i++) {
	  ch = 8;
	  write(1,&ch,1);
	}	

	// Copy line from history
	strcpy(line_buffer, history[++history_index]);
	line_length = strlen(line_buffer);
        cursor = line_length;
        history_searching = 0;

	// echo line
	write(1, line_buffer, line_length);

      }

      else if (ch1 == 91 && ch2 == 68) {
        if (cursor <= 0)
          continue;

        //printf("%d\n", ch);
        // Go back one character
        ch = 27;
        write(1,&ch,1);
        ch = 91;
        write(1,&ch,1);
        ch = 68;
        write(1,&ch,1);
        cursor--;
      }

      else if (ch1 == 91 && ch2 == 67) {
        if (cursor >= line_length)
          continue;

        //printf("%d\n", ch);
        // Go back one character
        ch = 27;
        write(1,&ch,1);
        ch = 91;
        write(1,&ch,1);
        ch = 67;
        write(1,&ch,1);
        cursor++;
      }

      
    }

    else if (ch>=32) {
      // It is a printable character. 
      write(1,&ch,1);
      for (int i = line_length + 1; i > cursor; i--) {
        line_buffer[i] = line_buffer[i-1]; 
        //ch = line_buffer[i];
        //write(1,&ch,1);
      }
      
    // add char to buffer.
      line_buffer[cursor]=ch;
      line_length++;
      cursor++;


      // Do echo
      for (int i = cursor; i < line_length; i++) {
        ch = line_buffer[i];
        write(1,&ch,1);
      }

      // If max number of character reached return.
      if (line_length==MAX_BUFFER_LINE-2) break;

      ch = ' ';
      write(1, &ch, 1);

      ch = 8;
      write(1, &ch, 1);
      
      for (int i = cursor; i < line_length; i++) {
        ch = 27;
        write(1,&ch,1);
        ch = 91;
        write(1,&ch,1);
        ch = 68;
        write(1,&ch,1);
      }

    }


  }

  
  // Add eol and null char at the end of string
  line_buffer[line_length]=10;
  line_length++;
  line_buffer[line_length]=0;

  return line_buffer;
}

