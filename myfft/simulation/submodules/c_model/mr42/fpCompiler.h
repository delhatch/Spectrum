#ifndef FPCOMPILER_H
#define FPCOMPILER_H

#define SC_INCLUDE_FX
#include "systemc.h"
#include "expression.h"
#include "math.h"
#include <iostream>
#include <vector>
#define EXPLENGTH 10
#define SIGLENGTH 32
#define fpExponent sc_fixed<EXPLENGTH,EXPLENGTH>
#define fpSignificand sc_fixed<SIGLENGTH,SIGLENGTH>
#define fpSign sc_fixed<1,1>
#define fpInternal sc_fixed<SIGLENGTH+EXPLENGTH+2,SIGLENGTH+EXPLENGTH+2>

using namespace std;

class expression;
class fpCompiler
{
public:
    // initialise from float.
    fpCompiler();
    fpCompiler(float num);
    fpCompiler(float num, int flag);
    fpCompiler(fpCompiler const& other);
    ~fpCompiler();

    // get set methods
    fpInternal getNumber();
    fpExponent getExponent();
    fpInternal getNumber() const ;
    fpExponent  getExponent() const;
    fpSignificand getSignificand();
    fpSign getSign();
    expression* getExpression();
    expression* getExpression() const;
    void setExpression(expression*);
    void clearObj();
    void signNorm();
    fpCompiler mult(fpCompiler num, int svopt);
    fpCompiler add(fpCompiler num);
    fpCompiler sub(fpCompiler num);
    float cast2float();

    // operator overloads
    fpCompiler operator+(fpCompiler num);
    fpCompiler operator-(fpCompiler num);
    fpCompiler operator*(fpCompiler num);
    fpCompiler operator=(const fpCompiler& num);
    fpCompiler operator=( const float& num);
    operator float();
    void printExpressionTree();

    // bit accurate models of * + etc, bit accurate models of hardware modules
    // fpInternal fpCompiler::fpmul(fpCompiler dataa, fpCompiler datab);
    // fpInternal fpCompiler::fpadd(fpCompiler dataa, fpCompiler datab, int addsub);
    fpInternal castftox(sc_fixed<32, 32> innum);
    fpInternal castftox_mr42(sc_fixed<32, 32> innum, int twid_flag);
    sc_fixed<32, 32> castxtof();
    sc_fixed<32, 32> castxtof_mr42();

private:
    // vector of expressions to store the computations on this number
    expression* exp;

    // a value representing the number
    fpInternal number;
};
#endif
