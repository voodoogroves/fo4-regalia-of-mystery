{
  BuildBladeMod.pas: TEST build of the Blade of Bastet as a melee UPGRADE MOD for the Chinese Officer Sword.
  Status: WRITTEN, NOT YET RUN (2026-11-23). Replaces the weapon-record approach in BuildBlade.pas, which
  was shown not to work: with the Blade equipped the player's ArmorPenetration stays 0 and the penetration
  perk (001F4166) is never added. Vanilla puts the stat, the enchantment and a keyword on an OMOD instead.

  What it builds (plugin RegaliaModTest.esp, master Fallout4.esm):
    - an OMOD copied from vanilla Electrified Serrated Blade (0014A0F1), the best vanilla upgrade: same attach point
      (ap_melee_MeleeMod "Upgrade"), target keyword (ma_ChineseOfficerSword), model, damage, bleed and shock.
      All its properties are kept, and three are appended, as vanilla Penetrating does:
        Keywords      ADD HasLegendary_Weapon_ArmorPenetrating (001F4424)
        Enchantments  ADD enchModArmorPenetration (001F4425)
        ActorValues   ADD ArmorPenetration (00097341) AP_STAT
    - a recipe copied from the Electrified Serrated recipe (0014A13B) pointing at the new mod: keeps its conditions and
      materials, and adds Silver 3, Gold 2, Crystal 2 (counts are summed if the base recipe already uses one).

  Use: craft it at a weapon workbench, on a Chinese Officer Sword, in the Upgrade slot. Then in the console:
    player.getav ArmorPenetration   (expect AP_STAT)      player.hasperk 001F4166   (expect 1)

  Run from MO2 with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildBladeMod.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaModTest in the filename box. Accept the save prompt when xEdit closes. The file lands in the game's Data folder.
  Log: our-scripts\build.log (step by step, with a dump of both new records).
}
unit BuildBladeMod;

const
  PLUGIN_HINT = 'RegaliaModTest';
  AP_STAT = '100.0';
  MOD_NAME = 'Blade of Bastet TEST100';
  MOD_EDID = 'MoM_OMOD_BladeTest100';
  COBJ_EDID = 'MoM_COBJ_BladeModTest100';
  MOD_DESC = 'TEST BUILD. Ignores 100% of the target''s damage resistance.';
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

function Initialize: integer;
var
  srcO, srcC, f, o, c, props, p, data, comps: IInterface;
begin
  Result := 0;
  log := TStringList.Create;
  try
    srcO := RecordByFormID(FileByIndex(0), $0014A0F1, True);   // mod_melee_ChineseOfficerSword_ShockAndSerrated
    srcC := RecordByFormID(FileByIndex(0), $0014A13B, True);   // co_mod_melee_ChineseOfficerSword_ShockAndSerrated
    if (not Assigned(srcO)) or (not Assigned(srcC)) then begin
      Say('FAIL: source records not found'); Exit;
    end;
    Say('source mod: ' + Name(srcO));
    Say('source recipe: ' + Name(srcC));

    // AddNewFile takes no arguments in xEdit 4.1.5f: type RegaliaModTest in the box.
    Say('Type ' + PLUGIN_HINT + ' in the filename box.');
    f := AddNewFile;
    if not Assigned(f) then begin
      Say('FAIL: no file created'); Exit;
    end;
    Say('new file: ' + GetFileName(f));
    AddMasterIfMissing(f, 'Fallout4.esm');

    // 1. the mod: copy Electrified Serrated as a new record, keep its properties, append ours
    o := wbCopyElementToFile(srcO, f, True, True);
    if not Assigned(o) then begin
      Say('FAIL: copy of the Electrified Serrated mod failed'); Exit;
    end;
    SetEditorID(o, MOD_EDID);
    SetElementEditValues(o, 'FULL', MOD_NAME);
    SetElementEditValues(o, 'DESC', MOD_DESC);

    data := ElementBySignature(o, 'DATA');
    props := ElementByName(data, 'Properties');
    Say('properties before: ' + IntToStr(ElementCount(props)));

    // Keep every existing property (damage, price, serrated/electrified keywords and enchantments)
    // and append the three that vanilla Penetrating uses.
    // a. Keywords ADD HasLegendary_Weapon_ArmorPenetrating
    p := ElementAssign(props, HighInteger, nil, False);
    SetElementEditValues(p, 'Value Type', 'FormID,Int');
    SetElementEditValues(p, 'Function Type', 'ADD');
    SetElementEditValues(p, 'Property', 'Keywords');
    SetElementNativeValues(p, 'Value 1', $001F4424);
    SetElementNativeValues(p, 'Value 2', 440);
    // b. Enchantments ADD enchModArmorPenetration
    p := ElementAssign(props, HighInteger, nil, False);
    SetElementEditValues(p, 'Value Type', 'FormID,Int');
    SetElementEditValues(p, 'Function Type', 'ADD');
    SetElementEditValues(p, 'Property', 'Enchantments');
    SetElementNativeValues(p, 'Value 1', $001F4425);
    SetElementNativeValues(p, 'Value 2', 440);
    // c. ActorValues ADD ArmorPenetration AP_STAT
    p := ElementAssign(props, HighInteger, nil, False);
    SetElementEditValues(p, 'Value Type', 'FormID,Float');
    SetElementEditValues(p, 'Function Type', 'ADD');
    SetElementEditValues(p, 'Property', 'ActorValues');
    SetElementNativeValues(p, 'Value 1', $00097341);
    SetElementEditValues(p, 'Value 2', AP_STAT);
    SetElementNativeValues(data, 'Property Count', ElementCount(props));
    Say('properties after: ' + IntToStr(ElementCount(props)));
    Say('mod: ' + Name(o));

    // 2. the recipe: copy the Electrified Serrated recipe, point it at the new mod
    c := wbCopyElementToFile(srcC, f, True, True);
    if not Assigned(c) then begin
      Say('FAIL: copy of the recipe failed'); Exit;
    end;
    SetEditorID(c, COBJ_EDID);
    SetElementNativeValues(c, 'CNAM', FormID(o));
    // At least the Electrified Serrated cost, plus the Blade's precious materials (same as the spec's sword recipe).
    comps := ElementBySignature(c, 'FVPA');
    if Assigned(comps) then begin
      Say('recipe components before: ' + IntToStr(ElementCount(comps)));
      AddOrRaise(comps, $0001FABB, 3);   // Silver
      AddOrRaise(comps, $0001FAA6, 2);   // Gold
      AddOrRaise(comps, $0001FA9F, 2);   // Crystal
      Say('recipe components after: ' + IntToStr(ElementCount(comps)));
    end else
      Say('WARN: no Components element on the recipe');
    Say('recipe: ' + Name(c));

    log.Add('');
    log.Add('===== mod dump');
    Dump(o, '');
    log.Add('');
    log.Add('===== recipe dump');
    Dump(c, '');
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
