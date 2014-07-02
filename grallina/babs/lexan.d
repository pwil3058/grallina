// lexan.d
//
// Copyright Peter Williams 2014 <pwil3058@bigpond.net.au>.
//
// This file is part of dguitk.
//
// dguitk is free software; you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation; either version 3
// of the License, or (at your option) any later version, with
// some exceptions, please read the COPYING file.
//
// dguitk is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with dguitk; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110, USA

module grallina.babs.lexan;

import std.regex;
import std.ascii;
import std.string;

class LexanException: Exception {
    this(string message, string file=__FILE__, size_t line=__LINE__, Throwable next=null)
    {
        super("LexAn Error:" ~ message, file, line, next);
    }
}

struct LiteralLexeme(H) {
    H handle;
    string pattern;

    @property
    size_t length()
    {
        return pattern.length;
    }

    @property
    bool is_valid()
    {
        return pattern.length > 0;
    }
}
unittest {
    LiteralLexeme!(int) el;
    assert(!el.is_valid);
    static auto ll = LiteralLexeme!(int)(6, "six");
    assert(ll.is_valid);
}

struct RegexLexeme(H, RE) {
    H handle;
    RE re;

    @property
    bool is_valid()
    {
        return !re.empty;
    }
}
unittest {
    RegexLexeme!(int, StaticRegex!char) erel;
    assert(!erel.is_valid);
    static auto rel = RegexLexeme!(int, StaticRegex!char)(12, ctRegex!("^twelve"));
    assert(rel.is_valid);
    RegexLexeme!(int, Regex!char) edrel;
    assert(!edrel.is_valid);
    auto drel =  RegexLexeme!(int, Regex!char)(12, regex("^twelve"));
    assert(drel.is_valid);
}

enum MatchType {literal, regularExpression};

class TokenSpec(H) {
    immutable H handle;
    immutable MatchType matchType;
    union {
        immutable string pattern;
        Regex!(char) re;
    }

    this(H handle, string specdef)
    {
        this.handle = handle;
        if (specdef[0] == '"' && specdef[$ - 1] == '"') {
            matchType = MatchType.literal;
            pattern = specdef[1 .. $ - 1];
        } else {
            matchType = MatchType.regularExpression;
            re =  regex("^" ~ specdef);
        }
    }
}

unittest {
    auto ts = new TokenSpec!string("TEST", "\"test\"");
    assert(ts.handle == "TEST");
    assert(ts.matchType == MatchType.literal);
    assert(ts.pattern == "test");
    ts = new TokenSpec!string("TESTRE", "[a-zA-Z]+");
    assert(ts.handle == "TESTRE");
    assert(ts.matchType == MatchType.regularExpression);
    assert(!ts.re.empty);
    auto ti = new TokenSpec!int(5, "[a-zA-Z]+");
    assert(ti.handle == 5);
    assert(ti.matchType == MatchType.regularExpression);
    assert(!ti.re.empty);
}

class LexanDuplicateLiteral: Exception {
    this(string name, string file=__FILE__, size_t line=__LINE__, Throwable next=null)
    {
        super(format("Duplicated literal specification: \"%s\".", name), file, line, next);
    }
}

private class LiteralMatchNode(H) {
    long lexeme_index;
    LiteralMatchNode!(H)[char] tails;

    this(string str, long str_lexeme_index)
    {
        if (str.length == 0) {
            lexeme_index = str_lexeme_index;
        } else {
            lexeme_index = -1;
            tails[str[0]] = new LiteralMatchNode(str[1 .. $], str_lexeme_index);
        }
    }

    @property
    bool validMatch()
    {
        return lexeme_index >= 0;
    }

    void add_tail(string new_tail, long nt_lexeme_index)
    {
        if (new_tail.length == 0) {
            if (validMatch) throw new LexanException("");
            lexeme_index = nt_lexeme_index;
        } else if (new_tail[0] in tails) {
            tails[new_tail[0]].add_tail(new_tail[1 .. $], nt_lexeme_index);
        } else {
            tails[new_tail[0]] = new LiteralMatchNode(new_tail[1 .. $], nt_lexeme_index);
        }
    }
}

class LiteralMatcher(H) {
private:
    LiteralLexeme!(H)[] lexemes;
    LiteralMatchNode!(H)[char] literals;

public:
    void add_literal(ref LiteralLexeme!(H) lexeme)
    {
        lexemes ~= lexeme;
        auto literal = lexeme.pattern;
        auto lexeme_index = cast(long) lexemes.length - 1;
        if (literal[0] in literals) {
            try {
                literals[literal[0]].add_tail(literal[1 .. $], lexeme_index);
            } catch (LexanException edata) {
                throw new LexanDuplicateLiteral(literal);
            }
        } else {
            literals[literal[0]] = new LiteralMatchNode!(H)(literal[1 .. $], lexeme_index);
        }
    }

    LiteralLexeme!(H) get_longest_match(string target)
    {
        LiteralLexeme!(H) lvm;
        auto lits = literals;
        for (auto index = 0; index < target.length && target[index] in lits; index++) {
            if (lits[target[index]].validMatch)
                lvm = lexemes[lits[target[index]].lexeme_index];
            lits = lits[target[index]].tails;
        }
        return lvm;
    }
}

unittest {
    import std.exception;
    auto lm = new LiteralMatcher!int;
    auto test_strings = ["alpha", "beta", "gamma", "delta", "test", "tes", "tenth", "alpine", "gammon", "gamble"];
    LiteralLexeme!int[] test_lexemes;
    for (auto i = 0; i < test_strings.length; i++) {
        test_lexemes ~= LiteralLexeme!int(i, test_strings[i]);
    }
    auto rubbish = "garbage";
    foreach(test_string; test_strings) {
        assert(lm.get_longest_match(rubbish ~ test_string).is_valid == false);
        assert(lm.get_longest_match((rubbish ~ test_string)[rubbish.length .. $]).is_valid == false);
        assert(lm.get_longest_match((rubbish ~ test_string ~ rubbish)[rubbish.length .. $]).is_valid == false);
        assert(lm.get_longest_match(test_string ~ rubbish).is_valid == false);
    }
    foreach(test_lexeme; test_lexemes) {
        lm.add_literal(test_lexeme);
    }
    foreach(test_lexeme; test_lexemes) {
        assertThrown!LexanDuplicateLiteral(lm.add_literal(test_lexeme));
    }
    foreach(test_string; test_strings) {
        assert(lm.get_longest_match(test_string).pattern == test_string);
    }
    foreach(test_string; test_strings) {
        assert(lm.get_longest_match(rubbish ~ test_string).is_valid == false);
        assert(lm.get_longest_match((rubbish ~ test_string)[rubbish.length .. $]).pattern == test_string);
        assert(lm.get_longest_match((rubbish ~ test_string ~ rubbish)[rubbish.length .. $]).pattern == test_string);
        assert(lm.get_longest_match(test_string ~ rubbish).pattern == test_string);
    }
}

struct CharLocation {
    // Line numbers and offsets both start at 1 (i.e. human friendly)
    // as these are used for error messages.
    size_t index;
    size_t lineNumber;
    size_t offset;
    string label; // e.g. name of file that text came from

    const string toString()
    {
        if (label.length > 0) {
            return format("%s:%s(%s)", label, lineNumber, offset);
        } else {
            return format("%s(%s)", lineNumber, offset);
        }
    }
}

class MatchResult(H) {
private:
    H _handle;
    string _matchedText;
    CharLocation _location;
    bool _is_valid_match;

public:
    this(H handle, string text, CharLocation locn)
    {
        _handle = handle;
        _matchedText = text;
        _location = locn;
        _is_valid_match = true;
    }

    this(string text, CharLocation locn)
    {
        _matchedText = text;
        _location = locn;
        _is_valid_match = false;
    }

    @property
    H handle()
    {
        if (!_is_valid_match) throw new LexanException("");
        return _handle;
    }

    @property
    ref string matchedText()
    {
        return _matchedText;
    }

    @property
    CharLocation location()
    {
        return _location;
    }

    @property
    bool is_valid_match()
    {
        return _is_valid_match;
    }
}

class LexicalAnalyserSpecification(H) {
    private LiteralMatcher!(H) literalMatcher;
    private TokenSpec!(H)[] regexTokenSpecs;
    private Regex!(char)[] skipReList;

    this(TokenSpec!(H)[] tokenSpecs, string[] skipPatterns = [])
    in {
        // Unique handles and out will check unique patterns
        foreach (i; 0 .. tokenSpecs.length) {
            foreach (j; i + 1 .. tokenSpecs.length) {
                assert(tokenSpecs[i].handle != tokenSpecs[j].handle);
            }
        }
    }
    out {
        assert(skipReList.length == skipPatterns.length);
    }
    body {
        literalMatcher = new LiteralMatcher!(H);
        foreach (ts; tokenSpecs) {
            if (ts.matchType == MatchType.literal) {
                auto lexeme = LiteralLexeme!(H)(ts.handle, ts.pattern);
                literalMatcher.add_literal(lexeme);
            } else if (ts.matchType == MatchType.regularExpression) {
                regexTokenSpecs ~= ts;
            }
        }
        foreach (skipPat; skipPatterns) {
            skipReList ~= regex("^" ~ skipPat);
        }
    }

    LexicalAnalyser!(H) new_analyser(string text, string label="")
    {
        return new LexicalAnalyser!(H)(this, text, label);
    }

    InjectableLexicalAnalyser!(H) new_injectable_analyser(string text, string label="")
    {
        return new InjectableLexicalAnalyser!(H)(this, text, label);
    }
}

class LexicalAnalyser(H) {
    LexicalAnalyserSpecification!(H) specification;
    private string inputText;
    private CharLocation index_location;
    private MatchResult!(H) currentMatch;

    this (LexicalAnalyserSpecification!(H) specification, string text, string label="")
    {
        this.specification = specification;
        index_location = CharLocation(0, 1, 1, label);
        inputText = text;
        currentMatch = advance();
    }

    private void incr_index_location(size_t length)
    {
        auto next_index = index_location.index + length;
        for (auto i = index_location.index; i < next_index; i++) {
            static if (newline.length == 1) {
                if (newline[0] == inputText[i]) {
                    index_location.lineNumber++;
                    index_location.offset = 1;
                } else {
                    index_location.offset++;
                }
            } else {
                if (newline == inputText[i .. i + newline.length]) {
                    index_location.lineNumber++;
                    index_location.offset = 0;
                } else {
                    index_location.offset++;
                }
            }
        }
        index_location.index = next_index;
    }

    private MatchResult!(H) advance()
    {
        mainloop: while (index_location.index < inputText.length) {
            // skips have highest priority
            foreach (skipRe; specification.skipReList) {
                auto m = match(inputText[index_location.index .. $], skipRe);
                if (!m.empty) {
                    incr_index_location(m.hit.length);
                    continue mainloop;
                }
            }

            // The reported location is for the first character of the match
            auto location = index_location;

            // Find longest match found by literal match or regex
            auto llm = specification.literalMatcher.get_longest_match(inputText[index_location.index .. $]);

            auto lrem = "";
            TokenSpec!(H) lremts;
            foreach (tspec; specification.regexTokenSpecs) {
                auto m = match(inputText[index_location.index .. $], tspec.re);
                if (m && m.hit.length > lrem.length) {
                    lrem = m.hit;
                    lremts = tspec;
                }
            }

            if (llm.is_valid && llm.length >= lrem.length) {
                // if the matches are of equal length literal wins
                incr_index_location(llm.length);
                return new MatchResult!(H)(llm.handle, llm.pattern, location);
            } else if (lrem.length) {
                incr_index_location(lrem.length);
                return new MatchResult!(H)(lremts.handle, lrem, location);
            } else {
                // Failure: send back the offending character(s) and location
                auto start = index_location.index;
                auto i = start;
                main_loop: while (i < inputText.length) {
                    // Gobble characters until something makes sense
                    i++;
                    if (specification.literalMatcher.get_longest_match(inputText[i .. $]).is_valid) break;
                    foreach (tspec; specification.regexTokenSpecs) {
                        if (match(inputText[i .. $], tspec.re)) break main_loop;
                    }
                    foreach (skipRe; specification.skipReList) {
                        if (match(inputText[i .. $], skipRe)) break main_loop;
                    }
                }
                incr_index_location(i - start);
                return new MatchResult!(H)(inputText[start .. index_location.index], location);
            }
        }

        return null;
    }

    @property
    bool empty()
    {
        return currentMatch is null;
    }

    @property
    MatchResult!(H) front()
    {
        return currentMatch;
    }

    void popFront()
    {
        currentMatch = advance();
    }
}

unittest {
    auto tslist = [
        new TokenSpec!string("IF", "\"if\""),
        new TokenSpec!string("IDENT", "[a-zA-Z]+[\\w_]*"),
        new TokenSpec!string("BTEXTL", r"&\{(.|[\n\r])*&\}"),
        new TokenSpec!string("PRED", r"\?\{(.|[\n\r])*\?\}"),
        new TokenSpec!string("LITERAL", "(\"\\S+\")"),
        new TokenSpec!string("ACTION", r"(!\{(.|[\n\r])*?!\})"),
        new TokenSpec!string("PREDICATE", r"(\?\((.|[\n\r])*?\?\))"),
        new TokenSpec!string("CODE", r"(%\{(.|[\n\r])*?%\})"),
    ];
    auto skiplist = [
        r"(/\*(.|[\n\r])*?\*/)", // D multi line comment
        r"(//[^\n\r]*)", // D EOL comment
        r"(\s+)", // White space
    ];
    auto laspec = new LexicalAnalyserSpecification!string(tslist, skiplist);
    auto la = laspec.new_analyser("if iffy\n \"quoted\" \"if\" \n9 $ \tname &{ one \n two &} and so ?{on?}");
    auto m = la.front(); la.popFront();
    assert(m.handle == "IF" && m.matchedText == "if" && m.location.lineNumber == 1);
    m = la.front(); la.popFront();
    assert(m.handle == "IDENT" && m.matchedText == "iffy" && m.location.lineNumber == 1);
    m = la.front(); la.popFront();
    assert(m.handle == "LITERAL" && m.matchedText == "\"quoted\"" && m.location.lineNumber == 2);
    m = la.front(); la.popFront();
    assert(m.handle == "LITERAL" && m.matchedText == "\"if\"" && m.location.lineNumber == 2);
    m = la.front(); la.popFront();
    assert(!m.is_valid_match && m.matchedText == "9" && m.location.lineNumber == 3);
    m = la.front(); la.popFront();
    assert(!m.is_valid_match && m.matchedText == "$" && m.location.lineNumber == 3);
    m = la.front(); la.popFront();
    assert(m.handle == "IDENT" && m.matchedText == "name" && m.location.lineNumber == 3);
    m = la.front(); la.popFront();
    assert(m.handle == "BTEXTL" && m.matchedText == "&{ one \n two &}" && m.location.lineNumber == 3);
    m = la.front(); la.popFront();
    assert(m.handle == "IDENT" && m.matchedText == "and" && m.location.lineNumber == 4);
    m = la.front(); la.popFront();
    assert(m.handle == "IDENT" && m.matchedText == "so" && m.location.lineNumber == 4);
    m = la.front(); la.popFront();
    assert(m.handle == "PRED" && m.matchedText == "?{on?}" && m.location.lineNumber == 4);
    assert(la.empty);
    la = laspec.new_analyser("
    some identifiers
// a single line comment with \"quote\"
some more identifiers.
/* a
multi line
comment */

\"+=\" and more ids.
\"\"\"
and an action !{ some D code !} and a predicate ?( a boolean expression ?)
and some included code %{
    kllkkkl
    hl;ll
%}
");
    m = la.front(); la.popFront();
    assert(m.handle == "IDENT" && m.matchedText == "some" && m.location.lineNumber == 2);
    m = la.front(); la.popFront();
    assert(m.handle == "IDENT" && m.matchedText == "identifiers" && m.location.lineNumber == 2);
    m = la.front(); la.popFront(); m = la.front(); la.popFront(); m = la.front(); la.popFront(); m = la.front(); la.popFront();
    assert(!m.is_valid_match);
    m = la.front(); la.popFront();
    assert(m.handle == "LITERAL" && m.matchedText == "\"+=\"" && m.location.lineNumber == 9);
    m = la.front(); la.popFront(); m = la.front(); la.popFront(); m = la.front(); la.popFront(); m = la.front(); la.popFront();
    m = la.front(); la.popFront();
    assert(m.handle == "LITERAL" && m.matchedText == "\"\"\"" && m.location.lineNumber == 10);
    m = la.front(); la.popFront(); m = la.front(); la.popFront(); m = la.front(); la.popFront();
    m = la.front(); la.popFront();
    assert(m.handle == "ACTION" && m.matchedText == "!{ some D code !}" && m.location.lineNumber == 11);
    m = la.front(); la.popFront(); m = la.front(); la.popFront(); m = la.front(); la.popFront();
    m = la.front(); la.popFront();
    assert(m.handle == "PREDICATE" && m.matchedText == "?( a boolean expression ?)" && m.location.lineNumber == 11);
    m = la.front(); la.popFront(); m = la.front(); la.popFront(); m = la.front(); la.popFront(); m = la.front(); la.popFront();
    m = la.front(); la.popFront();
    assert(m.handle == "CODE" && m.matchedText == "%{\n    kllkkkl\n    hl;ll\n%}" && m.location.lineNumber == 12);
    auto tilist = [
        new TokenSpec!int(0, "\"if\""),
        new TokenSpec!int(1, "[a-zA-Z]+[\\w_]*"),
        new TokenSpec!int(2, r"&\{(.|[\n\r])*&\}"),
        new TokenSpec!int(3, r"\?\{(.|[\n\r])*\?\}"),
        new TokenSpec!int(4, "(\"\\S+\")"),
        new TokenSpec!int(5, r"(!\{(.|[\n\r])*?!\})"),
        new TokenSpec!int(6, r"(\?\((.|[\n\r])*?\?\))"),
        new TokenSpec!int(7, r"(%\{(.|[\n\r])*?%\})"),
    ];
    auto ilaspec = new LexicalAnalyserSpecification!int(tilist, skiplist);
    auto ila = ilaspec.new_analyser("if iffy\n \"quoted\" $! %%name \"if\" \n9 $ \tname &{ one \n two &} and so ?{on?}");
    auto im = ila.front(); ila.popFront();
    assert(im.handle == 0 && im.matchedText == "if" && im.location.lineNumber == 1);
    im = ila.front(); ila.popFront();
    assert(im.handle == 1 && im.matchedText == "iffy" && im.location.lineNumber == 1);
    im = ila.front(); ila.popFront();
    assert(im.handle == 4 && im.matchedText == "\"quoted\"" && im.location.lineNumber == 2);
    im = ila.front(); ila.popFront();
    assert(!im.is_valid_match && im.matchedText == "$!" && im.location.lineNumber == 2);
    im = ila.front(); ila.popFront();
    assert(!im.is_valid_match && im.matchedText == "%%" && im.location.lineNumber == 2);
}

class InjectableLexicalAnalyser(H) {
    LexicalAnalyserSpecification!(H) specification;
    LexicalAnalyser!(H)[] lexan_stack;

    this (LexicalAnalyserSpecification!(H) specification, string text, string label)
    {
        this.specification = specification;
        lexan_stack ~= specification.new_analyser(text, label);
    }

    void inject(string text, string label)
    {
        lexan_stack ~= specification.new_analyser(text, label);
    }

    @property
    bool empty()
    {
        return lexan_stack.length == 0;
    }

    @property
    MatchResult!(H) front()
    {
        if (lexan_stack.length == 0) return null;
        return lexan_stack[$ - 1].currentMatch;
    }

    void popFront()
    {
        lexan_stack[$ - 1].popFront();
        while (lexan_stack.length > 0 && lexan_stack[$ - 1].empty) lexan_stack.length--;
    }
}
unittest {
    auto tslist = [
        new TokenSpec!string("IF", "\"if\""),
        new TokenSpec!string("IDENT", "[a-zA-Z]+[\\w_]*"),
        new TokenSpec!string("BTEXTL", r"&\{(.|[\n\r])*&\}"),
        new TokenSpec!string("PRED", r"\?\{(.|[\n\r])*\?\}"),
        new TokenSpec!string("LITERAL", "(\"\\S+\")"),
        new TokenSpec!string("ACTION", r"(!\{(.|[\n\r])*?!\})"),
        new TokenSpec!string("PREDICATE", r"(\?\((.|[\n\r])*?\?\))"),
        new TokenSpec!string("CODE", r"(%\{(.|[\n\r])*?%\})"),
    ];
    auto skiplist = [
        r"(/\*(.|[\n\r])*?\*/)", // D multi line comment
        r"(//[^\n\r]*)", // D EOL comment
        r"(\s+)", // White space
    ];
    auto laspec = new LexicalAnalyserSpecification!string(tslist, skiplist);
    auto ila = laspec.new_injectable_analyser("if iffy\n \"quoted\" \"if\" \n9 $ \tname &{ one \n two &} and so ?{on?}", "one");
    auto m = ila.front(); ila.popFront();
    assert(m.handle == "IF" && m.matchedText == "if" && m.location.lineNumber == 1);
    m = ila.front(); ila.popFront();
    assert(m.handle == "IDENT" && m.matchedText == "iffy" && m.location.lineNumber == 1);
    m = ila.front(); ila.popFront();
    assert(m.handle == "LITERAL" && m.matchedText == "\"quoted\"" && m.location.lineNumber == 2);
    m = ila.front(); ila.popFront();
    assert(m.handle == "LITERAL" && m.matchedText == "\"if\"" && m.location.lineNumber == 2);
    m = ila.front(); ila.popFront();
    assert(!m.is_valid_match && m.matchedText == "9" && m.location.lineNumber == 3);
    ila.inject("if one \"name\"", "two");
    m = ila.front(); ila.popFront();
    assert(m.handle == "IF" && m.matchedText == "if" && m.location.lineNumber == 1 && m.location.label == "two");
    m = ila.front(); ila.popFront();
    assert(m.handle == "IDENT" && m.matchedText == "one" && m.location.lineNumber == 1 && m.location.label == "two");
    m = ila.front(); ila.popFront();
    assert(m.handle == "LITERAL" && m.matchedText == "\"name\"" && m.location.lineNumber == 1 && m.location.label == "two");
    m = ila.front(); ila.popFront();
    assert(!m.is_valid_match && m.matchedText == "$" && m.location.lineNumber == 3);
    m = ila.front(); ila.popFront();
    assert(m.handle == "IDENT" && m.matchedText == "name" && m.location.lineNumber == 3);
    m = ila.front(); ila.popFront();
    assert(m.handle == "BTEXTL" && m.matchedText == "&{ one \n two &}" && m.location.lineNumber == 3);
    m = ila.front(); ila.popFront();
    assert(m.handle == "IDENT" && m.matchedText == "and" && m.location.lineNumber == 4);
    m = ila.front(); ila.popFront();
    assert(m.handle == "IDENT" && m.matchedText == "so" && m.location.lineNumber == 4);
    m = ila.front(); ila.popFront();
    assert(m.handle == "PRED" && m.matchedText == "?{on?}" && m.location.lineNumber == 4);
    assert(ila.empty);
}
