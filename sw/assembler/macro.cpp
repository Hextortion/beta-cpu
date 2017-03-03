#include <iostream>
#include <string>
#include <vector>

#include "macro.h"

using std::string;
using std::vector;
using std::ostream;

macro::macro(string& name, string& body, vector<string>& params) :
        name_(name), body_(body), params_(params) 
{
    called_ = false;
}

// ostream& operator<<(ostream& os, const macro& m)
// {
//     os << "\nmacro " << m.name_ << "(";
//     vector<string>::const_iterator it = m.params_.begin();
//     if (m.params_.size() >= 2) {
//         for (; it != (m.params_.end() - 1); ++it) {
//             os << *it << ", ";
//         }
//         os << *it << ")";
//     } else if (m.params_.size() == 1) {
//         os << *it << ")";
//     } else {
//         os << ")";
//     }
//     os << "\nbody:\n" << m.body_;
//     return os;
// }