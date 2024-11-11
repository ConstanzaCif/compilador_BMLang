%{
#include "final.tab.h"
%}

%%
"^"                         {return POTENCIA;}
"+"                         {return SUMA;}
"-"                         {return RESTA;}
"*"                         {return MULTI;}
"/"                         {return DIVI;}
"&&"                        {return AND;}
"||"                        {return OR;}
"("                         {return PA;}
")"                         {return PC;}
"<"                         {strcpy(yylval.cadena,yytext); return MENORQUE;}
">"                         {strcpy(yylval.cadena,yytext);return MAYORQUE;}
">="                        {strcpy(yylval.cadena,yytext);return MAYORIGUAL;}
"<="                        {strcpy(yylval.cadena,yytext);return MENORIGUAL;}
"<>"                        {strcpy(yylval.cadena,yytext);return DIFERENTEQUE;}
"="                         {return IGUAL;}
"=="                        {strcpy(yylval.cadena,yytext); return IGUALIGUAL;}
";"                         {return PUNTOCOMA;}
","                         {return COMA;}
"{"                         {return  IB;}
"}"                         {return FB;}
"DEC"                       {return DEC;}
"MAIN"                      {return MAIN;}
"INPUT"                     {return INPUT;}
"OUTPUT"                    {return OUTPUT;}
"IF"                        {return IF;}
"ELSE"                      {return ELSE;}
"while"                     {return WHILE;}
"for"                       {return FOR;}
[0-9]*                      {strcpy(yylval.cadena,yytext); return ENTERO;}
[a-zA-z][A-Za-z0-9]*        {strcpy(yylval.cadena,yytext); return IDENTIFICADOR;}
"/"."*/"                    {printf("COMENTARIO"); }
[[:space:]]|[[:space:]]+    { }
%%
int yywrap() {
    return 1;
}