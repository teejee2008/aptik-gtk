/*
 * UserHomeManager.vala
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

public class UserHomeManager : ManagerBox {

	protected Gtk.TreeViewColumn col_enc;
	
	public UserHomeManager(MainWindow parent) {
		
		base(parent, "home", "user-home", false, false);
	}

	public override void init_ui_mode(Mode _mode) {
		
		base.init_ui_mode(_mode);
		
		col_name.title = _("User");
		col_desc.title = _("Home Directory");

		if (mode == Mode.BACKUP){
			col_status.visible = true;
		}
		else if (mode == Mode.RESTORE){
			col_status.visible = false; // installed status is meaningless
		}

		gtk_hide(cmb_status);
	}

	protected override void init_treeview() {

		base.init_treeview();

		col_enc = new TreeViewColumn();
		col_enc.title = _("Encrypted?");
		col_enc.resizable = true;
		//col_enc.min_width = 180;
		treeview.append_column(col_enc);

		var cell_enc = new Gtk.CellRendererText();
		cell_enc.ellipsize = Pango.EllipsizeMode.END;
		col_enc.pack_start(cell_enc, false);

		col_enc.set_cell_data_func(cell_enc, cell_enc_data_func);
	}

	protected void cell_enc_data_func(CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){

		Item item;
		model.get (iter, 2, out item, -1);
			
		(cell as Gtk.CellRendererText).text = item.is_encrypted ? _("Yes") : _("No");
	}
	
}
