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

class LexanDuplicateLiteralPattern: Exception {
    string duplicate_pattern;

    this(string name, string file=__FILE__, size_t line=__LINE__, Throwable next=null)
    {
        duplicate_pattern = name;
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

    void add_tail(string new_tail, long nt_lexeme_index)
    {
        if (new_tail.length == 0) {
            if (lexeme_index >= 0) throw new LexanException("");
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
    this(ref LiteralLexeme!(H)[] lexeme_list)
    {
        lexemes = lexeme_list;
        for (auto i = 0; i < lexemes.length; i++) {
            auto lexeme = lexemes[i];
            auto literal = lexeme.pattern;
            if (literal[0] in literals) {
                try {
                    literals[literal[0]].add_tail(literal[1 .. $], i);
                } catch (LexanException edata) {
                    throw new LexanDuplicateLiteralPattern(literal);
                }
            } else {
                literals[literal[0]] = new LiteralMatchNode!(H)(literal[1 .. $], i);
            }
        }
    }

    LiteralLexeme!(H) get_longest_match(string target)
    {
        LiteralLexeme!(H) lvm;
        auto lits = literals;
        for (auto index = 0; index < target.length && target[index] in lits; index++) {
            if (lits[target[index]].lexeme_index >= 0)
                lvm = lexemes[lits[target[index]].lexeme_index];
            lits = lits[target[index]].tails;
        }
        return lvm;
    }
}
unittest {
    import std.exception;
    auto test_strings = ["alpha", "beta", "gamma", "delta", "test", "tes", "tenth", "alpine", "gammon", "gamble"];
    LiteralLexeme!int[] test_lexemes;
    for (auto i = 0; i < test_strings.length; i++) {
        test_lexemes ~= LiteralLexeme!int(i, test_strings[i]);
    }
    auto rubbish = "garbage";
    auto lm = new LiteralMatcher!int(test_lexemes);
    foreach(test_string; test_strings) {
        assert(lm.get_longest_match(test_string).is_valid);
        assert(lm.get_longest_match(rubbish ~ test_string).is_valid == false);
        assert(lm.get_longest_match((rubbish ~ test_string)[rubbish.length .. $]).is_valid == true);
        assert(lm.get_longest_match((rubbish ~ test_string ~ rubbish)[rubbish.length .. $]).is_valid == true);
        assert(lm.get_longest_match(test_string ~ rubbish).is_valid == true);
    }
    foreach(test_string; test_strings) {
        assert(lm.get_longest_match(test_string).pattern == test_string);
        assert(lm.get_longest_match(rubbish ~ test_string).is_valid == false);
        assert(lm.get_longest_match((rubbish ~ test_string)[rubbish.length .. $]).pattern == test_string);
        assert(lm.get_longest_match((rubbish ~ test_string ~ rubbish)[rubbish.length .. $]).pattern == test_string);
        assert(lm.get_longest_match(test_string ~ rubbish).pattern == test_string);
    }
    auto bad_strings = test_strings ~ "gamma";
    LiteralLexeme!int[] bad_lexemes;
    for (auto i = 0; i < bad_strings.length; i++) {
        bad_lexemes ~= LiteralLexeme!int(i, bad_strings[i]);
    }
    try {
        auto bad_lm = new LiteralMatcher!int(bad_lexemes);
        assert(false, "should blow up before here!");
    } catch (LexanDuplicateLiteralPattern edata) {
        assert(edata.duplicate_pattern == "gamma");
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

class LexanInvalidToken: Exception {
    string unexpected_text;
    CharLocation location;

    this(string utext, CharLocation locn, string file=__FILE__, size_t line=__LINE__, Throwable next=null)
    {
        string msg = format("Lexan: Invalid Iput: \"%s\" at %s.", utext, locn);
        super(msg, file, line, next);
    }
}

class Token(H) {
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
        if (!_is_valid_match) throw new LexanInvalidToken(_matchedText, location);
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

struct HandleAndText(H) {
    H handle;
    string text;

    @property
    size_t length()
    {
        return text.length;
    }

    @property
    bool is_valid()
    {
        return text.length > 0;
    }
}

class LexicalAnalyser(H) {
    private LiteralMatcher!(H) literalMatcher;
    private TokenSpec!(H)[] regexTokenSpecs;
    private Regex!(char)[] skipReList;

    this(TokenSpec!(H)[] tokenSpecs, string[] skipPatterns = [])
    in {
        // Unique handles
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
        LiteralLexeme!(H)[] lexemes;
        foreach (ts; tokenSpecs) {
            if (ts.matchType == MatchType.literal) {
                lexemes ~= LiteralLexeme!(H)(ts.handle, ts.pattern);
            } else if (ts.matchType == MatchType.regularExpression) {
                regexTokenSpecs ~= ts;
            }
        }
        literalMatcher = new LiteralMatcher!(H)(lexemes);
        foreach (skipPat; skipPatterns) {
            skipReList ~= regex("^" ~ skipPat);
        }
    }

    size_t get_skippable_count(string text)
    {
        size_t index = 0;
        while (index < text.length) {
            auto skips = 0;
            foreach (skipRe; skipReList) {
                auto m = match(text[index .. $], skipRe);
                if (!m.empty) {
                    index += m.hit.length;
                    skips++;
                }
            }
            if (skips == 0) break;
        }
        return index;
    }

    LiteralLexeme!(H) get_longest_literal_match(string text)
    {
        return literalMatcher.get_longest_match(text);
    }

    HandleAndText!(H) get_longest_regex_match(string text)
    {
        HandleAndText!(H) hat;

        foreach (tspec; regexTokenSpecs) {
            auto m = match(text, tspec.re);
            // TODO: check for two or more of the same length
            // and throw a wobbly
            if (m && m.hit.length > hat.length) {
                hat = HandleAndText!(H)(tspec.handle, m.hit);
            }
        }

        return hat;
    }

    size_t distance_to_next_valid_input(string text)
    {
        size_t index = 0;
        mainloop: while (index < text.length) {
            // Assume that the front of the text is invalid
            // TODO: put in precondition to that effect
            index++;
            if (literalMatcher.get_longest_match(text[index .. $]).is_valid) break;
            foreach (tspec; regexTokenSpecs) {
                if (match(text[index .. $], tspec.re)) break mainloop;
            }
            foreach (skipRe; skipReList) {
                if (match(text[index .. $], skipRe)) break mainloop;
            }
        }
        return index;
    }

    TokenInputRange!(H) input_token_range(string text, string label="")
    {
        return new TokenInputRange!(H)(this, text, label);
    }

    InjectableTokenInputRange!(H) injectable_input_token_range(string text, string label="")
    {
        return new InjectableTokenInputRange!(H)(this, text, label);
    }
}

class TokenInputRange(H) {
    LexicalAnalyser!(H) analyser;
    private string inputText;
    private CharLocation index_location;
    private Token!(H) currentMatch;

    this (LexicalAnalyser!(H) analyser, string text, string label="")
    {
        this.analyser = analyser;
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

    private Token!(H) advance()
    {
        while (index_location.index < inputText.length) {
            // skips have highest priority
            incr_index_location(analyser.get_skippable_count(inputText[index_location.index .. $]));

            // The reported location is for the first character of the match
            auto location = index_location;

            // Find longest match found by literal match or regex
            auto llm = analyser.get_longest_literal_match(inputText[index_location.index .. $]);

            auto lrem = analyser.get_longest_regex_match(inputText[index_location.index .. $]);

            if (llm.is_valid && llm.length >= lrem.length) {
                // if the matches are of equal length literal wins
                incr_index_location(llm.length);
                return new Token!(H)(llm.handle, llm.pattern, location);
            } else if (lrem.length) {
                incr_index_location(lrem.length);
                return new Token!(H)(lrem.handle, lrem.text, location);
            } else {
                // Failure: send back the offending character(s) and location
                auto start = index_location.index;
                incr_index_location(analyser.distance_to_next_valid_input(inputText[index_location.index .. $]));
                return new Token!(H)(inputText[start .. index_location.index], location);
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
    Token!(H) front()
    {
        return currentMatch;
    }

    void popFront()
    {
        currentMatch = advance();
    }
}

unittest {
    import std.exception;
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
    auto laspec = new LexicalAnalyser!string(tslist, skiplist);
    auto la = laspec.input_token_range("if iffy\n \"quoted\" \"if\" \n9 $ \tname &{ one \n two &} and so ?{on?}");
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
    assertThrown!LexanInvalidToken(m.handle != "blah blah blah");
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
    la = laspec.input_token_range("
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
    auto ilaspec = new LexicalAnalyser!int(tilist, skiplist);
    auto ila = ilaspec.input_token_range("if iffy\n \"quoted\" $! %%name \"if\" \n9 $ \tname &{ one \n two &} and so ?{on?}");
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

class InjectableTokenInputRange(H) {
    LexicalAnalyser!(H) analyser;
    TokenInputRange!(H)[] token_range_stack;

    this (LexicalAnalyser!(H) analyser, string text, string label)
    {
        this.analyser = analyser;
        token_range_stack ~= analyser.input_token_range(text, label);
    }

    void inject(string text, string label)
    {
        token_range_stack ~= analyser.input_token_range(text, label);
    }

    @property
    bool empty()
    {
        return token_range_stack.length == 0;
    }

    @property
    Token!(H) front()
    {
        if (token_range_stack.length == 0) return null;
        return token_range_stack[$ - 1].currentMatch;
    }

    void popFront()
    {
        token_range_stack[$ - 1].popFront();
        while (token_range_stack.length > 0 && token_range_stack[$ - 1].empty) token_range_stack.length--;
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
    auto laspec = new LexicalAnalyser!string(tslist, skiplist);
    auto ila = laspec.injectable_input_token_range("if iffy\n \"quoted\" \"if\" \n9 $ \tname &{ one \n two &} and so ?{on?}", "one");
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
