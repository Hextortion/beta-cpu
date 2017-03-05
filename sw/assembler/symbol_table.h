#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <unordered_map>
#include <string>
#include <vector>

#include "macro.h"
#include "symbol.h"

using std::unordered_map;
using std::string;
using std::vector;

class symbol_table {
public:
    symbol_table() = default;
    void initialize_macros();

    bool add_macro(
        string& macro_name, 
        vector<string>& macro_params,
        string& macro_body);

    void add_symbol(
        string& symbol_name,
        int value,
        symbol::symbol_type type);

    void clear_macro(
        string& symbol_name);

    bool get_macro(
        string& macro_name,
        int num_params,
        macro** macro_out);

    bool get_symbol(
        string& symbol_name,
        bool create,
        symbol** symbol_out);

    friend ostream& operator<<(ostream& o, const symbol_table& st);

private:
    unordered_map<string, symbol> table_;
};

#endif