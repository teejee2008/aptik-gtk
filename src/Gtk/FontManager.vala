/*
 * FontManager.vala
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

public class FontManager : ManagerBox {

	public FontManager(MainWindow parent) {
		
		base(parent, "fonts", "font-x-generic", false);
	}

	public override void init_ui_mode(Mode _mode) {
		
		base.init_ui_mode(_mode);
		
		col_name.title = _("Font File");
		col_desc.visible = false;

		/*if (mode == Mode.BACKUP){
			col_status.visible = false;
		}
		else if (mode == Mode.RESTORE){
			col_status.visible = true;
		}*/
		
		gtk_hide(cmb_status);
	}
}
