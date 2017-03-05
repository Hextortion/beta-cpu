#include <string>
#include <vector>
#include <iostream>

#include "macro.h"
#include "symbol.h"

using std::ostream;
using std::string;
using std::vector;
using std::cout;
using std::endl;

symbol::symbol(string& name, int value, symbol_type type) : 
        name_(name), value_(value), type_(type) 
{
    macro_defs_ = vector<macro>();
}

symbol::symbol(string& name, int value) : symbol(name, value, ASSIGN) {}

symbol::symbol(string& name) : symbol(name, 0, UNDEF) {}

ostream& operator<<(ostream& os, const symbol& s)
{
    os << "symbol " << s.name_ << " = " << s.value_;
    for (auto & m : s.macro_defs_) {
        os << m;
    }
    os << "\n";
    return os;
}