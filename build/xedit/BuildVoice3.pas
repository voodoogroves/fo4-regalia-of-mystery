{
  BuildVoice3.pas: TEST build, round 25 (the Voice of Set; plugin RegaliaVoice12). Round 24 (RegaliaVoice11) was VERIFIED.
  Round 25 (RegaliaVoice12): gold plating, a material swap on our weapon mod (art in the MO2 mod "Blade of Bastet Art"). Status: VERIFIED in game (2026-11-25).

  New in round 24 (Chris): the Eye of Ra raises the stagger chance; a Broken Voice of Set and its repair recipe (Cryptos Notes + Gun Nut 3). Random receivers stay.
    Eye: our copy of the legendary stagger mod also carries an Add Perk enchantment; the perk (copy of BigLeagues02's "Apply Combat Hit Spell" entry) casts our spell
    (copy of PerkDisarm with the legendary stagger effect, 30%) when the attacker wears MoM_EyeOfRa_KW and the weapon has MoM_Voice_KW. Independent of the
    mod's own 30%, so about 51% with the Eye.
    Recipe: Broken Voice + Steel 4 + Screws 2 + Silver 2 + Adhesive 3 at a Chemistry Station.
  Masters now: Fallout4.esm and RegaliaGold1.esp. IN THE MODULE LIST also tick RegaliaGold1.esp.
  Extra tests (RegaliaGold1.esp ticked too): hasperk with the Voice drawn; stagger frequency with and without the Eye; the repair recipe (spawn "Broken Voice" MISC),
  greyed until Cryptos Notes + Gun Nut 3, consumes the broken item, gives a working Voice.

  New in round 23: the stagger is the vanilla legendary mod mod_Legendary_Weapon_ChanceToStagger (001E81AB), verified by console amod on Voice7; it is added to every
  template combination. INRD (instance naming) is removed so the name stays exactly "Voice of Set". Also check in game: name, legendary effect listed, about 30% stagger.

  History (Chris's tests): Voice5 = real silenced gunshot (our sound mapping) and silent to NPCs: good. The burst and the stagger never showed.
  Cause of the burst: our bullet was a copy of Projectile45Caliber, a Beam projectile without the "Explosion" flag. The Captain Cosmos "Pulse" barrel
  (Creation Club) is just the vanilla MS09PushProjectile (00199046, Missile type, Explosion flag) with MS09PushExplosion (000E5786); no Creation Club master needed.
  The weapon-record enchantment (EITM) never applied even at 100%, so it is removed: the stagger now comes from the explosion.

  Builds (master Fallout4.esm only):
    EXPL MoM_EXPL_SonicBurst   copy of MS09PushExplosion, toned down (constants below), impact sound = Mirelurk King sonic (00101672)
    PROJ MoM_PROJ_Voice        copy of MS09PushProjectile: our explosion, faster, no drop, suppressed muzzle flash
    KSSM MoM_KSSM_VoiceSilenced  silenced revolver sound for the .44 keyword + Silenced + Player
    WEAP MoM_WEAP_Voice        "Voice of Set": copy of the .44, our projectile, Sound Level Silent, s_20_Silenced, damage 48

  IN THE MODULE LIST tick Fallout4.esm and the six DLC, then OK.

  Test in game (only RegaliaVoice12.esp ticked from ours): help "Voice of Set" 4 WEAP, player.additem <ID> 1, player.additem 0009221C 30.
    1. Silenced sound and silent to NPCs, as before.  2. A visible/audible sonic burst at EVERY impact; targets stagger or get pushed.
    3. Does the shot still hit and do the .44's damage?  4. Does standing near your own impact hurt or push you?

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildVoice3.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaVoice12 in the filename box. Accept the save prompt when xEdit closes. Run it ONCE.
  Log: our-scripts\build.log.
}
unit BuildVoice3;

const
  PLUGIN_HINT = 'RegaliaVoice12';
  EXPL_EDID = 'MoM_EXPL_SonicBurst';
  PROJ_EDID = 'MoM_PROJ_Voice';
  WEAP_EDID = 'MoM_WEAP_Voice';
  WEAP_NAME = 'Voice of Set';
  WEAP_DESC = 'A .44 revolver rebuilt to fire without a sound. The bullet is silent at the muzzle; where it lands, it screams.';
  KSSM_EDID = 'MoM_KSSM_VoiceSilenced';
  BURST_FORCE = 250;      // MS09: 1000
  BURST_DAMAGE = 0;       // MS09: 25
  BURST_INNER = 32;       // MS09: 100
  BURST_OUTER = 128;      // MS09: 300
  BURST_STAGGER = 'Medium';
  BULLET_SPEED = 10000;   // MS09: 4500
  FLASH_MODEL = 'Effects\MuzPistolSmallSupp.nif';
  GOLD_PLUGIN = 'RegaliaGold1.esp';
  EYE_KW_EDID = 'MoM_EyeOfRa_KW';
  CRYPTOS_EDID = 'MoM_PERK_Cryptos';
  EYE_CHANCE = 30;
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

// The number to write for a record: its own FormID if it lives in the file being built, else the file-local number mapped from its load-order ID.
function Ref(f, rec: IInterface): integer;
begin
  if GetFileName(GetFile(rec)) = GetFileName(f) then Result := FormID(rec)
  else Result := LoadOrderFormIDtoFileFormID(f, GetLoadOrderFormID(rec));
end;

function FindIn(plug: IInterface; sig, edid: string): IInterface;
begin
  Result := MainRecordByEditorID(GroupBySignature(plug, sig), edid);
  if not Assigned(Result) then Say('FAIL: ' + sig + ' ' + edid + ' not found in ' + GetFileName(plug));
end;

procedure AddComponent(f, comps: IInterface; formid: integer; cnt: integer);
var
  c: IInterface;
begin
  c := ElementAssign(comps, HighInteger, nil, False);
  SetElementNativeValues(c, 'Component', formid);
  SetElementNativeValues(c, 'Count', cnt);
end;

function AddHasPerkCondition(f, r, perk: IInterface): boolean;
var
  conds, cond, ctda: IInterface;
begin
  Result := False;
  conds := ElementByName(r, 'Conditions');
  if not Assigned(conds) then conds := Add(r, 'Conditions', True);
  if not Assigned(conds) then begin
    Say('FAIL: could not create the Conditions list on ' + EditorID(r)); Exit;
  end;
  cond := ElementAssign(conds, HighInteger, nil, False);
  ctda := ElementBySignature(cond, 'CTDA');
  if not Assigned(ctda) then begin
    Say('FAIL: no CTDA on the new condition of ' + EditorID(r)); Exit;
  end;
  SetElementEditValues(ctda, 'Function', 'HasPerk');
  SetElementNativeValues(ctda, 'Parameter #1', Ref(f, perk));
  SetElementNativeValues(ctda, 'Comparison Value', 1);
  Say('  condition on ' + EditorID(r) + ': ' + GetElementEditValues(ctda, 'Function') + ' ' + GetElementEditValues(ctda, 'Parameter #1') + ' ' + GetElementEditValues(ctda, 'Type') + ' ' + GetElementEditValues(ctda, 'Comparison Value'));
  Result := True;
end;

// A Chemistry Station recipe: ingredients, product (a record of another plugin), Utility category.
function MakeRecipe(f: IInterface; edid: string; product: IInterface): IInterface;
var
  r, fnam, kw: IInterface;
begin
  Result := nil;
  r := Add(Add(f, 'COBJ', True), 'COBJ', True);
  if not Assigned(r) then begin
    Say('FAIL: could not create the COBJ ' + edid); Exit;
  end;
  SetEditorID(r, edid);
  Add(r, 'FVPA', True);
  SetElementNativeValues(r, 'CNAM', Ref(f, product));
  Add(r, 'BNAM', True);
  SetElementNativeValues(r, 'BNAM', $00102158);   // WorkbenchChemlab
  fnam := Add(r, 'FNAM', True);
  kw := ElementAssign(fnam, HighInteger, nil, False);
  SetNativeValue(kw, $0006980C);                  // RecipeUtility
  Add(r, 'INTV', True);
  SetElementNativeValues(r, 'INTV\Created Object Count', 1);
  SetElementNativeValues(r, 'INTV\Priority', 0);
  Result := r;
end;

// Two substitutions: the .44's frame and bull barrel materials -> our gold ones (art/make_gold44.py).
function AddSwap(subs: IInterface; index: integer; orig, repl: string): boolean;
var
  sub: IInterface;
begin
  if index < ElementCount(subs) then sub := ElementByIndex(subs, index)
  else sub := ElementAssign(subs, HighInteger, nil, False);
  SetElementEditValues(sub, 'BNAM - Original Material', orig);
  SetElementEditValues(sub, 'SNAM - Replacement Material', repl);
  Say('  material swap: ' + GetElementEditValues(sub, 'BNAM - Original Material') + '  ->  ' + GetElementEditValues(sub, 'SNAM - Replacement Material'));
  Result := GetElementEditValues(sub, 'SNAM - Replacement Material') = repl;
end;

function Initialize: integer;
var
  esm, srcExpl, srcProj, srcWeap, srcLight, srcKssm, f, expl, proj, weap, el, kssm, kws, kwda, combs, obts, incs, incl: IInterface;
  gold, eyekw, cryptos, gunnut, srcStagMod, srcStagEnch, srcPerk, srcSpel, srcEnchAP, srcMgefAP, srcLocket: IInterface;
  voicekw, spel, perk, mgef, ench, omod, effs, eff, pcs, pc, conds, ctda, data, broken, cobj, cc: IInterface;
  tab, j, kept: integer;
  mswp, subs: IInterface;
  i, added: integer;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    srcExpl := RecordByFormID(esm, $000E5786, True);    // MS09PushExplosion
    srcProj := RecordByFormID(esm, $00199046, True);    // MS09PushProjectile
    srcWeap := RecordByFormID(esm, $000CE97D, True);    // the .44
    srcLight := RecordByFormID(esm, $001F1E46, True);   // MuzFlashLightMachineGunSuppressor
    srcKssm := RecordByFormID(esm, $0002B941, True);    // PistolHandmadeRevolverASilencedPlayer
    if (not Assigned(srcKssm)) then begin
      Say('FAIL: KSSM 0002B941 not found'); Exit;
    end;
    if (not Assigned(srcExpl)) or (not Assigned(srcProj)) or (not Assigned(srcWeap)) or (not Assigned(srcLight)) then begin
      Say('FAIL: a vanilla source record was not found'); Exit;
    end;
    Say('sources ok: ' + Name(srcExpl) + ' | ' + Name(srcProj) + ' | ' + Name(srcWeap) + ' | ' + Name(srcLight));
    srcStagMod := RecordByFormID(esm, $001E81AB, True);    // mod_Legendary_Weapon_ChanceToStagger
    srcStagEnch := RecordByFormID(esm, $0023AD16, True);   // its enchantment (the 30% stagger effect)
    srcPerk := RecordByFormID(esm, $000E36FC, True);       // BigLeagues02 (first entry: Apply Combat Hit Spell)
    srcSpel := RecordByFormID(esm, $001D604B, True);       // PerkDisarm
    srcEnchAP := RecordByFormID(esm, $001F4425, True);     // an Add Perk enchantment
    srcMgefAP := RecordByFormID(esm, $001F4423, True);     // the Add Perk effect
    srcLocket := RecordByFormID(esm, $00059B34, True);     // SilverLocket (MISC)
    gunnut := MainRecordByEditorID(GroupBySignature(esm, 'PERK'), 'GunNut03');
    if (not Assigned(srcStagMod)) or (not Assigned(srcStagEnch)) or (not Assigned(srcPerk)) or (not Assigned(srcSpel)) or
       (not Assigned(srcEnchAP)) or (not Assigned(srcMgefAP)) or (not Assigned(srcLocket)) or (not Assigned(gunnut)) then begin
      Say('FAIL: a vanilla source record for round 24 was not found'); Exit;
    end;
    gold := FindFile(GOLD_PLUGIN);
    if not Assigned(gold) then begin
      Say('FAIL: tick ' + GOLD_PLUGIN + ' in the module list'); Exit;
    end;
    eyekw := FindIn(gold, 'KYWD', EYE_KW_EDID);
    cryptos := FindIn(gold, 'PERK', CRYPTOS_EDID);
    if (not Assigned(eyekw)) or (not Assigned(cryptos)) then Exit;
    Say('Type ' + PLUGIN_HINT + ' in the filename box.');
    f := AddNewFile;
    if not Assigned(f) then begin
      Say('FAIL: no file created (cancelled, or the name already exists in Data?)'); Exit;
    end;
    Say('new file: ' + GetFileName(f));
    AddMasterIfMissing(f, 'Fallout4.esm');
    AddMasterIfMissing(f, GOLD_PLUGIN);

    expl := wbCopyElementToFile(srcExpl, f, True, True);
    if not Assigned(expl) then begin
      Say('FAIL: copy of the explosion failed'); Exit;
    end;
    SetEditorID(expl, EXPL_EDID);
    Say('  explosion as copied: force ' + GetElementEditValues(expl, 'DATA\Force') + ', damage ' + GetElementEditValues(expl, 'DATA\Damage') + ', radius ' + GetElementEditValues(expl, 'DATA\Inner Radius') + ' / ' + GetElementEditValues(expl, 'DATA\Outer Radius') + ', stagger ' + GetElementEditValues(expl, 'DATA\Stagger') + ', sound ' + GetElementEditValues(expl, 'DATA\Sound 1'));
    SetElementNativeValues(expl, 'DATA\Force', BURST_FORCE);
    SetElementNativeValues(expl, 'DATA\Damage', BURST_DAMAGE);
    SetElementNativeValues(expl, 'DATA\Inner Radius', BURST_INNER);
    SetElementNativeValues(expl, 'DATA\Outer Radius', BURST_OUTER);
    SetElementEditValues(expl, 'DATA\Stagger', BURST_STAGGER);
    SetElementNativeValues(expl, 'DATA\Sound 1', $00101672);   // FXExplosionMirelurkKingSonicProjectile
    Say('  explosion now: force ' + GetElementEditValues(expl, 'DATA\Force') + ', damage ' + GetElementEditValues(expl, 'DATA\Damage') + ', radius ' + GetElementEditValues(expl, 'DATA\Inner Radius') + ' / ' + GetElementEditValues(expl, 'DATA\Outer Radius') + ', stagger ' + GetElementEditValues(expl, 'DATA\Stagger') + ', sound ' + GetElementEditValues(expl, 'DATA\Sound 1'));
    Say('explosion: ' + Name(expl));

    proj := wbCopyElementToFile(srcProj, f, True, True);
    if not Assigned(proj) then begin
      Say('FAIL: copy of the .44 projectile failed'); Exit;
    end;
    SetEditorID(proj, PROJ_EDID);
    SetElementNativeValues(proj, 'DNAM\Explosion', FormID(expl));
    SetElementNativeValues(proj, 'DNAM\Gravity', 0);
    SetElementNativeValues(proj, 'DNAM\Speed', BULLET_SPEED);
    Say('  projectile type ' + GetElementEditValues(proj, 'DNAM\Type') + ', flags ' + GetElementEditValues(proj, 'DNAM\Flags') + ', speed ' + GetElementEditValues(proj, 'DNAM\Speed') + ', gravity ' + GetElementEditValues(proj, 'DNAM\Gravity'));
    SetElementNativeValues(proj, 'DNAM\Muzzle Flash - Light', FormID(srcLight));
    SetElementEditValues(proj, 'DNAM\Muzzle Flash - Duration', '0.05');
    el := ElementByPath(proj, 'Muzzle Flash Model\NAM1 - Model FileName');
    if not Assigned(el) then begin
      Say('FAIL: no Muzzle Flash Model\NAM1 on the projectile copy'); Exit;
    end;
    SetEditValue(el, FLASH_MODEL);
    el := ElementByPath(proj, 'Muzzle Flash Model\NAM2 - Model Information');
    if Assigned(el) then Remove(el);
    Say('  projectile explosion: ' + GetElementEditValues(proj, 'DNAM\Explosion') + ', flash light ' + GetElementEditValues(proj, 'DNAM\Muzzle Flash - Light') + ', flash model ' + GetElementEditValues(proj, 'Muzzle Flash Model\NAM1 - Model FileName'));
    Say('projectile: ' + Name(proj));

    weap := wbCopyElementToFile(srcWeap, f, True, True);
    if not Assigned(weap) then begin
      Say('FAIL: copy of the .44 failed'); Exit;
    end;
    SetEditorID(weap, WEAP_EDID);
    SetElementEditValues(weap, 'FULL', WEAP_NAME);
    SetElementEditValues(weap, 'DESC', WEAP_DESC);
    SetElementNativeValues(weap, 'FNAM\Override Projectile', FormID(proj));
    Say('  sound level was: ' + GetElementEditValues(weap, 'DNAM\Sound Level'));
    SetElementEditValues(weap, 'DNAM\Sound Level', 'Silent');
    Say('  weapon: override projectile ' + GetElementEditValues(weap, 'FNAM\Override Projectile') + ', sound level ' + GetElementEditValues(weap, 'DNAM\Sound Level') + ', damage ' + GetElementEditValues(weap, 'DNAM\Damage - Base') + ', stagger ' + GetElementEditValues(weap, 'DNAM\Stagger'));
    Say('weapon: ' + Name(weap));

    // ---- silenced gunshot sound: a sound keyword mapping for the .44 + Silenced ----
    kssm := wbCopyElementToFile(srcKssm, f, True, True);
    if not Assigned(kssm) then begin
      Say('FAIL: copy of the silenced revolver sound mapping failed'); Exit;
    end;
    SetEditorID(kssm, KSSM_EDID);
    kws := ElementByName(kssm, 'Keywords');
    i := 0;
    if Assigned(kws) then
      for i := 0 to ElementCount(kws) - 1 do
        if GetNativeValue(ElementByIndex(kws, i)) = $00055F9C then begin
          SetNativeValue(ElementByIndex(kws, i), $000D152C);   // s_40_PistolFortyFour
          Say('  sound mapping keyword 0 replaced: now ' + GetEditValue(ElementByIndex(kws, i)));
        end;
    for i := 0 to ElementCount(kws) - 1 do
      Say('  mapping keyword: ' + GetEditValue(ElementByIndex(kws, i)));
    Say('  mapping primary sound: ' + GetElementEditValues(kssm, 'DNAM'));
    kwda := ElementBySignature(weap, 'KWDA');
    el := ElementAssign(kwda, HighInteger, nil, False);
    SetNativeValue(el, $00054A67);   // s_20_Silenced
    Say('  weapon keywords now: ' + IntToStr(ElementCount(kwda)) + ' (last = ' + GetEditValue(ElementByIndex(kwda, ElementCount(kwda) - 1)) + ')');
    Say('sound mapping: ' + Name(kssm));

    // ---- the Eye of Ra: more stagger ----
    voicekw := Add(Add(f, 'KYWD', True), 'KYWD', True);
    SetEditorID(voicekw, 'MoM_Voice_KW');
    kwda := ElementBySignature(weap, 'KWDA');
    el := ElementAssign(kwda, HighInteger, nil, False);
    SetNativeValue(el, FormID(voicekw));
    Say('  weapon keywords now: ' + IntToStr(ElementCount(kwda)));

    spel := wbCopyElementToFile(srcSpel, f, True, True);
    if not Assigned(spel) then begin
      Say('FAIL: copy of the disarm spell failed'); Exit;
    end;
    SetEditorID(spel, 'MoM_SPEL_VoiceStagger');
    SetElementEditValues(spel, 'FULL', 'Voice of Set');
    // edit the spell's own effect (copying an enchantment effect into a spell came out empty in RegaliaVoice9)
    effs := ElementByName(spel, 'Effects');
    if ElementCount(effs) <> 1 then begin
      Say('FAIL: expected one spell effect, got ' + IntToStr(ElementCount(effs))); Exit;
    end;
    eff := ElementByIndex(effs, 0);
    SetElementNativeValues(eff, 'EFID - Base Effect', $001E81A8);   // ModLegendaryOnHitEffect_Stagger
    SetElementNativeValues(eff, 'EFIT\Magnitude', 4);
    SetElementNativeValues(eff, 'EFIT\Duration', 0);
    Say('  spell effect: ' + GetElementEditValues(eff, 'EFID - Base Effect') + ' magnitude ' + GetElementEditValues(eff, 'EFIT\Magnitude'));
    if GetElementNativeValues(eff, 'EFID - Base Effect') <> $001E81A8 then begin
      Say('FAIL: the spell effect is wrong'); Exit;
    end;
    // the chance goes on the perk entry (xEdit could not create a condition list on a spell effect)

    perk := wbCopyElementToFile(srcPerk, f, True, True);
    if not Assigned(perk) then begin
      Say('FAIL: copy of BigLeagues02 failed'); Exit;
    end;
    SetEditorID(perk, 'MoM_PERK_VoiceEye');
    SetElementEditValues(perk, 'FULL', 'Voice of Set');
    SetElementEditValues(perk, 'DESC', 'With the Eye of Ra, the Voice of Set staggers more often.');
    el := ElementByName(perk, 'Conditions');
    if Assigned(el) then Remove(el);
    el := ElementBySignature(perk, 'NNAM');
    if Assigned(el) then Remove(el);
    data := ElementBySignature(perk, 'DATA');
    SetElementNativeValues(data, 'Num Ranks', 1);
    SetElementNativeValues(data, 'Playable', 0);
    SetElementNativeValues(data, 'Hidden', 1);
    effs := ElementByName(perk, 'Effects');
    // keep only the "Apply Combat Hit Spell" entry (xEdit's order differs from the file's)
    for j := ElementCount(effs) - 1 downto 0 do begin
      eff := ElementByIndex(effs, j);
      Say('  perk entry ' + IntToStr(j) + ' as copied: ' + GetElementEditValues(ElementByName(eff, 'DATA - Effect Data'), 'Entry Point\Entry Point'));
      if Pos('Combat Hit Spell', GetElementEditValues(ElementByName(eff, 'DATA - Effect Data'), 'Entry Point\Entry Point')) = 0 then Remove(eff);
    end;
    if ElementCount(effs) <> 1 then begin
      Say('FAIL: expected exactly one Apply Combat Hit Spell entry, have ' + IntToStr(ElementCount(effs))); Exit;
    end;
    eff := ElementByIndex(effs, 0);
    el := ElementBySignature(ElementByName(eff, 'Function Parameters'), 'EPFD');
    if ElementCount(el) > 0 then el := ElementByIndex(el, 0);
    SetNativeValue(el, FormID(spel));
    Say('  perk entry spell now: ' + GetEditValue(el));
    if Pos('MoM_SPEL_VoiceStagger', GetEditValue(el)) = 0 then begin
      Say('FAIL: the perk entry does not point at our spell'); Exit;
    end;
    pcs := ElementByName(eff, 'Perk Conditions');
    kept := 0;
    for j := 0 to ElementCount(pcs) - 1 do begin
      pc := ElementByIndex(pcs, j);
      tab := GetElementNativeValues(pc, 'PRKC - Run On (Tab Index)');
      conds := ElementByName(pc, 'Conditions');
      while ElementCount(conds) > 1 do
        Remove(ElementByIndex(conds, ElementCount(conds) - 1));
      ctda := ElementBySignature(ElementByIndex(conds, 0), 'CTDA');
      if tab = 0 then begin
        SetElementEditValues(ctda, 'Function', 'WornHasKeyword');
        SetElementNativeValues(ctda, 'Parameter #1', Ref(f, eyekw));
        SetElementNativeValues(ctda, 'Comparison Value', 1);
        // second attacker condition: the chance, copied in form from the legendary stagger enchantment (GetRandomPercent <= N)
        el := ElementBySignature(ElementByIndex(ElementByName(ElementByIndex(ElementByName(srcStagEnch, 'Effects'), 0), 'Conditions'), 0), 'CTDA');
        ctda := ElementBySignature(ElementAssign(conds, HighInteger, nil, False), 'CTDA');
        SetElementEditValues(ctda, 'Function', GetElementEditValues(el, 'Function'));
        SetElementEditValues(ctda, 'Type', GetElementEditValues(el, 'Type'));
        SetElementNativeValues(ctda, 'Comparison Value', EYE_CHANCE);
        Say('  chance condition: ' + GetElementEditValues(ctda, 'Function') + ' ' + GetElementEditValues(ctda, 'Type') + ' ' + GetElementEditValues(ctda, 'Comparison Value') + ' (source type ' + GetElementEditValues(el, 'Type') + '); attacker conditions: ' + IntToStr(ElementCount(conds)));
        if (ElementCount(conds) <> 2) or (GetElementEditValues(ctda, 'Function') <> 'GetRandomPercent') then begin
          Say('FAIL: the chance condition was not added'); Exit;
        end;
        ctda := ElementBySignature(ElementByIndex(conds, 0), 'CTDA');
        kept := kept + 1;
      end;
      if tab = 1 then begin
        SetElementEditValues(ctda, 'Function', 'HasKeyword');
        SetElementNativeValues(ctda, 'Parameter #1', FormID(voicekw));
        kept := kept + 1;
      end;
      SetElementNativeValues(ctda, 'Comparison Value', 1);
      Say('  perk tab ' + IntToStr(tab) + ': ' + GetElementEditValues(ctda, 'Function') + ' ' + GetElementEditValues(ctda, 'Parameter #1') + ' ' + GetElementEditValues(ctda, 'Type') + ' ' + GetElementEditValues(ctda, 'Comparison Value'));
    end;
    if (kept <> 2) or (ElementCount(pcs) <> 2) then begin
      Say('FAIL: expected exactly the attacker and weapon tabs on the perk entry'); Exit;
    end;
    Say('  perk entry: ' + GetElementEditValues(ElementByName(eff, 'DATA - Effect Data'), 'Entry Point\Entry Point'));

    mgef := wbCopyElementToFile(srcMgefAP, f, True, True);
    SetEditorID(mgef, 'MoM_MGEF_VoicePerk');
    SetElementEditValues(mgef, 'FULL', 'MoM_MGEF_VoicePerk');
    SetElementNativeValues(ElementByPath(mgef, 'Magic Effect Data\DATA - Data'), 'Perk to Apply', FormID(perk));
    ench := wbCopyElementToFile(srcEnchAP, f, True, True);
    SetEditorID(ench, 'MoM_ENCH_Voice');
    SetElementNativeValues(ElementByIndex(ElementByName(ench, 'Effects'), 0), 'EFID - Base Effect', FormID(mgef));
    omod := wbCopyElementToFile(srcStagMod, f, True, True);
    if (not Assigned(mgef)) or (not Assigned(ench)) or (not Assigned(omod)) then begin
      Say('FAIL: copy of the effect, enchantment or mod failed'); Exit;
    end;
    SetEditorID(omod, 'MoM_OMOD_Voice');
    if not AddModProp(omod, 'FormID,Int', 'ADD', 'Enchantments', FormID(ench), '440') then Exit;
    // ---- the gold look ----
    mswp := Add(Add(f, 'MSWP', True), 'MSWP', True);
    if not Assigned(mswp) then begin
      Say('FAIL: could not create the material swap record'); Exit;
    end;
    SetEditorID(mswp, 'MoM_MSWP_VoiceGold');
    subs := Add(mswp, 'Material Substitutions', True);
    if not Assigned(subs) then begin
      Say('FAIL: could not create Material Substitutions'); Exit;
    end;
    if not AddSwap(subs, 0, 'Weapons\44\44.bgsm', 'Weapons\VoiceOfSet\VoiceGold.BGSM') then Exit;
    if not AddSwap(subs, 1, 'Weapons\44\44BullBarrel.bgsm', 'Weapons\VoiceOfSet\VoiceBullGold.BGSM') then Exit;
    Say('  substitutions on the swap: ' + IntToStr(ElementCount(subs)));
    if ElementCount(subs) <> 2 then begin
      Say('FAIL: expected two substitutions'); Exit;
    end;
    if not AddModProp(omod, 'FormID,Int', 'ADD', 'MaterialSwaps', FormID(mswp), '441') then Exit;
    Say('mod: ' + Name(omod));

    // ---- legendary stagger, built into every template combination; fixed name ----
    combs := ElementByPath(weap, 'Object Template\Combinations');
    if not Assigned(combs) then begin
      Say('FAIL: no Object Template\Combinations on the weapon copy'); Exit;
    end;
    added := 0;
    for i := 0 to ElementCount(combs) - 1 do begin
      obts := ElementBySignature(ElementByIndex(combs, i), 'OBTS');
      incs := ElementByName(obts, 'Includes');
      if Assigned(incs) then begin
        incl := ElementAssign(incs, HighInteger, nil, False);
        SetElementNativeValues(incl, 'Mod', FormID(omod));   // our copy of the legendary stagger mod
        SetElementNativeValues(incl, 'Attach Point Index', 0);
        SetElementEditValues(incl, 'Optional', 'False');
        SetElementEditValues(incl, 'Don''t Use All', 'True');
        SetElementNativeValues(obts, 'Include Count', ElementCount(incs));
        Say('  combination ' + IntToStr(i) + ': ' + IntToStr(ElementCount(incs)) + ' includes (count field ' + GetElementEditValues(obts, 'Include Count') + '), last = ' + GetElementEditValues(incl, 'Mod'));
        added := added + 1;
      end;
    end;
    if added = 0 then begin
      Say('FAIL: no combination had an Includes list'); Exit;
    end;
    el := ElementBySignature(weap, 'INRD');
    if Assigned(el) then Remove(el);
    Say('  legendary stagger added to ' + IntToStr(added) + ' of ' + IntToStr(ElementCount(combs)) + ' combinations; instance naming removed');

    // ---- the Broken Voice and its repair recipe ----
    broken := wbCopyElementToFile(srcLocket, f, True, True);
    if not Assigned(broken) then begin
      Say('FAIL: copy of the Silver Locket failed'); Exit;
    end;
    SetEditorID(broken, 'MoM_MISC_BrokenVoice');
    SetElementEditValues(broken, 'FULL', 'Broken Voice of Set');
    SetEditValue(ElementByPath(broken, 'Model\MODL - Model FileName'), 'Weapons\44\44.nif');
    el := ElementByPath(broken, 'Model\MODT - Model Information');
    if Assigned(el) then Remove(el);
    el := ElementBySignature(broken, 'CVPA');
    if Assigned(el) then Remove(el);
    cc := ElementBySignature(broken, 'KWDA');
    if not Assigned(cc) then cc := Add(broken, 'KWDA', True);
    el := ElementAssign(cc, HighInteger, nil, False);
    SetNativeValue(el, $001CC46A);   // UnscrappableObject
    Say('misc: ' + Name(broken));
    cobj := MakeRecipe(f, 'MoM_COBJ_RepairVoice', weap);
    if not Assigned(cobj) then Exit;
    cc := ElementBySignature(cobj, 'FVPA');
    AddComponent(f, cc, FormID(broken), 1);
    AddComponent(f, cc, $0001FABD, 4);   // Steel
    AddComponent(f, cc, $0003D294, 2);   // Screws
    AddComponent(f, cc, $0001FABB, 2);   // Silver
    AddComponent(f, cc, $0001FAA5, 3);   // Adhesive
    if not AddHasPerkCondition(f, cobj, cryptos) then Exit;
    if not AddHasPerkCondition(f, cobj, gunnut) then Exit;
    Say('recipe: ' + Name(cobj) + ' -> ' + GetElementEditValues(cobj, 'CNAM'));

    log.Add('===== perk dump');
    Dump(perk, '');
    log.Add('===== spell dump');
    Dump(spel, '');
    log.Add('===== mod dump');
    Dump(omod, '');
    log.Add('===== recipe dump');
    Dump(cobj, '');
    log.Add('');
    log.Add('===== weapon dump');
    Dump(weap, '');
    log.Add('');
    log.Add('===== projectile dump');
    Dump(proj, '');
    log.Add('');
    log.Add('===== explosion dump');
    Dump(expl, '');
    log.Add('');
    log.Add('===== sound mapping dump');
    Dump(kssm, '');
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
