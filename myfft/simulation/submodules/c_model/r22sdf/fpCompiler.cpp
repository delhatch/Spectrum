// ================================================================================
// Legal Notice: Copyright (C) 1991-2007 Altera Corporation
// Any megafunction design, and related net list (encrypted or decrypted),
// support information, device programming or simulation file, and any other
// associated documentation or information provided by Altera or a partner
// under Altera's Megafunction Partnership Program may be used only to
// program PLD devices (but not masked PLD devices) from Altera.  Any other
// use of such megafunction design, net list, support information, device
// programming or simulation file, or any other related documentation or
// information is prohibited for any other purpose, including, but not
// limited to modification, reverse engineering, de-compiling, or use with
// any other silicon devices, unless such use is explicitly licensed under
// a separate agreement with Altera or a megafunction partner.  Title to
// the intellectual property, including patents, copyrights, trademarks,
// trade secrets, or maskworks, embodied in any such megafunction design,
// net list, support information, device programming or simulation file, or
// any other related documentation or information provided by Altera or a
// megafunction partner, remains with Altera, the megafunction partner, or
// their respective licensors.  No other licenses, including any licenses
// needed under any third party's intellectual property, are provided herein.
// ================================================================================
//
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
fpInternal parseExpressionTree(expression* exp);
fpInternal printExpressionTreeRecursive(expression* exp);
fpInternal fpmul(fpInternal dataa, fpInternal datab);
fpInternal fpadd(fpInternal dataa, fpInternal datab, int addsub);

/********************************************
 *
 * Class functions
 *
 *******************************************/


/*
  Constructor initialises exponent, significand and sign 
  from num
*/
fpCompiler::fpCompiler(){
  number =0;
  exp =NULL;
}

fpCompiler::fpCompiler(fpCompiler const &other) {
  number = other.number;
  if (other.getExpression() == NULL) {
    exp = 0;
  }else {
    exp = new expression(*(other.getExpression()));
  }

}
/*
  Constructor initialises exponent, significand and sign 
  from num. Store num in the format of fpInternal (42 bits wide)
*/
fpCompiler::fpCompiler(float num){

   sc_fixed<32,32> fpbin = floatToBin(&num, sizeof(num));
  
  number = castftox(fpbin);

#ifdef DEBUGFPCOMPILER
  cout << "fpCompiler: fpCompiler: Original float " << num << " represented as hex "  << fpbin.to_string(SC_HEX) ;
  sc_fixed<42,42> tmp;
  tmp.range(41,0) = number.range(41,0);
  cout << " in internal format " <<  number.to_string(SC_HEX) <<endl;
  //cout << "                         exp       " << (this->getExponent()).to_string(SC_HEX) << endl;
  //cout << "                         Sig       " << (this->getSignificand()).to_string(SC_HEX) << endl;
#endif


#ifdef DEBUGFPCOMPILER  
  sc_fixed<32,32> fun = castxtof();
  if (fun != fpbin) {
    cout << "fpCompiler: fpCompiler: ERROR: Performing check by converting back to float " << fun.to_string(SC_HEX) << " != " << fpbin.to_string(SC_HEX) << endl;
  }
#endif
  exp =NULL;

} 
     
/* 
   Do nothing for now.
*/
fpCompiler::~fpCompiler() {
  //cout << "fpCompiler destructor " << this << endl;
  delete exp;

}
    
 
fpInternal fpCompiler::getNumber() {
  return number;

}
fpInternal fpCompiler::getNumber()  const {
  return number;

}


/* 
     return the current exponent value of number
*/
fpExponent fpCompiler::getExponent() {
  fpExponent tmpExp;
  tmpExp.range(9,0)= number(9,0);
  return tmpExp;

}
fpExponent fpCompiler::getExponent() const  {
  fpExponent tmpExp;
  tmpExp.range(9,0)= number(9,0);
  return tmpExp;

}


/* 
   return the current significand value of number
*/
fpSignificand fpCompiler::getSignificand(){
  fpSignificand tmpSig;
  tmpSig.range(31,0) = number.range(41,10);
  return tmpSig;
}



fpSign  fpCompiler::getSign(){
  fpSign tmpSign;
  tmpSign.range(0,0) = number.range(41,41);
  return tmpSign;

}
  

expression* fpCompiler::getExpression(){
  return exp;

} 
expression* fpCompiler::getExpression() const {
  return exp;

} 

void fpCompiler::setExpression(expression* tree) {
  if (tree == NULL) {
    exp = 0;
  }else {
    exp = new expression(*(tree));
  }

}

/*******************************************************
 *
 *                        OPERATORS
 *
 *******************************************************/
fpCompiler  fpCompiler::operator+(fpCompiler num){
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

fpCompiler  fpCompiler::operator-(fpCompiler num){
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


fpCompiler  fpCompiler::operator*(fpCompiler num){
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

fpCompiler  fpCompiler::operator=( const float& num){
#ifdef DEBUGFPCOMPILER
  cout << "fpCompiler: operator= : Evaluating float -> fpCompiler " << endl;
#endif
  fpCompiler tmp(num);
  return tmp;
}

fpCompiler  fpCompiler::operator=( const fpCompiler&  num){
#ifdef DEBUGFPCOMPILER
  cout << "fpCompiler: operator= : Evaluating fpCompiler -> fpCompiler" << endl;
#endif
  this->number = num.getNumber(); 
  this->exp = new expression(*(num.getExpression()));
  //this->printExpressionTree();
  return (*this);
 
}


fpCompiler::operator float(){
#ifdef DEBUGFPCOMPILER
  cout << "fpCompiler: operator float() : casting to float " << endl;
#endif
  number = parseExpressionTree(exp);

  sc_fixed<32,32> resultAfterCast = castxtof();
  float resultFloat = binToFloat(resultAfterCast);

#ifdef DEBUGFPCOMPILER
  cout << "Evaluated to " << number.to_string(SC_HEX) << endl;
  cout << "After casting " << resultAfterCast.to_string(SC_HEX) << " (" << resultFloat << ")" << endl;
#endif
 
  return  resultFloat;
}



/*******************************************************
 *
 *                        OTHEr
 *
 *******************************************************/


void fpCompiler::printExpressionTree(){
  //#ifdef DEBUGFPCOMPILER
  cout << "********************* EXPRESSION TREE **********************"<<endl;
  fpInternal tmp =  printExpressionTreeRecursive (exp);
  cout << "********************* EXPRESSION TREE **********************"<<endl;
  //#endif
}


fpInternal printExpressionTreeRecursive(expression* exp){

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
    Roperand= printExpressionTreeRecursive(ropExp);
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
  default:
    return 0;
    break;
  }
  
}

fpInternal parseExpressionTree(expression* exp){

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
    cout << "Performing add on " << Loperand.to_string(SC_BIN) << " and " << Roperand.to_string(SC_BIN) <<  endl;
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
  default:
    return 0;
  }
  
    

  
}



fpInternal fpmul(fpInternal dataa, fpInternal datab) {
  /*
    determine if we need to shift down by 3.
  */
  int shiftaa = 0;
  int shiftbb = 0;
  fpSignificand aaman, bbman;
  aaman.range(31,0) = dataa.range(41,10);
  bbman.range(31,0) = datab.range(41,10);
  fpExponent aaexp,bbexp;
  aaexp.range(9,0) = dataa.range(9,0);
  bbexp.range(9,0) = datab.range(9,0);
  sc_bit signa = (sc_bit)dataa[41];
  sc_bit signb = (sc_bit)datab[41];
  sc_bit aasatff = (sc_bit)dataa[42];
  sc_bit bbsatff = (sc_bit)datab[42];
  sc_bit aazipff = (sc_bit)dataa[43];
  sc_bit bbzipff = (sc_bit)datab[43];
  if (( signa == 1 && !(dataa.range(40,38) == 0x7))||
      ( signa == 0 && !(dataa.range(40,38) == 0x0))){
    shiftaa = 1;
    aaman.range(28,0) = dataa.range(41,13);
    for (int i = 0; i < 3 ; i++) {
      aaman.range(29+i,29+i) = dataa.range(41,41);
    }
    aaexp += 3;
  }
  else if (( signb == 1 && !(datab.range(40,38) == 0x7))||
	   ( signb == 0 && !(datab.range(40,38) == 0x0))){
    shiftbb = 1;
    bbman.range(28,0) = datab.range(41,13);
    for (int i = 0; i < 3 ; i++) {
      bbman.range(29+i,29+i) = datab.range(41,41);
    }
    bbexp += 3;
  } 
 

  /*
    multiply mantissas
  */
  sc_fixed<SIGLENGTH*2,SIGLENGTH*2> mulff = aaman * bbman;

  /*
    add exponents, but saturate if required, and chec
  */
  fpExponent expff = 0;
  if (aazipff == 0 && bbzipff == 0) {
    if (aasatff == 1 || bbsatff == 1) {
      for (int i =0; i < EXPLENGTH ; i ++) {
	expff[i] = 1;
      }
    }else {
      expff = aaexp + bbexp - 127;
    }
  }


  // shift left by 3 to maintain position of 1.0
  fpInternal result=0;
  result.range(41,10) = mulff.range(58,27);
  result.range(9,0) = expff.range(9,0);
  result.range(42,42) = aasatff | bbsatff;
  result.range(43,43) = aazipff | bbzipff;
#ifdef DEBUGFPCOMPILER
  cout << "fpmult result " << result.range(41,0).to_string(SC_BIN) << " (" << result.range(41,0).to_string(SC_HEX) << ")" << endl;
#endif
  return result;
 

}

fpInternal fpadd(fpInternal dataa, fpInternal datab, int addsub) {

  /* Alignment Phase:
    if the exponents differ, then determine which has the smaller exponent
    Right shift the significand of the smaller exponent by an amount equal 
    to E1-E2 where E1 is the larger exponent and E2 is the smaller exponent
  */
  sc_bit signa = (sc_bit)dataa[41];
  sc_bit signb = (sc_bit)datab[41];
  fpExponent aaexp,bbexp;
  aaexp.range(9,0) = dataa.range(9,0);
  bbexp.range(9,0) = datab.range(9,0);
  fpSignificand aaman,bbman;
  aaman.range(31,0) = dataa.range(41,10);
  bbman.range(31,0) = datab.range(41,10);
  sc_bit aasatff = (sc_bit)dataa[42];
  sc_bit bbsatff = (sc_bit)datab[42];
  sc_bit aazipff = (sc_bit)dataa[43];
  sc_bit bbzipff = (sc_bit)datab[43];

  fpExponent subexpone,subexptwo;
  subexpone= aaexp - bbexp;
  subexptwo = bbexp - aaexp;
  
  sc_bit switchff = (sc_bit)subexpone[9];

  fpSignificand manleftff, manrightff;
  fpExponent expshiftff,expbaseff;
  if (switchff == 1) {
    expshiftff = subexptwo;
    expbaseff = bbexp;
    manleftff = bbman;
    manrightff = aaman;
  }else{
    expshiftff = subexpone;
    expbaseff = aaexp;
    manleftff = aaman;
    manrightff = bbman;
  }
    
  fpSignificand shiftbusnode,shiftbus;
  int shift = (sc_uint<5>)expshiftff.range(4,0);
  shiftbusnode = manrightff >> shift;
  fpExponent expzerochk = expshiftff - 32;
  if (expzerochk[9] == 1) {
    shiftbus = shiftbusnode;
  }else {
    shiftbus = 0;
  }
 
  fpSignificand aluleft,aluright;
  sc_bit invertleftff = switchff & addsub;
  sc_bit invertrightff = (~switchff) & addsub;
  for (int i = 0; i < SIGLENGTH; i++) {
    aluleft[i] = (sc_bit)manleftff[i] ^ invertleftff;
    aluright[i]= (sc_bit)shiftbus[i] ^ invertrightff;
  }
  fpSignificand aluff = aluleft + aluright + addsub;

  fpInternal result=0;
  result.range(41,10) = aluff.range(31,0);
  result.range(9,0) = expbaseff.range(9,0);
  result.range(42,42) = aasatff | bbsatff;
  result.range(43,43) = aazipff & bbzipff;
#ifdef DEBUGFPCOMPILER
  cout << "fpadd result " << result.range(41,0).to_string(SC_BIN) << " (" << result.range(41,0).to_string(SC_HEX) << ")" << endl;
#endif
  return result; 
 
}

fpInternal fpCompiler::castftox(sc_fixed<32,32> innum) {
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
  int satf = (innum.range(30,23)).and_reduce();
  int zipf = !((innum.range(30,23)).or_reduce());

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
    }else {
      exp.range(7,0) = innum.range(30,23);
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
  fpSignificand man =0;
  sc_bit sign = (sc_bit)innum[31];
  //sign extend the mantissa to 32 bits
  //sign extend lower 4 bits to sign
  for (int i = 0; i < 4; i++) {
    man[31-i] = sign;
    man[i] = sign;
  } 
  man[27] = !(sign);
  //a kind of twos complement, without adding the 1
  for (int i=0;i<=22;i++) {
    man[i+4] = innum[i] ^ sign;
  }
  
  fpInternal castVal=0;
  castVal.range(41,10) = man.range(31,0);
  castVal.range(9,0) = exp.range(9,0);
  castVal.range(42,42) = satf;
  castVal.range(43,43) = zipf;
  return castVal;
  

}

sc_fixed<32,32> fpCompiler::castxtof() {

  sc_fixed<32,32> castFloat = 0;
  sc_bit sign = (sc_bit)number[41];
  sc_bit satff = (sc_bit)number[42];
  sc_bit zipff = (sc_bit)number[43];
  /* normalise the mantissa
     re-xor with sign bit
  */
  fpSignificand man =getSignificand();
  fpSignificand absNode = 0;
  for (int i=0;i<31;i++) {
    absNode[i] = man[i] ^ sign;
  }
  //determine how many shifts we need for normalisation
  int count = 0;
  bool found_max = false;
  for (int i=31;i>0;i--) {
    if (!found_max) {
      if (absNode[i] == 0) {
	count++;
      }
      else if (absNode[i] == 1) {
	found_max = true;
      }
    }
  }
  //shift the mantissa count to the right and drop off bottom bits
  sc_fixed<32,32,SC_TRN> manNode = 0;
  manNode = absNode << count;
  //add this offset to the exponent
  fpExponent expNode = getExponent() + 4 - count;
  int satexp = expNode[8] | (expNode.range(7,0)).and_reduce();
  int zipexp = expNode[9] | !((expNode.range(7,0)).or_reduce()) | !(absNode.range(31,0).or_reduce());
  
 //saturate or subnormal check
  if (zipff == 1 || zipexp == 1) {
    expNode = 0;
  } 
  else if (satff == 1 || satexp == 1) {
    for (int i= 0; i < EXPLENGTH; i++) {
      expNode[i] = 1;
    } 
  }
  castFloat.range(31,31) = sign;
  castFloat.range(30,23) = expNode.range(7,0);
  castFloat.range(22,0) = manNode.range(31,8);
  return castFloat;
  


}



