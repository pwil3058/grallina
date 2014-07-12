// bootstrap.d
//
// Copyright Peter Williams 2013 <pwil3058@bigpond.net.au>.
//
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import ddlib.templates;

mixin DDParserSupport;

alias ushort DDSymbol;

enum DDToken : DDSymbol {
    ddEND = 1,
    ddLEXERROR = 2,
    REGEX = 4,
    LITERAL = 5,
    TOKEN = 6,
    FIELD = 7,
    LEFT = 8,
    RIGHT = 9,
    NONASSOC = 10,
    PRECEDENCE = 11,
    SKIP = 12,
    ERROR = 13,
    LEXERROR = 14,
    NEWSECTION = 15,
    COLON = 16,
    VBAR = 17,
    DOT = 18,
    IDENT = 19,
    FIELDNAME = 20,
    PREDICATE = 21,
    ACTION = 22,
    DCODE = 23,
}

string dd_literal_token_string(DDToken dd_token)
{
    with (DDToken) switch (dd_token) {
    case TOKEN: return "%token"; break;
    case FIELD: return "%field"; break;
    case LEFT: return "%left"; break;
    case RIGHT: return "%right"; break;
    case NONASSOC: return "%nonassoc"; break;
    case PRECEDENCE: return "%prec"; break;
    case SKIP: return "%skip"; break;
    case ERROR: return "%error"; break;
    case LEXERROR: return "%lexerror"; break;
    case NEWSECTION: return "%%"; break;
    case COLON: return ":"; break;
    case VBAR: return "|"; break;
    case DOT: return "."; break;
    default:
    }
    return null;
}

enum DDNonTerminal : DDSymbol {
    ddSTART = 0,
    ddERROR = 3,
    specification = 24,
    preamble = 25,
    definitions = 26,
    production_rules = 27,
    coda = 28,
    field_definitions = 29,
    token_definitions = 30,
    skip_definitions = 31,
    precedence_definitions = 32,
    field_definition = 33,
    field_type = 34,
    field_name = 35,
    field_conversion_function = 36,
    token_definition = 37,
    new_token_name = 38,
    pattern = 39,
    skip_definition = 40,
    precedence_definition = 41,
    tag_list = 42,
    tag = 43,
    production_group = 44,
    production_group_head = 45,
    production_tail_list = 46,
    production_tail = 47,
    action = 48,
    predicate = 49,
    symbol_list = 50,
    tagged_precedence = 51,
    symbol = 52,
}

static DDLexicalAnalyser dd_lexical_analyser;
static this() {

    static auto dd_lit_lexemes = [
        DDLiteralLexeme(DDToken.TOKEN, "%token"),
        DDLiteralLexeme(DDToken.FIELD, "%field"),
        DDLiteralLexeme(DDToken.LEFT, "%left"),
        DDLiteralLexeme(DDToken.RIGHT, "%right"),
        DDLiteralLexeme(DDToken.NONASSOC, "%nonassoc"),
        DDLiteralLexeme(DDToken.PRECEDENCE, "%prec"),
        DDLiteralLexeme(DDToken.SKIP, "%skip"),
        DDLiteralLexeme(DDToken.ERROR, "%error"),
        DDLiteralLexeme(DDToken.LEXERROR, "%lexerror"),
        DDLiteralLexeme(DDToken.NEWSECTION, "%%"),
        DDLiteralLexeme(DDToken.COLON, ":"),
        DDLiteralLexeme(DDToken.VBAR, "|"),
        DDLiteralLexeme(DDToken.DOT, "."),
    ];

    static auto dd_regex_lexemes = [
        DDRegexLexeme!(DDToken.REGEX, `(\(.+\)(?=\s))`),
        DDRegexLexeme!(DDToken.LITERAL, `("\S+")`),
        DDRegexLexeme!(DDToken.IDENT, `([a-zA-Z]+[a-zA-Z0-9_]*)`),
        DDRegexLexeme!(DDToken.FIELDNAME, `(<[a-zA-Z]+[a-zA-Z0-9_]*>)`),
        DDRegexLexeme!(DDToken.PREDICATE, `(\?\((.|[\n\r])*?\?\))`),
        DDRegexLexeme!(DDToken.ACTION, `(!\{(.|[\n\r])*?!\})`),
        DDRegexLexeme!(DDToken.DCODE, `(%\{(.|[\n\r])*?%\})`),
    ];

    static auto dd_skip_rules = [
        regex(`^(/\*(.|[\n\r])*?\*/)`),
        regex(`^(//[^\n\r]*)`),
        regex(`^(\s+)`),
    ];

    dd_lexical_analyser = new DDLexicalAnalyser(dd_lit_lexemes, dd_regex_lexemes, dd_skip_rules);
}

alias uint DDProduction;
DDProductionData dd_get_production_data(DDProduction dd_production)
{
    with (DDNonTerminal) switch(dd_production) {
    case 0: return DDProductionData(ddSTART, 1);
    case 1: return DDProductionData(specification, 5);
    case 2: return DDProductionData(preamble, 0);
    case 3: return DDProductionData(preamble, 1);
    case 4: return DDProductionData(preamble, 2);
    case 5: return DDProductionData(coda, 0);
    case 6: return DDProductionData(coda, 1);
    case 7: return DDProductionData(definitions, 4);
    case 8: return DDProductionData(field_definitions, 0);
    case 9: return DDProductionData(field_definitions, 2);
    case 10: return DDProductionData(field_definition, 3);
    case 11: return DDProductionData(field_definition, 4);
    case 12: return DDProductionData(field_type, 1);
    case 13: return DDProductionData(field_type, 1);
    case 14: return DDProductionData(field_name, 1);
    case 15: return DDProductionData(field_name, 1);
    case 16: return DDProductionData(field_conversion_function, 1);
    case 17: return DDProductionData(field_conversion_function, 1);
    case 18: return DDProductionData(token_definitions, 1);
    case 19: return DDProductionData(token_definitions, 2);
    case 20: return DDProductionData(token_definition, 3);
    case 21: return DDProductionData(token_definition, 4);
    case 22: return DDProductionData(new_token_name, 1);
    case 23: return DDProductionData(new_token_name, 1);
    case 24: return DDProductionData(pattern, 1);
    case 25: return DDProductionData(pattern, 1);
    case 26: return DDProductionData(skip_definitions, 0);
    case 27: return DDProductionData(skip_definitions, 2);
    case 28: return DDProductionData(skip_definition, 2);
    case 29: return DDProductionData(precedence_definitions, 0);
    case 30: return DDProductionData(precedence_definitions, 2);
    case 31: return DDProductionData(precedence_definition, 2);
    case 32: return DDProductionData(precedence_definition, 2);
    case 33: return DDProductionData(precedence_definition, 2);
    case 34: return DDProductionData(tag_list, 1);
    case 35: return DDProductionData(tag_list, 2);
    case 36: return DDProductionData(tag, 1);
    case 37: return DDProductionData(tag, 1);
    case 38: return DDProductionData(tag, 1);
    case 39: return DDProductionData(tag, 1);
    case 40: return DDProductionData(production_rules, 1);
    case 41: return DDProductionData(production_rules, 2);
    case 42: return DDProductionData(production_group, 3);
    case 43: return DDProductionData(production_group_head, 2);
    case 44: return DDProductionData(production_group_head, 2);
    case 45: return DDProductionData(production_group_head, 2);
    case 46: return DDProductionData(production_tail_list, 1);
    case 47: return DDProductionData(production_tail_list, 3);
    case 48: return DDProductionData(production_tail, 0);
    case 49: return DDProductionData(production_tail, 1);
    case 50: return DDProductionData(production_tail, 2);
    case 51: return DDProductionData(production_tail, 1);
    case 52: return DDProductionData(production_tail, 4);
    case 53: return DDProductionData(production_tail, 3);
    case 54: return DDProductionData(production_tail, 3);
    case 55: return DDProductionData(production_tail, 2);
    case 56: return DDProductionData(production_tail, 3);
    case 57: return DDProductionData(production_tail, 2);
    case 58: return DDProductionData(production_tail, 2);
    case 59: return DDProductionData(production_tail, 1);
    case 60: return DDProductionData(action, 1);
    case 61: return DDProductionData(predicate, 1);
    case 62: return DDProductionData(tagged_precedence, 2);
    case 63: return DDProductionData(tagged_precedence, 2);
    case 64: return DDProductionData(symbol_list, 1);
    case 65: return DDProductionData(symbol_list, 2);
    case 66: return DDProductionData(symbol, 1);
    case 67: return DDProductionData(symbol, 1);
    case 68: return DDProductionData(symbol, 1);
    case 69: return DDProductionData(symbol, 1);
    default:
        throw new Exception("Malformed production data table");
    }
    assert(false);
}

struct DDAttributes {
    DDCharLocation dd_location;
    string dd_matched_text;
    union {
        DDSyntaxErrorData dd_syntax_error_data;
        Symbol symbol;
        SemanticAction semantic_action;
        ProductionTail production_tail;
        SymbolList symbol_list;
        Predicate predicate;
        AssociativePrecedence associative_precedence;
        ProductionTailList production_tail_list;
        StringList string_list;
    }

    this (ddlexan.Token!DDToken token)
    {
        dd_location = token.location;
        dd_matched_text = token.matched_text;
        if (token.is_valid_match) {
            dd_set_attribute_value(this, token.handle, token.matched_text);
        }
    }
}


void dd_set_attribute_value(ref DDAttributes attrs, DDToken dd_token, string text)
{
}

alias uint DDParserState;
DDParserState dd_get_goto_state(DDNonTerminal dd_non_terminal, DDParserState dd_current_state)
{
    with (DDNonTerminal) switch(dd_current_state) {
    case 0:
        switch (dd_non_terminal) {
        case specification: return 1;
        case preamble: return 2;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 0)", dd_non_terminal));
        }
        break;
    case 2:
        switch (dd_non_terminal) {
        case definitions: return 4;
        case field_definitions: return 5;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 2)", dd_non_terminal));
        }
        break;
    case 5:
        switch (dd_non_terminal) {
        case token_definitions: return 8;
        case field_definition: return 9;
        case token_definition: return 11;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 5)", dd_non_terminal));
        }
        break;
    case 7:
        switch (dd_non_terminal) {
        case production_rules: return 13;
        case production_group: return 14;
        case production_group_head: return 15;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 7)", dd_non_terminal));
        }
        break;
    case 8:
        switch (dd_non_terminal) {
        case skip_definitions: return 17;
        case token_definition: return 18;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 8)", dd_non_terminal));
        }
        break;
    case 10:
        switch (dd_non_terminal) {
        case field_type: return 19;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 10)", dd_non_terminal));
        }
        break;
    case 12:
        switch (dd_non_terminal) {
        case new_token_name: return 21;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 12)", dd_non_terminal));
        }
        break;
    case 13:
        switch (dd_non_terminal) {
        case coda: return 24;
        case production_group: return 26;
        case production_group_head: return 15;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 13)", dd_non_terminal));
        }
        break;
    case 15:
        switch (dd_non_terminal) {
        case production_tail_list: return 27;
        case production_tail: return 28;
        case action: return 29;
        case predicate: return 30;
        case symbol_list: return 31;
        case symbol: return 34;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 15)", dd_non_terminal));
        }
        break;
    case 17:
        switch (dd_non_terminal) {
        case precedence_definitions: return 40;
        case skip_definition: return 41;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 17)", dd_non_terminal));
        }
        break;
    case 19:
        switch (dd_non_terminal) {
        case field_name: return 43;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 19)", dd_non_terminal));
        }
        break;
    case 21:
        switch (dd_non_terminal) {
        case pattern: return 45;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 21)", dd_non_terminal));
        }
        break;
    case 22:
        switch (dd_non_terminal) {
        case new_token_name: return 48;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 22)", dd_non_terminal));
        }
        break;
    case 30:
        switch (dd_non_terminal) {
        case action: return 51;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 30)", dd_non_terminal));
        }
        break;
    case 31:
        switch (dd_non_terminal) {
        case action: return 54;
        case predicate: return 52;
        case tagged_precedence: return 53;
        case symbol: return 56;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 31)", dd_non_terminal));
        }
        break;
    case 40:
        switch (dd_non_terminal) {
        case precedence_definition: return 57;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 40)", dd_non_terminal));
        }
        break;
    case 43:
        switch (dd_non_terminal) {
        case field_conversion_function: return 62;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 43)", dd_non_terminal));
        }
        break;
    case 48:
        switch (dd_non_terminal) {
        case pattern: return 64;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 48)", dd_non_terminal));
        }
        break;
    case 50:
        switch (dd_non_terminal) {
        case production_tail: return 65;
        case action: return 29;
        case predicate: return 30;
        case symbol_list: return 31;
        case symbol: return 34;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 50)", dd_non_terminal));
        }
        break;
    case 52:
        switch (dd_non_terminal) {
        case action: return 67;
        case tagged_precedence: return 66;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 52)", dd_non_terminal));
        }
        break;
    case 53:
        switch (dd_non_terminal) {
        case action: return 68;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 53)", dd_non_terminal));
        }
        break;
    case 58:
        switch (dd_non_terminal) {
        case tag_list: return 71;
        case tag: return 72;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 58)", dd_non_terminal));
        }
        break;
    case 59:
        switch (dd_non_terminal) {
        case tag_list: return 75;
        case tag: return 72;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 59)", dd_non_terminal));
        }
        break;
    case 60:
        switch (dd_non_terminal) {
        case tag_list: return 76;
        case tag: return 72;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 60)", dd_non_terminal));
        }
        break;
    case 66:
        switch (dd_non_terminal) {
        case action: return 77;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 66)", dd_non_terminal));
        }
        break;
    case 71:
        switch (dd_non_terminal) {
        case tag: return 78;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 71)", dd_non_terminal));
        }
        break;
    case 75:
        switch (dd_non_terminal) {
        case tag: return 78;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 75)", dd_non_terminal));
        }
        break;
    case 76:
        switch (dd_non_terminal) {
        case tag: return 78;
        default:
            throw new Exception(format("Malformed goto table: no entry for (%s , 76)", dd_non_terminal));
        }
        break;
    default:
        throw new Exception(format("Malformed goto table: no entry for (%s, %s).", dd_non_terminal, dd_current_state));
    }
    throw new Exception(format("Malformed goto table: no entry for (%s, %s).", dd_non_terminal, dd_current_state));
}

bool dd_error_recovery_ok(DDParserState dd_parser_state, DDToken dd_token)
{
    with (DDToken) switch(dd_parser_state) {
    default:
    }
    return false;
}


import std.string;

import grallina.babs.lexan;
import symbols;
import grammar;

GrammarSpecification grammar_specification;

struct ProductionTail {
    Symbol[] right_hand_side;
    AssociativePrecedence associative_precedence;
    Predicate predicate;
    SemanticAction action;
}

// Aliases for use in field definitions
alias ProductionTail[] ProductionTailList;
alias Symbol[] SymbolList;
alias string[] StringList;

uint error_count;
uint warning_count;

void message(T...)(const CharLocation locn, const string tag, const string format, T args)
{
    stderr.writef("%s:%s:", locn, tag);
    stderr.writefln(format, args);
    stderr.flush();
}

void warning(T...)(const CharLocation locn, const string format, T args)
{
    message(locn, "Warning", format, args);
    warning_count++;
}

void error(T...)(const CharLocation locn, const string format, T args)
{
    message(locn, "Error", format, args);
    error_count++;
}

GrammarSpecification parse_specification_text(string text, string label="") {
    auto grammar_specification = new GrammarSpecification();

void
dd_do_semantic_action(ref DDAttributes dd_lhs, DDProduction dd_production, DDAttributes[] dd_args)
{
    switch(dd_production) {
    case 2: // preamble: <empty>
        // no preamble defined so there's nothing to do
        break;
    case 3: // preamble: DCODE
        grammar_specification.set_preamble(dd_args[1 - 1].dd_matched_text[2..$ - 2]);
        break;
    case 4: // preamble: DCODE DCODE
        grammar_specification.set_header(dd_args[1 - 1].dd_matched_text[2..$ - 2]);
        grammar_specification.set_preamble(dd_args[2 - 1].dd_matched_text[2..$ - 2]);
        break;
    case 5: // coda: <empty>
        // no coda defined so there's nothing to do
        break;
    case 6: // coda: DCODE
        grammar_specification.set_coda(dd_args[1 - 1].dd_matched_text[2..$ - 2]);
        break;
    case 8: // field_definitions: <empty>
        // do nothing
        break;
    case 10: // field_definition: "%field" field_type field_name
        if (grammar_specification.symbol_table.is_known_field(dd_args[3 - 1].dd_matched_text)) {
            auto previous = grammar_specification.symbol_table.get_field_defined_at(dd_args[3 - 1].dd_matched_text);
            error(dd_args[3 - 1].dd_location, "\"%s\" already declared at line %s.", previous.line_number);
        } else {
            grammar_specification.symbol_table.new_field(dd_args[3 - 1].dd_matched_text, dd_args[2 - 1].dd_matched_text, "", dd_args[3 - 1].dd_location);
        }
        break;
    case 11: // field_definition: "%field" field_type field_name field_conversion_function
        if (grammar_specification.symbol_table.is_known_field(dd_args[3 - 1].dd_matched_text)) {
            auto previous = grammar_specification.symbol_table.get_field_defined_at(dd_args[3 - 1].dd_matched_text);
            error(dd_args[3 - 1].dd_location, "\"%s\" already declared at line %s.", previous.line_number);
        } else {
            grammar_specification.symbol_table.new_field(dd_args[3 - 1].dd_matched_text, dd_args[2 - 1].dd_matched_text, dd_args[4 - 1].dd_matched_text, dd_args[3 - 1].dd_location);
        }
        break;
    case 12: // field_type: IDENT ?(  !is_allowable_name($1.dd_matched_text)  ?)
        warning(dd_args[1 - 1].dd_location, "field type name \"%s\" may clash with generated code", dd_args[1 - 1].dd_matched_text);
        break;
    case 14: // field_name: IDENT ?(  !is_allowable_name($1.dd_matched_text)  ?)
        warning(dd_args[1 - 1].dd_location, "field name \"%s\" may clash with generated code", dd_args[1 - 1].dd_matched_text);
        break;
    case 16: // field_conversion_function: IDENT ?(  !is_allowable_name($1.dd_matched_text)  ?)
        warning(dd_args[1 - 1].dd_location, "field conversion function name \"%s\" may clash with generated code", dd_args[1 - 1].dd_matched_text);
        break;
    case 20: // token_definition: "%token" new_token_name pattern
        if (grammar_specification.symbol_table.is_known_symbol(dd_args[2 - 1].dd_matched_text)) {
            auto previous = grammar_specification.symbol_table.get_declaration_point(dd_args[2 - 1].dd_matched_text);
            error(dd_args[2 - 1].dd_location, "\"%s\" already declared at line %s.", previous.line_number);
        } else {
            grammar_specification.symbol_table.new_token(dd_args[2 - 1].dd_matched_text, dd_args[3 - 1].dd_matched_text, dd_args[2 - 1].dd_location);
        }
        break;
    case 21: // token_definition: "%token" FIELDNAME new_token_name pattern
        auto field_name = dd_args[2 - 1].dd_matched_text[1..$ - 1];
        if (grammar_specification.symbol_table.is_known_symbol(dd_args[3 - 1].dd_matched_text)) {
            auto previous = grammar_specification.symbol_table.get_declaration_point(dd_args[3 - 1].dd_matched_text);
            error(dd_args[3 - 1].dd_location, "\"%s\" already declared at line %s.", previous.line_number);
        } else if (!grammar_specification.symbol_table.is_known_field(field_name)) {
            error(dd_args[2 - 1].dd_location, "field name \"%s\" is not known.", field_name);
            grammar_specification.symbol_table.new_token(dd_args[3 - 1].dd_matched_text, dd_args[4 - 1].dd_matched_text, dd_args[3 - 1].dd_location);
        } else {
            grammar_specification.symbol_table.new_token(dd_args[3 - 1].dd_matched_text, dd_args[4 - 1].dd_matched_text, dd_args[3 - 1].dd_location, field_name);
        }
        break;
    case 22: // new_token_name: IDENT ?(  !is_allowable_name($1.dd_matched_text)  ?)
        warning(dd_args[1 - 1].dd_location, "token name \"%s\" may clash with generated code", dd_args[1 - 1].dd_matched_text);
        break;
    case 26: // skip_definitions: <empty>
        // do nothing
        break;
    case 28: // skip_definition: "%skip" REGEX
        grammar_specification.symbol_table.add_skip_rule(dd_args[2 - 1].dd_matched_text);
        break;
    case 29: // precedence_definitions: <empty>
        // do nothing
        break;
    case 31: // precedence_definition: "%left" tag_list
        grammar_specification.symbol_table.set_precedences(Associativity.left, dd_args[2 - 1].symbol_list);
        break;
    case 32: // precedence_definition: "%right" tag_list
        grammar_specification.symbol_table.set_precedences(Associativity.right, dd_args[2 - 1].symbol_list);
        break;
    case 33: // precedence_definition: "%nonassoc" tag_list
        grammar_specification.symbol_table.set_precedences(Associativity.nonassoc, dd_args[2 - 1].symbol_list);
        break;
    case 34: // tag_list: tag
        if (dd_args[1 - 1].symbol is null) {
            dd_lhs.symbol_list = [];
        } else {
            dd_lhs.symbol_list = [dd_args[1 - 1].symbol];
        }
        break;
    case 35: // tag_list: tag_list tag
        if (dd_args[2 - 1].symbol is null) {
            dd_lhs.symbol_list = dd_args[1 - 1].symbol_list;
        } else {
            dd_lhs.symbol_list = dd_args[1 - 1].symbol_list ~ dd_args[2 - 1].symbol;
        }
        break;
    case 36: // tag: LITERAL
        dd_lhs.symbol = grammar_specification.symbol_table.get_literal_token(dd_args[1 - 1].dd_matched_text, dd_args[1 - 1].dd_location);
        if (dd_lhs.symbol is null) {
            error(dd_args[1 - 1].dd_location, "Literal \"%s\" is not known.", dd_args[1 - 1].dd_matched_text);
        }
        break;
    case 37: // tag: IDENT ?(  grammar_specification.symbol_table.is_known_token($1.dd_matched_text)  ?)
        dd_lhs.symbol = grammar_specification.symbol_table.get_symbol(dd_args[1 - 1].dd_matched_text, dd_args[1 - 1].dd_location);
        break;
    case 38: // tag: IDENT ?(  grammar_specification.symbol_table.is_known_non_terminal($1.dd_matched_text)  ?)
        dd_lhs.symbol = null;
        error(dd_args[1 - 1].dd_location, "Non terminal \"%s\" cannot be used as precedence tag.", dd_args[1 - 1].dd_matched_text);
        break;
    case 39: // tag: IDENT
        dd_lhs.symbol = grammar_specification.symbol_table.new_tag(dd_args[1 - 1].dd_matched_text, dd_args[1 - 1].dd_location);
        break;
    case 42: // production_group: production_group_head production_tail_list "."
        foreach (production_tail; dd_args[2 - 1].production_tail_list) {
            grammar_specification.new_production(dd_args[1 - 1].symbol, production_tail.right_hand_side, production_tail.predicate, production_tail.action, production_tail.associative_precedence);
        }
        break;
    case 43: // production_group_head: IDENT ":" ?(  grammar_specification.symbol_table.is_known_token($1.dd_matched_text)  ?)
        auto lineNo = grammar_specification.symbol_table.get_declaration_point(dd_args[1 - 1].dd_matched_text).line_number;
        error(dd_args[1 - 1].dd_location, "%s: token (defined at line %s) cannot be used as left hand side", dd_args[1 - 1].dd_matched_text, lineNo);
        dd_lhs.symbol = grammar_specification.symbol_table.get_symbol(dd_args[1 - 1].dd_matched_text, dd_args[1 - 1].dd_location);
        break;
    case 44: // production_group_head: IDENT ":" ?(  grammar_specification.symbol_table.is_known_tag($1.dd_matched_text)  ?)
        auto lineNo = grammar_specification.symbol_table.get_declaration_point(dd_args[1 - 1].dd_matched_text).line_number;
        error(dd_args[1 - 1].dd_location, "%s: precedence tag (defined at line %s) cannot be used as left hand side", dd_args[1 - 1].dd_matched_text, lineNo);
        dd_lhs.symbol = grammar_specification.symbol_table.get_symbol(dd_args[1 - 1].dd_matched_text, dd_args[1 - 1].dd_location);
        break;
    case 45: // production_group_head: IDENT ":"
        if (!is_allowable_name(dd_args[1 - 1].dd_matched_text)) {
            warning(dd_args[1 - 1].dd_location, "non terminal symbol name \"%s\" may clash with generated code", dd_args[1 - 1].dd_matched_text);
        }
        dd_lhs.symbol = grammar_specification.symbol_table.define_non_terminal(dd_args[1 - 1].dd_matched_text, dd_args[1 - 1].dd_location);
        break;
    case 46: // production_tail_list: production_tail
        dd_lhs.production_tail_list = [dd_args[1 - 1].production_tail];
        break;
    case 47: // production_tail_list: production_tail_list "|" production_tail
        dd_lhs.production_tail_list = dd_args[1 - 1].production_tail_list ~ dd_args[3 - 1].production_tail;
        break;
    case 48: // production_tail: <empty>
        dd_lhs.production_tail = ProductionTail([], AssociativePrecedence(), null, null);
        break;
    case 49: // production_tail: action
        dd_lhs.production_tail = ProductionTail([], AssociativePrecedence(), null, dd_args[1 - 1].semantic_action);
        break;
    case 50: // production_tail: predicate action
        dd_lhs.production_tail = ProductionTail([], AssociativePrecedence(), dd_args[1 - 1].predicate, dd_args[2 - 1].semantic_action);
        break;
    case 51: // production_tail: predicate
        dd_lhs.production_tail = ProductionTail([], AssociativePrecedence(), dd_args[1 - 1].predicate, null);
        break;
    case 52: // production_tail: symbol_list predicate tagged_precedence action
        dd_lhs.production_tail = ProductionTail(dd_args[1 - 1].symbol_list, dd_args[3 - 1].associative_precedence, dd_args[2 - 1].predicate, dd_args[4 - 1].semantic_action);
        break;
    case 53: // production_tail: symbol_list predicate tagged_precedence
        dd_lhs.production_tail = ProductionTail(dd_args[1 - 1].symbol_list, dd_args[3 - 1].associative_precedence, dd_args[2 - 1].predicate, null);
        break;
    case 54: // production_tail: symbol_list predicate action
        dd_lhs.production_tail = ProductionTail(dd_args[1 - 1].symbol_list, AssociativePrecedence(), dd_args[2 - 1].predicate, dd_args[3 - 1].semantic_action);
        break;
    case 55: // production_tail: symbol_list predicate
        dd_lhs.production_tail = ProductionTail(dd_args[1 - 1].symbol_list, AssociativePrecedence(), dd_args[2 - 1].predicate, null);
        break;
    case 56: // production_tail: symbol_list tagged_precedence action
        dd_lhs.production_tail = ProductionTail(dd_args[1 - 1].symbol_list, dd_args[2 - 1].associative_precedence, null, dd_args[3 - 1].semantic_action);
        break;
    case 57: // production_tail: symbol_list tagged_precedence
        dd_lhs.production_tail = ProductionTail(dd_args[1 - 1].symbol_list, dd_args[2 - 1].associative_precedence);
        break;
    case 58: // production_tail: symbol_list action
        dd_lhs.production_tail = ProductionTail(dd_args[1 - 1].symbol_list, AssociativePrecedence(), null, dd_args[2 - 1].semantic_action);
        break;
    case 59: // production_tail: symbol_list
        dd_lhs.production_tail = ProductionTail(dd_args[1 - 1].symbol_list);
        break;
    case 60: // action: ACTION
        dd_lhs.semantic_action = dd_args[1 - 1].dd_matched_text[2..$ - 2];
        break;
    case 61: // predicate: PREDICATE
        dd_lhs.predicate = dd_args[1 - 1].dd_matched_text[2..$ - 2];
        break;
    case 62: // tagged_precedence: "%prec" IDENT
        auto symbol = grammar_specification.symbol_table.get_symbol(dd_args[2 - 1].dd_matched_text, dd_args[2 - 1].dd_location, false);
        if (symbol is null) {
            error(dd_args[2 - 1].dd_location, "%s: Unknown symbol.", dd_args[2 - 1].dd_matched_text);
            dd_lhs.associative_precedence = AssociativePrecedence();
        } else if (symbol.type == SymbolType.non_terminal) {
            error(dd_args[2 - 1].dd_location, "%s: Illegal precedence tag (must be Token or Tag).", dd_args[2 - 1].dd_matched_text);
            dd_lhs.associative_precedence = AssociativePrecedence();
        } else {
            dd_lhs.associative_precedence = symbol.associative_precedence;
        }
        break;
    case 63: // tagged_precedence: "%prec" LITERAL
        auto symbol = grammar_specification.symbol_table.get_literal_token(dd_args[2 - 1].dd_matched_text, dd_args[2 - 1].dd_location);
        if (symbol is null) {
            dd_lhs.associative_precedence = AssociativePrecedence();
            error(dd_args[2 - 1].dd_location, "%s: Unknown literal token.", dd_args[2 - 1].dd_matched_text);
        } else {
            dd_lhs.associative_precedence = symbol.associative_precedence;
        }
        break;
    case 64: // symbol_list: symbol
        dd_lhs.symbol_list = [dd_args[1 - 1].symbol];
        break;
    case 65: // symbol_list: symbol_list symbol
        dd_lhs.symbol_list = dd_args[1 - 1].symbol_list ~ dd_args[2 - 1].symbol;
        break;
    case 66: // symbol: IDENT
        dd_lhs.symbol = grammar_specification.symbol_table.get_symbol(dd_args[1 - 1].dd_matched_text, dd_args[1 - 1].dd_location, true);
        break;
    case 67: // symbol: LITERAL
        dd_lhs.symbol = grammar_specification.symbol_table.get_literal_token(dd_args[1 - 1].dd_matched_text, dd_args[1 - 1].dd_location);
        if (dd_lhs.symbol is null) {
            error(dd_args[1 - 1].dd_location, "%s: unknown literal token", dd_args[1 - 1].dd_matched_text);
        }
        break;
    case 68: // symbol: "%error"
        dd_lhs.symbol = grammar_specification.symbol_table.get_special_symbol(SpecialSymbols.parse_error);
        break;
    case 69: // symbol: "%lexerror"
        dd_lhs.symbol = grammar_specification.symbol_table.get_special_symbol(SpecialSymbols.lex_error);;
        break;
    default:
        // Do nothing
    }
}

DDParseAction dd_get_next_action(DDParserState dd_current_state, DDToken dd_next_token, in DDAttributes[] dd_attribute_stack)
{
    with (DDToken) switch(dd_current_state) {
    case 0:
        switch (dd_next_token) {
        case DCODE: return dd_shift!(3);
        case TOKEN, FIELD:
            return dd_reduce!(2); // preamble: <empty>
        default:
            throw new DDSyntaxError([TOKEN, FIELD, DCODE]);
        }
        break;
    case 1:
        switch (dd_next_token) {
        case ddEND:
            return dd_accept!();
        default:
            throw new DDSyntaxError([ddEND]);
        }
        break;
    case 2:
        switch (dd_next_token) {
        case TOKEN, FIELD:
            return dd_reduce!(8); // field_definitions: <empty>
        default:
            throw new DDSyntaxError([TOKEN, FIELD]);
        }
        break;
    case 3:
        switch (dd_next_token) {
        case DCODE: return dd_shift!(6);
        case TOKEN, FIELD:
            return dd_reduce!(3); // preamble: DCODE
        default:
            throw new DDSyntaxError([TOKEN, FIELD, DCODE]);
        }
        break;
    case 4:
        switch (dd_next_token) {
        case NEWSECTION: return dd_shift!(7);
        default:
            throw new DDSyntaxError([NEWSECTION]);
        }
        break;
    case 5:
        switch (dd_next_token) {
        case TOKEN: return dd_shift!(12);
        case FIELD: return dd_shift!(10);
        default:
            throw new DDSyntaxError([TOKEN, FIELD]);
        }
        break;
    case 6:
        switch (dd_next_token) {
        case TOKEN, FIELD:
            return dd_reduce!(4); // preamble: DCODE DCODE
        default:
            throw new DDSyntaxError([TOKEN, FIELD]);
        }
        break;
    case 7:
        switch (dd_next_token) {
        case IDENT: return dd_shift!(16);
        default:
            throw new DDSyntaxError([IDENT]);
        }
        break;
    case 8:
        switch (dd_next_token) {
        case TOKEN: return dd_shift!(12);
        case LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION:
            return dd_reduce!(26); // skip_definitions: <empty>
        default:
            throw new DDSyntaxError([TOKEN, LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION]);
        }
        break;
    case 9:
        switch (dd_next_token) {
        case TOKEN, FIELD:
            return dd_reduce!(9); // field_definitions: field_definitions field_definition
        default:
            throw new DDSyntaxError([TOKEN, FIELD]);
        }
        break;
    case 10:
        switch (dd_next_token) {
        case IDENT: return dd_shift!(20);
        default:
            throw new DDSyntaxError([IDENT]);
        }
        break;
    case 11:
        switch (dd_next_token) {
        case TOKEN, LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION:
            return dd_reduce!(18); // token_definitions: token_definition
        default:
            throw new DDSyntaxError([TOKEN, LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION]);
        }
        break;
    case 12:
        switch (dd_next_token) {
        case IDENT: return dd_shift!(23);
        case FIELDNAME: return dd_shift!(22);
        default:
            throw new DDSyntaxError([IDENT, FIELDNAME]);
        }
        break;
    case 13:
        switch (dd_next_token) {
        case IDENT: return dd_shift!(16);
        case DCODE: return dd_shift!(25);
        case ddEND:
            return dd_reduce!(5); // coda: <empty>
        default:
            throw new DDSyntaxError([ddEND, IDENT, DCODE]);
        }
        break;
    case 14:
        switch (dd_next_token) {
        case ddEND, IDENT, DCODE:
            return dd_reduce!(40); // production_rules: production_group
        default:
            throw new DDSyntaxError([ddEND, IDENT, DCODE]);
        }
        break;
    case 15:
        switch (dd_next_token) {
        case LITERAL: return dd_shift!(36);
        case ERROR: return dd_shift!(37);
        case LEXERROR: return dd_shift!(38);
        case IDENT: return dd_shift!(35);
        case PREDICATE: return dd_shift!(33);
        case ACTION: return dd_shift!(32);
        case VBAR, DOT:
            return dd_reduce!(48); // production_tail: <empty>
        default:
            throw new DDSyntaxError([LITERAL, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION]);
        }
        break;
    case 16:
        switch (dd_next_token) {
        case COLON: return dd_shift!(39);
        default:
            throw new DDSyntaxError([COLON]);
        }
        break;
    case 17:
        switch (dd_next_token) {
        case SKIP: return dd_shift!(42);
        case LEFT, RIGHT, NONASSOC, NEWSECTION:
            return dd_reduce!(29); // precedence_definitions: <empty>
        default:
            throw new DDSyntaxError([LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION]);
        }
        break;
    case 18:
        switch (dd_next_token) {
        case TOKEN, LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION:
            return dd_reduce!(19); // token_definitions: token_definitions token_definition
        default:
            throw new DDSyntaxError([TOKEN, LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION]);
        }
        break;
    case 19:
        switch (dd_next_token) {
        case IDENT: return dd_shift!(44);
        default:
            throw new DDSyntaxError([IDENT]);
        }
        break;
    case 20:
        switch (dd_next_token) {
        case IDENT:
            if ( !is_allowable_name(dd_attribute_stack[$ - 2 + 1].dd_matched_text) ) {
                return dd_reduce!(12); // field_type: IDENT ?(  !is_allowable_name($1.dd_matched_text)  ?)
            } else {
                return dd_reduce!(13); // field_type: IDENT
            }
        default:
            throw new DDSyntaxError([IDENT]);
        }
        break;
    case 21:
        switch (dd_next_token) {
        case REGEX: return dd_shift!(46);
        case LITERAL: return dd_shift!(47);
        default:
            throw new DDSyntaxError([REGEX, LITERAL]);
        }
        break;
    case 22:
        switch (dd_next_token) {
        case IDENT: return dd_shift!(23);
        default:
            throw new DDSyntaxError([IDENT]);
        }
        break;
    case 23:
        switch (dd_next_token) {
        case REGEX, LITERAL:
            if ( !is_allowable_name(dd_attribute_stack[$ - 2 + 1].dd_matched_text) ) {
                return dd_reduce!(22); // new_token_name: IDENT ?(  !is_allowable_name($1.dd_matched_text)  ?)
            } else {
                return dd_reduce!(23); // new_token_name: IDENT
            }
        default:
            throw new DDSyntaxError([REGEX, LITERAL]);
        }
        break;
    case 24:
        switch (dd_next_token) {
        case ddEND:
            return dd_reduce!(1); // specification: preamble definitions "%%" production_rules coda
        default:
            throw new DDSyntaxError([ddEND]);
        }
        break;
    case 25:
        switch (dd_next_token) {
        case ddEND:
            return dd_reduce!(6); // coda: DCODE
        default:
            throw new DDSyntaxError([ddEND]);
        }
        break;
    case 26:
        switch (dd_next_token) {
        case ddEND, IDENT, DCODE:
            return dd_reduce!(41); // production_rules: production_rules production_group
        default:
            throw new DDSyntaxError([ddEND, IDENT, DCODE]);
        }
        break;
    case 27:
        switch (dd_next_token) {
        case VBAR: return dd_shift!(50);
        case DOT: return dd_shift!(49);
        default:
            throw new DDSyntaxError([VBAR, DOT]);
        }
        break;
    case 28:
        switch (dd_next_token) {
        case VBAR, DOT:
            return dd_reduce!(46); // production_tail_list: production_tail
        default:
            throw new DDSyntaxError([VBAR, DOT]);
        }
        break;
    case 29:
        switch (dd_next_token) {
        case VBAR, DOT:
            return dd_reduce!(49); // production_tail: action
        default:
            throw new DDSyntaxError([VBAR, DOT]);
        }
        break;
    case 30:
        switch (dd_next_token) {
        case ACTION: return dd_shift!(32);
        case VBAR, DOT:
            return dd_reduce!(51); // production_tail: predicate
        default:
            throw new DDSyntaxError([VBAR, DOT, ACTION]);
        }
        break;
    case 31:
        switch (dd_next_token) {
        case LITERAL: return dd_shift!(36);
        case PRECEDENCE: return dd_shift!(55);
        case ERROR: return dd_shift!(37);
        case LEXERROR: return dd_shift!(38);
        case IDENT: return dd_shift!(35);
        case PREDICATE: return dd_shift!(33);
        case ACTION: return dd_shift!(32);
        case VBAR, DOT:
            return dd_reduce!(59); // production_tail: symbol_list
        default:
            throw new DDSyntaxError([LITERAL, PRECEDENCE, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION]);
        }
        break;
    case 32:
        switch (dd_next_token) {
        case VBAR, DOT:
            return dd_reduce!(60); // action: ACTION
        default:
            throw new DDSyntaxError([VBAR, DOT]);
        }
        break;
    case 33:
        switch (dd_next_token) {
        case PRECEDENCE, VBAR, DOT, ACTION:
            return dd_reduce!(61); // predicate: PREDICATE
        default:
            throw new DDSyntaxError([PRECEDENCE, VBAR, DOT, ACTION]);
        }
        break;
    case 34:
        switch (dd_next_token) {
        case LITERAL, PRECEDENCE, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION:
            return dd_reduce!(64); // symbol_list: symbol
        default:
            throw new DDSyntaxError([LITERAL, PRECEDENCE, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION]);
        }
        break;
    case 35:
        switch (dd_next_token) {
        case LITERAL, PRECEDENCE, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION:
            return dd_reduce!(66); // symbol: IDENT
        default:
            throw new DDSyntaxError([LITERAL, PRECEDENCE, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION]);
        }
        break;
    case 36:
        switch (dd_next_token) {
        case LITERAL, PRECEDENCE, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION:
            return dd_reduce!(67); // symbol: LITERAL
        default:
            throw new DDSyntaxError([LITERAL, PRECEDENCE, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION]);
        }
        break;
    case 37:
        switch (dd_next_token) {
        case LITERAL, PRECEDENCE, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION:
            return dd_reduce!(68); // symbol: "%error"
        default:
            throw new DDSyntaxError([LITERAL, PRECEDENCE, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION]);
        }
        break;
    case 38:
        switch (dd_next_token) {
        case LITERAL, PRECEDENCE, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION:
            return dd_reduce!(69); // symbol: "%lexerror"
        default:
            throw new DDSyntaxError([LITERAL, PRECEDENCE, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION]);
        }
        break;
    case 39:
        switch (dd_next_token) {
        case LITERAL, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION:
            if ( grammar_specification.symbol_table.is_known_token(dd_attribute_stack[$ - 3 + 1].dd_matched_text) ) {
                return dd_reduce!(43); // production_group_head: IDENT ":" ?(  grammar_specification.symbol_table.is_known_token($1.dd_matched_text)  ?)
            } else if ( grammar_specification.symbol_table.is_known_tag(dd_attribute_stack[$ - 3 + 1].dd_matched_text) ) {
                return dd_reduce!(44); // production_group_head: IDENT ":" ?(  grammar_specification.symbol_table.is_known_tag($1.dd_matched_text)  ?)
            } else {
                return dd_reduce!(45); // production_group_head: IDENT ":"
            }
        default:
            throw new DDSyntaxError([LITERAL, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION]);
        }
        break;
    case 40:
        switch (dd_next_token) {
        case LEFT: return dd_shift!(58);
        case RIGHT: return dd_shift!(59);
        case NONASSOC: return dd_shift!(60);
        case NEWSECTION:
            return dd_reduce!(7); // definitions: field_definitions token_definitions skip_definitions precedence_definitions
        default:
            throw new DDSyntaxError([LEFT, RIGHT, NONASSOC, NEWSECTION]);
        }
        break;
    case 41:
        switch (dd_next_token) {
        case LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION:
            return dd_reduce!(27); // skip_definitions: skip_definitions skip_definition
        default:
            throw new DDSyntaxError([LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION]);
        }
        break;
    case 42:
        switch (dd_next_token) {
        case REGEX: return dd_shift!(61);
        default:
            throw new DDSyntaxError([REGEX]);
        }
        break;
    case 43:
        switch (dd_next_token) {
        case IDENT: return dd_shift!(63);
        case TOKEN, FIELD:
            return dd_reduce!(10); // field_definition: "%field" field_type field_name
        default:
            throw new DDSyntaxError([TOKEN, FIELD, IDENT]);
        }
        break;
    case 44:
        switch (dd_next_token) {
        case TOKEN, FIELD, IDENT:
            if ( !is_allowable_name(dd_attribute_stack[$ - 2 + 1].dd_matched_text) ) {
                return dd_reduce!(14); // field_name: IDENT ?(  !is_allowable_name($1.dd_matched_text)  ?)
            } else {
                return dd_reduce!(15); // field_name: IDENT
            }
        default:
            throw new DDSyntaxError([TOKEN, FIELD, IDENT]);
        }
        break;
    case 45:
        switch (dd_next_token) {
        case TOKEN, LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION:
            return dd_reduce!(20); // token_definition: "%token" new_token_name pattern
        default:
            throw new DDSyntaxError([TOKEN, LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION]);
        }
        break;
    case 46:
        switch (dd_next_token) {
        case TOKEN, LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION:
            return dd_reduce!(24); // pattern: REGEX
        default:
            throw new DDSyntaxError([TOKEN, LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION]);
        }
        break;
    case 47:
        switch (dd_next_token) {
        case TOKEN, LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION:
            return dd_reduce!(25); // pattern: LITERAL
        default:
            throw new DDSyntaxError([TOKEN, LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION]);
        }
        break;
    case 48:
        switch (dd_next_token) {
        case REGEX: return dd_shift!(46);
        case LITERAL: return dd_shift!(47);
        default:
            throw new DDSyntaxError([REGEX, LITERAL]);
        }
        break;
    case 49:
        switch (dd_next_token) {
        case ddEND, IDENT, DCODE:
            return dd_reduce!(42); // production_group: production_group_head production_tail_list "."
        default:
            throw new DDSyntaxError([ddEND, IDENT, DCODE]);
        }
        break;
    case 50:
        switch (dd_next_token) {
        case LITERAL: return dd_shift!(36);
        case ERROR: return dd_shift!(37);
        case LEXERROR: return dd_shift!(38);
        case IDENT: return dd_shift!(35);
        case PREDICATE: return dd_shift!(33);
        case ACTION: return dd_shift!(32);
        case VBAR, DOT:
            return dd_reduce!(48); // production_tail: <empty>
        default:
            throw new DDSyntaxError([LITERAL, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION]);
        }
        break;
    case 51:
        switch (dd_next_token) {
        case VBAR, DOT:
            return dd_reduce!(50); // production_tail: predicate action
        default:
            throw new DDSyntaxError([VBAR, DOT]);
        }
        break;
    case 52:
        switch (dd_next_token) {
        case PRECEDENCE: return dd_shift!(55);
        case ACTION: return dd_shift!(32);
        case VBAR, DOT:
            return dd_reduce!(55); // production_tail: symbol_list predicate
        default:
            throw new DDSyntaxError([PRECEDENCE, VBAR, DOT, ACTION]);
        }
        break;
    case 53:
        switch (dd_next_token) {
        case ACTION: return dd_shift!(32);
        case VBAR, DOT:
            return dd_reduce!(57); // production_tail: symbol_list tagged_precedence
        default:
            throw new DDSyntaxError([VBAR, DOT, ACTION]);
        }
        break;
    case 54:
        switch (dd_next_token) {
        case VBAR, DOT:
            return dd_reduce!(58); // production_tail: symbol_list action
        default:
            throw new DDSyntaxError([VBAR, DOT]);
        }
        break;
    case 55:
        switch (dd_next_token) {
        case LITERAL: return dd_shift!(70);
        case IDENT: return dd_shift!(69);
        default:
            throw new DDSyntaxError([LITERAL, IDENT]);
        }
        break;
    case 56:
        switch (dd_next_token) {
        case LITERAL, PRECEDENCE, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION:
            return dd_reduce!(65); // symbol_list: symbol_list symbol
        default:
            throw new DDSyntaxError([LITERAL, PRECEDENCE, ERROR, LEXERROR, VBAR, DOT, IDENT, PREDICATE, ACTION]);
        }
        break;
    case 57:
        switch (dd_next_token) {
        case LEFT, RIGHT, NONASSOC, NEWSECTION:
            return dd_reduce!(30); // precedence_definitions: precedence_definitions precedence_definition
        default:
            throw new DDSyntaxError([LEFT, RIGHT, NONASSOC, NEWSECTION]);
        }
        break;
    case 58:
        switch (dd_next_token) {
        case LITERAL: return dd_shift!(73);
        case IDENT: return dd_shift!(74);
        default:
            throw new DDSyntaxError([LITERAL, IDENT]);
        }
        break;
    case 59:
        switch (dd_next_token) {
        case LITERAL: return dd_shift!(73);
        case IDENT: return dd_shift!(74);
        default:
            throw new DDSyntaxError([LITERAL, IDENT]);
        }
        break;
    case 60:
        switch (dd_next_token) {
        case LITERAL: return dd_shift!(73);
        case IDENT: return dd_shift!(74);
        default:
            throw new DDSyntaxError([LITERAL, IDENT]);
        }
        break;
    case 61:
        switch (dd_next_token) {
        case LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION:
            return dd_reduce!(28); // skip_definition: "%skip" REGEX
        default:
            throw new DDSyntaxError([LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION]);
        }
        break;
    case 62:
        switch (dd_next_token) {
        case TOKEN, FIELD:
            return dd_reduce!(11); // field_definition: "%field" field_type field_name field_conversion_function
        default:
            throw new DDSyntaxError([TOKEN, FIELD]);
        }
        break;
    case 63:
        switch (dd_next_token) {
        case TOKEN, FIELD:
            if ( !is_allowable_name(dd_attribute_stack[$ - 2 + 1].dd_matched_text) ) {
                return dd_reduce!(16); // field_conversion_function: IDENT ?(  !is_allowable_name($1.dd_matched_text)  ?)
            } else {
                return dd_reduce!(17); // field_conversion_function: IDENT
            }
        default:
            throw new DDSyntaxError([TOKEN, FIELD]);
        }
        break;
    case 64:
        switch (dd_next_token) {
        case TOKEN, LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION:
            return dd_reduce!(21); // token_definition: "%token" FIELDNAME new_token_name pattern
        default:
            throw new DDSyntaxError([TOKEN, LEFT, RIGHT, NONASSOC, SKIP, NEWSECTION]);
        }
        break;
    case 65:
        switch (dd_next_token) {
        case VBAR, DOT:
            return dd_reduce!(47); // production_tail_list: production_tail_list "|" production_tail
        default:
            throw new DDSyntaxError([VBAR, DOT]);
        }
        break;
    case 66:
        switch (dd_next_token) {
        case ACTION: return dd_shift!(32);
        case VBAR, DOT:
            return dd_reduce!(53); // production_tail: symbol_list predicate tagged_precedence
        default:
            throw new DDSyntaxError([VBAR, DOT, ACTION]);
        }
        break;
    case 67:
        switch (dd_next_token) {
        case VBAR, DOT:
            return dd_reduce!(54); // production_tail: symbol_list predicate action
        default:
            throw new DDSyntaxError([VBAR, DOT]);
        }
        break;
    case 68:
        switch (dd_next_token) {
        case VBAR, DOT:
            return dd_reduce!(56); // production_tail: symbol_list tagged_precedence action
        default:
            throw new DDSyntaxError([VBAR, DOT]);
        }
        break;
    case 69:
        switch (dd_next_token) {
        case VBAR, DOT, ACTION:
            return dd_reduce!(62); // tagged_precedence: "%prec" IDENT
        default:
            throw new DDSyntaxError([VBAR, DOT, ACTION]);
        }
        break;
    case 70:
        switch (dd_next_token) {
        case VBAR, DOT, ACTION:
            return dd_reduce!(63); // tagged_precedence: "%prec" LITERAL
        default:
            throw new DDSyntaxError([VBAR, DOT, ACTION]);
        }
        break;
    case 71:
        switch (dd_next_token) {
        case LITERAL: return dd_shift!(73);
        case IDENT: return dd_shift!(74);
        case LEFT, RIGHT, NONASSOC, NEWSECTION:
            return dd_reduce!(31); // precedence_definition: "%left" tag_list
        default:
            throw new DDSyntaxError([LITERAL, LEFT, RIGHT, NONASSOC, NEWSECTION, IDENT]);
        }
        break;
    case 72:
        switch (dd_next_token) {
        case LITERAL, LEFT, RIGHT, NONASSOC, NEWSECTION, IDENT:
            return dd_reduce!(34); // tag_list: tag
        default:
            throw new DDSyntaxError([LITERAL, LEFT, RIGHT, NONASSOC, NEWSECTION, IDENT]);
        }
        break;
    case 73:
        switch (dd_next_token) {
        case LITERAL, LEFT, RIGHT, NONASSOC, NEWSECTION, IDENT:
            return dd_reduce!(36); // tag: LITERAL
        default:
            throw new DDSyntaxError([LITERAL, LEFT, RIGHT, NONASSOC, NEWSECTION, IDENT]);
        }
        break;
    case 74:
        switch (dd_next_token) {
        case LITERAL, LEFT, RIGHT, NONASSOC, NEWSECTION, IDENT:
            if ( grammar_specification.symbol_table.is_known_token(dd_attribute_stack[$ - 2 + 1].dd_matched_text) ) {
                return dd_reduce!(37); // tag: IDENT ?(  grammar_specification.symbol_table.is_known_token($1.dd_matched_text)  ?)
            } else if ( grammar_specification.symbol_table.is_known_non_terminal(dd_attribute_stack[$ - 2 + 1].dd_matched_text) ) {
                return dd_reduce!(38); // tag: IDENT ?(  grammar_specification.symbol_table.is_known_non_terminal($1.dd_matched_text)  ?)
            } else {
                return dd_reduce!(39); // tag: IDENT
            }
        default:
            throw new DDSyntaxError([LITERAL, LEFT, RIGHT, NONASSOC, NEWSECTION, IDENT]);
        }
        break;
    case 75:
        switch (dd_next_token) {
        case LITERAL: return dd_shift!(73);
        case IDENT: return dd_shift!(74);
        case LEFT, RIGHT, NONASSOC, NEWSECTION:
            return dd_reduce!(32); // precedence_definition: "%right" tag_list
        default:
            throw new DDSyntaxError([LITERAL, LEFT, RIGHT, NONASSOC, NEWSECTION, IDENT]);
        }
        break;
    case 76:
        switch (dd_next_token) {
        case LITERAL: return dd_shift!(73);
        case IDENT: return dd_shift!(74);
        case LEFT, RIGHT, NONASSOC, NEWSECTION:
            return dd_reduce!(33); // precedence_definition: "%nonassoc" tag_list
        default:
            throw new DDSyntaxError([LITERAL, LEFT, RIGHT, NONASSOC, NEWSECTION, IDENT]);
        }
        break;
    case 77:
        switch (dd_next_token) {
        case VBAR, DOT:
            return dd_reduce!(52); // production_tail: symbol_list predicate tagged_precedence action
        default:
            throw new DDSyntaxError([VBAR, DOT]);
        }
        break;
    case 78:
        switch (dd_next_token) {
        case LITERAL, LEFT, RIGHT, NONASSOC, NEWSECTION, IDENT:
            return dd_reduce!(35); // tag_list: tag_list tag
        default:
            throw new DDSyntaxError([LITERAL, LEFT, RIGHT, NONASSOC, NEWSECTION, IDENT]);
        }
        break;
    default:
        throw new Exception(format("Invalid parser state: %s", dd_current_state));
    }
    assert(false);
}


mixin DDImplementParser;

    if (!dd_parse_text(text, label)) return null;
    return grammar_specification;
}
