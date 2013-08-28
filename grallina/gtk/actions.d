// This program is free software; you can redistribute it and/or modify
// it under the terms of version 3 of the GNU Lesser General Public
// License as published by the Free Software Foundation.
//
// This code is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
// MA 02110-1301, USA.

module grallina.gtk.actions;

import std.string;

import gtk.TreeSelection;
import gtk.ActionGroup;
import gtk.UIManager;
import gobject.Signals;
import gtkc.gobjecttypes;

alias ulong Condns;

struct MaskedCondns {
    Condns condns;
    Condns mask;

    invariant() {
        assert((condns & mask) == condns);
    }

    MaskedCondns opBinary(string op) (in MaskedCondns other) const if (op == "|")
    {
        return MaskedCondns(this.condns | other.condns, this.mask | other.mask);
    }
}
unittest {
    import core.exception;
    import std.exception;

    auto bad = MaskedCondns(8, 7);
    assertThrown!AssertError(bad | MaskedCondns(1, 7));
    assert((MaskedCondns(8, 15) | MaskedCondns(1, 7)) == MaskedCondns(9, 15));
}

const Condns AC_DONT_CARE = 0;

Condns new_action_condn()
{
    static int next_shift;

    assert(next_shift < 64);
    return 1 << next_shift++;
}

const Condns AC_TREE_SELN_NONE;
const Condns AC_TREE_SELN_MADE;
const Condns AC_TREE_SELN_UNIQUE;
const Condns AC_TREE_SELN_PAIR;
const Condns AC_TREE_SELN_MASK;
static this() {
    AC_TREE_SELN_NONE = new_action_condn();
    AC_TREE_SELN_MADE = new_action_condn();
    AC_TREE_SELN_UNIQUE = new_action_condn();
    AC_TREE_SELN_PAIR = new_action_condn();
    AC_TREE_SELN_MASK = AC_TREE_SELN_NONE | AC_TREE_SELN_MADE | AC_TREE_SELN_UNIQUE | AC_TREE_SELN_PAIR;
}

MaskedCondns get_masked_tree_seln_conditions(TreeSelection tree_seln)
{
    if (tree_seln !is null) {
        switch (tree_seln.countSelectedRows()) {
        case 0: return MaskedCondns(AC_TREE_SELN_NONE, AC_TREE_SELN_MASK);
        case 1: return MaskedCondns(AC_TREE_SELN_MADE | AC_TREE_SELN_UNIQUE, AC_TREE_SELN_MASK);
        case 2: return MaskedCondns(AC_TREE_SELN_MADE | AC_TREE_SELN_PAIR, AC_TREE_SELN_MASK);
        default: return MaskedCondns(AC_TREE_SELN_MADE, AC_TREE_SELN_MASK);
        }
    }
    return MaskedCondns(AC_DONT_CARE, AC_TREE_SELN_MASK);
}

class ConditionalActionGroups {
    Condns current_condns;
    string name;
    ActionGroup[Condns] groups;
    UIManager[] ui_mgrs;
    // TODO: add invariant to say actions are unique

    this(string name)
    {
        this.name = name;
        current_condns = 0;
        ui_mgrs = [];
    }

    this(string name, TreeSelection tree_seln)
    {
        this(name);
        update_conditions(get_masked_tree_seln_conditions(tree_seln));
        tree_seln.addOnChanged(&tree_seln_change_cb);
    }

    ref ActionGroup opIndex(in Condns condns)
    {
        if (condns !in groups) {
            groups[condns] = new ActionGroup(name ~ ":" ~ format("%x", condns));
            groups[condns].setSensitive((condns & current_condns) == condns);
            foreach (ui_mgr; ui_mgrs) {
                ui_mgr.insertActionGroup(groups[condns], -1);
            }
        }
        return groups[condns];
    }

    private void tree_seln_change_cb(TreeSelection tree_seln)
    {
        update_conditions(get_masked_tree_seln_conditions(tree_seln));
    }

    void update_conditions(MaskedCondns changed_condns)
    {
        auto condns = changed_condns.condns | (current_condns & ~changed_condns.mask);
        foreach (key_condns, group; groups) {
            if (changed_condns.mask & key_condns)
                group.setSensitive((key_condns & condns) == key_condns);
        }
        current_condns = condns;
    }

    void add_ui_mgr(UIManager ui_mgr)
    {
        ui_mgrs ~= ui_mgr;
        foreach (agrp; groups.values) {
            ui_mgr.insertActionGroup(agrp, -1);
        }
    }
}
unittest {
    import std.stdio;
    import gtk.TreeView;
    import gtk.TreeIter;
    import gtk.Main;
    import gtk.ListStore;
    import gtk.Action;
    string args[] = [];
    Main.init(args);
    auto cag = new ConditionalActionGroups("test");
    assert(cag.current_condns == AC_DONT_CARE);
    auto ls = new ListStore([GType.STRING]);
    auto tv = new TreeView(ls);
    cag = new ConditionalActionGroups("test with tree selection", tv.getSelection());
    assert(cag.current_condns == (AC_TREE_SELN_NONE));
    assert(!cag[AC_TREE_SELN_UNIQUE].getSensitive());
    assert(!cag[AC_TREE_SELN_MADE].getSensitive());
    assert(cag[AC_TREE_SELN_NONE].getSensitive());
    assert(cag[AC_DONT_CARE].getSensitive());
    auto ti = new TreeIter();
    ls.append(ti);
    ls.setValue(ti, 0, "test");
    tv.getSelection().selectIter(ti);
    assert(cag.current_condns == (AC_TREE_SELN_MADE | AC_TREE_SELN_UNIQUE));
    assert(cag[AC_TREE_SELN_UNIQUE].getSensitive());
    assert(cag[AC_TREE_SELN_MADE].getSensitive());
    assert(cag[AC_TREE_SELN_MADE|AC_TREE_SELN_UNIQUE].getSensitive());
    assert(!cag[AC_TREE_SELN_PAIR].getSensitive());
    assert(!cag[AC_TREE_SELN_MADE|AC_TREE_SELN_PAIR].getSensitive());
    assert(!cag[AC_TREE_SELN_NONE].getSensitive());
    assert(cag[AC_DONT_CARE].getSensitive());
    auto uim = new UIManager();
    cag.add_ui_mgr(uim);
    cag[AC_TREE_SELN_UNIQUE].addAction(new Action("test", "_Test", "a test", cast(StockID) 0));
    uim.addUiFromString("<ui><popup name=\"test-popup\"><menuitem action=\"test\"/></popup></ui>");
    auto popup = uim.getWidget("/test-popup");
}
