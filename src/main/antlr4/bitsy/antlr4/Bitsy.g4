grammar Bitsy;

tokens { INDENT, DEDENT }

@lexer::members {

  // A queue where extra tokens are pushed on (see the NEWLINE lexer rule).         
  private java.util.Queue<Token> tokens = new java.util.LinkedList<>();
  
  // The stack that keeps track of the indentation level.
  private java.util.Stack<Integer> indents = new java.util.Stack<>();
  
  // The amount of opened braces, brackets and parenthesis.
  private int opened = 0;

  @Override
  public void emit(Token t) {
    super.setToken(t);
    tokens.offer(t);
  }

  @Override
  public Token nextToken() {

    // Check if the end-of-file is ahead and there are still some DEDENTS expected.
    if (_input.LA(1) == EOF && !this.indents.isEmpty()) {

      // First emit an extra line break that serves as the end of the statement.
      this.emit(new CommonToken(BitsyParser.NEWLINE, "\n"));

      // Now emit as much DEDENT tokens as needed.
      while (!indents.isEmpty()) {
        this.emit(new CommonToken(BitsyParser.DEDENT, "DEDENT"));
        indents.pop();
      }
    }

    Token next = super.nextToken();

    return tokens.isEmpty() ? next : tokens.poll();
  }  
  
  // Calculates the indentation of the provided spaces, taking the 
  // following rules into account:
  //
  // "Tabs are replaced (from left to right) by one to eight spaces 
  //  such that the total number of characters up to and including 
  //  the replacement is a multiple of eight [...]"
  //
  //  -- https://docs.python.org/3.1/reference/lexical_analysis.html#indentation
  static int getIndentationCount(String spaces) {
    
    int count = 0;
          
    for (char ch : spaces.toCharArray()) {
      switch (ch) {
        case '\t':
          count += 8 - (count % 8);
          break;
        default:
          // A normal space char.
          count++;
      }
    }
          
    return count;                                
  }
}

parse 
 : block EOF
 ;
 
block
 : (statement | NEWLINE)*
 ;

statement
 : functionCall
 | assignment
 | ifStatement
 | forStatement
 | whileStatement
 | functionDecl
 | returnStatement
 ;

returnStatement
 : RETURN expression 
 ;
 
functionCall
 : IDENTIFIER '(' exprList? ')'                     #identifierFunctionCall 
 | 'println' ( '(' expression? ')' | expression? )  #printFunctionCall            
 | 'assert' expression                              #assertFunctionCall
 ;
 
assignment
 : IDENTIFIER '=' expression
 ;
 
ifStatement
 : ifStat elseIfStat* elseStat?
 ;

ifStat
 : IF expression NEWLINE INDENT block DEDENT
 ;

elseIfStat
 : ELSE IF expression NEWLINE INDENT block DEDENT
 ;

elseStat
 : ELSE NEWLINE INDENT block DEDENT
 ;

functionDecl
 : DEF IDENTIFIER '(' argumentList? ')' (':' type)? NEWLINE INDENT block DEDENT
 ;
  
forStatement
 : FOR IDENTIFIER '=' expression TO expression NEWLINE INDENT block DEDENT
 ;
 
whileStatement
 : WHILE expression NEWLINE INDENT block DEDENT
 ;

argument
 : IDENTIFIER ':' type
 ;  

type
 : 'string'
 | 'number'
 | 'boolean'
 | 'null'
 | 'void'
 | 'list'
 | 'map'
 ;
 
argumentList
 : argument (',' argument)*
 ;

idList
 : IDENTIFIER (',' IDENTIFIER)*
 ;

exprList
 : expression (',' expression)*
 ;

expression
 : '-' expression                           #unaryMinusExpression
 | '!' expression                           #notExpression
 | expression '^' expression                #powerExpression
 | expression '*' expression                #multiplyExpression
 | expression '/' expression                #divideExpression
 | expression '%' expression                #modulusExpression
 | expression '+' expression                #addExpression
 | expression '-' expression                #subtractExpression
 | expression '>=' expression               #gtEqExpression
 | expression '<=' expression               #ltEqExpression
 | expression '>' expression                #gtExpression
 | expression '<' expression                #ltExpression
 | expression '==' expression               #eqExpression
 | expression '!=' expression	            #notEqExpression
 | expression '&&' expression               #andExpression
 | expression '||' expression               #orExpression
 | expression '?' expression ':' expression #ternaryExpression
 | NUMBER 						            #numberExpression
 | BOOL   						            #boolExpression
 | NULL										#nullExpression
 | functionCall 						    #functionCallExpression
 | list										#listExpression
 | IDENTIFIER   				            #identifierExpression
 | STRING 						            #stringExpression
 | '(' expression ')' 			            #expressionExpression
 ;
 
list
 : '[' exprList? ']'
 | '{' exprList? '}'
 ; 

IF       : 'if';
ELSE     : 'else'; 
NULL 	 : 'null';
FOR      : 'for';
TO       : 'to';
WHILE    : 'while';
DEF      : 'def';
RETURN   : 'return';

BOOL
 : 'true' 
 | 'false'
 ;

NUMBER
 : INT ('.' DIGIT*)?
 ;

IDENTIFIER
 : [a-zA-Z_] [a-zA-Z_0-9]*
 ; 

STRING
 : ["] (~["\r\n] | '\\\\' | '\\"')* ["]
 | ['] (~['\r\n] | '\\\\' | '\\\'')* [']
 ;
  
NEWLINE
 : ( '\r'? '\n' | '\r' ) SPACES?
   {
     String spaces = getText().replaceAll("[\r\n]+", "");
     int next = _input.LA(1);

     if (opened > 0 || next == '\r' || next == '\n' || next == '#') {
       // If we're inside a list or on a blank line, ignore all indents, 
       // dedents and line breaks.
       skip();
     }
     else {
       emit(new CommonToken(NEWLINE, "\n"));

       int indent = getIndentationCount(spaces);
       int previous = indents.isEmpty() ? 0 : indents.peek();

       if (indent == previous) {
         // skip indents of the same size as the present indent-size
         skip();
       }
       else if (indent > previous) {
         indents.push(indent);
         emit(new CommonToken(BitsyParser.INDENT, "INDENT"));
       }
       else {
         // Possibly emit more than 1 DEDENT token.
         while(!indents.isEmpty() && indents.peek() > indent) {
           emit(new CommonToken(BitsyParser.DEDENT, "DEDENT"));
           indents.pop();
         }
       }
     }
   }
 ;
 
SKIP
 : ( SPACES | COMMENT | LINE_JOINING ) -> skip
 ;
  
fragment SPACES
 : [ \t]+
 ;
 
fragment COMMENT
 : ('//' ~[\r\n]* | '/*' .*? '*/')
 ;

fragment LINE_JOINING
 : '\\' SPACES? ( '\r'? '\n' | '\r' )
 ;

fragment INT
 : [1-9] DIGIT*
 | '0'
 ;
 
fragment DIGIT 
 : [0-9]
 ;