package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

//Custom file dialog using raylib
/*
TODO:
- Make forwards and back system work on file tree.
- Add functionality for back arrow to go up a directory.
*/

current_dir :: #directory[:len(#directory)-1]

GuiFileDialogState :: struct {
  //Contains the all the state needed for the file dialog to operate with default values provided.
  first_load: bool,
  dir_nav_list: [dynamic]cstring, //List used for interaction with forwards and backwards buttons.
  current_dir_index: u32,
  current_dir: cstring, //Current dir is updated and used to load current files in view.
  files_list: [dynamic]cstring,
  dirs_list: [dynamic]cstring,
  selected_file: cstring, //Selected file which will be loaded when the button is clicked.
  gui_properties: GuiProperties,
  panelRec: rl.Rectangle,
  panelContentRec: rl.Rectangle,
  panelView: rl.Rectangle,
  panelScroll: rl.Vector2
}

InitFileDialog :: proc() -> GuiFileDialogState {
  //Initialise the file dialog and set default state
  state := GuiFileDialogState{
    first_load = true,
    dir_nav_list = [dynamic]cstring{},
    current_dir_index = 0,
    current_dir = current_dir,
    files_list = [dynamic]cstring{},
    dirs_list = [dynamic]cstring{},
    selected_file = nil,
    gui_properties = getDefaultProperties(),
    panelRec = {0, 0, 0, 0},
    panelContentRec = {},
    panelView = {0, 0, 0, 0},
    panelScroll = {0, 0}
  }
  getCurrentDirFiles(&state)
  append(&state.dir_nav_list, current_dir)
  return state
}

GuiFileDialog :: proc(rec: rl.Rectangle, state: ^GuiFileDialogState) -> bool {
  //Procedure used to visualise the file dialog using the current state
  scroll_bar_width := cast(f32)rl.GuiGetStyle(.SCROLLBAR, cast(i32)rl.GuiScrollBarProperty.SCROLL_SLIDER_SIZE)
  scroll_bar_padding := cast(f32)rl.GuiGetStyle(.DEFAULT, cast(i32)rl.GuiScrollBarProperty.SCROLL_PADDING)

  if (state.first_load) {
    //State reset in case of going in and out of loading screen.
    state.selected_file = nil
    state.first_load = false
    state.panelContentRec = {
      rec.x,
      cast(f32)(rec.y + state.gui_properties.PADDING_TOP + state.gui_properties.NAVBAR_SIZE + state.gui_properties.PADDING_ICONS),
      rec.width,
      0}
  }

  rl.GuiSetStyle(.DEFAULT, cast(i32)rl.GuiDefaultProperty.TEXT_SIZE, 20)
  
  x := rec.x
  y := rec.y
  width := rec.width
  height := rec.height

  state.panelRec = {
    x, 
    cast(f32)(y + state.gui_properties.PADDING_TOP + state.gui_properties.NAVBAR_SIZE + state.gui_properties.NAVBAR_PADDING),
    width,
    height - cast(f32)(y + +state.gui_properties.PADDING_TOP + state.gui_properties.NAVBAR_SIZE)
  }

  state.panelContentRec.width = width - 14


  //draw nav buttons and the current directory and the select button.
  draw_width := width - state.gui_properties.PADDING_LEFT - state.gui_properties.PADDING_RIGHT
  draw_height := height - state.gui_properties.PADDING_TOP - state.gui_properties.PADDING_BOTTOM
 
  if (rl.GuiButton(
    {
      cast(f32)(x + state.gui_properties.PADDING_LEFT), 
      cast(f32)(y + state.gui_properties.PADDING_TOP), 
      state.gui_properties.NAVBAR_SIZE, 
      state.gui_properties.NAVBAR_SIZE
    }, 
    rl.GuiIconText(.ICON_ARROW_LEFT, ""))) {
    //Have functionality to traverse up one directory at a time.
    current_dir_split := strings.split(string(state.current_dir), "/")
    outer_directory := strings.clone_to_cstring(strings.join(current_dir_split[:len(current_dir_split)-1], "/"))

    inject_at(&state.dir_nav_list, state.current_dir_index, outer_directory)
    state.current_dir = outer_directory
    getCurrentDirFiles(state)
  }

  if (rl.GuiButton(
    {
      cast(f32)(x + state.gui_properties.PADDING_LEFT + state.gui_properties.NAVBAR_SIZE + state.gui_properties.NAVBAR_PADDING), 
      cast(f32)(y + state.gui_properties.PADDING_TOP), 
      state.gui_properties.NAVBAR_SIZE, 
      state.gui_properties.NAVBAR_SIZE
    }, 
    rl.GuiIconText(.ICON_ARROW_RIGHT, ""))) {
    if (state.current_dir_index < (cast(u32)len(state.dir_nav_list) - 1)) {
      state.current_dir = state.dir_nav_list[state.current_dir_index + 1]
      state.current_dir_index += 1
      getCurrentDirFiles(state)
    }
  }

  rl.GuiLabel(
    {
      cast(f32)(x + state.gui_properties.PADDING_LEFT + (state.gui_properties.NAVBAR_SIZE * 2) + (state.gui_properties.NAVBAR_PADDING * 2)), 
      cast(f32)(y + state.gui_properties.PADDING_TOP), 
      cast(f32)(draw_width - (state.gui_properties.NAVBAR_SIZE * 5) - (state.gui_properties.NAVBAR_PADDING * 3)), 
      state.gui_properties.NAVBAR_SIZE
    }, 
    state.current_dir)

  if (rl.GuiButton(
    {
      cast(f32)(x + state.gui_properties.PADDING_LEFT + draw_width - (state.gui_properties.NAVBAR_SIZE * 3) - (state.gui_properties.NAVBAR_PADDING * 1)),
      cast(f32)(y + state.gui_properties.PADDING_TOP),
      cast(f32)(state.gui_properties.NAVBAR_SIZE * 3),
      state.gui_properties.NAVBAR_SIZE
    },
    "Select"
  )) {
    //Check selected file and return true.
    //For logic with this element interacting with the outer program.
    if (rl.FileExists(state.selected_file)) {
      if (rl.GetFileExtension(state.selected_file) == cstring(".combat")) {
        state.first_load = true
        return true
      }
    }
  }

  //Break the current width and height into a grid, draw all folders files in current directory

  icons_per_row := cast(i32)(state.panelContentRec.width / (state.gui_properties.ICON_SIZE + state.gui_properties.PADDING_ICONS))
  num_rows_max := cast(i32)((state.panelRec.height - state.gui_properties.PADDING_TOP - state.gui_properties.PADDING_BOTTOM) / (state.gui_properties.ICON_SIZE + state.gui_properties.PADDING_ICONS))

  file_counter : u32 = 0
  dir_count : u32 = cast(u32)len(state.dirs_list)
  file_count : u32 = cast(u32)len(state.files_list)

  num_rows_needed := (cast(f32)(dir_count + file_count) / cast(f32)icons_per_row)

  if (num_rows_needed / cast(f32)cast(i32)(num_rows_needed)) > 1 {
    num_rows_needed = cast(f32)cast(i32)(num_rows_needed) + 1
  }

  dynamic_icon_padding := cast(f32)((cast(i32)state.panelContentRec.width % (icons_per_row * cast(i32)state.gui_properties.ICON_SIZE)) / (icons_per_row + 1))

  if (dynamic_icon_padding < state.gui_properties.PADDING_ICONS) {
    dynamic_icon_padding = state.gui_properties.PADDING_ICONS
  }
  
  if (cast(i32)num_rows_needed > num_rows_max) {
    state.panelContentRec.height = (cast(f32)num_rows_needed * cast(f32)(state.gui_properties.ICON_SIZE + state.gui_properties.PADDING_ICONS)) + cast(f32)state.gui_properties.PADDING_ICONS
    rl.GuiScrollPanel(state.panelRec, nil, state.panelContentRec, &state.panelScroll, &state.panelView)

    rl.BeginScissorMode(cast(i32)state.panelView.x, cast(i32)state.panelView.y, cast(i32)state.panelView.width, cast(i32)state.panelView.height)
    rl.ClearBackground(rl.SKYBLUE)
  }

  draw_loop: for i in 0..<num_rows_needed {
    for j in 0..<icons_per_row {
      //Draw each file icon, with padding
      if file_counter < dir_count + file_count {
        filename : cstring = ""
        if (file_counter < dir_count) {
          path_split := strings.split(string(state.dirs_list[file_counter]), "/")//NOTE: Change file seperator based on OS.
          filename = strings.clone_to_cstring(path_split[len(path_split)-1])

          if (rl.GuiButton(
            {
              cast(f32)((x + state.gui_properties.PADDING_LEFT) + (cast(f32)j * (state.gui_properties.ICON_SIZE + dynamic_icon_padding))),
              cast(f32)((y + +state.gui_properties.PADDING_TOP + state.gui_properties.NAVBAR_SIZE + state.gui_properties.PADDING_ICONS) + (cast(f32)i * (state.gui_properties.ICON_SIZE + state.gui_properties.PADDING_ICONS)) + state.panelScroll.y),
              state.gui_properties.ICON_SIZE,
              state.gui_properties.ICON_SIZE
            },
            rl.GuiIconText(.ICON_FOLDER, filename)
          )) {
            //Folder clicked, change this to be current folder.
            inject_at(&state.dir_nav_list, state.current_dir_index, state.dirs_list[file_counter])
            state.current_dir = state.dirs_list[file_counter]
            getCurrentDirFiles(state)
            break draw_loop
          }
        }
        else {
          path_split := strings.split(string(state.files_list[file_counter - dir_count]), "/")
          filename = strings.clone_to_cstring(path_split[len(path_split)-1])

          if (rl.GuiButton(
            {
              cast(f32)((x + state.gui_properties.PADDING_LEFT) + (cast(f32)j * (state.gui_properties.ICON_SIZE + dynamic_icon_padding))),
              cast(f32)((y + +state.gui_properties.PADDING_TOP + state.gui_properties.NAVBAR_SIZE + state.gui_properties.PADDING_ICONS) + (cast(f32)i * (state.gui_properties.ICON_SIZE + state.gui_properties.PADDING_ICONS)) + state.panelScroll.y),
              state.gui_properties.ICON_SIZE,
              state.gui_properties.ICON_SIZE
            },
            rl.GuiIconText(.ICON_FILETYPE_TEXT, filename)
          )) {
            state.selected_file = state.files_list[file_counter - dir_count]
          }
        }
        file_counter += 1
      }
    }
  }
  if (cast(i32)num_rows_needed > num_rows_max) {
    rl.EndScissorMode()
  } else {
    state.panelScroll.y = 0
  }
  return false
}

getCurrentDirFiles :: proc(state: ^GuiFileDialogState) {
  file_list := rl.LoadDirectoryFiles(state.current_dir)
  clear(&state.dirs_list)
  clear(&state.files_list)

  for i in 0..<file_list.count {
    if (rl.IsPathFile(file_list.paths[i])) {
      append(&state.files_list, file_list.paths[i])
    }
    else {
      append(&state.dirs_list, file_list.paths[i])
    }
  }
}
