#include <unordered_map>
#include <string>
#include <vector>

#include "macro.h"
#include "symbol.h"
#include "symbol_table.h"

using std::unordered_map;
using std::string;
using std::vector;
using std::pair;

bool symbol_table::add_macro(
    string& macro_name, 
    vector<string>& macro_params,
    string& macro_body)
{
    macro *m;
    if (get_macro(macro_name, macro_params.size(), &m)) {
        return false;
    } else {
        symbol *s;
        get_symbol(macro_name, true, &s);
        s->macro_defs_.push_back(
                macro(macro_name, macro_body, macro_params));
        return true;
    }
}

void symbol_table::add_symbol(
    string& symbol_name,
    int value,
    symbol::symbol_type type)
{
    table_.emplace(symbol_name, symbol(symbol_name, value, type));
}

void symbol_table::clear_macro(
    string& symbol_name)
{
    symbol *s;
    if (get_symbol(symbol_name, false, &s)) {
        s->macro_defs_.clear();
    }
}

bool symbol_table::get_macro(
    string& macro_name,
    int num_params,
    macro** macro_out)
{
    symbol *s = NULL;
    bool ret = false;
    if (get_symbol(macro_name, false, &s)) {
        auto it = s->macro_defs_.begin();
        for (; it != s->macro_defs_.end(); ++it) {
            if (it->params_.size() == num_params) {
                *macro_out = (macro *)&(*it);
                ret = true;
            }
        }
    }
    return ret;
}

bool symbol_table::get_symbol(
    string& symbol_name,
    bool create,
    symbol** symbol_out)
{
    auto it = table_.find(symbol_name);
    if (it == table_.end()) {
        if (create) {
            auto emplace_pair = table_.emplace(symbol_name, 
                    symbol(symbol_name, 0, symbol::UNDEF));
            if (emplace_pair.second) {
                *symbol_out = (symbol *)&(emplace_pair.first->second);
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    } else {
        *symbol_out = (symbol *)&(it->second);
        return true;
    }
}