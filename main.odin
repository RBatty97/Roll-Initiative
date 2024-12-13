package main

import "core:fmt"
import "core:strings"
import "core:os"
import "core:encoding/json"
import rl "vendor:raylib"

/*
Program notes:
- Probably need to have some sort of program state (for screen should be displayed)
  For example title screen, setup screen, combat screen, setting screen.
- Need to come up with some sort of file format for saving pre-defined combat setups.
- File format for monsters and players to load into the program.
- Should output combat log file. Human readable, contains an entire runthrough turn by turn of the whole combat including
  dmg, healing, turn timers, toggling state (concentrating) etc.
- Maybe build in functionality to view combat logs within the program, not essential feature.

- Should all hook into web client (using server side events) to pass all the info for visualisation over local network.
*/

app_title :: "Roll Initiative"
app_dir :: #directory

View :: enum {
  TITLE_SCREEN,
  LOAD_SCREEN,
  SETUP_SCREEN,
  COMBAT_SCREEN,
  SETTINGS_SCREEN
}

State :: struct {
  window_width, window_height: i32,
  views_list: [dynamic]View,
  current_view_index: u32
}

@(init)
init :: proc() {
  //Initialisation steps
  rl.InitWindow(1080, 720, "Roll Initiative")
  rl.SetTargetFPS(60)
  rl.SetExitKey(.Q)
  rl.SetWindowState({.WINDOW_RESIZABLE})
  rl.GuiSetStyle(.DEFAULT, cast(i32)rl.GuiDefaultProperty.TEXT_SIZE, 60)
  load_entities_from_file("srd_5e_monsters.json")
}

main :: proc() {
  fileDialogState := InitFileDialog()
  setupState := InitSetupState()

  state := State{
    rl.GetRenderWidth(), 
    rl.GetRenderHeight(), 
    [dynamic]View{.TITLE_SCREEN},
    0
  }

  defer rl.CloseWindow()
  for (!rl.WindowShouldClose()) {
    //Do non-drawing stuff
    state.window_width = rl.GetRenderWidth()
    state.window_height = rl.GetRenderHeight()

    rl.GuiSetStyle(.DEFAULT, cast(i32)rl.GuiDefaultProperty.TEXT_SIZE, 60)
    //Draw
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.SKYBLUE)

    switch state.views_list[state.current_view_index] {
    case .TITLE_SCREEN:
      drawTitleScreen(&state)
    case .LOAD_SCREEN:
      drawLoadScreen(&state, &fileDialogState)
    case .SETUP_SCREEN:
      GuiDrawSetupScreen(&state, &setupState)
    case .COMBAT_SCREEN:
      //drawCombatScreen(&state)
    case .SETTINGS_SCREEN:
      //drawSettingScreen(&state)
    }
  }
}

getTextWidth :: proc(text: cstring) -> i32 {
  return rl.MeasureText(text, 60)
}

drawTitleScreen :: proc(state: ^State) {
  //Draw the title screen and handle changing into other screens.
  //Should have options to make new combat, load saved combat or change settings.

  title_width := getTextWidth("Roll Initiative")
  title_x := (state.window_width / 2) - (title_width / 2)
  rl.GuiLabel({cast(f32)title_x, 10, cast(f32)(state.window_width / 2), cast(f32)(state.window_height / 5)}, app_title)

  if (rl.GuiButton({cast(f32)(state.window_width / 4), (cast(f32)state.window_height * 0.25), cast(f32)(state.window_width / 2), cast(f32)(state.window_height / 5)}, "New Combat")) {
    inject_at(&state.views_list, state.current_view_index+1, View.SETUP_SCREEN)
    state.current_view_index += 1
  }
  if (rl.GuiButton({cast(f32)(state.window_width / 4), (cast(f32)state.window_height * 0.5), cast(f32)(state.window_width / 2), cast(f32)(state.window_height / 5)}, "Load Combat")) {
    inject_at(&state.views_list, state.current_view_index+1, View.LOAD_SCREEN)
    state.current_view_index += 1
  }
  rl.GuiButton({cast(f32)(state.window_width / 4), (cast(f32)state.window_height * 0.75), cast(f32)(state.window_width / 2), cast(f32)(state.window_height / 5)}, "Settings")
}

drawLoadScreen :: proc(state: ^State, fileDialogState: ^GuiFileDialogState) {
  rl.GuiSetStyle(.DEFAULT, cast(i32)rl.GuiDefaultProperty.TEXT_SIZE, 60)

  title_width := getTextWidth("Combat Setup")
  title_x := (state.window_width / 2) - (title_width / 2)
  rl.GuiLabel({cast(f32)title_x, 10, cast(f32)(state.window_width / 3), cast(f32)(state.window_height / 8)}, "Load Combat")

  rl.GuiSetStyle(.DEFAULT, cast(i32)rl.GuiDefaultProperty.TEXT_SIZE, 30)

  if (rl.GuiButton({(cast(f32)state.window_width * 0.025), 10, (cast(f32)state.window_width * 0.2), cast(f32)(state.window_height / 8)}, "Back")) {
    fileDialogState.first_load = true
    state.current_view_index -= 1
  }

  rl.GuiLine({50, cast(f32)((state.window_height / 8) + 20), cast(f32)(state.window_width - 100), 10}, "")

  if (GuiFileDialog({50, cast(f32)(state.window_height / 7), cast(f32)(state.window_width - 100), cast(f32)(state.window_height - (state.window_height / 7))}, fileDialogState)) {
    //Go to the setup screen and load all the information from the selected file.
    inject_at(&state.views_list, state.current_view_index+1, View.SETUP_SCREEN)
    state.current_view_index += 1
  }
}
