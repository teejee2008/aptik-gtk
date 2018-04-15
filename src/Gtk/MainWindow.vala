/*
 * MainWindow.vala
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
using Gee;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JsonHelper;
using TeeJee.ProcessHelper;
using TeeJee.System;
using TeeJee.Misc;
using TeeJee.GtkHelper;
using TeeJee.GtkHelper;

public class MainWindow : Window {
	
	private Box vbox_main;

	private Grid grid;

	private Gtk.Entry txt_basepath;

	private TerminalWindow termwin;

	int icon_size_list = 22;
	int button_width = 85;
	int button_height = 15;

	public MainWindow() {
		
		title = AppName + " v" + AppVersion;
		window_position = WindowPosition.CENTER;
		resizable = false;
		destroy.connect (Gtk.main_quit);
		//set_default_size (def_width, def_height);
		icon = get_app_icon(16);

		//vboxMain
		vbox_main = new Box (Orientation.VERTICAL, 6);
		vbox_main.margin = 6;
		//vbox_main.set_size_request (def_width, def_height);
		add (vbox_main);

		//actions ---------------------------------------------

		init_section_location();

		//init_section_password();

		init_section_backup();

		init_section_header_links();
		
		txt_basepath.text = App.basepath;

		termwin = new TerminalWindow.with_parent(this, false, true);
		termwin.start_shell();	
	
		//init_section_toolbar_bottom();

		//init_section_status();
	}

	private void init_section_header_links() {
		
		var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		//hbox.margin_bottom = 6;
		//hbox.margin_right = 6;
		vbox_main.pack_start (hbox, false, true, 0);

		//var expander = new Gtk.Label("");
		//expander.hexpand = true;
		//hbox.add(expander);

		// donate link
		var button = new Gtk.LinkButton.with_label("", _("Buy me a coffee"));
		hbox.add(button);
		
		button.clicked.connect(() => {
			var win = new DonationWindow();
			win.show();
		});

		// user manual
		button = new Gtk.LinkButton.with_label("", _("Read User Manual"));
		hbox.add(button);
		
		button.clicked.connect(() => {
			xdg_open("https://github.com/teejee2008/aptik-next/blob/master/MANUAL.md");
		});

		// about
		button = new Gtk.LinkButton.with_label("", _("About"));
		hbox.add(button);
		
		button.clicked.connect(() => {
			btn_show_about_window();
		});
	}

	private void btn_show_about_window(){
		
		var dialog = new AboutWindow();
		dialog.set_transient_for (this);

		dialog.authors = {
			"Tony George:teejeetech@gmail.com"
		};

		dialog.contributors = {
			//"Shem Pasamba (Proxy support for package downloads):shemgp@gmail.com"
		};

		dialog.third_party = {
			"Numix project (Main app icon):https://numixproject.org/",
			"Elementary project (various icons):https://github.com/elementary/icons",
			"Tango project (various icons):http://tango.freedesktop.org/Tango_Desktop_Project"
		};
		
		dialog.translators = {
			//"B. W. Knight (Korean):https://launchpad.net/~kbd0651",
			//"giulux (Italian):https://launchpad.net/~giulbuntu",
			//"Jorge Jamhour (Brazilian Portuguese):https://launchpad.net/~jorge-jamhour",
			//"Radek Otáhal (Czech):radek.otahal@email.cz",
			//"Rodion R. (Russian):https://launchpad.net/~r0di0n",
			//"Åke Engelbrektson:https://launchpad.net/~eson"
		};

		dialog.documenters = null;
		dialog.artists = null;
		dialog.donations = null;

		dialog.program_name = AppName;
		dialog.comments = _("Settings & Data Migration Utility for Linux");
		dialog.copyright = "Copyright © 2012-2018 %s (%s)".printf(AppAuthor, AppAuthorEmail);
		dialog.version = AppVersion;
		dialog.logo = get_app_icon(128); 

		dialog.license = "This program is free for personal and commercial use and comes with absolutely no warranty. You use this program entirely at your own risk. The author will not be liable for any damages arising from the use of this program.";
		dialog.website = "http://teejeetech.in";
		dialog.website_label = "http://teejeetech.blogspot.in";

		dialog.initialize();
		dialog.show_all();
	}
	
	private void init_section_location() {
		
		// header
		var label = new Label ("<b>" + _("Backup Location") + "</b>");
		label.set_use_markup(true);
		label.halign = Align.START;
		//label.margin_top = 12;
		label.margin_bottom = 6;
		vbox_main.pack_start (label, false, true, 0);
		
		var hbox = new Box (Gtk.Orientation.HORIZONTAL, 6);
		hbox.margin_bottom = 6;
		hbox.margin_right = 6;
		vbox_main.pack_start (hbox, false, true, 0);

		hbox.set_size_request(500,-1);

		// entry
		var entry = new Gtk.Entry();
		entry.hexpand = true;
		//entry.secondary_icon_stock = "gtk-open";
		entry.placeholder_text = _("Select backup directory");
		entry.margin_left = 6;
		hbox.pack_start (entry, true, true, 0);
		txt_basepath = entry;

		entry.changed.connect(() => {
			App.basepath = txt_basepath.text;
		});
		
		entry.icon_release.connect((p0, p1) => {
			backup_location_browse();
		});

		// btn_browse_backup_dir
		var button = new Gtk.Button.with_label (" " + _("Select") + " ");
		button.set_size_request(button_width, button_height);
		button.set_tooltip_text(_("Select backup location"));
		hbox.pack_start (button, false, true, 0);

		button.clicked.connect(backup_location_browse);
		
		// btn_open_backup_dir
		button = new Gtk.Button.with_label (" " + _("Open") + " ");
		button.set_size_request(button_width, button_height);
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
			this,
			FileChooserAction.SELECT_FOLDER,
			"_Cancel",
			Gtk.ResponseType.CANCEL,
			"_Open",
			Gtk.ResponseType.ACCEPT
		);

		chooser.select_multiple = false;
		chooser.set_filename(App.basepath);

		if (chooser.run() == Gtk.ResponseType.ACCEPT) {
			txt_basepath.text = chooser.get_filename();
		}

		chooser.destroy();
	}
	
	private void init_section_backup() {

		// lbl_header_backup
		var label = new Label ("<b>" + _("Backup &amp; Restore") + "</b>");
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_bottom = 6;
		vbox_main.pack_start (label, false, true, 0);

		//grid
		grid = new Grid();
		grid.set_column_spacing(6);
		grid.set_row_spacing(3);
		grid.margin_left = 6;
		grid.margin_bottom = 6;
		vbox_main.pack_start (grid, false, true, 0);

		int row = -1;

		init_section_repos(++row);

		init_section_cache(++row);

		init_section_packages(++row);

		init_section_users(++row);

		init_section_groups(++row);

		init_section_home(++row);
		
		init_section_mounts(++row);
		
		init_section_icons(++row);

		init_section_themes(++row);
		
		init_section_fonts(++row);

		init_section_dconf(++row);
		
		init_section_cron(++row);

		var sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
		sep.margin = 6;
		grid.attach(sep, 0, ++row, 4, 1);

		init_section_all(++row);
	}

	// helpers -----------------------------

	private void add_section_icon(int row, string icon_name) {

		var img = IconManager.lookup_image(icon_name, icon_size_list);
		grid.attach(img, 0, row, 1, 1);
	}
	
	private void add_section_label(int row, string text) {

		var label = new Gtk.Label(text);
		//label.set_tooltip_text(tooltip);
		label.set_use_markup(true);
		label.halign = Align.START;
		label.hexpand = true;
		grid.attach(label, 1, row, 1, 1);
	}

	private Gtk.ButtonBox add_section_actions(int row){

		var bbox = new Gtk.ButtonBox(Orientation.HORIZONTAL);
		bbox.set_layout(Gtk.ButtonBoxStyle.EXPAND);
		bbox.set_homogeneous(false);
		bbox.margin_left = 24;
		grid.attach(bbox, 2, row, 1, 1);
		return bbox;
	}

	private Gtk.Button add_button(Gtk.ButtonBox bbox, string text) {

		var button = new Gtk.Button.with_label(text);
		//button.set_size_request(button_width, button_height);
		bbox.add(button);
		return button;
	}

	private Gtk.Button add_button_view(Gtk.ButtonBox bbox) {

		return add_button(bbox, _("List"));
	}

	private Gtk.Button add_button_backup(Gtk.ButtonBox bbox) {

		return add_button(bbox, _("Backup"));
	}

	private Gtk.Button add_button_restore(Gtk.ButtonBox bbox) {

		return add_button(bbox, _("Restore"));
	}

	public void execute(string cmd){

		termwin.reset();
		termwin.show_all();		
		termwin.execute_command(cmd);
	}
	
	// sections ---------------------------------------
	
	private void init_section_repos(int row) {
		
		add_section_icon(row, "x-system-software-sources");

		add_section_label(row, Messages.TASK_REPOS);

		var bbox = add_section_actions(row);

		/*var button = add_button_view(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --list-repos --basepath '%s'".printf(App.basepath));
		});*/

		var button = add_button_backup(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			var win = new RepoWindow(this, false);
			win.show_all();
			
			//execute("pkexec aptik --backup-repos --basepath '%s'".printf(App.basepath));
		});

		button = add_button_restore(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			var win = new RepoWindow(this, true);
			win.show_all();
			
			//execute("pkexec aptik --restore-repos --basepath '%s'".printf(App.basepath));
		});
	}

	private void init_section_cache(int row) {
		
		add_section_icon(row, "download");

		add_section_label(row, Messages.TASK_CACHE);

		var bbox = add_section_actions(row);

		/*var button = add_button_view(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			//execute("pkexec aptik --list-cache --basepath '%s'".printf(App.basepath));
		});*/

		var button = add_button_backup(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --backup-cache --basepath '%s'".printf(App.basepath));
		});

		button = add_button_restore(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --restore-cache --basepath '%s'".printf(App.basepath));
		});
	}

	private void init_section_packages(int row) {
		
		add_section_icon(row, "package-x-generic");

		add_section_label(row, Messages.TASK_PACKAGES);

		var bbox = add_section_actions(row);
		
		/*var button = add_button_view(bbox);
		button.clicked.connect(()=>{

			var win = new PackageWindow(this, false);
			win.show_all();
			
			//execute("pkexec aptik --list-installed-user --basepath '%s'".printf(App.basepath));
		});*/

		var button = add_button_backup(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			var win = new PackageWindow(this, false);
			win.show_all();
			
			//execute("pkexec aptik --backup-packages --basepath '%s'".printf(App.basepath));
		});

		button = add_button_restore(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			var win = new PackageWindow(this, true);
			win.show_all();
			
			//execute("pkexec aptik --restore-packages --basepath '%s'".printf(App.basepath));
		});
	}

	private void init_section_users(int row) {
		
		add_section_icon(row, "config-users");

		add_section_label(row, Messages.TASK_USERS);

		var bbox = add_section_actions(row);
		
		/*var button = add_button_view(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --list-users --basepath '%s'".printf(App.basepath));
		});*/

		var button = add_button_backup(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --backup-users --basepath '%s'".printf(App.basepath));
		});

		button = add_button_restore(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --restore-users --basepath '%s'".printf(App.basepath));
		});
	}

	private void init_section_groups(int row) {
		
		add_section_icon(row, "config-users");

		add_section_label(row, Messages.TASK_GROUPS);

		var bbox = add_section_actions(row);
		
		/*var button = add_button_view(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --list-groups --basepath '%s'".printf(App.basepath));
		});*/

		var button = add_button_backup(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --backup-groups --basepath '%s'".printf(App.basepath));
		});

		button = add_button_restore(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --restore-groups --basepath '%s'".printf(App.basepath));
		});
	}

	private void init_section_home(int row) {
		
		add_section_icon(row, "user-home");

		add_section_label(row, Messages.TASK_HOME);

		var bbox = add_section_actions(row);
		
		/*var button = add_button_view(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --list-home --basepath '%s'".printf(App.basepath));
		});*/

		var button = add_button_backup(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --backup-home --basepath '%s'".printf(App.basepath));
		});

		button = add_button_restore(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --restore-home --basepath '%s'".printf(App.basepath));
		});
	}

	private void init_section_mounts(int row) {
		
		add_section_icon(row, "drive-harddisk");

		add_section_label(row, Messages.TASK_MOUNTS);

		var bbox = add_section_actions(row);
		
		/*var button = add_button_view(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --list-mounts --basepath '%s'".printf(App.basepath));
		});*/

		var button = add_button_backup(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --backup-mounts --basepath '%s'".printf(App.basepath));
		});

		button = add_button_restore(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --restore-mounts --basepath '%s'".printf(App.basepath));
		});
	}

	private void init_section_icons(int row) {
		
		add_section_icon(row, "preferences-theme");

		add_section_label(row, Messages.TASK_ICONS);

		var bbox = add_section_actions(row);
		
		/*var button = add_button_view(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --list-icons --basepath '%s'".printf(App.basepath));
		});*/

		var button = add_button_backup(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --backup-icons --basepath '%s'".printf(App.basepath));
		});

		button = add_button_restore(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --restore-icons --basepath '%s'".printf(App.basepath));
		});
	}

	private void init_section_themes(int row) {
		
		add_section_icon(row, "preferences-theme");

		add_section_label(row, Messages.TASK_THEMES);

		var bbox = add_section_actions(row);
		
		/*var button = add_button_view(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --list-themes --basepath '%s'".printf(App.basepath));
		});*/

		var button = add_button_backup(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --backup-themes --basepath '%s'".printf(App.basepath));
		});

		button = add_button_restore(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --restore-themes --basepath '%s'".printf(App.basepath));
		});
	}

	private void init_section_fonts(int row) {
		
		add_section_icon(row, "preferences-theme");

		add_section_label(row, Messages.TASK_FONTS);

		var bbox = add_section_actions(row);
		
		/*var button = add_button_view(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --list-fonts --basepath '%s'".printf(App.basepath));
		});

		button.sensitive = false;*/

		var button = add_button_backup(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --backup-fonts --basepath '%s'".printf(App.basepath));
		});

		button = add_button_restore(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --restore-fonts --basepath '%s'".printf(App.basepath));
		});
	}

	private void init_section_dconf(int row) {
		
		add_section_icon(row, "preferences-system");

		add_section_label(row, Messages.TASK_DCONF);

		var bbox = add_section_actions(row);
		
		/*var button = add_button_view(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			//execute("pkexec aptik --list-dconf --basepath '%s'".printf(App.basepath));
		});

		button.sensitive = false;*/

		var button = add_button_backup(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --backup-dconf --basepath '%s'".printf(App.basepath));
		});

		button = add_button_restore(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --restore-dconf --basepath '%s'".printf(App.basepath));
		});
	}

	private void init_section_cron(int row) {
		
		add_section_icon(row, "clock");

		add_section_label(row, Messages.TASK_CRON);

		var bbox = add_section_actions(row);
		
		/*var button = add_button_view(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			//execute("pkexec aptik --list-cron --basepath '%s'".printf(App.basepath));
		});

		button.sensitive = false;*/

		var button = add_button_backup(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --backup-cron --basepath '%s'".printf(App.basepath));
		});

		button = add_button_restore(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --restore-cron --basepath '%s'".printf(App.basepath));
		});
	}

	private void init_section_all(int row) {
		
		add_section_icon(row, "edit-select-all");

		add_section_label(row, Messages.TASK_ALL);

		var bbox = add_section_actions(row);
		
		var button = add_button_backup(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --backup-all --basepath '%s'".printf(App.basepath));
		});

		button = add_button_restore(bbox);
		button.clicked.connect(()=>{
			
			if (!check_backup_folder()) { return; }

			execute("pkexec aptik --restore-all --basepath '%s'".printf(App.basepath));
		});
	}

	private void btn_about_clicked () {
		
		var dialog = new AboutWindow();
		dialog.set_transient_for (this);

		dialog.authors = {
			"Tony George:teejeetech@gmail.com"
		};

		dialog.contributors = {
			"Shem Pasamba (Proxy support for package downloads):shemgp@gmail.com"
		};

		dialog.third_party = {
			"Numix project (Main app icon):https://numixproject.org/",
			"Elementary project (various icons):https://github.com/elementary/icons",
			"Tango project (various icons):http://tango.freedesktop.org/Tango_Desktop_Project"
		};
		
		dialog.translators = {
			"B. W. Knight (Korean):https://launchpad.net/~kbd0651",
			"giulux (Italian):https://launchpad.net/~giulbuntu",
			"Jorge Jamhour (Brazilian Portuguese):https://launchpad.net/~jorge-jamhour",
			"Radek Otáhal (Czech):radek.otahal@email.cz",
			"Rodion R. (Russian):https://launchpad.net/~r0di0n",
			"Åke Engelbrektson:https://launchpad.net/~eson"
		};

		dialog.documenters = null;
		dialog.artists = null;
		dialog.donations = null;

		dialog.program_name = AppName;
		dialog.comments = _("Migration utility for Ubuntu-based distributions");
		dialog.copyright = "Copyright © 2012-2017 %s (%s)".printf(AppAuthor, AppAuthorEmail);
		dialog.version = AppVersion;
		dialog.logo = get_app_icon(128); 

		dialog.license = "This program is free for personal and commercial use and comes with absolutely no warranty. You use this program entirely at your own risk. The author will not be liable for any damages arising from the use of this program.";
		dialog.website = "http://teejeetech.in";
		dialog.website_label = "http://teejeetech.blogspot.in";

		dialog.initialize();
		dialog.show_all();
	}

	private bool check_backup_folder() {
		if (dir_exists (txt_basepath.text)) {
			return true;
		}
		else {
			string title = _("Backup Location Not Found");
			string msg = _("Select a valid path for backup location");
			gtk_messagebox(title, msg, this, false);
			return false;
		}
	}

	private bool check_password() {

		//App.arg_password = txt_password.text;
		
		//if (App.arg_password.length > 0){
			return true;
		//}
		//else {
			/*string title = _("Password Field is Empty");
			string msg = _("Enter the passphrase for encryption");
			gtk_messagebox(title, msg, this, false);
			return false;*/
		//}
	}

	private bool check_backup_file(string file_name) {
		/*if (check_backup_folder()) {
			string backup_file = App.backup_dir + file_name;
			var f = File.new_for_path(backup_file);
			if (!f.query_exists()) {
				string title = _("File Not Found");
				string msg = _("File not found in backup directory") + " - %s".printf(file_name);
				gtk_messagebox(title, msg, this, true);
				return false;
			}
			else {
				return true;
			}
		}
		else {
			return false;
		}*/
		return false;
	}

	private bool check_backup_subfolder(string folder_name) {
		/*if (check_backup_folder()) {
			string folder = App.backup_dir + folder_name;
			var f = File.new_for_path(folder);
			if (!f.query_exists()) {
				string title = _("Folder Not Found");
				string msg = _("Folder not found in backup directory") + " - %s".printf(folder_name);
				gtk_messagebox(title, msg, this, true);
				return false;
			}
			else {
				return true;
			}
		}
		else {*/
			return false;
		//}
	}

}


