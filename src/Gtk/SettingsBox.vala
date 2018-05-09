/*
 * SettingsWindow.vala
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

public class SettingsBox : Gtk.Box {

	private Gtk.Box vbox_main;

	protected Button btn_restore;
	protected Button btn_backup;

	private MainWindow window;
	
	// init -------------------------
	
	public SettingsBox(MainWindow parent) {

		window = parent;
		
		init_ui();
	}

	public void init_ui() {
	
		vbox_main = new Gtk.Box (Orientation.VERTICAL, 6);
		vbox_main.margin = 12;
		//vbox_main.margin_right = 24;
		this.add(vbox_main);

		var hbox = new Gtk.Box(Orientation.HORIZONTAL, 6);
		//hbox.margin_left = 6;
		vbox_main.add(hbox);

		init_options(hbox);

		init_actions();
		
		show_all();
	}

	private void init_options(Gtk.Box box) {

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		box.add(vbox);
		
		var label = new Gtk.Label(format_text(_("Select Items"), true, false, true));
		label.set_use_markup(true);
		label.halign = Align.START;
		//label.margin = 12;
		vbox.add(label);

		var vbox2 = new Gtk.Box(Orientation.VERTICAL, 12);
		vbox2.margin = 12;
		vbox.add(vbox2);

		add_options_for_items(vbox2);

		// ---------------------
		
		var separator = new Gtk.Separator(Gtk.Orientation.VERTICAL);
		separator.margin = 24;
		//separator.margin_right = 24;
		box.add(separator);

		// ---------------------

		var vbox3 = new Gtk.Box(Orientation.VERTICAL, 6);
		box.add(vbox3);

		label = new Gtk.Label(format_text(_("Settings"), true, false, true));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_bottom = 12;
		vbox3.add(label);

		//var vbox4 = new Gtk.Box(Orientation.VERTICAL, 6);
		//vbox4.margin = 12;
		//vbox3.add(vbox4);

		add_options_packages(vbox3);

		add_options_home(vbox3);
	}

	private void add_options_for_items(Gtk.Box vbox){

		string fmt = "%s - <span size=\"small\" style=\"italic\">%s</span>";

		//NOTE: connect to 'clicked' event instead of 'toggled'

		var chk_repo = create_checkbutton(vbox, fmt.printf(_("Repos"), Messages.TASK_REPOS));

		chk_repo.active = App.include_repos;
		chk_repo.clicked.connect(()=>{
			App.include_repos = chk_repo.active;
		});

		// ----------------------------
		
		var chk_cache = create_checkbutton(vbox, fmt.printf(_("Cache"), Messages.TASK_CACHE));

		chk_cache.active = App.include_cache;
		chk_cache.clicked.connect(()=>{
			App.include_cache = chk_cache.active;
		});

		// ----------------------------
		
		var chk_packages = create_checkbutton(vbox, fmt.printf(_("Packages"), Messages.TASK_PACKAGES));

		chk_packages.active = App.include_packages;
		chk_packages.clicked.connect(()=>{
			App.include_packages = chk_packages.active;
		});

		// ----------------------------
		
		var chk_users = create_checkbutton(vbox, fmt.printf(_("Users"), Messages.TASK_USERS));
	
		chk_users.active = App.include_users;
		chk_users.clicked.connect(()=>{
			App.include_users = chk_users.active;
		});

		// ----------------------------

		var chk_groups = create_checkbutton(vbox, fmt.printf(_("Groups"), Messages.TASK_GROUPS));

		chk_groups.active = App.include_groups;
		chk_groups.clicked.connect(()=>{
			App.include_groups = chk_groups.active;
		});

		// ----------------------------

		var chk_home = create_checkbutton(vbox, fmt.printf(_("Home"), Messages.TASK_HOME));

		chk_home.active = App.include_home;
		chk_home.clicked.connect(()=>{
			App.include_home = chk_home.active;
		});

		// ----------------------------

		var chk_mounts = create_checkbutton(vbox, fmt.printf(_("Mounts"), Messages.TASK_MOUNTS));

		chk_mounts.active = App.include_mounts;
		chk_mounts.clicked.connect(()=>{
			App.include_mounts = chk_mounts.active;
		});

		// ----------------------------

		var chk_dconf = create_checkbutton(vbox, fmt.printf(_("Dconf"), Messages.TASK_DCONF));

		chk_dconf.active = App.include_dconf;
		chk_dconf.clicked.connect(()=>{
			App.include_dconf = chk_dconf.active;
		});

		// ----------------------------

		var chk_cron = create_checkbutton(vbox, fmt.printf(_("Cron"), Messages.TASK_CRON));

		chk_cron.active = App.include_cron;
		chk_cron.clicked.connect(()=>{
			App.include_cron = chk_cron.active;
		});

		// ----------------------------

		var chk_icons = create_checkbutton(vbox, fmt.printf(_("Icons"), Messages.TASK_ICONS));

		chk_icons.active = App.include_icons;
		chk_icons.clicked.connect(()=>{
			App.include_icons = chk_icons.active;
		});

		// ----------------------------

		var chk_themes = create_checkbutton(vbox, fmt.printf(_("Themes"), Messages.TASK_THEMES));

		chk_themes.active = App.include_themes;
		chk_themes.clicked.connect(()=>{
			App.include_themes = chk_themes.active;
		});

		// ----------------------------

		var chk_fonts = create_checkbutton(vbox, fmt.printf(_("Fonts"), Messages.TASK_FONTS));

		chk_fonts.active = App.include_fonts;
		chk_fonts.clicked.connect(()=>{
			App.include_fonts = chk_fonts.active;
		});

		// ----------------------------

		var chk_files = create_checkbutton(vbox, fmt.printf(_("Files"), Messages.TASK_FILES));

		chk_files.active = App.include_files;
		chk_files.clicked.connect(()=>{
			App.include_files = chk_files.active;
		});

		// ----------------------------

		var chk_scripts = create_checkbutton(vbox, fmt.printf(_("Scripts"), Messages.TASK_SCRIPTS));

		chk_scripts.active = App.include_scripts;
		chk_scripts.clicked.connect(()=>{
			App.include_scripts = chk_scripts.active;
		});

		// ----------------------------

		window.guimode_changed.connect(()=>{

			chk_cache.sensitive = !App.redist;
			chk_cache.active = App.redist ? false : App.include_cache;

			chk_users.sensitive = !App.redist;
			chk_users.active = App.redist ? false : App.include_users;

			chk_groups.sensitive = !App.redist;
			chk_groups.active = App.redist ? false : App.include_groups;

			chk_files.sensitive = (App.mode == Mode.RESTORE);
			chk_files.active = (App.mode == Mode.RESTORE);

			chk_scripts.sensitive = (App.mode == Mode.RESTORE);
			chk_scripts.active = (App.mode == Mode.RESTORE);
		});
	}


	private void add_options_packages(Gtk.Box vbox){

		var label = new Gtk.Label("<b>%s</b>".printf(Messages.TASK_PACKAGES));
		label.set_use_markup(true);
		label.halign = Align.START;
		//label.margin = 12;
		vbox.add(label);

		var vbox2 = new Gtk.Box(Orientation.VERTICAL, 12);
		vbox2.margin = 12;
		vbox.add(vbox2);

		add_option_include_pkg_foreign(vbox2);
		
		add_option_exclude_pkg_themes(vbox2);

		add_option_exclude_pkg_icons(vbox2);

		add_option_exclude_pkg_fonts(vbox2);
	}

	private void add_option_exclude_pkg_themes(Gtk.Box vbox){

		var chk = create_checkbutton(vbox, _("Exclude theme packages"));

		chk.set_tooltip_text(_("Exclude theme packages while re-installing software.\nYou can exclude these if you are restoring themes using Aptik.\nKeep this unchecked if you want updates."));

		chk.active = App.exclude_pkg_themes;
		chk.toggled.connect(()=>{
			App.exclude_pkg_themes = chk.active;
		});
	}

	private void add_option_exclude_pkg_icons(Gtk.Box vbox){

		var chk = create_checkbutton(vbox, _("Exclude icon packages"));

		chk.set_tooltip_text(_("Exclude icon packages while re-installing software.\nYou can exclude these if you are restoring icons using Aptik.\nKeep this unchecked if you want updates."));

		chk.active = App.exclude_pkg_icons;
		chk.toggled.connect(()=>{
			App.exclude_pkg_icons = chk.active;
		});
	}

	private void add_option_exclude_pkg_fonts(Gtk.Box vbox){

		var chk = create_checkbutton(vbox, _("Exclude font packages"));

		chk.set_tooltip_text(_("Exclude font packages while re-installing software.\nYou can exclude these if you are restoring fonts using Aptik.\nKeep this unchecked if you want updates."));
		
		chk.active = App.exclude_pkg_fonts;
		chk.toggled.connect(()=>{
			App.exclude_pkg_fonts = chk.active;
		});
	}

	private void add_option_include_pkg_foreign(Gtk.Box vbox){

		var chk = create_checkbutton(vbox, _("Include non-native packages"));

		chk.set_tooltip_text(_("Include packages with foreign architecture\nFor example, 32-bit (i386) packages on a 64-bit (amd64) system\nIncluding these packages can cause problems during restore."));

		chk.active = App.include_pkg_foreign;
		chk.toggled.connect(()=>{
			App.include_pkg_foreign = chk.active;
		});
	}


	private void add_options_home(Gtk.Box vbox){

		var label = new Gtk.Label("<b>%s</b>".printf(Messages.TASK_HOME));
		label.set_use_markup(true);
		label.halign = Align.START;
		//label.margin = 12;
		vbox.add(label);

		var vbox2 = new Gtk.Box(Orientation.VERTICAL, 12);
		vbox2.margin = 12;
		vbox.add(vbox2);

		add_option_exclude_home_encrypted(vbox2);
		
		add_option_exclude_home_hidden(vbox2);
	}

	private void add_option_exclude_home_encrypted(Gtk.Box vbox){

		var chk = create_checkbutton(vbox, _("Exclude encrypted home"));

		chk.set_tooltip_text(_("Exclude home directories which are encrypted"));

		chk.active = App.exclude_home_encrypted;
		chk.toggled.connect(()=>{
			App.exclude_home_encrypted = chk.active;
		});

		chk.sensitive = false;
	}
	
	private void add_option_exclude_home_hidden(Gtk.Box vbox){

		var chk = create_checkbutton(vbox, _("Exclude hidden files"));

		chk.set_tooltip_text(_("Exclude hidden files and directories in home, which contain application configuration files."));

		chk.active = App.exclude_home_hidden;
		chk.toggled.connect(()=>{
			App.exclude_home_hidden = chk.active;
		});
	}
		
	private Gtk.CheckButton create_checkbutton(Gtk.Box box, string text){

		var chk = new Gtk.CheckButton();
		box.add(chk);

		var label = new Gtk.Label(text);
		label.set_use_markup(true);
		chk.add(label);
		
		return chk;
	}
	
	private void init_actions() {

		var expander = new Gtk.Label("");
		expander.vexpand = true;
		vbox_main.add(expander);
		
		var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		vbox_main.add(hbox);

		var bbox = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
		bbox.set_layout(Gtk.ButtonBoxStyle.CENTER);
		bbox.set_homogeneous(false);
		bbox.hexpand = true;
		hbox.add(bbox);

		//btn_backup
		btn_backup = new Gtk.Button.with_label(_("Backup All Items"));
		btn_backup.no_show_all = true;
		btn_backup.set_size_request(150,-1);
		bbox.add(btn_backup);

		btn_backup.clicked.connect(btn_backup_clicked);

		//btn_restore
		btn_restore = new Gtk.Button.with_label(_("Restore All Items"));
		btn_restore.no_show_all = true;
		btn_restore.set_size_request(150,-1);
		bbox.add(btn_restore);

		btn_restore.clicked.connect(btn_restore_clicked);
	}

	public void init_ui_mode() {

		Timeout.add(100, init_ui_mode_delayed);
	}
	
	private bool init_ui_mode_delayed() {

		log_debug("SettingsBox.init_ui_mode_delayed()");

		switch (App.mode){
		case Mode.BACKUP:
			gtk_show(btn_backup);
			gtk_hide(btn_restore);
			break;
			
		case Mode.RESTORE:
			gtk_hide(btn_backup);
			gtk_show(btn_restore);
			break;
		}

		return false;
	}
	
	// events

	private void btn_backup_clicked() {

		log_debug("SettingsBox.btn_backup_clicked()");
		
		// check if no action required ------------------------------
		
		bool none_selected = !App.include_repos && !App.include_cache && !App.include_packages
			&& !App.include_users && !App.include_groups && !App.include_home && !App.include_dconf && !App.include_cron
			&& !App.include_mounts && !App.include_icons && !App.include_themes && !App.include_fonts;

		if (none_selected) {
			string title = _("No Items Selected");
			string msg = _("Select items to backup");
			gtk_messagebox(title, msg, window, false);
			return;
		}

		// save backup ---------------------

		Timeout.add(100, ()=>{

			string cmd = "pkexec aptik --backup-all";

			string basepath = App.basepath;

			if (App.redist){
				basepath = path_combine(App.basepath, "installer");
				cmd += " --redist";
			}

			cmd += " --basepath '%s'".printf(escape_single_quote(basepath));

			cmd += get_cmd_options();

			window.execute(cmd, true, false, false);
			
			return false;
		});
	}

	private string get_cmd_options(){

		string cmd = "";

		if (!App.include_repos){ cmd += " --skip-repos"; }

		if (!App.include_cache){ cmd += " --skip-cache"; }

		if (!App.include_packages){ cmd += " --skip-packages"; }

		if (!App.include_users){ cmd += " --skip-users"; }

		if (!App.include_groups){ cmd += " --skip-groups"; }

		if (!App.include_home){ cmd += " --skip-home"; }

		if (!App.include_mounts){ cmd += " --skip-mounts"; }

		if (!App.include_dconf){ cmd += " --skip-dconf"; }

		if (!App.include_cron){ cmd += " --skip-cron"; }

		if (!App.include_fonts){ cmd += " --skip-fonts"; }

		if (!App.include_icons){ cmd += " --skip-icons"; }

		if (!App.include_themes){ cmd += " --skip-themes"; }

		if (!App.include_themes){ cmd += " --skip-themes"; }

		if (App.include_packages){
			
			if (App.exclude_pkg_icons){ cmd += " --exclude-pkg-icons"; }

			if (App.exclude_pkg_themes){ cmd += " --exclude-pkg-themes"; }

			if (App.exclude_pkg_fonts){ cmd += " --exclude-pkg-fonts"; }

			if (App.include_pkg_foreign){ cmd += " --include-pkg-foreign"; }
		}

		if (App.include_home){

			if (App.exclude_home_hidden){ cmd += " --exclude-home-hidden"; }
		}

		return cmd;
	}

	private void btn_restore_clicked() {

		log_debug("SettingsBox.btn_restore_clicked()");
		
		// check if no action required ------------------------------
		
		bool none_selected = !App.include_repos && !App.include_cache && !App.include_packages
			&& !App.include_users && !App.include_groups && !App.include_home && !App.include_dconf && !App.include_cron
			&& !App.include_mounts && !App.include_icons && !App.include_themes && !App.include_fonts;
		
		if (none_selected) {
			string title = _("No Items Selected");
			string msg = _("All items already installed. No items selected for installation.");
			gtk_messagebox(title, msg, window, false);
			return;
		}

		bool internet_needed = App.include_repos || App.include_packages;

		if (internet_needed && !check_internet_connectivity()) {
			string title = _("Error");
			string msg = Messages.INTERNET_OFFLINE;
			gtk_messagebox(title, msg, window, false);
			return;
		}

		// restore backup ---------------------

		Timeout.add(100, ()=>{

			string cmd = "pkexec aptik --restore-all";

			string basepath = App.basepath;

			if (App.redist){
				basepath = path_combine(App.basepath, "installer");
				cmd += " --redist";
			}

			cmd += " --basepath '%s'".printf(escape_single_quote(basepath));

			cmd += get_cmd_options();

			window.execute(cmd, true, false, false);
			
			return false;
		});
	}


}
