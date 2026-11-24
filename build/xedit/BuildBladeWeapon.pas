{
  BuildBladeWeapon.pas: TEST build, round 6 (the Blade as its OWN WEAPON). Status: WRITTEN, NOT YET RUN (2026-11-24).

  Why: round 5 (an Upgrade mod plus a naming rule) showed the name rule puts its text in FRONT of the base name
  ("of Bastet Chinese Officer Sword") whatever its index. Chris wants the Blade's name to be just "Blade of Bastet".
  A weapon record of its own has its own name: with no name keyword (no Serrated) no naming rule fires, so the whole
  name is the weapon's FULL. No override of the shared naming record is needed.

  What it builds (plugin RegaliaWeapon1.esp, master Fallout4.esm):
    WEAP MoM_WEAP_BladeOfBastet: a copy of the Chinese Officer Sword (00147BE4), name "Blade of Bastet"; every template
         include that was the sword's "No Upgrade" mod (00176DF8) now points at OUR mod instead.
    OMOD MoM_OMOD_Blade: the Serrated-only mod (00176DF9) with the round 4 stats (AttackDamage 0.75 -> 1.2,
         AttackActionPointCost -0.43, Weight -0.33), its bleed enchantment, our keyword MoM_Blade_KW and our
         ENCH -> MGEF -> PERK chain, and WITHOUT dn_HasMeleeMod_Serrated.
    COBJ MoM_COBJ_BladeOfBastet: Chemistry Station, UNGATED: Chinese Officer Sword + Steel 4, Silver 3, Gold 2,
         Crystal 2, Adhesive 3 (the round 1 recipe).
    KYWD/PERK/MGEF/ENCH and the Eye of Ra item: unchanged from round 5 (perk entries 0.70 and 0.0).
  Speed stays medium (decided). The Upgrade-mod version is in RegaliaName1.esp / RegaliaStats1.esp for comparison.

  THE RISK: that our mod attaches through the weapon's default template include on a crafted item. Round 1 of this
  project failed with a LEGENDARY mod include; a plain Upgrade mod there is vanilla's own pattern, but it is untested.

  Test in game (only RegaliaWeapon1.esp ticked from ours): craft the Blade at a Chemistry Station (consumes a Chinese
  Officer Sword). Check, in this order:
    1. its NAME in the Pip-Boy and the crafting menu: "Blade of Bastet" and nothing else;
    2. does it carry the mod? damage about 70 unarmored, weight 2, VATS about 20, bleed. If these are the sword's
       plain 32 / 3 / 35, the include did not attach (tell me; that is the main failure);
    3. help "Bastet" 4 PERK, then player.hasperk <ID>: 1 while equipped, 0 unequipped;
    4. the dummy's heavy chest (about 50), then the Eye (70s);
    5. open the weapon workbench: what mods does the Blade offer (can the blade-mod slot be changed)?

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildBladeWeapon.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaWeapon1 in the filename box. Accept the save prompt when xEdit closes. Run it ONCE.
  Log: our-scripts\build.log.
}
unit BuildBladeWeapon;

const
  PLUGIN_HINT = 'RegaliaWeapon1';
  WEAP_EDID = 'MoM_WEAP_BladeOfBastet';
  WEAP_NAME = 'Blade of Bastet';
  DESC_TEXT = 'A Chinese officer''s sword reforged with silver, gold and a crystal-set hilt, in the manner of the Mistress of Mystery''s blade. Lighter, quicker to strike in VATS, and it bleeds. Ignores part of the target''s armor. Craft it from a Chinese Officer Sword at a Chemistry Station.';
  DMG_ADD = 0.45;
  AP_ADD = -0.43;
  WEIGHT_ADD = -0.33;
  BLADE_MULT = '0.7';
  EYE_MULT = '0.0';
  KW_EDID = 'MoM_Blade_KW';
  EYEKW_EDID = 'MoM_EyeOfRa_KW';
  OMOD_EDID = 'MoM_OMOD_Blade';
  COBJ_EDID = 'MoM_COBJ_BladeOfBastet';
  PERK_EDID = 'MoM_PERK_Blade';
  PERK_NAME = 'Bastet Test Perk';
  MGEF_EDID = 'MoM_MGEF_BladePerk';
  ENCH_EDID = 'MoM_ENCH_Blade';
  ARMO_EDID = 'MoM_ARMO_EyeOfRa';
  ARMO_NAME = 'Eye of Ra (test)';
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

// Add one FormID property (keyword / enchantment) to an OMOD copy.
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

// Change a Float MUL+ADD property by delta: bump the existing entry in place, or add one. Logs old and new values.
function BumpFloatProp(o: IInterface; prop: string; delta: double): boolean;
var
  data, props, p: IInterface;
  i: integer;
  oldv: double;
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
  for i := 0 to ElementCount(props) - 1 do begin
    p := ElementByIndex(props, i);
    if GetElementEditValues(p, 'Property') = prop then begin
      oldv := GetElementNativeValues(p, 'Value 1');
      SetElementNativeValues(p, 'Value 1', oldv + delta);
      Say('  ' + prop + ' bumped on ' + EditorID(o) + ': ' + FloatToStr(oldv) + ' -> ' + GetElementEditValues(p, 'Value 1'));
      Result := True; Exit;
    end;
  end;
  p := ElementAssign(props, HighInteger, nil, False);
  SetElementEditValues(p, 'Value Type', 'Float');
  SetElementEditValues(p, 'Function Type', 'MUL+ADD');
  SetElementEditValues(p, 'Property', prop);
  SetElementNativeValues(p, 'Value 1', delta);
  SetElementNativeValues(p, 'Value 2', 0);
  SetElementNativeValues(data, 'Property Count', ElementCount(props));
  Say('  ' + prop + ' added on ' + EditorID(o) + ': ' + GetElementEditValues(p, 'Value 1') + ' (now ' + IntToStr(ElementCount(props)) + ' properties)');
  Result := True;
end;

// Remove the Keywords property entry that adds one keyword (by FormID). Fails loudly if it is not there.
function RemoveKeywordProp(o: IInterface; fid: integer): boolean;
var
  data, props, p: IInterface;
  i: integer;
begin
  Result := False;
  data := ElementBySignature(o, 'DATA');
  props := ElementByName(data, 'Properties');
  if not Assigned(props) then begin
    Say('FAIL: no Properties on ' + Name(o)); Exit;
  end;
  for i := 0 to ElementCount(props) - 1 do begin
    p := ElementByIndex(props, i);
    if (GetElementEditValues(p, 'Property') = 'Keywords') and (GetElementNativeValues(p, 'Value 1') = fid) then begin
      Say('  removing keyword property: ' + GetElementEditValues(p, 'Value 1') + ' from ' + EditorID(o));
      Remove(p);
      SetElementNativeValues(data, 'Property Count', ElementCount(props));
      Say('  properties now: ' + IntToStr(ElementCount(props)));
      Result := True; Exit;
    end;
  end;
  Say('FAIL: keyword ' + IntToHex(fid, 8) + ' not found among the properties of ' + EditorID(o));
end;

procedure AddComponent(comps: IInterface; formid: integer; cnt: integer);
var
  c: IInterface;
begin
  c := ElementAssign(comps, HighInteger, nil, False);
  SetElementNativeValues(c, 'Component', formid);
  SetElementNativeValues(c, 'Count', cnt);
end;

// The Blade weapon: a copy of the sword whose template includes use OUR mod where the sword used "No Upgrade".
function MakeWeapon(f, srcWeap, omod: IInterface): IInterface;
var
  w, combs, comb, obts, incs, incl: IInterface;
  i, j, swapped: integer;
begin
  Result := nil;
  w := wbCopyElementToFile(srcWeap, f, True, True);
  if not Assigned(w) then begin
    Say('FAIL: copy of the sword failed'); Exit;
  end;
  SetEditorID(w, WEAP_EDID);
  SetElementEditValues(w, 'FULL', WEAP_NAME);
  SetElementEditValues(w, 'DESC', DESC_TEXT);
  combs := ElementByPath(w, 'Object Template\Combinations');
  if not Assigned(combs) then begin
    Say('FAIL: no Object Template\Combinations on the weapon copy'); Exit;
  end;
  swapped := 0;
  for i := 0 to ElementCount(combs) - 1 do begin
    comb := ElementByIndex(combs, i);
    obts := ElementBySignature(comb, 'OBTS');
    incs := ElementByName(obts, 'Includes');
    if Assigned(incs) then
      for j := 0 to ElementCount(incs) - 1 do begin
        incl := ElementByIndex(incs, j);
        if GetElementNativeValues(incl, 'Mod') = $00176DF8 then begin
          SetElementNativeValues(incl, 'Mod', FormID(omod));
          Say('  combination "' + GetElementEditValues(comb, 'FULL - Name') + '" include ' + IntToStr(j) + ' now: ' + GetElementEditValues(incl, 'Mod'));
          swapped := swapped + 1;
        end;
      end;
  end;
  if swapped = 0 then begin
    Say('FAIL: no template include of "No Upgrade" (00176DF8) found to replace'); Exit;
  end;
  Say('weapon: ' + Name(w) + ' (' + IntToStr(swapped) + ' includes replaced)');
  Result := w;
end;

// The recipe: Chemistry Station, ungated, consumes the sword.
function MakeWeaponRecipe(f, w: IInterface): IInterface;
var
  g, r, comps, fnam, kw: IInterface;
begin
  Result := nil;
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
  Result := r;
end;

function MakeKeyword(g: IInterface; edid: string): IInterface;
begin
  Result := Add(g, 'KYWD', True);
  if Assigned(Result) then SetEditorID(Result, edid);
end;

// One Blade mod: copy of the Serrated-only mod + our keyword + our enchantment + the stat changes.
function MakeBladeMod(f, srcOmod, kw, ench: IInterface; edid, title, desc: string): IInterface;
var
  o: IInterface;
begin
  Result := nil;
  o := wbCopyElementToFile(srcOmod, f, True, True);
  if not Assigned(o) then begin
    Say('FAIL: copy of the Serrated mod failed'); Exit;
  end;
  SetEditorID(o, edid);
  SetElementEditValues(o, 'FULL', title);
  SetElementEditValues(o, 'DESC', desc);
  if not AddModProp(o, 'FormID,Int', 'ADD', 'Keywords', FormID(kw), '440') then Exit;
  if not AddModProp(o, 'FormID,Int', 'ADD', 'Enchantments', FormID(ench), '440') then Exit;
  if not BumpFloatProp(o, 'AttackDamage', DMG_ADD) then Exit;
  if not BumpFloatProp(o, 'AttackActionPointCost', AP_ADD) then Exit;
  if not BumpFloatProp(o, 'Weight', WEIGHT_ADD) then Exit;
  if not RemoveKeywordProp(o, $000C73F2) then Exit;   // dn_HasMeleeMod_Serrated: only feeds the naming rule
  Result := o;
end;

function Initialize: integer;
var
  esm, srcOmod, srcWeap, srcPerk, srcEnch, srcMgef, srcArmo: IInterface;
  f, g, kw, eyekw, oA, w, cA, perk, mgef, ench, armo: IInterface;
  effs, eff, eff2, fp, epfd, pcs, pcs2, pc, pc2, conds, cond, ctda, mdata, ees, kwda, el: IInterface;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    srcOmod := RecordByFormID(esm, $00176DF9, True);   // mod_melee_ChineseOfficerSword_Serrated "Serrated Blade"
    srcWeap := RecordByFormID(esm, $00147BE4, True);   // ChineseOfficerSword
    srcPerk := RecordByFormID(esm, $00056DD7, True);   // PlayerPerk
    srcEnch := RecordByFormID(esm, $001F4425, True);   // enchModArmorPenetration
    srcMgef := RecordByFormID(esm, $001F4423, True);   // ModArmorPenetrationAddPerkEffect
    srcArmo := RecordByFormID(esm, $001C4BE8, True);   // ClothesEyeGlasses
    if (not Assigned(srcOmod)) or (not Assigned(srcWeap)) or (not Assigned(srcPerk)) or
       (not Assigned(srcEnch)) or (not Assigned(srcMgef)) or (not Assigned(srcArmo)) then begin
      Say('FAIL: source records not found (Serrated OMOD 00176DF9 / sword 00147BE4 / others)'); Exit;
    end;
    Say('sources: ' + Name(srcOmod) + ' | ' + Name(srcWeap) + ' | ' + Name(srcPerk) + ' | ' + Name(srcEnch) + ' | ' + Name(srcMgef) + ' | ' + Name(srcArmo));

    Say('Type ' + PLUGIN_HINT + ' in the filename box.');
    f := AddNewFile;
    if not Assigned(f) then begin
      Say('FAIL: no file created (cancelled, or the name already exists in Data?)'); Exit;
    end;
    Say('new file: ' + GetFileName(f));
    AddMasterIfMissing(f, 'Fallout4.esm');

    // keywords
    g := Add(f, 'KYWD', True);
    kw := MakeKeyword(g, KW_EDID);
    eyekw := MakeKeyword(g, EYEKW_EDID);
    if (not Assigned(kw)) or (not Assigned(eyekw)) then begin
      Say('FAIL: could not create the keywords'); Exit;
    end;
    Say('keywords: ' + Name(kw) + ' | ' + Name(eyekw));

    // perk (first entry: Blade 0.70)
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
    eff := ElementByIndex(effs, 0);
    fp := ElementByName(eff, 'Function Parameters');
    epfd := ElementBySignature(fp, 'EPFD');
    SetEditValue(ElementByIndex(epfd, 0), BLADE_MULT);
    Say('blade multiplier now: ' + GetEditValue(ElementByIndex(epfd, 0)));
    pcs := ElementByName(eff, 'Perk Conditions');
    pc := ElementByIndex(pcs, 0);
    conds := ElementByName(pc, 'Conditions');
    cond := ElementByIndex(conds, 0);
    ctda := ElementBySignature(cond, 'CTDA');
    SetElementNativeValues(ctda, 'Parameter #1', FormID(kw));
    Say('blade condition keyword now: ' + GetElementEditValues(ctda, 'Parameter #1') + ' / tab ' + GetElementEditValues(pc, 'PRKC - Run On (Tab Index)'));
    Say('perk: ' + Name(perk));

    // magic effect -> perk
    mgef := wbCopyElementToFile(srcMgef, f, True, True);
    if not Assigned(mgef) then begin
      Say('FAIL: copy of the magic effect failed'); Exit;
    end;
    SetEditorID(mgef, MGEF_EDID);
    SetElementEditValues(mgef, 'FULL', MGEF_EDID);
    mdata := ElementByPath(mgef, 'Magic Effect Data\DATA - Data');
    if not Assigned(mdata) then begin
      Say('FAIL: no Magic Effect Data\DATA - Data on the magic effect copy'); Exit;
    end;
    SetElementNativeValues(mdata, 'Perk to Apply', FormID(perk));
    Say('magic effect perk now: ' + GetElementEditValues(mdata, 'Perk to Apply'));

    // enchantment -> magic effect
    ench := wbCopyElementToFile(srcEnch, f, True, True);
    if not Assigned(ench) then begin
      Say('FAIL: copy of the enchantment failed'); Exit;
    end;
    SetEditorID(ench, ENCH_EDID);
    ees := ElementByName(ench, 'Effects');
    el := ElementByIndex(ees, 0);
    SetElementNativeValues(el, 'EFID - Base Effect', FormID(mgef));
    Say('enchantment effect now: ' + GetElementEditValues(el, 'EFID - Base Effect'));

    // the two Blade mods and their recipes
    oA := MakeBladeMod(f, srcOmod, kw, ench, OMOD_EDID, 'Blade of Bastet',
      'TEST BUILD 6. Lighter, cheaper in VATS, stronger; targets bleed; ignores part of the target''s armor.');
    if not Assigned(oA) then Exit;
    Say('mod: ' + Name(oA));
    w := MakeWeapon(f, srcWeap, oA);
    if not Assigned(w) then Exit;
    cA := MakeWeaponRecipe(f, w);
    if not Assigned(cA) then Exit;

    // Eye of Ra (last, so a failure here leaves the stats test intact)
    armo := wbCopyElementToFile(srcArmo, f, True, True);
    if not Assigned(armo) then begin
      Say('FAIL: copy of the eyeglasses failed'); Exit;
    end;
    SetEditorID(armo, ARMO_EDID);
    SetElementEditValues(armo, 'FULL', ARMO_NAME);
    kwda := ElementBySignature(armo, 'KWDA');
    if not Assigned(kwda) then begin
      Say('  eyeglasses have no KWDA; adding one');
      kwda := Add(armo, 'KWDA', True);
    end;
    Say('  keywords on the Eye before: ' + IntToStr(ElementCount(kwda)));
    el := ElementAssign(kwda, HighInteger, nil, False);
    SetNativeValue(el, FormID(eyekw));
    Say('  keywords on the Eye after: ' + IntToStr(ElementCount(kwda)) + ' (last = ' + GetEditValue(ElementByIndex(kwda, ElementCount(kwda) - 1)) + ')');
    Say('eye item: ' + Name(armo));

    eff2 := ElementAssign(effs, HighInteger, eff, False);
    if (not Assigned(eff2)) or (ElementCount(effs) <> 2) then begin
      Say('FAIL: could not duplicate the perk entry (effects now ' + IntToStr(ElementCount(effs)) + ')'); Exit;
    end;
    fp := ElementByName(eff2, 'Function Parameters');
    SetElementEditValues(fp, 'EPFB - Perk Entry ID (unique)', '12');
    epfd := ElementBySignature(fp, 'EPFD');
    SetEditValue(ElementByIndex(epfd, 0), EYE_MULT);
    Say('eye entry multiplier now: ' + GetEditValue(ElementByIndex(epfd, 0)));
    pcs2 := ElementByName(eff2, 'Perk Conditions');
    pc := ElementByIndex(pcs2, 0);
    pc2 := ElementAssign(pcs2, HighInteger, pc, False);
    SetElementEditValues(pc2, 'PRKC - Run On (Tab Index)', '0');
    conds := ElementByName(pc2, 'Conditions');
    cond := ElementByIndex(conds, 0);
    ctda := ElementBySignature(cond, 'CTDA');
    SetElementEditValues(ctda, 'Function', 'WornHasKeyword');
    SetElementNativeValues(ctda, 'Parameter #1', FormID(eyekw));
    Say('eye condition now: tab ' + GetElementEditValues(pc2, 'PRKC - Run On (Tab Index)') + ' / ' +
        GetElementEditValues(ctda, 'Function') + ' ' + GetElementEditValues(ctda, 'Parameter #1'));
    Say('perk effects: ' + IntToStr(ElementCount(effs)) + ', conditions on entry 2: ' + IntToStr(ElementCount(pcs2)));

    log.Add('');
    log.Add('===== weapon dump');
    Dump(w, '');
    log.Add('');
    log.Add('===== mod dump');
    Dump(oA, '');
    log.Add('');
    log.Add('===== recipe dump');
    Dump(cA, '');
    log.Add('');
    log.Add('===== perk dump');
    Dump(perk, '');
    log.Add('');
    log.Add('===== eye item dump');
    Dump(armo, '');
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
