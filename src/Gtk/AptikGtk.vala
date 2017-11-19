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

public const string AppName = "Aptik NG";
public const string AppShortName = "aptik-gtk";
public const string AppVersion = "17.10";
public const string AppAuthor = "Tony George";
public const string AppAuthorEmail = "teejeetech@gmail.com";

const string GETTEXT_PACKAGE = "";
const string LOCALE_DIR = "/usr/share/locale";

extern void exit(int exit_code);

public AptikGtk App;

public class AptikGtk : GLib.Object {

	public string basepath = "";

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

	// settings ---------------------------------

	public void save_settings(){

		var app_config_path = path_combine(get_user_home(), ".config/aptik-ng");

		var param = path_combine(app_config_path, "basepath");
		file_write(param, basepath);
	}

	public void load_settings(){

		var app_config_path = path_combine(get_user_home(), ".config/aptik-ng");

		var param = path_combine(app_config_path, "basepath");
		if (file_exists(param)){
			basepath = file_read(param);
		}
	}
	
}

