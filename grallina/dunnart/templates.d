// templates.d
//
// Copyright Peter Williams 2013 <pwil3058@bigpond.net.au>.
//
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module grallina.dunnart.templates;

mixin template DDParserSupport() {
    import std.conv;
    import std.string;
    import std.stdio;
    import std.regex;

    import ddlexan = grallina.babs.lexan;

    alias ddlexan.LiteralLexeme!DDToken DDLiteralLexeme;
    template DDRegexLexeme(DDToken handle, string script) {
        static  if (script[0] == '^') {
            enum DDRegexLexeme = ddlexan.RegexLexeme!(DDToken, Regex!char)(handle, regex(script));
        } else {
            enum DDRegexLexeme = ddlexan.RegexLexeme!(DDToken, Regex!char)(handle, regex("^" ~ script));
        }
    }
    alias ddlexan.LexicalAnalyser!(DDToken, Regex!char) DDLexicalAnalyser;
    alias ddlexan.TokenInputRange!DDToken DDTokenInputRange;
    alias ddlexan.CharLocation DDCharLocation;


    enum DDParseActionType { shift, reduce, accept };
    struct DDParseAction {
        DDParseActionType action;
        union {
            DDProduction production_id;
            DDParserState next_state;
            DDToken[] expected_tokens;
        }
    }

    struct DDProductionData {
        DDNonTerminal left_hand_side;
        size_t length;
    }

    template dd_shift(DDParserState dd_state) {
        enum dd_shift = DDParseAction(DDParseActionType.shift, dd_state);
    }

    template dd_reduce(DDProduction dd_production) {
        enum dd_reduce = DDParseAction(DDParseActionType.reduce, dd_production);
    }

    template dd_accept() {
        enum dd_accept = DDParseAction(DDParseActionType.accept, 0);
    }

    class DDSyntaxError: Exception {
        DDToken[] expected_tokens;

        this(DDToken[] expected_tokens, string file=__FILE__, size_t line=__LINE__, Throwable next=null)
        {
            this.expected_tokens = expected_tokens;
            string msg = format("Syntax Error: expected  %s.", expected_tokens);
            super(msg, file, line, next);
        }
    }

    class DDSyntaxErrorData {
        DDToken unexpected_token;
        string matched_text;
        DDCharLocation location;
        DDToken[] expected_tokens;
        long skipped_count;

        this(DDToken dd_token, DDAttributes dd_attrs, DDToken[] dd_token_list)
        {
            unexpected_token = dd_token;
            matched_text = dd_attrs.dd_matched_text;
            location = dd_attrs.dd_location;
            expected_tokens = dd_token_list;
            skipped_count = -1;
        }

        override string toString()
        {
            string str;
            if (unexpected_token == DDToken.ddLEXERROR) {
                str = format("%s: Unexpected input: %s", location, matched_text);
            } else {
                str = format("%s: Syntax Error: ", location.line_number);
                if (unexpected_token == DDToken.ddEND) {
                    str ~= "unexpected end of input: ";
                } else {
                    auto literal = dd_literal_token_string(unexpected_token);
                    if (literal is null) {
                        str ~= format("found %s (\"%s\"): ", unexpected_token, matched_text);
                    } else {
                        str ~= format("found \"%s\": ", literal);
                    }
                }
                str ~= format("expected %s.", expected_tokens_as_string());
            }
            return str;
        }

        string expected_tokens_as_string()
        {
            auto str = dd_literal_token_string(expected_tokens[0]);
            if (str is null) {
                str = to!(string)(expected_tokens[0]);
            } else {
                str = format("\"%s\"", str);
            }
            for (auto i = 1; i < expected_tokens.length - 1; i++) {
                auto literal = dd_literal_token_string(expected_tokens[i]);
                if (literal is null) {
                    str ~= format(", %s", to!(string)(expected_tokens[i]));
                } else {
                    str ~= format(", \"%s\"", literal);
                }
            }
            if (expected_tokens.length > 1) {
                auto literal = dd_literal_token_string(expected_tokens[$ - 1]);
                if (literal is null) {
                    str ~= format(" or %s", to!(string)(expected_tokens[$ - 1]));
                } else {
                    str ~= format(" or \"%s\"", literal);
                }
            }
            return str;
        }
    }
}

mixin template DDImplementParser() {
    struct DDParseStack {
        struct StackElement {
            DDSymbol symbol_id;
            DDParserState state;
        }
        static const STACK_LENGTH_INCR = 100;
        StackElement[] state_stack;
        DDAttributes[] attr_stack;
        size_t height;
        DDParserState last_error_state;

        invariant() {
            assert(state_stack.length == attr_stack.length);
            assert(height <= state_stack.length);
        }

        private @property
        size_t index()
        {
            return height - 1;
        }

        private @property
        DDParserState current_state()
        {
            return state_stack[index].state;
        }

        private @property
        DDSymbol top_symbol()
        {
            return state_stack[index].symbol_id;
        }

        private @property
        ref DDAttributes top_attributes()
        {
            return attr_stack[index];
        }

        private @property
        DDAttributes[] attributes_stack()
        {
            return attr_stack[0..height];
        }

        private
        void push(DDSymbol symbol_id, DDParserState state)
        {
            height += 1;
            if (height >= state_stack.length) {
                state_stack ~= new StackElement[STACK_LENGTH_INCR];
                attr_stack ~= new DDAttributes[STACK_LENGTH_INCR];
            }
            state_stack[index] = StackElement(symbol_id, state);
        }

        private
        void push(DDToken dd_token, DDParserState state, DDAttributes attrs)
        {
            push(dd_token, state);
            attr_stack[index] = attrs;
            last_error_state = 0; // Reset the last error state on shift
        }

        private
        void push(DDSymbol symbol_id, DDParserState state, DDSyntaxErrorData error_data)
        {
            push(symbol_id, state);
            attr_stack[index].dd_syntax_error_data = error_data;
        }

        private
        DDAttributes[] pop(size_t count)
        {
            if (count == 0) return [];
            height -= count;
            return attr_stack[height..height + count].dup;
        }

        private
        void do_reduce(DDProduction production_id)
        {
            auto productionData = dd_get_production_data(production_id);
            auto attrs = pop(productionData.length);
            auto nextState = dd_get_goto_state(productionData.left_hand_side, current_state);
            push(productionData.left_hand_side, nextState);
            dd_do_semantic_action(top_attributes, production_id, attrs);
        }

        private
        int find_viable_recovery_state(DDToken current_token)
        {
            int distance_to_viable_state = 0;
            while (distance_to_viable_state < height) {
                auto candidate_state = state_stack[index - distance_to_viable_state].state;
                if (candidate_state != last_error_state && dd_error_recovery_ok(candidate_state, current_token)) {
                    last_error_state = candidate_state;
                    return distance_to_viable_state;
                }
                distance_to_viable_state++;
            }
            return -1; /// Failure
        }
    }

    bool dd_parse_text(string text, string label="")
    {
        auto tokens = dd_lexical_analyser.input_token_range(text, label, DDToken.ddEND);
        auto parse_stack = DDParseStack();
        parse_stack.push(DDNonTerminal.ddSTART, 0);
        DDToken dd_token;
        DDParseAction next_action;
        DDSyntaxErrorData error_data;
        with (parse_stack) with (DDParseActionType) foreach (token; tokens) {
            dd_token = token.handle;
        try_again:
            if (error_data) {
                if (dd_token == DDToken.ddEND) break;
                error_data.skipped_count++;
                auto distance_to_viable_state = find_viable_recovery_state(dd_token);
                if (distance_to_viable_state == 0) continue; // get the next token and try again
                pop(distance_to_viable_state);
                auto nextState = dd_get_goto_state(DDNonTerminal.ddERROR, current_state);
                push(DDNonTerminal.ddERROR, nextState, error_data);
                error_data = null;
            }
            try {
                next_action = dd_get_next_action(current_state, dd_token, attributes_stack);
                while (next_action.action == reduce) {
                    do_reduce(next_action.production_id);
                    next_action = dd_get_next_action(current_state, dd_token, attributes_stack);
                }
                if (next_action.action == shift) {
                    push(dd_token, next_action.next_state, DDAttributes(token));
                } else if (next_action.action == accept) {
                    return true;
                }
            } catch (ddlexan.LexanInvalidToken edata) {
                dd_token = DDToken.ddLEXERROR;
                goto try_again;
            } catch (DDSyntaxError edata) {
                assert(error_data is null);
                error_data = new DDSyntaxErrorData(dd_token, DDAttributes(token), edata.expected_tokens);
                goto try_again;
            }
        }
        if (error_data) {
            stderr.writeln(error_data);
        } else {
            stderr.writeln("Unexpected end of input.");
        }
        return false;
    }
}
