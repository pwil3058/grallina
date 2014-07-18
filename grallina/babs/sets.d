// sets.d
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

module grallina.babs.sets;

import std.string: format;
import std.algorithm: copy, find;
import std.traits: isAssignable;
import std.array: retro;

mixin template DummyClass() {
    class Dummy {
        int val;
        this(int ival) { val = ival; };
        override int opCmp(Object o)
        {
            return val - (cast(Dummy) o).val;
        }
        override bool opEquals(Object o)
        {
            return val == (cast(Dummy) o).val;
        }
        override string toString() const {
            return format("Dummy(%s)", val);
        }
    }
}

private bool is_ordered(T)(in T[] list)
{
    for (auto j = 1; j < list.length; j++) {
        static if (is(T == class)) { // WORKAROUND: class opCmp() design flaw
            if (cast(T) list[j - 1] > cast(T) list[j]) return false;
        } else {
            if (list[j - 1] > list[j]) return false;
        }
    }
    return true;
}
unittest {
    assert(is_ordered(new int[0]));
    assert(is_ordered([1]));
    assert(is_ordered([1, 1]));
    assert(is_ordered([1, 2, 3, 4, 5, 6, 7]));
    assert(!is_ordered([1, 2, 4, 3, 5, 6, 7]));
    assert(is_ordered([1, 2, 3, 5, 5, 6, 7]));
    mixin DummyClass;
    assert(is_ordered([new Dummy(1), new Dummy(2), new Dummy(3), new Dummy(4), new Dummy(5), new Dummy(6), new Dummy(7)]));
    assert(!is_ordered([new Dummy(1), new Dummy(2), new Dummy(4), new Dummy(3), new Dummy(5), new Dummy(6), new Dummy(7)]));
    assert(is_ordered([new Dummy(1), new Dummy(2), new Dummy(3), new Dummy(5), new Dummy(5), new Dummy(6), new Dummy(7)]));
}

private bool is_ordered_no_dups(T)(in T[] list)
{
    for (auto j = 1; j < list.length; j++) {
        static if (is(T == class)) { // WORKAROUND: class opCmp() design flaw
            if (cast(T) list[j - 1] >= cast(T) list[j]) return false;
        } else {
            if (list[j - 1] >= list[j]) return false;
        }
    }
    return true;
}
unittest {
    assert(is_ordered_no_dups(new int[0]));
    assert(is_ordered_no_dups([1]));
    assert(!is_ordered_no_dups([1, 1]));
    assert(is_ordered_no_dups([1, 2, 3, 4, 5, 6, 7]));
    assert(!is_ordered_no_dups([1, 2, 4, 3, 5, 6, 7]));
    assert(!is_ordered_no_dups([1, 2, 3, 5, 5, 6, 7]));
    mixin DummyClass;
    assert(is_ordered_no_dups([new Dummy(1), new Dummy(2), new Dummy(3), new Dummy(4), new Dummy(5), new Dummy(6), new Dummy(7)]));
    assert(!is_ordered_no_dups([new Dummy(1), new Dummy(2), new Dummy(4), new Dummy(3), new Dummy(5), new Dummy(6), new Dummy(7)]));
    assert(!is_ordered_no_dups([new Dummy(1), new Dummy(2), new Dummy(3), new Dummy(5), new Dummy(5), new Dummy(6), new Dummy(7)]));
}

private T[] remove_adj_dups(T)(T[] list)
out (result) {
    for (auto i = 1; i < result.length; i++) {
        assert(result[i - 1] != result[i]);
    }
    foreach (item; list) {
        assert(find(result, item)[0] == item);
    }
}
body {
    if (list.length > 1) {
        // Remove any duplicates
        size_t last_index = 0;
        for (size_t index = 1; index < list.length; index++) {
            if (list[index] != list[last_index]) {
                list[++last_index] = list[index];
            }
        }
        list.length = last_index + 1;
    }
    return list;
}
unittest {
    int[] empty;
    assert(remove_adj_dups(empty) == []);
    int[] single = [1];
    assert(remove_adj_dups(single) == [1]);
    int[] pair = [1, 1];
    assert(remove_adj_dups(pair) == [1]);
    int[] few = [5, 1, 1, 5, 6, 6, 3];
    assert(remove_adj_dups(few) == [5, 1, 5, 6, 3]);
    mixin DummyClass;
    Dummy[] dfew = [new Dummy(5), new Dummy(1), new Dummy(1), new Dummy(5), new Dummy(6), new Dummy(6), new Dummy(3)];
    assert(remove_adj_dups(dfew) == [new Dummy(5), new Dummy(1), new Dummy(5), new Dummy(6), new Dummy(3)]);
}

struct BinarySearchResult {
    bool found; // whether the item was found
    size_t index; // location of item if found else "insert before" point
}

BinarySearchResult binary_search(T)(in T[] list, in T item)
in {
    assert(is_ordered_no_dups(list));
}
out (result) {
    if (result.found) {
        static if (is(T == class)) { // WORKAROUND: class opCmp() design flaw
            assert(cast(T) list[result.index] == cast(T) item);
        } else {
            assert(list[result.index] == item);
        }
    } else {
        static if (is(T == class)) { // WORKAROUND: class opCmp() design flaw
            assert(result.index == list.length || cast (T) list[result.index] > cast (T) item);
            assert(result.index == 0 || cast (T) list[result.index - 1] < cast (T) item);
        } else {
            assert(result.index == list.length || list[result.index] > item);
            assert(result.index == 0 || list[result.index - 1] < item);
        }
    }
}
body {
    // unsigned array indices make this prudent or imax could go out of range
    static if (is(T == class)) { // WORKAROUND: class opCmp() design flaw
        if (list.length == 0 || cast (T) item < cast (T) list[0]) return BinarySearchResult(false, 0);
    } else {
        if (list.length == 0 || item < list[0]) return BinarySearchResult(false, 0);
    }
    auto imax = list.length - 1;
    typeof(imax) imin = 0;

    while (imax >= imin) {
        typeof(imax) imid = (imin + imax) / 2;
        static if (is(T == class)) { // WORKAROUND: class opCmp() design flaw
            if (cast (T) list[imid] < cast (T) item) {
                imin = imid + 1;
            } else if (cast (T) list[imid] > cast (T) item) {
                imax = imid - 1;
            } else {
                return BinarySearchResult(true, imid);
            }
        } else {
            if (list[imid] < item) {
                imin = imid + 1;
            } else if (list[imid] > item) {
                imax = imid - 1;
            } else {
                return BinarySearchResult(true, imid);
            }
        }
    }
    assert(imin >= imax);
    return BinarySearchResult(false, imin);
}
unittest {
    assert(binary_search!int([], 5) == BinarySearchResult(false, 0));
    assert(binary_search!int([5], 5) == BinarySearchResult(true, 0));
    assert(binary_search!int([5], 6) == BinarySearchResult(false, 1));
    assert(binary_search!int([5], 4) == BinarySearchResult(false, 0));
    auto testlist = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23];
    for (auto i = 0; i < testlist.length; i++) {
        assert(binary_search(testlist, testlist[i]) == BinarySearchResult(true, i));
        assert(binary_search(testlist, testlist[i] - 1) == BinarySearchResult(false, i));
        assert(binary_search(testlist, testlist[i] + 1) == BinarySearchResult(false, i + 1));
    }
    mixin DummyClass;
    auto ctestlist = [new Dummy(1), new Dummy(3), new Dummy(5), new Dummy(7), new Dummy(9), new Dummy(11), new Dummy(13), new Dummy(15), new Dummy(17), new Dummy(19), new Dummy(21), new Dummy(23)];
    for (auto i = 0; i < ctestlist.length; i++) {
        assert(binary_search(ctestlist,  new Dummy(ctestlist[i].val)) == BinarySearchResult(true, i));
        assert(binary_search(ctestlist, new Dummy(ctestlist[i].val - 1)) == BinarySearchResult(false, i));
        assert(binary_search(ctestlist, new Dummy(ctestlist[i].val + 1)) == BinarySearchResult(false, i + 1));
    }
}

private T[] to_sorted_no_dups(T)(in T[] list...)
out (result) {
    for (auto i = 1; i < result.length; i++) {
        static if (is(T == class)) { // WORKAROUND: class opCmp() design flaw
            assert(cast(T) result[i - 1] < cast(T) result[i]);
        } else {
            assert(result[i - 1] < result[i]);
        }
    }
    foreach (item; list) {
        assert(find(result, item)[0] == item);
    }
}
body {
    static if (is(T == class)) { // WORKAROUND: class opCmp() design flaw
        auto list_dup = (cast(T[]) list).dup;
    } else {
        auto list_dup = list.dup;
    }
    return list_dup.sort.remove_adj_dups();;
}
unittest {
    int[] empty;
    assert(to_sorted_no_dups(empty) == []);
    int[] single = [1];
    assert(to_sorted_no_dups(single) == [1]);
    int[] pair = [1, 1];
    assert(to_sorted_no_dups(pair) == [1]);
    int[] few = [5, 1, 1, 5, 6, 6, 3];
    assert(to_sorted_no_dups(few) == [1, 3, 5, 6]);
    mixin DummyClass;
    Dummy[] dfew = [new Dummy(5), new Dummy(1), new Dummy(1), new Dummy(5), new Dummy(6), new Dummy(6), new Dummy(3)];
    assert(to_sorted_no_dups(dfew) == [new Dummy(1), new Dummy(3), new Dummy(5), new Dummy(6)]);
}

private ref T[] insert(T)(ref T[] list, in T item)
in {
    assert(is_ordered_no_dups(list));
}
out (result) {
    assert(is_ordered_no_dups(result));
    assert(find(result, item)[0] == item);
    foreach (i; list) {
        assert(find(result, i)[0] == i);
    }
}
body {
    auto bsr = binary_search(list, item);
    if (!bsr.found) {
        static if (!isAssignable!(T, const(T))) {
            list ~= cast(T) item;
        } else {
            list ~= item;
        }
        if (list.length > 1 && bsr.index < list.length - 1) {
            copy(retro(list[bsr.index .. $ - 1]), retro(list[bsr.index + 1 .. $]));
            static if (!isAssignable!(T, const(T))) {
                list[bsr.index] = cast(T) item;
            } else {
                list[bsr.index] = item;
            }
        }
    }
    return list;
}
unittest {
    auto list = [2, 4, 8, 16, 32];
    assert(insert(list, 1) == [1, 2, 4, 8, 16, 32]);
    assert(insert(list, 64) == [1, 2, 4, 8, 16, 32, 64]);
    assert(insert(list, 3) == [1, 2, 3, 4, 8, 16, 32, 64]);
    assert(insert(list, 7) == [1, 2, 3, 4, 7, 8, 16, 32, 64]);
    assert(insert(list, 21) == [1, 2, 3, 4, 7, 8, 16, 21, 32, 64]);
    mixin DummyClass;
    Dummy[] dlist = [new Dummy(2), new Dummy(4), new Dummy(8), new Dummy(16), new Dummy(32)];
    assert(insert(dlist, new Dummy(1)).length == 6);
}

private ref T[] remove(T)(ref T[] list, in T item)
in {
    assert(is_ordered_no_dups(list));
}
out (result) {
    assert(is_ordered_no_dups(result));
    assert(find(result, item).length == 0);
    foreach (i; list) {
        if (i != item) assert(find(result, i)[0] == i);
    }
}
body {
    auto bsr = binary_search(list, item);
    if (bsr.found) {
        copy(list[bsr.index + 1..$], list[bsr.index..$ - 1]);
        list.length--;
    }
    return list;
}
unittest {
    auto list = [1, 2, 3, 4, 7, 8, 16, 21, 32, 64];
    assert(remove(list, 1) == [2, 3, 4, 7, 8, 16, 21, 32, 64]);
    assert(remove(list, 64) == [2, 3, 4, 7, 8, 16, 21, 32]);
    assert(remove(list, 3) == [2, 4, 7, 8, 16, 21, 32]);
    assert(remove(list, 7) == [2, 4, 8, 16, 21, 32]);
    assert(remove(list, 21) == [2, 4, 8, 16, 32]);
    mixin DummyClass;
    Dummy[] dlist = [new Dummy(2), new Dummy(4), new Dummy(8), new Dummy(16), new Dummy(32)];
    assert(remove(dlist, dlist[0]).length == 4);
}