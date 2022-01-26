/*
*         Maria Sauras Fernandez
*   Second part of Minijulia Compiler
*        Sintactical class (BISON)
*/

%{

#include <stdio.h>
#include <stdlib.h>
extern FILE *yyout;
extern int yylineno;
extern int yylex();
/*extern void yyerror(char*);*/

/*Array to save the 3AC code*/

char* instructions_buffer[1000];

/* Control Var to generated line number of the instruction and temporally variables*/
unsigned long ln_inst = 1;

unsigned long tmp_cnt = 0;

%}

%code requires {
  /* Les definicions que s'utilitzen al %union han d'estar aqui */
  #include "exemple_dades.h"
  #include "exemple_funcions.h"
  #include "symtab.h"
}

%union{
  sym_value_type st;
}

/* Identifiers, variables and types */
%token <st.value_data.sense_valor> ASSIGN ENDLINE
%token <st.value_data.enter> INTEGER
%token <st.value_data.ident> ID
%token <st.value_data.real> FLOAT
%token <st.value_data.ident> STRING

/* Arithmetical operators */
%token  SUMA RESTA MUL DIV MOD POW 

/* Symbols */
%token OP CP OC CC PC SPACE COMMA FP_D

/* Funcions and Procedures*/
%token END DDP RETURN FUNC

%type <st> programa
%type <st> expressio_aritmetica
%type <st> valor
%type <st> sumrest mullist powlist
%type <st> matrix row  matrix_value 

%type <st> func_header
%type <st> parameters

/* Declarations */
%type main
%type function
%type sentences_list
%type start



%start programa

%%

programa : function_declaration main {
                                      emet(NULL,0,NULL,"HALT",NULL);
                                      emet(NULL,0,NULL,"END",NULL);

                                      for(int i=0; i<ln_inst-1; i++){
                                        fprintf(yyout,"%s\n",instructions_buffer[i]);
                                        free(instructions_buffer[i]);
                                      }
}

function_declaration : function_declaration function {
                                                      for(int i=0; i<ln_inst-1; i++){
                                                        fprintf(yyout,"%s\n",instructions_buffer[i]);
                                                        free(instructions_buffer[i]);
                                                      }
                                                      ln_inst = 1;
                                                      tmp_cnt = 0;                                                 
                                                     }

function : FUNC func_header ENDLINE sentences_list END ENDLINE {
                                                                emet(NULL,0,NULL,"END\n",NULL);
                                                                pop_scope();
                                                               }



parameters : parameters COMMA ID DDP ID   { $$.value_data.cont_params += 1; treat_parameter(&$$, $3, $5); }
           | ID DDP ID                    { $$.value_data.cont_params = 1; treat_parameter(&$$, $1, $3); }
           |                              { $$.value_data.cont_params = 0; }
            

func_header : ID OP parameters CP {
                                    emet(NULL,0,NULL,"START",&$1);
                                    $1.value_type = FUNCTION; /* El valor tipo de ID es FUNCTION */
                                    $1.value_data.cont_params = $3.value_data.cont_params;
                                    sym_enter($1.value_data.ident.lexema, &$1);
                                    push_scope();
                                  }

main : start sentences_list

start : { emet(NULL, 0, NULL, "START main", NULL); }                               


expressio_aritmetica : ID ASSIGN sumrest ENDLINE  {
                          $$.value_type = $3.value_type;
                          sym_enter($1.lexema, &$3);
                          $$ = $3;

                          if($$.value_type == INT_TYPE){
                            fprintf(yyout, "ID: %s value: %ld\n",$1.lexema, $3.value_data.enter);
                          } else if($$.value_type == FLOAT_TYPE){
                            fprintf(yyout, "ID: %s value: %.2f\n",$1.lexema, $3.value_data.real);
                          }else if($$.value_type == STRING_TYPE){
                            fprintf(yyout, "ID: %s value: %s\n",$1.lexema, $3.value_data.ident.lexema);
                          }else if ($$.value_type == MATRIX_TYPE){
                              if($$.value_data.matrix_type == INT_TYPE) {
                              int pos;
                              if($$.value_data.row > 1) fprintf(yyout, "INTEGER MATRIX [");
                              fprintf(yyout, "INTEGER VECTOR [");
                              for(int i= 0; i<$$.value_data.row; i++) 
                                for(int j= 0; j<$$.value_data.column; j++){
                                  pos = $$.value_data.column*i+j;
                                  fprintf(yyout, "%ld ",$$.value_data.integer_matrix[pos]);
                                }
                            } else if($$.value_data.matrix_type == FLOAT_TYPE) {
                                int pos;
                                if($$.value_data.row > 1) fprintf(yyout, "FLOAT MATRIX [");
                                fprintf(yyout, "FLOAT VECTOR [");
                                for(int i= 0; i<$$.value_data.row; i++) 
                                  for(int j= 0; j<$$.value_data.column; j++){
                                    pos = $$.value_data.column*i+j;
                                    fprintf(yyout, "%.2f ",$$.value_data.float_matrix[pos]);
                                  }
                            } else yyerror("Only accept Integer or Float matrix");
                            fprintf(yyout,"]\n");
                            fprintf(yyout,"Num de columnas Vector/Matrix: %ld\n", $$.value_data.column);
                            if($$.value_data.row > 1) fprintf(yyout,"Num de Filas Matrix: %ld\n", $$.value_data.row);
                            fprintf(yyout,"Num de elems Vector/Matrix: %ld\n", $$.value_data.num_elems);
                          }
                        }
                      | sumrest ENDLINE  {
                          $$.value_type = $1.value_type;
                          if($$.value_type == INT_TYPE){
                            fprintf(yyout, "INT value: %ld\n", $1.value_data.enter);
                            $$.value_data.enter= $1.value_data.enter;
                          } else if($$.value_type == FLOAT_TYPE){
                            fprintf(yyout, "FLOAT value: %f\n", $1.value_data.real);
                            $$.value_data.real = $1.value_data.real;
                          }else{
                            fprintf(yyout, "STRING value: %s\n", $1.value_data.ident.lexema);
                            $$.value_data.ident.lexema = $1.value_data.ident.lexema;
                          }
                        }


/* Priority Hierarchy */


matrix_value : FLOAT    { $$.value_type = FLOAT_TYPE; $$.value_data.real = $1;  }
             | INTEGER  { $$.value_type = INT_TYPE; $$.value_data.enter = $1; }
 

matrix : matrix PC row          { row_value(&$$,$1,$3); }
       | row                    { $$.value_data.row = 1; }

row : row SPACE matrix_value    { col_value(&$$,$1,$3); }
    | matrix_value              { col_ini(&$$, $1);}

sumrest : sumrest SUMA mullist  { sum_op(&$$,$1,$3); }
        | sumrest RESTA mullist { rest_op(&$$,$1,$3); }
        | mullist

mullist : mullist MUL powlist { mul_op(&$$,$1,$3); } 
        | mullist DIV powlist { div_op(&$$,$1,$3); }
        | mullist MOD powlist { mod_op(&$$,$1,$3); }
        | powlist

powlist : powlist POW valor { pow_op(&$$,$1,$3); }
        | valor

valor : FLOAT                                { $$.value_type = FLOAT_TYPE; $$.value_data.real = $1; }
      | INTEGER                              { $$.value_type = INT_TYPE; $$.value_data.enter = $1; }
      | STRING                               { $$.value_type = STRING_TYPE; $$.value_data.ident.lexema = $1.lexema; }
      | OP sumrest CP                        { $$ = $2; }
      | ID                                   { if(sym_lookup($1.lexema, &$$) == SYMTAB_NOT_FOUND) yyerror("Var doesn't exit"); }
      | OC matrix CC                         { $$ = $2; }
      | ID OC sumrest CC                     { acces_vector(&$$, $1.lexema, $3); }
      | ID OC sumrest COMMA sumrest CC       { acces_matrix(&$$, $1.lexema, $3, $5); }
      | FP_D OP sumrest COMMA sumrest CP     { div_op(&$$,$3,$5); }                 

%%
