/***********************************************************************
* File       : <spell_checker.c>
*
* Author     : <Siavash Katebzadeh>
*
* Description: 
*
* Date       : 08/10/18
*
***********************************************************************/
// ==========================================================================
// Spell checker 
// ==========================================================================
// Marks misspelled words in a sentence according to a dictionary

// Inf2C-CS Coursework 1. Task B/C 
// PROVIDED file, to be used as a skeleton.

// Instructor: Boris Grot
// TA: Siavash Katebzadeh
// 08 Oct 2018

#include <stdio.h>

// maximum size of input file
#define MAX_INPUT_SIZE 2048
// maximum number of words in dictionary file
#define MAX_DICTIONARY_WORDS 10000
// maximum size of each word in the dictionary
#define MAX_WORD_SIZE 20

int read_char() { return getchar(); }
int read_int()
{
    int i;
    scanf("%i", &i);
    return i;
}
void read_string(char* s, int size) { fgets(s, size, stdin); }

void print_char(int c)     { putchar(c); }   
void print_int(int i)      { printf("%i", i); }
void print_string(char* s) { printf("%s", s); }
void output(char *string)  { print_string(string); }

// dictionary file name
char dictionary_file_name[] = "dictionary.txt";
// input file name
char input_file_name[] = "input.txt";
// content of input file
char content[MAX_INPUT_SIZE + 1];
// valid punctuation marks
char punctuations[] = ",.!?";
// tokens of input file
char tokens[MAX_INPUT_SIZE + 1][MAX_INPUT_SIZE + 1];
// number of tokens in input file
int tokens_number = 0;
// content of dictionary file
char dictionary[MAX_DICTIONARY_WORDS * MAX_WORD_SIZE + 1];

///////////////////////////////////////////////////////////////////////////////
/////////////// Do not modify anything above
///////////////////////////////////////////////////////////////////////////////

// You can define your global variables here!
char dictSorted[MAX_DICTIONARY_WORDS][MAX_WORD_SIZE + 1];
char tokensLower[MAX_INPUT_SIZE + 1][MAX_INPUT_SIZE + 1];
char tokensCorrect[MAX_INPUT_SIZE + 1][MAX_INPUT_SIZE + 3];
int dictLength = 0;
int wrongIndex[2049];
int wrongCounter = 0;
// Task B
void spell_checker() {

  int i = 0;//Loop Counter
  int j = 0;//Loop Counter
  int k;//Loop Counter
  char c;//Token character storage
  char d;//Dictionary character storage
  char c1;//Token character storage
  char d1;//Dictionary character storage

  //Moving dictionary to 2D array

  for(k = 0; k < MAX_DICTIONARY_WORDS * MAX_WORD_SIZE + 1; ++k){

    c = dictionary[k];
    if(c == '\n') { i++; dictLength++; j = 0;}
    else if(c == '\0') { break; }
    else {dictSorted[i][j] = c; j++;}

  }

  int correct = 0; //Used to tell if word is spelled correctly
  int mistake = 0; //Used to tell if alphabetic token matches current dictionary word
  int ascii; //Used to store ascii value of a character

  //Setting all alphabetical tokens to lower case
  
  for(i = 0; i < MAX_INPUT_SIZE + 1; i++){
    for(j = 0; j < MAX_INPUT_SIZE + 1; j++){
      c = tokens[i][j];
      ascii = (int)c;
        if(c >= 'A' && c <= 'Z'){
	ascii += 32;
	tokensLower[i][j] = (char) ascii;
      }else{
	tokensLower[i][j] = c;
      }

    }

  }


  int alpha; //Used to tell if token is alphabetic

  //checking for spelling mistakes

  for(i = 0; i < MAX_INPUT_SIZE + 1; ++i){
    correct = 0;
    for(j = 0; j < dictLength; j++){


      for(k = 0; k < MAX_WORD_SIZE; k++){
	mistake = 0;
	d =  dictSorted[j][k];
        c = tokensLower[i][k];
	c1 = tokensLower[i][k+1];
	d1 = dictSorted[j][k+1];
	//check for alphabetic
	if(c >= 'a' && c <= 'z') {
	  alpha = 1;
	  //if token character and dictionary character don't match then move onto next word in dictionary
	  if(c != d && c != '\0'&& c != '\n'){
	    mistake = 1;
	    break;
	  }else if(c1 == '\0' && d1 != '\0'){
	    mistake = 1;
	    break;
	  }
	}else{ alpha = 0; break; }
      }
      
      if (mistake == 0 || alpha == 0) {correct = 1; break;}
    }
    //if token did not match any of words in dictionary then add the index of the token to the wrongIndex array
    if (correct == 0) { wrongIndex[wrongCounter] = i; wrongCounter+=1;}
  }

  for(i = 0; i < MAX_INPUT_SIZE + 1; i++){
    for(j = 0; j < MAX_INPUT_SIZE + 1; j++){

      //copy tokens array to tokensCorrect array
      c = tokens[i][j];
      tokensCorrect[i][j] = c;

    }

  }


  int tokensLength;
  for(i = 0; i < 2049; i++){
    //cycle thorugh tokens array, only going to elements that were wrong, using the wrongIndex array
    //add underscore to start of token
    tokensCorrect[wrongIndex[i]][0]='_';
    for(j = 0; j < MAX_INPUT_SIZE + 1; j++){
      //store the character from the token
      c = tokens[wrongIndex[i]][j];
      if(c != '\0'){
	//shift token characters to right by one
	tokensCorrect[wrongIndex[i]][j+1] = tokens[wrongIndex[i]][j];
      }else{tokensLength = j-1; break;}

    }
    //add underscore to end of token
    tokensCorrect[wrongIndex[i]][tokensLength +2]='_';
    //stop when all incorrect tokens have been processed
    if(wrongIndex[i+1] == 0){break;}
  }
  
  return;
}

// Task B
void output_tokens() {
 
  int i;


  //output each element from the tokensCorrect array
  for(i = 0; i < 2049; ++i){
    if(tokens[i][0] == '\0') {break;}
    output(tokensCorrect[i]);
  }
  output("\n");

  return;
}

//---------------------------------------------------------------------------
// Tokenizer function
// Split content into tokens
//---------------------------------------------------------------------------
void tokenizer(){
  char c;

  // index of content 
  int c_idx = 0;
  c = content[c_idx];
  do {

    // end of content
    if(c == '\0'){
      break;
    }

    // if the token starts with an alphabetic character
    if(c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z') {
      
      int token_c_idx = 0;
      // copy till see any non-alphabetic character
      do {
        tokens[tokens_number][token_c_idx] = c;

        token_c_idx += 1;
        c_idx += 1;

        c = content[c_idx];
      } while(c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z');
      tokens[tokens_number][token_c_idx] = '\0';
      tokens_number += 1;

      // if the token starts with one of punctuation marks
    } else if(c == ',' || c == '.' || c == '!' || c == '?') {
      
      int token_c_idx = 0;
      // copy till see any non-punctuation mark character
      do {
        tokens[tokens_number][token_c_idx] = c;

        token_c_idx += 1;
        c_idx += 1;

        c = content[c_idx];
      } while(c == ',' || c == '.' || c == '!' || c == '?');
      tokens[tokens_number][token_c_idx] = '\0';
      tokens_number += 1;

      // if the token starts with space
    } else if(c == ' ') {
      
      int token_c_idx = 0;
      // copy till see any non-space character
      do {
        tokens[tokens_number][token_c_idx] = c;

        token_c_idx += 1;
        c_idx += 1;

        c = content[c_idx];
      } while(c == ' ');
      tokens[tokens_number][token_c_idx] = '\0';
      tokens_number += 1;
    }
  } while(1);
}
//---------------------------------------------------------------------------
// MAIN function
//---------------------------------------------------------------------------

int main (void)
{


  /////////////Reading dictionary and input files//////////////
  ///////////////Please DO NOT touch this part/////////////////
  int c_input;
  int idx = 0;
  
  // open input file 
  FILE *input_file = fopen(input_file_name, "r");
  // open dictionary file
  FILE *dictionary_file = fopen(dictionary_file_name, "r");

  // if opening the input file failed
  if(input_file == NULL){
    print_string("Error in opening input file.\n");
    return -1;
  }

  // if opening the dictionary file failed
  if(dictionary_file == NULL){
    print_string("Error in opening dictionary file.\n");
    return -1;
  }

  // reading the input file
  do {
    c_input = fgetc(input_file);
    // indicates the the of file
    if(feof(input_file)) {
      content[idx] = '\0';
      break;
    }
    
    content[idx] = c_input;

    if(c_input == '\n'){
      content[idx] = '\0'; 
    }

    idx += 1;

  } while (1);

  // closing the input file
  fclose(input_file);

  idx = 0;

  // reading the dictionary file
  do {
    c_input = fgetc(dictionary_file);
    // indicates the end of file
    if(feof(dictionary_file)) {
      dictionary[idx] = '\0';
      break;
    }
    
    dictionary[idx] = c_input;
    idx += 1;
  } while (1);

  // closing the dictionary file
  fclose(dictionary_file);
  //////////////////////////End of reading////////////////////////
  ////////////////////////////////////////////////////////////////

  tokenizer();
  
  spell_checker();
  
  output_tokens();

  return 0;
}
