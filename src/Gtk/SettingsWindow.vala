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

public class SettingsWindow : Window {

	private Gtk.Box vbox_main;

	private int def_width = 700;
	private int def_height = 450;
	private uint tmr_init = 0;
	
	private MainWindow main_window;

	// init -------------------------
	
	public SettingsWindow(MainWindow parent) {
		
		set_transient_for(parent);
		set_modal(true);

		this.destroy.connect(()=>{
			parent.present();
		});

		main_window = parent;
		
		init_window();
	}

	public void init_window () {
	
		window_position = WindowPosition.CENTER;
		set_default_size (def_width, def_height);
		icon = get_app_icon(16);
		resizable = true;
		deletable = true;
		
		vbox_main = new Gtk.Box (Orientation.VERTICAL, 6);
		vbox_main.margin = 6;
		this.add(vbox_main);

		var hbox = new Gtk.Box(Orientation.HORIZONTAL, 6);
		//hbox.margin_left = 6;
		vbox_main.add(hbox);

		init_options(hbox);

		init_actions();
		
		show_all();

		tmr_init = Timeout.add(100, init_delayed);
	}

	private bool init_delayed() {
		
		/* any actions that need to run after window has been displayed */
		
		if (tmr_init > 0) {
			Source.remove(tmr_init);
			tmr_init = 0;
		}

		return false;
	}

	private void init_options(Gtk.Box box) {

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		box.add(vbox);
		
		var label = new Label("<b>" + _("Backup &amp; Restore") + "</b>");
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_bottom = 6;
		vbox.add(label);

		var vbox2 = new Gtk.Box(Orientation.VERTICAL, 3);
		vbox2.margin_left = 6;
		vbox.add(vbox2);

		add_options_for_items(vbox2);

		// ---------------------
		
		var separator = new Gtk.Separator(Gtk.Orientation.VERTICAL);
		separator.margin_left = 24;
		box.add(separator);

		// ---------------------

		var vbox3 = new Gtk.Box(Orientation.VERTICAL, 6);
		box.add(vbox3);

		add_options_packages(vbox3);

		add_options_home(vbox3);
	}

	private void add_options_for_items(Gtk.Box vbox){

		var chk_repo = create_checkbutton(vbox, Messages.TASK_REPOS);

		chk_repo.active = main_window.include_repos;
		chk_repo.toggled.connect(()=>{
			main_window.include_repos = chk_repo.active;
		});

		// ----------------------------
		
		var chk_cache = create_checkbutton(vbox, Messages.TASK_CACHE);

		chk_cache.active = main_window.include_cache;
		chk_cache.toggled.connect(()=>{
			main_window.include_cache = chk_cache.active;
		});

		// ----------------------------
		
		var chk_packages = create_checkbutton(vbox, Messages.TASK_PACKAGES);

		chk_packages.active = main_window.include_packages;
		chk_packages.toggled.connect(()=>{
			main_window.include_packages = chk_packages.active;
		});

		// ----------------------------
		
		var chk_users = create_checkbutton(vbox, Messages.TASK_USERS);
	
		chk_users.active = main_window.include_users;
		chk_users.toggled.connect(()=>{
			main_window.include_users = chk_users.active;
		});

		// ----------------------------

		var chk_groups = create_checkbutton(vbox, Messages.TASK_GROUPS);

		chk_groups.active = main_window.include_groups;
		chk_groups.toggled.connect(()=>{
			main_window.include_groups = chk_groups.active;
		});

		// ----------------------------

		var chk_home = create_checkbutton(vbox, Messages.TASK_HOME);

		chk_home.active = main_window.include_home;
		chk_home.toggled.connect(()=>{
			main_window.include_home = chk_home.active;
		});

		// ----------------------------

		var chk_mounts = create_checkbutton(vbox, Messages.TASK_MOUNTS);

		chk_mounts.active = main_window.include_mounts;
		chk_mounts.toggled.connect(()=>{
			main_window.include_mounts = chk_mounts.active;
		});

		// ----------------------------

		var chk_icons = create_checkbutton(vbox, Messages.TASK_ICONS);

		chk_icons.active = main_window.include_icons;
		chk_icons.toggled.connect(()=>{
			main_window.include_icons = chk_icons.active;
		});

		// ----------------------------

		var chk_themes = create_checkbutton(vbox, Messages.TASK_THEMES);

		chk_themes.active = main_window.include_themes;
		chk_themes.toggled.connect(()=>{
			main_window.include_themes = chk_themes.active;
		});

		// ----------------------------

		var chk_fonts = create_checkbutton(vbox, Messages.TASK_FONTS);

		chk_fonts.active = main_window.include_fonts;
		chk_fonts.toggled.connect(()=>{
			main_window.include_fonts = chk_fonts.active;
		});

		// ----------------------------

		var chk_dconf = create_checkbutton(vbox, Messages.TASK_DCONF);

		chk_dconf.active = main_window.include_dconf;
		chk_dconf.toggled.connect(()=>{
			main_window.include_dconf = chk_dconf.active;
		});

		// ----------------------------

		var chk_cron = create_checkbutton(vbox, Messages.TASK_CRON);

		chk_cron.active = main_window.include_cron;
		chk_cron.toggled.connect(()=>{
			main_window.include_cron = chk_cron.active;
		});

		// ----------------------------
	}

	private void add_options_packages(Gtk.Box vbox){

		var label = new Gtk.Label("<b>%s</b>".printf(Messages.TASK_PACKAGES));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_bottom = 6;
		vbox.add(label);

		var vbox2 = new Gtk.Box(Orientation.VERTICAL, 3);
		vbox2.margin_left = 6;
		vbox.add(vbox2);

		add_option_exclude_pkg_foreign(vbox2);
		
		add_option_exclude_pkg_themes(vbox2);

		add_option_exclude_pkg_icons(vbox2);

		add_option_exclude_pkg_fonts(vbox2);
	}

	private void add_option_exclude_pkg_themes(Gtk.Box vbox){

		var chk = create_checkbutton(vbox, _("Exclude theme packages"));

		chk.set_tooltip_text(_("Exclude theme packages while re-installing software.\nYou can exclude these if you are restoring themes using Aptik.\nKeep this unchecked if you want updates."));

		chk.active = main_window.exclude_pkg_themes;
		chk.toggled.connect(()=>{
			main_window.exclude_pkg_themes = chk.active;
		});
	}

	private void add_option_exclude_pkg_icons(Gtk.Box vbox){

		var chk = create_checkbutton(vbox, _("Exclude icon packages"));

		chk.set_tooltip_text(_("Exclude icon packages while re-installing software.\nYou can exclude these if you are restoring icons using Aptik.\nKeep this unchecked if you want updates."));

		chk.active = main_window.exclude_pkg_icons;
		chk.toggled.connect(()=>{
			main_window.exclude_pkg_icons = chk.active;
		});
	}

	private void add_option_exclude_pkg_fonts(Gtk.Box vbox){

		var chk = create_checkbutton(vbox, _("Exclude font packages"));

		chk.set_tooltip_text(_("Exclude font packages while re-installing software.\nYou can exclude these if you are restoring fonts using Aptik.\nKeep this unchecked if you want updates."));
		
		chk.active = main_window.exclude_pkg_fonts;
		chk.toggled.connect(()=>{
			main_window.exclude_pkg_fonts = chk.active;
		});
	}

	private void add_option_exclude_pkg_foreign(Gtk.Box vbox){

		var chk = create_checkbutton(vbox, _("Exclude non-native packages"));

		chk.set_tooltip_text(_("Exclude packages with foreign architecture\nFor example, 32-bit (i386) packages on a 64-bit (amd64) system"));

		chk.active = main_window.exclude_pkg_foreign;
		chk.toggled.connect(()=>{
			main_window.exclude_pkg_foreign = chk.active;
		});
	}

	private void add_options_home(Gtk.Box vbox){

		var label = new Gtk.Label("<b>%s</b>".printf(Messages.TASK_HOME));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_bottom = 6;
		vbox.add(label);

		var vbox2 = new Gtk.Box(Orientation.VERTICAL, 3);
		vbox2.margin_left = 6;
		vbox.add(vbox2);

		add_option_exclude_home_encrypted(vbox2);
		
		add_option_exclude_home_hidden(vbox2);
	}

	private void add_option_exclude_home_encrypted(Gtk.Box vbox){

		var chk = create_checkbutton(vbox, _("Exclude encrypted home"));

		chk.set_tooltip_text(_("Exclude home directories which are encrypted"));

		chk.active = main_window.exclude_home_encrypted;
		chk.toggled.connect(()=>{
			main_window.exclude_home_encrypted = chk.active;
		});

		chk.sensitive = false;
	}
	
	private void add_option_exclude_home_hidden(Gtk.Box vbox){

		var chk = create_checkbutton(vbox, _("Exclude hidden files"));

		chk.set_tooltip_text(_("Exclude hidden files and directories in home, which contain application configuration files."));

		chk.active = main_window.exclude_pkg_foreign;
		chk.toggled.connect(()=>{
			main_window.exclude_pkg_foreign = chk.active;
		});
	}
		
	private Gtk.CheckButton create_checkbutton(Gtk.Box box, string label){

		var chk = new Gtk.CheckButton.with_label(label);
		box.add(chk);
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

		// btn_close
		var button = new Gtk.Button.with_label(_("Ok"));
		bbox.pack_start(button, true, true, 0);

		button.clicked.connect(() => {
			this.close();
		});
	}

	// events
}
