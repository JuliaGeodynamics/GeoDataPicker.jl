using Gtk
using FileIO

function open_file_dialog()
    dialog = Gtk.Dialog("Select a file")

    file_button = Gtk.Button("Open")
    cancel_button = Gtk.Button("Cancel")
    add_button(dialog, file_button)
    add_button(dialog, cancel_button)

    selected_file = ""

    function on_file_button_clicked(widget)
        file_dialog = Gtk.FileChooserDialog("Select a file", dialog,
                                            Gtk.FileChooserAction.OPEN,
                                            ("Cancel", Gtk.ResponseType.CANCEL,
                                             "Open", Gtk.ResponseType.OK))

        filter = Gtk.FileFilter()
        add_pattern(filter, "*.txt")
        add_filter(file_dialog, filter)

        response = run(file_dialog)

        if response == Gtk.ResponseType.OK
            selected_file = joinpath(get_current_folder(file_dialog), get_filename(file_dialog))
            println("Selected file: $selected_file")
        end

        destroy(file_dialog)
    end

    signal_connect(on_file_button_clicked, file_button, "clicked")

    signal_connect(dialog) do widget
        destroy(dialog)
    end

    showall(dialog)
end

open_file_dialog()
