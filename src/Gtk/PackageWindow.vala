/*
 * PackageWindow.vala
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

public class PackageWindow : Window {
	
	private Gtk.Box vbox_main;

	private Box hbox_filter;
	private Entry txt_filter;
	private ComboBox cmb_pkg_section;
	private ComboBox cmb_status;
	private Gtk.Label lbl_count;
	
	private Gtk.TreeView treeview;
	private Gtk.TreeViewColumn col_status;

	private Gtk.TreeModelFilter model_filter;
	
	private Button btn_restore;
	private Button btn_backup;
	private Button btn_cancel;
	private Button btn_select_all;
	private Button btn_select_none;

	private int def_width = 700;
	private int def_height = 450;
	private uint tmr_init = 0;
	private uint tmr_refilter = 0;
	private bool is_running = false;
	private bool is_restore_view = false;

	public Gee.ArrayList<Package> packages = new Gee.ArrayList<Package>();

	private bool is_backup_view{
		get{
			return !is_restore_view;
		}
	}

	private const Gtk.TargetEntry[] targets = {
		{ "text/uri-list", 0, 0}
	};

	// init
	
	public PackageWindow(Gtk.Window parent, bool restore) {
		
		set_transient_for(parent);
		set_modal(true);
		is_restore_view = restore;

		Gtk.drag_dest_set (this,Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);
		drag_data_received.connect(on_drag_data_received);
		
		destroy.connect(()=>{
			parent.present();
		});
		
		init_window();
	}

	public void init_window () {
		
		//title = AppName + " v" + AppVersion;
		window_position = WindowPosition.CENTER;
		set_default_size (def_width, def_height);
		icon = get_app_icon(16);
		resizable = true;
		deletable = true;
		
		//vbox_main
		vbox_main = new Box (Orientation.VERTICAL, 6);
		vbox_main.margin = 6;
		add (vbox_main);

		//filters
		init_filters();

		//treeview
		init_treeview();

		//buttons
		init_actions();
		
		show_all();

		tmr_init = Timeout.add(100, init_delayed);
	}

	private bool init_delayed() {

		log_debug("PackageWindow.init_delayed()");
		
		/* any actions that need to run after window has been displayed */
		
		if (tmr_init > 0) {
			Source.remove(tmr_init);
			tmr_init = 0;
		}

		if (is_restore_view){
			title = _("Restore");
			
			btn_restore.show();
			btn_restore.visible = true;
			
			restore_init();
		}
		else{
			title = _("Backup");
			
			btn_backup.show();
			btn_backup.visible = true;

			backup_init();
		}

		return false;
	}

	private void init_filters() {

		log_debug("PackageWindow.init_filters()");

		//hbox_filter
		hbox_filter = new Box (Orientation.HORIZONTAL, 6);
		hbox_filter.margin_left = 3;
		hbox_filter.margin_right = 3;
		vbox_main.add (hbox_filter);

		//filter
		Label lbl_filter = new Label(_("Filter"));
		hbox_filter.add (lbl_filter);

		//txt_filter
		txt_filter = new Entry();
		txt_filter.hexpand = true;
		txt_filter.secondary_icon_stock = "gtk-clear";
		hbox_filter.add (txt_filter);

		txt_filter.icon_release.connect((p0, p1) => {
			txt_filter.text = "";
			model_filter.refilter();
		});

		string tt = _("Search package name and description");
		txt_filter.set_tooltip_markup(tt);
		
		init_cmb_status();

		lbl_count = new Gtk.Label("0");
		lbl_count.xalign = 0.5f;
		lbl_count.set_size_request(60,-1);
		hbox_filter.add(lbl_count);

		string css = "font: 12px bold";
		gtk_apply_css({ lbl_count }, css);
		//init_cmb_section();

		txt_filter.changed.connect(refilter_after_timeout);
	}

	private void init_cmb_status(){

		//cmb_status
		cmb_status = new ComboBox();
		
		string tt = "";
		tt += _("<b>Installed</b>\nAll installed packages.") + "\n\n";
		tt += _("<b>Installed (dist)</b>\nLinux distribution base packages (excluded by default)") + "\n\n";
		tt += _("<b>Installed (user)</b>\nExtra packages explicitly installed by user") + "\n\n";
		tt += _("<b>Installed (auto)</b>\nAutomatically installed dependency packages (excluded by default)") + "\n\n";
		tt += _("<b>Installed (manual)</b>\nPackages installed from unknown sources (not available in repositories)") + "\n\n";
		tt += _("<b>Installed (foreign)</b>\nInstalled packages with foreign architecture (excluded by default)") + "\n\n";
		tt += _("<b>Installed (libs)</b>\nLibrary packages (excluded by default)") + "\n\n";
		tt += _("<b>Installed (icons)</b>\nIcon theme packages (can be excluded from backup)") + "\n\n";
		tt += _("<b>Installed (themes)</b>\nTheme packages (can be excluded from backup)") + "\n\n";
		tt += _("<b>Installed (fonts)</b>\nFont packages (can be excluded from backup)") + "\n\n";
		tt += _("<b>Backup List</b>\nPackages listed in backup");
		cmb_status.set_tooltip_markup(tt);
		
		hbox_filter.add (cmb_status);

		var cell_cmb_status = new CellRendererPixbuf();
		cmb_status.pack_start (cell_cmb_status, false);
		cmb_status.set_attributes(cell_cmb_status, "pixbuf", 1);
		
		var cell_pkg_restore_status = new CellRendererText();
		cmb_status.pack_start(cell_pkg_restore_status, false );
		cmb_status.set_cell_data_func (cell_pkg_restore_status, (cell_pkg_restore_status, cell, model, iter) => {
			string status;
			model.get (iter, 0, out status, -1);
			(cell as Gtk.CellRendererText).text = status;
		});
	}

	private void init_cmb_section(){

		//cmb_pkg_section
		cmb_pkg_section = new ComboBox();
		cmb_pkg_section.set_tooltip_text(_("Category"));
		hbox_filter.add (cmb_pkg_section);

		CellRendererText cell_pkg_section = new CellRendererText();
		cmb_pkg_section.pack_start(cell_pkg_section, false );
		cmb_pkg_section.set_cell_data_func (cell_pkg_section, (cell_pkg_section, cell, model, iter) => {
			string section;
			model.get (iter, 0, out section, -1);
			(cell as Gtk.CellRendererText).text = section;
		});
	}

	private void init_treeview() {

		log_debug("PackageWindow.init_treeview()");
		
		//treeview
		treeview = new Gtk.TreeView();
		treeview.get_selection().mode = SelectionMode.MULTIPLE;
		treeview.headers_clickable = true;
		treeview.set_rules_hint (true);
		treeview.set_tooltip_column(3);

		//scrolled
		var scrolled = new Gtk.ScrolledWindow(null, null);
		scrolled.set_shadow_type (ShadowType.ETCHED_IN);
		scrolled.add (treeview);
		scrolled.expand = true;
		vbox_main.add(scrolled);

		// select ----------------------

		var col_select = new Gtk.TreeViewColumn();
		treeview.append_column(col_select);

		var cell_select = new Gtk.CellRendererToggle ();
		cell_select.activatable = true;
		col_select.pack_start (cell_select, false);

		col_select.set_cell_data_func (cell_select, (cell_layout, cell, model, iter) => {

			bool selected;
			Package pkg;
			model.get (iter, 0, out selected, 1, out pkg, -1);
			
			(cell as Gtk.CellRendererToggle).active = selected;
			
			if (is_restore_view){
				(cell as Gtk.CellRendererToggle).sensitive = !pkg.is_installed;
			}
			else{
				(cell as Gtk.CellRendererToggle).sensitive = true;
			}
		});

		cell_select.toggled.connect((path) => {

			bool selected;
			Package pkg;

			var store = (Gtk.ListStore) model_filter.child_model;

			TreeIter filter_iter, child_iter;
			model_filter.get_iter_from_string (out filter_iter, path);
			model_filter.get (filter_iter, 0, out selected, 1, out pkg, -1);

			pkg.is_selected = !selected;

			model_filter.convert_iter_to_child_iter(out child_iter, filter_iter);
			store.set(child_iter, 0, pkg.is_selected, -1);
		});

		// status ----------------------

		col_status = new TreeViewColumn();
		//col_status.title = _("");
		col_status.resizable = true;
		treeview.append_column(col_status);

		var cell_pkg_status = new CellRendererPixbuf ();
		col_status.pack_start (cell_pkg_status, false);
		col_status.set_attributes(cell_pkg_status, "pixbuf", 2);

		// name ----------------------

		var col_name = new TreeViewColumn();
		col_name.title = _("Package");
		col_name.resizable = true;
		col_name.min_width = 180;
		treeview.append_column(col_name);

		var cell_name = new CellRendererText ();
		cell_name.ellipsize = Pango.EllipsizeMode.END;
		col_name.pack_start (cell_name, false);

		col_name.set_cell_data_func (cell_name, (cell_layout, cell, model, iter) => {
			
			Package pkg;
			model.get (iter, 1, out pkg, -1);
			
			(cell as Gtk.CellRendererText).text = pkg.name;
		});

		//col_desc ----------------------

		var col_desc = new TreeViewColumn();
		col_desc.title = _("Description");
		col_desc.resizable = true;
		//col_desc.min_width = 300;
		treeview.append_column(col_desc);

		var cell_desc = new CellRendererText ();
		cell_desc.ellipsize = Pango.EllipsizeMode.END;
		col_desc.pack_start (cell_desc, false);

		col_desc.set_cell_data_func (cell_desc, (cell_layout, cell, model, iter) => {
			
			Package pkg;
			model.get (iter, 1, out pkg, -1);
			
			(cell as Gtk.CellRendererText).text = pkg.desc;
		});
	}

	private void init_actions() {

		log_debug("PackageWindow.init_actions()");
		
		//hbox_pkg_actions
		Box hbox_pkg_actions = new Box (Orientation.HORIZONTAL, 6);
		vbox_main.add (hbox_pkg_actions);

		//btn_select_all
		btn_select_all = new Gtk.Button.with_label (" " + _("Select All") + " ");
		hbox_pkg_actions.pack_start (btn_select_all, true, true, 0);
		
		btn_select_all.clicked.connect(() => {

			TreeIter filter_iter;

			var store = (Gtk.ListStore) model_filter.child_model;
			
			bool iterExists = model_filter.get_iter_first (out filter_iter);
			
			while (iterExists){

				TreeIter child_iter;
				model_filter.convert_iter_to_child_iter(out child_iter, filter_iter);

				bool selected;
				Package pkg;
				store.get(child_iter, 0, out selected, 1, out pkg, -1);
				
				pkg.is_selected = true;
				store.set(child_iter, 0, pkg.is_selected, -1);
				
				iterExists = model_filter.iter_next(ref filter_iter);
			}
			
			treeview_refresh();
		});

		//btn_select_none
		btn_select_none = new Gtk.Button.with_label (" " + _("Select None") + " ");
		hbox_pkg_actions.pack_start (btn_select_none, true, true, 0);
		
		btn_select_none.clicked.connect(() => {
			
			TreeIter filter_iter;

			var store = (Gtk.ListStore) model_filter.child_model;
			
			bool iterExists = model_filter.get_iter_first (out filter_iter);
			
			while (iterExists){

				TreeIter child_iter;
				model_filter.convert_iter_to_child_iter(out child_iter, filter_iter);
				
				bool selected;
				Package pkg;
				store.get(child_iter, 0, out selected, 1, out pkg, -1);
				
				pkg.is_selected = false;
				store.set(child_iter, 0, pkg.is_selected, -1);
				
				iterExists = model_filter.iter_next (ref filter_iter);
			}
			
			treeview_refresh();
		});

		//btn_backup
		btn_backup = new Gtk.Button.with_label (" <b>" + _("Backup") + "</b> ");
		btn_backup.no_show_all = true;
		hbox_pkg_actions.pack_start (btn_backup, true, true, 0);
		btn_backup.clicked.connect(btn_backup_clicked);

		//btn_restore
		btn_restore = new Gtk.Button.with_label (" <b>" + _("Restore") + "</b> ");
		btn_restore.no_show_all = true;
		hbox_pkg_actions.pack_start (btn_restore, true, true, 0);
		btn_restore.clicked.connect(btn_restore_clicked);

		//btn_cancel
		btn_cancel = new Gtk.Button.with_label (" " + _("Close") + " ");
		hbox_pkg_actions.pack_start (btn_cancel, true, true, 0);
		btn_cancel.clicked.connect(() => {
			this.close();
		});

		set_bold_font_for_buttons();
	}

	private void set_bold_font_for_buttons() {
		//set bold font for some buttons
		foreach(Button btn in new Button[] { btn_backup, btn_restore }) {
			foreach(Widget widget in btn.get_children()) {
				if (widget is Label) {
					Label lbl = (Label)widget;
					lbl.set_markup(lbl.label);
				}
			}
		}
	}

	// events

	private void on_drag_data_received (Gdk.DragContext drag_context, int x, int y, Gtk.SelectionData data, uint info, uint time) {
		int count = 0;
        foreach(string uri in data.get_uris()){
			string file = uri.replace("file://","").replace("file:/","");
			file = Uri.unescape_string (file);

			if (file.has_suffix(".deb")){
				//App.copy_deb_file(file);
				count++;
			}
		}

		if (count > 0){
			string msg = _("DEB files were copied to backup location.");
			gtk_messagebox(_("Files Copied"),msg,this,false);
		}

        Gtk.drag_finish (drag_context, true, false, time);
    }

	private void cmb_status_refresh() {

		log_debug("PackageWindow.cmb_status_refresh()");
		
		var store = new Gtk.ListStore(2, typeof(string), typeof(Gdk.Pixbuf));

		TreeIter iter;

		if (is_restore_view) {
			
			store.append(out iter);
			store.set (iter, 0, _("Backup List"), 1, null);

			store.append(out iter);
			store.set (iter, 0, _("Installed"), 1, null);

			store.append(out iter);
			store.set (iter, 0, _("Not Installed"), 1, null);

			store.append(out iter);
			store.set (iter, 0, _("Not Available"), 1, null);
		}
		else{
			store.append(out iter);
			store.set (iter, 0, _("Installed"), 1, null);
			store.append(out iter);
			store.set (iter, 0, _("Installed (dist)"), 1, null);
			store.append(out iter);
			store.set (iter, 0, _("Installed (user)"), 1, null);
			store.append(out iter);
			store.set (iter, 0, _("Installed (auto)"), 1, null);
			store.append(out iter);
			store.set (iter, 0, _("Installed (manual)"), 1, null);
			store.append(out iter);
			store.set (iter, 0, _("Installed (foreign)"), 1, null);
			store.append(out iter);
			store.set (iter, 0, _("Installed (libs)"), 1, null);
			store.append(out iter);
			store.set (iter, 0, _("Installed (icons)"), 1, null);
			store.append(out iter);
			store.set (iter, 0, _("Installed (themes)"), 1, null);
			store.append(out iter);
			store.set (iter, 0, _("Installed (fonts)"), 1, null);
		}
		
		cmb_status.set_model (store);
		cmb_status.active = 0;
	}

	private void cmb_section_refresh() {

		log_debug("PackageWindow.treeview_refresh()");
		
		var store = new Gtk.ListStore(1, typeof(string));
		TreeIter iter;
		store.append(out iter);
		store.set (iter, 0, _("All"));
		//foreach (string section in App.sections) {
		//	store.append(out iter);
		//	store.set (iter, 0, section);
		//}
		cmb_pkg_section.set_model(store);
		cmb_pkg_section.active = 0;
	}

	private void cmb_filters_connect() {

		log_debug("PackageWindow.cmb_filters_connect()");
		
		cmb_status.changed.connect(()=>{
			treeview_refilter();
		});

		//cmb_pkg_section.changed.connect(treeview_refilter);
		
		log_debug("connected: combo events");
	}

	private void cmb_filters_disconnect() {
		
		cmb_status.changed.disconnect(treeview_refilter);
		//cmb_pkg_section.changed.disconnect(treeview_refilter);
		log_debug("disconnected: combo events");
	}

	private void treeview_refilter() {
		
		log_debug("PackageWindow.treeview_refilter()");
		
		model_filter.refilter();
		
		lbl_count.label = "%d".printf(gtk_iter_count(model_filter));
	}

	private void treeview_refresh() {

		log_debug("PackageWindow.treeview_refresh()");
		
		var store = new Gtk.ListStore(4, typeof(bool), typeof(Package), typeof(Gdk.Pixbuf), typeof(string));
	
		//Gdk.Pixbuf pix_green = IconManager.lookup("item-green",16);
		//Gdk.Pixbuf pix_gray = IconManager.lookup("item-gray",16);
		//Gdk.Pixbuf pix_red  = IconManager.lookup("item-red",16);
		//Gdk.Pixbuf pix_pink  = IconManager.lookup("item-pink",16);
		//Gdk.Pixbuf pix_yellow  = IconManager.lookup("item-yellow",16);
		//Gdk.Pixbuf pix_blue  = IconManager.lookup("item-blue",16);

		Gdk.Pixbuf pix_package  = IconManager.lookup("package-x-generic",16);

		TreeIter iter;
		string tt = "";
		
		foreach(var pkg in packages) {
			
			store.append(out iter);
			store.set(iter, 0, pkg.is_selected);
			store.set(iter, 1, pkg);
			store.set(iter, 2, pix_package);
			store.set(iter, 3, tt);
		}

		model_filter = new TreeModelFilter(store, null);
		model_filter.set_visible_func(filter_packages_filter);
		treeview.set_model(model_filter);
		
		treeview.columns_autosize();
	}

	private bool filter_packages_filter(Gtk.TreeModel model, Gtk.TreeIter iter) {

		Package pkg;
		model.get (iter, 1, out pkg, -1);
		bool display = false;

		string search_string = txt_filter.text.strip().down();
		
		if ((search_string != null) && (search_string.length > 0)) {
			try {
				Regex regexName = new Regex (search_string, RegexCompileFlags.CASELESS);
				MatchInfo match_name;
				MatchInfo match_desc;
				if (regexName.match(pkg.name, 0, out match_name) || regexName.match (pkg.desc, 0, out match_desc)) {
					display = true;
				}
			}
			catch (Error e) {
				//ignore
			}
		}
		else{
			display = true;
		}

		if (!display){ return false; }

		if (is_restore_view){
			
			display = false;

			switch (cmb_status.active) {
			case 0: //Backup list
				display = true;
				break;
			case 1: //Installed
				if (pkg.is_installed) {
					display = true;
				}
				break;
			case 2: //Not Installed
				if (!pkg.is_installed) {
					display = true;
				}
				break;
			case 3: //Not Available
				if (!pkg.is_available) {
					display = true;
				}
				break;
			}
		}
		else{
			display = false;
			
			switch (cmb_status.active) {
			case 0: //installed
				if (pkg.is_installed) {
					display = true;
				}
				break;
			case 1: //Installed, Distribution
				if (pkg.is_dist) {
					display = true;
				}
				break;
			case 2: //Installed, User
				if (pkg.is_user) {
					display = true;
				}
				break;
			case 3: //Installed, Automatic
				if (pkg.is_auto) {
					display = true;
				}
				break;
			case 4: //Installed, manual
				if (pkg.is_manual) {
					display = true;
				}
				break;
			case 5: //Installed, foreign
				if (pkg.is_foreign) {
					display = true;
				}
				break;
			case 6: //Installed, libs
				if (pkg.name.has_prefix("lib")) {
					display = true;
				}
				break;
			case 7: //Installed, icons
				if (pkg.name.contains("-icon-theme")) {
					display = true;
				}
				break;
			case 8: //Installed, themes
				if (pkg.name.contains("-theme") && !pkg.name.contains("-icon-theme")) {
					display = true;
				}
				break;
			case 9: //Installed, fonts
				if (pkg.name.has_prefix("fonts-")) {
					display = true;
				}
				break;
			}
		}

		//switch (cmb_pkg_section.active) {
		//case 0: //all
			//exclude nothing
			//break;
		//default:
			//if (pkg.section != gtk_combobox_get_value(cmb_pkg_section, 0, ""))
			//{
			//	display = false;
			//}
			//break;
		//}

		return display;
	}

	private void refilter_after_timeout() {
		
		//remove pending action
		if (tmr_refilter > 0) {
			Source.remove(tmr_refilter);
			tmr_refilter = 0;
		}

		//add timed action
		tmr_refilter = Timeout.add(500, ()=>{
			
			if (tmr_refilter > 0) {
				Source.remove(tmr_refilter);
				tmr_refilter = 0;
			}
			
			model_filter.refilter();
			
			return true;
		});
	}
	
	// backup

	private void backup_init() {

		log_debug("PackageWindow.backup_init()");
		
		var status_msg = _("Listing packages...");
		var dlg = new ProgressWindow.with_parent(this, status_msg);
		dlg.show_all();
		gtk_do_events();
		
		try {
			is_running = true;
			Thread.create<void> (backup_init_thread, true);
		}
		catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		dlg.pulse_start();

		while (is_running) {
			dlg.sleep(200);
		}

		treeview_refresh();

		//disconnect combo events
		cmb_filters_disconnect();
		//refresh combos
		cmb_status_refresh();
		cmb_status.active = 2;
		cmb_section_refresh();
		//re-connect combo events
		cmb_filters_connect();

		treeview_refilter();

		dlg.destroy();
		gtk_do_events();

		/*string deb_list = "";
		foreach(var pkg in App.pkg_list_master.values){
			if (pkg.is_installed && pkg.is_deb && (pkg.deb_file_name.length == 0)){
				deb_list += pkg.id + " ";
			}
		}
		if (deb_list.length > 0){
			string deb_msg = _("Following packages are not available in software repositories") + ":\n\n";
			deb_msg += deb_list + "\n\n";
			deb_msg += _("If you have the DEB files for these packages, you can drag-and-drop the files on this window. Files will be saved to backup location and used for restore.");
			gtk_messagebox(_("Unknown Source"), deb_msg, this, false);
		}*/
	}

	private void backup_init_thread() {

		log_debug("PackageWindow.backup_init_thread()");
		
		packages.clear();
		
		string std_out, std_err;
		exec_sync("aptik --dump-packages", out std_out, out std_err);
		
		foreach(string line in std_out.split("\n")){

			var match = regex_match("""NAME='(.*)',ARCH='(.*)',DESC='(.*)',I='(0|1)',D='(0|1)',A='(0|1)',U='(0|1)',F='(0|1)',M='(0|1)'""", line);
			
			if (match != null){
				
				var pkg = new Package();
				packages.add(pkg);
				
				pkg.name = match.fetch(1);
				pkg.arch = match.fetch(2);
				pkg.desc = match.fetch(3);
				pkg.is_installed = (match.fetch(4) == "1") ? true : false;
				pkg.is_dist = (match.fetch(5) == "1") ? true : false;
				pkg.is_auto = (match.fetch(6) == "1") ? true : false;
				pkg.is_user = (match.fetch(7) == "1") ? true : false;
				pkg.is_foreign = (match.fetch(8) == "1") ? true : false;
				pkg.is_manual = (match.fetch(9) == "1") ? true : false;
			}
		}

		packages.sort((a,b) => {
			return strcmp(a.name,b.name);
		});

		foreach(var pkg in packages){
			pkg.is_selected = pkg.is_user;
		}
		
		is_running = false;
	}

	private void btn_backup_clicked() {

		log_debug("PackageWindow.btn_backup_clicked()");
		
		//check if no action required
		bool none_selected = true;
		foreach(var pkg in packages) {
			if (pkg.is_selected) {
				none_selected = false;
				break;
			}
		}
		if (none_selected) {
			string title = _("No Packages Selected");
			string msg = _("Select the packages to backup");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		var status_msg = _("Saving...");
		var dlg = new ProgressWindow.with_parent(this,status_msg,true);
		dlg.show_all();
		gtk_do_events();

		string backup_path = create_backup_path(App.basepath);

		// save exclude list ---------------------
		
		/*string txt = "";
		foreach(var pkg in packages){
			txt += "%s\n".printf(pkg.name);
		}
		string exclude_list = path_combine(backup_path, "exclude.list");
		file_write(exclude_list, txt, false);
		chmod(backup_path, "a+rwx");*/

		// save backup ---------------------
		
		save_package_list_installed(backup_path); // ignore retval
		
		bool ok = save_package_list_selected(backup_path);
		
		if (ok){
			dlg.finish(Messages.BACKUP_OK, true);
		}
		else{
			dlg.finish(Messages.BACKUP_ERROR, false);
		}
	}

	public bool save_package_list_installed(string backup_path) {

		string backup_file = path_combine(backup_path, "installed.list");

		string txt = "\n# DO NOT EDIT - This list is not used for restore\n\n";

		int count = 0;
		
		foreach(var pkg in packages){
			
			if (!pkg.is_installed){ continue; }
			
			txt += "%s".printf(pkg.name);
			
			if (pkg.desc.length > 0){
				txt += " # %s".printf(pkg.desc);
			}

			txt += "\n";

			count++;
		}

		bool ok = file_write(backup_file, txt);

		if (ok){
			chmod(backup_file, "a+rw");
			log_msg("%s: %s (%d packages)".printf(_("Saved"), backup_file, count));
		}

		return ok;
	}

	public bool save_package_list_selected(string backup_path) {

		string backup_file = path_combine(backup_path, "selected.list");

		string txt = "\n";

		txt += "# %s\n".printf(_("Packages listed in this file will be installed on restore"));
		txt += "# %s\n\n".printf(_("Comment-out or remove lines for unwanted items"));

		int count = 0;
		
		foreach(var pkg in packages){

			if (!pkg.is_installed){ continue; }

			if (!pkg.is_selected){ continue; }

			if (pkg.name.has_prefix("linux-headers")){ continue; }
			if (pkg.name.has_prefix("linux-signed")){ continue; }
			if (pkg.name.has_prefix("linux-tools")){ continue; }
			if (pkg.name.has_prefix("linux-image")){ continue; }

			// user selected
			
			//if (!include_foreign && pkg.is_foreign){ continue; }
			//if (exclude_icons && pkg.name.contains("-icon-theme")){ continue; }
			//if (exclude_themes && pkg.name.contains("-theme") && !pkg.name.contains("-icon-theme")){ continue; }
			//if (exclude_fonts && pkg.name.has_prefix("fonts-")){ continue; }
			
			count++;

			txt += "%s".printf(pkg.name);
			
			if (pkg.desc.length > 0){
				txt += " # %s".printf(pkg.desc);
			}

			txt += "\n";
		}

		bool ok = file_write(backup_file, txt);

		if (ok){
			chmod(backup_file, "a+rw");
			log_msg("%s: %s (%d packages)".printf(_("Saved"), backup_file, count));
		}

		return ok;
	}

	public string create_backup_path(string basepath){
		
		string backup_path = path_combine(basepath, "packages");
		dir_create(backup_path);
		chmod(backup_path, "a+rwx");
		return backup_path;
	}
	
	// restore
	
	private void restore_init() {

		log_debug("PackageWindow.restore_init()");
		
		var status_msg = _("Listing items from backup...");
		var dlg = new ProgressWindow.with_parent(this, status_msg);
		dlg.show_all();
		gtk_do_events();

		try {
			is_running = true;
			Thread.create<void> (restore_init_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		dlg.pulse_start();
		//dlg.update_status_line(true);
		
		while (is_running) {
			//dlg.update_message(App.status_line);
			dlg.sleep(200);
		}

		treeview_refresh();

		//disconnect combo events
		cmb_filters_disconnect();
		//refresh combos
		cmb_status_refresh();
		cmb_status.active = 0;
		cmb_section_refresh();
		//re-connect combo events
		cmb_filters_connect();

		treeview_refilter();

		//if (App.pkg_list_missing.length > 0) {
			//var title = _("Missing Packages");
			//var msg = _("Following packages are not available (missing PPA):\n\n%s").printf(App.pkg_list_missing);
			//gtk_messagebox(title, msg, this, false);
		//}

		dlg.destroy();
		gtk_do_events();
	}

	private void restore_init_thread() {

		log_debug("PackageWindow.restore_init_thread()");
		
		packages.clear();
		
		string std_out, std_err;
		string cmd = "aptik --dump-packages-backup --basepath '%s'".printf(escape_single_quote(App.basepath));
		exec_sync(cmd, out std_out, out std_err);

		foreach(string line in std_out.split("\n")){

			var match = regex_match("""NAME='(.*)',DESC='(.*)',A='(0|1)',I='(0|1)'""", line);
			
			if (match != null){
				
				var pkg = new Package();
				packages.add(pkg);
				
				pkg.name = match.fetch(1);
				pkg.desc = match.fetch(2);
				pkg.is_available = (match.fetch(3) == "1") ? true : false;
				pkg.is_installed = (match.fetch(4) == "1") ? true : false;
			}
		}

		log_msg("count=%d".printf(packages.size));

		packages.sort((a,b) => {
			return strcmp(a.name,b.name);
		});

		foreach(var pkg in packages){
			pkg.is_selected = !pkg.is_installed;
		}
		
		is_running = false;
	}

	private void btn_restore_clicked() {

		log_debug("PackageWindow.btn_restore_clicked()");
		
		// check if no action required ------------------------------
		
		bool none_selected = true;
		
		foreach(var pkg in packages) {
			if (pkg.is_selected && !pkg.is_installed) {
				none_selected = false;
				break;
			}
		}
		
		if (none_selected) {
			string title = _("Nothing To Do");
			string msg = _("All packages are already installed, or no packages are selected for installation");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		if (!check_internet_connectivity()) {
			string title = _("Error");
			string msg = Messages.INTERNET_OFFLINE;
			gtk_messagebox(title, msg, this, false);
			return;
		}

		this.hide();

		App.main_window.execute("pkexec aptik --restore-packages --basepath '%s'".printf(App.basepath));
	}
}

public class Package : GLib.Object {
	
	public string name = "";
	public string arch = "";
	public string desc = "";
	public bool is_available = false;
	public bool is_installed = false;
	public bool is_selected = false;
	public bool is_dist = false;
	public bool is_auto = false;
	public bool is_user = false;
	public bool is_foreign = false;
	public bool is_manual = false;
}

