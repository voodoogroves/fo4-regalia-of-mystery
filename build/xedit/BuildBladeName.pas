{
  BuildBladeName.pas: TEST build, round 5 (the NAME). Status: WRITTEN, NOT YET RUN (2026-11-24).

  Decision (Chris, 2026-11-24): keep the Upgrade-mod Blade at MEDIUM speed with cheaper VATS (the Speed property did
  nothing for melee). Round 4 showed the in-game name is still "Serrated": the sword's naming record dn_CommonMelee
  (INNR 000B9738) maps keyword dn_HasMeleeMod_Serrated to the text "Serrated". Rules are text + keywords + index, the
  last rule "*" is the base item name (index 10000), so a rule can only add words around the base name.

  This build is round 4's Blade (same stats: AttackDamage 0.75 -> 1.2, AttackActionPointCost -0.43, Weight -0.33, bleed,
  our keyword and ENCH/MGEF/PERK chain, the Eye) with only these differences:
    1. the Speed variant is gone (one mod, one recipe);
    2. the mod no longer carries the keyword dn_HasMeleeMod_Serrated (it only feeds the name; the bleed comes from the
       enchantment), so "Serrated" should disappear from the name;
    3. an OVERRIDE of dn_CommonMelee (INNR 000B9738) with one added rule: keyword MoM_Blade_KW -> text NAME_TEXT at
       index NAME_INDEX (10001, after the base name at 10000). Hoped result: "Chinese Officer Sword of Bastet".
       Constants at the top. Cost: an override of a shared vanilla record (another mod that also edits it conflicts).

  Plugin RegaliaName1.esp (master Fallout4.esm).

  Test in game (only RegaliaName1.esp ticked from ours): craft or spawn the Blade, put it on a sword, read its name in
  the Pip-Boy and in the world/inventory list. Possible outcomes: "Chinese Officer Sword of Bastet" (good), the text
  in front instead, a missing space, or no rule applied at all; tell me exactly what it shows. Also check that bleed
  still applies (the mod's description says so) and the stats are unchanged (damage about 70, weight 2).

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildBladeName.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaName1 in the filename box. Accept the save prompt when xEdit closes. Run it ONCE.
  Log: our-scripts\build.log.
}
unit BuildBladeName;

const
  PLUGIN_HINT = 'RegaliaName1';
  NAME_TEXT = 'of Bastet';
  NAME_INDEX = '10001';
  DMG_ADD = 0.45;
  AP_ADD = -0.43;
  WEIGHT_ADD = -0.33;
  BLADE_MULT = '0.7';
  EYE_MULT = '0.0';
  KW_EDID = 'MoM_Blade_KW';
  EYEKW_EDID = 'MoM_EyeOfRa_KW';
  OMOD_EDID = 'MoM_OMOD_Blade';
  COBJ_EDID = 'MoM_COBJ_Blade';
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

// Override the naming record and add one rule: keyword kw -> NAME_TEXT at NAME_INDEX.
function AddNameRule(f, srcInnr, kw: IInterface): IInterface;
var
  inn, rules, rs, names, tmpl, nw, kwda: IInterface;
  n: integer;
begin
  Result := nil;
  inn := wbCopyElementToFile(srcInnr, f, False, True);
  if not Assigned(inn) then begin
    Say('FAIL: override of the naming record failed'); Exit;
  end;
  rules := ElementByName(inn, 'Naming Rules');
  if not Assigned(rules) then begin
    Say('FAIL: no Naming Rules element'); Exit;
  end;
  rs := ElementByIndex(rules, 0);
  names := ElementByName(rs, 'Names');
  if not Assigned(names) then begin
    Say('FAIL: no Names element in ruleset 0'); Exit;
  end;
  n := ElementCount(names);
  Say('  naming rules before: ' + IntToStr(n) + ' (VNAM ' + GetElementEditValues(rs, 'VNAM - Count') + ')');
  tmpl := ElementByIndex(names, n - 2);   // a keyworded rule (the last one, "*", has no keywords)
  if not Assigned(ElementBySignature(tmpl, 'KWDA')) then begin
    Say('FAIL: template rule has no keywords: ' + GetElementEditValues(tmpl, 'WNAM - Text')); Exit;
  end;
  nw := ElementAssign(names, HighInteger, tmpl, False);
  SetElementEditValues(nw, 'WNAM - Text', NAME_TEXT);
  kwda := ElementBySignature(nw, 'KWDA');
  SetNativeValue(ElementByIndex(kwda, 0), FormID(kw));
  SetElementEditValues(nw, 'YNAM - Index', NAME_INDEX);
  SetElementNativeValues(rs, 'VNAM - Count', ElementCount(names));
  Say('  naming rules after: ' + IntToStr(ElementCount(names)) + ' (VNAM ' + GetElementEditValues(rs, 'VNAM - Count') + ')');
  Say('  new rule: ' + GetElementEditValues(nw, 'WNAM - Text') + ' | keyword ' + GetEditValue(ElementByIndex(kwda, 0)) + ' | index ' + GetElementEditValues(nw, 'YNAM - Index'));
  Result := inn;
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
  esm, srcOmod, srcCobj, srcPerk, srcEnch, srcMgef, srcArmo, srcInnr, innr: IInterface;
  f, g, kw, eyekw, oA, cA, perk, mgef, ench, armo: IInterface;
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
    srcInnr := RecordByFormID(esm, $000B9738, True);   // dn_CommonMelee
    if (not Assigned(srcOmod)) or (not Assigned(srcCobj)) or (not Assigned(srcPerk)) or
       (not Assigned(srcEnch)) or (not Assigned(srcMgef)) or (not Assigned(srcArmo)) or (not Assigned(srcInnr)) then begin
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
      'TEST BUILD 5. Lighter, cheaper in VATS, stronger; targets bleed; ignores part of the target''s armor.');
    if not Assigned(oA) then Exit;
    Say('mod: ' + Name(oA));
    cA := MakeRecipe(f, srcCobj, oA, COBJ_EDID);
    Say('recipe: ' + Name(cA));

    // the name rule (override of dn_CommonMelee)
    innr := AddNameRule(f, srcInnr, kw);
    if not Assigned(innr) then Exit;
    Say('naming record: ' + Name(innr));

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
    log.Add('');
    log.Add('===== naming record: last rules only');
    Dump(ElementByIndex(ElementByName(ElementByIndex(ElementByName(innr, 'Naming Rules'), 0), 'Names'), ElementCount(ElementByName(ElementByIndex(ElementByName(innr, 'Naming Rules'), 0), 'Names')) - 1), '');
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
