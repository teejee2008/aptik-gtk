/*
 * RepoWindow.vala
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

public class Item : GLib.Object{
	
	public string name = "";
	public string desc = "";
	public bool selected = false;
	public bool installed = false;
}

public class RepoWindow : Window {

	public Gee.ArrayList<Repo> repos = new Gee.ArrayList<Repo>();
	
	private Gtk.Box vbox_main;

	private Button btn_restore;
	private Button btn_backup;
	private Button btn_cancel;
	private Button btn_select_all;
	private Button btn_select_none;
	
	private TreeView treeview;
	//private TreeViewColumn col_status;
	private ScrolledWindow scrolled;

	private int def_width = 700;
	private int def_height = 450;
	private uint tmr_init = 0;
	
	private bool is_running = false;
	private bool is_restore_view = false;

	private bool is_backup_view{
		get{
			return !is_restore_view;
		}
	}

	// init -------------------------
	
	public RepoWindow(Window parent, bool restore) {
		
		set_transient_for(parent);
		set_modal(true);
		is_restore_view = restore;

		destroy.connect(()=>{
			parent.present();
		});
		
		init_window();
	}

	public void init_window () {
	
		window_position = WindowPosition.CENTER;
		set_default_size (def_width, def_height);
		icon = get_app_icon(16);
		resizable = true;
		deletable = true;

		//vbox_main
		vbox_main = new Gtk.Box (Orientation.VERTICAL, 6);
		vbox_main.margin = 6;
		add (vbox_main);

		//treeview
		init_treeview();

		//buttons
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

	private void init_treeview() {
		
		// treeview
		treeview = new Gtk.TreeView();
		treeview.get_selection().mode = SelectionMode.MULTIPLE;
		treeview.headers_clickable = true;
		//treeview.set_rules_hint (true);
		//treeview.set_tooltip_column(3);

		// scrolled
		scrolled = new Gtk.ScrolledWindow(null, null);
		scrolled.set_shadow_type (ShadowType.ETCHED_IN);
		scrolled.add (treeview);
		scrolled.expand = true;
		vbox_main.add(scrolled);

		// col_select ----------------------

		var col_select = new Gtk.TreeViewColumn();
		col_select.title = "";
		treeview.append_column(col_select);
		
		var cell_select = new Gtk.CellRendererToggle();
		cell_select.activatable = true;
		col_select.pack_start (cell_select, false);

		col_select.set_cell_data_func (cell_select, (cell_layout, cell, model, iter) => {
			
			bool selected;
			Item item;
			model.get (iter, 0, out selected, 1, out item, -1);
			(cell as Gtk.CellRendererToggle).active = selected;
			(cell as Gtk.CellRendererToggle).sensitive = !is_restore_view || !item.installed;
		});

		cell_select.toggled.connect((path) => {
			
			var model = (Gtk.ListStore)treeview.model;
			bool selected;
			Item item;
			TreeIter iter;

			model.get_iter_from_string (out iter, path);
			model.get (iter, 0, out selected);
			model.get (iter, 1, out item);
			model.set (iter, 0, !selected);
			item.selected = !selected;
		});

		// col_status ----------------------

		var col_status = new Gtk.TreeViewColumn();
		col_status.resizable = true;
		treeview.append_column(col_status);

		var cell_status = new Gtk.CellRendererPixbuf ();
		col_status.pack_start (cell_status, false);
		col_status.set_attributes(cell_status, "pixbuf", 2);

		// col_name ----------------------

		var col_name = new Gtk.TreeViewColumn();
		col_name.title = _("Repo");
		col_name.resizable = true;
		col_name.min_width = 180;
		treeview.append_column(col_name);

		var cell_name = new Gtk.CellRendererText ();
		cell_name.ellipsize = Pango.EllipsizeMode.END;
		col_name.pack_start (cell_name, false);

		col_name.set_cell_data_func (cell_name, (cell_layout, cell, model, iter) => {
			Item item;
			model.get (iter, 1, out item, -1);
			(cell as Gtk.CellRendererText).text = item.name;
		});

		// col_desc ----------------------

		var col_desc = new Gtk.TreeViewColumn();
		if (is_restore_view){
			col_desc.title = _("Packages");
		}
		else{
			col_desc.title = _("Packages");
		}
		col_desc.resizable = true;
		treeview.append_column(col_desc);

		var cell_desc = new Gtk.CellRendererText ();
		cell_desc.ellipsize = Pango.EllipsizeMode.END;
		col_desc.pack_start (cell_desc, false);

		col_desc.set_cell_data_func (cell_desc, (cell_layout, cell, model, iter) => {
			Item item;
			model.get (iter, 1, out item, -1);
			(cell as Gtk.CellRendererText).text = item.desc;
		});
	}

	private void init_actions() {
		
		var hbox = new Box (Orientation.HORIZONTAL, 6);
		vbox_main.add (hbox);

		// btn_select_all
		var button = new Gtk.Button.with_label (_("Select All"));
		hbox.pack_start (button, true, true, 0);
		btn_select_all = button;
		
		button.clicked.connect(() => {
			
			foreach(var repo in repos) {
				
				if (is_restore_view) {
					
					if (!repo.is_installed) {
						repo.is_selected = true;
					}
					else {
						//no change
					}
				}
				else {
					repo.is_selected = true;
				}
			}
			
			treeview_refresh();
		});

		// btn_select_none
		button = new Gtk.Button.with_label (" " + _("Select None") + " ");
		hbox.pack_start (button, true, true, 0);
		btn_select_none = button;
		
		btn_select_none.clicked.connect(() => {
			
			foreach(var repo in repos) {
				
				if (is_restore_view) {
					
					if (!repo.is_installed) {
						repo.is_selected = false;
					}
					else {
						//no change
					}
				}
				else {
					repo.is_selected = false;
				}
			}
			
			treeview_refresh();
		});

		// btn_backup
		button = new Gtk.Button.with_label (" <b>" + _("Backup") + "</b> ");
		button.no_show_all = true;
		hbox.pack_start(button, true, true, 0);
		btn_backup = button;
		
		button.clicked.connect(btn_backup_clicked);

		// btn_restore
		button = new Gtk.Button.with_label (" <b>" + _("Restore") + "</b> ");
		button.no_show_all = true;
		hbox.pack_start(button, true, true, 0);
		btn_restore = button;
		
		button.clicked.connect(btn_restore_clicked);

		// btn_cancel
		button = new Gtk.Button.with_label (" " + _("Close") + " ");
		hbox.pack_start(button, true, true, 0);
		btn_cancel = button;
		
		button.clicked.connect(() => {
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

	private void treeview_refresh() {
		
		var model = new Gtk.ListStore(4, typeof(bool), typeof(Repo), typeof(Gdk.Pixbuf), typeof(string));

		Gdk.Pixbuf pix_enabled = IconManager.lookup("item-green", 16);
		Gdk.Pixbuf pix_missing = IconManager.lookup("item-gray", 16);

		TreeIter iter;

		foreach(var repo in repos) {
			
			//add row
			model.append(out iter);
			model.set (iter, 0, repo.is_selected);
			model.set (iter, 1, repo);
			model.set (iter, 2, repo.is_installed ? pix_enabled : pix_missing);
			model.set (iter, 3, "");
		}

		treeview.set_model(model);
		treeview.columns_autosize();
	}

	private void backup_init(){

		log_debug("RepoWindow.backup_init()");
		
		var status_msg = _("Listing repositories...");
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

		dlg.destroy();
		gtk_do_events();
	}

	private void backup_init_thread() {

		log_debug("RepoWindow.backup_init_thread()");
		
		repos.clear();
		
		string std_out, std_err;
		exec_sync("aptik --dump-repos", out std_out, out std_err);
		
		foreach(string line in std_out.split("\n")){

			if (line.strip().length == 0) { continue; }
			
			var match = regex_match("""NAME='(.*)',DESC='(.*)'""", line);
			
			if (match != null){
				
				var repo = new Repo();
				repos.add(repo);
				
				repo.name = match.fetch(1);
				repo.desc = match.fetch(2);
				repo.is_installed = true;
			}
			else{
				log_debug("no-match: %s".printf(line));
			}
		}

		repos.sort((a,b) => {
			return strcmp(a.name,b.name);
		});

		foreach(var repo in repos){
			repo.is_selected = repo.is_installed;
		}
		
		is_running = false;
	}

	private void restore_init(){

		log_debug("RepoWindow.backup_init()");
		
		var status_msg = _("Listing items from backup...");
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

		dlg.destroy();
		gtk_do_events();
	}

	private void restore_init_thread(){
		
		log_debug("RepoWindow.restore_init_thread()");
		
		repos.clear();
		
		string std_out, std_err;
		exec_sync("aptik --dump-repos-backup", out std_out, out std_err);
		
		foreach(string line in std_out.split("\n")){

			if (line.strip().length == 0) { continue; }
			
			var match = regex_match("""NAME='(.*)',DESC='(.*)',I='(0|1)'""", line);
			
			if (match != null){
				
				var repo = new Repo();
				repos.add(repo);
				
				repo.name = match.fetch(1);
				repo.desc = match.fetch(2);
				repo.is_installed = (match.fetch(3) == "1") ? true : false;
			}
			else{
				log_debug("no-match: %s".printf(line));
			}
		}

		repos.sort((a,b) => {
			return strcmp(a.name,b.name);
		});

		foreach(var repo in repos){
			repo.is_selected = !repo.is_installed;
		}
		
		is_running = false;
	}

	private void btn_backup_clicked(){

	}

	private void btn_restore_clicked(){

	}
}

public class Repo : GLib.Object {
	
	public string name = "";
	public string desc = "";
	public bool is_installed = false;
	public bool is_selected = false;
}
