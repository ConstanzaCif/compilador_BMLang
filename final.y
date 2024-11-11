%{ 
#include <stdio.h>  
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

void yyerror(char *mensaje);
int yylex();
void nuevaTemp(char *s);
void nuevaEtiqueta(char *etiqueta);
extern char *yytext;
char etiquetaNoVerdad[10], etiquetaFin[10], etiquetaInicio[10], etiquetaSiguiente[10], etiquetaPotencia[10], etiquetaPotenciaFin[10], etiquetaEntrada[10], etiquetaConvertir[10], etiquetaImpresion[10];
int etiquetaActual = 1, potenciaActual = 1, finPotenciaActual = 1, enteroActual = 1, impresionActual =1;
void generarPotencia(const char* base, int exponente, char* resultado);
int esNumero(const char* cadena);
void nuevaPotencia(char *etiqueta, char *etiqueta1);
void nuevoEntero(char *etiqueta);
void enteroCadena(char *etiqueta);
void imprimir(char *etiqueta);
char buffer[50];
#define LABEL_SIZE 10     
#define STACK_CAPACITY 10 

typedef struct {
    char data[STACK_CAPACITY][LABEL_SIZE];  // Arreglo de etiquetas 
    int top;                                // Índice del tope de la pila
} PilaEtiquetas;
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
%type <cadena> expresion termino factor valor condicional comparacion  condicionFinal asignacion condicionWhile id



%%
programa    :   {
                    iniciarStack(&pila);
                    printf(".code\n");
                    printf("Start: \n");
                }   MAIN IB bloque FB  
                {
                    printf("    mov ax, 4c00h\n");
                    printf("    int 21h\n");
                }
            ;
bloque      : sentencia otra_sentencia
            ;
bloque_condicional: bloque 
    {
            nuevaEtiqueta(etiquetaFin);
        printf("    jmp %s \n", etiquetaFin);
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
asignacion  : id IGUAL expresion 
            {
                printf("    mov [%s], %s\n", $1, $3);
            }
            ;
expresion   : expresion SUMA termino  
            { 
                nuevaTemp($$); 
                printf("    mov ax, %s \n", esNumero($1) ? $1 : (sprintf(buffer, "[%s]", $1), buffer));
                printf("    add ax, %s\n", esNumero($3) ? $3 : (sprintf(buffer, "[%s]", $3), buffer));
                printf("    mov %s, ax\n", $$); 
            }
            | expresion RESTA termino   
            { 
                nuevaTemp($$); 
                printf("    mov ax, %s \n", esNumero($1) ? $1 : (sprintf(buffer, "[%s]", $1), buffer));
                printf("    add ax, %s\n", esNumero($3) ? $3 : (sprintf(buffer, "[%s]", $3), buffer));
                printf("    mov %s, ax\n", $$); 
            }
            | termino                   {sprintf($$, "%s", $1);}  
            ;
termino     : termino MULTI factor 
            { 
                nuevaTemp($$); 
                printf("    mov ax, %s \n", esNumero($1) ? $1 : (sprintf(buffer, "[%s]", $1), buffer));
                printf("    mov bx, %s \n", esNumero($3) ? $3 : (sprintf(buffer, "[%s]", $3), buffer));
                printf("    imul bx\n");
                printf("    mov %s, ax\n", $$); 
            }
            | termino DIVI factor   
            { 
                nuevaTemp($$); 
                printf("    mov ax, %s \n", esNumero($1) ? $1 : (sprintf(buffer, "[%s]", $1), buffer));
                printf("    mov bx, $s \n", esNumero($3) ? $3 : (sprintf(buffer, "[%s]", $3), buffer));
                printf("    idiv bx\n" );
                printf("    mov %s, ax\n", $$); 
            }
            | factor               {sprintf($$, "%s", $1);} 
            ;
factor      : PA expresion PC   {sprintf($$, "%s", $2);}
            | factor POTENCIA factor  
            { 
                nuevaTemp($$); 
                nuevaPotencia(etiquetaPotencia, etiquetaPotenciaFin);
                printf("    mov cx, %s \n", esNumero($3) ? $3 : (sprintf(buffer, "[%s]", $1), buffer)); 
                printf("    mov ax, %s\n", esNumero($1) ? $3 : (sprintf(buffer, "[%s]", $1), buffer)); 
                printf("    mov bx, ax\n"); 
                printf("    dec cx\n"); 
                printf("    JZ %s\n", etiquetaPotenciaFin); 
                printf("%s:\n", etiquetaPotencia); 
                printf("    mul bx \n"); 
                printf("    Loop %s\n", etiquetaPotencia); 
                printf("%s:\n", etiquetaPotenciaFin); 
                printf("    mov %s, ax \n", $$); 
            }
            | valor 
            {
                sprintf($$, "%s", $1); 
            }
            ;
lectura     : INPUT id
            {
                nuevoEntero(etiquetaEntrada);
                printf("    mov ah, 0Ah\n"); 
                printf("    LEA DX, [buffer]\n");
                printf("    int 21h\n"); 
                printf("    mov SI, 2\n"); 
                printf("    mov cx, [buffer+1]\n"); 
                printf("    mov ax, 0\n");
                printf("%s: \n", etiquetaEntrada);
                printf("    mov bl, [buffer + SI]\n");
                printf("    sub bl, '0'\n");
                printf("    mov dx, ax\n");
                printf("    mov ax, 10\n");
                printf("    mul dx\n");
                printf("    add ax, bl\n");
                printf("    INC SI\n");
                printf("    LOOP %s\n", etiquetaEntrada);
                printf("    mov %s, ax\n", esNumero($2) ? $2 : (sprintf(buffer, "[%s]", $2), buffer));
            } 
            ; 
escritura   : OUTPUT id 
            {
                enteroCadena(etiquetaConvertir);
                imprimir(etiquetaImpresion);
                printf("    mov ax, [%s] \n", $2);
                printf("    mov cx, 0 \n");
                printf("    mov bx, 10 \n");
                printf("%s: \n", etiquetaConvertir);
                printf("    xor dx, dx\n");
                printf("    div bx\n");
                printf("    add dl, '0' \n");
                printf("    push dx \n");
                printf("    inc cx\n");
                printf("    cmp ax, 0 \n");
                printf("    jne %s \n", etiquetaConvertir);
                
                printf("%s: \n", etiquetaImpresion);
                printf("    pop dx\n");
                printf("    mov ah, 2 \n");
                printf("    int 21h\n");
                printf("    loop %s\n", etiquetaImpresion);
            }
            ;
condicional : IF PA  condicionFinal PC IB bloque_condicional FB else
    {
        printf("%s: \n",etiquetaFin)
    }
            ;
else        : ELSE IB  bloque FB 
            |
            ;
condicionFinal : comparacion 
                ;
condicionWhile: comparacion 
            ;
condicionFor: comparacion 
            ;
comparacion : valor MENORQUE valor 
            {
                char etiqueta[10];
                nuevaEtiqueta(etiqueta);
                pushLabel(&pila, etiqueta);
                printf("    mov ax, %s \n", esNumero($1) ? $1: (sprintf(buffer, "[%s]", $1), buffer));
                printf("    cmp ax, %s \n", esNumero($3) ? $3: (sprintf(buffer, "[%s]", $3), buffer));
                printf("    jnl %s\n", etiqueta);
            }
            | valor MAYORQUE valor
            {
                char etiqueta[10];
                nuevaEtiqueta(etiqueta);
                pushLabel(&pila, etiqueta);
                printf("    mov ax, %s \n", esNumero($1) ? $1: (sprintf(buffer, "[%s]", $1), buffer));
                printf("    cmp ax, %s \n", esNumero($3) ? $3: (sprintf(buffer, "[%s]", $3), buffer));
                printf("    jng %s\n", etiqueta);
            }
            | valor IGUALIGUAL valor
            {
                char etiqueta[10];
                nuevaEtiqueta(etiqueta);
                pushLabel(&pila, etiqueta);
                printf("    mov ax, %s \n", esNumero($1) ? $1: (sprintf(buffer, "[%s]", $1), buffer));
                printf("    cmp ax, %s \n", esNumero($3) ? $3: (sprintf(buffer, "[%s]", $3), buffer));
                printf("    jne %s\n", etiqueta);
            }
            | valor MENORIGUAL valor
            {
                char etiqueta[10];
                nuevaEtiqueta(etiqueta);
                pushLabel(&pila, etiqueta);
                printf("    mov ax, %s \n", esNumero($1) ? $1: (sprintf(buffer, "[%s]", $1), buffer));
                printf("    cmp ax, %s \n", esNumero($3) ? $3: (sprintf(buffer, "[%s]", $3), buffer));
                printf("    jg %s\n", etiqueta);
            }
            | valor MAYORIGUAL valor
            {
                char etiqueta[10];
                nuevaEtiqueta(etiqueta);
                pushLabel(&pila, etiqueta);
                printf("    mov ax, %s \n", esNumero($1) ? $1: (sprintf(buffer, "[%s]", $1), buffer));
                printf("    cmp ax, %s \n", esNumero($3) ? $3: (sprintf(buffer, "[%s]", $3), buffer));
                printf("    jl %s\n", etiqueta);
            }
            | valor DIFERENTEQUE valor
            {
                char etiqueta[10];
                nuevaEtiqueta(etiqueta);
                pushLabel(&pila, etiqueta);
                printf("    mov ax, %s \n", esNumero($1) ? $1: (sprintf(buffer, "[%s]", $1), buffer));
                printf("    cmp ax, %s \n", esNumero($3) ? $3: (sprintf(buffer, "[%s]", $3), buffer));
                printf("    je %s\n", etiqueta);
            }
            ;
bucle       : FOR PA asignacion PUNTOCOMA
            {
                nuevaEtiqueta(etiquetaInicio);
                printf("%s: \n", etiquetaInicio);       
            } condicionFor PUNTOCOMA asignacion PC IB bloque FB 
            {
                printf("    jmp %s \n", etiquetaInicio);
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
                    printf("    jmp %s \n", etiquetaInicio);
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
    sprintf(etiqueta, "L%d", etiquetaActual++);
}
void nuevaPotencia(char *etiqueta, char *etiqueta1) {
    static int potenciaActual = 1;
    static int finPotenciaActual = 1;
    sprintf(etiqueta, "Potencia_loop%d", potenciaActual++);
    sprintf(etiqueta1, "FinPotencia%d", finPotenciaActual++);
}
void nuevoEntero(char *etiqueta) {
    static int enteroActual = 1;
    sprintf(etiqueta, "Entrada_loop%d", enteroActual++);
}
void enteroCadena(char *etiqueta) {
    static int cadenaActual = 1;
    sprintf(etiqueta, "convertir%d", cadenaActual++);
}
void imprimir(char *etiqueta) {
    static int impresionActual = 1;
    sprintf(etiqueta, "imprimir%d", impresionActual++);
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
int esNumero(const char* cadena) {
    for (int i = 0; cadena[i] != '\0'; i++) {
        if (!isdigit(cadena[i])) {
            return 0; 
        }
    }
    return 1;
}
void iniciarStack(PilaEtiquetas *stack) {
    stack->top = -1;
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