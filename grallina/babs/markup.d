// markup.d
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

module grallina.babs.markup;

import std.regex;

import grallina.babs.lexan;

enum Handle {
    START_TAG,
    END_TAG,
    START_END_TAG,
    NAME,
    EQUALS,
    AMPERSAND,
    LESS_THAN,
    GREATER_THAN,
}

static auto document_literals = [
    LiteralLexeme!Handle(Handle.AMPERSAND, "&amp;"),
    LiteralLexeme!Handle(Handle.LESS_THAN, "&lt;"),
    LiteralLexeme!Handle(Handle.GREATER_THAN, "&gt;")
];

static auto start_tag_literals = [
    LiteralLexeme!Handle(Handle.EQUALS, "=")
];

template XMLName() {
    enum XMLName = "[_a-zA-Z][-_a-zA-z0-9.]*";
}

template SQString() {
    enum SQString = "'[^']*'";
}

template DQString() {
    enum DQString = `"[^"]*"`;
}

template QString() {
    enum QString = "(" ~ SQString!() ~ ")|(" ~ DQString!() ~ ")";
}

template AnythingButLtGt() {
    enum AnythingButLtGt = `(?:(?:[^<>'"/]*)|(?:` ~ QString!() ~ ")*)";
}

// TODO: convert to ctRegex when it stops crashing all the time
alias EtRegexLexeme REL;
static RegexLexeme!(Handle, Regex!char)[] document_res;
static Regex!(char)[] document_skips;
static this() {
    document_res = [
        REL!(Handle, Handle.START_TAG, "<" ~ AnythingButLtGt!() ~ "*>"),
        REL!(Handle, Handle.END_TAG, "</(" ~ XMLName!() ~ ")>"),
        REL!(Handle, Handle.START_END_TAG, "<" ~ AnythingButLtGt!() ~ "*/>"),
    ];
}
unittest {
    struct TestCase { string text; string expected_match; int expected_matcher; }
    auto test_cases = [
        TestCase("<>", "<>", 0),
        TestCase("<<a>", "", 0),
        TestCase("<a>>", "<a>", 0),
        TestCase("<a '>' >   ", "<a '>' >", 0),
        TestCase(" <<a>", "", 0),

        TestCase("</a>>>>>", "</a>", 1),
        TestCase("</_a-8.a>>>>>", "</_a-8.a>", 1),
        TestCase("</._a-8.a>>>>>", "", 1), // illegal name
        TestCase("<</a>>>>>", "", 1),

        TestCase("</>>>>", "</>", 2),
        TestCase("<a/>>>>", "<a/>", 2),
        TestCase("<a '>' />>>>", "<a '>' />", 2),
        TestCase("<<a/>>>>", "", 2),
    ];
    foreach (TestCase test_case; test_cases) {
        int[] matchers;
        int correct_matches;
        for (auto i = 0; i < 3; i++) {
            auto m = match(test_case.text, document_res[i].re);
            if (m) {
                matchers ~= i;
                if (m.hit == test_case.expected_match) {
                    correct_matches++;
                } else {
                    import std.stdio;
                    writeln(m.hit, " != ", test_case.expected_match, " ", i);
                }
            }
        }
        if (test_case.expected_match.length == 0) {
            assert(matchers.length == 0);
        } else {
            assert(matchers.length == 1);
            assert(matchers[0] == test_case.expected_matcher);
            assert(correct_matches == 1);
        }
    }
}

private static LexicalAnalyser!(Handle, Regex!char) document_lexan;

static this () {
    document_lexan = new LexicalAnalyser!(Handle, Regex!char)(document_literals, document_res, document_skips);
}
