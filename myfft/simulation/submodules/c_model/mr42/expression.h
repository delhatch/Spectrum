#include <iostream>

#ifndef EXPRESSION_H
#define EXPRESSION_H
#define ADD 0
#define SUB 1
#define MULT 2
#define ADD_MR42 3
#define SUB_MR42 4
#define MULT_MR42 5
#define MULT_MR42_SVOPT 6
#define SNORM 7

using namespace std;

class fpCompiler;

class expression
{
public:
    expression(fpCompiler* lop_, fpCompiler* rop_, int op_);
    expression(expression const& other);
    ~expression();

    fpCompiler* getLop();
    fpCompiler* getRop();
    int getOp() ;

    expression  operator=( const expression& num);

private:
    void copy(expression const& other);
    fpCompiler* lop;
    fpCompiler* rop;
    int op;
};

#endif