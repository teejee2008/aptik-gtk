/*
 * TermBox.vala
 *
 * Copyright 2017 Tony George <teejeetech@gmail.com>
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
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;

public class TermBox : Gtk.Box {

	private Vte.Terminal term;
	private Pid child_pid;
	private bool cancelled = false;
	private bool is_running = false;

	private bool as_admin = false;
	private bool bash_initialized = false;
	
	private Gtk.Window window;

	public const int DEF_FONT_SIZE = 11;
	public const string DEF_COLOR_FG = "#DCDCDC";
	public const string DEF_COLOR_BG = "#2C2C2C";

	public signal void shell_exited();
	
	public signal void child_exited();
	
	public TermBox(Gtk.Window _window){
		//base(Gtk.Orientation.VERTICAL, 6); // issue with vala
		Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0); // work-around

		margin = 0;
		spacing = 0;
		
		window = _window;
		
		init_ui();
	}

	private void init_ui(){

		log_debug("TermBox: init_ui()");

		//scrolled
		var scrolled = new Gtk.ScrolledWindow(null, null);
		scrolled.set_shadow_type(ShadowType.ETCHED_IN);
		scrolled.expand = true;
		scrolled.hscrollbar_policy = PolicyType.AUTOMATIC;
		scrolled.vscrollbar_policy = PolicyType.AUTOMATIC;
		this.add(scrolled);

		//terminal
		term = new Vte.Terminal();
		term.expand = true;
		term.set_size_request(2000,-1);
		scrolled.add(term);
		
		term.input_enabled = true;
		term.backspace_binding = Vte.EraseBinding.AUTO;
		term.cursor_blink_mode = Vte.CursorBlinkMode.SYSTEM;
		term.cursor_shape = Vte.CursorShape.UNDERLINE;
		term.rewrap_on_resize = true;
		term.allow_bold = false;

		term.scroll_on_keystroke = true;
		term.scroll_on_output = true;
		term.scrollback_lines = 100000;

		var fontdesc = Pango.FontDescription.from_string("liberation mono,droid sans mono,ubuntu mono,monospace regular 10");

		set_font_desc(fontdesc);
		
		set_color_foreground("#EEEEEC");
		
		set_color_background("#2E3436");

		// donation link

		var hbox = new Gtk.Box(Orientation.HORIZONTAL, 6);
		this.add(hbox);

		var bbox = new Gtk.ButtonBox(Orientation.HORIZONTAL);
		bbox.set_layout(Gtk.ButtonBoxStyle.CENTER);
		this.add(bbox);

		var lbtn = new Gtk.LinkButton.with_label("", _("Buy me a coffee"));
		lbtn.set_tooltip_text("PayPal");
		bbox.add(lbtn);

		lbtn.clicked.connect(() => { 
			var win = new DonationWindow(window); 
			win.show(); 
		});
		
		//lbtn.clicked.connect(() => {
		//	xdg_open("https://www.paypal.com/cgi-bin/webscr?business=teejeetech@gmail.com&cmd=_xclick&currency_code=USD&amount=5&item_name=Aptik%20Donation", "");
		//});
	}

	public void start_shell(bool _as_admin){

		log_debug("TermBox: start_shell()");

		as_admin = _as_admin;
		
		string[] argv;

		string shell_path = cmd_exists("bash") ? get_cmd_path("bash") : get_cmd_path("sh");

		if (as_admin){
			argv = new string[2];
			argv[0] = get_cmd_path("pkexec");
			argv[1] = shell_path;
		}
		else{
			argv = new string[1];
			argv[0] = shell_path;
		}
		
		string[] env = Environ.get();
		
		try{

			is_running = true;
			
			term.spawn_sync(
				Vte.PtyFlags.DEFAULT, //pty_flags
				"/root", //working_directory
				argv, //argv
				env, //env
				GLib.SpawnFlags.SEARCH_PATH, //spawn_flags
				null, //child_setup
				out child_pid,
				null
			);

			bash_initialized = false;

			init_bash();

			term.child_exited.connect((status)=>{
				
				log_debug("TermBox: shell_exited(): pid=%d, status=%d".printf(child_pid, status));
				
				child_exited();
				
				shell_exited();
				
				//if (!cancelled){
				//	start_shell(as_admin);
				//}
			});

			reset();

			//string cmd = "setterm -linewrap off";
			//feed_command(cmd);

			log_debug("TermBox: start_shell(): started");
		}
		catch (Error e) {
			log_error (e.message);
		}
	}

	public void init_bash(){

		if (bash_initialized){ return; }

		//string cmd = """PS1='\[\033[01;93m\]\$ \[\033[00m\]'""";

		string cmd = """PS1='\[\033[01;32m\]\t \[\033[01;93m\]\$ \[\033[00m\]'""";

		//if (as_admin){
			//cmd = cmd.replace("""\$""", """\#""");
		//}

		feed_command(cmd);

		bash_initialized = true;
	}

	public void exit_shell(){
		cancelled = true;
		feed_command("exit");
	}

	public void restart_shell(){
		exit_shell();
		start_shell(as_admin);
	}

	public void terminate_child(){
		cancelled = true;
		process_quit(child_pid);
	}

	public bool has_running_process {
		get{
			var children = get_process_children(child_pid);
			return (children.length > 0);
		}
	}

	public int get_status(){

		string status_file = "/tmp/aptik-last-status";
		
		feed_command("echo $? > '%s'".printf(status_file));

		sleep(100);
		
		if (file_exists(status_file)){
			int status = int.parse(file_read(status_file));
			return status;
		}
		else{
			return -1;
		}
	}

	public int get_child_pid() {
		return child_pid;
	}

	public void feed_command(string command, bool newline = true, bool signal_child_exit = false){
		
		string cmd = command;

		if (newline){
			cmd = "%s\n".printf(cmd);
		}
		
		term.feed_child(cmd.to_utf8());

		if (signal_child_exit){

			Timeout.add(1000, ()=>{

				if (!has_running_process){
					
					child_exited();
					return false;
				}
				
				return true;
			});
		}
	}

	public void refresh(){

		log_debug("TermBox: refresh()");
		
		if (this.visible && !is_running){
			start_shell(as_admin);
		}
	}

	public void change_directory(string dir_path){

		log_debug("TermBox: change_directory()");

		feed_command("cd '%s'".printf(escape_single_quote(dir_path)));
	}

	private void show_running_process_message(){
		// TODO: Add check to ignore background process
		gtk_messagebox(_("Terminal is busy"),_("This action cannot be executed while a process is running"), window, true);
	}

	public void copy(){

		log_debug("TermBox: copy()");
		
		term.copy_primary();

		Gdk.Display display = this.get_display ();
		var clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_PRIMARY);
		string txt = clipboard.wait_for_text();
		if (txt != null){
			clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
			clipboard.set_text(txt, -1);
		}
	}

	public void paste(){

		log_debug("TermBox: paste()");
		
		Gdk.Display display = this.get_display ();
		Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
		string txt = clipboard.wait_for_text();
		if (txt != null){
			feed_command(txt, false);
		}
	}

	public void reset(){

		log_debug("TermBox: reset()");

		feed_command("tput reset");
	}

	public void open_settings(){

		log_debug("TermBox: open_settings()");

		feed_command("fish_config");
	}

	public void set_font_size(int size_pts){
		term.font_desc = Pango.FontDescription.from_string("normal %d".printf(size_pts));
	}

	public void set_font_desc(Pango.FontDescription font_desc){
		term.set_font(font_desc);
	}

	public void set_color_foreground(string color){

		log_debug("TermBox: set_color_foreground(): %s".printf(color));
		
		var rgba = Gdk.RGBA();
		rgba.parse(color);
		term.set_color_foreground(rgba);
	}
	
	public void set_color_background(string color){
		
		log_debug("TermBox: set_color_background(): %s".printf(color));
		
		var rgba = Gdk.RGBA();
		rgba.parse(color);
		term.set_color_background(rgba);
	}

	public void set_defaults(){
		set_font_size(DEF_FONT_SIZE);
		set_color_foreground(DEF_COLOR_FG);
		set_color_background(DEF_COLOR_BG);
	}

	public void chroot_current(){
		
		feed_command("sudo polo-chroot $(pwd)");
	}

	public void chroot(string path){

		var cmd = "sudo polo-chroot '%s' \n".printf(
			//App.term_enable_network ? "--enable-network" : "",
			//App.term_enable_gui ? "--enable-gui" : "",
			escape_single_quote(path));
		
		feed_command(cmd);
	}
}

