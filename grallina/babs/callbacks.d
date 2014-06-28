// i18ndummy.d
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

module grallina.babs.callbacks;

import std.string: format;
import std.variant: Variant, variantArray;
import std.array: insertInPlace, replaceInPlace;

import grallina.babs.i18ndummy;

private class ClientData(T...) {
    bool delegate(T, Variant[]...) client_delegate;
    private Variant[] extra_args;
    bool is_suspended;

    this(bool delegate(T, Variant[]...) client_delegate, Variant[] extra_args)
    {
        this.client_delegate = client_delegate;
        this.extra_args = extra_args;
    }

    bool make_call(T...)(T args) {
       if (is_suspended) return false;
        return client_delegate(args, extra_args);
    }
}

abstract class ConnectionProxy {
    abstract bool is_suspended();
    abstract bool is_suspended(bool value);
    abstract bool is_connected();
    abstract void disconnect();
}

class Connection(T...) {
private:
    Callback!(T) callback;
    ClientData!(T) client_data;

public:
    this(Callback!(T) callback, ClientData!(T) client_data)
    {
        this.callback = callback;
        this.client_data = client_data;
    }

    bool is_suspended()
    {
        return (client_data is null) || client_data.is_suspended;
    }

    bool is_suspended(bool value)
    {
        if (client_data is null) return true;
        client_data.is_suspended = value;
        return client_data.is_suspended;
    }

    bool is_connected() { return callback !is null; }

    void disconnect()
    {
        if (callback is null) return;
        callback.disconnect(this);
        callback = null;
        client_data = null;
    }
}

abstract class CallbackProxy {
    enum : ubyte { BEFORE, NORMAL, AFTER }
    private bool _blockable;

    bool is_blockable() { return _blockable; }

    bool is_blockable(bool value)
    {
        _blockable = value;
        return _blockable;
    }

    abstract ConnectionProxy connect(V...)(V args);
    abstract ConnectionProxy connect_before(V...)(V args);
    abstract ConnectionProxy connect_after(V...)(V args);
    abstract void emit(V...)(V args);
}

class Callback(T...): CallbackProxy {
    alias bool delegate(T, Variant[]...) DT;
    private ClientData!(T)[][3] ordered_clients;

    this (bool blockable=true)
    {
        _blockable = blockable;
    }

    Connection!(T) connect(V...)(V args)
    {
        auto ccd = new ClientData!(T)(args[0], variantArray(args[1..$]));
        ordered_clients[NORMAL] ~= ccd;
        return new Connection!(T)(this, ccd);
    }

    Connection!(T) connect_before(V...)(V args)
    {
        auto ccd = new ClientData!(T)(args[0], variantArray(args[1..$]));
        ordered_clients[BEFORE].insertInPlace(0, ccd);
        return new Connection!(T)(this, ccd);
    }

    Connection!(T) connect_after(V...)(V args)
    {
        auto ccd = new ClientData!(T)(args[0], variantArray(args[1..$]));
        ordered_clients[AFTER] ~= ccd;
        return new Connection!(T)(this, ccd);
    }

    void emit(V...)(V args)
    {
        foreach (clients; ordered_clients) {
            foreach (client; clients) {
                if (client.make_call(args) && _blockable) return;
            }
        }
    }

private:
    void disconnect(Connection!(T) connection)
    in {
        assert(!connection.is_connected || connection.callback == this);
    }
    body {
        if (!connection.is_connected) return;
        size_t i;
        foreach (ref clients; ordered_clients) {
            for (i = 0; i < clients.length; i++) if (clients[i] == connection.client_data) break;
            if (i < clients.length) {
                replaceInPlace(clients, i, i + 1, cast(ClientData!(T)[]) null);
                break;
            }
        }
    }
}
unittest {
    auto cb = new Callback!(int, string)(false);
    cb.emit(7, "seven");
    struct A {
        int ii;
        string ss;
        Variant[] vargs;
        bool cb(int i, string s, Variant[] args...){
            ii = i;
            ss = s;
            vargs = args;
            return false;
        }
        bool bcb(int i, string s, Variant[] args...){
            ii = i;
            ss = s;
            vargs = args;
            return false;
        }
    }
    A a;
    auto cn = cb.connect(&a.cb, 1, 2, 3);
    cb.emit(9, "eleven");
    assert(a.ii == 9 && a.ss == "eleven" && a.vargs == variantArray(1, 2, 3));
    cn.is_suspended = true;
    cb.emit(8, "nine");
    assert(a.ii == 9 && a.ss == "eleven" && a.vargs == variantArray(1, 2, 3));
    cn.is_suspended = false;
    cb.emit(10, "twelve");
    assert(a.ii == 10 && a.ss == "twelve" && a.vargs == variantArray(1, 2, 3));
    cn.disconnect();
    cb.emit(11, "no way");
    assert(a.ii == 10 && a.ss == "twelve" && a.vargs == variantArray(1, 2, 3));
    cn.disconnect();
    struct B {
        int ii;
        string ss;
        Variant[] vargs;
        bool bb;
        bool bcb(int i, string s, Variant[] args...){
            ii = i;
            ss = s;
            vargs = args;
            bb = i % 2 == 0;
            return bb;
        }
    }
    B b;
    auto bcb = new Callback!(int, string)();
    auto cna = bcb.connect(&a.bcb);
    auto cnb = bcb.connect(&b.bcb);
    bcb.emit(11, "no trues");
    assert(a.ii == 11 && a.ss == "no trues" && a.vargs == variantArray());
    assert(b.ii == 11 && b.ss == "no trues" && b.vargs == variantArray() && b.bb == false);
    bcb.emit(10, "one true: non blocking");
    assert(a.ii == 10 && a.ss == "one true: non blocking" && a.vargs == variantArray());
    assert(b.ii == 10 && b.ss == "one true: non blocking" && b.vargs == variantArray() && b.bb == true);
    cnb.disconnect();
    cnb = bcb.connect_before(&b.bcb);
    bcb.emit(11, "no trues");
    assert(a.ii == 11 && a.ss == "no trues" && a.vargs == variantArray());
    assert(b.ii == 11 && b.ss == "no trues" && b.vargs == variantArray() && b.bb == false);
    bcb.emit(8, "one true: blocking");
    assert(a.ii == 11 && a.ss == "no trues" && a.vargs == variantArray());
    assert(b.ii == 8 && b.ss == "one true: blocking" && b.vargs == variantArray() && b.bb == true);
    cnb.is_suspended = true;
    bcb.emit(6, "b would be true but is disabled so doesn't block");
    assert(a.ii == 6 && a.ss == "b would be true but is disabled so doesn't block" && a.vargs == variantArray());
    assert(b.ii == 8 && b.ss == "one true: blocking" && b.vargs == variantArray() && b.bb == true);
}


/// An callback specific exception for reporting errors.
abstract class CallbackException: Exception {
    this(string message, string file=__FILE__, size_t line=__LINE__, Throwable next=null)
    {
        super("Callbacks Error: " ~ message, file, line, next);
    }
}

private class CallbackDuplicateName: CallbackException {
    static auto TEMPLATE = T!"A callback named \"%s\" already exists.";

    this(string name, string file=__FILE__, size_t line=__LINE__, Throwable next=null)
    {
        super(format(TEMPLATE, name), file, line, next);
    }
}

private class CallbackUnknownName: CallbackException {
    static auto TEMPLATE = T!"Unknown callback name: \"%s\".";

    this(string name, string file=__FILE__, size_t line=__LINE__, Throwable next=null)
    {
        super(format(TEMPLATE, name), file, line, next);
    }
}
