// markup.d
//
// Copyright Peter Williams 2014 <pwil3058@bigpond.net.au>.
//
// This file is part of grallina.
//
// grallina is free software; you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation; either version 3
// of the License, or (at your option) any later version, with
// some exceptions, please read the COPYING file.
//
// grallina is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with grallina; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110, USA

module grallina.babs.markup;

import std.regex;
import std.string;

import grallina.babs.lexan;

enum DocHandle {
    START_TAG,
    END_TAG,
    START_END_TAG,
    AMPERSAND,
    LESS_THAN,
    GREATER_THAN,
    IMPL_CDATA,
    EXPL_CDATA,
}

enum TagHandle {
    NAME,
    EQUALS,
    VALUE,
    WHITESPACE,
}

static auto document_literals = [
    LiteralLexeme!DocHandle(DocHandle.AMPERSAND, "&amp;"),
    LiteralLexeme!DocHandle(DocHandle.LESS_THAN, "&lt;"),
    LiteralLexeme!DocHandle(DocHandle.GREATER_THAN, "&gt;")
];

static auto tag_literals = [
    LiteralLexeme!TagHandle(TagHandle.EQUALS, "=")
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
    enum AnythingButLtGt = `(?:(?:[^!<>'"/][^<>'"/]*)|(?:` ~ QString!() ~ ")*)";
}

// TODO: convert to ctRegex when it stops crashing all the time
alias EtRegexLexeme REL;
static RegexLexeme!(DocHandle, Regex!char)[] document_res;
static Regex!(char)[] document_skips;
static RegexLexeme!(TagHandle, Regex!char)[] tag_res;
static Regex!(char)[] tag_skips;
static this() {
    document_res = [
        REL!(DocHandle, DocHandle.START_TAG, "<" ~ AnythingButLtGt!() ~ "*>"),
        REL!(DocHandle, DocHandle.END_TAG, "</(" ~ XMLName!() ~ ")>"),
        REL!(DocHandle, DocHandle.START_END_TAG, "<" ~ AnythingButLtGt!() ~ "*/>"),
        REL!(DocHandle, DocHandle.IMPL_CDATA, "[^&<>]+"),
        REL!(DocHandle, DocHandle.EXPL_CDATA, r"<!\[CDATA\[(.|[\n\r])*?]]>"),
    ];
    document_skips = [ regex("^<!--(.|[\n\r])*?-->") ];
    tag_res = [
        REL!(TagHandle, TagHandle.NAME, XMLName!()),
        REL!(TagHandle, TagHandle.VALUE, QString!()),
        REL!(TagHandle, TagHandle.WHITESPACE, r"\s*"),
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

private static LexicalAnalyser!(DocHandle, Regex!char) document_lexan;
private static LexicalAnalyser!(TagHandle, Regex!char) tag_lexan;

static this () {
    document_lexan = new LexicalAnalyser!(DocHandle, Regex!char)(document_literals, document_res, document_skips);
    tag_lexan = new LexicalAnalyser!(TagHandle, Regex!char)(tag_literals, tag_res, tag_skips);
}

class MarkupException: Exception {
    CharLocation location;

    this(string message, CharLocation location, string file=__FILE__, size_t line=__LINE__, Throwable next=null)
    {
        this.location = location;
        super(format("%s: at: %s", message, location), file, line, next);
    }
}

struct NamedValue {
    string name;
    string value;
}

private ref CharLocation combine(ref CharLocation locn1, in CharLocation locn2)
{
    if (locn2.line_number > 1) {
        locn1.line_number += locn2.line_number - 1;
        locn1.offset = locn2.offset;
    } else {
        locn1.offset += locn2.offset + 1; // allow for "<"
    }
    locn1.index += locn2.index + 1;
    return locn1;
}

struct Tag {
    string name;
    NamedValue[] attributes;

    this(string text, CharLocation start_location) {
        auto tokens = tag_lexan.input_token_range(text);
        if (tokens.empty) throw new MarkupException("Empty tag", start_location);
        auto first = tokens.front;
        if (first.is_valid_match && first.handle == TagHandle.NAME) {
            name = first.matched_text;
        } else {
            throw new MarkupException("Invalid tag name: " ~ first.matched_text, combine(start_location, first.location));
        }
        tokens.popFront();
        auto expected_handle = TagHandle.WHITESPACE;
        string attr_name;
        with (TagHandle) foreach (token; tokens) {
            with (token) if (handle == expected_handle) {
                final switch (handle) {
                case NAME:
                    attr_name = matched_text;
                    expected_handle = EQUALS;
                    break;
                case EQUALS:
                    expected_handle = VALUE;
                    break;
                case VALUE:
                    attributes ~= NamedValue(attr_name, matched_text);
                    expected_handle = WHITESPACE;
                    break;
                case WHITESPACE:
                    expected_handle = NAME;
                    break;
                }
            } else {
                throw new MarkupException(format("Expected %s got %s: %s", expected_handle, handle, matched_text), combine(start_location, location));
            }
        }
        if (expected_handle != TagHandle.WHITESPACE) throw new MarkupException("Incomplete TAG", start_location);
    }
}

class MarkUp {
    protected string _extracted_text;

    this(string text) {
        string[] tag_stack;
        with (DocHandle) foreach (token; document_lexan.input_token_range(text)) {
            with (token) final switch (handle) {
            case START_TAG:
                auto tag = Tag(token.matched_text[1..$-1], location);
                handle_start_tag(tag, extracted_text.length, tag_stack, location);
                tag_stack ~= tag.name;
                break;
            case END_TAG:
                if (tag_stack.length == 0) {
                    throw new MarkupException(format("Unexpected end tag: %s", matched_text), location);
                } else if (tag_stack[$-1] != matched_text[2..$-1]) {
                    throw new MarkupException(format("Expected </%s> end tag got: %s", tag_stack[$-1], matched_text), location);
                } else {
                    tag_stack.length--;
                    handle_end_tag(matched_text[2..$-1], extracted_text.length, location);
                }
                break;
            case START_END_TAG:
                auto tag = Tag(token.matched_text[1..$-2], location);
                handle_start_tag(tag, extracted_text.length, tag_stack, location);
                handle_end_tag(tag.name, extracted_text.length, location);
                break;
            case IMPL_CDATA:
                _extracted_text ~= matched_text;
                break;
            case EXPL_CDATA:
                _extracted_text ~= matched_text[9..$-3];
                break;
            case AMPERSAND:
                _extracted_text ~= "&";
                break;
            case LESS_THAN:
                _extracted_text ~= "<";
                break;
            case GREATER_THAN:
                _extracted_text ~= ">";
                break;
            }
        }
    }

    abstract void handle_start_tag(in Tag tag, size_t et_index, in string[] context, in CharLocation location);
    abstract void handle_end_tag(string tag_name, size_t et_index, in CharLocation location);

    @property
    string extracted_text() { return _extracted_text; }
}
unittest {
    import std.stdio;
    class TestMarkUp: MarkUp {
        this(string text) { super(text); }
        override void handle_start_tag(in Tag tag, size_t et_index, in string[] context, in CharLocation location)
        {
            writefln("Tag: %s", tag.name);
            foreach (attr; tag.attributes) {
                writefln("\t%s = %s", attr.name, attr.value);
            }
        }
        override void handle_end_tag(string tag_name, size_t et_index, in CharLocation location)
        {
            writefln("EndTag: %s", tag_name);
        }
    }
    auto mu = new TestMarkUp("this is <b>bold</b> text &amp; test <c x='hj'/> <!-- a comment --> then --&gt; <![CDATA[&amp;]]>");
    writeln("Extracted text: ", mu.extracted_text);
}
