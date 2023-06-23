import { ModCallback, InputHook, ButtonAction } from "isaac-typescript-definitions";
import { ModCallbackCustom, isFirstPlayer} from "isaacscript-common";
import { mod } from "../mod";

const control = {
    1: ButtonAction.ITEM,
    2: ButtonAction.PILL_CARD,
    3: ButtonAction.BOMB,
    CHANGE_MODE: ButtonAction.DROP
  };

export function allomancy(): void {
    mod.AddCallbackCustom(ModCallbackCustom.INPUT_ACTION_PLAYER,
                        usePower,
                        undefined,
                        undefined,
                        InputHook.IS_ACTION_PRESSED,
                        control[1]);
    mod.AddCallbackCustom(ModCallbackCustom.INPUT_ACTION_PLAYER,
                        usePower,
                        undefined,
                        undefined,
                        InputHook.IS_ACTION_PRESSED,
                        control[2]);
    mod.AddCallbackCustom(ModCallbackCustom.INPUT_ACTION_PLAYER,
                        usePower,
                        undefined,
                        undefined,
                        InputHook.IS_ACTION_PRESSED,
                        control[3]);
}



function usePower(player: EntityPlayer, _inputHook: InputHook, _buttonAction: ButtonAction): boolean | undefined {
    player.AddBombs(1);
    return undefined;
}


/*
function ControlsUpdate(entity, hook, action){

    if(entity !== undefined) {

        const player = entity:ToPlayer();
        const pData = player:GetData();

        //SI TIENES CUALQUIERA DE LOS ITEMS METÁLICOS
        if(player && MR.allomancy.physical.has(player) && pData.controlsChanged){
            //CONTROLES DE PRESIÓN
            if MR.allomancy.pressingPower(MR.enum.power.IRON, player) or MR.allomancy.pressingPower(MR.enum.power.STEEL, player) {
                MR.allomancy.physical.use(player)

                if MR.allomancy.pressingPower(MR.enum.power.IRON, player) { pData.pulling = true else pData.pulling = false }
                if MR.allomancy.pressingPower(MR.enum.power.STEEL, player) { pData.pushing = true else pData.pushing = false }

            else
                if #pData.selectedEntities > 0 {
                    MR.tracer.deselectEntities(entity)
                }
            }
        }
    }
}
*/