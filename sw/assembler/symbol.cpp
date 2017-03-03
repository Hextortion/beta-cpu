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

// void symbol::add_macro_definition(macro m)
// {
//     macro_defs_.push_back(m);
// }

// void symbol::clear_macro_definitions()
// {
//     macro_defs_.clear();
// }

// bool symbol::lookup_macro(int num_params, macro* m)
// {
//     for (auto &p : macro_defs_) {
//         if (macro_defs_.size() == num_params) {
//             m = &p;
//             return true;
//         }
//     }
//     return false;
// }

// ostream& operator<<(ostream& os, const symbol& s)
// {
//     os << "symbol " << s.name_ << " = " << s.value_;
//     for (auto const& m : s.macro_defs_) {
//         os << m;
//     }
//     return os;
// }

// int main()
// {
//     symbol s1("test", 2);

//     vector<string> vs1;
//     vs1.push_back("r0");
//     vs1.push_back("r1");
//     vs1.push_back("r2");
//     string b1 = "r0 = r1 + r2";
//     macro m1("test", b1, vs1);
//     s1.add_macro_definition(m1);

//     cout << s1 << endl;

//     return 0;
// }