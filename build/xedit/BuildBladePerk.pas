{
  BuildBladePerk.pas: TEST build of design "B": a workbench-crafted Upgrade mod that only adds OUR keyword, plus OUR own
  perk that reads that keyword and reduces the target's damage resistance. Status: WRITTEN, NOT YET RUN (2026-11-23).

  Why: three attempts to give the sword the vanilla legendary chain (template stat, Upgrade-slot mod with the stat and
  enchantment, template include of a legendary mod) all failed in game. Vanilla's mundane melee mods (Puncturing, Spiked)
  work differently: the mod only adds a keyword and the base PlayerPerk has an entry that checks the weapon for it
  (Mod Target Damage Resistance, Multiply Value 0.85, weapon tab, HasKeyword ap_melee_ArmorPenetrate). We copy that
  pattern with our own keyword and our own perk, so we choose the number.

  BUG FIXED (2026-11-23, found in the first run's log): earlier scripts looked up the OMOD data block with
  ElementByName(o, 'Data'), which returns nothing (the element is named 'DATA - Data'), so no property was ever added
  to a copied mod. BuildBladeMod.pas had the same bug: its Upgrade-slot test never contained the penetration properties,
  so that approach is still UNTESTED. This script uses ElementBySignature(o, 'DATA') and fails loudly if it is missing.

  What it builds (plugin RegaliaPerkTest2.esp, master Fallout4.esm). Two alternative upgrade mods, both crafted at the
  weapon workbench with the same recipe (copy of the Electrified Serrated recipe 0014A13B plus Silver 3, Gold 2,
  Crystal 2; needs Blacksmith 3 and Science 1):
    1. KYWD  MoM_Blade_KW
    2. OMOD A  "Blade of Bastet (keyword test)": copy of Electrified Serrated Blade (0014A0F1), all properties kept,
             plus Keywords ADD MoM_Blade_KW. Works only with the perk below.
    3. OMOD B  "Blade of Bastet (stat test)": copy of the No Upgrade mod (00176DF8) with the vanilla trio that gun
             Armor Piercing receivers use: Keywords HasLegendary_Weapon_ArmorPenetrating (001F4424), Enchantments
             enchModArmorPenetration (001F4425), ActorValues ArmorPenetration (00097341) = STAT_VALUE. Needs no perk of ours.
    4. COBJ  one recipe for each mod.
    5. PERK  MoM_PERK_BladeTest: copy of the base PlayerPerk (00056DD7) with every effect removed except the first
             (Mod Target Damage Resistance / Multiply Value, weapon-tab condition HasKeyword). The condition is
             re-pointed to MoM_Blade_KW and the multiplier set to PERK_MULT (0.0 for the test: ignores ALL armor).
             The final value for the spec is 0.70 (30%).

  Test in game (only this plugin ticked from ours; untick the other Regalia plugins):
    Mod B (stat test): put "Blade of Bastet (stat test)" on a sword, equip, console: player.getav ArmorPenetration
       (expect STAT_VALUE) and player.hasperk 001F4166 (expect 1). No perk of ours needed.
    Mod A (keyword test): player.addperk <ID> (find it with: help "Bastet" 4 PERK), put "Blade of Bastet (keyword test)"
       on a sword; dummy in the heavy combat chest: plain sword about 15, expect about 31 (multiplier 0.0).

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildBladePerk.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaPerkTest2 in the filename box. Accept the save prompt when xEdit closes. Run it ONCE.
  Log: our-scripts\build.log (step by step, with dumps of all new records).
}
unit BuildBladePerk;

const
  PLUGIN_HINT = 'RegaliaPerkTest2';
  STAT_VALUE = '30.0';
  PERK_MULT = '0.0';
  KW_EDID = 'MoM_Blade_KW';
  OMOD_A_EDID = 'MoM_OMOD_BladeKeyword';
  COBJ_A_EDID = 'MoM_COBJ_BladeKeyword';
  OMOD_B_EDID = 'MoM_OMOD_BladeStat';
  COBJ_B_EDID = 'MoM_COBJ_BladeStat';
  PERK_EDID = 'MoM_PERK_BladeTest';
  PERK_NAME = 'Bastet Test Perk';
  LOG_FILE = 'Z:\home\deck\Games\mo2-lint\tools\our-scripts\build.log';

var
  log: TStringList;

procedure Say(s: string);
begin
  log.Add(s);
  AddMessage(s);
end;

procedure Dump(e: IInterface; indent: string);
var
  i: integer;
  n: string;
begin
  n := Name(e);
  if Pos('Model Information', n) > 0 then
    log.Add(indent + n + ' = (skipped)')
  else begin
    log.Add(indent + n + ' = ' + GetEditValue(e));
    for i := 0 to ElementCount(e) - 1 do
      Dump(ElementByIndex(e, i), indent + '  ');
  end;
end;

// Add cnt of a component to the recipe. If the recipe already uses it, the counts are summed.
procedure AddOrRaise(comps: IInterface; formid: integer; cnt: integer);
var
  i: integer;
  el: IInterface;
begin
  for i := 0 to ElementCount(comps) - 1 do begin
    el := ElementByIndex(comps, i);
    if GetElementNativeValues(el, 'Component') = formid then begin
      SetElementNativeValues(el, 'Count', GetElementNativeValues(el, 'Count') + cnt);
      Exit;
    end;
  end;
  el := ElementAssign(comps, HighInteger, nil, False);
  SetElementNativeValues(el, 'Component', formid);
  SetElementNativeValues(el, 'Count', cnt);
end;

// Add one property to an OMOD copy. The data block is found by signature; fail loudly if it is missing.
function AddModProp(o: IInterface; vtype, ftype, prop: string; v1: integer; v2: string): boolean;
var
  data, props, p: IInterface;
begin
  Result := False;
  data := ElementBySignature(o, 'DATA');
  if not Assigned(data) then begin
    Say('FAIL: no DATA block on ' + Name(o)); Exit;
  end;
  props := ElementByName(data, 'Properties');
  if not Assigned(props) then begin
    Say('FAIL: no Properties on ' + Name(o)); Exit;
  end;
  p := ElementAssign(props, HighInteger, nil, False);
  SetElementEditValues(p, 'Value Type', vtype);
  SetElementEditValues(p, 'Function Type', ftype);
  SetElementEditValues(p, 'Property', prop);
  SetElementNativeValues(p, 'Value 1', v1);
  SetElementEditValues(p, 'Value 2', v2);
  SetElementNativeValues(data, 'Property Count', ElementCount(props));
  Say('  property added: ' + prop + ' (now ' + IntToStr(ElementCount(props)) + ' on ' + EditorID(o) + ')');
  Result := True;
end;

// Copy a recipe, point it at the mod and add the precious materials.
function MakeRecipe(f, srcCobj, modRec: IInterface; edid: string): IInterface;
var
  c, comps: IInterface;
begin
  c := wbCopyElementToFile(srcCobj, f, True, True);
  SetEditorID(c, edid);
  SetElementNativeValues(c, 'CNAM', FormID(modRec));
  comps := ElementBySignature(c, 'FVPA');
  if Assigned(comps) then begin
    AddOrRaise(comps, $0001FABB, 3);   // Silver
    AddOrRaise(comps, $0001FAA6, 2);   // Gold
    AddOrRaise(comps, $0001FA9F, 2);   // Crystal
    Say('  recipe ' + edid + ' components: ' + IntToStr(ElementCount(comps)));
  end else
    Say('WARN: no Components element on ' + edid);
  Result := c;
end;

function Initialize: integer;
var
  esm, srcOmod, srcNull, srcCobj, srcPerk, f, g, kw, oA, oB, cA, cB, perk: IInterface;
  effs, eff, fp, epfd, pcs, pc, conds, cond, ctda: IInterface;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    srcOmod := RecordByFormID(esm, $0014A0F1, True);   // mod_melee_ChineseOfficerSword_ShockAndSerrated
    srcNull := RecordByFormID(esm, $00176DF8, True);   // mod_melee_ChineseOfficerSword_Null
    srcCobj := RecordByFormID(esm, $0014A13B, True);   // co_mod_melee_ChineseOfficerSword_ShockAndSerrated
    srcPerk := RecordByFormID(esm, $00056DD7, True);   // PlayerPerk
    if (not Assigned(srcOmod)) or (not Assigned(srcNull)) or (not Assigned(srcCobj)) or (not Assigned(srcPerk)) then begin
      Say('FAIL: source records not found'); Exit;
    end;
    Say('sources: ' + Name(srcOmod) + ' | ' + Name(srcCobj) + ' | ' + Name(srcPerk));

    Say('Type ' + PLUGIN_HINT + ' in the filename box.');
    f := AddNewFile;
    if not Assigned(f) then begin
      Say('FAIL: no file created (cancelled, or the name already exists in Data?)'); Exit;
    end;
    Say('new file: ' + GetFileName(f));
    AddMasterIfMissing(f, 'Fallout4.esm');

    // 1. our keyword
    g := Add(f, 'KYWD', True);
    kw := Add(g, 'KYWD', True);
    if not Assigned(kw) then begin
      Say('FAIL: could not create the keyword'); Exit;
    end;
    SetEditorID(kw, KW_EDID);
    Say('keyword: ' + Name(kw));

    // 2. mod A: keyword test. Copy Electrified Serrated, keep its properties, add our keyword
    oA := wbCopyElementToFile(srcOmod, f, True, True);
    if not Assigned(oA) then begin
      Say('FAIL: copy of the Electrified Serrated mod failed'); Exit;
    end;
    SetEditorID(oA, OMOD_A_EDID);
    SetElementEditValues(oA, 'FULL', 'Blade of Bastet (keyword test)');
    SetElementEditValues(oA, 'DESC', 'TEST BUILD A. Adds the Bastet keyword; needs the Bastet test perk.');
    if not AddModProp(oA, 'FormID,Int', 'ADD', 'Keywords', FormID(kw), '440') then Exit;
    Say('mod A: ' + Name(oA));

    // 3. mod B: stat test. Copy No Upgrade and give it the vanilla trio used by gun Armor Piercing receivers
    oB := wbCopyElementToFile(srcNull, f, True, True);
    if not Assigned(oB) then begin
      Say('FAIL: copy of the No Upgrade mod failed'); Exit;
    end;
    SetEditorID(oB, OMOD_B_EDID);
    SetElementEditValues(oB, 'FULL', 'Blade of Bastet (stat test)');
    SetElementEditValues(oB, 'DESC', 'TEST BUILD B. Vanilla armor-penetration stat and enchantment.');
    if not AddModProp(oB, 'FormID,Int', 'ADD', 'Keywords', $001F4424, '440') then Exit;
    if not AddModProp(oB, 'FormID,Int', 'ADD', 'Enchantments', $001F4425, '440') then Exit;
    if not AddModProp(oB, 'FormID,Float', 'ADD', 'ActorValues', $00097341, STAT_VALUE) then Exit;
    Say('mod B: ' + Name(oB));

    // recipes for both
    cA := MakeRecipe(f, srcCobj, oA, COBJ_A_EDID);
    cB := MakeRecipe(f, srcCobj, oB, COBJ_B_EDID);
    Say('recipes: ' + Name(cA) + ' | ' + Name(cB));

    // 4. our perk: copy PlayerPerk, keep only its first effect (the melee armor-penetration entry), re-point it
    perk := wbCopyElementToFile(srcPerk, f, True, True);
    if not Assigned(perk) then begin
      Say('FAIL: copy of PlayerPerk failed'); Exit;
    end;
    SetEditorID(perk, PERK_EDID);
    SetElementEditValues(perk, 'FULL', PERK_NAME);
    effs := ElementByName(perk, 'Effects');
    Say('perk effects before: ' + IntToStr(ElementCount(effs)));
    while ElementCount(effs) > 1 do
      Remove(ElementByIndex(effs, ElementCount(effs) - 1));
    Say('perk effects after: ' + IntToStr(ElementCount(effs)));
    eff := ElementByIndex(effs, 0);

    // the multiplier
    fp := ElementByName(eff, 'Function Parameters');
    epfd := ElementBySignature(fp, 'EPFD');
    SetEditValue(ElementByIndex(epfd, 0), PERK_MULT);
    Say('multiplier now: ' + GetEditValue(ElementByIndex(epfd, 0)));

    // the weapon-tab condition: HasKeyword <ours>
    pcs := ElementByName(eff, 'Perk Conditions');
    pc := ElementByIndex(pcs, 0);
    conds := ElementByName(pc, 'Conditions');
    cond := ElementByIndex(conds, 0);
    ctda := ElementBySignature(cond, 'CTDA');
    SetElementNativeValues(ctda, 'Parameter #1', FormID(kw));
    Say('condition keyword now: ' + GetElementEditValues(ctda, 'Parameter #1') + ' / tab ' + GetElementEditValues(pc, 'PRKC - Run On (Tab Index)'));
    Say('perk: ' + Name(perk));

    log.Add('');
    log.Add('===== keyword dump');
    Dump(kw, '');
    log.Add('');
    log.Add('===== mod A dump');
    Dump(oA, '');
    log.Add('');
    log.Add('===== mod B dump');
    Dump(oB, '');
    log.Add('');
    log.Add('===== recipe A dump');
    Dump(cA, '');
    log.Add('');
    log.Add('===== perk dump');
    Dump(perk, '');
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
