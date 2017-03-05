#include <iostream>
#include <fstream>
#include <istream>
#include <sstream>
#include <streambuf>
#include <string>
#include <vector>
#include <cctype>
#include <unordered_map>

#include "macro.h"
#include "symbol.h"
#include "symbol_table.h"

using std::cin;
using std::cout;
using std::endl;
using std::string;
using std::pair;
using std::ifstream;
using std::istringstream;
using std::stringstream;
using std::istreambuf_iterator;
using std::vector;
using std::unordered_map;

static symbol_table g_symbol_table;
static symbol dot;
static int pass;
static int max_dot;
static bool uses_dot;

string get_file_string(string& filename);
bool is_token_char(char c);
bool is_symbol_start_char(char c);
bool check_for_char(char c, size_t& offset, string& text);
bool is_eol(char c);

void scan(string& text);
void read_macro(size_t& offset, string& text);
string read_string(size_t& offset, string& text);
bool read_expression(size_t& offset, string& text, int& result);
bool read_term(size_t& offset, string& text, int& result);
void read_operand(size_t& offset, string& text);
int read_literal(size_t& offset, string& text);
int read_char_literal(size_t& offset, string& text);
int read_symbol_value(size_t& offset, string& text);
void call_macro(vector<int> macro_args, macro *m);
void assign_label(size_t& offset, string& token);
void assign_value(size_t& offset, string& text, string& token);
void assemble_byte(int v);
void assemble_string(size_t& offset, string& text);
int assemble_octal_digits(char ch, size_t& offset, string& text);

string get_file_string(string& filename)
{
    ifstream ifs(filename);
    return string((istreambuf_iterator<char>(ifs)), 
            istreambuf_iterator<char>());
}

void skip_blanks(size_t& offset, string& text)
{
    while (offset < text.length() && isspace(text[offset])) {
        offset++;
    }
}

bool is_token_char(char c)
{
    return isalnum(c) || c == '$' || c == '_' || c == '.';
}

bool is_symbol_start_char(char c)
{
    return isalpha(c) || c == '$' || c == '_' || c == '.';
}

bool is_eol(char c)
{
    return c == '\n' || c == '|' || c == '\0';
}

void skip_token(size_t& offset, string& text)
{
    while (offset < text.length() && is_token_char(text[offset])) {
        offset++;
    }
}

bool check_for_char(char c, size_t& offset, string& text)
{
    skip_blanks(offset, text);
    if (offset < text.length() && text[offset] == c) {
        offset++;
        return true;
    }
    return false;
}

//
// TODO: Implement error handling code
//
void read_macro(
    size_t& offset, 
    string& text)
{
    size_t start = offset;
    skip_token(offset, text);

    if (offset == start) {
        cout << "expected name following .macro" << endl;
        exit(-1);
    }

    string macro_name = text.substr(start, offset - start);
    vector<string> macro_params;
    string macro_body;

    //
    // See if parenthesized list follows. If it does, each entry should be
    // a symbol.
    //
    if (check_for_char('(', offset, text)) {
        while (true) {
            if (check_for_char(')', offset, text)) {
                break;
            }
            
            if (offset >= text.length()) {
                cout << "expected ')' in macro definition" << endl;
                exit(-1);
            }
            
            char ch = text[offset];
            if (!is_symbol_start_char(ch)) {
                cout << "symbol expected in macro parameter list" << endl;
                exit(-1);
            }

            start = offset;
            skip_token(offset, text);
            macro_params.push_back(text.substr(start, offset - start));

            skip_blanks(offset, text);
            if (offset < text.length() && text[offset] == ',') {
                offset++;
            }
        }
    }

    // Read the body of the macro
    size_t end;
    if (check_for_char('{', offset, text)) {
        end = text.find_first_of('}', offset);
    } else {
        end = text.find_first_of('\n', offset);
    }

    if (end == string::npos) {
        end = text.length();
    }

    macro_body = text.substr(offset, end - offset);
    offset = end + 1;

    if (!g_symbol_table.add_macro(macro_name, macro_params, macro_body)) {
        cout << "pass: " << pass << endl;
        cout << "failed to add macro " << macro_name << endl;
        exit(-1);
    }
}

void scan(string& text)
{
    size_t offset = 0;

    while (offset < text.length()) {
        skip_blanks(offset, text);
        if (offset < text.length() && !is_eol(text[offset])) {
            skip_blanks(offset, text);
            size_t start = offset;
            skip_token(offset, text);
            string token = text.substr(start, offset - start);
            skip_blanks(offset, text);
            char ch;

            if (offset < text.length()) {
                ch = text[offset];
            } else {
                ch = 0;
            }

            if (token == ".macro") {
                read_macro(offset, text);
                continue;
            } else if (token == ".align") {
                int align = 4;
                if (!is_eol(ch)) {
                    read_expression(offset, text, align);
                }
                while ((dot.value_ % align) != 0) {
                    assemble_byte(0);
                }
                continue;
            } else if (token == ".text") {
                assemble_string(offset, text);
                assemble_byte(0);
                while (dot.value_ % 4 != 0) {
                    assemble_byte(0);
                }
                continue;
            } else if (token == ".ascii") {
                assemble_string(offset, text);
                continue;
            }

            if (ch == ':') {
                assign_label(offset, token);
                continue;
            } else if (ch = '=') {
                assign_value(offset, text, token);
                continue;
            }

            //
            // This is not a special form, so read operands and place their 
            // value into memory.
            //
            offset = start;
            while (offset < text.length() && !is_eol(text[offset])) {
                read_operand(offset, text);
                skip_blanks(offset, text);
                if (offset < text.length() && text[offset] == ',') {
                    offset++;
                }
            }
        }

        //
        // Now we are at the EOL marker (which might be a comment char)
        // So we have to skip until we find the actual end of the line.
        //
        while (offset < text.length() && text[offset] != '\n') {
            offset++;
        }

        // Skip the newline.
        offset++;
    }
}

void assign_value(
    size_t& offset,
    string& text,
    string& token)
{
    offset++;
    symbol *s = NULL;
    if (g_symbol_table.get_symbol(token, true, &s)) {
        int v;
        if (read_expression(offset, text, v)) {
            if (s->type_ == symbol::LABEL) {
                cout << "illegal redefinition of symbol " 
                        << token << endl;
                exit(-1);
            } else {
                s->type_ = symbol::ASSIGN;
                s->value_ = v;
                if (s->name_ == "." && dot.value_ > max_dot) {
                    max_dot = dot.value_;
                }
            }
        }
    }    
}

void assign_label(
    size_t& offset,
    string& token)
{
    offset++;
    symbol *s = NULL;
    if (g_symbol_table.get_symbol(token, true, &s)) {
        if (pass == 1) {
            if (s->type_ != symbol::UNDEF) {
                cout << "multiply defined symbol " << token << endl;
                exit(-1);
            } else {
                s->type_ = symbol::LABEL;
                s->value_ = dot.value_;
            }
        } else {
            if (s->value_ != dot.value_) {
                cout << "phase error in symbol definition "
                        << token << endl;
                exit(-1);
            }
        }
    }    
}

string read_string(
    size_t& offset, 
    string& text)
{
    skip_blanks(offset, text);
    stringstream result;

    if (!check_for_char('\"', offset, text)) {
        cout << "expected double-quote as start of string" << endl;
        exit(-1);
    }

    loop:
    while (offset < text.length()) {
        char ch = text[offset++];
        switch (ch) {
            case '\"': return result.str();
            case '\n': goto loop;
            case '\\':
                if (offset < text.length()) {
                    ch = text[offset++];
                    switch (ch) {
                        case 'b': ch = '\b'; break;
                        case 'f': ch = '\f'; break;
                        case 'n': ch = '\n'; break;
                        case 'r': ch = '\r'; break;
                        case 't': ch = '\t'; break;
                    }
                }
            default: result << ch; break;
        }
    }

    cout << "unterminated string constant" << endl;
    exit(-1);
    return result.str();
}

int read_literal(
    size_t& offset,
    string& text)
{
    int base = 10;
    size_t start = offset;
    skip_token(offset, text);
    string number = text.substr(start, offset - start);
    string number_prefix = number.substr(0, 2);

    if (number_prefix == "0x" || number_prefix == "0X") {
        base = 16;
        number = number.substr(2);
    } else if (number_prefix == "0b" || number_prefix == "0B") {
        base = 2;
        number = number.substr(2);
    } else if (number[0] == '0') {
        if (number.length() > 1) {
            base = 8;
            number = number.substr(1);
        }
    }

    unsigned long lresult = std::stoul(number, nullptr, base);
    return (int)lresult;   
}

int read_symbol_value(
    size_t& offset,
    string& text)
{
    size_t start = offset;
    skip_token(offset, text);
    string name = text.substr(start, offset - start);
    symbol *s = NULL;

    if (g_symbol_table.get_symbol(name, true, &s)) {
        if (pass == 2 && s->type_ == symbol::UNDEF) {
            cout << "undefined symbol" << name << endl;
            exit(-1);
        } else {
            return s->value_;
        }
    } else {
        cout << "error getting symbol" << endl;
        exit(-1);
    }    
}

bool read_char_literal(
    size_t& offset,
    string& text,
    int& result)
{
    char ch = text[offset];
    offset += 3;
    if (offset < text.length()) {
        if (text[offset - 2] == '\\') {
            offset++;
            ch = text[offset - 2];
            switch (ch) {
                case 'b': ch = '\b'; break;
                case 'f': ch = '\f'; break;
                case 'n': ch = '\n'; break;
                case 'r': ch = '\r'; break;
                case 't': ch = '\t'; break;
            }        
        } else {
            ch = text[offset - 2];
        }
        if (offset < text.length() && text[offset - 1] == '\'') {
            result = (int)ch;
            return true;
        }
        cout << "bad character constant" << endl;
        exit(-1);
    }
    return false;
}

bool read_term(
    size_t& offset, 
    string& text, 
    int& result)
{
    skip_blanks(offset, text);
    bool ret = true;

    if (offset >= text.length()) {
        ret = false;
    }

    char ch = text[offset];

    if (isdigit(ch)) {
        result = read_literal(offset, text);
    } else if (is_symbol_start_char(ch)) {
        result = read_symbol_value(offset, text);
    } else if (ch == '\'') {
        if (!read_char_literal(offset, text, result)) {
            cout << "unable to read char literal" << endl;
            exit(-1);
        }
    } else if (ch == '-') {
        offset++;
        read_term(offset, text, result);
        result = -result;
    } else if (ch == '~') {
        offset++;
        read_term(offset, text, result);
        result = ~result;
    } else if (ch == '(') {
        offset++;
        if (read_expression(offset, text, result)) {
            skip_blanks(offset, text);
            if (offset >= text.length() || text[offset] != ')') {
                cout << "unbalanced parenthesis in expression" << endl;
                exit(-1);
            } else {
                offset++;
            }
        }
    } else {
        cout << "illegal term in expression " << offset << endl;
        cout << text.substr(offset) << endl;
        exit(-1);
    }

    return ret;
}

bool read_expression(
    size_t& offset, 
    string& text, 
    int& result)
{
    int term;
    bool valid = read_term(offset, text, result);

    while (valid) {
        skip_blanks(offset, text);
        if (offset >= text.length()) {
            break;
        }

        switch (text[offset++]) {
            case '+':
                if (valid = read_term(offset, text, term)) {
                    result = result + term;
                }
                continue;
            case '-':
                if (valid = read_term(offset, text, term)) {
                    result = result - term;
                }
                continue;
            case '*':
                if (valid = read_term(offset, text, term)) {
                    result = result * term;
                }
                continue;
            case '/':
                if (valid = read_term(offset, text, term)) {
                    result = result / term;
                }
                continue;
            case '%':
                if (valid = read_term(offset, text, term)) {
                    result = result % term;
                    result = result < 0 ? result + term : result;
                }
                continue;
            case '>':
                if (check_for_char('>', offset, text)) {
                    if (valid = read_term(offset, text, term)) {
                        result = result >> term;
                    }
                    continue;
                }
                offset--;
                goto exit;
            case '<':
                if (check_for_char('<', offset, text)) {
                    if (valid = read_term(offset, text, term)) {
                        result = result << term;
                    }
                    continue;
                }
                offset--;
                goto exit;
            default:
                offset--;
                goto exit;
        }
    }

    exit:
    return valid;
}

void read_operand(
    size_t& offset, 
    string& text)
{
    skip_blanks(offset, text);
    if (is_symbol_start_char(text[offset])) {
        size_t start = offset;
        skip_token(offset, text);
        size_t end = offset;

        if (check_for_char('(', offset, text)) {
            string macro_name = text.substr(start, end - start);

            vector<int> macro_args;
            while (true) {
                if (check_for_char(')', offset, text)) {
                    break;
                }
                check_for_char(',', offset, text);
                int v;
                if (read_expression(offset, text, v)) {
                    macro_args.push_back(v);
                } else {
                    cout << "expression or close paren expected" << endl;
                    exit(-1);
                }
            }

            macro *m = NULL;
            if (g_symbol_table.get_macro(macro_name, macro_args.size(), &m)) {
                if (m->called_) {
                    cout << "recursive call to macro " << macro_name << endl;
                    exit(-1);
                }
            } else {
                cout << "can't find macro definition for " << macro_name 
                        << " with " << macro_args.size() 
                        << " arguments" << endl;
                exit(-1);
            }

            call_macro(macro_args, m);
        }
        offset = start;
    }
    int v;
    if (read_expression(offset, text, v)) {
        assemble_byte(v);
    } else {
        cout << "illegal operand" << endl;
        exit(-1);
    }
}

void call_macro(
    vector<int> macro_args,
    macro *m)
{
    m->called_ = true;
    vector<int> saved_values;
    vector<symbol::symbol_type> saved_types;

    for (int i = 0; i < m->params_.size(); ++i) {
        symbol *s = NULL;
        if (g_symbol_table.get_symbol(m->params_[i], false, &s)) {
            saved_values.push_back(s->value_);
            saved_types.push_back(s->type_);        
            s->value_ = macro_args[i];
            s->type_ = symbol::ASSIGN;
        } else {
            cout << "could not find symbol " << m->params_[i] << endl;
            exit(-1);
        }
    }

    scan(m->body_);
    m->called_ = false;

    for (int i = 0; i < m->params_.size(); ++i) {
        symbol *s = NULL;
        if (g_symbol_table.get_symbol(m->params_[i], false, &s)) {      
            s->value_ = saved_values[i];
            s->type_ = saved_types[i];
        } else {
            cout << "could not find symbol " << m->params_[i] << endl;
            exit(-1);
        }
    }
}

void assemble_byte(int v)
{
    if (pass == 2) {
        cout << "mem[" << dot.value_ << "] = " << v << endl;
    }

    dot.value_++;

    if (dot.value_ > max_dot) {
        max_dot = dot.value_;
    }
}

void assemble_string(
    size_t& offset,
    string& text)
{
    if (check_for_char('\"', offset, text)) {
        while (offset < text.length()) {
            char ch = text[offset++];
            switch (ch) {
                case '\"':
                    return;
                case '\n':
                    goto exit_loop;
                case '\\':
                    if (offset < text.length()) {
                        ch = text[offset++];
                    }
                    switch (ch) {
                        case 'b': ch = '\b'; break;
                        case 'f': ch = '\f'; break;
                        case 'n': ch = '\n'; break;
                        case 'r': ch = '\r'; break;
                        case 't': ch = '\t'; break;
                        case '\\': ch = '\\'; break;
                        default:
                            if (ch >= '0' && ch <= '7') {
                                ch = assemble_octal_digits(ch, offset, text);
                            }
                    }
                default:
                    assemble_byte(ch);
                    break;
            }
        }
        exit_loop:
        cout << "unterminated string constant" << endl;
        exit(-1);
    }
}

int assemble_octal_digits(
    char ch, 
    size_t& offset, 
    string& text)
{
    int result = ch - '0';
    if (offset < text.length()) {
        ch = text[offset];
        if (ch >= '0' && ch <= '7') {
            offset++;
            result = result * 8 + ch - '0';
            if (offset < text.length()) {
                ch = text[offset];
                if (ch >= '0' && ch <= '7') {
                    offset++;
                    result = result * 7 + ch - '0';
                }
            }
        }
    }
    return result;
}

int main(
    int argc,
    char *argv[])
{
    if (argc < 2) {
        return -1;
    }

    string filename = argv[1];
    string text = get_file_string(filename);

    string dot_name = ".";
    dot = symbol(dot_name, 0);
    max_dot = 0;
    pass = 1;
    g_symbol_table.initialize_macros();
    
    scan(text);

    dot.value_ = 0;
    max_dot = 0;
    pass = 2;
    g_symbol_table.initialize_macros();

    scan(text);

    return 0;
}