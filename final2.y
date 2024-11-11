%{ 
#include <stdio.h>  
#include <string.h>
#include <stdlib.h>

#define LABEL_SIZE 10     
#define STACK_CAPACITY 10 

typedef struct {
    char data[STACK_CAPACITY][LABEL_SIZE];  // Arreglo de etiquetas 
    int top;                                // Índice del tope de la pila
} PilaEtiquetas;

void yyerror(char *mensaje);
int yylex();
void nuevaTemp(char *s);
void nuevaEtiqueta(char *etiqueta);
extern char *yytext;
char etiquetaNoVerdad[10], etiquetaFin[10], etiquetaInicio[10], etiquetaSiguiente[10];
int etiquetaActual = 1;
void generarPotencia(const char* base, int exponente, char* resultado);
PilaEtiquetas pila;
void iniciarStack(PilaEtiquetas *stack);
void pushLabel(PilaEtiquetas *stack, const char *label);
char *popLabel(PilaEtiquetas *stack);
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
                iniciarStack(&pila);
            } MAIN IB bloque FB  {printf("Programa terminado")}
            ;
bloque      : sentencia otra_sentencia
            ;
bloque_condicional: bloque 
    {
            nuevaEtiqueta(etiquetaFin);
        printf("    go to %s \n", etiquetaFin);
        char *etiquetaSalida = popLabel(&pila); 
        printf("%s: \n", etiquetaSalida);
    }
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
declaracion : DEC id lista_ids 
            ;
lista_ids   : COMA id lista_ids 
            | 
            ;
asignacion  : id IGUAL expresion {printf("    %s = %s \n", $$, $3)}
            ;
expresion   : expresion SUMA termino  { nuevaTemp($$); printf("    %s=%s+%s\n",$$,$1,$3); }
            | expresion RESTA termino   { nuevaTemp($$); printf("    %s=%s-%s\n",$$,$1,$3);   }
            | termino                   {sprintf($$, "%s", $1);}  
            ;
termino     : termino MULTI factor { nuevaTemp($$); printf("    %s=%s*%s\n",$$,$1,$3);   }
            | termino DIVI factor   { nuevaTemp($$); printf("   %s=%s/%s\n",$$,$1,$3);   }
            | factor               {sprintf($$, "%s", $1);} 
            ;
factor      : PA expresion PC   {sprintf($$, "%s", $2);}
            | factor POTENCIA factor  { nuevaTemp($$); generarPotencia($1, atoi($3), $$);  }
            | valor {sprintf($$, "%s", $1);} 
            ;
lectura     : INPUT id{printf("    call input\n"); printf("    pop %s\n", $2)} 
            ; 
escritura   : OUTPUT id {printf("   push %s\n", $2); printf("   call output\n");}
            ;
condicional : IF PA  condicionFinal PC IB bloque_condicional FB else
    {
        printf("%s: \n",etiquetaFin)
    }
            ;
else        : ELSE IB  bloque FB 
            |
            ;
condicionFinal : condicion {
                char etiqueta[10];
                nuevaEtiqueta(etiqueta);
                pushLabel(&pila, etiqueta);
                printf("    ifz %s goto %s \n", $$, etiqueta);
};
condicionWhile: condicion {

        nuevaEtiqueta(etiquetaNoVerdad);
        printf("    ifz %s goto %s \n", $1, etiquetaNoVerdad)
};
condicionFor: condicion {
    nuevaEtiqueta(etiquetaNoVerdad);
    printf("    ifz %s goto %s \n", $1, etiquetaNoVerdad)
}
condicion   : expresion_logica
            { 
                strcpy($$, $1);
            }
            |condicion OR expresion_logica 
            {
                nuevaTemp($$); printf("    %s=%s||%s\n",$$,$1,$3);
            }
            ;
expresion_logica :  expresion_logica AND comparacion 
            {
                nuevaTemp($$); 
                printf("    %s=%s&&%s\n",$$,$1,$3);
            }
            | comparacion
            {
                strcpy($$, $1);
            }
            ;
comparacion : valor operador_condicional valor {nuevaTemp($$); printf("    %s=%s %s %s\n",$$,$1,$2,$3)}
            ;
operador_condicional : MENORQUE 
                    | MAYORQUE
                    | IGUALIGUAL
                    | MENORIGUAL
                    | MAYORIGUAL
                    | DIFERENTEQUE
                    ;
bucle       : FOR PA asignacion PUNTOCOMA
            {
                nuevaEtiqueta(etiquetaInicio);
                printf("%s: \n", etiquetaInicio);       
            } condicionFor PUNTOCOMA asignacion PC IB bloque FB 
            {
                printf("    goto %s \n", etiquetaInicio);
                printf("%s: \n", etiquetaNoVerdad);
            }
            ; 
whilecito:      WHILE PA 
                {
                    nuevaEtiqueta(etiquetaInicio);
                    printf("%s: \n", etiquetaInicio);
                }
                condicionWhile PC IB  bloque FB
                {
                    printf("    goto %s \n", etiquetaInicio);
                    printf("%s: \n", etiquetaNoVerdad);
                }
            ;
id          : IDENTIFICADOR 
            ;
valor       : IDENTIFICADOR   {sprintf($$, "%s", yytext);}
            | ENTERO         {sprintf($$, "%s", yytext);}
            ;



%%

int main(){
    yyparse();
    return 0;
}

void yyerror(char *mensaje){
    printf("Error de sintaxis");
}

void nuevaTemp(char *s){
	static int actual=1;
	sprintf(s,"t%d",actual++);
}
void nuevaEtiqueta(char *etiqueta) {
    static int etiquetaActual = 1;
    sprintf(etiqueta, "L%d", etiquetaActual++);}

void iniciarStack(PilaEtiquetas *stack) {
    stack->top = -1;
}
void generarPotencia(const char* base, int exponente, char* resultado) {
    char temp[10];
    strcpy(resultado, base);  

    for (int i = 1; i < exponente; i++) {
        nuevaTemp(temp);
        printf("%s = %s * %s\n", temp, resultado, base);
        strcpy(resultado, temp);
        }
}
//Apilar etiqueta
void pushLabel(PilaEtiquetas *stack, const char *label) {
    if (stack->top == STACK_CAPACITY - 1) {
        fprintf(stderr, "Error: pila de etiquetas llena\n");
        exit(1);
    }
    stack->top++;
    strncpy(stack->data[stack->top], label, LABEL_SIZE);
}

// Desapila la última etiqueta
char *popLabel(PilaEtiquetas *stack) {
    if (stack->top == -1) {
        fprintf(stderr, "Error: pila de etiquetas vacía\n");
        exit(1);
    }
    return stack->data[stack->top--];
}