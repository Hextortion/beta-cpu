#ifndef MACRO_H
#define MACRO_H

#include <string>
#include <vector>
#include <iostream>

using std::vector;
using std::string;
using std::ostream;

class macro {
public:
    macro() = default;
    macro(string& name, string& body, vector<string>& params);

    string name_;
    string body_;
    vector<string> params_;
    bool called_;
};

ostream& operator<<(ostream& os, const macro& m);

#endif