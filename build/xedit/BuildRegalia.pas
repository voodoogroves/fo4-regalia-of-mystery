{
  BuildRegalia.pas: the whole mod in ONE plugin, RegaliaOfMystery.esp (light/ESL flagged). Description: docs\build-spec.md.
  Merges the test chain (BuildBladeGold, BuildGarb, BuildVeil, BuildBroken2, BuildVoice3, BuildWorld): every record is made once with its
  final values. The only overrides are four map cells and the Commonwealth worldspace.
  Status 2026-11-26: built and tested in game; what has and has not been seen is in the build spec, section 3.6.

  Masters: Fallout4.esm and DLCNukaWorld.esm (the Eye of Ra is a copy of its Shock Collar).
  IN THE MODULE LIST tick the game and the six DLC only, NO Regalia plugin. Type RegaliaOfMystery in the filename box (an older file of
  that name must first be moved out of the game's Data folder). Close xEdit and accept the save.

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildRegalia.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Log: our-scripts\build.log. The last line must read "done". Check the saved file with build/check/compare_chain.py.
}
unit BuildRegalia;

const
  PLUGIN_HINT = 'RegaliaOfMystery';
  PLUGIN_DESC = 'Regalia of Mystery. THIS MATERIAL IS NOT MADE, GUARANTEED OR SUPPORTED BY ZENIMAX OR ITS AFFILIATES.';
  FIRST_ID = $800;                         // lowest object ID that is safe in a light plugin
  LOG_FILE = 'Z:\home\deck\Games\mo2-lint\tools\our-scripts\build.log';
  CRYPTOS_FILE = 'Z:\home\deck\Repos\fo4-regalia-of-mystery\docs\cryptos-text.md';
  DIARY_FILE = 'Z:\home\deck\Repos\fo4-regalia-of-mystery\docs\diary-text.md';

  // Blade
  BLADE_NAME = 'Blade of Bastet';
  BLADE_DESC = 'A Chinese officer''s sword reforged with silver, gold and a crystal-set hilt, in the manner of the Mistress of Mystery''s blade. Lighter, quicker to strike in VATS, and it bleeds. Ignores part of the target''s armor.';
  BLADE_MOD_DESC = 'A lightened, honed edge that finds the gaps in armor and bleeds what it cuts.';
  PLAIN_BLADE_MODEL = 'Weapons\ChineseOfficerSword\Blade.nif';
  OLD_MA = $0018782C;                      // ma_ChineseOfficerSword
  DMG_ADD = 0.45;
  AP_ADD = -0.43;
  WEIGHT_ADD = -0.33;
  BLADE_MULT = '0.7';
  BLADE_EYE_MULT = '0.0';

  // Eye and Cryptos
  EYE_DESC = 'A shock collar rewired by hand to hold a new crystal, rebuilt from the Cryptos notes. Worn, it makes every other piece of the Regalia of Mystery stronger.';
  CRYPTOS_PERK_NAME = 'Mystery: Cryptos Notes';
  CRYPTOS_PERK_DESC = 'You have studied the Cryptos notes on rebuilding the Regalia of Mystery.';

  // Garb
  GARB_NAME = 'Garb of Mysteries';
  GARB_DESC = 'A sequined dress in charcoal, edged in emerald and cream-gold, cut for quiet work. You are harder to notice while sneaking and your steps fall softer. Worn with the Eye of Ra, it turns blows aside and you slip past nearly everyone.';
  GARB_PERK_DESC = 'Harder to detect while sneaking, and sneak attacks hit harder.';
  GARB_RESIST = 30;                        // damage and energy resistance of the dress itself
  GARB_EYE_RESIST = 40;                    // added to both with the Eye
  SKILL_BASE = '5.0';
  SKILL_EYE = '20.0';
  MELEE_BASE = '0.2';
  MELEE_EYE = '0.4';                       // added to the base
  OTHER_BASE = '0.1';
  OTHER_EYE = '0.2';                       // added to the base
  TATTERED_DESC = 'A torn, filthy dress that was once fine: faded green chevrons still show through the grime. Someone cared about this. It could be mended at a Chemistry Station by a good armorer who has read the Cryptos notes.';
  UNDERARMOR_SLOTS = 1992;                 // slots 33 and 36 to 40

  // Veil
  VEIL_NAME = 'Veil of Secrets';
  VEIL_DESC = 'A black veil worked with a fine net of cream-gold thread. It turns away toxins and spoilage, and lends a quiet persuasiveness; with the Eye of Ra the protection and the persuasiveness grow.';
  VEIL_PERK_DESC = 'Easier to persuade in dialogue.';
  PERSUADE_BASE = '5.0';
  PERSUADE_EYE = '10.0';
  POISON_BASE = 10;
  POISON_EYE = 10;

  // Voice
  VOICE_NAME = 'Voice of Set';
  VOICE_DESC = 'A .44 revolver rebuilt to fire without a sound. The bullet is silent at the muzzle; where it lands, it screams.';
  BURST_FORCE = 250;
  BURST_DAMAGE = 0;
  BURST_INNER = 32;
  BURST_OUTER = 128;
  BURST_STAGGER = 'Medium';
  BURST_CHANCE = 50;                       // percent, with the Eye
  BULLET_SPEED = 10000;
  FLASH_MODEL = 'Effects\MuzPistolSmallSupp.nif';

  // World
  NPC_NAME = 'Mysterious Traveler';
  HAIR_ID = $0016CA35;                     // HairFemale08 "No Apologies"
  NO_RESPAWN = $40000000;

var
  log: TStringList;
  plug, esm: IInterface;
  eyeKw, cryptosPerk, cryptosBook, seekerDress, burstEnch: IInterface;
  itemSword, itemNecklace, itemDress, itemVeil, itemRevolver: IInterface;

procedure Say(s: string);
begin
  log.Add(s);
  AddMessage(s);
end;

// A vanilla record by FormID; logs a failure if it is missing.
function Van(id: integer): IInterface;
begin
  Result := RecordByFormID(esm, id, True);
  if not Assigned(Result) then Say('FAIL: vanilla record ' + IntToHex(id, 8) + ' not found');
end;

function VanPerk(edid: string): IInterface;
begin
  Result := MainRecordByEditorID(GroupBySignature(esm, 'PERK'), edid);
  if not Assigned(Result) then Say('FAIL: vanilla perk ' + edid + ' not found');
end;

// The number to write for a record: its own FormID if it lives in the file being built, else the file-local number mapped from its load-order ID.
function Ref(rec: IInterface): integer;
begin
  if GetFileName(GetFile(rec)) = GetFileName(plug) then Result := FormID(rec)
  else Result := LoadOrderFormIDtoFileFormID(plug, GetLoadOrderFormID(rec));
end;

// Write a reference into an element and check it reads back as the record we meant.
function SetRef(el, rec: IInterface): boolean;
begin
  Result := False;
  if not Assigned(rec) then begin
    Say('FAIL: no record to reference'); Exit;
  end;
  if not Assigned(el) then begin
    Say('FAIL: missing element for ' + EditorID(rec)); Exit;
  end;
  SetNativeValue(el, Ref(rec));
  Result := Pos(EditorID(rec), GetEditValue(el)) > 0;
  if Result then Say('  reference: ' + GetEditValue(el))
  else Say('FAIL: expected ' + EditorID(rec) + ', read ' + GetEditValue(el));
end;

// A new empty record of our own.
function NewRec(sig, edid: string): IInterface;
begin
  Result := Add(Add(plug, sig, True), sig, True);
  if not Assigned(Result) then begin
    Say('FAIL: could not create ' + sig + ' ' + edid); Exit;
  end;
  SetEditorID(Result, edid);
  Say(sig + ' ' + edid + ' ' + IntToHex(FormID(Result), 8));
end;

// A new record of our own, copied from another.
function CopyAs(src: IInterface; edid: string): IInterface;
begin
  Result := nil;
  if not Assigned(src) then begin
    Say('FAIL: no source for ' + edid); Exit;
  end;
  Result := wbCopyElementToFile(src, plug, True, True);
  if not Assigned(Result) then begin
    Say('FAIL: copy failed for ' + edid); Exit;
  end;
  SetEditorID(Result, edid);
  Say(Signature(Result) + ' ' + edid + ' ' + IntToHex(FormID(Result), 8) + ' from ' + EditorID(src));
end;

procedure RemoveSig(r: IInterface; sig: string);
var
  el: IInterface;
begin
  el := ElementBySignature(r, sig);
  if Assigned(el) then Remove(el);
end;

// Change a model path (and drop the stale model hash info).
function SetModel(r: IInterface; model: string): boolean;
var
  el: IInterface;
begin
  Result := False;
  el := ElementByPath(r, 'Model\MODL - Model FileName');
  if not Assigned(el) then begin
    Say('FAIL: no model on ' + EditorID(r)); Exit;
  end;
  SetEditValue(el, model);
  el := ElementByPath(r, 'Model\MODT - Model Information');
  if Assigned(el) then Remove(el);
  Result := GetElementEditValues(r, 'Model\MODL - Model FileName') = model;
  if not Result then Say('FAIL: the model was not changed on ' + EditorID(r));
end;

// Set substitution number index on a material swap.
function SetSub(mswp: IInterface; index: integer; orig, repl: string): boolean;
var
  subs, sub: IInterface;
begin
  Result := False;
  subs := ElementByName(mswp, 'Material Substitutions');
  if not Assigned(subs) then subs := Add(mswp, 'Material Substitutions', True);
  if not Assigned(subs) then begin
    Say('FAIL: no Material Substitutions on ' + EditorID(mswp)); Exit;
  end;
  if index < ElementCount(subs) then sub := ElementByIndex(subs, index)
  else sub := ElementAssign(subs, HighInteger, nil, False);
  SetElementEditValues(sub, 'BNAM - Original Material', orig);
  SetElementEditValues(sub, 'SNAM - Replacement Material', repl);
  Say('  swap: ' + orig + ' -> ' + GetElementEditValues(sub, 'SNAM - Replacement Material'));
  Result := (ElementCount(subs) = index + 1) and (GetElementEditValues(sub, 'SNAM - Replacement Material') = repl);
  if not Result then Say('FAIL: substitution ' + IntToStr(index) + ' is wrong on ' + EditorID(mswp));
end;

function MakeSwap(edid, orig, repl: string): IInterface;
var
  r: IInterface;
begin
  Result := nil;
  r := NewRec('MSWP', edid);
  if not Assigned(r) then Exit;
  if not SetSub(r, 0, orig, repl) then Exit;
  Result := r;
end;

// Put a material swap on a record's model.
function SetModelSwap(r, mswp: IInterface): boolean;
var
  model, el: IInterface;
begin
  Result := False;
  model := ElementByName(r, 'Model');
  if not Assigned(model) then begin
    Say('FAIL: no Model on ' + EditorID(r)); Exit;
  end;
  el := ElementBySignature(model, 'MODS');
  if not Assigned(el) then el := Add(model, 'MODS', True);
  Result := SetRef(el, mswp);
end;

// Our copy of a vanilla armor addon with our material swap on both biped models.
function MakeAddon(srcid: integer; edid: string; mswp: IInterface): IInterface;
var
  arma, m, ms: IInterface;
  i: integer;
  container, sig: string;
begin
  Result := nil;
  arma := CopyAs(Van(srcid), edid);
  if not Assigned(arma) then Exit;
  for i := 0 to 1 do begin
    if i = 0 then begin
      container := 'Male Biped Model'; sig := 'MO2S';
    end else begin
      container := 'Female Biped Model'; sig := 'MO3S';
    end;
    m := ElementByName(arma, container);
    if not Assigned(m) then begin
      Say('FAIL: no "' + container + '" on ' + edid); Exit;
    end;
    ms := ElementBySignature(m, sig);
    if not Assigned(ms) then ms := Add(m, sig, True);
    if not SetRef(ms, mswp) then Exit;
  end;
  Result := arma;
end;

function SetArmature(armo, arma: IInterface): boolean;
var
  models: IInterface;
begin
  Result := False;
  models := ElementByName(armo, 'Models');
  if (not Assigned(models)) or (ElementCount(models) < 1) then begin
    Say('FAIL: no Models (armature) list on ' + EditorID(armo)); Exit;
  end;
  Result := SetRef(ElementByPath(ElementByIndex(models, 0), 'MODL - Armor Addon'), arma);
end;

procedure AddKeyword(r: IInterface; id: integer);
var
  kw, el: IInterface;
begin
  kw := ElementBySignature(r, 'KWDA');
  if not Assigned(kw) then kw := Add(r, 'KWDA', True);
  el := ElementAssign(kw, HighInteger, nil, False);
  SetNativeValue(el, id);
end;

function AddOurKeyword(r, ourkw: IInterface): boolean;
var
  kw: IInterface;
begin
  kw := ElementBySignature(r, 'KWDA');
  if not Assigned(kw) then kw := Add(r, 'KWDA', True);
  Result := SetRef(ElementAssign(kw, HighInteger, nil, False), ourkw);
end;

// Replace ma_ChineseOfficerSword with our keyword in a keyword list.
function SwapMaKeyword(list, newkw: IInterface; what: string): boolean;
var
  i: integer;
  el: IInterface;
begin
  Result := False;
  if not Assigned(list) then begin
    Say('FAIL: no keyword list on ' + what); Exit;
  end;
  for i := 0 to ElementCount(list) - 1 do begin
    el := ElementByIndex(list, i);
    if GetNativeValue(el) = OLD_MA then begin
      Result := SetRef(el, newkw); Exit;
    end;
  end;
  Say('FAIL: ma_ChineseOfficerSword not found on ' + what);
end;

// ---- weapon mod properties ----

function ModProps(o: IInterface): IInterface;
begin
  Result := ElementByName(ElementBySignature(o, 'DATA'), 'Properties');
  if not Assigned(Result) then Say('FAIL: no Properties on ' + EditorID(o));
end;

// Add a property that adds one of our records (keyword, enchantment, material swap).
function AddModRef(o, rec: IInterface; prop, v2: string): boolean;
var
  props, p: IInterface;
begin
  Result := False;
  props := ModProps(o);
  if not Assigned(props) then Exit;
  p := ElementAssign(props, HighInteger, nil, False);
  SetElementEditValues(p, 'Value Type', 'FormID,Int');
  SetElementEditValues(p, 'Function Type', 'ADD');
  SetElementEditValues(p, 'Property', prop);
  SetElementNativeValues(p, 'Value 1', Ref(rec));
  SetElementEditValues(p, 'Value 2', v2);
  SetElementNativeValues(ElementBySignature(o, 'DATA'), 'Property Count', ElementCount(props));
  Say('  property ' + prop + ': ' + GetElementEditValues(p, 'Value 1'));
  Result := Pos(EditorID(rec), GetElementEditValues(p, 'Value 1')) > 0;
  if not Result then Say('FAIL: the ' + prop + ' property is wrong on ' + EditorID(o));
end;

// Change a Float MUL+ADD property by delta: bump the existing entry, or add one.
function BumpFloatProp(o: IInterface; prop: string; delta: double): boolean;
var
  props, p: IInterface;
  i: integer;
  oldv: double;
begin
  Result := False;
  props := ModProps(o);
  if not Assigned(props) then Exit;
  for i := 0 to ElementCount(props) - 1 do begin
    p := ElementByIndex(props, i);
    if GetElementEditValues(p, 'Property') = prop then begin
      oldv := GetElementNativeValues(p, 'Value 1');
      SetElementNativeValues(p, 'Value 1', oldv + delta);
      Say('  ' + prop + ': ' + FloatToStr(oldv) + ' -> ' + GetElementEditValues(p, 'Value 1'));
      Result := True; Exit;
    end;
  end;
  p := ElementAssign(props, HighInteger, nil, False);
  SetElementEditValues(p, 'Value Type', 'Float');
  SetElementEditValues(p, 'Function Type', 'MUL+ADD');
  SetElementEditValues(p, 'Property', prop);
  SetElementNativeValues(p, 'Value 1', delta);
  SetElementNativeValues(p, 'Value 2', 0);
  SetElementNativeValues(ElementBySignature(o, 'DATA'), 'Property Count', ElementCount(props));
  Say('  ' + prop + ' added: ' + GetElementEditValues(p, 'Value 1'));
  Result := True;
end;

function RemoveKeywordProp(o: IInterface; fid: integer): boolean;
var
  props, p: IInterface;
  i: integer;
begin
  Result := False;
  props := ModProps(o);
  if not Assigned(props) then Exit;
  for i := 0 to ElementCount(props) - 1 do begin
    p := ElementByIndex(props, i);
    if (GetElementEditValues(p, 'Property') = 'Keywords') and (GetElementNativeValues(p, 'Value 1') = fid) then begin
      Remove(p);
      SetElementNativeValues(ElementBySignature(o, 'DATA'), 'Property Count', ElementCount(props));
      Result := True; Exit;
    end;
  end;
  Say('FAIL: keyword property ' + IntToHex(fid, 8) + ' not found on ' + EditorID(o));
end;

// ---- conditions, perks, effects ----

// Point a condition at one of our records and check it.
function SetCondRef(ctda, rec: IInterface): boolean;
begin
  Result := False;
  if (not Assigned(ctda)) or (not Assigned(rec)) then begin
    Say('FAIL: no condition or no record for it'); Exit;
  end;
  SetElementNativeValues(ctda, 'Parameter #1', Ref(rec));
  Result := Pos(EditorID(rec), GetElementEditValues(ctda, 'Parameter #1')) > 0;
  if Result then Say('  condition: ' + GetElementEditValues(ctda, 'Function') + ' ' + GetElementEditValues(ctda, 'Parameter #1'))
  else Say('FAIL: condition parameter reads ' + GetElementEditValues(ctda, 'Parameter #1'));
end;

// Point the tab-0 (attacker) condition of a perk entry at a function and one of our records.
function SetTab0Condition(eff: IInterface; funcName: string; param: IInterface): boolean;
var
  pcs, pc, ctda: IInterface;
  i: integer;
begin
  Result := False;
  pcs := ElementByName(eff, 'Perk Conditions');
  if not Assigned(pcs) then begin
    Say('FAIL: no Perk Conditions on an entry'); Exit;
  end;
  for i := 0 to ElementCount(pcs) - 1 do begin
    pc := ElementByIndex(pcs, i);
    if GetElementNativeValues(pc, 'PRKC - Run On (Tab Index)') = 0 then begin
      ctda := ElementBySignature(ElementByIndex(ElementByName(pc, 'Conditions'), 0), 'CTDA');
      if not Assigned(ctda) then begin
        Say('FAIL: no CTDA in the tab 0 condition'); Exit;
      end;
      SetElementEditValues(ctda, 'Function', funcName);
      if not SetCondRef(ctda, param) then Exit;
      SetElementNativeValues(ctda, 'Comparison Value', 1);
      Result := True; Exit;
    end;
  end;
  Say('FAIL: no tab 0 perk condition found on an entry');
end;

procedure SetEntry(eff: IInterface; valueStr: string; entryId: integer);
var
  fp: IInterface;
begin
  fp := ElementByName(eff, 'Function Parameters');
  SetElementEditValues(fp, 'EPFB - Perk Entry ID (unique)', IntToStr(entryId));
  SetEditValue(ElementByIndex(ElementBySignature(fp, 'EPFD'), 0), valueStr);
  Say('  entry ' + IntToStr(entryId) + ': ' + GetElementEditValues(ElementByName(eff, 'DATA - Effect Data'), 'Entry Point\Entry Point') + ' value ' + GetEditValue(ElementByIndex(ElementBySignature(fp, 'EPFD'), 0)));
end;

// Copy a perk entry into effs, set its value, entry ID and tab 0 condition.
function AddEntry(effs, srcEff: IInterface; valueStr: string; entryId: integer; funcName: string; param: IInterface): boolean;
var
  e: IInterface;
begin
  Result := False;
  e := ElementAssign(effs, HighInteger, srcEff, False);
  if not Assigned(e) then begin
    Say('FAIL: could not copy a perk entry'); Exit;
  end;
  SetEntry(e, valueStr, entryId);
  Result := SetTab0Condition(e, funcName, param);
end;

// A hidden one-rank perk copied from a vanilla perk, without its requirements and next rank.
function MakeHiddenPerk(srcid: integer; edid, title, desc: string): IInterface;
var
  perk, data, el: IInterface;
begin
  Result := nil;
  perk := CopyAs(Van(srcid), edid);
  if not Assigned(perk) then Exit;
  SetElementEditValues(perk, 'FULL', title);
  SetElementEditValues(perk, 'DESC', desc);
  data := ElementBySignature(perk, 'DATA');
  SetElementNativeValues(data, 'Num Ranks', 1);
  SetElementNativeValues(data, 'Playable', 0);
  SetElementNativeValues(data, 'Hidden', 1);
  el := ElementByName(perk, 'Conditions');
  if Assigned(el) then Remove(el);
  RemoveSig(perk, 'NNAM');
  Result := perk;
end;

// A magic effect that adds one of our perks.
function MakeAddPerkEffect(edid, title: string; perk: IInterface): IInterface;
var
  mgef, data: IInterface;
begin
  Result := nil;
  mgef := CopyAs(Van($001F4423), edid);       // ModArmorPenetrationAddPerkEffect
  if not Assigned(mgef) then Exit;
  SetElementEditValues(mgef, 'FULL', title);
  data := ElementByPath(mgef, 'Magic Effect Data\DATA - Data');
  if not Assigned(data) then begin
    Say('FAIL: no effect data on ' + edid); Exit;
  end;
  SetElementNativeValues(data, 'Perk to Apply', Ref(perk));
  if Pos(EditorID(perk), GetElementEditValues(data, 'Perk to Apply')) = 0 then begin
    Say('FAIL: ' + edid + ' does not apply the perk'); Exit;
  end;
  Result := mgef;
end;

// Append an enchantment effect copied from a vanilla enchantment's first effect.
function CopyEffect(effs: IInterface; srcid: integer): IInterface;
begin
  Result := ElementAssign(effs, HighInteger, ElementByIndex(ElementByName(Van(srcid), 'Effects'), 0), False);
  if not Assigned(Result) then Say('FAIL: could not copy an effect from ' + IntToHex(srcid, 8));
end;

// Cut an effect to one condition: "the Eye of Ra is worn".
function OnlyWithEye(eff: IInterface): boolean;
var
  conds, ctda: IInterface;
begin
  conds := ElementByName(eff, 'Conditions');
  while ElementCount(conds) > 1 do
    Remove(ElementByIndex(conds, ElementCount(conds) - 1));
  ctda := ElementBySignature(ElementByIndex(conds, 0), 'CTDA');
  SetElementEditValues(ctda, 'Function', 'WornHasKeyword');
  SetElementNativeValues(ctda, 'Type', 0);
  Result := SetCondRef(ctda, eyeKw);
  if not Result then Exit;
  SetElementNativeValues(ctda, 'Comparison Value', 1);
end;

// ---- items and recipes ----

// A broken piece: a plain, non-wearable copy of the Silver Locket, never scrappable. model '' keeps the locket's.
function MakeBroken(edid, title, model: string): IInterface;
var
  m: IInterface;
begin
  Result := nil;
  m := CopyAs(Van($00059B34), edid);          // SilverLocket (MISC)
  if not Assigned(m) then Exit;
  SetElementEditValues(m, 'FULL', title);
  if model <> '' then
    if not SetModel(m, model) then Exit;
  RemoveSig(m, 'CVPA');
  AddKeyword(m, $001CC46A);                   // UnscrappableObject
  Result := m;
end;

procedure AddComponent(recipe: IInterface; id: integer; cnt: integer);
var
  c: IInterface;
begin
  c := ElementAssign(ElementBySignature(recipe, 'FVPA'), HighInteger, nil, False);
  SetElementNativeValues(c, 'Component', id);
  SetElementNativeValues(c, 'Count', cnt);
end;

function AddHasPerkCondition(r, perk: IInterface): boolean;
var
  conds, ctda: IInterface;
begin
  Result := False;
  if not Assigned(perk) then Exit;
  conds := ElementByName(r, 'Conditions');
  if not Assigned(conds) then conds := Add(r, 'Conditions', True);
  if not Assigned(conds) then begin
    Say('FAIL: could not create the Conditions list on ' + EditorID(r)); Exit;
  end;
  ctda := ElementBySignature(ElementAssign(conds, HighInteger, nil, False), 'CTDA');
  if not Assigned(ctda) then begin
    Say('FAIL: no CTDA on the new condition of ' + EditorID(r)); Exit;
  end;
  SetElementEditValues(ctda, 'Function', 'HasPerk');
  if not SetCondRef(ctda, perk) then Exit;
  SetElementNativeValues(ctda, 'Comparison Value', 1);
  Result := True;
end;

// A Chemistry Station repair recipe that consumes the broken item. The caller adds the other components.
function MakeRecipe(edid: string; product, broken: IInterface): IInterface;
var
  r, fnam, kw: IInterface;
begin
  Result := nil;
  r := NewRec('COBJ', edid);
  if not Assigned(r) then Exit;
  Add(r, 'FVPA', True);
  Add(r, 'CNAM', True);
  if not SetRef(ElementBySignature(r, 'CNAM'), product) then Exit;
  Add(r, 'BNAM', True);
  SetElementNativeValues(r, 'BNAM', $00102158);   // WorkbenchChemlab
  fnam := Add(r, 'FNAM', True);
  kw := ElementAssign(fnam, HighInteger, nil, False);
  SetNativeValue(kw, $0006980C);                  // RecipeUtility
  Add(r, 'INTV', True);
  SetElementNativeValues(r, 'INTV\Created Object Count', 1);
  SetElementNativeValues(r, 'INTV\Priority', 0);
  AddComponent(r, Ref(broken), 1);
  Result := r;
end;

// Both gates, and a log of what the recipe ended up with.
function GateRecipe(r, skillPerk: IInterface): boolean;
var
  comps: IInterface;
  i: integer;
begin
  Result := False;
  if not AddHasPerkCondition(r, cryptosPerk) then Exit;
  if not AddHasPerkCondition(r, skillPerk) then Exit;
  comps := ElementBySignature(r, 'FVPA');
  for i := 0 to ElementCount(comps) - 1 do
    Say('  ' + EditorID(r) + ': ' + GetElementEditValues(ElementByIndex(comps, i), 'Component') + ' x ' + GetElementEditValues(ElementByIndex(comps, i), 'Count'));
  Result := True;
end;

// ---- sections ----

// Keywords, the Cryptos perk and the five broken items: what everything else points at.
function BuildShared(eyeKwEdid: string): boolean;
var
  perk, data, effs: IInterface;
begin
  Result := False;
  eyeKw := NewRec('KYWD', eyeKwEdid);
  if not Assigned(eyeKw) then Exit;
  perk := CopyAs(Van($0008E3A6), 'MoM_PERK_Cryptos');     // the Barbarian magazine perk
  if not Assigned(perk) then Exit;
  SetElementEditValues(perk, 'FULL', CRYPTOS_PERK_NAME);
  SetElementEditValues(perk, 'DESC', CRYPTOS_PERK_DESC);
  data := ElementBySignature(perk, 'DATA');
  SetElementNativeValues(data, 'Num Ranks', 1);
  effs := ElementByName(perk, 'Effects');
  if Assigned(effs) then
    while ElementCount(effs) > 0 do
      Remove(ElementByIndex(effs, ElementCount(effs) - 1));
  cryptosPerk := perk;
  itemSword := MakeBroken('MoM_MISC_BrokenBladeOfBastet', 'Mystery: Broken Sword', 'Weapons\ChineseOfficerSword\ChineseOfficerSword01.nif');
  itemNecklace := MakeBroken('MoM_MISC_BrokenEyeOfRa', 'Mystery: Broken Necklace', '');
  itemDress := MakeBroken('MoM_MISC_TatteredDress', 'Mystery: Tattered Dress', 'Clothes\SlinkyDress\GO_SequinDress.nif');
  itemVeil := MakeBroken('MoM_MISC_TatteredVeil', 'Mystery: Worn Veil', 'Armor\Raider02\Mask_GO.nif');
  itemRevolver := MakeBroken('MoM_MISC_BrokenVoice', 'Mystery: Broken Revolver', 'Weapons\44\44.nif');
  Result := Assigned(itemSword) and Assigned(itemNecklace) and Assigned(itemDress) and Assigned(itemVeil) and Assigned(itemRevolver);
end;

function BuildBlade(nw: IInterface): boolean;
var
  bladeKw, makw, perk, effs, eff, eff2, fp, pcs, pc, pc2, ctda, mgef, ench, el, omod, mswp, weap, combs, obts, incs, incl, eye, recipe: IInterface;
  i, j, swapped: integer;
begin
  Result := False;
  bladeKw := NewRec('KYWD', 'MoM_Blade_KW');
  makw := NewRec('KYWD', 'MoM_ma_Blade');
  if (not Assigned(bladeKw)) or (not Assigned(makw)) then Exit;

  // perk: 30% armor penetration with the Blade, 100% with the Eye
  perk := CopyAs(Van($00056DD7), 'MoM_PERK_Blade');       // PlayerPerk
  if not Assigned(perk) then Exit;
  SetElementEditValues(perk, 'FULL', BLADE_NAME);
  effs := ElementByName(perk, 'Effects');
  while ElementCount(effs) > 1 do
    Remove(ElementByIndex(effs, ElementCount(effs) - 1));
  eff := ElementByIndex(effs, 0);
  fp := ElementByName(eff, 'Function Parameters');
  SetEditValue(ElementByIndex(ElementBySignature(fp, 'EPFD'), 0), BLADE_MULT);
  pcs := ElementByName(eff, 'Perk Conditions');
  ctda := ElementBySignature(ElementByIndex(ElementByName(ElementByIndex(pcs, 0), 'Conditions'), 0), 'CTDA');
  if not SetCondRef(ctda, bladeKw) then Exit;
  eff2 := ElementAssign(effs, HighInteger, eff, False);
  if (not Assigned(eff2)) or (ElementCount(effs) <> 2) then begin
    Say('FAIL: could not duplicate the Blade perk entry'); Exit;
  end;
  SetEntry(eff2, BLADE_EYE_MULT, 12);
  pcs := ElementByName(eff2, 'Perk Conditions');
  pc := ElementByIndex(pcs, 0);
  pc2 := ElementAssign(pcs, HighInteger, pc, False);
  SetElementEditValues(pc2, 'PRKC - Run On (Tab Index)', '0');
  ctda := ElementBySignature(ElementByIndex(ElementByName(pc2, 'Conditions'), 0), 'CTDA');
  SetElementEditValues(ctda, 'Function', 'WornHasKeyword');
  if not SetCondRef(ctda, eyeKw) then Exit;

  mgef := MakeAddPerkEffect('MoM_MGEF_BladePerk', BLADE_NAME, perk);
  if not Assigned(mgef) then Exit;
  ench := CopyAs(Van($001F4425), 'MoM_ENCH_Blade');       // enchModArmorPenetration
  if not Assigned(ench) then Exit;
  el := ElementByIndex(ElementByName(ench, 'Effects'), 0);
  if not SetRef(ElementByPath(el, 'EFID - Base Effect'), mgef) then Exit;

  // the mod the weapon always carries
  omod := CopyAs(Van($00176DF9), 'MoM_OMOD_Blade');       // Serrated Blade
  if not Assigned(omod) then Exit;
  SetElementEditValues(omod, 'FULL', BLADE_NAME);
  SetElementEditValues(omod, 'DESC', BLADE_MOD_DESC);
  if not AddModRef(omod, bladeKw, 'Keywords', '440') then Exit;
  if not AddModRef(omod, ench, 'Enchantments', '440') then Exit;
  if not BumpFloatProp(omod, 'AttackDamage', DMG_ADD) then Exit;
  if not BumpFloatProp(omod, 'AttackActionPointCost', AP_ADD) then Exit;
  if not BumpFloatProp(omod, 'Weight', WEIGHT_ADD) then Exit;
  if not RemoveKeywordProp(omod, $000C73F2) then Exit;    // dn_HasMeleeMod_Serrated
  if not SwapMaKeyword(ElementBySignature(omod, 'MNAM'), makw, 'the Blade mod') then Exit;
  if not SetModel(omod, PLAIN_BLADE_MODEL) then Exit;
  mswp := MakeSwap('MoM_MSWP_BladeGold', 'Weapons\ChineseOfficerSword\ChineseOfficerSword01A.BGSM', 'Weapons\BladeOfBastet\BladeOfBastetGold.BGSM');
  if not Assigned(mswp) then Exit;
  if not AddModRef(omod, mswp, 'MaterialSwaps', '441') then Exit;

  // the weapon
  weap := CopyAs(Van($00147BE4), 'MoM_WEAP_BladeOfBastet');   // ChineseOfficerSword
  if not Assigned(weap) then Exit;
  SetElementEditValues(weap, 'FULL', BLADE_NAME);
  SetElementEditValues(weap, 'DESC', BLADE_DESC);
  combs := ElementByPath(weap, 'Object Template\Combinations');
  if not Assigned(combs) then begin
    Say('FAIL: no combinations on the Blade'); Exit;
  end;
  swapped := 0;
  for i := 0 to ElementCount(combs) - 1 do begin
    obts := ElementBySignature(ElementByIndex(combs, i), 'OBTS');
    incs := ElementByName(obts, 'Includes');
    if Assigned(incs) then
      for j := 0 to ElementCount(incs) - 1 do begin
        incl := ElementByIndex(incs, j);
        if GetElementNativeValues(incl, 'Mod') = $00176DF8 then begin   // No Upgrade
          if not SetRef(ElementByPath(incl, 'Mod'), omod) then Exit;
          swapped := swapped + 1;
        end;
      end;
  end;
  if swapped = 0 then begin
    Say('FAIL: no "No Upgrade" include found on the Blade'); Exit;
  end;
  if not SwapMaKeyword(ElementBySignature(weap, 'KWDA'), makw, 'the Blade') then Exit;

  recipe := MakeRecipe('MoM_COBJ_BladeOfBastet', weap, itemSword);
  if not Assigned(recipe) then Exit;
  AddComponent(recipe, $0001FABD, 4);   // Steel
  AddComponent(recipe, $0001FABB, 3);   // Silver
  AddComponent(recipe, $0001FAA6, 2);   // Gold
  AddComponent(recipe, $0001FA9F, 2);   // Crystal
  AddComponent(recipe, $0001FAA5, 3);   // Adhesive
  if not GateRecipe(recipe, Van($000264D8)) then Exit;    // Blacksmith03

  // the Eye of Ra
  eye := CopyAs(RecordByFormID(nw, $06029AFA, True), 'MoM_ARMO_EyeOfRa');   // DLC04_ShockCollar
  if not Assigned(eye) then Exit;
  SetElementEditValues(eye, 'FULL', 'Eye of Ra');
  SetElementEditValues(eye, 'DESC', EYE_DESC);
  if not AddOurKeyword(eye, eyeKw) then Exit;
  recipe := MakeRecipe('MoM_COBJ_EyeOfRa', eye, itemNecklace);
  if not Assigned(recipe) then Exit;
  AddComponent(recipe, $0001FA9F, 2);   // Crystal
  AddComponent(recipe, $0001FABB, 2);   // Silver
  AddComponent(recipe, $0001FAA5, 2);   // Adhesive
  Result := GateRecipe(recipe, VanPerk('Science03'));
end;

function BuildGarb(recipeEdid: string): boolean;
var
  perk, effs, base, ninja, mgef, ench, eff, conds, mswp, arma, armo, dama, res, kwda, recipe: IInterface;
  i, before: integer;
begin
  Result := False;
  perk := MakeHiddenPerk($0004C935, 'MoM_PERK_Garb', GARB_NAME, GARB_PERK_DESC);   // Sneak01
  if not Assigned(perk) then Exit;
  effs := ElementByName(perk, 'Effects');
  if ElementCount(effs) <> 2 then begin
    Say('FAIL: expected 2 entries on the copied Sneak perk'); Exit;
  end;
  Remove(ElementByIndex(effs, 0));              // drop Mod Detection Movement; keep Mod Detection Sneak Skill
  base := ElementByIndex(effs, 0);
  SetEntry(base, SKILL_BASE, 0);
  if not SetTab0Condition(base, 'HasPerk', perk) then Exit;
  if not AddEntry(effs, base, SKILL_EYE, 1, 'WornHasKeyword', eyeKw) then Exit;
  ninja := ElementByName(Van($0004D8A6), 'Effects');        // Ninja01: entry 0 melee, entry 1 other
  if not AddEntry(effs, ElementByIndex(ninja, 0), MELEE_BASE, 2, 'HasPerk', perk) then Exit;
  if not AddEntry(effs, ElementByIndex(ninja, 1), OTHER_BASE, 3, 'HasPerk', perk) then Exit;
  if not AddEntry(effs, ElementByIndex(ninja, 0), MELEE_EYE, 4, 'WornHasKeyword', eyeKw) then Exit;
  if not AddEntry(effs, ElementByIndex(ninja, 1), OTHER_EYE, 5, 'WornHasKeyword', eyeKw) then Exit;
  if ElementCount(effs) <> 6 then begin
    Say('FAIL: expected 6 Garb perk entries'); Exit;
  end;

  // enchantment: Perception +1, our perk, speed while sneaking, and the two resistances that need the Eye
  mgef := MakeAddPerkEffect('MoM_MGEF_GarbPerk', GARB_NAME, perk);
  if not Assigned(mgef) then Exit;
  ench := CopyAs(Van($00192193), 'MoM_ENCH_Garb');          // Fortify Perception
  if not Assigned(ench) then Exit;
  SetElementEditValues(ench, 'FULL', GARB_NAME);
  effs := ElementByName(ench, 'Effects');
  eff := CopyEffect(effs, $001F4425);                       // an Add Perk effect
  if not Assigned(eff) then Exit;
  if not SetRef(ElementByPath(eff, 'EFID - Base Effect'), mgef) then Exit;
  eff := CopyEffect(effs, $00245BDE);                       // Stealth Move
  if not Assigned(eff) then Exit;
  conds := ElementByName(eff, 'Conditions');
  if ElementCount(conds) = 2 then Remove(ElementByIndex(conds, 1));   // keep IsSneaking
  for i := 0 to 1 do begin
    eff := CopyEffect(effs, $00245BDE);
    if not Assigned(eff) then Exit;
    if i = 0 then SetElementNativeValues(eff, 'EFID - Base Effect', $0004A0AC)    // AbFortifyResistDamage
    else SetElementNativeValues(eff, 'EFID - Base Effect', $000559A4);            // AbFortifyResistEnergy
    SetElementNativeValues(eff, 'EFIT\Magnitude', GARB_EYE_RESIST);
    if not OnlyWithEye(eff) then Exit;
    Say('  ' + GetElementEditValues(eff, 'EFID - Base Effect') + ' +' + GetElementEditValues(eff, 'EFIT\Magnitude'));
  end;
  if ElementCount(effs) <> 5 then begin
    Say('FAIL: expected 5 effects on the Garb enchantment'); Exit;
  end;

  mswp := MakeSwap('MoM_MSWP_GarbStripes', 'Clothes\SlinkyDress\SequinDress.BGSM', 'Clothes\GarbOfMysteries\GarbOfMysteries.BGSM');
  if not Assigned(mswp) then Exit;
  arma := MakeAddon($0011A27A, 'MoM_ARMA_Garb', mswp);      // AAClothesSequinDress
  if not Assigned(arma) then Exit;
  armo := CopyAs(Van($0011A27B), 'MoM_ARMO_Garb');          // ClothesSequinDress
  if not Assigned(armo) then Exit;
  SetElementEditValues(armo, 'FULL', GARB_NAME);
  SetElementEditValues(armo, 'DESC', GARB_DESC);
  if not SetRef(ElementBySignature(armo, 'EITM'), ench) then Exit;
  if not SetArmature(armo, arma) then Exit;
  SetElementNativeValues(armo, 'FNAM\Armor Rating', GARB_RESIST);
  SetElementNativeValues(armo, 'DATA\Value', 50);
  SetElementNativeValues(armo, 'DATA\Weight', 1.0);
  SetElementNativeValues(armo, 'BOD2\First Person Flags', UNDERARMOR_SLOTS);
  dama := ElementBySignature(armo, 'DAMA');
  if not Assigned(dama) then dama := Add(armo, 'DAMA', True);
  if not Assigned(dama) then begin
    Say('FAIL: could not create the Garb resistances'); Exit;
  end;
  res := ElementAssign(dama, HighInteger, nil, False);
  SetElementNativeValues(res, 'Damage Type', $00060A81);    // dtEnergy
  SetElementNativeValues(res, 'Value', GARB_RESIST);
  // no ballistic weave: drop the attach point and the keyword its mods look for
  RemoveSig(armo, 'APPR');
  kwda := ElementBySignature(armo, 'KWDA');
  before := ElementCount(kwda);
  for i := ElementCount(kwda) - 1 downto 0 do
    if Pos('ma_Railroad_ClothingArmor', GetEditValue(ElementByIndex(kwda, i))) = 1 then Remove(ElementByIndex(kwda, i));
  Say('Garb: armor ' + GetElementEditValues(armo, 'FNAM\Armor Rating') + ', resistances ' + IntToStr(ElementCount(dama)) + ', keywords ' + IntToStr(before) + ' -> ' + IntToStr(ElementCount(kwda)));
  if Assigned(ElementBySignature(armo, 'APPR')) or (ElementCount(kwda) <> before - 1) or (ElementCount(dama) <> 1) then begin
    Say('FAIL: the Garb armor record is wrong'); Exit;
  end;

  recipe := MakeRecipe(recipeEdid, armo, itemDress);
  if not Assigned(recipe) then Exit;
  AddComponent(recipe, $001223C7, 6);   // Cloth
  AddComponent(recipe, $0001FAA5, 2);   // Adhesive
  AddComponent(recipe, $0001FABB, 1);   // Silver
  Result := GateRecipe(recipe, VanPerk('Armorer03'));
end;

// The tattered dress the Traveler wears (non-playable, so it does not show in her loot).
function BuildSeekerDress(edid: string): boolean;
var
  mswp, arma, dress: IInterface;
begin
  Result := False;
  mswp := MakeSwap('MoM_MSWP_TatteredDress', 'Clothes\SlinkyDress\SequinDress.BGSM', 'Clothes\GarbOfMysteries\TatteredDress.BGSM');
  if not Assigned(mswp) then Exit;
  arma := MakeAddon($0011A27A, 'MoM_ARMA_TatteredDress', mswp);
  if not Assigned(arma) then Exit;
  dress := CopyAs(Van($0011A27B), edid);
  if not Assigned(dress) then Exit;
  SetElementEditValues(dress, 'FULL', 'Tattered Dress');
  SetElementEditValues(dress, 'DESC', TATTERED_DESC);
  RemoveSig(dress, 'EITM');
  if not SetArmature(dress, arma) then Exit;
  SetElementNativeValues(dress, 'FNAM\Armor Rating', 0);
  SetElementNativeValues(dress, 'DATA\Value', 5);
  SetElementNativeValues(dress, 'DATA\Weight', 1.0);
  SetElementNativeValues(dress, 'BOD2\First Person Flags', UNDERARMOR_SLOTS);
  RemoveSig(dress, 'DAMA');
  AddKeyword(dress, $001CC46A);   // UnscrappableObject
  SetElementNativeValues(dress, 'Record Header\Record Flags', GetElementNativeValues(dress, 'Record Header\Record Flags') or $4);   // Non-Playable
  if (GetElementNativeValues(dress, 'Record Header\Record Flags') and $4) = 0 then begin
    Say('FAIL: Non-Playable was not set'); Exit;
  end;
  seekerDress := dress;
  Result := True;
end;

function BuildVeil(recipeEdid: string): boolean;
var
  perk, effs, base, pcs, pc, ee, gas, mgef, ench, eff, mswp, arma, armo, dama, res, recipe: IInterface;
  i: integer;
begin
  Result := False;
  perk := MakeHiddenPerk($0004A0D4, 'MoM_PERK_Veil', VEIL_NAME, VEIL_PERK_DESC);   // BlackWidow01
  if not Assigned(perk) then Exit;
  effs := ElementByName(perk, 'Effects');
  if ElementCount(effs) <> 2 then begin
    Say('FAIL: expected 2 entries on the copied Black Widow perk'); Exit;
  end;
  Remove(ElementByIndex(effs, 0));              // drop the weapon damage entry; keep Mod Charisma Challenge Chance
  base := ElementByIndex(effs, 0);
  pcs := ElementByName(base, 'Perk Conditions');
  for i := ElementCount(pcs) - 1 downto 0 do begin   // drop the sex condition
    pc := ElementByIndex(pcs, i);
    if GetElementNativeValues(pc, 'PRKC - Run On (Tab Index)') <> 0 then Remove(pc);
  end;
  SetEntry(base, PERSUADE_BASE, 0);
  if not SetTab0Condition(base, 'HasPerk', perk) then Exit;
  if not AddEntry(effs, base, PERSUADE_EYE, 1, 'WornHasKeyword', eyeKw) then Exit;
  // poison gas immunity: the Hazmat Suit perk's first entry
  gas := ElementAssign(effs, HighInteger, ElementByIndex(ElementByName(Van($0014EF46), 'Effects'), 0), False);
  if not Assigned(gas) then begin
    Say('FAIL: could not copy the gas entry'); Exit;
  end;
  ee := ElementByName(gas, 'Function Parameters');
  SetElementEditValues(ee, 'EPFB - Perk Entry ID (unique)', '2');
  Say('  gas entry: ' + GetElementEditValues(ElementByName(gas, 'DATA - Effect Data'), 'Entry Point\Entry Point') + ' value ' + GetEditValue(ElementByIndex(ElementBySignature(ee, 'EPFD'), 0)));
  if ElementCount(effs) <> 3 then begin
    Say('FAIL: expected 3 Veil perk entries'); Exit;
  end;

  mgef := MakeAddPerkEffect('MoM_MGEF_VeilPerk', VEIL_NAME, perk);
  if not Assigned(mgef) then Exit;
  ench := CopyAs(Van($00245BDE), 'MoM_ENCH_Veil');          // Stealth Move
  if not Assigned(ench) then Exit;
  SetElementEditValues(ench, 'FULL', VEIL_NAME);
  effs := ElementByName(ench, 'Effects');
  while ElementCount(effs) > 1 do
    Remove(ElementByIndex(effs, ElementCount(effs) - 1));
  eff := ElementByIndex(effs, 0);
  SetElementNativeValues(eff, 'EFID - Base Effect', $0004D86B);   // AbFortifyResistPoison
  SetElementNativeValues(eff, 'EFIT\Magnitude', POISON_EYE);
  if not OnlyWithEye(eff) then Exit;
  eff := CopyEffect(effs, $001F4425);
  if not Assigned(eff) then Exit;
  if not SetRef(ElementByPath(eff, 'EFID - Base Effect'), mgef) then Exit;

  mswp := MakeSwap('MoM_MSWP_Veil', 'Armor\Raider02\Raider02Mask.BGSM', 'Armor\VeilOfSecrets\VeilOfSecrets.BGSM');
  if not Assigned(mswp) then Exit;
  arma := MakeAddon($000787D0, 'MoM_ARMA_Veil', mswp);      // AA_Raider_02_Helmet_Mask
  if not Assigned(arma) then Exit;
  armo := CopyAs(Van($000787DA), 'MoM_ARMO_Veil');          // Surgical Mask
  if not Assigned(armo) then Exit;
  SetElementEditValues(armo, 'FULL', VEIL_NAME);
  SetElementEditValues(armo, 'DESC', VEIL_DESC);
  if not Assigned(ElementBySignature(armo, 'EITM')) then Add(armo, 'EITM', True);
  if not SetRef(ElementBySignature(armo, 'EITM'), ench) then Exit;
  if not SetArmature(armo, arma) then Exit;
  SetElementNativeValues(armo, 'DATA\Value', 40);
  SetElementNativeValues(armo, 'DATA\Weight', 0.2);
  dama := ElementBySignature(armo, 'DAMA');
  if not Assigned(dama) then dama := Add(armo, 'DAMA', True);
  if not Assigned(dama) then begin
    Say('FAIL: could not create the Veil resistances'); Exit;
  end;
  res := ElementAssign(dama, HighInteger, nil, False);
  SetElementNativeValues(res, 'Damage Type', $00060A84);    // dtPoison
  SetElementNativeValues(res, 'Value', POISON_BASE);
  Say('Veil: resistances ' + IntToStr(ElementCount(dama)));

  recipe := MakeRecipe(recipeEdid, armo, itemVeil);
  if not Assigned(recipe) then Exit;
  AddComponent(recipe, $001223C7, 3);   // Cloth
  AddComponent(recipe, $0001FAA5, 2);   // Adhesive
  AddComponent(recipe, $0001FABB, 2);   // Silver
  Result := GateRecipe(recipe, VanPerk('Chemist03'));
end;

// The sonic burst's enchantment: stagger whoever is caught (never the player), with the Eye worn, by chance.
function MakeBurstStagger(edid: string): IInterface;
var
  ench, effs, conds, ctda: IInterface;
begin
  Result := nil;
  ench := CopyAs(Van($0023AD16), edid);         // ench_mod_LegendaryChanceToStagger
  if not Assigned(ench) then Exit;
  effs := ElementByName(ench, 'Effects');
  while ElementCount(effs) > 1 do
    Remove(ElementByIndex(effs, ElementCount(effs) - 1));
  conds := ElementByName(ElementByIndex(effs, 0), 'Conditions');
  if not Assigned(conds) then begin
    Say('FAIL: no condition list on the burst effect'); Exit;
  end;
  while ElementCount(conds) > 2 do
    Remove(ElementByIndex(conds, ElementCount(conds) - 1));
  while ElementCount(conds) < 3 do ElementAssign(conds, HighInteger, nil, False);
  // 0: the one caught is not the player
  ctda := ElementBySignature(ElementByIndex(conds, 0), 'CTDA');
  SetElementEditValues(ctda, 'Function', 'GetIsID');
  SetElementNativeValues(ctda, 'Type', 0);
  SetElementNativeValues(ctda, 'Parameter #1', $00000007);   // the Player base record
  SetElementNativeValues(ctda, 'Comparison Value', 0);
  SetElementEditValues(ctda, 'Run On', 'Subject');
  // 1: the player wears the Eye of Ra
  ctda := ElementBySignature(ElementByIndex(conds, 1), 'CTDA');
  SetElementEditValues(ctda, 'Function', 'WornHasKeyword');
  SetElementNativeValues(ctda, 'Type', 0);
  if not SetCondRef(ctda, eyeKw) then Exit;
  SetElementNativeValues(ctda, 'Comparison Value', 1);
  SetElementEditValues(ctda, 'Run On', 'Reference');
  SetElementNativeValues(ctda, 'Reference', $00000014);      // PlayerRef
  // 2: the chance
  ctda := ElementBySignature(ElementByIndex(conds, 2), 'CTDA');
  SetElementEditValues(ctda, 'Function', 'GetRandomPercent');
  SetElementNativeValues(ctda, 'Type', 160);                 // less than or equal
  SetElementNativeValues(ctda, 'Comparison Value', BURST_CHANCE);
  SetElementEditValues(ctda, 'Run On', 'Subject');
  if (ElementCount(effs) <> 1) or (ElementCount(conds) <> 3) or (GetElementEditValues(ctda, 'Function') <> 'GetRandomPercent') or (GetElementNativeValues(ctda, 'Type') <> 160) then begin
    Say('FAIL: the burst enchantment was not set up'); Exit;
  end;
  Result := ench;
end;

function BuildVoice(recipeEdid: string): boolean;
var
  expl, proj, weap, kssm, kws, el, omod, mswp, combs, obts, incs, incl, recipe: IInterface;
  i, added: integer;
begin
  Result := False;
  burstEnch := MakeBurstStagger('MoM_ENCH_BurstStagger');
  if not Assigned(burstEnch) then Exit;

  expl := CopyAs(Van($000E5786), 'MoM_EXPL_SonicBurst');     // MS09PushExplosion
  if not Assigned(expl) then Exit;
  SetElementNativeValues(expl, 'DATA\Force', BURST_FORCE);
  SetElementNativeValues(expl, 'DATA\Damage', BURST_DAMAGE);
  SetElementNativeValues(expl, 'DATA\Inner Radius', BURST_INNER);
  SetElementNativeValues(expl, 'DATA\Outer Radius', BURST_OUTER);
  SetElementEditValues(expl, 'DATA\Stagger', BURST_STAGGER);
  SetElementNativeValues(expl, 'DATA\Sound 1', $00101672);   // FXExplosionMirelurkKingSonicProjectile
  if not Assigned(ElementBySignature(expl, 'EITM')) then Add(expl, 'EITM', True);
  if not SetRef(ElementBySignature(expl, 'EITM'), burstEnch) then Exit;
  Say('  burst: force ' + GetElementEditValues(expl, 'DATA\Force') + ', damage ' + GetElementEditValues(expl, 'DATA\Damage') + ', radius ' + GetElementEditValues(expl, 'DATA\Inner Radius') + ' / ' + GetElementEditValues(expl, 'DATA\Outer Radius') + ', stagger ' + GetElementEditValues(expl, 'DATA\Stagger'));

  proj := CopyAs(Van($00199046), 'MoM_PROJ_Voice');          // MS09PushProjectile
  if not Assigned(proj) then Exit;
  if not SetRef(ElementByPath(proj, 'DNAM\Explosion'), expl) then Exit;
  SetElementNativeValues(proj, 'DNAM\Gravity', 0);
  SetElementNativeValues(proj, 'DNAM\Speed', BULLET_SPEED);
  SetElementNativeValues(proj, 'DNAM\Muzzle Flash - Light', $001F1E46);   // MuzFlashLightMachineGunSuppressor
  SetElementEditValues(proj, 'DNAM\Muzzle Flash - Duration', '0.05');
  el := ElementByPath(proj, 'Muzzle Flash Model\NAM1 - Model FileName');
  if not Assigned(el) then begin
    Say('FAIL: no muzzle flash model on the projectile'); Exit;
  end;
  SetEditValue(el, FLASH_MODEL);
  el := ElementByPath(proj, 'Muzzle Flash Model\NAM2 - Model Information');
  if Assigned(el) then Remove(el);

  weap := CopyAs(Van($000CE97D), 'MoM_WEAP_Voice');          // the .44
  if not Assigned(weap) then Exit;
  SetElementEditValues(weap, 'FULL', VOICE_NAME);
  SetElementEditValues(weap, 'DESC', VOICE_DESC);
  if not SetRef(ElementByPath(weap, 'FNAM\Override Projectile'), proj) then Exit;
  SetElementEditValues(weap, 'DNAM\Sound Level', 'Silent');
  AddKeyword(weap, $00054A67);                               // s_20_Silenced

  // silenced gunshot: a sound keyword mapping for the .44 + Silenced
  kssm := CopyAs(Van($0002B941), 'MoM_KSSM_VoiceSilenced');  // PistolHandmadeRevolverASilencedPlayer
  if not Assigned(kssm) then Exit;
  kws := ElementByName(kssm, 'Keywords');
  added := 0;
  for i := 0 to ElementCount(kws) - 1 do
    if GetNativeValue(ElementByIndex(kws, i)) = $00055F9C then begin
      SetNativeValue(ElementByIndex(kws, i), $000D152C);     // s_40_PistolFortyFour
      added := added + 1;
    end;
  if added <> 1 then begin
    Say('FAIL: expected to replace one sound mapping keyword, replaced ' + IntToStr(added)); Exit;
  end;

  // our copy of the legendary stagger mod: the gold look, built into every template combination
  omod := CopyAs(Van($001E81AB), 'MoM_OMOD_Voice');          // mod_Legendary_Weapon_ChanceToStagger
  if not Assigned(omod) then Exit;
  mswp := MakeSwap('MoM_MSWP_VoiceGold', 'Weapons\44\44.bgsm', 'Weapons\VoiceOfSet\VoiceGold.BGSM');
  if not Assigned(mswp) then Exit;
  if not SetSub(mswp, 1, 'Weapons\44\44BullBarrel.bgsm', 'Weapons\VoiceOfSet\VoiceBullGold.BGSM') then Exit;
  if not AddModRef(omod, mswp, 'MaterialSwaps', '441') then Exit;
  // no FeaturedItem keyword (every legendary mod adds it): its pop-up opened over the craft menu and the game crashed on TAKE
  if not RemoveKeywordProp(omod, $001B3FAC) then Exit;
  Say('  FeaturedItem keyword removed from the Voice mod');
  combs:= ElementByPath(weap, 'Object Template\Combinations');
  if not Assigned(combs) then begin
    Say('FAIL: no combinations on the Voice'); Exit;
  end;
  added := 0;
  for i := 0 to ElementCount(combs) - 1 do begin
    obts := ElementBySignature(ElementByIndex(combs, i), 'OBTS');
    incs := ElementByName(obts, 'Includes');
    if Assigned(incs) then begin
      incl := ElementAssign(incs, HighInteger, nil, False);
      if not SetRef(ElementByPath(incl, 'Mod'), omod) then Exit;
      SetElementNativeValues(incl, 'Attach Point Index', 0);
      SetElementEditValues(incl, 'Optional', 'False');
      SetElementEditValues(incl, 'Don''t Use All', 'True');
      SetElementNativeValues(obts, 'Include Count', ElementCount(incs));
      added := added + 1;
    end;
  end;
  if added = 0 then begin
    Say('FAIL: no combination had an Includes list'); Exit;
  end;
  RemoveSig(weap, 'INRD');                                   // the name stays exactly "Voice of Set"
  Say('  legendary mod added to ' + IntToStr(added) + ' of ' + IntToStr(ElementCount(combs)) + ' combinations');

  recipe := MakeRecipe(recipeEdid, weap, itemRevolver);
  if not Assigned(recipe) then Exit;
  AddComponent(recipe, $0001FABD, 4);   // Steel
  AddComponent(recipe, $0003D294, 2);   // Screws
  AddComponent(recipe, $0001FABB, 2);   // Silver
  AddComponent(recipe, $0001FAA5, 3);   // Adhesive
  Result := GateRecipe(recipe, VanPerk('GunNut03'));
end;

// The Cryptos book: our sketch (on the model and the full reading page), our text, teaches the Cryptos perk.
function BuildCryptos(edid: string): boolean;
var
  mswp, stat, book: IInterface;
  text: TStringList;
begin
  Result := False;
  mswp := MakeSwap('MoM_MSWP_CryptosSketch', 'Interface\Note\PhotoHorizLowPolySilverShroud.BGSM', 'RegaliaOfMystery\CryptosSketch.BGSM');
  if not Assigned(mswp) then Exit;
  if not SetSub(mswp, 1, 'Interface\Note\Note.BGSM', 'RegaliaOfMystery\CryptosPage.BGSM') then Exit;
  stat := CopyAs(Van($001B5EF1), 'MoM_STAT_CryptosSketch');   // DONOTUSE_InventoryNote, the full reading page
  if not Assigned(stat) then Exit;
  if not SetModelSwap(stat, mswp) then Exit;
  book := CopyAs(Van($0018AC1E), edid);                       // Silver Shroud Photo
  if not Assigned(book) then Exit;
  SetElementEditValues(book, 'FULL', 'Mystery: Cryptos');
  text := TStringList.Create;
  text.LoadFromFile(CRYPTOS_FILE);
  SetElementEditValues(book, 'DESC', Trim(text.Text));
  text.Free;
  SetElementEditValues(book, 'DNAM\Flags\Add Perk', '1');
  if not SetRef(ElementByPath(book, 'DNAM\Teaches'), cryptosPerk) then Exit;
  if not SetModelSwap(book, mswp) then Exit;
  if not Assigned(ElementBySignature(book, 'INAM')) then Add(book, 'INAM', True);
  if not SetRef(ElementBySignature(book, 'INAM'), stat) then Exit;
  if Pos('THE VOICE OF SET', GetElementEditValues(book, 'DESC')) = 0 then begin
    Say('FAIL: the Cryptos text is incomplete'); Exit;
  end;
  cryptosBook := book;
  Result := True;
end;

// ---- the world ----

function AddItem(r, item: IInterface): boolean;
var
  items, entry: IInterface;
begin
  items := ElementByName(r, 'Items');
  if not Assigned(items) then begin
    items := Add(r, 'Items', True);
    entry := ElementByIndex(items, 0);
  end else
    entry := ElementAssign(items, HighInteger, nil, False);
  Result := SetRef(ElementByPath(entry, 'CNTO\Item'), item);
  SetElementNativeValues(entry, 'CNTO\Count', 1);
end;

// Swap the template's hair (and hairlines) for HAIR_ID and its extra parts.
function SetHair(npc, hairpart: IInterface): boolean;
var
  parts, extras: IInterface;
  i, removed: integer;
begin
  Result := False;
  parts := ElementByName(npc, 'Head Parts');
  if not Assigned(parts) then begin
    Say('FAIL: no Head Parts on the corpse'); Exit;
  end;
  removed := 0;
  for i := ElementCount(parts) - 1 downto 0 do
    if Pos('HairFemale', GetEditValue(ElementByIndex(parts, i))) = 1 then begin
      Remove(ElementByIndex(parts, i));
      removed := removed + 1;
    end;
  Say('  hair parts removed: ' + IntToStr(removed));
  if not SetRef(ElementAssign(parts, HighInteger, nil, False), hairpart) then Exit;
  extras := ElementByName(hairpart, 'Extra Parts');
  if Assigned(extras) then
    for i := 0 to ElementCount(extras) - 1 do
      if not SetRef(ElementAssign(parts, HighInteger, nil, False), LinksTo(ElementByIndex(extras, i))) then Exit;
  Result := removed > 0;
  if not Result then Say('FAIL: no template hair was found to replace');
end;

procedure SetPlace(r: IInterface; x, y, z, rot: string);
begin
  if not Assigned(ElementBySignature(r, 'DATA')) then Add(r, 'DATA', True);
  SetElementEditValues(r, 'DATA\Position\X', x);
  SetElementEditValues(r, 'DATA\Position\Y', y);
  SetElementEditValues(r, 'DATA\Position\Z', z);
  SetElementEditValues(r, 'DATA\Rotation\Z', rot);
end;

// Place the actor once, dead, with the saved pose of a vanilla placement.
function PlaceBody(cell, npc: IInterface; poseid: integer): boolean;
var
  achr, srcPose, pose: IInterface;
  flags: integer;
begin
  Result := False;
  srcPose := Van(poseid);
  if not Assigned(srcPose) then Exit;
  achr := Add(cell, 'ACHR', True);
  if not Assigned(achr) then begin
    Say('FAIL: could not add the placed actor to the cell'); Exit;
  end;
  if not Assigned(ElementBySignature(achr, 'NAME')) then Add(achr, 'NAME', True);
  if not SetRef(ElementBySignature(achr, 'NAME'), npc) then Exit;
  SetPlace(achr, '5514.07', '-18598.39', '1820.00', '0');
  flags := $200;                          // Starts Dead
  SetElementNativeValues(achr, 'Record Header\Record Flags', GetElementNativeValues(achr, 'Record Header\Record Flags') or flags);
  pose := ElementBySignature(srcPose, 'XRGD');
  if not Assigned(pose) then begin
    Say('FAIL: no saved pose on the source'); Exit;
  end;
  wbCopyElementToRecord(pose, achr, False, True);
  pose := ElementBySignature(srcPose, 'XRGB');
  if Assigned(pose) then wbCopyElementToRecord(pose, achr, False, True);
  if (not Assigned(ElementBySignature(achr, 'XRGD'))) or ((GetElementNativeValues(achr, 'Record Header\Record Flags') and flags) <> flags) then begin
    Say('FAIL: the body was not set up'); Exit;
  end;
  Say('PLACED the Traveler as ' + IntToHex(FormID(achr), 8));
  Result := True;
end;

// Place an object once in a cell (rot = heading in degrees).
function PlaceObject(cell, base: IInterface; x, y, z, rot: string; flags: integer): boolean;
var
  r: IInterface;
begin
  Result := False;
  if not Assigned(base) then Exit;
  r := Add(cell, 'REFR', True);
  if not Assigned(r) then begin
    Say('FAIL: could not add a reference to the cell'); Exit;
  end;
  if not Assigned(ElementBySignature(r, 'NAME')) then Add(r, 'NAME', True);
  if not SetRef(ElementBySignature(r, 'NAME'), base) then Exit;
  SetPlace(r, x, y, z, rot);
  if flags <> 0 then begin
    SetElementNativeValues(r, 'Record Header\Record Flags', GetElementNativeValues(r, 'Record Header\Record Flags') or flags);
    if (GetElementNativeValues(r, 'Record Header\Record Flags') and flags) <> flags then begin
      Say('FAIL: the reference flags were not set'); Exit;
    end;
  end;
  Say('PLACED ' + EditorID(base) + ' as ' + IntToHex(FormID(r), 8) + ' at ' + x + ', ' + y + ', ' + z + ' in cell ' + IntToHex(FormID(cell), 8));
  Result := True;
end;

// A container of our own: a vanilla look with our skin, no respawn, exactly one item. model '' keeps the mesh.
function MakeContainer(srcid: integer; edid, title: string; item: IInterface; skin, original, model: string): IInterface;
var
  c, el, flags, mswp: IInterface;
begin
  Result := nil;
  c := CopyAs(Van(srcid), edid);
  if not Assigned(c) then Exit;
  SetElementEditValues(c, 'FULL', title);
  RemoveSig(c, 'VMAD');
  el := ElementByName(c, 'Items');
  if Assigned(el) then Remove(el);
  if not AddItem(c, item) then Exit;
  flags := ElementByPath(c, 'DATA\Flags');
  if not Assigned(flags) then begin
    Say('FAIL: no container flags on ' + edid); Exit;
  end;
  SetNativeValue(flags, GetNativeValue(flags) and $FD);   // bit 1 = Respawns
  if (ElementCount(ElementByName(c, 'Items')) <> 1) or ((GetNativeValue(flags) and 2) <> 0) then begin
    Say('FAIL: ' + edid + ' still respawns or has the wrong contents'); Exit;
  end;
  if model <> '' then
    if not SetModel(c, model) then Exit;
  mswp := MakeSwap('MoM_MSWP_' + skin, original, 'RegaliaOfMystery\' + skin + '.BGSM');
  if not Assigned(mswp) then Exit;
  if not SetModelSwap(c, mswp) then Exit;
  Result := c;
end;

// An override of a vanilla cell; its references are not copied.
function OverrideCell(id: integer): IInterface;
begin
  Result := wbCopyElementToFile(Van(id), plug, False, True);
  if not Assigned(Result) then Say('FAIL: override of cell ' + IntToHex(id, 8) + ' failed');
end;

function BuildWorld(diaryEdid: string): boolean;
var
  diary, otft, npc, el, hairpart, roof, swan, cafe, hubris: IInterface;
  text: TStringList;
begin
  Result := False;
  diary := CopyAs(Van($001D5CDC), diaryEdid);   // DN036MinutemenNote
  if not Assigned(diary) then Exit;
  SetElementEditValues(diary, 'FULL', 'Mystery: Traveler''s Diary');
  text := TStringList.Create;
  text.LoadFromFile(DIARY_FILE);
  SetElementEditValues(diary, 'DESC', Trim(text.Text));
  text.Free;
  SetElementNativeValues(diary, 'INAM', $001B5EF1);   // the full note page
  if Pos('Someone should.', GetElementEditValues(diary, 'DESC')) = 0 then begin
    Say('FAIL: the diary text is incomplete'); Exit;
  end;

  otft := NewRec('OTFT', 'MoM_OTFT_Seeker');
  if not Assigned(otft) then Exit;
  el := ElementBySignature(otft, 'INAM');
  if not Assigned(el) then el := Add(otft, 'INAM', True);
  if ElementCount(el) = 0 then ElementAssign(el, HighInteger, nil, False);
  if not SetRef(ElementByIndex(el, 0), seekerDress) then Exit;
  if ElementCount(el) <> 1 then begin
    Say('FAIL: expected one outfit item'); Exit;
  end;

  npc := CopyAs(Van($0020A578), 'MoM_NPC_Seeker');    // Loot_CorpseSettlerFemale_Empty
  if not Assigned(npc) then Exit;
  if not Assigned(ElementBySignature(npc, 'FULL')) then Add(npc, 'FULL', True);
  SetElementEditValues(npc, 'FULL', NPC_NAME);
  el := ElementBySignature(npc, 'MWGT');
  if (not Assigned(el)) or (ElementCount(el) <> 3) then begin
    Say('FAIL: no three-value weight on the corpse'); Exit;
  end;
  SetNativeValue(ElementByIndex(el, 0), 1.0);   // thin
  SetNativeValue(ElementByIndex(el, 1), 0.0);
  SetNativeValue(ElementByIndex(el, 2), 0.0);
  hairpart := Van(HAIR_ID);
  if not Assigned(hairpart) then Exit;
  if not SetHair(npc, hairpart) then Exit;
  el := ElementByPath(npc, 'ACBS\Use Template Actors');
  if not Assigned(el) then begin
    Say('FAIL: no template flags on the corpse'); Exit;
  end;
  SetNativeValue(el, GetNativeValue(el) and $FF7F);   // bit 7 = Base Data (the name)
  if (GetNativeValue(el) and $80) <> 0 then begin
    Say('FAIL: Base Data is still taken from the template'); Exit;
  end;
  if not SetRef(ElementBySignature(npc, 'HCLF'), Van($0019EE60)) then Exit;   // jet black
  if not SetRef(ElementBySignature(npc, 'DOFT'), otft) then Exit;
  if not AddItem(npc, itemDress) then Exit;

  roof := OverrideCell($0000E0BA);     // HubrisComicsExt
  swan := OverrideCell($0000E0B9);     // SwansPondExt
  cafe := OverrideCell($0000E0D9);     // near the cafe
  hubris := OverrideCell($0004542D);   // HubrisComics01
  if (not Assigned(roof)) or (not Assigned(swan)) or (not Assigned(cafe)) or (not Assigned(hubris)) then Exit;
  if not PlaceBody(roof, npc, $001289CF) then Exit;
  if not PlaceObject(roof, MakeContainer($001002A4, 'MoM_CONT_Blade', 'Traveler''s Suitcase', itemSword,
    'ContSuitcase', 'SetDressing\Suitcase\Suitcase_prewar.BGSM', 'SetDressing\Suitcase\Suitcase_prewar.nif'),
    '7408.37', '-18588.25', '1856.75', '68', 0) then Exit;
  if not PlaceObject(swan, MakeContainer($0008E59E, 'MoM_CONT_Voice', 'Traveler''s Duffle Bag', itemRevolver,
    'ContDuffle', 'SetDressing\DuffleBag\DuffleBag.BGSM', ''),
    '11993.90', '-20086.55', '596.40', '35', 0) then Exit;
  if not PlaceObject(cafe, MakeContainer($0020A6FD, 'MoM_CONT_Veil', 'First Aid Kit', itemVeil,
    'ContMedKit', 'SetDressing\FirstAidKit\FirstAidKitPharm.BGSM', ''),
    '7267.84', '-20585.32', '1117.20', '180', 0) then Exit;
  if not PlaceObject(hubris, MakeContainer($001103E3, 'MoM_CONT_Eye', 'Traveler''s Tool Case', itemNecklace,
    'ContToolCase', 'SetDressing\ToolCase\ToolCase1.BGSM', ''),
    '2818.30', '-245.50', '839.50', '135', 0) then Exit;
  // the two books, loose beside her
  if not PlaceObject(roof, diary, '5556.00', '-18622.00', '1806.00', '80', NO_RESPAWN) then Exit;
  Result := PlaceObject(roof, cryptosBook, '5560.00', '-18578.00', '1806.00', '110', NO_RESPAWN);
end;

// Mark the plugin light. Done last; if xEdit refuses, the log says so and the flag can be set on the saved file.
procedure SetLightFlag(header: IInterface);
begin
  try
    SetElementNativeValues(header, 'Record Header\Record Flags', GetElementNativeValues(header, 'Record Header\Record Flags') or $200);
  except
    Say('NOTE: xEdit refused the light flag');
  end;
  if (GetElementNativeValues(header, 'Record Header\Record Flags') and $200) = 0 then Say('NOTE: the light flag is NOT set')
  else Say('light flag set');
end;

function Initialize: integer;
var
  nw, header: IInterface;
  i: integer;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    nw := nil;
    for i := 0 to FileCount - 1 do
      if LowerCase(GetFileName(FileByIndex(i))) = 'dlcnukaworld.esm' then nw := FileByIndex(i);
    if not Assigned(nw) then begin
      Say('FAIL: DLCNukaWorld.esm is not loaded: tick it and the other five DLC in the module list'); Exit;
    end;
    if (not FileExists(CRYPTOS_FILE)) or (not FileExists(DIARY_FILE)) then begin
      Say('FAIL: a text file is missing'); Exit;
    end;

    Say('Type ' + PLUGIN_HINT + ' in the filename box.');
    plug := AddNewFile;
    if not Assigned(plug) then begin
      Say('FAIL: no file created (cancelled, or the name already exists in Data?)'); Exit;
    end;
    Say('new file: ' + GetFileName(plug));
    if GetFileName(plug) <> PLUGIN_HINT + '.esp' then begin
      Say('FAIL: the file must be named ' + PLUGIN_HINT + '. Answer No to saving and run again.'); Exit;
    end;
    AddMasterIfMissing(plug, 'Fallout4.esm');
    AddMasterIfMissing(plug, 'DLCNukaWorld.esm');
    header := ElementByIndex(plug, 0);
    SetElementNativeValues(header, 'HEDR\Next Object ID', FIRST_ID);
    if not Assigned(ElementBySignature(header, 'SNAM')) then Add(header, 'SNAM', True);
    SetElementEditValues(header, 'SNAM', PLUGIN_DESC);

    if not BuildShared('MoM_EyeOfRa_KW') then Exit;
    if (FormID(eyeKw) and $00FFFFFF) <> FIRST_ID then begin
      Say('FAIL: the first record is ' + IntToHex(FormID(eyeKw), 8) + ', not object ID 000800'); Exit;
    end;
    if not BuildBlade(nw) then Exit;
    if not BuildGarb('MoM_COBJ_RepairGarb') then Exit;
    if not BuildSeekerDress('MoM_ARMO_SeekerDress') then Exit;
    if not BuildVeil('MoM_COBJ_RepairVeil') then Exit;
    if not BuildVoice('MoM_COBJ_RepairVoice') then Exit;
    if not BuildCryptos('MoM_BOOK_Cryptos') then Exit;
    if not BuildWorld('MoM_BOOK_Diary') then Exit;
    SetLightFlag(header);
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
