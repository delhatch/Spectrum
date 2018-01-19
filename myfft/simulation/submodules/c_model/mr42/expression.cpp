#include "expression.h"
#include "fpCompiler.h"
#include <iostream>

expression::expression(fpCompiler* lop_, fpCompiler* rop_, int op_)
{
    lop = lop_;
    rop = rop_;
    op = op_;
}

expression::expression(expression const& other)
{
    copy(other);
}

void expression::copy(expression const& other)
{
    lop = other.lop ? new fpCompiler (*other.lop) : 0;
    rop = other.rop ? new fpCompiler (*other.rop) : 0;
    op = other.op;

}

expression::~expression()
{
    //cout << "destructor "<< endl;
    delete rop;
    delete lop;
}

fpCompiler* expression::getLop()
{
    return lop;
}

fpCompiler* expression::getRop()
{
    return rop;
}

int expression::getOp()
{
    return op;
}

expression  expression::operator=( const expression& num)
{
#ifdef DEBUGFPCOMPILER
    cout << "expression: operator= : Evaluating expression -> expression " << endl;
#endif
    return num;
}