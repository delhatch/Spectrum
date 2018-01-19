#define _CRT_SECURE_NO_WARNINGS
#define SC_INCLUDE_FX
#define DEBUG 0
#define DEBUG1 0
#define DEBUG3 0
#define RND_CONV 1
#define TRN_0 0
#define COUT_FMT SC_DEC

/* This is the implementation file for the synchronous process "fft" */
#include <iostream>
#include "systemc.h"
#include "math.h"
#include "fpCompiler.h"
#include "util.h"
#include <stdio.h>
#include <stdlib.h>
#ifdef MEX_COMPILE
#include "mex.h"
#endif

using namespace std;
fpInternal getNegation(fpInternal data);
fpInternal parseExpressionTree(expression* exp);
fpInternal printExpressionTreeRecursive(expression* exp);
fpInternal fpmul(fpInternal dataa, fpInternal datab);
fpInternal fpmul_mr42(fpInternal dataa, fpInternal datab, int svopt);
fpInternal fpadd(fpInternal dataa, fpInternal datab, int addsub);
fpInternal fpadd_mr42(fpInternal dataa, fpInternal datab, int addsub);
fpInternal fpsnorm(fpInternal dataa);

/********************************************
*
* Class functions
*
*******************************************/
/*
Constructor initialises exponent, significand and sign
from num
*/
fpCompiler::fpCompiler()
{
    number = 0;
    exp = NULL;
}

fpCompiler::fpCompiler(fpCompiler const& other)
{
    number = other.number;
    if (other.getExpression() == NULL) {
        exp = 0;
    } else {
        exp = new expression(*(other.getExpression()));
    }

}

/*
Constructor initialises exponent, significand and sign
from num. Store num in the format of fpInternal (42 bits wide)
*/
fpCompiler::fpCompiler(float num)
{

    sc_fixed<32, 32> fpbin = floatToBin(&num, sizeof(num));

    number = castftox(fpbin);

#ifdef DEBUGFPCOMPILER
    cout << "fpCompiler: fpCompiler: Original float " << num << " represented as hex "  << fpbin.to_string(SC_HEX) ;
    sc_fixed<42, 42> tmp;
    tmp.range(41, 0) = number.range(41, 0);
    cout << " in internal format " <<  number.to_string(SC_HEX) << endl;
    //cout << "                         exp       " << (this->getExponent()).to_string(SC_HEX) << endl;
    //cout << "                         Sig       " << (this->getSignificand()).to_string(SC_HEX) << endl;
#endif


#ifdef DEBUGFPCOMPILER
    sc_fixed<32, 32> fun = castxtof();
    if (fun != fpbin) {
        cout << "fpCompiler: fpCompiler: ERROR: Performing check by converting back to float " << fun.to_string(SC_HEX) << " != " << fpbin.to_string(SC_HEX) << endl;
    }
#endif
    exp = NULL;

}

fpCompiler::fpCompiler(float num, int flag)
{
    sc_fixed<32, 32> fpbin = floatToBin(&num, sizeof(num));
    if (flag != 2) {
        number = castftox_mr42(fpbin, flag);
        exp = NULL;
    } else {
        number = castftox_mr42(fpbin, 0);
        number = getNegation(number);
        exp = NULL;
    }
}

/*
Do nothing for now.
*/
fpCompiler::~fpCompiler()
{
    //cout << "fpCompiler destructor " << this << endl;
    delete exp;

}

void fpCompiler::clearObj()
{
    number = 0;
    expression* thisTmp = exp;
    exp = NULL;
    delete thisTmp;
}

fpInternal fpCompiler::getNumber()
{
    return number;

}
fpInternal fpCompiler::getNumber()  const
{
    return number;

}

/*
return the current exponent value of number
*/
fpExponent fpCompiler::getExponent()
{
    fpExponent tmpExp;
    tmpExp.range(9, 0) = number(9, 0);
    return tmpExp;

}
fpExponent fpCompiler::getExponent() const
{
    fpExponent tmpExp;
    tmpExp.range(9, 0) = number(9, 0);
    return tmpExp;

}

/*
return the current significand value of number
*/
fpSignificand fpCompiler::getSignificand()
{
    fpSignificand tmpSig;
    tmpSig.range(31, 0) = number.range(41, 10);
    return tmpSig;
}

fpSign  fpCompiler::getSign()
{
    fpSign tmpSign;
    tmpSign.range(0, 0) = number.range(41, 41);
    return tmpSign;

}

expression* fpCompiler::getExpression()
{
    return exp;

}
expression* fpCompiler::getExpression() const
{
    return exp;

}

void fpCompiler::setExpression(expression* tree)
{
    expression* thisTmp ;
    thisTmp = exp;
    if (tree == NULL) {
        exp = 0;
    } else {
        exp = new expression(*(tree));
    }
    delete thisTmp;
}


void fpCompiler::signNorm()
{
#ifdef DEBUGFPCOMPILER
    cout << "fpCompiler: function signNorm : Normalizing sign number" << endl;
#endif
    expression* thisExp = new expression(this, this, SNORM);
    setExpression(thisExp);
}

fpCompiler fpCompiler::mult(fpCompiler num, int svopt)
{
#ifdef DEBUGFPCOMPILER
    cout << "fpCompiler: function mult : " << number.to_string(SC_HEX) << " * " << num.getNumber().to_string(SC_HEX) << " with svopt=" << svopt << endl;
#endif
    fpCompiler combinedfp;
    expression* thisExp;
    if (svopt) {
        thisExp  = new expression(this, &num, MULT_MR42_SVOPT);
    } else {
        thisExp  = new expression(this, &num, MULT_MR42);
    }
    combinedfp.setExpression(thisExp);
    return combinedfp;
}

fpCompiler fpCompiler::add(fpCompiler num)
{
#ifdef DEBUGFPCOMPILER
    cout << "fpCompiler: function add : " << number.to_string(SC_HEX) << " * " << num.getNumber().to_string(SC_HEX) << endl;
#endif
    fpCompiler combinedfp;
    expression* thisExp  = new expression(this, &num, ADD_MR42);
    combinedfp.setExpression(thisExp);
    return combinedfp;
}

fpCompiler fpCompiler::sub(fpCompiler num)
{
#ifdef DEBUGFPCOMPILER
    cout << "fpCompiler: function sub : " << number.to_string(SC_HEX) << " * " << num.getNumber().to_string(SC_HEX) << endl;
#endif
    fpCompiler combinedfp;
    expression* thisExp  = new expression(this, &num, SUB_MR42);
    combinedfp.setExpression(thisExp);
    return combinedfp;
}

float fpCompiler::cast2float()
{
#ifdef DEBUGFPCOMPILER
    cout << "fpCompiler: function cast2float : casting to float ";
#endif
    number = parseExpressionTree(exp);

    sc_fixed<32, 32> resultAfterCast = castxtof_mr42();
    float resultFloat = binToFloat(resultAfterCast);

#ifdef DEBUGFPCOMPILER
    cout << "Evaluated to " << number.to_string(SC_HEX) << endl;
    cout << "After casting " << resultAfterCast.to_string(SC_HEX) << " (" << resultFloat << ")" << endl;
#endif

    return  resultFloat;
}

/*******************************************************
*
*                        OPERATORS
*
*******************************************************/
fpCompiler  fpCompiler::operator+(fpCompiler num)
{
#ifdef DEBUGFPCOMPILER
    cout << "fpCompiler: operator+ : " << number.to_string(SC_HEX) << " + " << (num.getNumber()).to_string(SC_HEX) << endl;
#endif
    /*
    create a new fpComiler to represent the combine result of operation,
    create a new expression to represent this operation and associate it
    with this fpCompiler
    */
    fpCompiler combinedfp;
    expression* thisExp  = new expression(this, &num, ADD);
    combinedfp.setExpression(thisExp);
    return combinedfp;
}

fpCompiler  fpCompiler::operator-(fpCompiler num)
{
#ifdef DEBUGFPCOMPILER
    cout << "fpCompiler: operator- : " << number.to_string(SC_HEX) << " - " << (num.getNumber()).to_string(SC_HEX) << endl;
#endif
    /*
    create a new fpComiler to represent the combine result of operation,
    create a new expression to represent this operation and associate it
    with this fpCompiler
    */
    fpCompiler combinedfp;
    expression* thisExp  = new expression(this, &num, SUB);
    combinedfp.setExpression(thisExp);
    return combinedfp;
}

fpCompiler  fpCompiler::operator*(fpCompiler num)
{
#ifdef DEBUGFPCOMPILER
    cout << "fpCompiler: operator* : " << number.to_string(SC_HEX) << " * " << (num.getNumber()).to_string(SC_HEX) << endl;
#endif
    /*
    create a new fpComiler to represent the combine result of operation,
    create a new expression to represent this operation and associate it
    with this fpCompiler
    */
    fpCompiler combinedfp;
    expression* thisExp  = new expression(this, &num, MULT);
    combinedfp.setExpression(thisExp);
    return combinedfp;
}

fpCompiler  fpCompiler::operator=( const float& num)
{
#ifdef DEBUGFPCOMPILER
    cout << "fpCompiler: operator= : Evaluating float -> fpCompiler " << endl;
#endif

    fpCompiler tmp(num);
    return tmp;
}

fpCompiler  fpCompiler::operator=( const fpCompiler&  num)
{
#ifdef DEBUGFPCOMPILER
    cout << "fpCompiler: operator= : Evaluating fpCompiler -> fpCompiler" << endl;
#endif

    expression* thisTmp ;
    thisTmp = this->exp;
    delete thisTmp;

    this->number = num.getNumber();
    this->exp = new expression(*(num.getExpression()));
    //this->printExpressionTree();
    return (*this);
}

fpCompiler::operator float()
{
#ifdef DEBUGFPCOMPILER
    cout << "fpCompiler: operator float() : casting to float " << endl;
#endif
    number = parseExpressionTree(exp);

    sc_fixed<32, 32> resultAfterCast = castxtof();
    float resultFloat = binToFloat(resultAfterCast);

#ifdef DEBUGFPCOMPILER
    cout << "Evaluated to " << number.to_string(SC_HEX) << endl;
    cout << "After casting " << resultAfterCast.to_string(SC_HEX) << " (" << resultFloat << ")" << endl;
#endif

    return  resultFloat;
}

/*******************************************************
*
*                        OTHER
*
*******************************************************/
fpInternal getNegation(fpInternal data)
{
    sc_bit sign_temp = (sc_bit)1;
    fpExponent exp_temp;
    exp_temp.range(9, 0) = data.range(9, 0);
    fpSignificand man_temp;
    man_temp.range(31, 0) = data.range(41, 10);
    sc_bit sat_temp = (sc_bit)data[42];
    sc_bit zip_temp = (sc_bit)data[43];


    for (int i = 0; i < 32; i++) {
        man_temp[i] = man_temp[i] ^ sign_temp;
    }

    for (int i = 0; i < 32; i++) {
        if (man_temp[i] == 1) {
            man_temp[i] = 0;
        } else {
            man_temp[i] = 1;
            i = 32;
        }
    }

    fpInternal result = 0;
    result.range(41, 10) = man_temp.range(31, 0);
    result.range(9, 0) = exp_temp.range(9, 0);
    result.range(42, 42) = sat_temp;
    result.range(43, 43) = zip_temp;
    return result;
}

void fpCompiler::printExpressionTree()
{
#ifdef DEBUGFPCOMPILER
    cout << "********************* EXPRESSION TREE **********************" << endl;
    fpInternal tmp =  printExpressionTreeRecursive (exp);
    cout << "********************* EXPRESSION TREE **********************" << endl;
#endif
}

fpInternal printExpressionTreeRecursive(expression* exp)
{

    //start with Left operand
    fpInternal Loperand;
    fpInternal Roperand;

    expression* lopExp = (exp->getLop())->getExpression();
    if (lopExp != NULL) {
        Loperand = printExpressionTreeRecursive(lopExp);
    } else {
        Loperand = (exp->getLop())->getNumber();

    }
    expression* ropExp = (exp->getRop())->getExpression();
    if (ropExp != NULL) {
        Roperand = printExpressionTreeRecursive(ropExp);
    } else {
        Roperand = exp->getRop()->getNumber();
    }

    switch (exp->getOp()) {
    case ADD:
        cout << "Add on " << Loperand.to_string(SC_BIN) << " and " << Roperand.to_string(SC_BIN) <<  endl;
        return fpadd(Loperand, Roperand, ADD );
        break;
    case SUB:
        cout << "Sub on " << Loperand.to_string(SC_HEX) << " and " << Roperand.to_string(SC_HEX) <<  endl;
        return fpadd(Loperand, Roperand, SUB );
        break;
    case MULT:
        cout << "Mult on " << Loperand.to_string(SC_HEX) << " and " << Roperand.to_string(SC_HEX) <<  endl;
        return fpmul(Loperand, Roperand);
        break;
    case ADD_MR42:
        cout << "Add (MR42) on " << Loperand.to_string(SC_BIN) << " and " << Roperand.to_string(SC_BIN) <<  endl;
        return fpadd(Loperand, Roperand, ADD_MR42 );
        break;
    case SUB_MR42:
        cout << "Sub (MR42) on " << Loperand.to_string(SC_HEX) << " and " << Roperand.to_string(SC_HEX) <<  endl;
        return fpadd(Loperand, Roperand, SUB_MR42 );
        break;
    case MULT_MR42:
        cout << "Mult (MR42) on " << Loperand.to_string(SC_HEX) << " and " << Roperand.to_string(SC_HEX) <<  endl;
        return fpmul_mr42(Loperand, Roperand, MULT_MR42);
        break;
    case MULT_MR42_SVOPT:
        cout << "Mult (MR42) on " << Loperand.to_string(SC_HEX) << " and " << Roperand.to_string(SC_HEX) <<  endl;
        return fpmul_mr42(Loperand, Roperand, MULT_MR42_SVOPT);
        break;
    case SNORM:
        cout << "Snorm on " << Loperand.to_string(SC_HEX) << " and " << Roperand.to_string(SC_HEX) <<  endl;
        return fpsnorm(Loperand);
        break;
    default:
        return 0;
        break;
    }
}

fpInternal parseExpressionTree(expression* exp)
{

    //start with Left operand
    fpInternal Loperand;
    fpInternal Roperand;

    //cout << "Getting Lopexp" <<endl;
    expression* lopExp = (exp->getLop())->getExpression();
    if (lopExp != NULL) {
        //cout << "Parsing LopExp" << endl;
        Loperand = parseExpressionTree(lopExp);
        //cout << "Lop of lopExp is " << lopExp->getLop()->getNumber().to_string(SC_HEX) << endl;
    } else {
        //cout << "LopExp points to a null expression, found leaf node " << endl;
        Loperand = (exp->getLop())->getNumber();
        //cout << "LopExp Leaf node is " << Loperand.to_string(SC_HEX) << endl;

    }
    //cout << "Getting Ropexp" <<endl;
    expression* ropExp = (exp->getRop())->getExpression();
    if (ropExp != NULL) {
        //cout << "Parsing RopExp" << endl;
        Roperand = parseExpressionTree(ropExp);
        //cout << "Rop of RopExp is " << ropExp->getRop()->getNumber().to_string(SC_HEX) << endl;
    } else {
        //cout << "ropExp points to a null expression, found leaf node " << endl;
        Roperand = exp->getRop()->getNumber();
        //cout << "ropExp Leaf node is " << Roperand.to_string(SC_HEX) << endl;
    }

    switch (exp->getOp()) {
    case ADD:
#ifdef DEBUGFPCOMPILER
        cout << "Performing add on " << Loperand.to_string(SC_HEX) << " and " << Roperand.to_string(SC_HEX) <<  endl;
#endif
        return fpadd(Loperand, Roperand, ADD );
        break;
    case SUB:
#ifdef DEBUGFPCOMPILER
        cout << "Performing sub on " << Loperand.to_string(SC_HEX) << " and " << Roperand.to_string(SC_HEX) <<  endl;
#endif
        return fpadd(Loperand, Roperand, SUB );
        break;
    case MULT:
#ifdef DEBUGFPCOMPILER
        cout << "Performing mult on " << Loperand.to_string(SC_HEX) << " and " << Roperand.to_string(SC_HEX) <<  endl;
#endif
        return fpmul(Loperand, Roperand);
        break;
    case ADD_MR42:
#ifdef DEBUGFPCOMPILER
        cout << "Performing add (MR42) on mantissa=" << Loperand.range(41, 10).to_string(SC_HEX) << " exp=" << Loperand.range(7, 0).to_string(SC_HEX) << "\tand\tmantissa=" << Roperand.range(41, 10).to_string(SC_HEX) << " exp=" << Roperand.range(7, 0).to_string(SC_HEX) << endl;
#endif
        return fpadd_mr42(Loperand, Roperand, ADD_MR42 );
        break;
    case SUB_MR42:
#ifdef DEBUGFPCOMPILER
        cout << "Performing add (MR42) on mantissa=" << Loperand.range(41, 10).to_string(SC_HEX) << " exp=" << Loperand.range(7, 0).to_string(SC_HEX) << "\tand\tmantissa=" << Roperand.range(41, 10).to_string(SC_HEX) << " exp=" << Roperand.range(7, 0).to_string(SC_HEX) << endl;
#endif
        return fpadd_mr42(Loperand, Roperand, SUB_MR42 );
        break;
    case MULT_MR42:
#ifdef DEBUGFPCOMPILER
        cout << "Performing mult (MR42) on mantissa=" << Loperand.range(41, 10).to_string(SC_HEX) << " exp=" << Loperand.range(7, 0).to_string(SC_HEX) << "\tand\tmantissa=" << Roperand.range(41, 10).to_string(SC_HEX) << " exp=" << Roperand.range(7, 0).to_string(SC_HEX) << endl;
#endif
        return fpmul_mr42(Loperand, Roperand, MULT_MR42);
        break;
    case MULT_MR42_SVOPT:
#ifdef DEBUGFPCOMPILER
        cout << "Performing mult (MR42, 27-bit multiplier) on mantissa=" << Loperand.range(41, 10).to_string(SC_HEX) << " exp=" << Loperand.range(7, 0).to_string(SC_HEX) << "\tand\tmantissa=" << Roperand.range(41, 10).to_string(SC_HEX) << " exp=" << Roperand.range(7, 0).to_string(SC_HEX) << endl;
#endif
        return fpmul_mr42(Loperand, Roperand, MULT_MR42_SVOPT);
        break;
    case SNORM:
#ifdef DEBUGFPCOMPILER
        cout << "Performing snorm on mantissa=" << Loperand.range(41, 10).to_string(SC_HEX) << " exp=" << Loperand.range(7, 0).to_string(SC_HEX) << endl;
#endif
        return fpsnorm(Loperand);
        break;
    default:
        return 0;
    }
}

fpInternal fpmul(fpInternal dataa, fpInternal datab)
{
    /*
    determine if we need to shift down by 3.
    */
    int shiftaa = 0;
    int shiftbb = 0;
    fpSignificand aaman, bbman;
    aaman.range(31, 0) = dataa.range(41, 10);
    bbman.range(31, 0) = datab.range(41, 10);
    fpExponent aaexp, bbexp;
    aaexp.range(9, 0) = dataa.range(9, 0);
    bbexp.range(9, 0) = datab.range(9, 0);
    sc_bit signa = (sc_bit)dataa[41];
    sc_bit signb = (sc_bit)datab[41];
    sc_bit aasatff = (sc_bit)dataa[42];
    sc_bit bbsatff = (sc_bit)datab[42];
    sc_bit aazipff = (sc_bit)dataa[43];
    sc_bit bbzipff = (sc_bit)datab[43];
    if (( signa == 1 && !(dataa.range(40, 38) == 0x7)) ||
            ( signa == 0 && !(dataa.range(40, 38) == 0x0))) {
        shiftaa = 1;
        aaman.range(28, 0) = dataa.range(41, 13);
        for (int i = 0; i < 3 ; i++) {
            aaman.range(29 + i, 29 + i) = dataa.range(41, 41);
        }
        aaexp += 3;
    } else if (( signb == 1 && !(datab.range(40, 38) == 0x7)) ||
               ( signb == 0 && !(datab.range(40, 38) == 0x0))) {
        shiftbb = 1;
        bbman.range(28, 0) = datab.range(41, 13);
        for (int i = 0; i < 3 ; i++) {
            bbman.range(29 + i, 29 + i) = datab.range(41, 41);
        }
        bbexp += 3;
    }

    /*
    multiply mantissas
    */
    sc_fixed<SIGLENGTH * 2, SIGLENGTH * 2> mulff = aaman * bbman;

    /*
    add exponents, but saturate if required, and chec
    */
    fpExponent expff = 0;
    if (aazipff == 0 && bbzipff == 0) {
        if (aasatff == 1 || bbsatff == 1) {
            for (int i = 0; i < EXPLENGTH ; i ++) {
                expff[i] = 1;
            }
        } else {
            expff = aaexp + bbexp - 127;
        }
    }

    // shift left by 3 to maintain position of 1.0
    fpInternal result = 0;
    result.range(41, 10) = mulff.range(58, 27);
    result.range(9, 0) = expff.range(9, 0);
    result.range(42, 42) = aasatff | bbsatff;
    result.range(43, 43) = aazipff | bbzipff;
#ifdef DEBUGFPCOMPILER
    cout << "fpmult result " << result.range(41, 0).to_string(SC_BIN) << " (" << result.range(41, 0).to_string(SC_HEX) << ")" << endl;
#endif
    return result;
}

fpInternal fpmul_mr42(fpInternal dataa, fpInternal datab, int svopt)
{
    fpSignificand aaman, bbman;
    aaman.range(31, 0) = dataa.range(41, 10);
    bbman.range(31, 0) = datab.range(41, 10);

    sc_fixed<27, 27> aaman27, bbman27;
    aaman27.range(26, 0) = dataa.range(41, 15);
    bbman27.range(26, 0) = datab.range(41, 15);

    fpExponent aaexp, bbexp;
    aaexp.range(9, 0) = dataa.range(9, 0);
    bbexp.range(9, 0) = datab.range(9, 0);

    sc_bit aasatff = (sc_bit)dataa[42];
    sc_bit bbsatff = (sc_bit)datab[42];
    sc_bit aazipff = (sc_bit)dataa[43];
    sc_bit bbzipff = (sc_bit)datab[43];

    /*
    multiply mantissas
    */
    sc_fixed<54, 54> mulff_temp;
    sc_fixed<SIGLENGTH * 2, SIGLENGTH * 2> mulff;

    if (svopt - 5) {
        mulff_temp = aaman27 * bbman27;
    } else {
        mulff = aaman * bbman;
    }

    /*
    add exponents, but saturate if required, and chec
    */
    fpExponent expff = 0;
    if (aasatff == 1 || bbsatff == 1) {
        for (int i = 0; i < EXPLENGTH ; i ++) {
            expff[i] = 1;
        }
    } else {
        expff = aaexp + bbexp - 125;
    }

    fpInternal result = 0;
    if (svopt - 5) {
        result.range(41, 10) = mulff_temp.range(53, 22);
    } else {
        result.range(41, 10) = mulff.range(63, 32);
    }
    result.range(9, 0) = expff.range(9, 0);
    result.range(42, 42) = aasatff | bbsatff;
    result.range(43, 43) = aazipff | bbzipff;
#ifdef DEBUGFPCOMPILER
    cout << "fpmul result mantissa=" << result.range(41, 10).to_string(SC_HEX) << " exp=" << result.range(7, 0).to_string(SC_HEX) << endl;
#endif
    return result;
}

fpInternal fpadd(fpInternal dataa, fpInternal datab, int addsub)
{
    /* Alignment Phase:
    if the exponents differ, then determine which has the smaller exponent
    Right shift the significand of the smaller exponent by an amount equal
    to E1-E2 where E1 is the larger exponent and E2 is the smaller exponent
    */
    sc_bit signa = (sc_bit)dataa[41];
    sc_bit signb = (sc_bit)datab[41];
    fpExponent aaexp, bbexp;
    aaexp.range(9, 0) = dataa.range(9, 0);
    bbexp.range(9, 0) = datab.range(9, 0);
    fpSignificand aaman, bbman;
    aaman.range(31, 0) = dataa.range(41, 10);
    bbman.range(31, 0) = datab.range(41, 10);
    sc_bit aasatff = (sc_bit)dataa[42];
    sc_bit bbsatff = (sc_bit)datab[42];
    sc_bit aazipff = (sc_bit)dataa[43];
    sc_bit bbzipff = (sc_bit)datab[43];

    for (int i = 0; i < SIGLENGTH; i++) {
        if (addsub == 1) {
            if (bbman[i] == 0) {
                bbman[i] = 1;
            } else {
                bbman[i] = 0;
            }
        }
    }

    fpExponent subexpone, subexptwo;
    subexpone = aaexp - bbexp;
    subexptwo = bbexp - aaexp;

    sc_bit switchff = (sc_bit)subexpone[9];

    fpSignificand manleftff, manrightff;
    fpExponent expshiftff, expbaseff;
    if (switchff == 1) {
        expshiftff = subexptwo;
        expbaseff = bbexp;
        manleftff = bbman;
        manrightff = aaman;
    } else {
        expshiftff = subexpone;
        expbaseff = aaexp;
        manleftff = aaman;
        manrightff = bbman;
    }

    fpSignificand shiftbusnode, shiftbus;
    int shift = (sc_uint<5>)expshiftff.range(4, 0);
    shiftbusnode = manrightff >> shift;
    fpExponent expzerochk = expshiftff - 32;
    if (expzerochk[9] == 1) {
        shiftbus = shiftbusnode;
    } else {
        shiftbus = 0;
    }

    fpSignificand aluleft, aluright;
    sc_bit invertleftff = switchff & addsub;
    sc_bit invertrightff = (~switchff) & addsub;
    for (int i = 0; i < SIGLENGTH; i++) {
        aluleft[i] = (sc_bit)manleftff[i] ^ invertleftff;
        aluright[i] = (sc_bit)shiftbus[i] ^ invertrightff;
    }
    fpSignificand aluff = aluleft + aluright + addsub;

    fpInternal result = 0;
    result.range(41, 10) = aluff.range(31, 0);
    result.range(9, 0) = expbaseff.range(9, 0);
    result.range(42, 42) = aasatff | bbsatff;
    result.range(43, 43) = aazipff & bbzipff;
#ifdef DEBUGFPCOMPILER
    cout << "fpadd result " << result.range(41, 0).to_string(SC_BIN) << " (" << result.range(41, 0).to_string(SC_HEX) << ")" << endl;
#endif
    return result;
}

fpInternal fpadd_mr42(fpInternal dataa, fpInternal datab, int addsub)
{
    sc_bit signa = (sc_bit)dataa[41];
    sc_bit signb = (sc_bit)datab[41];
    fpExponent aaexp, bbexp;
    aaexp.range(9, 0) = dataa.range(9, 0);
    bbexp.range(9, 0) = datab.range(9, 0);
    fpSignificand aaman, bbman;
    aaman.range(31, 0) = dataa.range(41, 10);
    bbman.range(31, 0) = datab.range(41, 10);
    sc_bit aasatff = (sc_bit)dataa[42];
    sc_bit bbsatff = (sc_bit)datab[42];
    sc_bit aazipff = (sc_bit)dataa[43];
    sc_bit bbzipff = (sc_bit)datab[43];

    for (int i = 0; i < SIGLENGTH; i++) {
        if (addsub == 4) {
            if (bbman[i] == 0) {
                bbman[i] = 1;
            } else {
                bbman[i] = 0;
            }
        }
    }

    fpExponent subexpone, subexptwo;
    subexpone = aaexp - bbexp;
    subexptwo = bbexp - aaexp;

    sc_bit switchff = (sc_bit)subexpone[9];

    fpSignificand manleftff, manrightff;
    fpExponent expshiftff, expbaseff;
    if (switchff == 1) {
        expshiftff = subexptwo;
        expbaseff = bbexp;
        manleftff = bbman;
        manrightff = aaman;
    } else {
        expshiftff = subexpone;
        expbaseff = aaexp;
        manleftff = aaman;
        manrightff = bbman;
    }

    fpSignificand shiftbusnode, shiftbus;
    int shift = (sc_uint<5>)expshiftff.range(4, 0);
    shiftbusnode = manrightff >> shift;
    fpExponent expzerochk = expshiftff - 32;
    if (expzerochk[9] == 1) {
        shiftbus = shiftbusnode;
    } else {
        shiftbus = 0;
    }

    fpSignificand aluff = manleftff + shiftbus + (addsub - 3);

    fpInternal result = 0;
    result.range(41, 10) = aluff.range(31, 0);
    result.range(9, 0) = expbaseff.range(9, 0);
    result.range(42, 42) = aasatff | bbsatff;
    result.range(43, 43) = aazipff & bbzipff;
#ifdef DEBUGFPCOMPILER
    cout << "fpadd result mantissa=" << result.range(41, 10).to_string(SC_HEX) << " exp=" << result.range(7, 0).to_string(SC_HEX) << endl;
#endif
    return result;
}

fpInternal fpsnorm(fpInternal dataa)
{
    /* Alignment Phase:
    if the exponents differ, then determine which has the smaller exponent
    Right shift the significand of the smaller exponent by an amount equal
    to E1-E2 where E1 is the larger exponent and E2 is the smaller exponent
    */
    sc_bit signa = (sc_bit)dataa[41];
    fpExponent aaexp;
    aaexp.range(9, 0) = dataa.range(9, 0);
    fpSignificand aaman;
    aaman.range(31, 0) = dataa.range(41, 10);
    sc_bit aasatff = (sc_bit)dataa[42];
    sc_bit aazipff = (sc_bit)dataa[43];

    int count = 0;
    if (signa == 0) {
        for (int i = 30; i > 0; i--) {
            if (aaman[i] == 0) {
                count = count + 1;
            } else {
                i = 1;
            }
        }
    } else {
        for (int i = 30; i > 0; i--) {
            if (aaman[i] == 1) {
                count = count + 1;
            } else {
                i = 1;
            }
        }
    }

    for (int j = 0; j < 31 - count; j++) {
        aaman[30 - j] = aaman[30 - j - count];
    }

    for (int j = 0; j < count; j++) {
        aaman[j] = 0;
    }

    aaexp = aaexp - count;

    fpInternal result = 0;
    result.range(41, 10) = aaman.range(31, 0);
    result.range(9, 0) = aaexp.range(9, 0);
    result.range(42, 42) = aasatff;
    result.range(43, 43) = aazipff;

#ifdef DEBUGFPCOMPILER
    cout << "fpsnorm result mantissa=" << result.range(41, 10).to_string(SC_HEX) << " exp=" << result.range(7, 0).to_string(SC_HEX) << endl;
#endif
    return result;
}

fpInternal fpCompiler::castftox(sc_fixed<32, 32> innum)
{
    /*
    Takes a 32 bit input signal and casts it to a 42 bit internal
    representation

    +-----+-----+------------------+-------------+
    | 43  | 42  | 41     ...    10 | 9    ...  0 |
    +--------------------------------------------+
    | zip | sat |   significand    |  exponent   |
    |     |     |    modified      |             |
    +-----+-----+------------------+-------------+
    */

    //check for saturation (ie if exponent is all 1's), and subnormals
    int satf = (innum.range(30, 23)).and_reduce();
    int zipf = !((innum.range(30, 23)).or_reduce());

    /*
    Set the exponent.
    If saturate, set all to 1
    If subnormal, set all to 0
    Otherwise set to innum[22..30]
    */
    fpExponent exp = 0;
    if (zipf == 0) {
        if (satf == 1) {
            for (int i = 0; i < EXPLENGTH; i++) {
                exp[i] = 1;
            }
        } else {
            exp.range(7, 0) = innum.range(30, 23);
        }
    }
    exp[8] = satf;
    exp[9] = 0;

    /*
    set the Significand

    +----------+------+-------------+--------+
    | 31 .. 28 |  27  | 26   ..  4  | 3 .. 0 |
    +----------+------+-------------+--------+
    | sign     | not  | significand | sign   |
    |          | sign |  xor sign   |        |
    +----------+------+-------------+--------+

    */
    fpSignificand man = 0;
    sc_bit sign = (sc_bit)innum[31];
    //sign extend the mantissa to 32 bits
    //sign extend lower 4 bits to sign
    for (int i = 0; i < 4; i++) {
        man[31 - i] = sign;
        man[i] = sign;
    }
    man[27] = !(sign);
    //a kind of twos complement, without adding the 1
    for (int i = 0; i <= 22; i++) {
        man[i + 4] = innum[i] ^ sign;
    }

    fpInternal castVal = 0;
    castVal.range(41, 10) = man.range(31, 0);
    castVal.range(9, 0) = exp.range(9, 0);
    castVal.range(42, 42) = satf;
    castVal.range(43, 43) = zipf;
    return castVal;

}

fpInternal fpCompiler::castftox_mr42(sc_fixed<32, 32> innum, int twid_flag)
{
    /*
    Takes a 32 bit input signal and casts it to a 42 bit internal
    representation

    +-----+-----+------------------+-------------+
    | 43  | 42  | 41     ...    10 | 9    ...  0 |
    +--------------------------------------------+
    | zip | sat |   significand    |  exponent   |
    |     |     |    modified      |             |
    +-----+-----+------------------+-------------+
    */

    //check for saturation (ie if exponent is all 1's), and subnormals
    int satf = (innum.range(30, 23)).and_reduce();
    int zipf = !((innum.range(30, 23)).or_reduce());

    /*
    Set the exponent.
    If saturate, set all to 1
    If subnormal, set all to 0
    Otherwise set to innum[22..30]
    */
    fpExponent exp = 0;
    if (zipf == 0) {
        if (satf == 1) {
            for (int i = 0; i < EXPLENGTH; i++) {
                exp[i] = 1;
            }
        } else {
            exp.range(7, 0) = innum.range(30, 23);
        }
    }
    exp[8] = satf;
    exp[9] = 0;

    /*
    set the Significand
    (Twiddle Factor)
    +------+------+-------------+--------+
    | 31   |  30  | 29   ..  7  | 6 .. 0 |
    +------+------+-------------+--------+
    | sign | not  | significand | sign   |
    |      | sign |  xor sign   |        |
    +------+------+-------------+--------+
    (Data)
    +----------+------+-------------+--------+
    | 31 .. 27 |  26  | 25   ..  3  | 2 .. 0 |
    +----------+------+-------------+--------+
    |   sign   | not  | significand | sign   |
    |          | sign |  xor sign   |        |
    +----------+------+-------------+--------+
    */
    fpSignificand man = 0;
    fpSignificand sign = 0;
    sign[0] = innum[31];
    //sc_bit sign = (sc_bit)innum[31];

    if (twid_flag == 1) {
        man[31] = 0 ^ sign[0];
        man[30] = 1 ^ sign[0];
        for (int i = 0; i <= 22; i++) {
            man[i + 7] = innum[i] ^ sign[0];
        }
        for (int i = 0; i <= 6; i++) {
            man[i] = 0 ^ sign[0];
        }
    } else {
        for (int i = 0; i <= 4; i++) {
            man[i + 27] = 0 ^ sign[0];
        }
        man[26] = 1 ^ sign[0];
        for (int i = 0; i <= 22; i++) {
            man[i + 3] = innum[i] ^ sign[0];
        }
        man[2] = 0 ^ sign[0];
        man[1] = 0 ^ sign[0];
        man[0] = 0 ^ sign[0];
    }

    man = man + sign;

    fpInternal castVal = 0;
    castVal.range(41, 10) = man.range(31, 0);
    castVal.range(9, 0) = exp.range(9, 0);
    castVal.range(42, 42) = satf;
    castVal.range(43, 43) = zipf;
    return castVal;
}

sc_fixed<32, 32> fpCompiler::castxtof()
{

    sc_fixed<32, 32> castFloat = 0;
    sc_bit sign = (sc_bit)number[41];
    sc_bit satff = (sc_bit)number[42];
    sc_bit zipff = (sc_bit)number[43];
    /* normalise the mantissa
    re-xor with sign bit
    */
    fpSignificand man = getSignificand();
    fpSignificand absNode = 0;
    for (int i = 0; i < 31; i++) {
        absNode[i] = man[i] ^ sign;
    }
    //determine how many shifts we need for normalisation
    int count = 0;
    bool found_max = false;
    for (int i = 31; i > 0; i--) {
        if (!found_max) {
            if (absNode[i] == 0) {
                count++;
            } else if (absNode[i] == 1) {
                found_max = true;
            }
        }
    }
    //shift the mantissa count to the right and drop off bottom bits
    sc_fixed<32, 32, SC_TRN> manNode = 0;
    manNode = absNode << count;
    //add this offset to the exponent
    fpExponent expNode = getExponent() + 4 - count;
    int satexp = expNode[8] | (expNode.range(7, 0)).and_reduce();
    int zipexp = expNode[9] | !((expNode.range(7, 0)).or_reduce()) | !(absNode.range(31, 0).or_reduce());

    //saturate or subnormal check
    if (zipff == 1 || zipexp == 1) {
        expNode = 0;
    } else if (satff == 1 || satexp == 1) {
        for (int i = 0; i < EXPLENGTH; i++) {
            expNode[i] = 1;
        }
    }
    castFloat.range(31, 31) = sign;
    castFloat.range(30, 23) = expNode.range(7, 0);
    castFloat.range(22, 0) = manNode.range(31, 8);
    return castFloat;
}

sc_fixed<32, 32> fpCompiler::castxtof_mr42()
{
    sc_fixed<32, 32> castFloat = 0;
    sc_bit sign = (sc_bit)number[41];
    sc_bit satff = (sc_bit)number[42];
    sc_bit zipff = (sc_bit)number[43];
    /* normalise the mantissa
    re-xor with sign bit
    */
    fpSignificand man = getSignificand();
    fpSignificand absNode = 0;
    for (int i = 0; i < 31; i++) {
        absNode[i] = man[i] ^ sign;
    }
    //determine how many shifts we need for normalisation
    int count = 0;
    bool found_max = false;
    for (int i = 31; i > 0; i--) {
        if (!found_max) {
            if (absNode[i] == 0) {
                count++;
            } else if (absNode[i] == 1) {
                found_max = true;
            }
        }
    }

    count = count - 1;

    //shift the mantissa count to the right and drop off bottom bits
    sc_fixed<32, 32, SC_TRN> manNode = 0;
    manNode = absNode << count;
    //add this offset to the exponent
    fpExponent expNode = getExponent() + 4 - count;
    int satexp = expNode[8] | (expNode.range(7, 0)).and_reduce();
    int zipexp = expNode[9] | !((expNode.range(7, 0)).or_reduce()) | !(absNode.range(31, 0).or_reduce());

    //saturate or subnormal check
    if (zipff == 1 || zipexp == 1) {
        expNode = 0;
    } else if (satff == 1 || satexp == 1) {
        for (int i = 0; i < EXPLENGTH; i++) {
            expNode[i] = 1;
        }
    }
    castFloat.range(31, 31) = sign;
    castFloat.range(30, 23) = expNode.range(7, 0);
    castFloat.range(22, 0) = manNode.range(29, 7);

    //rounding
    /*
     * there are two issues here:
     * 1. If the rounding of mantissa overflows then the exponent must be
     * incremented but it isn't.
     * 2. p=22 should be p=23, or simply replace that line with break
     * This causes problem like case:77456, let's try without rounding.
     */
    /*
    if (manNode[6] == 1) {
        for (int p=0; p<=22; p++) {
            if (castFloat[p] == 1) {
                castFloat[p] = 0;
            } else {
                castFloat[p] = 1;
                p = 22;
            }
        }
    }
    */
    return castFloat;
}
