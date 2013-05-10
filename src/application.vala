class TomaTan.Application: Object {
    public Application(string[] args) {
        Gtk.init(ref args);
        timer = new TomaTan.Timer();
        ui = new TomaTan.UI(timer);
    }

    public int run() {
        Gtk.main();
        return 0;
    }

    private TomaTan.Timer timer;
    private TomaTan.UI ui;
}
