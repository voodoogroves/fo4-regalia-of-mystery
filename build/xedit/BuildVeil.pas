{
  BuildVeil.pas: round 18, the Veil of Secrets. Status: VERIFIED in game (2026-11-24; gas immunity untested).

  Design (docs/spec-veil-of-secrets.md; Chris's decisions 2026-11-24): a black fabric veil with a cream-gold diamond net (art: build/art/make_veil.py --lace);
  the EYE AMPLIFIES it; effects: persuade chance and a protection stand-in for disease; NO radiation resistance, NO armor rating, intimidate left out
  (no vanilla anchor: the entry point Mod Player Intimidation is used by no vanilla perk).
    Persuade: Mod Charisma Challenge Chance Add Value +5, +10 more with the Eye (15 total). Vanilla anchor: Black Widow / Lady Killer +10, +20, +30.
    "Disease": THE GAME HAS NO DISEASE RESISTANCE (no actor value; Lead Belly only reduces radiation from food and drink), so it is POISON resistance:
    an armor resistance dtPoison 10 on the mask, and +10 more with the Eye (an enchantment effect AbFortifyResistPoison with an Eye condition).
  Base: the Surgical Mask (ARMO 000787DA, slots 48 Beard and 49 Mouth, addon AA_Raider_02_Helmet_Mask 000787D0).

  GAS IMMUNITY (added 2026-11-24, from a research hand-off, verified in xEdit): the Hazmat Suit's perk (HazmatSuitRadResistancePerk 0014EF46) has an entry
  Mod Incoming Spell Magnitude / Set Value 0.0 on any incoming spell carrying the keyword DN102_PoisonGasEffectKeyword (000449B9). Exactly three effects carry it
  in the whole game (HalluciGen gas 000E6203 and the two Nuka-World Gauntlet gas effects 0602D828 and 0603DB50). The Veil's perk gets a copy of that one entry
  (not the two radiation entries): the wearer takes no damage from those gases. Always on while the Veil is worn (GAS_NEEDS_EYE is False).

  What it builds (plugin RegaliaVeil1.esp; masters Fallout4.esm and RegaliaGold1.esp, which supplies the Eye of Ra keyword MoM_EyeOfRa_KW):
    MSWP MoM_MSWP_Veil          Armor\Raider02\Raider02Mask.BGSM -> Armor\VeilOfSecrets\VeilOfSecrets.BGSM (the net art, in the MO2 mod "Veil of Secrets Art")
    ARMA MoM_ARMA_Veil          copy of AA_Raider_02_Helmet_Mask with MO2S and MO3S = that swap
    PERK MoM_PERK_Veil          a copy of Black Widow rank 1 (hidden, one rank, requirement and next-rank link removed, its weapon-damage entry and its
                                sex condition removed): persuade +5, and a copy with +10 if the Eye is worn; plus the gas entry copied from the Hazmat perk
    MGEF MoM_MGEF_VeilPerk      copy of 001F4423 (Add Perk), Perk to Apply = our perk
    ENCH MoM_ENCH_Veil          built from Stealth Move (ENCH 00245BDE): its effect becomes AbFortifyResistPoison magnitude 10 with the condition
                                WornHasKeyword MoM_EyeOfRa_KW; plus our Add Perk effect
    ARMO MoM_ARMO_Veil          "Veil of Secrets": copy of the Surgical Mask with our armature and enchantment, resistance dtPoison 10, value 40, weight 0.2

  IN THE MODULE LIST tick Fallout4.esm, ALL SIX DLC, AND RegaliaGold1.esp. Then OK.

  Test in game (RegaliaVeil1.esp and RegaliaGold1.esp ticked; "Veil of Secrets Art" enabled; Test profile; Normal difficulty):
    1. help "Veil of Secrets" 4 ARMO, player.additem <ID> 1, equip. The look: a black veil with a cream-gold diamond net. Name, description, the Pip-Boy poison resistance.
    2. help "Veil of Secrets" 4 PERK, then player.hasperk <ID>: 1 while worn, 0 when not.
    3. With the Eye worn too (RegaliaGold1): hasperk still 1; the poison resistance in the Pip-Boy goes up by 10.
    3b. THE GAS: walk into the HalluciGen, Inc. basement gas (quest Hazardous Material) or the Nuka-World Gauntlet gas room (quest Taken for a Ride) wearing the
       Veil: no damage from the gas? Compare without the Veil, and with the vanilla Hazmat Suit as a control. (Untested; the research did not test either.)
    4. Does it conflict with a hat or helmet (it should not: slots 48 and 49 only)? Does it look right on the male and female model?

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildVeil.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaVeil1 in the filename box. Accept the save prompt when xEdit closes (answer No after an error). Run it ONCE.
  Log: our-scripts\build.log.
}
unit BuildVeil;

const
  PLUGIN_HINT = 'RegaliaVeil1';
  EYE_PLUGIN = 'RegaliaGold1.esp';
  EYE_KW_EDID = 'MoM_EyeOfRa_KW';
  MSWP_EDID = 'MoM_MSWP_Veil';
  MAT_ORIGINAL = 'Armor\Raider02\Raider02Mask.BGSM';
  MAT_REPLACEMENT = 'Armor\VeilOfSecrets\VeilOfSecrets.BGSM';
  ARMA_EDID = 'MoM_ARMA_Veil';
  ARMO_EDID = 'MoM_ARMO_Veil';
  ARMO_NAME = 'Veil of Secrets';
  ARMO_DESC = 'A black veil worked with a fine net of cream-gold thread. It turns away toxins, spoilage and poison gas, and lends a quiet persuasiveness; with the Eye of Ra the protection and the persuasiveness grow.';
  PERK_EDID = 'MoM_PERK_Veil';
  PERK_NAME = 'Veil of Secrets';
  PERK_DESC = 'Easier to persuade in dialogue. You take no damage from poison gas.';
  MGEF_EDID = 'MoM_MGEF_VeilPerk';
  ENCH_EDID = 'MoM_ENCH_Veil';
  ENCH_NAME = 'Veil of Secrets';
  PERSUADE_BASE = '5.0';
  PERSUADE_EYE = '10.0';
  GAS_NEEDS_EYE = False;
  POISON_BASE = 10;
  POISON_EYE = 10;
  ARMO_VALUE = 40;
  ARMO_WEIGHT = 0.2;
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
  esm, gold, srcArmo, srcArma, srcEnchStealth, srcEnchAP, srcMgefAP, srcPerkBW, srcPerkHaz, gasEff, eyekw, f, mswp, arma, armo, perk, mgef, ench: IInterface;
  effs, base, ee, el, ees, newEff, conds, pcs, pc, dama, res, models, m0, data, ctda, cond: IInterface;
  i: integer;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    srcArmo := RecordByFormID(esm, $000787DA, True);        // Clothes_Raider_SurgicalMask
    srcArma := RecordByFormID(esm, $000787D0, True);        // AA_Raider_02_Helmet_Mask
    srcEnchStealth := RecordByFormID(esm, $00245BDE, True); // enchArmorStealthMoveMod (a constant effect with conditions)
    srcEnchAP := RecordByFormID(esm, $001F4425, True);      // enchModArmorPenetration (an Add Perk enchantment)
    srcMgefAP := RecordByFormID(esm, $001F4423, True);      // the Add Perk effect
    srcPerkBW := RecordByFormID(esm, $0004A0D4, True);      // BlackWidow01 (its second entry: Mod Charisma Challenge Chance Add Value 10)
    srcPerkHaz := RecordByFormID(esm, $0014EF46, True);     // HazmatSuitRadResistancePerk (its first entry blocks the poison gas)
    if (not Assigned(srcArmo)) or (not Assigned(srcArma)) or (not Assigned(srcEnchStealth)) or (not Assigned(srcEnchAP)) or
       (not Assigned(srcMgefAP)) or (not Assigned(srcPerkBW)) or (not Assigned(srcPerkHaz)) then begin
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

    // ---- the perk (persuade) ----
    perk := wbCopyElementToFile(srcPerkBW, f, True, True);
    if not Assigned(perk) then begin
      Say('FAIL: copy of the Black Widow perk failed'); Exit;
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
    Say('perk effects as copied: ' + IntToStr(ElementCount(effs)) + ' (expect 2: weapon damage x1.05, persuade +10)');
    if ElementCount(effs) <> 2 then begin
      Say('FAIL: expected 2 entries on the copied Black Widow perk'); Exit;
    end;
    Remove(ElementByIndex(effs, 0));          // drop the weapon damage entry; keep Mod Charisma Challenge Chance
    base := ElementByIndex(effs, 0);
    // drop the sex condition (tab 1) so the bonus applies to everyone
    pcs := ElementByName(base, 'Perk Conditions');
    for i := ElementCount(pcs) - 1 downto 0 do begin
      pc := ElementByIndex(pcs, i);
      if GetElementNativeValues(pc, 'PRKC - Run On (Tab Index)') <> 0 then begin
        Say('  removing a non-attacker condition (tab ' + GetElementEditValues(pc, 'PRKC - Run On (Tab Index)') + ')');
        Remove(pc);
      end;
    end;
    ee := ElementByName(base, 'Function Parameters');
    SetElementEditValues(ee, 'EPFB - Perk Entry ID (unique)', '0');
    SetEditValue(ElementByIndex(ElementBySignature(ee, 'EPFD'), 0), PERSUADE_BASE);
    if not SetTab0Condition(f, base, 'HasPerk', perk, 1) then Exit;
    Say('  entry 0: persuade base ' + PERSUADE_BASE);
    if not Assigned(AddEntry(f, effs, base, PERSUADE_EYE, 1, True, perk, eyekw)) then Exit;
    // the gas entry: copy the Hazmat perk's first entry (Mod Incoming Spell Magnitude, Set Value 0.0, spell keyword DN102_PoisonGasEffectKeyword)
    gasEff := ElementAssign(effs, HighInteger, ElementByIndex(ElementByName(srcPerkHaz, 'Effects'), 0), False);
    if not Assigned(gasEff) then begin
      Say('FAIL: could not copy the gas entry from the Hazmat perk'); Exit;
    end;
    ee := ElementByName(gasEff, 'Function Parameters');
    SetElementEditValues(ee, 'EPFB - Perk Entry ID (unique)', '2');
    pcs := ElementByName(gasEff, 'Perk Conditions');
    Say('  gas entry: ' + GetElementEditValues(ElementByName(gasEff, 'DATA - Effect Data'), 'Entry Point\Entry Point') + ' / ' + GetElementEditValues(ElementByName(gasEff, 'DATA - Effect Data'), 'Entry Point\Function') + ', value ' + GetEditValue(ElementByIndex(ElementBySignature(ee, 'EPFD'), 0)) + ', ' + IntToStr(ElementCount(pcs)) + ' perk condition(s) as copied (expect 1: the gas keyword)');
    if GAS_NEEDS_EYE then begin
      Say('FAIL: GAS_NEEDS_EYE is not implemented in this build (it would need an added tab 0 condition)'); Exit;
    end;
    Say('perk: ' + Name(perk) + ' with ' + IntToStr(ElementCount(effs)) + ' entries (expect 3: persuade, persuade with the Eye, the gas)');

    // ---- the Add Perk effect ----
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

    // ---- the enchantment: Stealth Move's structure becomes "poison resistance +10 while the Eye is worn", plus our Add Perk effect ----
    ench := wbCopyElementToFile(srcEnchStealth, f, True, True);
    if not Assigned(ench) then begin
      Say('FAIL: copy of Stealth Move failed'); Exit;
    end;
    SetEditorID(ench, ENCH_EDID);
    SetElementEditValues(ench, 'FULL', ENCH_NAME);
    ees := ElementByName(ench, 'Effects');
    Say('enchantment effects as copied: ' + IntToStr(ElementCount(ees)) + ' (Stealth Move has 2, a duplicate)');
    while ElementCount(ees) > 1 do
      Remove(ElementByIndex(ees, ElementCount(ees) - 1));
    newEff := ElementByIndex(ees, 0);
    SetElementNativeValues(newEff, 'EFID - Base Effect', $0004D86B);      // AbFortifyResistPoison (a vanilla record: the same number in every file)
    SetElementNativeValues(newEff, 'EFIT\Magnitude', POISON_EYE);
    conds := ElementByName(newEff, 'Conditions');
    Say('  poison effect: ' + GetElementEditValues(newEff, 'EFID - Base Effect') + ' magnitude ' + GetElementEditValues(newEff, 'EFIT\Magnitude') + ', conditions as copied: ' + IntToStr(ElementCount(conds)) + ' (expect 2)');
    if ElementCount(conds) = 2 then Remove(ElementByIndex(conds, 1));
    cond := ElementByIndex(conds, 0);
    ctda := ElementBySignature(cond, 'CTDA');
    if not Assigned(ctda) then begin
      Say('FAIL: no CTDA on the poison effect condition'); Exit;
    end;
    SetElementEditValues(ctda, 'Function', 'WornHasKeyword');
    SetElementNativeValues(ctda, 'Parameter #1', LoadOrderFormIDtoFileFormID(f, GetLoadOrderFormID(eyekw)));
    SetElementNativeValues(ctda, 'Comparison Value', 1);
    Say('  poison effect condition: ' + GetElementEditValues(ctda, 'Function') + ' ' + GetElementEditValues(ctda, 'Parameter #1') + ' (' + IntToStr(ElementCount(conds)) + ' condition)');
    newEff := ElementAssign(ees, HighInteger, ElementByIndex(ElementByName(srcEnchAP, 'Effects'), 0), False);
    if not Assigned(newEff) then begin
      Say('FAIL: could not add the Add Perk effect to the enchantment'); Exit;
    end;
    SetElementNativeValues(newEff, 'EFID - Base Effect', FormID(mgef));
    Say('  effect 2: ' + GetElementEditValues(newEff, 'EFID - Base Effect'));
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

    // ---- the veil ----
    armo := wbCopyElementToFile(srcArmo, f, True, True);
    if not Assigned(armo) then begin
      Say('FAIL: copy of the Surgical Mask failed'); Exit;
    end;
    SetEditorID(armo, ARMO_EDID);
    SetElementEditValues(armo, 'FULL', ARMO_NAME);
    SetElementEditValues(armo, 'DESC', ARMO_DESC);
    el := ElementBySignature(armo, 'EITM');
    if not Assigned(el) then el := Add(armo, 'EITM', True);
    SetElementNativeValues(armo, 'EITM', FormID(ench));
    Say('  enchantment now: ' + GetElementEditValues(armo, 'EITM'));
    models := ElementByName(armo, 'Models');
    if (not Assigned(models)) or (ElementCount(models) < 1) then begin
      Say('FAIL: the veil copy has no Models (armature) list'); Exit;
    end;
    m0 := ElementByIndex(models, 0);
    Say('  armature was: ' + GetElementEditValues(m0, 'MODL - Armor Addon'));
    SetElementNativeValues(m0, 'MODL - Armor Addon', FormID(arma));
    Say('  armature now: ' + GetElementEditValues(m0, 'MODL - Armor Addon'));
    SetElementNativeValues(armo, 'DATA\Value', ARMO_VALUE);
    SetElementNativeValues(armo, 'DATA\Weight', ARMO_WEIGHT);
    dama := ElementBySignature(armo, 'DAMA');
    if not Assigned(dama) then dama := Add(armo, 'DAMA', True);
    if not Assigned(dama) then begin
      Say('FAIL: could not create the Resistances list'); Exit;
    end;
    res := ElementAssign(dama, HighInteger, nil, False);
    SetElementNativeValues(res, 'Damage Type', $00060A84);   // dtPoison
    SetElementNativeValues(res, 'Value', POISON_BASE);
    Say('  resistance: ' + GetElementEditValues(res, 'Damage Type') + ' = ' + GetElementEditValues(res, 'Value') + ' (' + IntToStr(ElementCount(dama)) + ' entries); armor rating ' + GetElementEditValues(armo, 'FNAM\Armor Rating'));
    Say('  slots: ' + GetElementEditValues(armo, 'BOD2\First Person Flags'));
    Say('veil: ' + Name(armo));

    log.Add('');
    log.Add('===== veil dump');
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
