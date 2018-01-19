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

#include "expression.h"
#include "fpCompiler.h"
#include <iostream>

expression::expression(fpCompiler* lop_, fpCompiler* rop_, int op_){
  lop = lop_;
  rop = rop_;
  op = op_;
}
expression::expression(expression const &other){
  copy(other);
}

void expression::copy(expression const &other) {
  lop = other.lop ? new fpCompiler (*other.lop) : 0;
  rop = other.rop ? new fpCompiler (*other.rop) : 0;
  op = other.op;

}
   
expression::~expression(){
  //cout << "destructor "<< endl;
  delete rop;
  delete lop;
}

fpCompiler* expression::getLop() {
  return lop;
}
  
fpCompiler* expression::getRop() {
  return rop;
}
  
int expression::getOp() {
  return op;
}

expression  expression::operator=( const expression& num){
#ifdef DEBUGFPCOMPILER
  cout << "expression: operator= : Evaluating expression -> expression " << endl;
#endif
  return num;
}


 
