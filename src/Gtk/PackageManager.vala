/*
 * PackageManager.vala
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

public class PackageManager : ManagerBox {

	public PackageManager(MainWindow parent) {
		
		base(parent, "packages", "package-x-generic", true, true);
	}

	public override void init_ui_mode(Mode _mode) {

		base.init_ui_mode(_mode);
		
		log_debug("PackageManager.init_ui_mode()");

		col_name.title = _("Package");
		col_desc.title = _("Description");
	}
	
	protected override void init_cmb_status(){

		base.init_cmb_status();
		
		string tt = "";
		tt += _("<b>Installed</b>\nAll installed items.") + "\n\n";
		tt += _("<b>Installed (dist)</b>\nLinux distribution base items (excluded by default)") + "\n\n";
		tt += _("<b>Installed (user)</b>\nExtra items explicitly installed by user") + "\n\n";
		tt += _("<b>Installed (auto)</b>\nAutomatically installed dependency items (excluded by default)") + "\n\n";
		tt += _("<b>Installed (manual)</b>\nPackages installed from unknown sources (not available in repositories)") + "\n\n";
		tt += _("<b>Installed (foreign)</b>\nInstalled items with foreign architecture (excluded by default)") + "\n\n";
		tt += _("<b>Installed (libs)</b>\nLibrary items (excluded by default)") + "\n\n";
		tt += _("<b>Installed (icons)</b>\nIcon theme items (can be excluded from backup)") + "\n\n";
		tt += _("<b>Installed (themes)</b>\nTheme items (can be excluded from backup)") + "\n\n";
		tt += _("<b>Installed (fonts)</b>\nFont items (can be excluded from backup)") + "\n\n";
		tt += _("<b>Backup List</b>\nPackages listed in backup");
		cmb_status.set_tooltip_markup(tt);
	}

	/*private void init_cmb_section(){

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
	}*/

	// events

	protected override void on_drag_data_received (Gdk.DragContext drag_context, int x, int y, Gtk.SelectionData data, uint info, uint time) {
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

	protected override void cmb_status_refresh() {

		log_debug("PackageManager.cmb_status_refresh()");
		
		var store = new Gtk.ListStore(2, typeof(string), typeof(Gdk.Pixbuf));

		TreeIter iter;

		switch (mode) {
		case Mode.RESTORE:
			store.append(out iter);
			store.set (iter, 0, _("Backup List"), 1, null);

			store.append(out iter);
			store.set (iter, 0, _("Installed"), 1, null);

			store.append(out iter);
			store.set (iter, 0, _("Not Installed"), 1, null);

			store.append(out iter);
			store.set (iter, 0, _("Not Available"), 1, null);
			break;
			
		case Mode.BACKUP:
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
			break;
		}
		
		cmb_status.set_model (store);
		cmb_status.active = 0;
	}

	/*private void cmb_section_refresh() {

		log_debug("PackageManager.treeview_refresh()");
		
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

	protected override bool filter_items_filter(Gtk.TreeModel model, Gtk.TreeIter iter) {

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

		switch (mode){
		case Mode.RESTORE:
		
			display = false;

			switch (cmb_status.active) {
			case 0: //Backup list
				display = true;
				break;
			case 1: //Installed
				if (item.is_installed) {
					display = true;
				}
				break;
			case 2: //Not Installed
				if (!item.is_installed) {
					display = true;
				}
				break;
			case 3: //Not Available
				if (!item.is_available) {
					display = true;
				}
				break;
			}

			break;
			
		case Mode.BACKUP:
		
			display = false;
			
			switch (cmb_status.active) {
			case 0: //installed
				if (item.is_installed) {
					display = true;
				}
				break;
			case 1: //Installed, Distribution
				if (item.is_dist) {
					display = true;
				}
				break;
			case 2: //Installed, User
				if (item.is_user) {
					display = true;
				}
				break;
			case 3: //Installed, Automatic
				if (item.is_auto) {
					display = true;
				}
				break;
			case 4: //Installed, manual
				if (item.is_manual) {
					display = true;
				}
				break;
			case 5: //Installed, foreign
				if (item.is_foreign) {
					display = true;
				}
				break;
			case 6: //Installed, libs
				if (item.name.has_prefix("lib")) {
					display = true;
				}
				break;
			case 7: //Installed, icons
				if (item.name.contains("-icon-theme")) {
					display = true;
				}
				break;
			case 8: //Installed, themes
				if (item.name.contains("-theme") && !item.name.contains("-icon-theme")) {
					display = true;
				}
				break;
			case 9: //Installed, fonts
				if (item.name.has_prefix("fonts-")) {
					display = true;
				}
				break;
			}

			break;
		}

		//switch (cmb_pkg_section.active) {
		//case 0: //all
			//exclude nothing
			//break;
		//default:
			//if (item.section != gtk_combobox_get_value(cmb_pkg_section, 0, ""))
			//{
			//	display = false;
			//}
			//break;
		//}

		return display;
	}

	protected override void btn_restore_clicked() {

		base.btn_restore_clicked();
	}
}
