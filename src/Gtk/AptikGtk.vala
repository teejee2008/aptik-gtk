/*
 * AptikGtk.vala
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

using GLib;
using Gtk;
using Gee;
using Json;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JsonHelper;
using TeeJee.ProcessHelper;
using TeeJee.System;
using TeeJee.Misc;
using TeeJee.GtkHelper;

public const string AppName = "Aptik GTK";
public const string AppShortName = "aptik-gtk";
public const string AppVersion = "18.5.1";
public const string AppAuthor = "Tony George";
public const string AppAuthorEmail = "teejeetech@gmail.com";

const string GETTEXT_PACKAGE = "";
const string LOCALE_DIR = "/usr/share/locale";

extern void exit(int exit_code);

public AptikGtk App;

public class AptikGtk : GLib.Object {

	public LinuxDistro distro = null;
	public string basepath = "";

	public Mode mode = Mode.BACKUP;
	
	public bool include_repos = true;
	public bool include_cache = true;
	public bool include_packages = true;
	public bool include_users = true;
	public bool include_groups = true;
	public bool include_home = true;
	public bool include_mounts = true;
	public bool include_icons = true;
	public bool include_themes = true;
	public bool include_fonts = true;
	public bool include_dconf = true;
	public bool include_cron = true;
	public bool include_files = true;
	public bool include_scripts = true;

	public bool exclude_pkg_icons = false;
	public bool exclude_pkg_themes = false;
	public bool exclude_pkg_fonts = false;
	public bool include_pkg_foreign = false;

	public bool exclude_home_encrypted = true;
	public bool exclude_home_hidden = false;

	public bool redist = false;

	public MainWindow main_window;

	public static int main (string[] args) {
		
		set_locale();

		Gtk.init(ref args);

		init_tmp(AppShortName);

		IconManager.init(args, AppShortName);

		App = new AptikGtk();
		App.load_settings();
		App.parse_arguments(args);
		
		var window = new MainWindow();
		window.destroy.connect(Gtk.main_quit);
		window.show_all();

		App.main_window = window;

		//start event loop
		Gtk.main();

		App.save_settings();

		//App.exit_app();

		return 0;
	}

	public AptikGtk(){
		
		distro = new LinuxDistro();
	}

	private static void set_locale() {
		
		Intl.setlocale(GLib.LocaleCategory.MESSAGES, "aptik");
		Intl.textdomain(GETTEXT_PACKAGE);
		Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
		Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALE_DIR);
	}

	public bool parse_arguments(string[] args) {
		
		// parse options
		for (int k = 1; k < args.length; k++) // Oth arg is app path
		{
			switch (args[k].down()) {
			case "--debug":
				LOG_DEBUG = true;
				break;
				
			case "--help":
			case "--h":
			case "-h":
				log_msg(help_message());
				exit(0);
				return true;
				
			default:
				// unknown option; show help and exit
				log_error("%s: %s".printf(_("Unknown option"), args[k]));
				log_msg(help_message());
				exit(1);
				return false;
			}
		}

		return true;
	}

	public static string help_message() {
		
		string msg = "\n" + AppName + " v" + AppVersion + " by %s (%s)".printf(AppAuthor, AppAuthorEmail) + "\n";
		msg += "\n";
		msg += _("Syntax") + ": aptik-gtk [options]\n";
		msg += "\n";
		msg += _("Options") + ":\n";
		msg += "\n";
		msg += "  --debug      " + _("Print debug information") + "\n";
		msg += "  --h[elp]     " + _("Show all options") + "\n";
		msg += "\n";
		return msg;
	}

	public void copy_deb_file(string src_file){
		
		string backup_debs = path_combine(basepath, "debs/files");
		dir_create(backup_debs);
		chmod(backup_debs, "a+rwx");
		
		string file_name = file_basename(src_file);
		string dest_file = path_combine(backup_debs, file_name);
		file_copy(src_file, dest_file);
		
		chmod(dest_file, "a+rw");
	}
	
	// settings ---------------------------------

	public void save_settings(){

		save_param(ConfigParam.BASEPATH, basepath);

		save_param(ConfigParam.INC_REPOS, include_repos.to_string());
		save_param(ConfigParam.INC_CACHE, include_cache.to_string());
		save_param(ConfigParam.INC_PACKAGES, include_packages.to_string());
		save_param(ConfigParam.INC_USERS, include_users.to_string());
		save_param(ConfigParam.INC_GROUPS, include_groups.to_string());
		save_param(ConfigParam.INC_HOME, include_home.to_string());
		save_param(ConfigParam.INC_MOUNTS, include_mounts.to_string());
		save_param(ConfigParam.INC_ICONS, include_icons.to_string());
		save_param(ConfigParam.INC_THEMES, include_themes.to_string());
		save_param(ConfigParam.INC_FONTS, include_fonts.to_string());
		save_param(ConfigParam.INC_DCONF, include_dconf.to_string());
		save_param(ConfigParam.INC_CRON, include_cron.to_string());
		save_param(ConfigParam.INC_FILES, include_files.to_string());
		save_param(ConfigParam.INC_SCRIPTS, include_scripts.to_string());

		save_param(ConfigParam.EXC_PKG_ICONS, exclude_pkg_icons.to_string());
		save_param(ConfigParam.EXC_PKG_THEMES, exclude_pkg_themes.to_string());
		save_param(ConfigParam.EXC_PKG_FONTS, exclude_pkg_fonts.to_string());
		save_param(ConfigParam.EXC_PKG_FOREIGN, include_pkg_foreign.to_string());

		save_param(ConfigParam.EXC_HOME_ENC, exclude_home_encrypted.to_string());
		save_param(ConfigParam.EXC_HOME_HIDDEN, exclude_home_hidden.to_string());
	}

	public void save_param(ConfigParam param, string param_value){

		var app_config_path = path_combine(get_user_home(), ".config/aptik");
		
		var param_file = path_combine(app_config_path, param.to_string().replace("CONFIG_PARAM_",""));
		file_write(param_file, param_value);
	}

	public void load_settings(){

		basepath = load_param(ConfigParam.BASEPATH, "");

		include_repos    = load_param_bool(ConfigParam.INC_REPOS,    true);
		include_cache    = load_param_bool(ConfigParam.INC_CACHE,    true);
		include_packages = load_param_bool(ConfigParam.INC_PACKAGES, true);
		include_users    = load_param_bool(ConfigParam.INC_USERS,    true);
		include_groups   = load_param_bool(ConfigParam.INC_GROUPS,   true);
		include_home     = load_param_bool(ConfigParam.INC_HOME,     true);
		include_mounts   = load_param_bool(ConfigParam.INC_MOUNTS,   true);
		include_icons    = load_param_bool(ConfigParam.INC_ICONS,    true);
		include_themes   = load_param_bool(ConfigParam.INC_THEMES,   true);
		include_fonts    = load_param_bool(ConfigParam.INC_FONTS,    true);
		include_dconf    = load_param_bool(ConfigParam.INC_DCONF,    true);
		include_cron     = load_param_bool(ConfigParam.INC_CRON,     true);
		include_files    = load_param_bool(ConfigParam.INC_FILES,    true);
		include_scripts  = load_param_bool(ConfigParam.INC_SCRIPTS,  true);

		exclude_pkg_icons   = load_param_bool(ConfigParam.EXC_PKG_ICONS,   false);
		exclude_pkg_themes  = load_param_bool(ConfigParam.EXC_PKG_THEMES,  false);
		exclude_pkg_fonts   = load_param_bool(ConfigParam.EXC_PKG_FONTS,   false);
		include_pkg_foreign = load_param_bool(ConfigParam.EXC_PKG_FOREIGN, false);

		exclude_home_encrypted = load_param_bool(ConfigParam.EXC_HOME_ENC, true);
		exclude_home_hidden = load_param_bool(ConfigParam.EXC_HOME_HIDDEN, false);
	}

	public string load_param(ConfigParam param, string default_value){

		var app_config_path = path_combine(get_user_home(), ".config/aptik");

		var param_file = path_combine(app_config_path, param.to_string().replace("CONFIG_PARAM_",""));
		
		if (file_exists(param_file)){
			return file_read(param_file);
		}
		else{
			return default_value;
		}
	}

	public bool load_param_bool(ConfigParam param, bool default_value){

		string txt = load_param(param, default_value.to_string());

		return bool.parse(txt);
	}
}

public enum ConfigParam {
	BASEPATH,
	INC_REPOS,
	INC_CACHE,
	INC_PACKAGES,
	INC_USERS,
	INC_GROUPS,
	INC_HOME,
	INC_MOUNTS,
	INC_ICONS,
	INC_THEMES,
	INC_FONTS,
	INC_DCONF,
	INC_CRON,
	INC_FILES,
	INC_SCRIPTS,
	EXC_PKG_ICONS,
	EXC_PKG_THEMES,
	EXC_PKG_FONTS,
	EXC_PKG_FOREIGN,
	EXC_HOME_ENC,
	EXC_HOME_HIDDEN
}

