{
  BuildGarb.pas: round 17, the REAL Garb of Mysteries (not a look test). Status: VERIFIED in game (2026-11-24).

  Design (spec/spec-garb-of-mysteries.md; Chris's decisions 2026-11-24): light armor (the dress should take ballistic weave), weighted to sneak and utility;
  NO upgrade ladder; the Eye of Ra amplifies ONLY the sneaking effects (no DR/ER boost).
    DR 20, ER 20 (fixed); value 50, weight 1.0; +1 Perception; +5 sneaking speed (while sneaking); harder to detect while sneaking: Mod Detection
    Sneak Skill +5, +20 more with the Eye (total +25); sneak attack: small bonus (melee 1H +0.25, other +0.125), more with the Eye (+0.75 and +0.375, so
    totals 1.0 and 0.5 = Ninja rank 1).
  Vanilla anchors, read from the records 2026-11-24: Sneak01 (PERK 0004C935) uses Mod Detection Sneak Skill Add 20 and Mod Detection Movement x0.9 ("20%
  harder to detect"); Ninja01 (0004D8A6) uses Mod Sneak Attack Mult Add 1.0 (melee 1H) and 0.5 (other); Stealth Move (ENCH 00245BDE) is Fortify Actor Speed
  Mult 5 with the condition IsSneaking; Fortify Perception (ENCH 00192193) is AbFortifyPerception magnitude 1.

  What it builds (plugin RegaliaGarb2.esp; masters Fallout4.esm and RegaliaGold1.esp, which supplies the Eye of Ra keyword MoM_EyeOfRa_KW):
    MSWP MoM_MSWP_GarbStripes   Clothes\\SlinkyDress\\SequinDress.BGSM -> Clothes\\GarbOfMysteries\\GarbOfMysteries.BGSM (the art mod, verified)
    ARMA MoM_ARMA_Garb          copy of AAClothesSequinDress with MO2S and MO3S = that swap
    PERK MoM_PERK_Garb          a copy of Sneak01 (hidden, one rank, requirement and next-rank link removed) with six entries: sneak skill +5; sneak skill
                                +20 if the Eye is worn; sneak attack melee +0.25 and other +0.125; the same +0.75 and +0.375 if the Eye is worn
    MGEF MoM_MGEF_GarbPerk      copy of 001F4423 (Add Perk), Perk to Apply = our perk
    ENCH MoM_ENCH_Garb          copy of Fortify Perception (+1) plus two effects copied from vanilla: our Add Perk effect, and Stealth Move (speed +5, IsSneaking)
    ARMO MoM_ARMO_Garb          "Garb of Mysteries": copy of the Sequin Dress (0011A27B) with our armature and enchantment, Armor Rating 20, Energy resistance 20
  (the dress's vanilla Fortify Charisma is replaced by our enchantment.)
  SLOTS (added 2026-11-24, Chris): the dress is treated like UNDERARMOR: body slot 33 plus the [U] slots 36 to 40, no armor-piece slots 41 to 45, so chest and leg armor can be worn over it.

  IN THE MODULE LIST tick Fallout4.esm, ALL SIX DLC, AND RegaliaGold1.esp (it needs Nuka-World). Then OK.

  Test in game (only RegaliaGarb2.esp and RegaliaGold1.esp ticked from ours; "Garb of Mysteries Art" and the ballistic weave mod enabled):
    1. help "Garb of Mysteries" 4 ARMO, player.additem <ID> 1, equip. The look is the verified striped dress. Name and description; the Pip-Boy shows DR 20 and ER 20,
       weight 1, value 50, Perception +1, and a sneaking-speed effect.
    2. help "Garb of Mysteries" 4 PERK, then player.hasperk <ID>: 1 while the dress is worn, 0 when not.
    3. At an ARMOR WORKBENCH: is ballistic weave offered on the Garb? (If not: raise DR and ER, see the spec.)
    4. The Eye amplifier: craft or spawn the Jury-Rigged Eye (RegaliaGold1) and wear both; the perk stays (hasperk 1). Sneak attack with the Blade on the dummy,
       Garb off, Garb on, Garb and Eye on: the damage should step up a little, then more.
    5. Anything odd: the dress looking different, a missing effect, an error at equip.

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildGarb.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaGarb2 in the filename box. Accept the save prompt when xEdit closes. Run it ONCE.
  Log: our-scripts\build.log.
}
unit BuildGarb;

const
  PLUGIN_HINT = 'RegaliaGarb2';
  EYE_PLUGIN = 'RegaliaGold1.esp';
  EYE_KW_EDID = 'MoM_EyeOfRa_KW';
  MSWP_EDID = 'MoM_MSWP_GarbStripes';
  MAT_ORIGINAL = 'Clothes\SlinkyDress\SequinDress.BGSM';
  MAT_REPLACEMENT = 'Clothes\GarbOfMysteries\GarbOfMysteries.BGSM';
  ARMA_EDID = 'MoM_ARMA_Garb';
  ARMO_EDID = 'MoM_ARMO_Garb';
  ARMO_NAME = 'Garb of Mysteries';
  ARMO_DESC = 'A sequined dress in charcoal, edged in emerald and cream-gold, cut for quiet work. Light on protection and easy on other people''s attention: you are harder to notice while sneaking and your steps fall softer. Worn with the Eye of Ra, you slip past nearly everyone.';
  PERK_EDID = 'MoM_PERK_Garb';
  PERK_NAME = 'Garb of Mysteries';
  PERK_DESC = 'Harder to detect while sneaking, and sneak attacks hit harder.';
  MGEF_EDID = 'MoM_MGEF_GarbPerk';
  ENCH_EDID = 'MoM_ENCH_Garb';
  ENCH_NAME = 'Garb of Mysteries';
  DR_VALUE = 20;
  ER_VALUE = 20;
  ARMO_VALUE = 50;
  ARMO_WEIGHT = 1.0;
  SKILL_BASE = '5.0';
  SKILL_EYE = '20.0';
  MELEE_BASE = '0.25';
  MELEE_EYE = '0.75';
  OTHER_BASE = '0.125';
  OTHER_EYE = '0.375';
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
  if (Pos('Model Information', n) > 0) or (Pos('Sculpt Data', n) > 0) then
    log.Add(indent + n + ' = (skipped)')
  else begin
    log.Add(indent + n + ' = ' + GetEditValue(e));
    for i := 0 to ElementCount(e) - 1 do
      Dump(ElementByIndex(e, i), indent + '  ');
  end;
end;

function FindFile(fname: string): IInterface;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to FileCount - 1 do
    if LowerCase(GetFileName(FileByIndex(i))) = LowerCase(fname) then begin
      Result := FileByIndex(i); Exit;
    end;
end;

function MakeMaterialSwap(f: IInterface): IInterface;
var
  g, r, subs, sub: IInterface;
begin
  Result := nil;
  g := Add(f, 'MSWP', True);
  r := Add(g, 'MSWP', True);
  if not Assigned(r) then begin
    Say('FAIL: could not create the material swap record'); Exit;
  end;
  SetEditorID(r, MSWP_EDID);
  subs := Add(r, 'Material Substitutions', True);
  if not Assigned(subs) then begin
    Say('FAIL: could not create Material Substitutions on the swap'); Exit;
  end;
  if ElementCount(subs) = 0 then sub := ElementAssign(subs, HighInteger, nil, False)
  else sub := ElementByIndex(subs, 0);
  SetElementEditValues(sub, 'BNAM - Original Material', MAT_ORIGINAL);
  SetElementEditValues(sub, 'SNAM - Replacement Material', MAT_REPLACEMENT);
  Say('  material swap: ' + GetElementEditValues(sub, 'BNAM - Original Material') + '  ->  ' + GetElementEditValues(sub, 'SNAM - Replacement Material'));
  Result := r;
end;

function SetSwap(arma: IInterface; container, sig: string; mswp: IInterface): boolean;
var
  m, ms: IInterface;
begin
  Result := False;
  m := ElementByName(arma, container);
  if not Assigned(m) then begin
    Say('FAIL: no "' + container + '" block on the addon'); Exit;
  end;
  ms := ElementBySignature(m, sig);
  if not Assigned(ms) then ms := Add(m, sig, True);
  if not Assigned(ms) then begin
    Say('FAIL: could not add ' + sig + ' to "' + container + '"'); Exit;
  end;
  SetNativeValue(ms, FormID(mswp));
  Say('  ' + container + ' / ' + sig + ' now: ' + GetEditValue(ms));
  Result := True;
end;

// Point the tab-0 (attacker) condition of a perk entry at a function and a parameter, with a comparison value.
function SetTab0Condition(f, eff: IInterface; funcName: string; param: IInterface; cmp: double): boolean;
var
  pcs, pc, conds, cond, ctda: IInterface;
  i, raw: integer;
begin
  Result := False;
  pcs := ElementByName(eff, 'Perk Conditions');
  if not Assigned(pcs) then begin
    Say('FAIL: no Perk Conditions on an entry'); Exit;
  end;
  for i := 0 to ElementCount(pcs) - 1 do begin
    pc := ElementByIndex(pcs, i);
    if GetElementNativeValues(pc, 'PRKC - Run On (Tab Index)') = 0 then begin
      conds := ElementByName(pc, 'Conditions');
      cond := ElementByIndex(conds, 0);
      ctda := ElementBySignature(cond, 'CTDA');
      if not Assigned(ctda) then begin
        Say('FAIL: no CTDA in the tab 0 condition'); Exit;
      end;
      SetElementEditValues(ctda, 'Function', funcName);
      // FormID(e) is in the numbering of the file the record LIVES in (for a record of another plugin it would be misread as one of ours). A record from ANOTHER plugin must be converted: its LOAD-ORDER id into THIS file's numbering, or it is read as one of our own
      // records (the first run wrote the Eye keyword as our magic effect). A record of THIS file already has the file's own numbering: do not convert it
      // (converting it raised "Load order FileID [02] can not be mapped", 2026-11-24).
      if GetFileName(GetFile(param)) = GetFileName(f) then raw := FormID(param)
      else raw := LoadOrderFormIDtoFileFormID(f, GetLoadOrderFormID(param));   // FormID() is local to the record's OWN file; the conversion needs the LOAD-ORDER id
      SetElementNativeValues(ctda, 'Parameter #1', raw);
      SetElementNativeValues(ctda, 'Comparison Value', cmp);
      Say('    condition written: ' + GetElementEditValues(ctda, 'Function') + ' ' + GetElementEditValues(ctda, 'Parameter #1'));
      Result := True; Exit;
    end;
  end;
  Say('FAIL: no tab 0 perk condition found on an entry');
end;

// Copy a perk entry into effs, set its value, entry ID and tab 0 condition. eye = True: needs the Eye worn; False: needs our perk (always true while worn).
function AddEntry(f, effs, srcEff: IInterface; valueStr: string; entryId: integer; eye: boolean; perk, eyekw: IInterface): IInterface;
var
  e, fp, epfd: IInterface;
  ok: boolean;
begin
  Result := nil;
  e := ElementAssign(effs, HighInteger, srcEff, False);
  if not Assigned(e) then begin
    Say('FAIL: could not copy a perk entry'); Exit;
  end;
  fp := ElementByName(e, 'Function Parameters');
  SetElementEditValues(fp, 'EPFB - Perk Entry ID (unique)', IntToStr(entryId));
  epfd := ElementBySignature(fp, 'EPFD');
  SetEditValue(ElementByIndex(epfd, 0), valueStr);
  if eye then ok := SetTab0Condition(f, e, 'WornHasKeyword', eyekw, 1)
  else ok := SetTab0Condition(f, e, 'HasPerk', perk, 1);
  if not ok then Exit;
  Say('  entry ' + IntToStr(entryId) + ': ' + GetElementEditValues(ElementByName(e, 'DATA - Effect Data'), 'Entry Point\Entry Point') + ' value ' + GetEditValue(ElementByIndex(epfd, 0)) + ' (eye ' + IntToStr(Ord(eye)) + ')');
  Result := e;
end;

function Initialize: integer;
var
  esm, gold, srcArmo, srcArma, srcEnchPerc, srcEnchStealth, srcEnchAP, srcMgefAP, srcPerkSneak, srcPerkNinja: IInterface;
  eyekw, f, mswp, arma, armo, perk, mgef, ench, effs, base, ee, srcN, n0, n1, data, models, m0, el, ees, dama, res, newEff, conds: IInterface;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    srcArmo := RecordByFormID(esm, $0011A27B, True);        // ClothesSequinDress
    srcArma := RecordByFormID(esm, $0011A27A, True);        // AAClothesSequinDress
    srcEnchPerc := RecordByFormID(esm, $00192193, True);    // EnchClothingPerception (Fortify Perception +1)
    srcEnchStealth := RecordByFormID(esm, $00245BDE, True); // enchArmorStealthMoveMod
    srcEnchAP := RecordByFormID(esm, $001F4425, True);      // enchModArmorPenetration (an Add Perk enchantment)
    srcMgefAP := RecordByFormID(esm, $001F4423, True);      // ModArmorPenetrationAddPerkEffect (the Add Perk effect)
    srcPerkSneak := RecordByFormID(esm, $0004C935, True);   // Sneak01
    srcPerkNinja := RecordByFormID(esm, $0004D8A6, True);   // Ninja01
    if (not Assigned(srcArmo)) or (not Assigned(srcArma)) or (not Assigned(srcEnchPerc)) or (not Assigned(srcEnchStealth)) or
       (not Assigned(srcEnchAP)) or (not Assigned(srcMgefAP)) or (not Assigned(srcPerkSneak)) or (not Assigned(srcPerkNinja)) then begin
      Say('FAIL: a vanilla source record was not found'); Exit;
    end;
    gold := FindFile(EYE_PLUGIN);
    if not Assigned(gold) then begin
      Say('FAIL: ' + EYE_PLUGIN + ' is not loaded: tick it (and Nuka-World and the other DLC) in the module list'); Exit;
    end;
    eyekw := MainRecordByEditorID(GroupBySignature(gold, 'KYWD'), EYE_KW_EDID);
    if not Assigned(eyekw) then begin
      Say('FAIL: keyword ' + EYE_KW_EDID + ' not found in ' + EYE_PLUGIN); Exit;
    end;
    Say('sources ok; Eye keyword: ' + Name(eyekw));

    Say('Type ' + PLUGIN_HINT + ' in the filename box.');
    f := AddNewFile;
    if not Assigned(f) then begin
      Say('FAIL: no file created (cancelled, or the name already exists in Data?)'); Exit;
    end;
    Say('new file: ' + GetFileName(f));
    AddMasterIfMissing(f, 'Fallout4.esm');
    AddMasterIfMissing(f, EYE_PLUGIN);

    // ---- the perk ----
    perk := wbCopyElementToFile(srcPerkSneak, f, True, True);
    if not Assigned(perk) then begin
      Say('FAIL: copy of the Sneak perk failed'); Exit;
    end;
    SetEditorID(perk, PERK_EDID);
    SetElementEditValues(perk, 'FULL', PERK_NAME);
    SetElementEditValues(perk, 'DESC', PERK_DESC);
    data := ElementBySignature(perk, 'DATA');
    SetElementNativeValues(data, 'Num Ranks', 1);
    SetElementNativeValues(data, 'Playable', 0);
    SetElementNativeValues(data, 'Hidden', 1);
    el := ElementByName(perk, 'Conditions');
    if Assigned(el) then Remove(el);
    el := ElementBySignature(perk, 'NNAM');
    if Assigned(el) then Remove(el);
    effs := ElementByName(perk, 'Effects');
    Say('perk effects as copied: ' + IntToStr(ElementCount(effs)) + ' (expect 2: movement x0.9, sneak skill +20)');
    if ElementCount(effs) <> 2 then begin
      Say('FAIL: expected 2 entries on the copied Sneak perk'); Exit;
    end;
    Remove(ElementByIndex(effs, 0));          // drop Mod Detection Movement x0.9; keep Mod Detection Sneak Skill
    base := ElementByIndex(effs, 0);
    ee := ElementByName(base, 'Function Parameters');
    SetElementEditValues(ee, 'EPFB - Perk Entry ID (unique)', '0');
    SetEditValue(ElementByIndex(ElementBySignature(ee, 'EPFD'), 0), SKILL_BASE);
    if not SetTab0Condition(f, base, 'HasPerk', perk, 1) then Exit;
    Say('  entry 0: sneak skill base ' + SKILL_BASE);
    if not Assigned(AddEntry(f, effs, base, SKILL_EYE, 1, True, perk, eyekw)) then Exit;
    srcN := ElementByName(srcPerkNinja, 'Effects');
    n0 := ElementByIndex(srcN, 0);            // melee 1H
    n1 := ElementByIndex(srcN, 1);            // other weapons
    if not Assigned(AddEntry(f, effs, n0, MELEE_BASE, 2, False, perk, eyekw)) then Exit;
    if not Assigned(AddEntry(f, effs, n1, OTHER_BASE, 3, False, perk, eyekw)) then Exit;
    if not Assigned(AddEntry(f, effs, n0, MELEE_EYE, 4, True, perk, eyekw)) then Exit;
    if not Assigned(AddEntry(f, effs, n1, OTHER_EYE, 5, True, perk, eyekw)) then Exit;
    Say('perk: ' + Name(perk) + ' with ' + IntToStr(ElementCount(effs)) + ' entries');

    // ---- the Add Perk effect and the enchantment ----
    mgef := wbCopyElementToFile(srcMgefAP, f, True, True);
    if not Assigned(mgef) then begin
      Say('FAIL: copy of the Add Perk effect failed'); Exit;
    end;
    SetEditorID(mgef, MGEF_EDID);
    SetElementEditValues(mgef, 'FULL', MGEF_EDID);
    el := ElementByPath(mgef, 'Magic Effect Data\DATA - Data');
    if not Assigned(el) then begin
      Say('FAIL: no Magic Effect Data\DATA - Data on the effect copy'); Exit;
    end;
    SetElementNativeValues(el, 'Perk to Apply', FormID(perk));
    Say('effect: ' + Name(mgef) + ' -> perk ' + GetElementEditValues(el, 'Perk to Apply'));

    ench := wbCopyElementToFile(srcEnchPerc, f, True, True);
    if not Assigned(ench) then begin
      Say('FAIL: copy of Fortify Perception failed'); Exit;
    end;
    SetEditorID(ench, ENCH_EDID);
    SetElementEditValues(ench, 'FULL', ENCH_NAME);
    ees := ElementByName(ench, 'Effects');
    Say('enchantment effects as copied: ' + IntToStr(ElementCount(ees)) + ' (expect 1: Fortify Perception 1)');
    newEff := ElementAssign(ees, HighInteger, ElementByIndex(ElementByName(srcEnchAP, 'Effects'), 0), False);
    if not Assigned(newEff) then begin
      Say('FAIL: could not add the Add Perk effect to the enchantment'); Exit;
    end;
    SetElementNativeValues(newEff, 'EFID - Base Effect', FormID(mgef));
    Say('  effect 2: ' + GetElementEditValues(newEff, 'EFID - Base Effect'));
    newEff := ElementAssign(ees, HighInteger, ElementByIndex(ElementByName(srcEnchStealth, 'Effects'), 0), False);
    if not Assigned(newEff) then begin
      Say('FAIL: could not add the Stealth Move effect to the enchantment'); Exit;
    end;
    conds := ElementByName(newEff, 'Conditions');
    Say('  effect 3: ' + GetElementEditValues(newEff, 'EFID - Base Effect') + ' with ' + IntToStr(ElementCount(conds)) + ' conditions as copied (expect 2: IsSneaking, GetValue)');
    if ElementCount(conds) = 2 then Remove(ElementByIndex(conds, 1));
    Say('  effect 3 conditions now: ' + IntToStr(ElementCount(conds)) + ' (expect 1: IsSneaking)');
    Say('enchantment: ' + Name(ench) + ' with ' + IntToStr(ElementCount(ees)) + ' effects');

    // ---- the look ----
    mswp := MakeMaterialSwap(f);
    if not Assigned(mswp) then Exit;
    arma := wbCopyElementToFile(srcArma, f, True, True);
    if not Assigned(arma) then begin
      Say('FAIL: copy of the armor addon failed'); Exit;
    end;
    SetEditorID(arma, ARMA_EDID);
    if not SetSwap(arma, 'Male Biped Model', 'MO2S', mswp) then Exit;
    if not SetSwap(arma, 'Female Biped Model', 'MO3S', mswp) then Exit;
    Say('addon: ' + Name(arma));

    // ---- the dress ----
    armo := wbCopyElementToFile(srcArmo, f, True, True);
    if not Assigned(armo) then begin
      Say('FAIL: copy of the Sequin Dress failed'); Exit;
    end;
    SetEditorID(armo, ARMO_EDID);
    SetElementEditValues(armo, 'FULL', ARMO_NAME);
    SetElementEditValues(armo, 'DESC', ARMO_DESC);
    Say('  enchantment was: ' + GetElementEditValues(armo, 'EITM'));
    SetElementNativeValues(armo, 'EITM', FormID(ench));
    Say('  enchantment now: ' + GetElementEditValues(armo, 'EITM'));
    models := ElementByName(armo, 'Models');
    if (not Assigned(models)) or (ElementCount(models) < 1) then begin
      Say('FAIL: the dress copy has no Models (armature) list'); Exit;
    end;
    m0 := ElementByIndex(models, 0);
    SetElementNativeValues(m0, 'MODL - Armor Addon', FormID(arma));
    Say('  armature now: ' + GetElementEditValues(m0, 'MODL - Armor Addon'));
    SetElementNativeValues(armo, 'FNAM\Armor Rating', DR_VALUE);
    SetElementNativeValues(armo, 'DATA\Value', ARMO_VALUE);
    SetElementNativeValues(armo, 'DATA\Weight', ARMO_WEIGHT);
    // UNDERARMOR slots (Chris, 2026-11-24: the dress took the chest and leg ARMOR slots, so chest and leg armor could not be worn with it).
    // Vanilla underarmor (Raider, Rustic, High School, Gunner underarmors) uses slots 33 (body) and 36 to 40 (the [U] torso, both arms, both legs) and none of
    // the armor-piece slots 41 to 45. First Person Flags bit n = slot 30 + n: slots 33, 36, 37, 38, 39, 40 = 8 + 64 + 128 + 256 + 512 + 1024 = 1992 (BOD2 c8070000).
    Say('  slots were: ' + GetElementEditValues(armo, 'BOD2\First Person Flags'));
    SetElementNativeValues(armo, 'BOD2\First Person Flags', 1992);
    Say('  slots now: ' + GetElementEditValues(armo, 'BOD2\First Person Flags'));
    Say('  armor rating ' + GetElementEditValues(armo, 'FNAM\Armor Rating') + ', value ' + GetElementEditValues(armo, 'DATA\Value') + ', weight ' + GetElementEditValues(armo, 'DATA\Weight'));
    dama := ElementBySignature(armo, 'DAMA');
    if not Assigned(dama) then dama := Add(armo, 'DAMA', True);
    if not Assigned(dama) then begin
      Say('FAIL: could not create the Resistances list'); Exit;
    end;
    res := ElementAssign(dama, HighInteger, nil, False);
    SetElementNativeValues(res, 'Damage Type', $00060A81);   // dtEnergy
    SetElementNativeValues(res, 'Value', ER_VALUE);
    Say('  resistance: ' + GetElementEditValues(res, 'Damage Type') + ' = ' + GetElementEditValues(res, 'Value') + ' (' + IntToStr(ElementCount(dama)) + ' entries)');
    Say('dress: ' + Name(armo));

    log.Add('');
    log.Add('===== dress dump');
    Dump(armo, '');
    log.Add('');
    log.Add('===== perk dump');
    Dump(perk, '');
    log.Add('');
    log.Add('===== enchantment dump');
    Dump(ench, '');
    log.Add('');
    log.Add('===== effect dump');
    Dump(mgef, '');
    log.Add('');
    log.Add('===== addon dump');
    Dump(arma, '');
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
