{
  BuildBladePerk2.pas: TEST build, round 3. Status: RUN AND VERIFIED IN GAME (2026-11-24); results in spec-blade-of-bastet.md ("Round 3 results").

  Findings it builds on (2026-11-24, in game, Test profile, SKK dummy, Normal):
    - Mod B (vanilla trio on an Upgrade mod): getav ArmorPenetration 30, hasperk 001F4166 1; heavy chest 32 -> 18.
    - Mod A (our keyword + our perk added by console, multiplier 0.0): damage identical vs unarmored, heavy chest
      and full combat armor, i.e. ALL armor ignored. The HasKeyword perk entry works.
  What this build tests:
    1. DELIVERY WITHOUT CONSOLE: mod A also carries OUR enchantment -> OUR magic effect (Add Perk archetype, copied from
       the vanilla chain 001F4425 -> 001F4423) -> OUR perk, so equipping the sword grants the perk (no player.addperk).
    2. The REAL STRENGTH: the Blade entry multiplier is 0.70 (30% ignored). Expect the heavy chest to read about 18 to
       20 (mod B read 18).
    3. EYE OF RA: a second perk entry, multiplier 0.0, with two conditions: weapon HasKeyword MoM_Blade_KW (tab 1) AND
       attacker WornHasKeyword MoM_EyeOfRa_KW (tab 0). Multipliers stack, so Blade alone = 0.70, Blade + Eye = 0.70 x 0.0
       = 100% ignored, Eye alone = nothing. The Eye is a copy of ClothesEyeGlasses (ARMO 001C4BE8) with our keyword added;
       no enchantment, no script. Get it with: help "Eye of Ra" 4 ARMO, then player.additem <ID> 1.
    The Eye steps are LAST so that a failure there still leaves the chain test intact (the plugin is saved on close).

  Plugin RegaliaPerkTest3.esp (master Fallout4.esm):
    KYWD MoM_Blade_KW, KYWD MoM_EyeOfRa_KW
    PERK MoM_PERK_Blade  (two entries, see above)
    MGEF MoM_MGEF_BladePerk (copy of 001F4423, Perk to Apply -> our perk)
    ENCH MoM_ENCH_Blade     (copy of 001F4425, effect -> our MGEF)
    OMOD MoM_OMOD_Blade     (copy of Electrified Serrated Blade 0014A0F1, + keyword, + our enchantment)
    COBJ MoM_COBJ_Blade     (copy of 0014A13B + Silver 3, Gold 2, Crystal 2; weapon workbench; Blacksmith 3, Science 1)
    ARMO MoM_ARMO_EyeOfRa   (copy of ClothesEyeGlasses, + keyword)

  Test in game (ONLY RegaliaPerkTest3.esp ticked from ours; Normal difficulty; dummy in the heavy combat chest):
    A. Put the Blade mod on a sword and equip it. player.hasperk <perk ID> (find: help "Bastet" 4 PERK) expect 1 with
       no addperk; unequip, expect 0. Heavy chest: plain 15, expect about 18 to 20.
    B. Wear the Eye (player.additem). Heavy chest should now equal the unarmored number (all armor ignored).
    C. Take the Eye off: back to about 18 to 20. Eye with a plain sword: 15.

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildBladePerk2.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaPerkTest3 in the filename box. Accept the save prompt when xEdit closes. Run it ONCE.
  Log: our-scripts\build.log (step by step, with dumps of all new records).
}
unit BuildBladePerk2;

const
  PLUGIN_HINT = 'RegaliaPerkTest3';
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

// Make a new keyword record in the file's KYWD group.
function MakeKeyword(g: IInterface; edid: string): IInterface;
begin
  Result := Add(g, 'KYWD', True);
  if Assigned(Result) then SetEditorID(Result, edid);
end;

function Initialize: integer;
var
  esm, srcOmod, srcCobj, srcPerk, srcEnch, srcMgef, srcArmo: IInterface;
  f, g, kw, eyekw, oA, cA, perk, mgef, ench, armo: IInterface;
  effs, eff, eff2, fp, epfd, pcs, pcs2, pc, pc2, conds, cond, ctda, mdata, ees, kwda, el: IInterface;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    srcOmod := RecordByFormID(esm, $0014A0F1, True);   // mod_melee_ChineseOfficerSword_ShockAndSerrated
    srcCobj := RecordByFormID(esm, $0014A13B, True);   // co_mod_melee_ChineseOfficerSword_ShockAndSerrated
    srcPerk := RecordByFormID(esm, $00056DD7, True);   // PlayerPerk
    srcEnch := RecordByFormID(esm, $001F4425, True);   // enchModArmorPenetration
    srcMgef := RecordByFormID(esm, $001F4423, True);   // ModArmorPenetrationAddPerkEffect
    srcArmo := RecordByFormID(esm, $001C4BE8, True);   // ClothesEyeGlasses
    if (not Assigned(srcOmod)) or (not Assigned(srcCobj)) or (not Assigned(srcPerk)) or
       (not Assigned(srcEnch)) or (not Assigned(srcMgef)) or (not Assigned(srcArmo)) then begin
      Say('FAIL: source records not found'); Exit;
    end;
    Say('sources: ' + Name(srcOmod) + ' | ' + Name(srcPerk) + ' | ' + Name(srcEnch) + ' | ' + Name(srcMgef) + ' | ' + Name(srcArmo));

    Say('Type ' + PLUGIN_HINT + ' in the filename box.');
    f := AddNewFile;
    if not Assigned(f) then begin
      Say('FAIL: no file created (cancelled, or the name already exists in Data?)'); Exit;
    end;
    Say('new file: ' + GetFileName(f));
    AddMasterIfMissing(f, 'Fallout4.esm');

    // 1. keywords
    g := Add(f, 'KYWD', True);
    kw := MakeKeyword(g, KW_EDID);
    eyekw := MakeKeyword(g, EYEKW_EDID);
    if (not Assigned(kw)) or (not Assigned(eyekw)) then begin
      Say('FAIL: could not create the keywords'); Exit;
    end;
    Say('keywords: ' + Name(kw) + ' | ' + Name(eyekw));

    // 2. our perk (needed first: the magic effect points at it). Copy PlayerPerk, keep its first effect only.
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

    // 3. magic effect: copy the vanilla Add Perk effect and point it at our perk
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
    Say('magic effect perk now: ' + GetElementEditValues(mdata, 'Perk to Apply') + ' | archetype ' + GetElementEditValues(mdata, 'Archetype'));

    // 4. enchantment: copy the vanilla one and point its effect at our magic effect
    ench := wbCopyElementToFile(srcEnch, f, True, True);
    if not Assigned(ench) then begin
      Say('FAIL: copy of the enchantment failed'); Exit;
    end;
    SetEditorID(ench, ENCH_EDID);
    ees := ElementByName(ench, 'Effects');
    el := ElementByIndex(ees, 0);
    SetElementNativeValues(el, 'EFID - Base Effect', FormID(mgef));
    Say('enchantment effect now: ' + GetElementEditValues(el, 'EFID - Base Effect'));

    // 5. mod: Electrified Serrated + our keyword + our enchantment
    oA := wbCopyElementToFile(srcOmod, f, True, True);
    if not Assigned(oA) then begin
      Say('FAIL: copy of the Electrified Serrated mod failed'); Exit;
    end;
    SetEditorID(oA, OMOD_EDID);
    SetElementEditValues(oA, 'FULL', 'Blade of Bastet');
    SetElementEditValues(oA, 'DESC', 'TEST BUILD 3. Grants the Bastet test perk while equipped.');
    if not AddModProp(oA, 'FormID,Int', 'ADD', 'Keywords', FormID(kw), '440') then Exit;
    if not AddModProp(oA, 'FormID,Int', 'ADD', 'Enchantments', FormID(ench), '440') then Exit;
    Say('mod: ' + Name(oA));
    cA := MakeRecipe(f, srcCobj, oA, COBJ_EDID);
    Say('recipe: ' + Name(cA));

    // 6. EYE OF RA (last, so a failure here leaves the chain test intact).
    //    Item: copy of the Eyeglasses with our keyword.
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

    //    Perk entry 2: copy entry 1, multiplier 0.0, entry ID 12, plus an attacker-tab WornHasKeyword condition.
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
    log.Add('===== keywords dump');
    Dump(kw, ''); Dump(eyekw, '');
    log.Add('');
    log.Add('===== perk dump');
    Dump(perk, '');
    log.Add('');
    log.Add('===== magic effect dump');
    Dump(mgef, '');
    log.Add('');
    log.Add('===== enchantment dump');
    Dump(ench, '');
    log.Add('');
    log.Add('===== mod dump');
    Dump(oA, '');
    log.Add('');
    log.Add('===== recipe dump');
    Dump(cA, '');
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
