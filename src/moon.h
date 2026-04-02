// moon.h
// a simple scripting language interpreter in C++

#ifndef MOON_H
#define MOON_H

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <map>
#include <variant>
#include <functional>
#include <memory>
#include <cmath>
#include <ctime>
#include <cstdlib>
#include <stdexcept>

struct Error {
    std::string file;
    int line;
    std::string msg;
};

struct MoonArray;
using ArrayPtr = std::shared_ptr<MoonArray>;
using Value    = std::variant<double, std::string, ArrayPtr>;

struct MoonArray { std::vector<Value> elems; };

std::string to_str(const Value& v);   // forward-declared for MoonArray::to_str
std::string to_str(const Value& v) {
    if (auto* d = std::get_if<double>(&v)) {
        char buf[32]; snprintf(buf, sizeof(buf), "%.15g", *d); return buf;
    }
    if (auto* s = std::get_if<std::string>(&v)) return *s;
    // array
    const auto& elems = std::get<ArrayPtr>(v)->elems;
    std::string r = "[";
    for (size_t i = 0; i < elems.size(); i++) {
        if (i) r += ", ";
        // quote strings inside arrays
        if (std::holds_alternative<std::string>(elems[i]))
            r += '"' + std::get<std::string>(elems[i]) + '"';
        else
            r += to_str(elems[i]);
    }
    return r + "]";
}

double to_bool(const Value& v) {
    if (auto* d = std::get_if<double>(&v))    return *d != 0.0 ? 1.0 : 0.0;
    if (auto* s = std::get_if<std::string>(&v)) return s->empty() ? 0.0 : 1.0;
    return std::get<ArrayPtr>(v)->elems.empty() ? 0.0 : 1.0;  // empty array = falsy
}

enum TK {
    NUM, STR, IDENT,
    VAR, PROC, WHILE, FOR, IN, IF, ELSE, RETURN, PRINT, BREAK,
    AND, OR, NOT,
    ASSIGN, PLUS, MINUS, STAR, SLASH,
    LT, GT, LE, GE, EQ, NEQ,
    LPAREN, RPAREN, LBRACE, RBRACE, LBRACKET, RBRACKET, COMMA, END
};
struct Token { TK type; std::string val; int line = 1; };

std::vector<Token> lex(const std::string& src, const std::string& filename = "<stdin>") {
    std::vector<Token> toks;
    size_t i = 0, n = src.size(); int line = 1;
    while (i < n) {
        if (src[i] == '\n') { line++; i++; continue; }
        if (isspace((unsigned char)src[i])) { i++; continue; }
        if (src[i] == '#') { while (i < n && src[i] != '\n') i++; continue; }
        if (src[i] == '"') {
            std::string s; i++;
            while (i < n && src[i] != '"') {
                if (src[i] == '\\' && i+1 < n) {
                    switch (src[++i]) {
                        case 'n': s+='\n'; break; case 't': s+='\t'; break;
                        case '\\':s+='\\'; break; case '"': s+='"';  break;
                        default:  s+='\\'; s+=src[i]; break;
                    }
                } else { s += src[i]; }
                i++;
            }
            toks.push_back({STR, s, line}); i++; continue;
        }
        if (isdigit((unsigned char)src[i]) ||
                (src[i] == '.' && i+1 < n && isdigit((unsigned char)src[i+1]))) {
            std::string s; bool has_dot = false;
            while (i < n && (isdigit((unsigned char)src[i]) || src[i] == '.')) {
                if (src[i] == '.') {
                    if (has_dot) throw Error{filename, line, "malformed number '" + s + ".'"};
                    has_dot = true;
                }
                s += src[i++];
            }
            toks.push_back({NUM, s, line}); continue;
        }
        if (isalpha((unsigned char)src[i]) || src[i] == '_') {
            std::string s;
            while (i < n && (isalnum((unsigned char)src[i]) || src[i] == '_')) s += src[i++];
            TK t = IDENT;
            if      (s=="var")    t=VAR;   else if (s=="proc")   t=PROC;
            else if (s=="while")  t=WHILE; else if (s=="for")    t=FOR;
            else if (s=="in")     t=IN;    else if (s=="if")     t=IF;
            else if (s=="else")   t=ELSE;  else if (s=="return") t=RETURN;
            else if (s=="print")  t=PRINT; else if (s=="break")  t=BREAK;
            else if (s=="and")    t=AND;   else if (s=="or")     t=OR;
            else if (s=="not")    t=NOT;
            toks.push_back({t, s, line}); continue;
        }
        if (i+1 < n) {
            char a=src[i], b=src[i+1];
            if (a=='<'&&b=='='){toks.push_back({LE,"<=",line}); i+=2; continue;}
            if (a=='>'&&b=='='){toks.push_back({GE,">=",line}); i+=2; continue;}
            if (a=='='&&b=='='){toks.push_back({EQ,"==",line}); i+=2; continue;}
            if (a=='!'&&b=='='){toks.push_back({NEQ,"!=",line}); i+=2; continue;}
        }
        static const std::string ops = "=+-*/<>(),{}[]";
        static const TK opt[] = {ASSIGN,PLUS,MINUS,STAR,SLASH,LT,GT,
                                  LPAREN,RPAREN,COMMA,LBRACE,RBRACE,LBRACKET,RBRACKET};
        size_t p = ops.find(src[i]);
        if (p != std::string::npos) { toks.push_back({opt[p], std::string(1,src[i]), line}); i++; continue; }
        throw Error{filename, line, std::string("unknown character '") + src[i] + "'"};
    }
    toks.push_back({END, "", line}); return toks;
}

struct ReturnSignal { Value val; };
struct BreakSignal  {};

struct Proc {
    std::vector<std::string> params;
    std::vector<Token>       body;
};

struct Interpreter {
    std::vector<Token>            T;
    size_t                        pos = 0;
    std::map<std::string, Value>& globals;
    std::map<std::string, Value>  locals;
    std::map<std::string, Proc>&  procs;
    std::function<void(const std::string&, const std::string&)> load_fn;
    bool in_proc = false;
    std::string filename;

    Token consume()    { return T[pos++]; }
    bool  check(TK t)  { return T[pos].type == t; }
    bool  match(TK t)  { if (check(t)) { pos++; return true; } return false; }
    Token expect(TK t) {
        if (!check(t)) throw Error{filename, T[pos].line, "unexpected '" + T[pos].val + "'"};
        return consume();
    }
    int cur_line() { return T[pos].line; }

    Value get_var(const std::string& n) {
        auto it = locals.find(n);   if (it != locals.end())  return it->second;
        auto it2 = globals.find(n); if (it2 != globals.end()) return it2->second;
        throw Error{filename, cur_line(), "undefined '" + n + "'"};
    }
    void decl_var(const std::string& n, Value v) {
        if (in_proc) locals[n] = v; else globals[n] = v;
    }
    void assign_var(const std::string& n, Value v) {
        auto it = locals.find(n);   if (it != locals.end())  { it->second = v; return; }
        auto it2 = globals.find(n); if (it2 != globals.end()) { it2->second = v; return; }
        if (in_proc) locals[n] = v; else globals[n] = v;
    }

    void run() { while (!check(END)) stmt(); }

    void stmt() {
        if (check(VAR)) {
            consume(); std::string n = expect(IDENT).val; expect(ASSIGN); decl_var(n, expr());
        }
        else if (check(PROC))   { proc_decl(); }
        else if (check(IF))     { if_stmt(); }
        else if (check(WHILE))  { while_stmt(); }
        else if (check(FOR))    { for_stmt(); }
        else if (check(PRINT))  { print_stmt(); }
        else if (check(RETURN)) { consume(); throw ReturnSignal{expr()}; }
        else if (check(BREAK))  { consume(); throw BreakSignal{}; }
        // indexed assignment: a[i] = v   or   a[i][j] = v
        else if (check(IDENT) && T[pos+1].type == LBRACKET) {
            indexed_assign();
        }
        // plain assignment: x = v
        else if (check(IDENT) && T[pos+1].type == ASSIGN) {
            std::string n = consume().val; consume(); assign_var(n, expr());
        }
        // bare call: f(args)
        else if (check(IDENT) && T[pos+1].type == LPAREN) { expr(); }
        else if (!check(RBRACE) && !check(END))
            throw Error{filename, cur_line(), "unexpected '" + T[pos].val + "'"};
    }

    // a[i] = v  (single-level; extend later for multi-level)
    void indexed_assign() {
        std::string n = consume().val;
        expect(LBRACKET); Value idx = expr(); expect(RBRACKET);
        // check for nested: a[i][j] = v
        if (check(LBRACKET)) {
            // resolve a[i] first, then treat it as a nested indexed assign
            Value outer = get_var(n);
            auto& ap = std::get<ArrayPtr>(outer);
            int i = checked_index(ap, idx, n);
            // now ap->elems[i] must itself be an array
            expect(LBRACKET); Value idx2 = expr(); expect(RBRACKET);
            expect(ASSIGN); Value rhs = expr();
            auto& inner = std::get<ArrayPtr>(ap->elems[i]);
            int j = checked_index(inner, idx2, n);
            inner->elems[j] = rhs;
        } else {
            expect(ASSIGN); Value rhs = expr();
            Value arr = get_var(n);
            auto& ap = std::get<ArrayPtr>(arr);
            int i = checked_index(ap, idx, n);
            ap->elems[i] = rhs;
            // no write-back needed: shared_ptr mutation is in-place
        }
    }

    int checked_index(const ArrayPtr& ap, const Value& idx, const std::string& name) {
        int i = (int)std::get<double>(idx);
        if (i < 0) i += (int)ap->elems.size();   // negative indexing: -1 = last
        if (i < 0 || i >= (int)ap->elems.size())
            throw Error{filename, cur_line(), "index " + std::to_string(i) + " out of bounds for '" + name + "'"};
        return i;
    }

    void proc_decl() {
        consume(); std::string name = expect(IDENT).val;
        expect(LPAREN);
        std::vector<std::string> params;
        while (!check(RPAREN)) {
            params.push_back(expect(IDENT).val);
            if (!check(RPAREN)) expect(COMMA);
        }
        expect(RPAREN);
        std::vector<Token> body;
        body.push_back(expect(LBRACE));
        int depth = 1;
        while (depth > 0) {
            if (check(LBRACE)) depth++; else if (check(RBRACE)) depth--;
            body.push_back(consume());
        }
        body.push_back({END, ""});
        procs[name] = {params, std::move(body)};
    }

    void run_block() {
        expect(LBRACE);
        try { while (!check(RBRACE) && !check(END)) stmt(); }
        catch (...) {
            int depth = 0;
            while (!check(END)) {
                if      (check(LBRACE)) { depth++; pos++; }
                else if (check(RBRACE)) { if (depth==0) break; depth--; pos++; }
                else pos++;
            }
            expect(RBRACE); throw;
        }
        expect(RBRACE);
    }

    void skip_block() {
        expect(LBRACE); int depth = 1;
        while (depth > 0) {
            if (check(LBRACE)) depth++; else if (check(RBRACE)) depth--;
            pos++;
        }
    }

    void if_stmt() {
        consume();
        expect(LPAREN); bool taken = to_bool(expr()) != 0.0; expect(RPAREN);
        if (taken) run_block(); else skip_block();
        while (check(ELSE)) {
            consume();
            if (check(IF)) {
                consume();
                expect(LPAREN); bool c = to_bool(expr()) != 0.0; expect(RPAREN);
                if (!taken && c) { run_block(); taken = true; } else skip_block();
            } else {
                if (!taken) run_block(); else skip_block(); break;
            }
        }
    }

    void while_stmt() {
        consume(); size_t cond = pos;
        while (true) {
            pos = cond;
            expect(LPAREN); bool c = to_bool(expr()) != 0.0; expect(RPAREN);
            if (!c) { skip_block(); break; }
            try { run_block(); } catch (BreakSignal&) { break; }
        }
    }

    // for var i in array_or_string { body }
    void for_stmt() {
        consume();                      // 'for'
        expect(LPAREN);
        expect(VAR);
        std::string var_name = expect(IDENT).val;
        expect(IN);
        Value collection = expr();
        expect(RPAREN);
        // save body position so we can re-execute
        size_t body_start = pos;

        auto run_body_with = [&](Value v) {
            pos = body_start;
            decl_var(var_name, v);       // or assign — decl shadows in proc, overwrites in top-level
            try { run_block(); } catch (BreakSignal&) { throw; }
        };

        if (std::holds_alternative<ArrayPtr>(collection)) {
            // iterate over array elements
            const auto& elems = std::get<ArrayPtr>(collection)->elems;
            bool broken = false;
            for (size_t i = 0; i < elems.size() && !broken; i++) {
                try { run_body_with(elems[i]); }
                catch (BreakSignal&) { broken = true; }
            }
            if (!broken) { pos = body_start; skip_block(); }
        } else if (std::holds_alternative<std::string>(collection)) {
            // iterate over characters
            const std::string& s = std::get<std::string>(collection);
            bool broken = false;
            for (size_t i = 0; i < s.size() && !broken; i++) {
                try { run_body_with(std::string(1, s[i])); }
                catch (BreakSignal&) { broken = true; }
            }
            if (!broken) { pos = body_start; skip_block(); }
        } else {
            throw Error{filename, cur_line(), "'for in' requires array or string"};
        }
    }

    void print_stmt() {
        int pl = T[pos].line; consume();
        std::string out;
        while (!check(END)   && !check(RBRACE) && !check(VAR)   && !check(PROC)
            && !check(WHILE) && !check(FOR)    && !check(IF)    && !check(ELSE)
            && !check(BREAK) && !check(PRINT)  && !check(RETURN)
            && !(check(IDENT) && T[pos+1].type == ASSIGN)
            && T[pos].line == pl)
            out += to_str(expr());
        std::cout << out << "\n";
    }

    // ── Proc call ─────────────────────────────────────────────────────────────

    Value call_user(const std::string& name, std::vector<Value> args) {
        auto& p = procs.at(name);
        if (args.size() != p.params.size())
            throw Error{filename, cur_line(), "arity mismatch calling '" + name + "'"};
        Interpreter sub{p.body, 0, globals, {}, procs, load_fn, true, filename};
        for (size_t i = 0; i < args.size(); i++) sub.locals[p.params[i]] = args[i];
        Value result = 0.0;
        try { sub.run_block(); } catch (ReturnSignal& r) { result = r.val; }
        return result;
    }

    Value call_builtin(const std::string& nm, std::vector<Value>& a) {
        auto d   = [&](int i) -> double { return std::get<double>(a[i]); };
        auto sv  = [&](int i) -> std::string { return std::get<std::string>(a[i]); };
        auto ap  = [&](int i) -> ArrayPtr& { return std::get<ArrayPtr>(a[i]); };
        auto chk = [&](size_t n) {
            if (a.size() != n)
                throw Error{filename, cur_line(), nm + ": expected " + std::to_string(n) + " arg(s)"};
        };
        auto chk_arr = [&](int i, const std::string& fn) {
            if (!std::holds_alternative<ArrayPtr>(a[i]))
                throw Error{filename, cur_line(), fn + ": argument must be an array"};
        };

        // ── math ──────────────────────────────────────────────────────────────
        if (nm=="floor") { chk(1); return std::floor(d(0)); }
        if (nm=="ceil")  { chk(1); return std::ceil(d(0));  }
        if (nm=="abs")   { chk(1); return std::abs(d(0));   }
        if (nm=="sqrt")  { chk(1); return std::sqrt(d(0));  }
        if (nm=="sin")   { chk(1); return std::sin(d(0));   }
        if (nm=="cos")   { chk(1); return std::cos(d(0));   }
        if (nm=="tan")   { chk(1); return std::tan(d(0));   }
        if (nm=="atan2") { chk(2); return std::atan2(d(0), d(1)); }
        if (nm=="pow")   { chk(2); return std::pow(d(0), d(1)); }
        if (nm=="log")   { chk(1); return std::log(d(0));   }
        if (nm=="log2")  { chk(1); return std::log2(d(0));  }
        if (nm=="exp")   { chk(1); return std::exp(d(0));   }
        if (nm=="rand")  { chk(0); return (double)std::rand() / RAND_MAX; }

        // ── string ────────────────────────────────────────────────────────────
        if (nm=="len") {
            chk(1);
            if (std::holds_alternative<ArrayPtr>(a[0]))
                return (double)ap(0)->elems.size();
            return (double)sv(0).size();
        }
        if (nm=="sub")  {
            chk(3); auto s=sv(0); int lo=(int)d(1), hi=(int)d(2);
            if (lo<0) lo=0; if (hi>(int)s.size()) hi=(int)s.size();
            return lo<hi ? s.substr(lo,hi-lo) : std::string{};
        }
        if (nm=="find") { chk(2); auto p=sv(0).find(sv(1)); return p==std::string::npos?-1.0:(double)p; }
        if (nm=="str")  { chk(1); return to_str(a[0]); }
        if (nm=="num")  { chk(1); return std::stod(sv(0)); }
        if (nm=="upper"){ chk(1); std::string s=sv(0); for(char&c:s)c=toupper((unsigned char)c); return s; }
        if (nm=="lower"){ chk(1); std::string s=sv(0); for(char&c:s)c=tolower((unsigned char)c); return s; }
        if (nm=="char") { chk(1); return std::string(1,(char)(int)d(0)); }
        if (nm=="asc")  { chk(1); if(sv(0).empty()) throw Error{filename,cur_line(),"asc: empty string"}; return (double)(unsigned char)sv(0)[0]; }
        if (nm=="type") {
            chk(1);
            if (std::holds_alternative<double>(a[0]))    return std::string{"number"};
            if (std::holds_alternative<std::string>(a[0]))return std::string{"string"};
            return std::string{"array"};
        }

        // ── array ─────────────────────────────────────────────────────────────
        if (nm=="arr") {
            // arr()  → empty array
            // arr(n) → array of n zeros
            // arr(n, val) → array of n copies of val
            auto a_ = std::make_shared<MoonArray>();
            if (a.size() == 0) return a_;
            int n = (int)d(0);
            Value fill = a.size() >= 2 ? a[1] : Value{0.0};
            a_->elems.resize(n, fill);
            return a_;
        }
        if (nm=="push") {
            if (a.size() < 2) throw Error{filename, cur_line(), "push: needs array and value"};
            chk_arr(0, "push");
            for (size_t i = 1; i < a.size(); i++) ap(0)->elems.push_back(a[i]);
            return a[0];   // return the array for chaining
        }
        if (nm=="pop") {
            chk(1); chk_arr(0, "pop");
            if (ap(0)->elems.empty()) throw Error{filename, cur_line(), "pop: empty array"};
            Value v = ap(0)->elems.back(); ap(0)->elems.pop_back(); return v;
        }
        if (nm=="insert") {
            // insert(arr, i, val) — insert val before index i
            if (a.size() != 3) throw Error{filename, cur_line(), "insert: needs 3 args"};
            chk_arr(0, "insert");
            int i = (int)d(1);
            if (i < 0 || i > (int)ap(0)->elems.size())
                throw Error{filename, cur_line(), "insert: index out of bounds"};
            ap(0)->elems.insert(ap(0)->elems.begin() + i, a[2]);
            return a[0];
        }
        if (nm=="remove") {
            // remove(arr, i) — remove element at index i, return it
            chk(2); chk_arr(0, "remove");
            int i = (int)d(1);
            if (i < 0) i += (int)ap(0)->elems.size();
            if (i < 0 || i >= (int)ap(0)->elems.size())
                throw Error{filename, cur_line(), "remove: index out of bounds"};
            Value v = ap(0)->elems[i];
            ap(0)->elems.erase(ap(0)->elems.begin() + i);
            return v;
        }
        if (nm=="slice") {
            // slice(arr, lo, hi) — new array with elements [lo, hi)
            chk(3); chk_arr(0, "slice");
            int lo=(int)d(1), hi=(int)d(2);
            int sz = (int)ap(0)->elems.size();
            if (lo<0) lo=0; if (hi>sz) hi=sz;
            auto r = std::make_shared<MoonArray>();
            if (lo < hi) r->elems.assign(ap(0)->elems.begin()+lo, ap(0)->elems.begin()+hi);
            return r;
        }
        if (nm=="concat") {
            // concat(a, b) — new array with all elements of a then b
            chk(2); chk_arr(0, "concat"); chk_arr(1, "concat");
            auto r = std::make_shared<MoonArray>(MoonArray{ap(0)->elems});
            r->elems.insert(r->elems.end(), ap(1)->elems.begin(), ap(1)->elems.end());
            return r;
        }
        if (nm=="join") {
            // join(arr, sep) — concatenate elements as strings with separator
            chk(2); chk_arr(0, "join"); std::string sep = sv(1), out;
            const auto& el = ap(0)->elems;
            for (size_t i = 0; i < el.size(); i++) { if(i) out+=sep; out+=to_str(el[i]); }
            return out;
        }
        if (nm=="split") {
            // split(str, delim) → array of strings
            chk(2); std::string s=sv(0), delim=sv(1);
            auto r = std::make_shared<MoonArray>();
            size_t dlen = delim.size();
            while (true) {
                size_t p = s.find(delim);
                if (p == std::string::npos) { r->elems.push_back(s); break; }
                r->elems.push_back(s.substr(0, p)); s = s.substr(p + dlen);
            }
            return r;
        }
        if (nm=="copy") {
            // copy(arr) → shallow copy (new array, same values)
            chk(1); chk_arr(0, "copy");
            return std::make_shared<MoonArray>(MoonArray{ap(0)->elems});
        }
        if (nm=="range") {
            // range(lo, hi[, step]) → [lo, lo+step, ...]
            if (a.size() < 2 || a.size() > 3)
                throw Error{filename, cur_line(), "range: needs 2 or 3 args"};
            double lo=d(0), hi=d(1), step = a.size()==3 ? d(2) : 1.0;
            if (step == 0) throw Error{filename, cur_line(), "range: step cannot be 0"};
            auto r = std::make_shared<MoonArray>();
            for (double x = lo; step>0 ? x<hi : x>hi; x += step) r->elems.push_back(x);
            return r;
        }
        if (nm=="keys") {
            // keys() — returns all global variable names (useful for debugging)
            chk(0);
            auto r = std::make_shared<MoonArray>();
            for (auto& [k, _] : globals) r->elems.push_back(k);
            return r;
        }

        // ── file I/O ──────────────────────────────────────────────────────────
        if (nm=="read") {
            chk(1); std::ifstream f(sv(0));
            if (!f) throw Error{filename, cur_line(), "read: can't open '" + sv(0) + "'"};
            return std::string(std::istreambuf_iterator<char>(f), {});
        }
        if (nm=="write") {
            chk(2); std::ofstream f(sv(0));
            if (!f) throw Error{filename, cur_line(), "write: can't open '" + sv(0) + "'"};
            f << sv(1); return 0.0;
        }
        if (nm=="append") {
            chk(2); std::ofstream f(sv(0), std::ios::app);
            if (!f) throw Error{filename, cur_line(), "append: can't open '" + sv(0) + "'"};
            f << sv(1); return 0.0;
        }
        if (nm=="load") {
            chk(1);
            if (!load_fn) throw Error{filename, cur_line(), "load: not available"};
            std::string path = sv(0); std::ifstream f(path);
            if (!f) {
                const char* home = getenv("HOME");
                if (home) { std::string hp = std::string(home) + "/.moon/" + path; f.open(hp); if (f) path = hp; }
            }
            if (!f) throw Error{filename, cur_line(), "load: can't open '" + sv(0) + "'"};
            load_fn(std::string(std::istreambuf_iterator<char>(f), {}), path);
            return 0.0;
        }

        // ── interactive & misc ────────────────────────────────────────────────
        if (nm=="input") {
            if (a.size() > 1) throw Error{filename, cur_line(), "input: 0 or 1 arg"};
            if (a.size() == 1) std::cout << to_str(a[0]) << std::flush;
            std::string line;
            if (!std::getline(std::cin, line)) return std::string{};
            return line;
        }
        if (nm=="clock") { chk(0); return (double)std::clock() / CLOCKS_PER_SEC; }
        if (nm=="exit")  { chk(1); std::exit((int)d(0)); }
        if (nm=="assert"){
            if (a.size() < 1 || a.size() > 2) throw Error{filename, cur_line(), "assert: 1 or 2 args"};
            if (!to_bool(a[0])) {
                std::string msg = a.size() == 2 ? sv(1) : "assertion failed";
                throw Error{filename, cur_line(), msg};
            }
            return 0.0;
        }

        throw Error{filename, cur_line(), "undefined '" + nm + "'"};
    }

    Value expr()     { return or_expr(); }
    Value or_expr()  { Value l=and_expr(); while(check(OR)) {consume(); Value r=and_expr(); l=(to_bool(l)||to_bool(r))?1.0:0.0;} return l; }
    Value and_expr() { Value l=not_expr(); while(check(AND)){consume(); Value r=not_expr(); l=(to_bool(l)&&to_bool(r))?1.0:0.0;} return l; }
    Value not_expr() { if(check(NOT)){consume(); return to_bool(not_expr())==0.0?1.0:0.0;} return cmp(); }

    Value cmp() {
        Value l = add();
        if (check(LT)||check(GT)||check(LE)||check(GE)||check(EQ)||check(NEQ)) {
            TK op = consume().type; Value r = add();
            if (op==EQ)  return l==r ? 1.0 : 0.0;
            if (op==NEQ) return l!=r ? 1.0 : 0.0;
            double a=std::get<double>(l), b=std::get<double>(r);
            switch(op) {
                case LT: return a<b?1.0:0.0; case GT: return a>b?1.0:0.0;
                case LE: return a<=b?1.0:0.0; case GE: return a>=b?1.0:0.0;
                default: return 0.0;
            }
        }
        return l;
    }
    Value add() {
        Value l = mul();
        while (check(PLUS)||check(MINUS)) {
            bool plus = consume().type==PLUS; Value r = mul();
            if (plus && (std::holds_alternative<std::string>(l)||std::holds_alternative<std::string>(r)))
                l = to_str(l) + to_str(r);
            else if (plus) l = std::get<double>(l) + std::get<double>(r);
            else           l = std::get<double>(l) - std::get<double>(r);
        }
        return l;
    }
    Value mul() {
        Value l = unary();
        while (check(STAR)||check(SLASH)) {
            bool star = consume().type==STAR; Value r = unary();
            l = star ? std::get<double>(l)*std::get<double>(r) : std::get<double>(l)/std::get<double>(r);
        }
        return l;
    }
    Value unary() {
        if (check(MINUS)) { consume(); return -std::get<double>(unary()); }
        return index_expr();
    }
    // index_expr: apply zero or more [i] subscripts to an atom
    Value index_expr() {
        Value v = atom();
        while (check(LBRACKET)) {
            consume();
            Value idx = expr();
            expect(RBRACKET);
            if (!std::holds_alternative<ArrayPtr>(v))
                throw Error{filename, cur_line(), "subscript on non-array"};
            auto& ap = std::get<ArrayPtr>(v);
            int i = (int)std::get<double>(idx);
            if (i < 0) i += (int)ap->elems.size();
            if (i < 0 || i >= (int)ap->elems.size())
                throw Error{filename, cur_line(), "index " + std::to_string(i) + " out of bounds"};
            v = ap->elems[i];
        }
        return v;
    }
    Value atom() {
        if (check(NUM))     return std::stod(consume().val);
        if (check(STR))     return consume().val;
        if (check(LPAREN))  { consume(); Value v=expr(); expect(RPAREN); return v; }
        // array literal: [expr, expr, ...]
        if (check(LBRACKET)) {
            consume();
            auto arr = std::make_shared<MoonArray>();
            while (!check(RBRACKET)) {
                arr->elems.push_back(expr());
                if (!check(RBRACKET)) expect(COMMA);
            }
            expect(RBRACKET);
            return arr;
        }
        if (check(IDENT)) {
            std::string n = consume().val;
            if (check(LPAREN)) {
                consume();
                std::vector<Value> args;
                while (!check(RPAREN)) {
                    args.push_back(expr());
                    if (!check(RPAREN)) expect(COMMA);
                }
                expect(RPAREN);
                auto it = procs.find(n);
                return it != procs.end() ? call_user(n, args) : call_builtin(n, args);
            }
            return get_var(n);
        }
        throw Error{filename, cur_line(), "unexpected in expr '" + T[pos].val + "'"};
    }
};

struct Environment {
    std::map<std::string, Value> globals;
    std::map<std::string, Proc>  procs;

    void exec(const std::string& src, const std::string& filename = "<stdin>") {
        auto toks = lex(src, filename);
        Interpreter interp{std::move(toks), 0, globals, {}, procs, {}, false, filename};
        interp.load_fn = [this](const std::string& s, const std::string& f){ this->exec(s, f); };
        interp.run();
    }
};

int brace_depth(const std::string& s) {
    int d = 0; bool in_str = false;
    for (char c : s) {
        if (c == '"') in_str = !in_str;
        else if (!in_str) { if (c=='{') d++; else if (c=='}') d--; }
    }
    return d;
}

void repl(Environment& env) {
    std::string buf; int depth = 0;
    while (true) {
        std::cout << (depth==0 ? "> " : ".. ") << std::flush;
        std::string line;
        if (!std::getline(std::cin, line)) { std::cout << "\n"; break; }
        depth += brace_depth(line);
        buf += line + "\n";
        if (depth <= 0) {
            depth = 0;
            if (buf.find_first_not_of(" \t\n") != std::string::npos) {
                try { env.exec(buf, "<stdin>"); }
                catch (Error& e)         { std::cerr << e.file << ":" << e.line << ": " << e.msg << "\n"; }
                catch (std::exception& e){ std::cerr << "error: " << e.what() << "\n"; }
            }
            buf.clear();
        }
    }
}

#endif // MOON_H
