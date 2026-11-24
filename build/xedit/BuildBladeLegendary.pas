{
  BuildBladeLegendary.pas: builds the Blade of Bastet as a distinct WEAPON whose object template INCLUDES our own
  legendary mod (a copy of vanilla Penetrating, 001F4426). Status: WRITTEN, NOT YET RUN (2026-11-23).

  Why this shape: two earlier approaches failed in game (BuildBlade.pas: properties on the weapon template;
  BuildBladeMod.pas: the same properties on an Upgrade-slot mod). In both, with the item equipped, the player's
  ArmorPenetration stayed 0 and the perk 001F4166 was absent. A vanilla legendary (Sword of Wonders) shows
  ArmorPenetration 30 and perk rank 1, so the chain works on melee when the legendary mod is attached properly.

  What it builds (plugin RegaliaLegendTest2.esp, master Fallout4.esm), UNGATED prototype:
    1. OMOD  MoM_OMOD_BladeOfBastetLegendary: copy of mod_Legendary_Weapon_ArmorPenetrating (001F4426), so same slot
             (ap_Legendary), legendary flag, keywords, enchantment (001F4425) and ActorValues ArmorPenetration; only the
             name, description and stat value (AP_STAT) are changed.
    2. WEAP  MoM_WEAP_BladeOfBastet: copy of the Chinese Officer Sword (00147BE4). In the template's "Default"
             combination a second include is added (a copy of the existing "No Upgrade" include) pointing at our OMOD with
             Attach Point Index 0 (as every vanilla weapon that ships with a legendary mod does; an index of 1 was tried first and the game ignored the include).
    3. COBJ  MoM_COBJ_BladeOfBastet: Chemistry Station recipe (sword 1, Steel 4, Silver 3, Gold 2, Crystal 2, Adhesive 3).

  Test: untick RegaliaOfMystery.esp, RegaliaTest100.esp and RegaliaModTest.esp, tick RegaliaLegendTest2.esp. Craft it, equip, then:
    player.getav ArmorPenetration   (expect 30)      player.hasperk 001F4166   (expect 1)
  then the dummy in the heavy combat chest (plain sword about 15; expect about 17+).

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildBladeLegendary.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaLegendTest2 in the filename box. Accept the save prompt when xEdit closes. Run it ONCE (a second run fails
  because the file already exists). Log: our-scripts\build.log, with a dump of all three new records.
}
unit BuildBladeLegendary;

const
  PLUGIN_HINT = 'RegaliaLegendTest2';
  AP_STAT = '30.0';
  ITEM_NAME = 'Blade of Bastet';
  WEAP_EDID = 'MoM_WEAP_BladeOfBastet';
  OMOD_EDID = 'MoM_OMOD_BladeOfBastetLegendary';
  COBJ_EDID = 'MoM_COBJ_BladeOfBastet';
  LOG_FILE = 'Z:\home\deck\Games\mo2-lint\tools\our-scripts\build.log';
  DESC_TEXT = 'A Chinese officer''s sword reforged with silver, gold and a crystal-set hilt, in the manner of the Mistress of Mystery''s blade. Ignores 30% of the target''s damage and energy resistance. Craft it from a Chinese Officer Sword at a Chemistry Station.';

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

procedure AddComponent(comps: IInterface; formid: integer; cnt: integer);
var
  c: IInterface;
begin
  c := ElementAssign(comps, HighInteger, nil, False);
  SetElementNativeValues(c, 'Component', formid);
  SetElementNativeValues(c, 'Count', cnt);
end;

function Initialize: integer;
var
  esm, srcSword, srcOmod, f, o, w, g, r, data, props, p, comps, fnam, kw: IInterface;
  combs, comb0, obts, incs, inc: IInterface;
  i: integer;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    srcSword := RecordByFormID(esm, $00147BE4, True);   // ChineseOfficerSword
    srcOmod := RecordByFormID(esm, $001F4426, True);    // mod_Legendary_Weapon_ArmorPenetrating
    if (not Assigned(srcSword)) or (not Assigned(srcOmod)) then begin
      Say('FAIL: source records not found'); Exit;
    end;
    Say('source sword: ' + Name(srcSword));
    Say('source legendary mod: ' + Name(srcOmod));

    Say('Type ' + PLUGIN_HINT + ' in the filename box.');
    f := AddNewFile;
    if not Assigned(f) then begin
      Say('FAIL: no file created (cancelled, or the name already exists in Data?)'); Exit;
    end;
    Say('new file: ' + GetFileName(f));
    AddMasterIfMissing(f, 'Fallout4.esm');

    // 1. our legendary mod: copy of vanilla Penetrating, change name, description and the stat
    o := wbCopyElementToFile(srcOmod, f, True, True);
    if not Assigned(o) then begin
      Say('FAIL: copy of the legendary mod failed'); Exit;
    end;
    SetEditorID(o, OMOD_EDID);
    SetElementEditValues(o, 'FULL', ITEM_NAME);
    SetElementEditValues(o, 'DESC', 'Ignores 30% of the target''s damage and energy resistance.');
    data := ElementBySignature(o, 'DATA');
    props := ElementByName(data, 'Properties');
    for i := 0 to ElementCount(props) - 1 do begin
      p := ElementByIndex(props, i);
      if Pos('ActorValues', GetElementEditValues(p, 'Property')) > 0 then begin
        SetElementEditValues(p, 'Value 2', AP_STAT);
        Say('stat set on property ' + IntToStr(i) + ' = ' + GetElementEditValues(p, 'Value 2'));
      end;
    end;
    Say('legendary mod: ' + Name(o));

    // 2. the weapon: copy of the sword, then include our legendary mod in the Default combination
    w := wbCopyElementToFile(srcSword, f, True, True);
    if not Assigned(w) then begin
      Say('FAIL: copy of the sword failed'); Exit;
    end;
    SetEditorID(w, WEAP_EDID);
    SetElementEditValues(w, 'FULL', ITEM_NAME);
    SetElementEditValues(w, 'DESC', DESC_TEXT);

    combs := ElementByPath(w, 'Object Template\Combinations');
    if not Assigned(combs) then begin
      Say('FAIL: no Combinations on the weapon'); Exit;
    end;
    comb0 := ElementByIndex(combs, 0);               // the "Default" combination
    obts := ElementBySignature(comb0, 'OBTS');
    Say('combination 0: ' + Name(comb0) + ' / ' + GetElementEditValues(comb0, 'FULL'));
    incs := ElementByName(obts, 'Includes');
    if not Assigned(incs) then begin
      Say('FAIL: no Includes element'); Exit;
    end;
    Say('includes before: ' + IntToStr(ElementCount(incs)));
    inc := ElementAssign(incs, HighInteger, ElementByIndex(incs, 0), False);   // copy of the "No Upgrade" include
    SetElementNativeValues(inc, 'Mod', FormID(o));
    SetElementNativeValues(inc, 'Attach Point Index', 0);   // vanilla uniques with a legendary mod (Tesla Rifle, Sentry Bot miniguns) all use 0; index 1 was ignored by the game
    SetElementNativeValues(obts, 'Include Count', ElementCount(incs));
    Say('includes after: ' + IntToStr(ElementCount(incs)));
    Say('weapon: ' + Name(w));

    // 3. the recipe (UNGATED: no conditions)
    g := Add(f, 'COBJ', True);
    r := Add(g, 'COBJ', True);
    if not Assigned(r) then begin
      Say('FAIL: could not create the COBJ record'); Exit;
    end;
    SetEditorID(r, COBJ_EDID);
    comps := Add(r, 'FVPA', True);
    AddComponent(comps, $00147BE4, 1);   // Chinese Officer Sword
    AddComponent(comps, $0001FABD, 4);   // Steel
    AddComponent(comps, $0001FABB, 3);   // Silver
    AddComponent(comps, $0001FAA6, 2);   // Gold
    AddComponent(comps, $0001FA9F, 2);   // Crystal
    AddComponent(comps, $0001FAA5, 3);   // Adhesive
    SetElementNativeValues(r, 'CNAM', FormID(w));
    Add(r, 'BNAM', True);
    SetElementNativeValues(r, 'BNAM', $00102158);   // WorkbenchChemlab
    fnam := Add(r, 'FNAM', True);
    kw := ElementAssign(fnam, HighInteger, nil, False);
    SetNativeValue(kw, $0006980C);                  // RecipeUtility
    Add(r, 'INTV', True);
    SetElementNativeValues(r, 'INTV\Created Object Count', 1);
    SetElementNativeValues(r, 'INTV\Priority', 0);
    Say('recipe: ' + Name(r));

    log.Add('');
    log.Add('===== legendary mod dump');
    Dump(o, '');
    log.Add('');
    log.Add('===== weapon dump');
    Dump(w, '');
    log.Add('');
    log.Add('===== recipe dump');
    Dump(r, '');
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
