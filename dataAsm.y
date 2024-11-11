%{ 
#include <stdio.h>  
#include <string.h>
#include <stdlib.h>

void yyerror(char *mensaje);
int yylex();
void nuevaTemp(char *s);
void nuevaEtiqueta(char *etiqueta);
extern char *yytext;
char etiquetaNoVerdad[10], etiquetaFin[10], etiquetaInicio[10], etiquetaSiguiente[10];
int etiquetaActual = 1;
%}

%union{
	char cadena[50];
}

%left  SUMA RESTA 
%left MULTI DIVI 
%right POTENCIA
%token AND OR 

%token PA PC
%token MAYORQUE MAYORIGUAL MENORIGUAL DIFERENTEQUE
%token IGUAL PUNTOCOMA IB FB COMA
%token DEC MAIN INPUT OUTPUT IF ELSE WHILE FOR 

%token <cadena>ENTERO 
%token <cadena> IDENTIFICADOR
%token <cadena> MENORQUE
%token <cadena> IGUALIGUAL
%type <cadena> expresion termino factor valor condicional condicion expresion_logica comparacion operador_condicional condicionFinal asignacion condicionWhile id



%%
programa    : 
            {
                printf(".model small\n");
                printf(".Stack\n");
                printf(".data\n");
                printf(".data\n  buffer db 6, ?, '     '\n" );

            }MAIN IB bloque FB  
            ;
bloque      : sentencia otra_sentencia
            ;
bloque_condicional: bloque 
            ;
otra_sentencia: sentencia otra_sentencia 
            | 
            ;
sentencia   :condicional 
            |asignacion PUNTOCOMA
            | lectura PUNTOCOMA
            | escritura PUNTOCOMA
            | declaracion PUNTOCOMA
            | bucle
            | whilecito
            ;
declaracion : DEC id lista_ids {printf("%s dw ?\n", $2);}
            ;
lista_ids   : COMA id lista_ids 
            | 
            ;
asignacion  : id IGUAL expresion 
            ;
expresion   : expresion SUMA termino  { nuevaTemp($$); printf("%s dw ? \n", $$); }
            | expresion RESTA termino   { nuevaTemp($$); printf("%s dw ? \n", $$); }
            | termino                   {}  
            ;
termino     : termino MULTI factor { nuevaTemp($$); printf("%s dw ? \n", $$);  }
            | termino DIVI factor   { nuevaTemp($$);printf("%s dw ? \n", $$);   }
            | factor               
            ;
factor      : PA expresion PC   
            | factor POTENCIA factor  { nuevaTemp($$); printf("%s dw ? \n", $$);    }
            | valor 
            ;
lectura     : INPUT id
            ; 
escritura   : OUTPUT id 
            ;
condicional : IF PA  condicionFinal PC IB bloque_condicional FB else
            ;
else        : ELSE IB  bloque FB 
            |
            ;
condicionFinal : condicion {
                nuevaEtiqueta(etiquetaNoVerdad);
                };
condicionWhile: condicion {
        nuevaEtiqueta(etiquetaSiguiente);
        };
condicionFor: condicion {
    nuevaEtiqueta(etiquetaSiguiente);
    };
condicion   : expresion_logica
            { 
                strcpy($$, $1);
            }
            |condicion OR expresion_logica 
            ;
expresion_logica :  expresion_logica AND comparacion 
            | comparacion
            {
                strcpy($$, $1);
            }
            ;
comparacion : valor operador_condicional valor 
            ;
operador_condicional : MENORQUE 
                    | MAYORQUE
                    | IGUALIGUAL
                    | MENORIGUAL
                    | MAYORIGUAL
                    | DIFERENTEQUE
                    ;
bucle       : FOR PA asignacion PUNTOCOMA condicionFor PUNTOCOMA asignacion PC IB bloque FB 
            ; 
whilecito:      WHILE PA condicionWhile PC IB  bloque FB
            ;
id          : IDENTIFICADOR 
            ;
valor       : IDENTIFICADOR   
            | ENTERO        
            ;



%%

int main(){
    yyparse();
    return 0;
}

void yyerror(char *mensaje){
    fprintf(stderr, "Error de sintaxis %s", mensaje);
}

void nuevaTemp(char *s){
	static int actual=1;
	sprintf(s,"t%d",actual++);
}
void nuevaEtiqueta(char *etiqueta) {
    static int etiquetaActual = 1;
    sprintf(etiqueta, "L%d", etiquetaActual++);}