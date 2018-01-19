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
class fpCompiler {
 public:

  //initialise from float.
  fpCompiler();      
  fpCompiler(float num);      
  fpCompiler::fpCompiler(fpCompiler const &other);
  ~fpCompiler();    
 
  //get set methods
  fpInternal getNumber();
  fpExponent getExponent();
  fpInternal getNumber() const ;
  fpExponent  getExponent() const;
  fpSignificand getSignificand();
  fpSign getSign();
  expression* getExpression();
  expression* getExpression() const;
  void setExpression(expression*);

  //operator overloads
  fpCompiler operator+(fpCompiler num);
  fpCompiler operator-(fpCompiler num);
  fpCompiler operator*(fpCompiler num);
  fpCompiler operator=(const fpCompiler& num);
  fpCompiler operator=( const float& num);
  operator float();
   void printExpressionTree();
   
  //bit accurate models of * + etc, bit accurate models of hardware modules
  // fpInternal fpCompiler::fpmul(fpCompiler dataa, fpCompiler datab);
  // fpInternal fpCompiler::fpadd(fpCompiler dataa, fpCompiler datab, int addsub);
  fpInternal fpCompiler::castftox(sc_fixed<32,32> innum);
  sc_fixed<32,32> fpCompiler::castxtof();

 private:

  //vector of expressions to store the computations on this number
  expression* exp;

  // a value representing the number
  fpInternal number;

 };      
#endif


