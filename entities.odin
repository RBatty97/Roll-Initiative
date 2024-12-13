package main

import "core:fmt"
import "core:os"
import "core:encoding/json"
import "core:strings"

/*
File to contain all information and functionality surrounding entities.
Data structure for entities.
Loading entities from file.
*/

EntityType :: enum {

}

EntitySize :: enum {
  tiny,
  small,
  medium,
  large,
  huge,
  gargantuan
}

Entity :: struct {
  name: string,
  type: string,
  size: string,
  alignment: string,
  AC: string,
  HP_max: string,
  HP: string,
  speed: string,
  STR: string,
  STR_mod: string,
  DEX: string,
  DEX_mod: string,
  CON: string,
  CON_mod: string,
  INT: string,
  INT_mod: string,
  WIS: string,
  WIS_mod: string,
  CHA: string,
  CHA_mod: string,
  saving_throws: string,
  skills: string,
  dmg_resistances: string,
  dmg_immunities: string,
  senses: string,
  languages: string,
  CR: string
}

load_entities_from_file :: proc(filename: string) -> #soa[dynamic]Entity {
  entities: #soa[dynamic]Entity
  file_data, ok :=  os.read_entire_file(filename)
  if (ok) {
    json_data, ok := json.parse(file_data)
    //Loop over the entities and fill the struct.
    for entity, i in json_data.(json.Array) {
      entity_fields := entity.(json.Object)
      new_entity := Entity{
        entity_fields["name"].(string),
        strings.split(strings.split(entity_fields["meta"].(string), ",")[0], " ")[1],
        strings.split(strings.split(entity_fields["meta"].(string), ",")[0], " ")[0],
        strings.split(entity_fields["meta"].(string), ",")[1],
        entity_fields["Armor Class"].(string),
        entity_fields["Hit Points"].(string),
        entity_fields["Current Hit Points"].(string) if ("Current Hit Points" in entity_fields) else entity_fields["Hit Points"].(string),
        entity_fields["Speed"].(string),
        entity_fields["STR"].(string),
        entity_fields["STR_mod"].(string),
        entity_fields["DEX"].(string),
        entity_fields["DEX_mod"].(string),
        entity_fields["CON"].(string),
        entity_fields["CON_mod"].(string),
        entity_fields["INT"].(string),
        entity_fields["INT_mod"].(string),
        entity_fields["WIS"].(string),
        entity_fields["WIS_mod"].(string),
        entity_fields["CHA"].(string),
        entity_fields["CHA_mod"].(string),
        entity_fields["Saving Throws"].(string) if ("Saving Throws" in entity_fields) else "",
        entity_fields["Skills"].(string) if ("Skills" in entity_fields) else "",
        entity_fields["Damage Resistances"].(string) if ("Damage Resistances" in entity_fields) else "",
        entity_fields["Damage Immunities"].(string) if ("Damage Immunities" in entity_fields) else "",
        entity_fields["Senses"].(string) if ("Senses" in entity_fields) else "",
        entity_fields["Languages"].(string) if ("Languages" in entity_fields) else "",
        entity_fields["Challenge"].(string)
      }
      append_soa(&entities, new_entity)
    }
  }
  return entities
}
