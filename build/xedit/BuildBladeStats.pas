{
  BuildBladeStats.pas: TEST build, round 4 (stats). Status: RUN AND VERIFIED IN GAME (2026-11-24); results in spec-blade-of-bastet.md ("Round 4 results").

  Design (2026-11-24, from Chris): the Blade is a FAST, light long sword at the tier of the Disciples Blade in its
  Cutlass state (+75% damage, bleed), keeping the long-sword stab animations (NO Anims1hmShortWeapon keyword).
  Numbers come from the vanilla records read in xEdit:
    Chinese Officer Sword: damage 16, weight 3.0, AP 35, swing 1.12s. Disciples Blade: damage 20, weight 1.5, AP 20,
    swing 0.77s (Melee Speed Fast, a weapon-record field). Cutlass mod = AttackDamage MUL+ADD 0.75 -> 35 base.
    Serrated (Chinese sword) = AttackDamage MUL+ADD 0.75 + bleed enchantment (no shock) -> 28 base.
  This build bases a mod on the SERRATED-ONLY mod (no shock) and changes:
    AttackDamage      0.75 + DMG_ADD (0.45)  -> x2.2 -> about 35 base
    AttackActionPointCost  AP_ADD (-0.43)    -> 35 x 0.57 = 20
    Weight            WEIGHT_ADD (-0.33)     -> 3.0 x 0.67 = 2.0
    Speed             SPEED_ADD (0.45)       -> UNTESTED for melee; only on the "speed test" variant
  Plus everything proven in round 3: keyword MoM_Blade_KW, own ENCH -> MGEF -> PERK (30% = multiplier 0.70) and the
  Eye of Ra keyword item with the second perk entry (multiplier 0.0, WornHasKeyword).
  Existing AttackDamage entry is bumped in place (0.75 -> 1.2), not duplicated; the other properties are added.

  Plugin RegaliaStats1.esp (master Fallout4.esm). Two alternative upgrade mods, same recipe (copy of the Serrated
  recipe plus Silver 3, Gold 2, Crystal 2): "Blade of Bastet" (no Speed change) and "Blade of Bastet (speed test)".
  The in-game NAME is still the vanilla naming-rule result ("Serrated ..."): fixing the name is the next step.

  Test in game (only RegaliaStats1.esp ticked from ours; Normal difficulty; dummy, heavy chest):
    1. Plain sword: damage 32 on the dummy unarmored (STR 10), AP 35 in VATS, weight 3.
    2. Blade (no speed): about 70 unarmored (x2.2), AP about 20, weight about 2, chest about 50 (30% ignored). hasperk 1.
    3. Blade (speed test): same, and: does the swing look/feel faster? Count swings in 10 seconds against plain.
    4. Eye on: chest damage equals unarmored.

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildBladeStats.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaStats1 in the filename box. Accept the save prompt when xEdit closes. Run it ONCE.
  Log: our-scripts\build.log.
}
unit BuildBladeStats;

const
  PLUGIN_HINT = 'RegaliaStats1';
  DMG_ADD = 0.45;
  AP_ADD = -0.43;
  WEIGHT_ADD = -0.33;
  SPEED_ADD = 0.45;
  BLADE_MULT = '0.7';
  EYE_MULT = '0.0';
  KW_EDID = 'MoM_Blade_KW';
  EYEKW_EDID = 'MoM_EyeOfRa_KW';
  OMOD_EDID = 'MoM_OMOD_Blade';
  OMODS_EDID = 'MoM_OMOD_BladeSpeed';
  COBJ_EDID = 'MoM_COBJ_Blade';
  COBJS_EDID = 'MoM_COBJ_BladeSpeed';
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

function MakeKeyword(g: IInterface; edid: string): IInterface;
begin
  Result := Add(g, 'KYWD', True);
  if Assigned(Result) then SetEditorID(Result, edid);
end;

// One Blade mod: copy of the Serrated-only mod + our keyword + our enchantment + the stat changes.
function MakeBladeMod(f, srcOmod, kw, ench: IInterface; edid, title, desc: string; withSpeed: boolean): IInterface;
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
  if withSpeed then
    if not BumpFloatProp(o, 'Speed', SPEED_ADD) then Exit;
  Result := o;
end;

function Initialize: integer;
var
  esm, srcOmod, srcCobj, srcPerk, srcEnch, srcMgef, srcArmo: IInterface;
  f, g, kw, eyekw, oA, oB, cA, cB, perk, mgef, ench, armo: IInterface;
  effs, eff, eff2, fp, epfd, pcs, pcs2, pc, pc2, conds, cond, ctda, mdata, ees, kwda, el: IInterface;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    srcOmod := RecordByFormID(esm, $00176DF9, True);   // mod_melee_ChineseOfficerSword_Serrated "Serrated Blade"
    srcCobj := RecordByFormID(esm, $00187835, True);   // co_mod_ChineseOfficerSword_Serrated
    srcPerk := RecordByFormID(esm, $00056DD7, True);   // PlayerPerk
    srcEnch := RecordByFormID(esm, $001F4425, True);   // enchModArmorPenetration
    srcMgef := RecordByFormID(esm, $001F4423, True);   // ModArmorPenetrationAddPerkEffect
    srcArmo := RecordByFormID(esm, $001C4BE8, True);   // ClothesEyeGlasses
    if (not Assigned(srcOmod)) or (not Assigned(srcCobj)) or (not Assigned(srcPerk)) or
       (not Assigned(srcEnch)) or (not Assigned(srcMgef)) or (not Assigned(srcArmo)) then begin
      Say('FAIL: source records not found (Serrated OMOD 00176DF9 / COBJ 00187835)'); Exit;
    end;
    Say('sources: ' + Name(srcOmod) + ' | ' + Name(srcCobj) + ' | ' + Name(srcPerk) + ' | ' + Name(srcEnch) + ' | ' + Name(srcMgef) + ' | ' + Name(srcArmo));

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
      'TEST BUILD 4. Lighter, cheaper in VATS, stronger; ignores part of the target''s armor.', False);
    if not Assigned(oA) then Exit;
    Say('mod: ' + Name(oA));
    oB := MakeBladeMod(f, srcOmod, kw, ench, OMODS_EDID, 'Blade of Bastet (speed test)',
      'TEST BUILD 4. As the Blade, plus a Speed bump (untested for melee).', True);
    if not Assigned(oB) then Exit;
    Say('mod: ' + Name(oB));
    cA := MakeRecipe(f, srcCobj, oA, COBJ_EDID);
    cB := MakeRecipe(f, srcCobj, oB, COBJS_EDID);
    Say('recipes: ' + Name(cA) + ' | ' + Name(cB));

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
    log.Add('===== mod (no speed) dump');
    Dump(oA, '');
    log.Add('');
    log.Add('===== mod (speed test) dump');
    Dump(oB, '');
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
