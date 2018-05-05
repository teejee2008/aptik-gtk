/*
 * ManagerBox.vala
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

public class ManagerBox : Gtk.Box {

	protected Gtk.Box vbox_main;
	
	protected Box hbox_filter;
	protected Entry txt_filter;

	protected ComboBox cmb_status;
	protected Gtk.Label lbl_count;

	protected Gtk.ButtonBox bbox_selection;
	protected Gtk.ButtonBox bbox_execute;
	
	protected Gtk.TreeView treeview;
	protected Gtk.TreeViewColumn col_select;
	protected Gtk.TreeViewColumn col_status;
	protected Gtk.TreeViewColumn col_name;
	protected Gtk.TreeViewColumn col_desc;
	protected Gtk.TreeModelFilter model_filter;
	
	protected Button btn_restore;
	protected Button btn_backup;
	protected Button btn_cancel;
	protected Button btn_select_all;
	protected Button btn_select_none;
	protected Button btn_select_reset;

	protected Gtk.Overlay overlay; 
	protected Gtk.Box? vbox_overlay;

	protected Mode mode = Mode.BACKUP;

	protected uint tmr_init = 0;
	protected uint tmr_refilter = 0;
	protected bool is_running = false;

	protected MainWindow window;

	protected string item_type = "";

	protected string item_icon_name = "";

	protected bool internet_needed_for_restore = false;

	protected bool show_status = false;

	public Gee.ArrayList<Item> items = new Gee.ArrayList<Item>();

	public ManagerBox(MainWindow parent, string _item_type, string _item_icon_name, bool _internet_needed_for_restore, bool _show_status) {

		spacing = 6;
		margin = 6;
		
		window = parent;

		item_type = _item_type;

		item_icon_name = _item_icon_name;

		internet_needed_for_restore = _internet_needed_for_restore;

		overlay = new Gtk.Overlay(); 
		this.add(overlay);
    
		vbox_main = new Gtk.Box(Orientation.VERTICAL, 6);
		overlay.add(vbox_main);

		show_status = _show_status;

		init_ui();
	}

	protected virtual void init_ui(){

		init_filters();
		
		init_treeview();
		
		init_actions();
		
		show_all();
	}

	public virtual void init_ui_mode(Mode _mode) {

		log_debug("ManagerBox.init_ui_mode()");

		mode = _mode;

		treeview_clear();

		tmr_init = Timeout.add(100, init_ui_mode_delayed);
	}

	public void start_spinner(){

		log_debug("start_spinner()");
		
		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.halign = Align.CENTER;
		vbox.valign = Align.CENTER;
		vbox_overlay = vbox;

		var spinner = new Gtk.Spinner();
		spinner.set_size_request(128,128);
		spinner.active = true;

		vbox.add(spinner);
		
		overlay.add_overlay(vbox);

		vbox_main.sensitive = false;
		window.set_sidebar_sensitive(false);
		
		show_all();
		gtk_do_events();
	}

	public void remove_overlay(){

		if (vbox_overlay == null){ return; }
		
		log_debug("remove_overlay()");

		overlay.remove(vbox_overlay);
		vbox_overlay = null;

		vbox_main.sensitive = true;
		window.set_sidebar_sensitive(true);

		gtk_do_events();
	}

	public void show_action_result(bool success){

		log_debug("show_action_result():%s".printf(success.to_string()));

		var vbox = new Gtk.Box(Orientation.VERTICAL, 6);
		vbox.halign = Align.CENTER;
		vbox.valign = Align.CENTER;
		vbox_overlay = vbox;

		Gtk.Image img;
		
		if (success){
			img = IconManager.lookup_image("action-ok", 128);
			
		}
		else{
			img = IconManager.lookup_image("action-error", 128);
		}
		
		img.set_size_request(128,128);
		vbox.add(img);
		
		overlay.add_overlay(vbox);

		overlay.show_all();
		gtk_do_events();

		Timeout.add(1000, ()=>{

			remove_overlay();
			gtk_set_busy(false, window);
			return false;
		});
	}

	protected bool init_ui_mode_delayed() {

		log_debug("ManagerBox.init_ui_mode_delayed()");
		
		switch (mode){
		case Mode.BACKUP:
			gtk_show(btn_backup);
			gtk_hide(btn_restore);
			backup_init();
			break;
			
		case Mode.RESTORE:
			gtk_hide(btn_backup);
			gtk_show(btn_restore);
			restore_init();
			break;
		}

		return false;
	}

	protected virtual void init_filters() {

		log_debug("ManagerBox.init_filters()");

		//hbox_filter
		hbox_filter = new Box (Orientation.HORIZONTAL, 6);
		//hbox_filter.margin_left = 3;
		//hbox_filter.margin_right = 3;
		vbox_main.add (hbox_filter);

		//filter
		//Label lbl_filter = new Label(_("Filter"));
		//hbox_filter.add (lbl_filter);

		//txt_filter
		txt_filter = new Entry();
		txt_filter.hexpand = true;
		txt_filter.secondary_icon_pixbuf = IconManager.lookup("edit-clear",16);
		txt_filter.placeholder_text = _("Filter");
		hbox_filter.add (txt_filter);

		txt_filter.icon_release.connect((p0, p1) => {
			txt_filter.text = "";
			model_filter.refilter();
		});

		//string tt = _("Search name and description");
		//txt_filter.set_tooltip_markup(tt);
		
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

	protected virtual void init_cmb_status(){

		//cmb_status
		cmb_status = new Gtk.ComboBox();
		hbox_filter.add(cmb_status);

		var cell_cmb_status = new Gtk.CellRendererPixbuf();
		cmb_status.pack_start(cell_cmb_status, false);
		cmb_status.set_attributes(cell_cmb_status, "pixbuf", 1);
		
		var cell_pkg_restore_status = new Gtk.CellRendererText();
		cmb_status.pack_start(cell_pkg_restore_status, false );
		cmb_status.set_cell_data_func(cell_pkg_restore_status, (cell_pkg_restore_status, cell, model, iter) => {
			string status;
			model.get (iter, 0, out status, -1);
			(cell as Gtk.CellRendererText).text = status;
		});
	}

	protected virtual void init_treeview() {

		log_debug("ManagerBox.init_treeview()");
		
		//treeview
		treeview = new Gtk.TreeView();
		treeview.get_selection().mode = SelectionMode.MULTIPLE;
		treeview.headers_clickable = true;
		//treeview.set_rules_hint (true);
		treeview.set_tooltip_column(4);

		//scrolled
		var scrolled = new Gtk.ScrolledWindow(null, null);
		scrolled.set_shadow_type (ShadowType.ETCHED_IN);
		scrolled.add (treeview);
		scrolled.expand = true;
		vbox_main.add(scrolled);

		// select ----------------------

		col_select = new Gtk.TreeViewColumn();
		treeview.append_column(col_select);

		var cell_select = new Gtk.CellRendererToggle ();
		cell_select.activatable = true;
		col_select.pack_start (cell_select, false);

		col_select.set_cell_data_func(cell_select, cell_select_data_func);

		cell_select.toggled.connect(cell_select_toggled);

		// status ----------------------

		col_status = new TreeViewColumn();
		//col_status.title = _("");
		col_status.resizable = true;
		treeview.append_column(col_status);

		var cell_pkg_status = new CellRendererPixbuf ();
		col_status.pack_start (cell_pkg_status, false);
		col_status.set_attributes(cell_pkg_status, "pixbuf", 3);

		// name ----------------------

		col_name = new TreeViewColumn();
		col_name.title = _("Name");
		col_name.resizable = true;
		//col_name.min_width = 180;
		treeview.append_column(col_name);

		var cell_name = new CellRendererText ();
		cell_name.ellipsize = Pango.EllipsizeMode.NONE;
		col_name.pack_start (cell_name, false);

		col_name.set_cell_data_func(cell_name, cell_name_data_func);

		//col_desc ----------------------

		col_desc = new TreeViewColumn();
		col_desc.title = _("Description");
		col_desc.resizable = true;
		//col_desc.min_width = 300;
		treeview.append_column(col_desc);

		var cell_desc = new CellRendererText ();
		cell_desc.ellipsize = Pango.EllipsizeMode.END;
		col_desc.pack_start (cell_desc, false);

		col_desc.set_cell_data_func (cell_desc, cell_desc_data_func);
	}

	protected void cell_select_data_func(CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){

		bool sensitive, active;
		Item item;
		model.get (iter, 0, out active, 1, out sensitive, 2, out item, -1);
		
		(cell as Gtk.CellRendererToggle).active = active;

		(cell as Gtk.CellRendererToggle).sensitive = sensitive;
	}

	protected void cell_select_toggled(string path){

		var store = (Gtk.ListStore) model_filter.child_model;

		TreeIter filter_iter, child_iter;
		model_filter.get_iter_from_string (out filter_iter, path);

		bool active, sensitive;
		Item item;
		model_filter.get (filter_iter, 0, out active, 1, out sensitive, 2, out item, -1);

		if (sensitive){

			item.is_selected = !active;

			model_filter.convert_iter_to_child_iter(out child_iter, filter_iter);
			store.set(child_iter, 0, item.is_selected, -1);
		}
	}

	protected void cell_name_data_func(CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){

		Item item;
		model.get (iter, 2, out item, -1);
			
		(cell as Gtk.CellRendererText).text = item.name;
	}
	
	protected void cell_desc_data_func(CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){

		Item item;
		model.get (iter, 2, out item, -1);
			
		(cell as Gtk.CellRendererText).text = item.desc;
	}
	
	protected void init_actions() {

		log_debug("ManagerBox.init_actions()");

		var box = new Gtk.Box(Orientation.HORIZONTAL, 6);
		vbox_main.add(box);

		var bbox1 = new Gtk.ButtonBox(Orientation.HORIZONTAL);
		bbox1.set_layout(Gtk.ButtonBoxStyle.EXPAND);
		box.add(bbox1);

		bbox_selection = bbox1;

		var bbox2 = new Gtk.ButtonBox(Orientation.HORIZONTAL);
		bbox2.hexpand = true;
		bbox2.set_layout(Gtk.ButtonBoxStyle.CENTER);
		box.add(bbox2);

		bbox_execute = bbox2;

		//btn_select_all
		var button = new Gtk.Button();
		button.set_image(IconManager.lookup_image("checkbox-checked-symbolic", 16));
		button.always_show_image = true;
		button.set_tooltip_text(_("Select All"));
		bbox1.add(button);

		btn_select_all = button;
		
		btn_select_all.clicked.connect(() => {

			TreeIter filter_iter;

			var store = (Gtk.ListStore) model_filter.child_model;
			
			bool iterExists = model_filter.get_iter_first (out filter_iter);
			
			while (iterExists){

				TreeIter child_iter;
				model_filter.convert_iter_to_child_iter(out child_iter, filter_iter);

				bool active, sensitive;
				Item item;
				store.get(child_iter, 0, out active, 1, out sensitive, 2, out item, -1);

				if (sensitive){
					item.is_selected = true;
					store.set(child_iter, 0, item.is_selected, -1);
				}
				
				iterExists = model_filter.iter_next(ref filter_iter);
			}
			
			treeview_refresh();
		});

		//btn_select_none
		button = new Gtk.Button();
		button.set_image(IconManager.lookup_image("checkbox-symbolic", 16));
		button.always_show_image = true;
		button.set_tooltip_text(_("Select None"));
		bbox1.add(button);

		btn_select_none = button;
		
		btn_select_none.clicked.connect(() => {
			
			TreeIter filter_iter;

			var store = (Gtk.ListStore) model_filter.child_model;
			
			bool iterExists = model_filter.get_iter_first (out filter_iter);
			
			while (iterExists){

				TreeIter child_iter;
				model_filter.convert_iter_to_child_iter(out child_iter, filter_iter);
				
				bool active, sensitive;
				Item item;
				store.get(child_iter, 0, out active, 1, out sensitive, 2, out item, -1);

				if (sensitive){
					item.is_selected = false;
					store.set(child_iter, 0, item.is_selected, -1);
				}

				iterExists = model_filter.iter_next (ref filter_iter);
			}
			
			treeview_refresh();
		});

		//btn_select_reset
		button = new Gtk.Button();
		button.set_image(IconManager.lookup_image("view-refresh-symbolic", 16));
		button.always_show_image = true;
		button.set_tooltip_text(_("Reset Selections"));
		bbox1.add(button);

		btn_select_reset = button;
		
		btn_select_reset.clicked.connect(() => {
			
			switch(mode){
			case Mode.BACKUP:
				select_items_for_backup();
				break;
			case Mode.RESTORE:
				select_items_for_restore();
				break;
			}
			
			treeview_refresh();
		});

		//btn_backup
		btn_backup = new Gtk.Button.with_label(_("Backup"));
		btn_backup.no_show_all = true;
		btn_backup.set_size_request(150,-1);
		bbox2.add(btn_backup);

		btn_backup.clicked.connect(btn_backup_clicked);

		//btn_restore
		btn_restore = new Gtk.Button.with_label(_("Restore"));
		btn_restore.no_show_all = true;
		btn_restore.set_size_request(150,-1);
		bbox2.add(btn_restore);

		btn_restore.clicked.connect(btn_restore_clicked);

		//set_bold_font_for_buttons();
	}

	protected void set_bold_font_for_buttons() {
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

	protected virtual void on_drag_data_received (Gdk.DragContext drag_context, int x, int y, Gtk.SelectionData data, uint info, uint time) {
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
			//gtk_messagebox(_("Files Copied"), msg, this, false);
		}

        Gtk.drag_finish (drag_context, true, false, time);
    }

	protected virtual void cmb_status_refresh() {

		log_debug("ManagerBox.cmb_status_refresh()");
		
		var store = new Gtk.ListStore(2, typeof(string), typeof(Gdk.Pixbuf));
		
		cmb_status.set_model (store);
		cmb_status.active = 0;
	}

	/*private virtual void cmb_section_refresh() {

		log_debug("ManagerBox.treeview_refresh()");
		
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
	}*/

	protected virtual void cmb_filters_connect() {

		log_debug("ManagerBox.cmb_filters_connect()");
		
		cmb_status.changed.connect(()=>{
			treeview_refilter();
		});

		//cmb_pkg_section.changed.connect(treeview_refilter);
		
		log_debug("connected: combo events");
	}

	protected void cmb_filters_disconnect() {
		
		cmb_status.changed.disconnect(treeview_refilter);
		//cmb_pkg_section.changed.disconnect(treeview_refilter);
		log_debug("disconnected: combo events");
	}

	protected void treeview_refilter() {
		
		log_debug("ManagerBox.treeview_refilter()");
		
		model_filter.refilter();
		
		lbl_count.label = "%d".printf(gtk_iter_count(model_filter));
	}

	protected virtual void treeview_refresh() {

		log_debug("ManagerBox.treeview_refresh()");
		
		var store = new Gtk.ListStore(5, typeof(bool), typeof(bool), typeof(Item), typeof(Gdk.Pixbuf), typeof(string));
	
		var pix_green = IconManager.lookup("item-green",16);
		var pix_gray = IconManager.lookup("item-gray",16);
		//Gdk.Pixbuf pix_red  = IconManager.lookup("item-red",16);
		//Gdk.Pixbuf pix_pink  = IconManager.lookup("item-pink",16);
		//Gdk.Pixbuf pix_yellow  = IconManager.lookup("item-yellow",16);
		//Gdk.Pixbuf pix_blue  = IconManager.lookup("item-blue",16);

		var pix_item  = IconManager.lookup(item_icon_name,16);

		TreeIter iter;
		string tt = "";
		
		foreach(var item in items) {

			var pix_selected = (mode == Mode.BACKUP) ? pix_item : (item.is_installed ? pix_green : pix_gray);
			
			store.append(out iter);
			store.set(iter, 0, item.is_selected);
			store.set(iter, 1, item.is_selectable);
			store.set(iter, 2, item);
			store.set(iter, 3, pix_selected);
			store.set(iter, 4, tt);
		}

		model_filter = new TreeModelFilter(store, null);
		model_filter.set_visible_func(filter_items_filter);
		treeview.set_model(model_filter);
		
		treeview.columns_autosize();
	}

	protected virtual void treeview_clear() {

		log_debug("ManagerBox.treeview_clear()");
		
		var store = new Gtk.ListStore(5, typeof(bool), typeof(bool), typeof(Item), typeof(Gdk.Pixbuf), typeof(string));
	
		model_filter = new TreeModelFilter(store, null);
		model_filter.set_visible_func(filter_items_filter);
		treeview.set_model(model_filter);
		
		treeview.columns_autosize();
	}

	protected virtual bool filter_items_filter(Gtk.TreeModel model, Gtk.TreeIter iter) {

		Item item;
		model.get (iter, 2, out item, -1);
		bool display = false;

		string search_string = txt_filter.text.strip().down();
		
		if ((search_string != null) && (search_string.length > 0)) {
			try {
				Regex regexName = new Regex (search_string, RegexCompileFlags.CASELESS);
				MatchInfo match_name;
				MatchInfo match_desc;
				if (regexName.match(item.name, 0, out match_name) || regexName.match (item.desc, 0, out match_desc)) {
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
		
		return display;
	}

	protected void refilter_after_timeout() {
		
		// remove pending action
		
		if (tmr_refilter > 0) {
			Source.remove(tmr_refilter);
			tmr_refilter = 0;
		}

		// add timed action
		
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

	protected void backup_init() {

		log_debug("ManagerBox.backup_init()");
		
		//var status_msg = _("Listing items...");
		//var dlg = new ProgressWindow.with_parent(parent_window, status_msg);
		//dlg.show_all();
		//gtk_do_events();

		start_spinner();
		
		try {
			is_running = true;
			Thread.create<void> (backup_init_thread, true);
		}
		catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		//dlg.pulse_start();

		while (is_running) {
			sleep(100);
			gtk_do_events();
		}

		treeview_refresh();

		//disconnect combo events
		cmb_filters_disconnect();
		
		//refresh combos
		cmb_status_refresh();
		cmb_status.active = 2;

		//re-connect combo events
		cmb_filters_connect();

		treeview_refilter();

		//dlg.destroy();
		
		//gtk_do_events();

		remove_overlay();

		show_all();
	}

	protected virtual void backup_init_thread() {

		log_debug("ManagerBox.backup_init_thread()");
		
		items.clear();
		
		string std_out, std_err;
		string cmd = "aptik --dump-%s".printf(item_type);

		log_debug("$ " + cmd);
		
		exec_sync(cmd, out std_out, out std_err);

		parse_backend_stdout(std_out);

		items.sort((a,b) => {
			return strcmp(a.name,b.name);
		});

		log_debug("count=%d".printf(items.size));

		select_items_for_backup();
		
		is_running = false;
	}

	protected virtual void select_items_for_backup(){
		
		foreach(var item in items){

			item.is_selected = item.is_selected_by_default;
		}
	}

	protected virtual void btn_backup_clicked() {

		log_debug("ManagerBox.btn_backup_clicked()");
		
		//check if no action required
		bool none_selected = true;
		foreach(var item in items) {
			if (item.is_selected) {
				none_selected = false;
				break;
			}
		}
		
		if (none_selected) {
			string title = _("No Items Selected");
			string msg = _("Select items to backup");
			gtk_messagebox(title, msg, window, false);
			return;
		}

		save_selections();
		
		// save backup ---------------------

		Timeout.add(100, ()=>{

			string cmd = "pkexec aptik --backup-%s --apply-selections".printf(item_type);
			
			string basepath = App.basepath;

			if (App.redist){
				basepath = path_combine(App.basepath, "distribution");
				cmd += " --redist";
			}

			cmd += " --basepath '%s'".printf(escape_single_quote(basepath));

			bool show_status_animation = show_status && (mode == Mode.BACKUP);
			
			window.execute(cmd, !show_status_animation);

			if (show_status_animation){
				vbox_main.sensitive = false;
				gtk_set_busy(true, window);
			}

			return false;
		});
	}

	public void save_selections(){

		string basepath = App.basepath;

		if (App.redist){
			basepath = path_combine(App.basepath, "distribution");
		}
			
		string backup_path = create_backup_path(basepath);
		
		string exclude_list = path_combine(backup_path, "selections.list");
		
		string txt = "";
		foreach(var item in items){
			txt += "%s %s\n".printf(item.is_selected ? "+" : "-", item.name);
		}
		
		file_write(exclude_list, txt, false);
		chmod(exclude_list, "a+rwx");
		
		log_debug("saved: %s".printf(exclude_list));

		//log_debug("txt: %s".printf(txt));
	}

	public virtual string create_backup_path(string basepath){
		
		string backup_path = path_combine(basepath, item_type);

		if (!dir_exists(backup_path)){
			dir_create(backup_path);
			chmod(backup_path, "a+rwx");
		}
		
		return backup_path;
	}

	public virtual void parse_backend_stdout(string std_out){

		var item = new Item();
		
		foreach(string line in std_out.split("\n")){

			var match = regex_match("""NAME='([^']*)'""", line);

			if (match != null){
				
				item = new Item();
				items.add(item);
				
				item.name = match.fetch(1);
			}

			match = regex_match("""DESC='([^']*)'""", line);
			if (match != null){
				item.desc = match.fetch(1);
			}

			//match = regex_match("""ARCH='([^']*)'""", line);
			//if (match != null){
			//	item. = match.fetch(1);
			//}

			match = regex_match("""ACT='(0|1)'""", line);
			if (match != null){
				item.is_selected = (match.fetch(1) == "1") ? true : false;
				item.is_selected_by_default = item.is_selected;
			}

			match = regex_match("""SENS='(0|1)'""", line);
			if (match != null){
				item.is_selectable= (match.fetch(1) == "1") ? true : false;
			}

			match = regex_match("""INST='(0|1)'""", line);
			if (match != null){
				item.is_installed = (match.fetch(1) == "1") ? true : false;
			}

			match = regex_match("""AVAIL='(0|1)'""", line);
			if (match != null){
				item.is_available = (match.fetch(1) == "1") ? true : false;
			}

			match = regex_match("""DIST='(0|1)'""", line);
			if (match != null){
				item.is_dist = (match.fetch(1) == "1") ? true : false;
			}

			match = regex_match("""AUTO='(0|1)'""", line);
			if (match != null){
				item.is_auto = (match.fetch(1) == "1") ? true : false;
			}

			match = regex_match("""USER='(0|1)'""", line);
			if (match != null){
				item.is_user = (match.fetch(1) == "1") ? true : false;
			}

			match = regex_match("""FOR='(0|1)'""", line);
			if (match != null){
				item.is_foreign = (match.fetch(1) == "1") ? true : false;
			}

			match = regex_match("""MAN='(0|1)'""", line);
			if (match != null){
				item.is_manual = (match.fetch(1) == "1") ? true : false;
			}

			match = regex_match("""ENC='(0|1)'""", line);
			if (match != null){
				item.is_encrypted = (match.fetch(1) == "1") ? true : false;
			}

			// mounts ------
			
			match = regex_match("""DEV='([^']*)'""", line);
			if (match != null){
				item.device = match.fetch(1);
			}

			match = regex_match("""MPATH='([^']*)'""", line);
			if (match != null){
				item.mount_path = match.fetch(1);
			}

			match = regex_match("""FS='([^']*)'""", line);
			if (match != null){
				item.fstype = match.fetch(1);
			}

			match = regex_match("""OPT='([^']*)'""", line);
			if (match != null){
				item.options = match.fetch(1);
			}

			match = regex_match("""DUMP='([^']*)'""", line);
			if (match != null){
				item.dump = match.fetch(1);
			}

			match = regex_match("""PASS='([^']*)'""", line);
			if (match != null){
				item.pass = match.fetch(1);
			}
			
			match = regex_match("""PASSWORD='([^']*)'""", line);
			if (match != null){
				item.password = match.fetch(1);
			}

			match = regex_match("""TYPE='([^']*)'""", line);
			if (match != null){
				item.type = match.fetch(1);
			}
		}
	}
	
	// restore
	
	protected virtual void restore_init() {

		log_debug("ManagerBox.restore_init()");
		
		//var status_msg = _("Listing items from backup...");
		//var dlg = new ProgressWindow.with_parent(parent_window, status_msg);
		//dlg.show_all();

		start_spinner();
		
		try {
			is_running = true;
			Thread.create<void> (restore_init_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		//dlg.pulse_start();
		//dlg.update_status_line(true);
		
		while (is_running) {
			//dlg.update_message(App.status_line);
			//dlg.sleep(200);
			sleep(100);
			gtk_do_events();
		}

		treeview_refresh();

		//disconnect combo events
		cmb_filters_disconnect();
		//refresh combos
		cmb_status_refresh();
		cmb_status.active = 0;
		//cmb_section_refresh();
		//re-connect combo events
		cmb_filters_connect();

		treeview_refilter();

		//if (App.pkg_list_missing.length > 0) {
			//var title = _("Missing Packages");
			//var msg = _("Following packages are not available (missing PPA):\n\n%s").printf(App.pkg_list_missing);
			//gtk_messagebox(title, msg, this, false);
		//}

		//dlg.destroy();
		remove_overlay();


		
		gtk_do_events();
	}

	protected virtual void restore_init_thread() {

		log_debug("ManagerBox.restore_init_thread()");
		
		items.clear();

		string std_out, std_err;
		string cmd = "aptik --dump-%s-backup --basepath '%s'".printf(item_type, escape_single_quote(App.basepath));

		log_debug("$ " + cmd);
		
		exec_sync(cmd, out std_out, out std_err);

		parse_backend_stdout(std_out);

		items.sort((a,b) => {
			return strcmp(a.name,b.name);
		});

		log_debug("count=%d".printf(items.size));

		select_items_for_restore();

		is_running = false;
	}

	protected virtual void select_items_for_restore(){
		
		foreach(var item in items){

			item.is_selected = item.is_selected_by_default;
		}
	}

	protected virtual void btn_restore_clicked() {

		log_debug("ManagerBox.btn_restore_clicked()");
		
		// check if no action required ------------------------------
		
		bool none_selected = true;
		
		foreach(var item in items) {
			if (item.is_selected && !item.is_installed) {
				none_selected = false;
				break;
			}
		}
		
		if (none_selected) {
			string title = _("No Items Selected");
			string msg = _("All items already installed. No items selected for installation.");
			gtk_messagebox(title, msg, window, false);
			return;
		}

		if (internet_needed_for_restore && !check_internet_connectivity()) {
			string title = _("Error");
			string msg = Messages.INTERNET_OFFLINE;
			gtk_messagebox(title, msg, window, false);
			return;
		}

		save_selections();
		
		// restore backup ---------------------

		Timeout.add(100, ()=>{

			string cmd = "pkexec aptik --restore-%s --apply-selections".printf(item_type);
			
			string basepath = App.basepath;

			//if (App.redist){
			//	basepath = path_combine(App.basepath, "distribution");
			//	cmd += " --redist";
			//}

			cmd += " --basepath '%s'".printf(escape_single_quote(basepath));
			
			window.execute(cmd);
			
			return false;
		});
	}
}

public class Item : GLib.Object {
	
	public string name = "";
	public string desc = "";

	public bool is_selected = false;
	public bool is_selected_by_default = false;
	public bool is_selectable = false;
	
	public bool is_available = false;
	public bool is_installed = false;
	
	public bool is_dist = false;
	public bool is_auto = false;
	public bool is_user = false;
	public bool is_foreign = false;
	public bool is_manual = false;

	public bool is_encrypted = false;

	public string device = "";
	public string mount_path = "";
	public string fstype = "";
	public string options = "";
	public string dump = "";
	public string pass = "";

	//public string name = "";
	//public string device = "";
	public string password = "";
	//public string options = "";

	public string type = "";
}

