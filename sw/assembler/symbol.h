#ifndef SYMBOL_H
#define SYMBOL_H

#include <string>
#include <vector>
#include <iostream>

#include "macro.h"

using std::string;
using std::vector;
using std::ostream;

class symbol;

class symbol {
public:
    enum symbol_type { UNDEF, ASSIGN, LABEL };
    
    symbol() = default;
    symbol(string& name, int value, symbol_type type);
    symbol(string& name, int value);
    symbol(string& name);

    string name_;
    int value_;
    symbol_type type_;
    vector<macro> macro_defs_;
};

#endif