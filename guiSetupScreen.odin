package main

import "core:fmt"
import rl "vendor:raylib"

SetupState :: struct {
  player_select_dropdown: bool,
  dropdown_active: i32,
  gui_properties: GuiProperties
}

InitSetupState :: proc() -> SetupState {
  setupState := SetupState{
    player_select_dropdown = false,
    dropdown_active = 0,
    gui_properties = getDefaultProperties()
  }
  return setupState
}

GuiDrawSetupScreen :: proc(state: ^State, setupState: ^SetupState) {
  //Draw the combat setup screen. Should be triggered by both new combat and load combat buttons,
  //load combat should populate the options before displaying.

  rl.GuiSetStyle(.DEFAULT, cast(i32)rl.GuiDefaultProperty.TEXT_SIZE, 60)

  title_width := getTextWidth("Combat Setup")
  title_x := (state.window_width / 2) - (title_width / 2)
  rl.GuiLabel({cast(f32)title_x, 10, cast(f32)(state.window_width / 3), cast(f32)(state.window_height / 8)}, "Combat Setup")

  rl.GuiSetStyle(.DEFAULT, cast(i32)rl.GuiDefaultProperty.TEXT_SIZE, 30)
  
  if (rl.GuiButton({(cast(f32)state.window_width * 0.025), 10, cast(f32)(state.window_height / 8), cast(f32)(state.window_height / 8)}, "Back")) {
    state.current_view_index -= 1
  }

  if (rl.GuiButton({(cast(f32)state.window_width * 0.025) + cast(f32)(state.window_height / 8) + 20, 10, cast(f32)(state.window_height / 8), cast(f32)(state.window_height / 8)}, rl.GuiIconText(.ICON_FILE_OPEN, ""))) {
    inject_at(&state.views_list, state.current_view_index+1, View.LOAD_SCREEN)
    state.current_view_index += 1
  }
  if (rl.GuiButton({(cast(f32)state.window_width * 0.775), 10, (cast(f32)state.window_width * 0.2), cast(f32)(state.window_height / 8)}, "Start Combat")) {
    //Change view to combat screen with the current combat loaded
  }
  //Layout 3 panels to fill with the different bits of info needed.
  draw_width : f32 = cast(f32)state.window_width - setupState.gui_properties.PADDING_LEFT - setupState.gui_properties.PADDING_RIGHT
  draw_height : f32 = cast(f32)state.window_height - ((cast(f32)state.window_height / 8) + 10) - setupState.gui_properties.PADDING_TOP
  
  panel_y := (cast(f32)state.window_height / 8) + 10 + setupState.gui_properties.PADDING_TOP
  panel_width := cast(f32)state.window_width / 3.5
  dynamic_x_padding : f32 = (draw_width - (3 * panel_width)) / 2

  current_panel_x : f32 = setupState.gui_properties.PADDING_LEFT
  //Will contain all entities loaded into the program for adding into the combat.
  rl.GuiPanel(
    {
      current_panel_x,
      panel_y,
      panel_width,
      draw_height - setupState.gui_properties.PADDING_BOTTOM
    },
    "Left panel")

  if (rl.GuiDropdownBox({current_panel_x, panel_y, panel_width, 50}, "All;Players;Monsters;NPC's", &setupState.dropdown_active, setupState.player_select_dropdown)) {
    setupState.player_select_dropdown = !setupState.player_select_dropdown
  }
  //List all entities currently added into the combat
  current_panel_x = setupState.gui_properties.PADDING_LEFT + panel_width + dynamic_x_padding

  rl.GuiPanel(
    {
      current_panel_x,
      panel_y,
      panel_width,
      draw_height - setupState.gui_properties.PADDING_BOTTOM
    },
    "Mid panel")
  //Options and stats I/O for each selected entity + general combat options.
  current_panel_x = setupState.gui_properties.PADDING_LEFT + (2 * panel_width) + (2 * dynamic_x_padding)
  rl.GuiPanel(
    {
      current_panel_x,
      panel_y,
      panel_width,
      draw_height - setupState.gui_properties.PADDING_BOTTOM
    },
    "Right panel")

//  if (rl.GuiDropdownBox({200, 200, 400, 100}, "Option 1; Option 2; Option 3", &setupState.dropdown_active, setupState.player_select_dropdown)) {
//    setupState.player_select_dropdown = !setupState.player_select_dropdown
//  }
}
//Filter entities list for display list. Should reconstruct the full list based on the option selected in the dropdown button.
filterEntities :: proc() {}
