// i18ndummy.d
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

module grallina.babs.i18ndummy;

/**
 * Provide an interface for tagging/collecting localizable strings.
 *
 * Reference: D Cookbook, Adam D. Ruppe, ISBN 978-1-78328-721-5, pp 148-150.
 */

// Private type to wrap strings that have been tagged for i18n.
// This is needed to let the compiler that the translation can't be
// done at compile and makes us use the tags accordingly.
bool decorate;
private struct StringWrapper {
    private string __value;
    @property
    string value()
    {
        if (decorate) {
            return "i18n(" ~ __value ~ ")";
        } else {
            return __value;
        }
    }
    alias value this;
}

/// Tag a string for i18n/l8n.
template T(string key, string file=__FILE__, size_t line=__LINE__) {
    version(gettext) {
        import std.conv;
        pragma(msg, "#: " ~ file ~ ":" ~ to!string(line));
        pragma(msg, "msgid \"" ~ key ~ "\"");
        pragma(msg, "msgstr \"\"");
        pragma(msg, "");
    }

    enum T = StringWrapper(key);
}
unittest {
    import std.stdio;
    auto t = "a test string";
    auto tt = T!"a test string";
    assert(t == tt);
}
