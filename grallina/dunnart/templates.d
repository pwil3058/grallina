// templates.d
//
// Copyright Peter Williams 2013 <pwil3058@bigpond.net.au>.
//
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module ddlib.templates;

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


    enum DDParseActionType { shift, reduce, accept, error };
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

    DDParseAction dd_shift(DDParserState dd_state)
    {
        return DDParseAction(DDParseActionType.shift, dd_state);
    }

    DDParseAction dd_reduce(DDProduction dd_production)
    {
        return DDParseAction(DDParseActionType.reduce, dd_production);
    }

    DDParseAction dd_error(DDToken[] expected_tokens)
    {
        auto action = DDParseAction(DDParseActionType.error);
        action.expected_tokens = expected_tokens;
        return action;
    }

    DDParseAction dd_accept()
    {
        return DDParseAction(DDParseActionType.accept, 0);
    }

    class DDSyntaxErrorData {
        DDToken unexpected_token;
        string matched_text;
        DDCharLocation location;
        DDToken[] expected_tokens;
        uint skip_count;

        this(DDToken dd_token, DDAttributes dd_attrs, DDToken[] dd_token_list)
        {
            unexpected_token = dd_token;
            matched_text = dd_attrs.dd_matched_text;
            location = dd_attrs.dd_location;
            expected_tokens = dd_token_list;
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

    struct DDTokenStream {
        DDAttributes current_token_attributes;
        DDToken current_token;
        DDTokenInputRange tokens;

        this(string text, string label="")
        {
            tokens = dd_lexical_analyser.input_token_range(text, label);
            get_next_token();
        }

        void get_next_token()
        {
            if (tokens.empty) {
                current_token = DDToken.ddEND;
                return;
            }
            auto mr = tokens.front;
            current_token_attributes.dd_location = mr.location;
            current_token_attributes.dd_matched_text = mr.matched_text;
            if (mr.is_valid_match) {
                current_token = mr.handle;
                dd_set_attribute_value(current_token_attributes, current_token, mr.matched_text);
            } else {
                current_token = DDToken.ddLEXERROR;
            }
            tokens.popFront();
        }
    }
}

mixin template DDImplementParser() {
    bool dd_parse_text(string text, string label="")
    {
        auto token_stream = DDTokenStream(text, label);
        auto parse_stack = DDParseStack();
        parse_stack.push(DDNonTerminal.ddSTART, 0);
        // Error handling data
        auto skip_count = 0;
        while (true) with (parse_stack) with (token_stream) {
            auto next_action = dd_get_next_action(current_state, current_token, attributes_stack);
            final switch (next_action.action) with (DDParseActionType) {
            case shift:
                push(current_token, next_action.next_state, current_token_attributes);
                get_next_token();
                skip_count = 0; // Reset the count of tokens skipped during error recovery
                break;
            case reduce:
                auto productionData = dd_get_production_data(next_action.production_id);
                auto attrs = pop(productionData.length);
                auto nextState = dd_get_goto_state(productionData.left_hand_side, current_state);
                push(productionData.left_hand_side, nextState);
                dd_do_semantic_action(top_attributes, next_action.production_id, attrs);
                break;
            case accept:
                return true;
            case error:
                auto error_data = new DDSyntaxErrorData(current_token, current_token_attributes, next_action.expected_tokens);
                auto distance_to_viable_state = find_viable_recovery_state(current_token);
                while (distance_to_viable_state < 0 && current_token != DDToken.ddEND) {
                    get_next_token();
                    skip_count++;
                    distance_to_viable_state = find_viable_recovery_state(current_token);
                }
                error_data.skip_count = skip_count;
                if (distance_to_viable_state >= 0) {
                    pop(distance_to_viable_state);
                    auto nextState = dd_get_goto_state(DDNonTerminal.ddERROR, current_state);
                    push(DDNonTerminal.ddERROR, nextState, error_data);
                } else {
                    stderr.writeln(error_data);
                    return false;
                }
            }
        }
    }
}
