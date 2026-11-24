{
  BuildGarbTest.pas: LOOK TEST build, round 16 (the Garb of Mysteries: the Sequin Dress with our own material). Status: WRITTEN, NOT YET RUN (2026-11-24).

  Design (Chris, 2026-11-24): the Garb is built on the Sequin Dress (ClothesSequinDress 0011A27B; Agatha's Dress shares its addon): it is body-hugging,
  and its texture is already a dark sequin dress. Look: charcoal body, emerald chevrons, pale cream-gold top band (colours measured from an in-game
  picture of the Fallout 76 outfit: chevrons 65,137,80; body 53,56,57; collar 198,181,150). Art: build/art/make_dress.py (outputs are derived from
  Bethesda's texture: NOT committed).

  What the vanilla records say (looked up 2026-11-24): the armor addon AAClothesSequinDress (ARMA 0011A27A) has Male Biped Model DressMSequin.nif and
  Female Biped Model DressFSequin.nif, no material swaps; the worn mesh has two materials, the dress (Clothes\\SlinkyDress\\SequinDress.BGSM) and the
  body skin. The dress is one 2048 x 2048 BC1 texture. A swap on the addon's biped models replaces the dress material only.

  This build makes (plugin RegaliaGarb1.esp, master Fallout4.esm ONLY, no DLC):
    MSWP MoM_MSWP_GarbStripes  Clothes\\SlinkyDress\\SequinDress.BGSM -> Clothes\\GarbOfMysteries\\GarbOfMysteries.BGSM
    ARMA MoM_ARMA_Garb         a copy of AAClothesSequinDress with MO2S (male) and MO3S (female) = that swap
    ARMO MoM_ARMO_GarbTest     "Garb of Mysteries (look test)": a copy of the Sequin Dress whose armature is our addon
  Nothing else: no armor values, no broken form, no recipe, no gates (look only).

  THE ART lives in the MO2 mod "Garb of Mysteries Art" (loose files: Textures\\Clothes\\GarbOfMysteries\\GarbOfMysteries_d.dds and
  Materials\\Clothes\\GarbOfMysteries\\GarbOfMysteries.BGSM; the Test profile already has the loose-file ini settings). The FIRST texture is the UV TEST
  texture: vertical columns = distinct hues (left to right in tenths: red, orange, yellow, lime, green, cyan, blue, violet, magenta, white), rows =
  light (top) to dark (bottom) in tenths. Replacing the texture file needs no plugin rebuild.

  Test in game (only RegaliaGarb1.esp ticked from ours; Test profile; "Garb of Mysteries Art" ticked):
    1. help "Garb of Mysteries" 4 ARMO, player.additem <ID> 1, equip it.
    2. Take keyboard screenshots: front, back, left side, right side (and a close-up of the chest), in daylight if you can.
    3. Tell me: does the dress show the coloured columns at all (a pink or plain sequin dress means the swap or the loose files did not load)?
       Which hue is on the front of the chest? Which on the back? Is the top band (where the collar would be) a separate colour?
    4. Does it fit the male and female body (if you test both)?

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildGarbTest.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaGarb1 in the filename box. Accept the save prompt when xEdit closes. Run it ONCE.
  Log: our-scripts\build.log.
}
unit BuildGarbTest;

const
  PLUGIN_HINT = 'RegaliaGarb1';
  MSWP_EDID = 'MoM_MSWP_GarbStripes';
  MAT_ORIGINAL = 'Clothes\SlinkyDress\SequinDress.BGSM';
  MAT_REPLACEMENT = 'Clothes\GarbOfMysteries\GarbOfMysteries.BGSM';
  ARMA_EDID = 'MoM_ARMA_Garb';
  ARMO_EDID = 'MoM_ARMO_GarbTest';
  ARMO_NAME = 'Garb of Mysteries (look test)';
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

// The material swap record: original material -> replacement material.
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

// Set (adding it if missing) a material swap subrecord inside a biped model block of the addon.
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

function Initialize: integer;
var
  esm, srcArmo, srcArma, f, mswp, arma, armo, models, m0: IInterface;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    srcArmo := RecordByFormID(esm, $0011A27B, True);   // ClothesSequinDress
    srcArma := RecordByFormID(esm, $0011A27A, True);   // AAClothesSequinDress
    if (not Assigned(srcArmo)) or (not Assigned(srcArma)) then begin
      Say('FAIL: source records not found (ClothesSequinDress 0011A27B / AAClothesSequinDress 0011A27A)'); Exit;
    end;
    Say('sources: ' + Name(srcArmo) + ' | ' + Name(srcArma));

    Say('Type ' + PLUGIN_HINT + ' in the filename box.');
    f := AddNewFile;
    if not Assigned(f) then begin
      Say('FAIL: no file created (cancelled, or the name already exists in Data?)'); Exit;
    end;
    Say('new file: ' + GetFileName(f));
    AddMasterIfMissing(f, 'Fallout4.esm');

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

    armo := wbCopyElementToFile(srcArmo, f, True, True);
    if not Assigned(armo) then begin
      Say('FAIL: copy of the Sequin Dress failed'); Exit;
    end;
    SetEditorID(armo, ARMO_EDID);
    SetElementEditValues(armo, 'FULL', ARMO_NAME);
    models := ElementByName(armo, 'Models');
    if (not Assigned(models)) or (ElementCount(models) < 1) then begin
      Say('FAIL: the dress copy has no Models (armature) list'); Exit;
    end;
    m0 := ElementByIndex(models, 0);
    Say('  armature was: ' + GetElementEditValues(m0, 'MODL - Armor Addon'));
    SetElementNativeValues(m0, 'MODL - Armor Addon', FormID(arma));
    Say('  armature now: ' + GetElementEditValues(m0, 'MODL - Armor Addon'));
    Say('dress: ' + Name(armo));

    log.Add('');
    log.Add('===== material swap dump');
    Dump(mswp, '');
    log.Add('');
    log.Add('===== addon dump');
    Dump(arma, '');
    log.Add('');
    log.Add('===== dress dump');
    Dump(armo, '');
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
