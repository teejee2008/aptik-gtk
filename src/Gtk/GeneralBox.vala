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
	//protected Gtk.Box hbox_installer_mode;

	protected Gtk.RadioButton opt_backup;
	protected Gtk.RadioButton opt_restore;
	protected Gtk.RadioButton opt_installer;

	protected Gtk.Entry entry_location;
	protected Gtk.Entry entry_appname;
	protected Gtk.Entry entry_outname;
	protected Gtk.Entry entry_outpath;

	protected MainWindow window;

	protected Gtk.SizeGroup sg_buttons;

	public GeneralBox(MainWindow parent) {

		window = parent;

		vbox_main = new Gtk.Box(Orientation.VERTICAL, 12);
		vbox_main.margin = 12;
		this.add(vbox_main);

		init_ui();
	}

	protected virtual void init_ui(){

		sg_buttons = new Gtk.SizeGroup(SizeGroupMode.BOTH);

		init_ui_location();

		init_ui_mode();

		init_ui_mode_gui_mode();

		add_links();
		
		show_all();
	}

	private void init_ui_location() {

		var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
		vbox_main.add(vbox);
		
		// header
		var label = new Gtk.Label(format_text(_("Backup Location"), true, false, true));
		label.set_use_markup(true);
		label.halign = Align.START;
		//label.margin_top = 12;
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
			if (window.check_backup_folder()) {
				exo_open_folder(App.basepath, false);
			}
		});
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

	private void init_ui_mode_gui_mode() {

		var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
		vbox_main.add(vbox);
		
		// header
		var label = new Gtk.Label(format_text(_("UI Mode"), true, false, true));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_top = 12;
		//label.margin_bottom = 12;
		vbox.add(label);

		var vbox2 = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
		vbox2.margin = 12;
		vbox.add(vbox2);
		vbox = vbox2;

		// easy --------------------------------

		string txt = "  <b>%s</b>".printf(_("Easy"));
		string subtext = format_text(_("Backup and Restore with a single click"), false, true, false);
		
		var opt_easy = add_radio_option(vbox, txt, subtext, null);
		
		// advanced -------------------------

		txt = "  <b>%s</b>".printf(_("Advanced"));
		subtext = format_text(_("Show advanced options for individual items"), false, true, false);
		
		var opt_advanced = add_radio_option(vbox, txt, subtext, opt_easy);
			
		// expert -------------------------

		txt = "  <b>%s</b>".printf(_("Expert"));
		subtext = format_text(_("Show all advanced options"), false, true, false);
		
		var opt_expert = add_radio_option(vbox, txt, subtext, opt_advanced);
	
		// events -----------------------
		
		opt_easy.clicked.connect(() => {
			if (opt_easy.active){
				opt_advanced.active = false;
				opt_expert.active = false;
				App.guimode = GUIMode.EASY;
				window.guimode_changed();
			}
			else if (!opt_easy.active && !opt_advanced.active && !opt_expert.active){
				opt_easy.active = true;
			}
		});

		opt_advanced.clicked.connect(() => {
			if (opt_advanced.active){
				opt_easy.active = false;
				opt_expert.active = false;
				App.guimode = GUIMode.ADVANCED;
				window.guimode_changed();
			}
			else if (!opt_easy.active && !opt_advanced.active && !opt_expert.active){
				opt_advanced.active = true;
			}
		});
		
		opt_expert.clicked.connect(() => {
			if (opt_expert.active){
				opt_easy.active = false;
				opt_advanced.active = false;
				App.guimode = GUIMode.EXPERT;
				window.guimode_changed();
			}
			else if (!opt_easy.active && !opt_advanced.active && !opt_expert.active){
				opt_expert.active = true;
			}
		});

		window.guimode_changed.connect(()=>{

			if (cmd_exists("aptik-gen")){
				opt_installer.visible = true;
				//gtk_show(opt_installer);
			}
			else{
				opt_installer.visible = false;
				//gtk_hide(opt_installer);
			}

			/*switch(App.guimode){
				
			case GUIMode.EASY:
			
				hbox_installer_mode.sensitive = false;
				break;
				
			case GUIMode.ADVANCED:
			case GUIMode.EXPERT:
			
				hbox_installer_mode.sensitive = true;
				break;
			}*/
		});

		// set initial state ---------------------

		switch (App.guimode){
		case GUIMode.EASY:
			opt_easy.active = true;
			break;
		case GUIMode.ADVANCED:
			opt_advanced.active = true;
			break;
		case GUIMode.EXPERT:
			opt_expert.active = true;
			break;
		}
	}

	private void init_ui_mode() {

		var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
		vbox_main.add(vbox);
		
		// header
		var label = new Gtk.Label(format_text(_("Backup Mode"), true, false, true));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_top = 12;
		//label.margin_bottom = 12;
		vbox.add(label);

		var vbox2 = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
		vbox2.margin = 12;
		vbox.add(vbox2);
		vbox = vbox2;
		
		// backup --------------------------------

		string txt = "  <b>%s</b>".printf(_("Backup"));
		string subtext = format_text(_("Create backups for current system"), false, true, false);
		
		opt_backup = add_radio_option(vbox, txt, subtext, null);
		
		// restore -------------------------

		txt = "  <b>%s</b>".printf(_("Restore"));
		subtext = format_text(_("Restore backups on new system"), false, true, false);
		
		opt_restore = add_radio_option(vbox, txt, subtext, opt_backup);

		// installer -------------------------

		txt = "  <b>%s</b>".printf(_("Create Installer"));
		subtext = format_text(_("Create installer to share with friends"), false, true, false);
		
		opt_installer = add_radio_option(vbox, txt, subtext, opt_restore);
		
		// events -----------------------
		
		opt_backup.clicked.connect(opt_backup_clicked);

		opt_restore.clicked.connect(opt_restore_clicked);
		
		opt_installer.clicked.connect(opt_installer_clicked);

		// set initial state ---------------------
		
		opt_backup.active = (App.mode == Mode.BACKUP) && !App.redist;
		
		opt_restore.active = (App.mode == Mode.RESTORE);

		opt_installer.active = (App.mode == Mode.BACKUP) && App.redist;
	}

	private Gtk.SizeGroup sg_radio;
	
	private Gtk.RadioButton add_radio_option(Gtk.Box box, string text, string subtext, Gtk.RadioButton? another_radio_in_group){

		var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		box.add(hbox);
		
		Gtk.RadioButton radio = null;

		if (another_radio_in_group == null){
			radio = new Gtk.RadioButton(null);
		}
		else{
			radio = new Gtk.RadioButton.from_widget(another_radio_in_group);
		}

		radio.label = text;

		hbox.add(radio);

		if (sg_radio == null){
			sg_radio = new Gtk.SizeGroup(SizeGroupMode.HORIZONTAL);
		}
		
		sg_radio.add_widget(radio);

		var label = new Gtk.Label("- " + subtext);
		label.use_markup = true;
		hbox.add(label);

		radio.notify["sensitive"].connect(()=>{
			label.sensitive = radio.sensitive;
		});

		radio.notify["visible"].connect(()=>{
			label.visible = radio.visible;
			label.no_show_all = radio.no_show_all;
		});

		radio.notify["no_show_all"].connect(()=>{
			label.no_show_all = radio.no_show_all;
		});
		
		foreach(var child in radio.get_children()){
			if (child is Gtk.Label){
				var lbl = (Gtk.Label) child;
				lbl.use_markup = true;
				break;
			}
		}
		
		return radio;
	}
	
	public void opt_backup_clicked(){

		if (!opt_backup.active){ return; }
		
		log_debug("GeneralBox: opt_backup_clicked()");

		App.mode = Mode.BACKUP;
		App.redist = false;

		opt_backup.active = true;
		
		opt_restore.active = false;

		opt_installer.active = false;

		window.mode_changed();
		window.guimode_changed();
	}

	public void opt_restore_clicked(){

		if (!opt_restore.active){ return; }
		
		log_debug("GeneralBox: opt_restore_clicked()");

		App.mode = Mode.RESTORE;
		App.redist = false;

		opt_backup.active = false;
		
		opt_restore.active = true;

		opt_installer.active = false;

		window.mode_changed();
		window.guimode_changed();
	}

	public void opt_installer_clicked(){

		if (!opt_installer.active){ return; }
		
		log_debug("GeneralBox: opt_installer_clicked()");
		
		App.mode = Mode.BACKUP;
		App.redist = true;

		opt_backup.active = false;
		
		opt_restore.active = false;

		opt_installer.active = true;

		window.mode_changed();
		window.guimode_changed();
	}

	private void add_links(){

		var expander = new Gtk.Label(""); 
		expander.vexpand = true; 
		vbox_main.add(expander);

		var bbox1 = new Gtk.ButtonBox(Orientation.HORIZONTAL);
		bbox1.set_layout(Gtk.ButtonBoxStyle.CENTER);
		vbox_main.add(bbox1);

		var btn = new Gtk.Button.with_label("New Version Available");
		bbox1.add(btn);
		
		btn.clicked.connect(()=>{
			var win = new VersionMessageWindow(window);
		});

		//string css = "font-size: 20px; font-weight: bold;";

		//gtk_apply_css({ btn }, css);

		expander = new Gtk.Label(""); 
		expander.vexpand = true; 
		vbox_main.add(expander);
		
    
		var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6); 
		//hbox.margin_bottom = 6; 
		//hbox.margin_right = 6; 
		vbox_main.add(hbox);

		// donate link

		var bbox = add_link_box();
		
		//var button = new Gtk.LinkButton.with_label("", _("Donate")); 
		//bbox.add(button);
    
		//button.clicked.connect(() => {
		//	var win = new DonationWindow(window); 
		//	win.show(); 
		//});
	
		// user manual

		//bbox = add_link_box();
		
		var button = new Gtk.LinkButton.with_label("", _("User Manual")); 
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
