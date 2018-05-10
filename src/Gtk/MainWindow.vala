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
	
	private string current_child;
	private bool switch_to_terminal;
	private bool show_action_result_on_exit;
	private bool refresh_on_exit;
	
	private int window_width = 900;
	private int window_height = 700;

	private GeneralBox box_general;
	private InstallerBox box_inst;
	private SettingsBox box_all;
	private PackageManager mgr_pkg;
	private RepoManager mgr_repo;
	private PackageCacheManager mgr_cache;
	private UserManager mgr_users;
	private GroupManager mgr_groups;
	private UserHomeManager mgr_home;
	private MountManager mgr_mounts;
	private DconfManager mgr_dconf;
	private CronManager mgr_cron;
	private ThemeManager mgr_themes;
	private ThemeManager mgr_icons;
	private FontManager mgr_fonts;
	private FilesManager mgr_files;
	private ScriptManager mgr_scripts;
	private TermBox term;
	
	private string pages = "general installer all repos cache packages users groups home mounts dconf cron icons themes fonts files scripts console";

	public signal void mode_changed();

	public signal void guimode_changed();
	
	public signal void term_action_complete();

	private const Gtk.TargetEntry[] targets = {
		{ "text/uri-list", 0, 0}
	};
	
	public MainWindow() {
		
		title = AppName + " v" + AppVersion;
		window_position = WindowPosition.CENTER;
		resizable = true;
		destroy.connect (Gtk.main_quit);
		icon = get_app_icon(16);

		//vbox_main
		vbox_main = new Gtk.Box(Orientation.VERTICAL, 6);
		//vbox_main.margin = 6;
		vbox_main.set_size_request(window_width, window_height);
		this.add(vbox_main);

		check_aptik_version();

		init_ui();

		// events -----------------------------

		attach_drag_drop_handlers();

		mode_changed.connect(on_mode_changed);

		guimode_changed.connect(on_guimode_changed);

		// initailize --------------------------

		guimode_changed();
		//on_guimode_changed();
		
		show_all();

		Timeout.add(100, ()=>{

			term.shell_exited.connect(on_term_shell_exited);
			
			term.start_shell(true);
			
			return false;
		});
	}

	private void on_term_shell_exited(){
		
		exit(1);
	}

	private void attach_drag_drop_handlers(){
		Gtk.drag_dest_set (this,Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);
		drag_data_received.connect(on_drag_data_received);
	}

	private void on_drag_data_received (Gdk.DragContext drag_context, int x, int y, Gtk.SelectionData data, uint info, uint time) {

		int count = 0;

        foreach(string uri in data.get_uris()){
			
			string file = uri.replace("file://","").replace("file:/","");
			file = Uri.unescape_string (file);

			if (file.has_suffix(".deb")){
				App.copy_deb_file(file);
				count++;
			}
		}

		if (count > 0){
			string msg = _("DEB files were copied to backup location.");
			gtk_messagebox(_("Files Copied"),msg,this,false);
		}

        Gtk.drag_finish (drag_context, true, false, time);
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

		// init classes ---------------------------------
		
		box_general = new GeneralBox(this);

		box_inst = new InstallerBox(this);

		box_all = new SettingsBox(this);

		mgr_repo = new RepoManager(this);

		mgr_cache = new PackageCacheManager(this);

		mgr_pkg = new PackageManager(this);

		mgr_users = new UserManager(this);

		mgr_groups = new GroupManager(this);

		mgr_home = new UserHomeManager(this);

		mgr_mounts = new MountManager(this);

		mgr_dconf = new DconfManager(this);

		mgr_cron = new CronManager(this);

		mgr_icons = new ThemeManager(this, "icons");

		mgr_themes = new ThemeManager(this, "themes");

		mgr_fonts = new FontManager(this);

		mgr_files = new FilesManager(this);

		mgr_scripts = new ScriptManager(this);

		term = new TermBox(this);
		term.expand = true;
	}

	private bool sidebar_button_release(Gdk.EventButton event){

		log_debug("MainWindow: sidebar_button_release(): %s".printf(stack.visible_child_name));

		if (App.basepath.length == 0){
			
			string txt = _("Backup Path Not Selected");
			string msg = _("Select backup path");
			gtk_messagebox(txt, msg, this, true);
			stack.visible_child_name = "general";
			return false;
		}

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
		case "files":
			mgr_files.init_ui_mode(App.mode);
			break;
		case "scripts":
			mgr_scripts.init_ui_mode(App.mode);
			break;
		}

		return false;
	}
	
	private void on_mode_changed(){

		log_debug("MainWindow: on_mode_changed()");

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
		//mgr_files.items.clear(); // doesn't change with mode
		//mgr_scripts.items.clear(); // doesn't change with mode

		mgr_cache.sensitive = !App.redist;
		mgr_users.sensitive = !App.redist;
		mgr_groups.sensitive = !App.redist;
	}

	private void on_guimode_changed(){

		log_debug("MainWindow: on_guimode_changed()");

		switch(App.guimode){
			
		case GUIMode.EASY:
		
			foreach(string page_name in pages.split(" ")){

				if (page_name.strip().length > 0){ remove_page(page_name); }
			}

			foreach(string page_name in "general all console".split(" ")){

				if (page_name.strip().length == 0){ continue; }
				
				add_page(page_name);
			}
			
			break;
			
		case GUIMode.ADVANCED:
		
			foreach(string page_name in pages.split(" ")){

				if (page_name.strip().length > 0){ remove_page(page_name); }
			}

			string active_pages = "general installer repos cache packages users groups home mounts dconf cron icons themes fonts console";

			if (!App.redist){
				active_pages = active_pages.replace("installer","");
			}
			else{
				active_pages = active_pages.replace("cache","").replace("users","").replace("groups","");
			}
			
			foreach(string page_name in active_pages.split(" ")){

				if (page_name.strip().length == 0){ continue; }
				
				add_page(page_name);
			}

			break;
			
		case GUIMode.EXPERT:

			foreach(string page_name in pages.split(" ")){

				if (page_name.strip().length > 0){ remove_page(page_name); }
			}

			string active_pages = "general installer repos cache packages users groups home mounts dconf cron icons themes fonts files scripts console";

			if (!App.redist){
				active_pages = active_pages.replace("installer","");
			}
			else{
				active_pages = active_pages.replace("cache","").replace("users","").replace("groups","");
			}
			
			foreach(string page_name in active_pages.split(" ")){

				if (page_name.strip().length == 0){ continue; }
				
				add_page(page_name);
			}
			
			break;
		}
	}

	private void add_page(string page_name){
		
		switch(page_name){
		case "general":
			stack.add_titled(box_general, "general", _("General"));
			break;
		case "installer":
			stack.add_titled(box_inst, "installer", _("Installer"));
			break;
		case "all":
			if (App.guimode == GUIMode.EASY){
				if (App.mode == Mode.BACKUP){
					stack.add_titled(box_all, "all", _("Backup"));
				}
				else{
					stack.add_titled(box_all, "all", _("Restore"));
				}
			}
			else{
				stack.add_titled(box_all, "all", _("All Items"));
			}
			break;
		case "repos":
			stack.add_titled(mgr_repo, "repos", _("Repos"));
			break;
		case "cache":
			stack.add_titled(mgr_cache, "cache", _("Cache"));
			break;
		case "packages":
			stack.add_titled(mgr_pkg, "packages", _("Packages"));
			break;
		case "users":
			stack.add_titled(mgr_users, "users", _("Users"));
			break;
		case "groups":
			stack.add_titled(mgr_groups, "groups", _("Groups"));
			break;
		case "home":
			stack.add_titled(mgr_home, "home", _("Home"));
			break;
		case "mounts":
			stack.add_titled(mgr_mounts, "mounts", _("Mounts"));
			break;
		case "dconf":
			stack.add_titled(mgr_dconf, "dconf", _("DConf"));
			break;
		case "cron":
			stack.add_titled(mgr_cron, "cron", _("Cron"));
			break;
		case "icons":
			stack.add_titled(mgr_icons, "icons", _("Icons"));
			break;
		case "themes":
			stack.add_titled(mgr_themes, "themes", _("Themes"));
			break;
		case "fonts":
			stack.add_titled(mgr_fonts, "fonts", _("Fonts"));
			break;
		case "files":
			stack.add_titled(mgr_files, "files", _("Files"));
			break;
		case "scripts":
			stack.add_titled(mgr_scripts, "scripts", _("Scripts"));
			break;
		case "console":
			stack.add_titled(term, "console", _("Terminal"));
			break;
		}
	}

	private void remove_page(string page_name){

		var child = stack.get_child_by_name(page_name);
		
		if (child != null){ stack.remove(child);}
	}

	public void clear_page(string page_name){
		
		switch(page_name){
		case "repos":
			mgr_repo.items.clear();
			break;
		case "cache":
			mgr_cache.items.clear();
			break;
		case "packages":
			mgr_pkg.items.clear();
			break;
		case "users":
			mgr_users.items.clear();
			break;
		case "groups":
			mgr_groups.items.clear();
			break;
		case "home":
			mgr_home.items.clear();
			break;
		case "mounts":
			mgr_mounts.items.clear();
			break;
		case "dconf":
			mgr_dconf.items.clear();
			break;
		case "cron":
			mgr_cron.items.clear();
			break;
		case "icons":
			mgr_icons.items.clear();
			break;
		case "themes":
			mgr_themes.items.clear();
			break;
		case "fonts":
			mgr_fonts.items.clear();
			break;
		case "files":
			mgr_files.items.clear();
			break;
		case "scripts":
			mgr_scripts.items.clear();
			break;
		}
	}

	// actions ------------------------------
	
	public void execute(string cmd, bool _switch_to_terminal, bool _show_action_result_on_exit, bool _refresh_on_exit){

		term.init_bash();

		current_child = stack.visible_child_name;

		switch_to_terminal = _switch_to_terminal;

		show_action_result_on_exit = _show_action_result_on_exit;

		refresh_on_exit = _refresh_on_exit;

		if (switch_to_terminal){
			
			stack.visible_child_name = "console";
		}
		
		if (term.has_running_process){
			
			string txt = _("Terminal Busy");
			string msg = _("A process is running in terminal. Please wait for it to complete.");
			gtk_messagebox(txt, msg, this, true);
			stack.visible_child_name = "console";
			return;
		}

		sidebar.sensitive = false;

		term.feed_command(cmd, true, true);

		term.child_exited.connect(on_term_child_exit);
	}

	public void on_term_child_exit(){

		sidebar.sensitive = true;
		
		if (App.mode == Mode.RESTORE){
				
			clear_page(current_child);

			if (current_child == "packages"){

				clear_page("fonts");
				clear_page("icons");
				clear_page("themes");
			}
		}

		if (!switch_to_terminal){

			var box = (ManagerBox) stack.get_child_by_name(current_child);

			bool refresh = false;
			if ((App.mode == Mode.RESTORE) || (current_child == "files") || (current_child == "scripts")){
				refresh = true;
			}

			bool success = (get_status() == 0);
			box.finish_action(show_action_result_on_exit, success, refresh_on_exit);

			if (!success){
				stack.visible_child_name = "console";
			}
		}

		term.child_exited.disconnect(on_term_child_exit);
	}

	public int get_status(){
		
		return term.get_status();
	}
	
	
	public void btn_show_about_window(){
		
		var dialog = new AboutWindow(this);

		dialog.authors = {
			"Tony George:teejeetech@gmail.com"
		};

		dialog.contributors = {
			//"Shem Pasamba (Proxy support for package downloads):shemgp@gmail.com"
		};

		dialog.third_party = {
			"Numix project (various icons):https://numixproject.org/",
			"Elementary project (various icons):https://github.com/elementary/icons",
			"Tango project (various icons):http://tango.freedesktop.org/Tango_Desktop_Project",
			"Arc Icon Theme (various icons):https://github.com/horst3180/arc-icon-theme"
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
		dialog.copyright = "Copyright © 2012-2018";
		dialog.author_name = AppAuthor;
		dialog.author_email = AppAuthorEmail;
		dialog.version = AppVersion;
		dialog.logo = get_app_icon(128); 

		dialog.license = "This program is free for personal and commercial use and comes with absolutely no warranty. You use this program entirely at your own risk. The author will not be liable for any damages arising from the use of this program.";
		dialog.website = "https://github.com/teejee2008/aptik";
		dialog.website_label = "https://github.com/teejee2008/aptik";

		dialog.initialize();
		dialog.show_all();
	}

	public void set_sidebar_sensitive(bool _sensitive){
		sidebar.sensitive = _sensitive;
	}
}

public enum Mode{
	BACKUP,
	RESTORE,
	MANAGE
}

public enum GUIMode{
	EASY,
	ADVANCED,
	EXPERT
}
