/*
 * Copyright (c) 2013, Philip Xu <pyx@xrefactor.com>
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

using Gtk;
using Notify;

class TomaTan.UI: GLib.Object {
    public UI(TomaTan.Timer timer) {
        this.timer = timer;
        this.logo = new Gdk.Pixbuf.from_xpm_data(TomaTan.logo_xpm);

        Notify.init(TomaTan.NAME);

        timer.done.connect((t) => {
            var alert = new Notification(TomaTan.NAME,
                                         TomaTan.NOTIFICATION_MESSAGE,
                                         null);
            alert.set_urgency(Urgency.CRITICAL);
            alert.set_icon_from_pixbuf(logo);
            try {
                alert.show();
            } catch (Error e) {
                GLib.error("%s\n", e.message);
            }
        });

        init_trayicon();
        init_popup_menu();
        init_window();
    }

    private void init_window() {
        this.window = new Gtk.Window();
        window.title = TomaTan.NAME;
        window.window_position = Gtk.WindowPosition.CENTER;
        window.type_hint = Gdk.WindowTypeHint.DIALOG;
        window.set_default_size(WIDTH, HEIGHT);
        window.set_keep_above(true);
        window.skip_pager_hint = true;
        window.skip_taskbar_hint = true;
        window.decorated = false;

        var label = new Gtk.Label(null);
        label.use_markup = true;

        var logo64 = logo.scale_simple(WIDTH, HEIGHT, Gdk.InterpType.BILINEAR);
        var image = new Gtk.Image.from_pixbuf(logo64);

        var overlay = new Gtk.Overlay();
        overlay.add(label);
        overlay.add_overlay(image);
        window.add(overlay);

        var fmt = "<span size='xx-large'><tt>%02u</tt></span>";

        window.add_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
        window.enter_notify_event.connect(() => {
            image.hide();
            label.label = fmt.printf(timer.minute);
            return true;
        });

        window.add_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
        window.leave_notify_event.connect(() => {
            image.show();
            return true;
        });

        window.add_events(Gdk.EventMask.BUTTON_PRESS_MASK);
        window.button_press_event.connect((e) => {
            if (e.type == Gdk.EventType.BUTTON_PRESS)
                switch (e.button) {
                case 1:
                    window.begin_move_drag((int) e.button,
                                           (int) e.x_root,
                                           (int) e.y_root,
                                           e.time);
                    break;

                case 3:
                    menu.popup(null, null, null, e.button, e.time);
                    break;
                }
            image.show();
            return true;
        });

        window.destroy.connect(Gtk.main_quit);

        window.show_all();
        window.stick();
    }

    private void init_trayicon() {
        this.trayicon = new Gtk.StatusIcon.from_pixbuf(logo);
        trayicon.set_tooltip_text(TomaTan.NAME);
        trayicon.set_visible(true);

        trayicon.query_tooltip.connect((x, y, kb, tooltip) => {
            tooltip.set_icon(logo);
            var markup = "<span size='x-large'>%s</span>\n\n\t<tt>%s</tt>.";
            tooltip.set_markup(markup.printf(NAME, @"$timer"));
            return true;
        });
    }

    private void init_popup_menu() {
        var start = new Gtk.ImageMenuItem.from_stock(Stock.MEDIA_PLAY, null);
        var stop = new Gtk.ImageMenuItem.from_stock(Stock.MEDIA_STOP, null);

        start.label = "Start";
        start.activate.connect(() => {
            timer.reset();
            timer.start();
            start.sensitive = false;
            stop.sensitive = true;
        });

        stop.sensitive = false;
        stop.activate.connect(() => {
            timer.stop();
            stop.sensitive = false;
            start.sensitive = true;
        });

        timer.done.connect((t) => {
            stop.sensitive = false;
            start.sensitive = true;
        });

        var about = new Gtk.ImageMenuItem.from_stock(Stock.ABOUT, null);
        about.activate.connect(() => {
            var about_dialog = new Gtk.AboutDialog();
            about_dialog.version = TomaTan.VERSION;
            about_dialog.program_name = TomaTan.NAME;
            about_dialog.comments = TomaTan.DESC;
            about_dialog.copyright = TomaTan.COPYRIGHT;
            about_dialog.license = TomaTan.LICENSE;
            about_dialog.wrap_license = true;
            about_dialog.license_type = License.BSD;
            about_dialog.artists = TomaTan.ARTISTS;
            about_dialog.authors = TomaTan.AUTHORS;
            about_dialog.website = TomaTan.URL;
            about_dialog.logo = logo;
            about_dialog.run();
            about_dialog.hide();
        });

        var quit = new Gtk.ImageMenuItem.from_stock(Stock.QUIT, null);
        quit.activate.connect(main_quit);

        this.menu = new Gtk.Menu();
        menu.append(start);
        menu.append(stop);
        menu.append(new Gtk.SeparatorMenuItem());
        menu.append(about);
        menu.append(quit);

        trayicon.popup_menu.connect((button, time) => {
            menu.popup(null, null, null, button, time);
        });

        menu.show_all();
    }

    private const int WIDTH = 64;
    private const int HEIGHT = 64;
    private const int BUTTON_DRAG = 1;
    private const int BUTTON_CONTEXT_MENU = 3;

    private Gtk.Window window;
    private Gtk.Menu menu;
    private Gtk.StatusIcon trayicon;
    private Gdk.Pixbuf logo;
    private TomaTan.Timer timer;
}
