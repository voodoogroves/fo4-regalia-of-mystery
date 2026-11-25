{
  BuildVoice1.pas: TEST build, round 19 (the Voice of Set, first test: a silent .44 whose bullet spawns a sonic burst). Status: RUN as RegaliaVoice1 and RegaliaVoice2, SUPERSEDED by BuildVoice3.pas (2026-11-25).

  Design (Chris, 2026-11-24): the Voice of Set is a .44 (lore) with a sonic effect, kept in line with the .44 (damage 48; the Western Revolver is 60), no visual
  suppressor. Silenced at the source, a sonic burst and a small stagger at the target.

  This test builds (plugin RegaliaVoice2.esp, master Fallout4.esm only):
    EXPL MoM_EXPL_SonicBurst   copy of MirelurkKingSonicExplosion (000EA8F9) with Stagger = Small (damage 0, radius 64, its own sonic sound and screen warp)
    PROJ MoM_PROJ_Voice        copy of Projectile45Caliber (000FBF9B): Explosion = our burst, suppressed muzzle flash (MuzPistolSmallSupp.nif, suppressor light)
    WEAP MoM_WEAP_Voice        "Voice of Set": copy of the .44 (000CE97D), Override Projectile = ours, Sound Level = Silent, damage 48 (unchanged)
  Unknown being tested: do Beam-type (hitscan) bullets fire the Explosion field on impact? If not, fall back to an enchantment on-hit effect.

  IN THE MODULE LIST tick Fallout4.esm and the six DLC, then OK.

  Test in game (RegaliaVoice2.esp ticked): help "Voice of Set" 4 WEAP, player.additem <ID> 1, player.additem 0009221C 30.
    1. Fire at a wall and at a raider/dummy: is the shot QUIET (do nearby NPCs stay unaware)? Compare with a plain .44.
    2. Is there a sonic burst (sound, screen warp, stagger) at the impact point? Does the muzzle flash look suppressed?
    3. Damage in the Pip-Boy: 48 like the plain .44?

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildVoice1.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaVoice2 in the filename box. Accept the save prompt when xEdit closes. Run it ONCE.
  Log: our-scripts\build.log.
}
unit BuildVoice1;

const
  PLUGIN_HINT = 'RegaliaVoice2';
  EXPL_EDID = 'MoM_EXPL_SonicBurst';
  PROJ_EDID = 'MoM_PROJ_Voice';
  WEAP_EDID = 'MoM_WEAP_Voice';
  WEAP_NAME = 'Voice of Set';
  WEAP_DESC = 'A .44 revolver rebuilt to fire without a sound. The bullet is silent at the muzzle; where it lands, it screams.';
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
  esm, srcExpl, srcProj, srcWeap, srcLight, f, expl, proj, weap, el: IInterface;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    srcExpl := RecordByFormID(esm, $000EA8F9, True);    // MirelurkKingSonicExplosion
    srcProj := RecordByFormID(esm, $000FBF9B, True);    // Projectile45Caliber
    srcWeap := RecordByFormID(esm, $000CE97D, True);    // the .44
    srcLight := RecordByFormID(esm, $001F1E46, True);   // MuzFlashLightMachineGunSuppressor
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
    Say('  explosion stagger was: ' + GetElementEditValues(expl, 'DATA\Stagger'));
    SetElementEditValues(expl, 'DATA\Stagger', 'Small');
    Say('  explosion stagger now: ' + GetElementEditValues(expl, 'DATA\Stagger') + ', damage ' + GetElementEditValues(expl, 'DATA\Damage') + ', outer radius ' + GetElementEditValues(expl, 'DATA\Outer Radius'));
    Say('explosion: ' + Name(expl));

    proj := wbCopyElementToFile(srcProj, f, True, True);
    if not Assigned(proj) then begin
      Say('FAIL: copy of the .44 projectile failed'); Exit;
    end;
    SetEditorID(proj, PROJ_EDID);
    SetElementNativeValues(proj, 'DNAM\Explosion', FormID(expl));
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

    log.Add('');
    log.Add('===== weapon dump');
    Dump(weap, '');
    log.Add('');
    log.Add('===== projectile dump');
    Dump(proj, '');
    log.Add('');
    log.Add('===== explosion dump');
    Dump(expl, '');
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
