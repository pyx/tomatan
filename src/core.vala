/*
 * Copyright (c) 2013-2015, Philip Xu <pyx@xrefactor.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

class TomaTan.Timer: Object {
    public const uint DEFAULT_SECONDS_IN_POMODORI = 60 * 25;
    public signal void done();

    public uint second {
        get { return counter; }
    }

    public uint minute {
        get { return counter / 60; }
    }

    public Timer() {
        reset();
    }

    public void start() {
        stop();
        id = Timeout.add(1000, () => {
            return tick();
        });
    }

    public void stop() {
        if (id != null && Source.remove(id))
            id = null;
    }

    public void reset(uint ticks = DEFAULT_SECONDS_IN_POMODORI) {
        lock (counter) {
            counter = ticks;
        }
    }

    public bool tick() {
        lock (counter) {
            if (--counter > 0)
                return true;
        }
        id = null;
        done();
        return false;
    }

    public string to_string() {
        if (id == null)
            return "not running";

        switch (minute) {
        case 0:
            return "less than one minute";

        case 1:
            return "one minute left";

        default:
            return "%u minutes left".printf(minute);
        }
    }

    private uint counter = DEFAULT_SECONDS_IN_POMODORI;
    private uint? id = null;
}
