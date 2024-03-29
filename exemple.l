/*
*         Maria Sauras Fernandez
*       Stage 3 of Minijulia Compiler
*           Lexical class (Flex)
*/

%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "exemple.tab.h"
#include "exemple_funcions.h"
#include "symtab.h"

%}

%option yylineno
%option noyywrap
%option noinput
%option nounput

/* Definimos matrix y lo usaremos tanto para los vectores como para las matrices*/

%S MATRIX

lletra  [a-zA-Z{}]
digit   [0-9]
float   {digit}+"."{digit}*("e-"{digit}+)? 
text    ["][^_\n\t\"\']*["] 
comment ([#][^\n\"\']* | [#=][^\"\']*[=#])
boolean (true|false)

%%

"in"                        { return IN; }

"for"                       { return FOR; }

"while"                      { return WHILE; }

"if"                        { return IF; }

"elseif"                    { return ELSEIF; }

"else"                      { return ELSE; }

"::"                        { return DDP; }

":"                         { return DP; }

"return"                    { return RETURN; }

"end"                       { return END; }

"function"                  { return FUNC; }

{boolean}                  {
                              if (strcmp(strdup(yytext),"false") == 0)
                                yylval.cl.st.value_data.boolean = 0;
                              else
                                yylval.cl.st.value_data.boolean = 1;
                                
                              yylval.cl.st.value_data.ident.value_type = BOOL_TYPE;
                              return BOOLEAN; 
                            }
            


{lletra}({lletra}|{digit})*_*({lletra}|{digit})* {
                              yylval.cl.st.value_data.ident.lexema = strdup(yytext);
                              yylval.cl.st.value_data.ident.lenght = yyleng;
                              yylval.cl.st.value_data.ident.line = yylineno;
                              yylval.cl.st.value_data.ident.value_type = UNKNOWN_TYPE;
                              return ID;
                            }

">"                         { return GREATERTHAN; }

">="                        { return GREATEREQ; }

"<"                         { return LESSTHAN; }

"<="                        { return LESSEQ; }

"=="                        { return EQ; }

"!="                        { return DIF; }

"!"                         { return NOT; }

"&&"                        { return AND; }

"||"                        { return OR; }
                            

"("                         { return OP; }

")"                         { return CP; }

"+"                         { return SUMA; }

"-"                         { return RESTA; }

"*"                         { return MUL; } 

"/"                         { return DIV; }

"%"                         { return MOD; }

"^"                         { return POW; }                    

"="                         { return ASSIGN; }

","                         { return COMMA; } 

"["" "*                     { BEGIN MATRIX; return OC; }

<MATRIX>" "*;" "*           { return PC; }

<MATRIX>" "+                { return SPACE; }        

" "*"]"                     { BEGIN INITIAL; return CC; }

{text}                      {
                              yylval.cl.st.value_data.ident.lexema = strdup(yytext);
                              yylval.cl.st.value_data.ident.lenght = yyleng;
                              yylval.cl.st.value_data.ident.value_type = STRING_TYPE;
                              return STRING;
                            } 


{float}                     {
                              yylval.cl.st.value_data.real = atof(yytext);
                              return FLOAT;
                            }


{digit}+                    {
                              yylval.cl.st.value_data.enter = atoi(yytext);
                              return INTEGER;
                            }

          
^[ \t]*[\n]                 {}

[\n]                        { return ENDLINE; }

.                           {}

%%
