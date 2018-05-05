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
	protected Gtk.Box vbox_installer;
	protected Gtk.Box hbox_installer_mode;

	protected Gtk.ToggleButton btn_backup;
	protected Gtk.ToggleButton btn_restore;
	protected Gtk.ToggleButton btn_installer;

	protected Gtk.Entry entry_location;
	protected Gtk.Entry entry_appname;
	protected Gtk.Entry entry_outname;
	protected Gtk.Entry entry_outpath;

	protected MainWindow window;

	protected Gtk.SizeGroup sg_buttons;

	public GeneralBox(MainWindow parent) {

		window = parent;

		vbox_main = new Gtk.Box(Orientation.VERTICAL, 12);
		vbox_main.margin = 6;
		this.add(vbox_main);

		init_ui();
	}

	protected virtual void init_ui(){

		sg_buttons = new Gtk.SizeGroup(SizeGroupMode.HORIZONTAL);

		init_ui_location();
		
		init_ui_mode_gui_mode();

		init_ui_mode();

		init_ui_mode_installer();

		add_links();
		
		show_all();
	}

	private void init_ui_location() {

		var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
		vbox_main.add(vbox);
		
		// header
		var label = new Gtk.Label(format_text(_("Select Backup Path"), true, false, true));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_top = 12;
		//label.margin_bottom = 12;
		vbox.pack_start(label, false, true, 0);

		var vbox2 = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
		vbox2.margin = 12;
		vbox.add(vbox2);
		vbox = vbox2;
		
		var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		vbox.add(hbox);

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
			window,
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
			gtk_messagebox(title, msg, window, false);
			return false;
		}
	}

	private void init_ui_mode_gui_mode() {

		var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
		vbox_main.add(vbox);
		
		// header
		var label = new Gtk.Label(format_text(_("Select UI Mode"), true, false, true));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_top = 12;
		//label.margin_bottom = 12;
		vbox.add(label);

		var vbox2 = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
		vbox2.margin = 12;
		vbox.add(vbox2);
		vbox = vbox2;
		
		// backup --------------------------------

		var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		vbox.add(hbox);
		
		var button = new Gtk.ToggleButton.with_label(_("Easy"));
		hbox.add(button);
		
		sg_buttons.add_widget(button);
		var btn_easy = button;
		
		label = new Gtk.Label(format_text(_("Backup and Restore with a single click"), false, true, false));
		label.set_use_markup(true);
		hbox.add(label);

		// restore -------------------------

		hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		vbox.add(hbox);

		button = new Gtk.ToggleButton.with_label(_("Advanced"));
		hbox.add(button);
		
		sg_buttons.add_widget(button);
		var btn_advanced = button;

		label = new Gtk.Label(format_text(_("Show advanced options for individual items"), false, true, false));
		label.set_use_markup(true);
		hbox.add(label);

		// installer -------------------------

		hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		vbox.add(hbox);

		button = new Gtk.ToggleButton.with_label(_("Expert"));
		hbox.add(button);
		
		sg_buttons.add_widget(button);
		var btn_expert = button;

		label = new Gtk.Label(format_text(_("Show all advanced options"), false, true, false));
		label.set_use_markup(true);
		hbox.add(label);

		// events -----------------------
		
		btn_easy.clicked.connect(() => {
			if (btn_easy.active){
				btn_advanced.active = false;
				btn_expert.active = false;
				App.guimode = GUIMode.EASY;
				window.guimode_changed();
			}
		});

		btn_advanced.clicked.connect(() => {
			if (btn_advanced.active){
				btn_easy.active = false;
				btn_expert.active = false;
				App.guimode = GUIMode.ADVANCED;
				window.guimode_changed();
			}
		});
		
		btn_expert.clicked.connect(() => {
			if (btn_expert.active){
				btn_easy.active = false;
				btn_advanced.active = false;
				App.guimode = GUIMode.EXPERT;
				window.guimode_changed();
			}
		});

		window.guimode_changed.connect(()=>{

			if (cmd_exists("aptik-gen")){
				gtk_show(hbox_installer_mode);
			}
			else{
				gtk_hide(hbox_installer_mode);
			}

			switch(App.guimode){
				
			case GUIMode.EASY:
			
				hbox_installer_mode.sensitive = false;
				break;
				
			case GUIMode.ADVANCED:
			case GUIMode.EXPERT:
			
				hbox_installer_mode.sensitive = true;
				break;
			}
		});

		btn_easy.active = true;
		
		btn_easy.grab_focus();
	}

	private void init_ui_mode() {

		var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
		vbox_main.add(vbox);
		
		// header
		var label = new Gtk.Label(format_text(_("Select Backup Mode"), true, false, true));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_top = 12;
		//label.margin_bottom = 12;
		vbox.add(label);

		var vbox2 = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
		vbox2.margin = 12;
		vbox.add(vbox2);
		vbox = vbox2;
		
		// backup --------------------------------

		var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		vbox.add(hbox);
		
		var button = new Gtk.ToggleButton.with_label(_("Backup"));
		button.set_tooltip_text(_("Create backups for current system"));
		hbox.add(button);
		
		sg_buttons.add_widget(button);
		btn_backup = button;
		
		label = new Gtk.Label(format_text(_("Create backups for current system"), false, true, false));
		label.set_use_markup(true);
		hbox.add(label);

		// restore -------------------------

		hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		vbox.add(hbox);

		button = new Gtk.ToggleButton.with_label(_("Restore"));
		button.set_tooltip_text(_("Restore backups on new system"));
		hbox.add(button);
		
		sg_buttons.add_widget(button);
		btn_restore = button;

		label = new Gtk.Label(format_text(_("Restore backups on new system"), false, true, false));
		label.set_use_markup(true);
		hbox.add(label);

		// installer -------------------------

		hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		vbox.add(hbox);
		hbox_installer_mode = hbox;
		
		button = new Gtk.ToggleButton.with_label(_("Create Installer"));
		button.set_tooltip_text(_("Create installer to share with friends"));
		hbox.add(button);
		
		sg_buttons.add_widget(button);
		btn_installer = button;

		label = new Gtk.Label(format_text(_("Create installer to share with friends"), false, true, false));
		label.set_use_markup(true);
		hbox.add(label);

		// events -----------------------
		
		btn_backup.clicked.connect(btn_backup_clicked);

		btn_restore.clicked.connect(btn_restore_clicked);
		
		btn_installer.clicked.connect(btn_installer_clicked);

		// set initial state ---------------------
		
		btn_backup.active = (App.mode == Mode.BACKUP) && !App.redist;
		
		btn_restore.active = (App.mode == Mode.RESTORE);

		btn_installer.active = (App.mode == Mode.BACKUP) && App.redist;

		// focus ----------------------------------
		
		btn_backup.grab_focus();
	}

	public void btn_backup_clicked(){

		if (!btn_backup.active){ return; }
		
		log_debug("GeneralBox: btn_backup_clicked()");

		App.mode = Mode.BACKUP;
		App.redist = false;

		btn_backup.active = true;
		
		btn_restore.active = false;

		btn_installer.active = false;

		window.mode_changed();
		window.guimode_changed();
	}

	public void btn_restore_clicked(){

		if (!btn_restore.active){ return; }
		
		log_debug("GeneralBox: btn_restore_clicked()");

		App.mode = Mode.RESTORE;
		App.redist = false;

		btn_backup.active = false;
		
		btn_restore.active = true;

		btn_installer.active = false;

		window.mode_changed();
		window.guimode_changed();
	}

	public void btn_installer_clicked(){

		if (!btn_installer.active){ return; }
		
		log_debug("GeneralBox: btn_installer_clicked()");
		
		App.mode = Mode.BACKUP;
		App.redist = true;

		btn_backup.active = false;
		
		btn_restore.active = false;

		btn_installer.active = true;

		window.mode_changed();
		window.guimode_changed();
	}

	private void init_ui_mode_installer() {

		vbox_installer = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
		vbox_installer.margin_top = 12;
		vbox_main.add(vbox_installer);

		gtk_hide(vbox_installer);
		
		// header -------------------------
		
		var label = new Gtk.Label(format_text(_("Installer Options"), true, false, true));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_bottom = 12;
		vbox_installer.add(label);

		var sg = new Gtk.SizeGroup(SizeGroupMode.HORIZONTAL);

		// name --------------------
		
		var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		vbox_installer.add(hbox);

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
		vbox_installer.add(hbox);

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
		vbox_installer.add(hbox);

		label = new Gtk.Label(_("Working Dir"));
		label.xalign = 0.0f;
		hbox.add(label);
		sg.add_widget(label);
		
		entry = new Gtk.Entry();
		entry.hexpand = true;
		hbox.add(entry);
		entry.sensitive = false;
		entry_outpath = entry;

		entry.text = path_combine(App.basepath, "distribution");

		var button = new Gtk.Button.with_label(_("Open"));
		button.set_tooltip_text(_("Open folder"));
		hbox.add(button);

		button.clicked.connect(() => {

			string dist_path = path_combine(App.basepath, "distribution");
			dir_create(dist_path);
			exo_open_folder(dist_path, false);
		});

		// prepare -------------------------

		hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		hbox.margin_top = 12;
		vbox_installer.add(hbox);

		label = new Gtk.Label(format_text(_("Create backups and click 'Generate Installer' to finish"), false, true, false));
		label.set_use_markup(true);
		hbox.add(label);

		// action -------------------------

		hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		hbox.margin_top = 12;
		vbox_installer.add(hbox);

		var btn_generate = new Gtk.ToggleButton.with_label(_("Generate Installer"));
		hbox.add(btn_generate);
		sg_buttons.add_widget(btn_generate);

		label = new Gtk.Label(format_text(_("Generate installer from backup files"), false, true, false));
		label.set_use_markup(true);
		hbox.add(label);

		btn_generate.clicked.connect(()=>{
			
			Timeout.add(100, ()=>{
				
				string dist_path = path_combine(App.basepath, "distribution");

				string cmd = "pkexec aptik-gen --pack";

				cmd += " --appname '%s'".printf(escape_single_quote(entry_appname.text));

				cmd += " --outname '%s'".printf(escape_single_quote(entry_outname.text));

				cmd += " --outpath '%s'".printf(escape_single_quote(entry_outpath.text));

				cmd += " --basepath '%s'".printf(escape_single_quote(dist_path));
				
				window.execute(cmd);
				
				return false;
			});
		});
	}

	private void add_links(){

		var expander = new Gtk.Label(""); 
		expander.vexpand = true; 
		vbox_main.add(expander);
    
		var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6); 
		//hbox.margin_bottom = 6; 
		//hbox.margin_right = 6; 
		vbox_main.add(hbox);

		// donate link

		var bbox = add_link_box();
		
		var button = new Gtk.LinkButton.with_label("", _("Donate")); 
		bbox.add(button);
    
		button.clicked.connect(() => {
			var win = new DonationWindow(window); 
			win.show(); 
		});
	
		// user manual

		//bbox = add_link_box();
		
		button = new Gtk.LinkButton.with_label("", _("User Manual")); 
		bbox.add(button);

		button.clicked.connect(() => { 
			xdg_open("https://github.com/teejee2008/aptik/blob/master/MANUAL.md"); 
		});

		// about

		//bbox = add_link_box();
		
		button = new Gtk.LinkButton.with_label("", _("About")); 
		bbox.add(button);

		button.clicked.connect(() => { 
			window.btn_show_about_window(); 
		}); 
	}

	private Gtk.ButtonBox add_link_box(){

		//var hbox = new Gtk.Box(Orientation.HORIZONTAL, 6);
		//vbox_main.add(hbox);

		var bbox = new Gtk.ButtonBox(Orientation.HORIZONTAL);
		bbox.set_layout(Gtk.ButtonBoxStyle.CENTER);
		vbox_main.add(bbox);

		return bbox;
	}
}
