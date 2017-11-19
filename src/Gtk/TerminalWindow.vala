/*
 * TerminalWindow.vala
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

public class TerminalWindow : Gtk.Window {
	
	private Gtk.Box vbox_main;
	private TermBox term;
	private Gtk.Button btn_cancel;

	private int def_width = 800;
	private int def_height = 500;

	private Gtk.Window parent_win = null;

	// init
	
	public TerminalWindow.with_parent(Gtk.Window? parent, bool fullscreen = false, bool show_cancel_button = false) {
		
		if (parent != null){
			set_transient_for(parent);
			parent_win = parent;
		}
		
		set_modal(false);
		window_position = WindowPosition.CENTER;

		if (fullscreen){
			this.fullscreen();
		}

		this.delete_event.connect(on_delete_event);
		
		init_window();
	}

	public bool on_delete_event(){

		if (term.has_running_process){
			term.terminate_child();
			return true; // stay open
		}

		this.hide();
		return true; // stay open
	}

	public void init_window () {
		
		title = "";
		icon = get_app_icon(16);
		resizable = true;
		deletable = true;
		
		// vbox_main ------------------------------
		
		vbox_main = new Gtk.Box(Orientation.VERTICAL, 0);
		vbox_main.margin = 0;
		vbox_main.set_size_request(def_width, def_height);
		this.add(vbox_main);

		// terminal ------------------------------

		term = new TermBox(this);
		term.expand = true;
		vbox_main.add(term);

		// actions ------------------------------

		var bbox = new Gtk.ButtonBox(Orientation.HORIZONTAL);
		bbox.set_layout(Gtk.ButtonBoxStyle.CENTER);
		bbox.margin = 3;
		vbox_main.add(bbox);
		
		//btn_cancel
		var button = new Gtk.Button.with_label (_("Close"));
		bbox.add(button);
		btn_cancel = button;
		
		btn_cancel.clicked.connect(()=>{
			on_delete_event();
		});

		term.child_exited.connect(()=>{
			button.label = _("Close");
		});
	}

	public void start_shell(){

		term.start_shell();
	}
	
	public void execute_command(string cmd){

		term.feed_command(cmd);
	}

	public void reset(){

		term.reset();
	}
}


