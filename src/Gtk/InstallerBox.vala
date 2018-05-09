/*
 * InstallerBox.vala
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

public class InstallerBox : Gtk.Box {

	protected Gtk.Box vbox_main;

	protected Gtk.Entry entry_appname;
	protected Gtk.Entry entry_outname;
	protected Gtk.Entry entry_outpath;

	protected MainWindow window;

	protected Gtk.SizeGroup sg_buttons;

	public InstallerBox(MainWindow parent) {

		window = parent;

		vbox_main = new Gtk.Box(Orientation.VERTICAL, 12);
		vbox_main.margin = 12;
		this.add(vbox_main);

		init_ui();
	}

	protected virtual void init_ui(){

		init_ui_mode_installer();

		show_all();
	}

	private void init_ui_mode_installer() {

		var sg = new Gtk.SizeGroup(SizeGroupMode.HORIZONTAL);
		
		// header -------------------------
		
		var label = new Gtk.Label(format_text(_("Installer Options"), true, false, true));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_bottom = 12;
		vbox_main.add(label);

		var vbox = new Gtk.Box(Orientation.VERTICAL, 12);
		vbox.margin = 12;
		vbox_main.add(vbox);

		// name --------------------
		
		var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		vbox.add(hbox);

		label = new Gtk.Label(_("Title"));
		label.xalign = 0.0f;
		hbox.add(label);
		sg.add_widget(label);
		
		var entry = new Gtk.Entry();
		entry.hexpand = true;
		hbox.add(entry);
		entry_appname = entry;
		
		entry.text = _("My Tweaks v1.0");

		// file name -----------------------

		hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		vbox.add(hbox);

		label = new Gtk.Label(_("File name"));
		label.xalign = 0.0f;
		hbox.add(label);
		sg.add_widget(label);
		
		entry = new Gtk.Entry();
		entry.hexpand = true;
		hbox.add(entry);
		entry_outname = entry;

		string distname = App.distro.description;

		if (!distname.contains(App.distro.release)){
			distname += "_%s".printf(App.distro.release);
		}

		distname = distname.replace(" ", "_").down();
		
		string outname = "installer-%s-%s.run".printf(distname, App.distro.package_arch);
 
		entry.text = outname;

		// work dir -----------------------

		hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		vbox.add(hbox);

		label = new Gtk.Label(_("Work Folder"));
		label.xalign = 0.0f;
		hbox.add(label);
		sg.add_widget(label);
		
		entry = new Gtk.Entry();
		entry.hexpand = true;
		hbox.add(entry);
		entry.sensitive = false;
		entry_outpath = entry;

		entry.text = path_combine(App.basepath, "installer");

		var button = new Gtk.Button.with_label(_("Open"));
		button.set_tooltip_text(_("Open folder"));
		hbox.add(button);

		button.clicked.connect(() => {

			string inst_path = path_combine(App.basepath, "installer");
			
			string files_path = path_combine(inst_path, "files");
			
			dir_create(files_path);
			
			exo_open_folder(inst_path, false);
		});

		// prepare -------------------------

		hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		hbox.margin_top = 24;
		vbox.add(hbox);

		label = new Gtk.Label(format_text(_("Create backups and click 'Generate Installer' to finish"), false, true, false));
		label.set_use_markup(true);
		hbox.add(label);

		// action -------------------------

		hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		hbox.margin_top = 12;
		vbox.add(hbox);

		var btn_generate = new Gtk.ToggleButton.with_label(_("Generate Installer"));
		hbox.add(btn_generate);
		//sg.add_widget(btn_generate);

		label = new Gtk.Label(format_text(_("Generate installer from backup files"), false, true, false));
		label.set_use_markup(true);
		hbox.add(label);

		btn_generate.clicked.connect(()=>{
			
			Timeout.add(100, ()=>{
				
				string inst_path = path_combine(App.basepath, "installer");
			
				string files_path = path_combine(inst_path, "files");

				string cmd = "pkexec aptik-gen --pack";

				cmd += " --appname '%s'".printf(escape_single_quote(entry_appname.text));

				cmd += " --outname '%s'".printf(escape_single_quote(entry_outname.text));

				cmd += " --outpath '%s'".printf(escape_single_quote(entry_outpath.text));

				cmd += " --basepath '%s'".printf(escape_single_quote(files_path));
				
				window.execute(cmd, true, false, false);
				
				return false;
			});
		});
	}
}
