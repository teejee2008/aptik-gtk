/*
 * ScriptManager.vala
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

public class ScriptManager : ManagerBox {

	protected Gtk.TreeViewColumn col_enable;
	
	public ScriptManager(MainWindow parent) {
		
		base(parent, "scripts", "text-x-script", false, true, true);
	}

	protected override void init_ui(){
		
		base.init_ui();

		col_name.title = _("Script");

		gtk_hide(hbox_filter);

		gtk_hide(bbox_selection);

		gtk_hide(bbox_execute);

		// actions ----------------
		
		var bbox = new Gtk.ButtonBox(Orientation.HORIZONTAL);
		bbox.set_spacing(6);
		bbox.hexpand = true;
		bbox.set_layout(Gtk.ButtonBoxStyle.CENTER);
		hbox_actions.add(bbox);

		//btn_add_files
		var button = new Gtk.Button.with_label(_("Add Script File"));
		button.set_size_request(150,-1);
		bbox.add(button);

		button.clicked.connect(btn_add_files_clicked);

		//btn_remove
		button = new Gtk.Button.with_label(_("Remove Selected"));
		button.set_size_request(150,-1);
		bbox.add(button);

		button.clicked.connect(btn_remove_clicked);

		show_all();
	}

	protected override void init_treeview() {

		base.init_treeview();

		col_enable = new TreeViewColumn();
		col_enable.title = _("Enable");
		col_enable.resizable = true;
		//col_enc.min_width = 180;
		//treeview.append_column(col_enable);

		var cell_enable = new Gtk.CellRendererText();
		cell_enable.ellipsize = Pango.EllipsizeMode.END;
		col_enable.pack_start(cell_enable, false);

		col_enable.set_cell_data_func(cell_enable, cell_enable_data_func);
	}

	protected void cell_enable_data_func(CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){

		Item item;
		model.get (iter, 2, out item, -1);

		string txt = "";
		
		if (item.name.has_prefix("_")){
			
			txt = item.name.replace("_","/");

			if (txt.has_suffix(".tar.gz")){
				txt = txt.replace(".tar.gz","");
			}

			if (txt.has_suffix(".tar.xz")){
				txt = txt.replace(".tar.xz","");
			}
		}
		else{
			txt = "???";
		}

		(cell as Gtk.CellRendererText).text = txt;
	}

	protected virtual void btn_add_files_clicked() {

		log_debug("ScriptManager.btn_add_files_clicked()");

		var filters = new Gee.ArrayList<Gtk.FileFilter>();
		
		var filter = create_file_filter(_("All Files"), { "*" });
		filters.add(filter);
		
		filter = create_file_filter("Bash Script Files (*.sh*)", { "*.sh" });
		filters.add(filter);
		
		var default_filter = filter;

		var selected_items = gtk_select_files(window, true, true, filters, default_filter);
		//string iso_file = (selected_files.size > 0) ? selected_files[0] : "";

		if (selected_items.size == 0){
			return;
		}
		
		// save backup ---------------------

		foreach(string file in selected_items){
			string dst_file = path_combine(App.basepath, "scripts/files/" + file_basename(file));
			file_copy(file, dst_file);
			chmod(dst_file, "a+rw");
		}

		init_ui_mode(App.mode);
	}

	protected virtual void btn_remove_clicked() {

		log_debug("ScriptManager.btn_remove_clicked()");
		
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
			string msg = _("Select items to remove");
			gtk_messagebox(title, msg, window, false);
			return;
		}

		// save backup ---------------------

		foreach(var item in items) {
			if (item.is_selected){
				string dst_file = path_combine(App.basepath, "scripts/files/" + item.name);
				file_delete(dst_file);
			}
		}

		init_ui_mode(App.mode);
	}
}
