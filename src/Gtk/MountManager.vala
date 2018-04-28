/*
 * MountManager.vala
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

public class MountManager : ManagerBox {

	//protected Gtk.TreeViewColumn col_name;
	protected Gtk.TreeViewColumn col_device;
	protected Gtk.TreeViewColumn col_mp;
	protected Gtk.TreeViewColumn col_fstype;
	protected Gtk.TreeViewColumn col_options;
	protected Gtk.TreeViewColumn col_dump;
	protected Gtk.TreeViewColumn col_pass;

	protected Gtk.RadioButton rbtn_fstab;
	protected Gtk.RadioButton rbtn_crypttab;
	
	protected Gtk.TreeViewColumn col_password;
	
	public MountManager(MainWindow parent) {
		
		base(parent, "mounts", "drive-harddisk", false);
	}

	public override void init_ui_mode(Mode _mode) {
		
		base.init_ui_mode(_mode);
		
		rbtn_fstab.active = true;
		btn_fstab_clicked();
	}

	protected override void init_treeview() {

		base.init_treeview();

		col_device = add_column(_("Device"));
		var cell_txt = add_cell_text(col_device);
		col_device.set_cell_data_func(cell_txt, cell_device_data_func);

		col_device.min_width = 180;

		col_mp = add_column(_("MountPath"));
		cell_txt = add_cell_text(col_mp);
		col_mp.set_cell_data_func(cell_txt, cell_mp_data_func);

		cell_txt.ellipsize = Pango.EllipsizeMode.NONE;

		col_fstype = add_column(_("FS"));
		cell_txt = add_cell_text(col_fstype);
		col_fstype.set_cell_data_func(cell_txt, cell_fstype_data_func);

		cell_txt.ellipsize = Pango.EllipsizeMode.NONE;
		
		col_password = add_column(_("Password / Keyfile"));
		cell_txt = add_cell_text(col_password);
		col_password.set_cell_data_func(cell_txt, cell_password_data_func);

		col_password.min_width = 20;
		
		col_options = add_column(_("Options"));
		cell_txt = add_cell_text(col_options);
		col_options.set_cell_data_func(cell_txt, cell_options_data_func);

		col_options.min_width = 20;

		col_dump = add_column(_("D"));
		cell_txt = add_cell_text(col_dump);
		col_dump.set_cell_data_func(cell_txt, cell_dump_data_func);

		col_pass = add_column(_("P"));
		cell_txt = add_cell_text(col_pass);
		col_pass.set_cell_data_func(cell_txt, cell_pass_data_func);
	}

	private Gtk.TreeViewColumn add_column(string title){

		var col = new Gtk.TreeViewColumn();
		col.title = title;
		col.resizable = true;
		//col.min_width = 180;
		treeview.append_column(col);

		return col;
	}

	private Gtk.CellRendererText add_cell_text(Gtk.TreeViewColumn col){

		var cell_txt = new Gtk.CellRendererText();
		cell_txt.ellipsize = Pango.EllipsizeMode.END;
		col.pack_start(cell_txt, false);

		return cell_txt;
	}

	protected void cell_device_data_func(CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){

		Item item;
		model.get (iter, 2, out item, -1);
			
		(cell as Gtk.CellRendererText).text = item.device;
	}

	protected void cell_mp_data_func(CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){

		Item item;
		model.get (iter, 2, out item, -1);
			
		(cell as Gtk.CellRendererText).text = item.mount_path;
	}

	protected void cell_fstype_data_func(CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){

		Item item;
		model.get (iter, 2, out item, -1);
			
		(cell as Gtk.CellRendererText).text = item.fstype;
	}
	
	protected void cell_options_data_func(CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){

		Item item;
		model.get (iter, 2, out item, -1);
			
		(cell as Gtk.CellRendererText).text = item.options;
	}

	protected void cell_dump_data_func(CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){

		Item item;
		model.get (iter, 2, out item, -1);
			
		(cell as Gtk.CellRendererText).text = item.dump;
	}

	protected void cell_pass_data_func(CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){

		Item item;
		model.get (iter, 2, out item, -1);
			
		(cell as Gtk.CellRendererText).text = item.pass;
	}

	protected void cell_password_data_func(CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){

		Item item;
		model.get (iter, 2, out item, -1);
			
		(cell as Gtk.CellRendererText).text = item.password;
	}

	protected override void init_filters() {

		base.init_filters();
		
		var rbtn = new Gtk.RadioButton.with_label_from_widget (null, _("Regular Devices (fstab)"));
		hbox_filter.add (rbtn);
		rbtn_fstab = rbtn;
		rbtn.toggled.connect(btn_fstab_clicked);

		rbtn = new Gtk.RadioButton.with_label_from_widget (rbtn, _("Encrypted Devices (crypttab)"));
		hbox_filter.add (rbtn);
		rbtn_crypttab = rbtn;
		rbtn.toggled.connect(btn_crypttab_clicked);

		gtk_hide(txt_filter);
		
		gtk_hide(cmb_status);

		gtk_hide(lbl_count);
	}

	private void btn_fstab_clicked(){

		col_name.visible = false;
		col_desc.visible = false;
		
		col_device.visible = true;
		col_mp.visible = true;
		col_fstype.visible = true;
		col_password.visible = false;
		col_options.visible = true;
		col_dump.visible = true;
		col_pass.visible = true;

		treeview_refilter();

		treeview.columns_autosize();
	}

	private void btn_crypttab_clicked(){

		col_name.visible = true;
		col_desc.visible = false;
		
		col_device.visible = true;
		col_mp.visible = false;
		col_fstype.visible = false;
		col_password.visible = true;
		col_options.visible = true;
		col_dump.visible = false;
		col_pass.visible = false;

		treeview_refilter();

		treeview.columns_autosize();
	}

	protected override bool filter_items_filter(Gtk.TreeModel model, Gtk.TreeIter iter) {

		Item item;
		model.get (iter, 2, out item, -1);
		
		bool display = false;

		if (rbtn_fstab.active){
			display = (item.type == "fstab");
		}
		else if (rbtn_crypttab.active){
			display = (item.type == "crypttab");
		}

		return display;
	}
}
