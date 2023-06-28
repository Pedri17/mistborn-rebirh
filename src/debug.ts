import { ModCallback } from "isaac-typescript-definitions";
import {
  VectorZero,
  arrayRemoveIndexInPlace,
  game,
  getEntityFromPtrHash,
} from "isaacscript-common";
import * as entity from "./entities/entity";
import { mod } from "./mod";
import * as util from "./utils/util";

class ScreenMessageClass {
  messages: string[] = [];
  opacity: number = 1;
  lastMessageQuantity = 0;
}

class EntityMessageClass {
  displacement: number = 0;
  message: string = "";
  position: Vector = VectorZero;
  initFrame: number = 0;
}

class debugClass {
  active: boolean = true;
  screen: ScreenMessageClass = new ScreenMessageClass();
  position: EntityMessageClass[] = [];
  entities: Map<PtrHash, Map<string, any>> = new Map();
  variables: Map<string, any> = new Map();
}

let debug = new debugClass();

const preconf = {
  numScreenMess: 3,
  numEntityMess: 3,
};

export function init() {
  mod.AddCallback(ModCallback.POST_RENDER, renderDebug);
}

/**
 * Set a debug variable on a entity or on the top left of the screen
 *
 * @param varName This need to be unique to every entity or the screen.
 * @param value Variable that will be displayed.
 * @param ent Optional. Entity where variable will be displayed.
 */
export function setVariable(varName: string, value: any, ent?: Entity) {
  if (ent !== undefined) {
    //To entity
    const ID = GetPtrHash(ent);

    if (entity.isExisting(ent)) {
      // Ensure that is alive
      let variables: Map<string, any> = new Map();
      variables.set(varName, value);
      if (debug.entities.get(ID) === undefined) {
        // New entity
        debug.entities.set(ID, variables);
      } else {
        // Saved entity
        variables = debug.entities.get(ID)!;
        variables.set(varName, value);
      }
    } else if (debug.entities.get(ID) !== undefined) {
      debug.entities.delete(ID);
    }
  } else {
    // To screen
    debug.variables.set(varName, value);
  }
}

/**
 * Adds a message that will be rendered at the bottom right of the screen or on a entity position.
 *
 * @param text message that will be displayed.
 * @param entPos Optional. Position where message will be displayed, use entity to take its position.
 *
 */
export function addMessage(text: string, entPos?: Vector | Entity) {
  // To screen
  if (entPos === undefined) {
    // Add lastMessageQuantity if it is a repeated message
    if (debug.screen.messages[1] === text) {
      debug.screen.lastMessageQuantity += 1;
    } else {
      debug.screen.lastMessageQuantity = 0;
    }

    debug.screen.messages.push(text);
    debug.screen.opacity = 1;

    // Limit message num
    if (debug.screen.messages.length > preconf.numScreenMess) {
      arrayRemoveIndexInPlace(debug.screen.messages, preconf.numScreenMess + 1);
    }
  } else {
    // To entity
    let newEntityMess = new EntityMessageClass();

    newEntityMess.message = text;
    newEntityMess.initFrame = Isaac.GetFrameCount();
    newEntityMess.displacement = 0;
    if (util.isType<Entity>(entPos)) {
      let pos = entPos.Position;
      entPos = pos;
    }
    newEntityMess.position = game.GetRoom().WorldToScreenPosition(entPos);

    debug.position.push(newEntityMess);
  }
}

/**
 * Used on PostRenderCallback, render debug messages and variables.
 */
function renderDebug() {
  if (debug.active) {
    let f = Font();
    f.Load("font/pftempestasevencondensed.fnt");

    // Screen messages
    let message: string = "";
    if (debug.screen.messages.length > 0) {
      for (let i = 0; i < preconf.numScreenMess + 1; i++) {
        if (debug.screen.messages[i] !== undefined) {
          if (i === 1 && debug.screen.lastMessageQuantity > 0) {
            message = `x${debug.screen.lastMessageQuantity}: ${debug.screen.messages[i]}`;
          } else {
            message = `${debug.screen.messages[i]}`;
          }
          Isaac.RenderText(
            message,
            5,
            255 - 11 * (i - 1),
            1,
            1,
            1,
            debug.screen.opacity - (1 / preconf.numScreenMess) * (i - 1),
          );
        }
      }

      if (debug.screen.opacity > 0) {
        debug.screen.opacity -= 0.003;
      }
    }

    // Position messages
    let numEntities = debug.position.length;
    if (numEntities > 0) {
      for (let i = 0; i < numEntities + 1; i++) {
        let opacity = 1;
        let entityMess = debug.position[i];

        if (entityMess !== undefined) {
          if (entityMess.displacement < 100) {
            opacity -= entityMess.displacement / 100;
            f.DrawString(
              entityMess.message,
              entityMess.position.X - f.GetStringWidth(entityMess.message) / 2,
              entityMess.position.Y - entityMess.displacement,
              KColor(1, 1, 1, opacity),
              0,
              true,
            );
            entityMess.displacement =
              (Isaac.GetFrameCount() - entityMess.initFrame) / 3;
          } else {
            opacity = 0;
            arrayRemoveIndexInPlace(debug.position, i);
          }
        }
      }
    }

    let r: number = 0;
    let g: number = 0;
    let b: number = 0;

    // Screen variables
    if (debug.variables.size > 0) {
      let messVar: string = "";
      let i = 1;
      for (let [name, value] of debug.variables) {
        if (name !== "") messVar = name + ": ";

        if (util.isType<boolean>(value)) {
          if (value) {
            r = 0;
            g = 1;
            b = 0;
          } else {
            r = 1;
            g = 0;
            b = 0;
          }
        }
        messVar += `${value}`;
        Isaac.RenderText(messVar, 32, 28 + 11 * (i - 1), r, g, b, 1);
        i++;
      }
    }

    // Entity variables
    if (debug.entities.size > 0) {
      for (let [ptr, variables] of debug.entities) {
        // Remove entity if it is not alive
        if (!entity.isExisting(getEntityFromPtrHash(ptr))) {
          debug.entities.delete(ptr);
        } else {
          const ent = getEntityFromPtrHash(ptr)!;
          const pos = game.GetRoom().WorldToScreenPosition(ent.Position);

          let i = 1;
          for (let [name, value] of variables) {
            let messVar = "";

            if (name !== "") {
              messVar = name + ": ";
            }

            if (util.isType<boolean>(value)) {
              if (value) {
                r = 0;
                g = 1;
                b = 0;
              } else {
                r = 1;
                g = 0;
                b = 0;
              }
            }

            messVar += `${value}`;
            f.DrawString(
              messVar,
              pos.X - f.GetStringWidth(messVar) / 2,
              pos.Y + f.GetLineHeight() * (i - 1),
              KColor(r, g, b, 1),
              0,
              true,
            );
            i++;
          }
        }
      }
    }
  }
}
