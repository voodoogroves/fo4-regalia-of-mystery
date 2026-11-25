{
  BuildVoice3.pas: TEST build, round 23 (the Voice of Set; plugin RegaliaVoice8). Status: VERIFIED in game (2026-11-25).

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

  Test in game (only RegaliaVoice8.esp ticked from ours): help "Voice of Set" 4 WEAP, player.additem <ID> 1, player.additem 0009221C 30.
    1. Silenced sound and silent to NPCs, as before.  2. A visible/audible sonic burst at EVERY impact; targets stagger or get pushed.
    3. Does the shot still hit and do the .44's damage?  4. Does standing near your own impact hurt or push you?

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildVoice3.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaVoice8 in the filename box. Accept the save prompt when xEdit closes. Run it ONCE.
  Log: our-scripts\build.log.
}
unit BuildVoice3;

const
  PLUGIN_HINT = 'RegaliaVoice8';
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

function Initialize: integer;
var
  esm, srcExpl, srcProj, srcWeap, srcLight, srcKssm, f, expl, proj, weap, el, kssm, kws, kwda, combs, obts, incs, incl: IInterface;
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
    Say('Type ' + PLUGIN_HINT + ' in the filename box.');
    f := AddNewFile;
    if not Assigned(f) then begin
      Say('FAIL: no file created (cancelled, or the name already exists in Data?)'); Exit;
    end;
    Say('new file: ' + GetFileName(f));
    AddMasterIfMissing(f, 'Fallout4.esm');

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
        SetElementNativeValues(incl, 'Mod', $001E81AB);   // mod_Legendary_Weapon_ChanceToStagger
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
