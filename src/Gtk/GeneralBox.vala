/*
 * GeneralBox.vala
 *
 * Copyright 2012-2017 Tony George <teejeetech@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */


using Gtk;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.ProcessHelper;
using TeeJee.System;
using TeeJee.Misc;
using TeeJee.GtkHelper;

public class GeneralBox : Gtk.Box {

	protected Gtk.Box vbox_main;

	protected Gtk.Entry entry_location;

	protected MainWindow parent_window;

	public signal void mode_changed();
	
	public GeneralBox(MainWindow parent) {

		parent_window = parent;

		vbox_main = new Gtk.Box(Orientation.VERTICAL, 12);
		vbox_main.margin = 12;
		this.add(vbox_main);

		init_ui();
	}

	protected virtual void init_ui(){

		init_ui_location();

		init_ui_mode();
		
		show_all();
	}

	private void init_ui_location() {
		
		// header
		var label = new Gtk.Label(format_text(_("Select Backup Path"), true, false, true));
		label.set_use_markup(true);
		label.halign = Align.START;
		vbox_main.pack_start(label, false, true, 0);
		
		var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		hbox.margin = 12;
		vbox_main.pack_start(hbox, false, true, 0);

		hbox.set_size_request(500,-1);

		// entry
		var entry = new Gtk.Entry();
		entry.hexpand = true;
		//entry.placeholder_text = _("Enter Backup Path");
		hbox.pack_start(entry, true, true, 0);

		entry.text = App.basepath;
		
		entry_location = entry;

		entry.changed.connect(() => {
			App.basepath = entry.text;
		});
		
		entry.icon_release.connect((p0, p1) => {
			backup_location_browse();
		});

		// btn_browse_backup_dir
		var button = new Gtk.Button.with_label(_("Select"));
		button.set_tooltip_text(_("Select backup location"));
		hbox.pack_start (button, false, true, 0);

		button.clicked.connect(backup_location_browse);
		
		// btn_open_backup_dir
		button = new Gtk.Button.with_label(_("Open"));
		button.set_tooltip_text(_("Open backup location"));
		hbox.pack_start (button, false, true, 0);

		button.clicked.connect(() => {
			if (check_backup_folder()) {
				exo_open_folder(App.basepath, false);
			}
		});

		button.grab_focus();
	}

	private void backup_location_browse(){
		
		//chooser
		var chooser = new Gtk.FileChooserDialog(
			"Select Path",
			parent_window,
			FileChooserAction.SELECT_FOLDER,
			"_Cancel",
			Gtk.ResponseType.CANCEL,
			"_Open",
			Gtk.ResponseType.ACCEPT
		);

		chooser.select_multiple = false;
		chooser.set_filename(App.basepath);

		if (chooser.run() == Gtk.ResponseType.ACCEPT) {
			entry_location.text = chooser.get_filename();
		}

		chooser.destroy();
	}

	private bool check_backup_folder() {
		
		if (dir_exists (entry_location.text)) {
			return true;
		}
		else {
			string title = _("Backup Location Not Found");
			string msg = _("Select a valid path for backup location");
			gtk_messagebox(title, msg, parent_window, false);
			return false;
		}
	}

	private void init_ui_mode() {
		
		// header
		var label = new Gtk.Label(format_text(_("Select Mode"), true, false, true));
		label.set_use_markup(true);
		label.halign = Align.START;
		//label.margin_top = 24;
		//label.margin_bottom = 24;
		vbox_main.pack_start(label, false, true, 0);

		var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		hbox.margin = 12;
		vbox_main.pack_start(hbox, false, true, 0);
		hbox.set_size_request(500,-1);

		// backup --------------------------------
		
		var button = new Gtk.ToggleButton.with_label(_("Backup"));
		button.set_tooltip_text(_("Create backups for current system"));
		hbox.pack_start (button, false, true, 0);
		var btn_backup = button;

		// restore -------------------------

		button = new Gtk.ToggleButton.with_label(_("Restore"));
		button.set_tooltip_text(_("Restore backups on new system"));
		hbox.pack_start (button, false, true, 0);
		var btn_restore = button;

		// events -----------------------
		
		btn_backup.clicked.connect(() => {
			if (btn_backup.active){
				App.mode = Mode.BACKUP;
				btn_restore.active = false;
				mode_changed();
			}
		});
		
		btn_restore.clicked.connect(() => {
			if (btn_restore.active){
				App.mode = Mode.RESTORE;
				btn_backup.active = false;
				mode_changed();
			}
		});

		btn_backup.active = true;

		btn_backup.grab_focus();
	}
}
