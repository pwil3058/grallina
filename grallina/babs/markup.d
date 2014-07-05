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
}

static auto start_tag_literals = [
    LiteralLexeme!Handle(Handle.EQUALS, "=")
];

template XMLName() {
    enum XMLName = "[_a-zA-Z][-_a-zA-z0-9.]*";
}

template AnythingButLtGt() {
    enum AnythingButLtGt = `(?:(?:[^><'"]+)|(?:(?:'[^']*')|(?:"[^"]*"))+)`;
}

// TODO: convert to ctRegex when it stops crashing all the time
alias EtRegexLexeme REL;
static RegexLexeme!(Handle, Regex!char)[] document_res;
static this() {
    document_res = [
        REL!(Handle, Handle.START_TAG, "<" ~ AnythingButLtGt!() ~ "*[^>/]>"),
        REL!(Handle, Handle.END_TAG, "</" ~ XMLName!() ~ ">"),
        REL!(Handle, Handle.START_END_TAG, "<" ~ AnythingButLtGt!() ~ "*/>"),
    ];
}
unittest {
    assert(!match(r"<>", document_res[0].re));
    assert(!match(r"<<a>", document_res[0].re));
    assert(match(r"<a>>", document_res[0].re).hit == r"<a>");
    assert(!match(r"<a/>", document_res[0].re));
    assert(match(r"<a '>' >", document_res[0].re).hit == "<a '>' >");
    assert(match(r"</a>>>>>", document_res[1].re).hit == r"</a>");
    assert(match(r"</_a-8.a>>>>>", document_res[1].re).hit == r"</_a-8.a>");
    assert(!match(r"<</a>", document_res[1].re));
    assert(!match(r"</>", document_res[1].re));
    assert(!match(r"<a/>", document_res[1].re));
    assert(match(r"</>>>>", document_res[2].re).hit == "</>");
    assert(match(r"<a/>>>>", document_res[2].re).hit == r"<a/>");
    assert(match(r"<a '>' />>>>", document_res[2].re).hit == r"<a '>' />");
}
