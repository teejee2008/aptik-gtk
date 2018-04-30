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
	private Gtk.Paned pane;
	private Gtk.StackSidebar sidebar;
	private Gtk.Stack stack;
	private TermBox term;

	private int window_width = 900;
	private int window_height = 700;

	private GeneralBox box_general;
	private SettingsBox box_all;
	private PackageManager mgr_pkg;
	private RepoManager mgr_repo;
	private PackageCacheManager mgr_cache;
	private ThemeManager mgr_themes;
	private ThemeManager mgr_icons;
	private FontManager mgr_fonts;
	private DconfManager mgr_dconf;
	private CronManager mgr_cron;
	private UserHomeManager mgr_home;
	private MountManager mgr_mounts;
	private UserManager mgr_users;
	private GroupManager mgr_groups;
	
	public MainWindow() {
		
		title = AppName + " v" + AppVersion;
		window_position = WindowPosition.CENTER;
		resizable = false;
		destroy.connect (Gtk.main_quit);
		icon = get_app_icon(16);

		//vbox_main
		vbox_main = new Gtk.Box(Orientation.VERTICAL, 6);
		//vbox_main.margin = 6;
		vbox_main.set_size_request(window_width, window_height);
		this.add(vbox_main);

		check_aptik_version();

		init_ui();

		init_ui_general();

		init_ui_all();

		init_ui_repos();

		init_ui_cache();

		init_ui_packages();

		init_ui_users();

		init_ui_groups();

		init_ui_home();

		init_ui_mounts();

		init_ui_dconf();

		init_ui_cron();

		init_ui_icons();

		init_ui_themes();

		init_ui_fonts();

		init_ui_console();
		
		show_all();
		
		//actions ---------------------------------------------

		//init_section_location();

		//init_section_password();

		//init_section_backup();

		//init_section_header_links();
		
		//txt_basepath.text = App.basepath;

		//termwin = new TerminalWindow.with_parent(this, false, true);
		//termwin.start_shell();	
	
		//init_section_toolbar_bottom();

		//init_section_status();
	}

	private void check_aptik_version(){

		if (!cmd_exists("aptik")){

			string txt = _("Aptik Not Installed");
			
			string msg = "%s\n".printf(
				_("Could not find console application. Please install the 'aptik' package.")
			);

			gtk_messagebox(txt, msg, this, true);
			exit(1);
		}
		
		string std_out, std_err;
		exec_sync("aptik --version", out std_out, out std_err);
		string aptik_version = std_out.strip();
		
		if (AppVersion != aptik_version){
			
			string txt = _("Version Mismatch");
			
			string msg = "%s\n\n%s (v%s)\n\n%s (v%s)\n".printf(
				_("GUI version does not match console version. Please install same version of 'aptik' and 'aptik-gtk' packages."),
				_("aptik-gtk"), AppVersion,
				_("aptik"), aptik_version
			);

			gtk_messagebox(txt, msg, this, true);
			exit(1);
		}
	}

	private void init_ui(){

		pane = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
		//pane.margin = 6;
		vbox_main.add(pane);

		sidebar = new Gtk.StackSidebar();
		sidebar.set_size_request(120,-1);
		sidebar.expand = true;
		pane.pack1(sidebar, false, false); //resize, shrink

		sidebar.button_release_event.connect(sidebar_button_release);

		stack = new Gtk.Stack();
		stack.set_transition_duration(100);
        stack.set_transition_type(Gtk.StackTransitionType.SLIDE_UP_DOWN);
        stack.expand = true;
		pane.pack2(stack, true, true); //resize, shrink

		pane.wide_handle = false;
		
		sidebar.set_stack(stack);
	}

	private bool sidebar_button_release(Gdk.EventButton event){

		log_debug("sidebar: %s".printf(stack.visible_child_name));

		switch(stack.visible_child_name){
		case "all":
			box_all.init_ui_mode();
			break;
		case "repos":
			if (mgr_repo.items.size == 0){
				mgr_repo.init_ui_mode(App.mode);
			}
			break;
		case "cache":
			if (mgr_cache.items.size == 0){
				mgr_cache.init_ui_mode(App.mode);
			}
			break;
		case "packages":
			if (mgr_pkg.items.size == 0){
				mgr_pkg.init_ui_mode(App.mode);
			}
			break;
		case "themes":
			if (mgr_themes.items.size == 0){
				mgr_themes.init_ui_mode(App.mode);
			}
			break;
		case "icons":
			if (mgr_icons.items.size == 0){
				mgr_icons.init_ui_mode(App.mode);
			}
			break;
		case "fonts":
			if (mgr_fonts.items.size == 0){
				mgr_fonts.init_ui_mode(App.mode);
			}
			break;
		case "users":
			if (mgr_users.items.size == 0){
				mgr_users.init_ui_mode(App.mode);
			}
			break;
		case "groups":
			if (mgr_groups.items.size == 0){
				mgr_groups.init_ui_mode(App.mode);
			}
			break;
		case "dconf":
			if (mgr_dconf.items.size == 0){
				mgr_dconf.init_ui_mode(App.mode);
			}
			break;
		case "cron":
			if (mgr_cron.items.size == 0){
				mgr_cron.init_ui_mode(App.mode);
			}
			break;
		case "home":
			if (mgr_home.items.size == 0){
				mgr_home.init_ui_mode(App.mode);
			}
			break;
		case "mounts":
			if (mgr_mounts.items.size == 0){
				mgr_mounts.init_ui_mode(App.mode);
			}
			break;
		}

		return false;
	}

	private void init_ui_general(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "general", _("General"));

		box_general = new GeneralBox(this);
		vbox.add(box_general);

		box_general.mode_changed.connect(()=>{
			
			mgr_repo.items.clear();
			mgr_cache.items.clear();
			mgr_pkg.items.clear();
			mgr_icons.items.clear();
			mgr_themes.items.clear();
			mgr_fonts.items.clear();
			mgr_users.items.clear();
			mgr_groups.items.clear();
			mgr_dconf.items.clear();
			mgr_cron.items.clear();
			mgr_home.items.clear();
			mgr_mounts.items.clear();
		});
	}

	private void init_ui_all(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "all", _("All Items"));

		box_all = new SettingsBox(this);
		vbox.add(box_all);
	}
	
	private void init_ui_repos(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "repos", _("Repos"));

		mgr_repo = new RepoManager(this);
		vbox.add(mgr_repo);
	}
	
	private void init_ui_cache(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "cache", _("Cache"));

		mgr_cache = new PackageCacheManager(this);
		vbox.add(mgr_cache);
	}

	private void init_ui_packages(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "packages", _("Packages"));

		mgr_pkg = new PackageManager(this);
		vbox.add(mgr_pkg);
	}

	private void init_ui_users(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "users", _("Users"));

		mgr_users = new UserManager(this);
		vbox.add(mgr_users);
	}

	private void init_ui_groups(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "groups", _("Groups"));

		mgr_groups = new GroupManager(this);
		vbox.add(mgr_groups);
	}

	private void init_ui_home(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "home", _("Home"));

		mgr_home = new UserHomeManager(this);
		vbox.add(mgr_home);
	}

	private void init_ui_mounts(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "mounts", _("Mounts"));

		mgr_mounts = new MountManager(this);
		vbox.add(mgr_mounts);
	}

	private void init_ui_dconf(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "dconf", _("DConf"));

		mgr_dconf = new DconfManager(this);
		vbox.add(mgr_dconf);
	}

	private void init_ui_cron(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "cron", _("Cron"));

		mgr_cron = new CronManager(this);
		vbox.add(mgr_cron);
	}

	private void init_ui_icons(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "icons", _("Icons"));

		mgr_icons = new ThemeManager(this, "icons");
		vbox.add(mgr_icons);
	}

	private void init_ui_themes(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "themes", _("Themes"));

		mgr_themes = new ThemeManager(this, "themes");
		vbox.add(mgr_themes);
	}

	private void init_ui_fonts(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "fonts", _("Fonts"));

		mgr_fonts = new FontManager(this);
		vbox.add(mgr_fonts);
	}

	private void init_ui_console(){

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.margin = 6;
		
		stack.add_titled(vbox, "console", _("Console"));

		term = new TermBox(this);
		term.expand = true;
		vbox.add(term);
		
		term.start_shell();

	}

	public void execute(string cmd){
		
		stack.visible_child_name = "console";

		sidebar.sensitive = false;
		
		term.child_exited.connect(()=>{
			sidebar.sensitive = true;
		});

		term.feed_command(cmd);
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
		dialog.website = "https://github.com/teejee2008/aptik";
		dialog.website_label = "https://github.com/teejee2008/aptik";

		dialog.initialize();
		dialog.show_all();
	}
	
}

public enum Mode{
	BACKUP,
	RESTORE,
	MANAGE
}

