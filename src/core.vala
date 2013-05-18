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
