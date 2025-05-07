#!/usr/bin/env python3
"""
NixOS Application Recommendation Engine GUI

A simple GTK interface for the application recommendation engine.
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GdkPixbuf, GLib, Pango
import os
import sys
import threading
import subprocess
from app_recommender import AppRecommender

class AppRecommenderWindow(Gtk.Window):
    """Main window for the application recommender GUI."""
    
    def __init__(self):
        """Initialize the window."""
        Gtk.Window.__init__(self, title="NixOS App Recommender")
        self.set_default_size(800, 600)
        self.set_position(Gtk.WindowPosition.CENTER)
        
        # Initialize recommendation engine
        self.recommender = AppRecommender()
        self.recommendations = []
        
        # Main layout
        self.grid = Gtk.Grid()
        self.grid.set_column_spacing(10)
        self.grid.set_row_spacing(10)
        self.grid.set_margin_start(20)
        self.grid.set_margin_end(20)
        self.grid.set_margin_top(20)
        self.grid.set_margin_bottom(20)
        self.add(self.grid)
        
        # Header
        self.header_label = Gtk.Label()
        self.header_label.set_markup("<span font_weight='bold' font_size='large'>NixOS App Recommendations</span>")
        self.header_label.set_hexpand(True)
        self.header_label.set_halign(Gtk.Align.CENTER)
        self.grid.attach(self.header_label, 0, 0, 2, 1)
        
        # Description
        self.desc_label = Gtk.Label()
        self.desc_label.set_markup(
            "This tool recommends applications based on your usage patterns and system configuration. "
            "Click 'Scan & Recommend' to find new applications tailored to your needs."
        )
        self.desc_label.set_line_wrap(True)
        self.desc_label.set_max_width_chars(60)
        self.desc_label.set_hexpand(True)
        self.grid.attach(self.desc_label, 0, 1, 2, 1)
        
        # Buttons
        self.button_box = Gtk.Box(spacing=10)
        self.button_box.set_homogeneous(False)
        
        self.scan_button = Gtk.Button.new_with_label("Scan & Recommend")
        self.scan_button.connect("clicked", self.on_scan_clicked)
        self.button_box.pack_start(self.scan_button, True, True, 0)
        
        self.refresh_button = Gtk.Button.new_with_label("Refresh")
        self.refresh_button.connect("clicked", self.on_refresh_clicked)
        self.button_box.pack_start(self.refresh_button, True, True, 0)
        
        self.install_button = Gtk.Button.new_with_label("Install Selected")
        self.install_button.connect("clicked", self.on_install_clicked)
        self.button_box.pack_start(self.install_button, True, True, 0)
        
        self.grid.attach(self.button_box, 0, 2, 2, 1)
        
        # Loading spinner
        self.spinner = Gtk.Spinner()
        self.spinner.set_hexpand(True)
        self.spinner.set_halign(Gtk.Align.CENTER)
        self.grid.attach(self.spinner, 0, 3, 2, 1)
        
        # Status label
        self.status_label = Gtk.Label()
        self.status_label.set_text("Ready")
        self.status_label.set_hexpand(True)
        self.status_label.set_halign(Gtk.Align.CENTER)
        self.grid.attach(self.status_label, 0, 4, 2, 1)
        
        # Create the TreeView for recommendations
        self.create_recommendations_view()
        
        # Show initial recommendations if available
        self.show_all()
        self.spinner.hide()
        self.refresh_recommendations()
    
    def create_recommendations_view(self):
        """Create the TreeView for displaying recommendations."""
        # Scrolled window
        scrolled_window = Gtk.ScrolledWindow()
        scrolled_window.set_hexpand(True)
        scrolled_window.set_vexpand(True)
        scrolled_window.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        
        # ListStore model: app_name, category, reason, score, install_check
        self.recommendations_store = Gtk.ListStore(str, str, str, float, bool)
        
        # TreeView
        self.recommendations_view = Gtk.TreeView(model=self.recommendations_store)
        self.recommendations_view.set_rules_hint(True)
        
        # Checkbox column for selection
        renderer_toggle = Gtk.CellRendererToggle()
        renderer_toggle.connect("toggled", self.on_cell_toggled)
        column_toggle = Gtk.TreeViewColumn("Install", renderer_toggle, active=4)
        self.recommendations_view.append_column(column_toggle)
        
        # App name column
        renderer_text = Gtk.CellRendererText()
        renderer_text.set_property("ellipsize", Pango.EllipsizeMode.END)
        column_text = Gtk.TreeViewColumn("Application", renderer_text, text=0)
        column_text.set_resizable(True)
        column_text.set_expand(True)
        self.recommendations_view.append_column(column_text)
        
        # Category column
        renderer_text = Gtk.CellRendererText()
        column_text = Gtk.TreeViewColumn("Category", renderer_text, text=1)
        column_text.set_resizable(True)
        self.recommendations_view.append_column(column_text)
        
        # Score column
        renderer_text = Gtk.CellRendererText()
        column_text = Gtk.TreeViewColumn("Score", renderer_text, text=3)
        self.recommendations_view.append_column(column_text)
        
        # Reason column
        renderer_text = Gtk.CellRendererText()
        renderer_text.set_property("ellipsize", Pango.EllipsizeMode.END)
        column_text = Gtk.TreeViewColumn("Reason", renderer_text, text=2)
        column_text.set_resizable(True)
        column_text.set_expand(True)
        self.recommendations_view.append_column(column_text)
        
        scrolled_window.add(self.recommendations_view)
        self.grid.attach(scrolled_window, 0, 5, 2, 1)
        
    def on_cell_toggled(self, widget, path):
        """Handle toggling of install checkboxes."""
        self.recommendations_store[path][4] = not self.recommendations_store[path][4]
    
    def on_scan_clicked(self, widget):
        """Handle scan button click event."""
        self.status_label.set_text("Scanning installed applications and usage patterns...")
        self.spinner.show()
        self.spinner.start()
        self.scan_button.set_sensitive(False)
        self.refresh_button.set_sensitive(False)
        
        # Run the scan in a separate thread
        threading.Thread(target=self.run_scan, daemon=True).start()
    
    def run_scan(self):
        """Run the scan and recommendation generation in a background thread."""
        try:
            # Scan installed applications
            self.recommender.scan_installed_applications()
            GLib.idle_add(self.status_label.set_text, "Scanning application usage...")
            
            # Scan application usage
            self.recommender.scan_application_usage()
            GLib.idle_add(self.status_label.set_text, "Generating recommendations...")
            
            # Generate recommendations
            self.recommender.generate_recommendations()
            
            # Update UI
            GLib.idle_add(self.refresh_recommendations)
            GLib.idle_add(self.status_label.set_text, "Scan complete")
            
        except Exception as e:
            GLib.idle_add(self.status_label.set_text, f"Error: {str(e)}")
        finally:
            GLib.idle_add(self.spinner.stop)
            GLib.idle_add(self.spinner.hide)
            GLib.idle_add(self.scan_button.set_sensitive, True)
            GLib.idle_add(self.refresh_button.set_sensitive, True)
    
    def on_refresh_clicked(self, widget):
        """Handle refresh button click event."""
        self.refresh_recommendations()
    
    def on_install_clicked(self, widget):
        """Handle install button click event."""
        # Get selected applications
        selected_apps = []
        for row in self.recommendations_store:
            if row[4]:  # If install checkbox is checked
                selected_apps.append(row[0])
        
        if not selected_apps:
            self.status_label.set_text("No applications selected for installation")
            return
        
        # Run the installation
        self.status_label.set_text(f"Installing {len(selected_apps)} applications...")
        self.spinner.show()
        self.spinner.start()
        self.install_button.set_sensitive(False)
        
        # Run installation in a separate thread
        threading.Thread(
            target=self.run_installation, 
            args=(selected_apps,), 
            daemon=True
        ).start()
    
    def run_installation(self, apps):
        """Run the installation in a background thread."""
        try:
            cmd = ["nix-env", "-iA", "nixos."] + apps
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            stdout, stderr = process.communicate()
            
            if process.returncode == 0:
                GLib.idle_add(
                    self.status_label.set_text,
                    f"Successfully installed {len(apps)} applications"
                )
            else:
                GLib.idle_add(
                    self.status_label.set_text,
                    f"Installation failed: {stderr.strip()}"
                )
            
        except Exception as e:
            GLib.idle_add(self.status_label.set_text, f"Installation error: {str(e)}")
        finally:
            GLib.idle_add(self.spinner.stop)
            GLib.idle_add(self.spinner.hide)
            GLib.idle_add(self.install_button.set_sensitive, True)
            GLib.idle_add(self.refresh_recommendations)
    
    def refresh_recommendations(self):
        """Refresh the recommendations display."""
        self.recommendations_store.clear()
        
        # Get recommendations
        recommendations = self.recommender.get_top_recommendations(limit=20)
        
        # Update store
        for rec in recommendations:
            self.recommendations_store.append([
                rec["app_name"],
                rec["category"],
                rec["reason"],
                rec["score"],
                False
            ])
        
        if not recommendations:
            self.status_label.set_text(
                "No recommendations available. Click 'Scan & Recommend' to generate recommendations."
            )
        else:
            self.status_label.set_text(f"Showing {len(recommendations)} recommendations")

def main():
    """Main function to run the GUI."""
    win = AppRecommenderWindow()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    win.spinner.hide()
    Gtk.main()

if __name__ == "__main__":
    main()