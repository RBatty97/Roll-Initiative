package main

GuiProperties :: struct {
  PADDING_TOP: f32,
  PADDING_LEFT: f32,
  PADDING_RIGHT: f32,
  PADDING_BOTTOM: f32,
  PADDING_ICONS: f32,
  NAVBAR_SIZE: f32,
  NAVBAR_PADDING: f32,
  ICON_SIZE: f32,
}

getDefaultProperties :: proc() -> GuiProperties {
  props := GuiProperties{
    PADDING_TOP = 30,
    PADDING_LEFT = 30,
    PADDING_RIGHT = 30,
    PADDING_BOTTOM = 30,
    PADDING_ICONS = 30,
    NAVBAR_SIZE = 50,
    NAVBAR_PADDING = 10,
    ICON_SIZE = 150,
  }
  return props
}
