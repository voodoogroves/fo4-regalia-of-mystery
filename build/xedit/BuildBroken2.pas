{
  BuildBroken2.pas: TEST build, round 18 (the Tattered Dress, the Broken Veil, and their two repair recipes). Status: VERIFIED in game (2026-11-24).

  Decisions (Chris, 2026-11-24): every regalia piece is found broken and repaired; the Tattered Dress must stand out (faded chevrons, grime); the Broken Veil
  is our own ARMO copy of the Surgical Mask; the Veil's skill gate is Chemist 3; the Garb's is Armorer 3; each recipe also needs the Cryptos Notes perk.

  What it builds (plugin RegaliaBroken2.esp; masters Fallout4.esm, RegaliaGold1.esp, RegaliaGarb2.esp, RegaliaVeil1.esp):
    MSWP MoM_MSWP_TatteredDress   Clothes\SlinkyDress\SequinDress.BGSM -> Clothes\GarbOfMysteries\TatteredDress.BGSM (art mod "Garb of Mysteries Art")
    ARMA MoM_ARMA_TatteredDress   copy of AAClothesSequinDress with MO2S and MO3S = that swap
    ARMO MoM_ARMO_TatteredDress   "Tattered Dress": copy of the Sequin Dress, our armature, no enchantment, no resistances, armor rating 0, underarmor slots
    ARMO MoM_ARMO_BrokenVeil      "Broken Veil of Secrets": copy of the Surgical Mask (vanilla look), unscrappable keyword
    COBJ MoM_COBJ_RepairGarb      Tattered Dress + Cloth 6 + Adhesive 2 + Silver 1 -> Garb of Mysteries (RegaliaGarb2); HasPerk Cryptos Notes + Armorer03
    COBJ MoM_COBJ_RepairVeil      Broken Veil + Cloth 3 + Adhesive 2 + Silver 2 -> Veil of Secrets (RegaliaVeil1); HasPerk Cryptos Notes + Chemist03
  FormIDs of records in other plugins are converted with LoadOrderFormIDtoFileFormID (see Alexandria memory/fo4-xedit-reference.md).

  IN THE MODULE LIST tick Fallout4.esm, ALL SIX DLC, RegaliaGold1.esp, RegaliaGarb2.esp and RegaliaVeil1.esp, then OK.

  Test in game (RegaliaGold1, Garb2, Veil1, Broken2 ticked; "Garb of Mysteries Art" and "Veil of Secrets Art" enabled):
    1. help "Tattered Dress" 4 ARMO, player.additem <ID> 1: wear it. Does it stand out (green chevrons, grimy body, yellowed cowl)? Do chest/leg armor go over it?
    2. help "Broken Veil" 4 ARMO, player.additem <ID> 1: wear it (the plain surgical mask).
    3. With the Cryptos book read and Armorer 3 / Chemist 3 (player.addperk), the repair recipes at a Chemistry Station: each shows exactly two perk prerequisites,
       greyed until met; crafting consumes the broken item and gives the Garb / the Veil (the real ones, with their effects).

  Run from MO2 (FO4Edit BUILD entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildBroken2.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Type RegaliaBroken2 in the filename box. Accept the save prompt when xEdit closes. Run it ONCE.
  Log: our-scripts\build.log.
}
unit BuildBroken2;

const
  PLUGIN_HINT = 'RegaliaBroken2';
  GOLD_PLUGIN = 'RegaliaGold1.esp';
  GARB_PLUGIN = 'RegaliaGarb2.esp';
  VEIL_PLUGIN = 'RegaliaVeil1.esp';
  MSWP_EDID = 'MoM_MSWP_TatteredDress';
  ARMA_EDID = 'MoM_ARMA_TatteredDress';
  DRESS_EDID = 'MoM_ARMO_TatteredDress';
  DRESS_NAME = 'Tattered Dress';
  DRESS_DESC = 'A torn, filthy dress that was once fine: faded green chevrons still show through the grime. Someone cared about this. It could be mended at a Chemistry Station by a good armorer who has read the Cryptos notes.';
  MAT_ORIGINAL = 'Clothes\SlinkyDress\SequinDress.BGSM';
  MAT_REPLACEMENT = 'Clothes\GarbOfMysteries\TatteredDress.BGSM';
  VEIL_EDID = 'MoM_ARMO_BrokenVeil';
  VEIL_NAME = 'Broken Veil of Secrets';
  VEIL_DESC = 'A stained, frayed mask with threads of black lace still caught in it. A chemist who has read the Cryptos notes could rebuild it at a Chemistry Station.';
  GARB_EDID = 'MoM_ARMO_Garb';
  VEILREAL_EDID = 'MoM_ARMO_Veil';
  CRYPTOS_EDID = 'MoM_PERK_Cryptos';
  GARBCOBJ_EDID = 'MoM_COBJ_RepairGarb';
  VEILCOBJ_EDID = 'MoM_COBJ_RepairVeil';
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

function Initialize: integer;
var
  esm, gold, garb, veil, srcDress, srcArma, srcMask, perkArmorer, perkChemist, cryptos, garbArmo, veilArmo: IInterface;
  f, mswp, arma, dress, bveil, models, m0, el, ck, dama, cg, cv, cc: IInterface;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    srcDress := RecordByFormID(esm, $0011A27B, True);   // ClothesSequinDress
    srcArma := RecordByFormID(esm, $0011A27A, True);    // AAClothesSequinDress
    srcMask := RecordByFormID(esm, $000787DA, True);    // Clothes_Raider_SurgicalMask
    perkArmorer := MainRecordByEditorID(GroupBySignature(esm, 'PERK'), 'Armorer03');
    perkChemist := MainRecordByEditorID(GroupBySignature(esm, 'PERK'), 'Chemist03');
    if (not Assigned(srcDress)) or (not Assigned(srcArma)) or (not Assigned(srcMask)) or (not Assigned(perkArmorer)) or (not Assigned(perkChemist)) then begin
      Say('FAIL: a vanilla source record was not found (Sequin Dress, its addon, Surgical Mask, perks Armorer03 / Chemist03 by editor ID)'); Exit;
    end;
    gold := FindFile(GOLD_PLUGIN);
    garb := FindFile(GARB_PLUGIN);
    veil := FindFile(VEIL_PLUGIN);
    if (not Assigned(gold)) or (not Assigned(garb)) or (not Assigned(veil)) then begin
      Say('FAIL: tick ' + GOLD_PLUGIN + ', ' + GARB_PLUGIN + ' and ' + VEIL_PLUGIN + ' (and the six DLC) in the module list'); Exit;
    end;
    cryptos := FindIn(gold, 'PERK', CRYPTOS_EDID);
    garbArmo := FindIn(garb, 'ARMO', GARB_EDID);
    veilArmo := FindIn(veil, 'ARMO', VEILREAL_EDID);
    if (not Assigned(cryptos)) or (not Assigned(garbArmo)) or (not Assigned(veilArmo)) then Exit;
    Say('sources ok: ' + Name(perkArmorer) + ' | ' + Name(perkChemist) + ' | ' + Name(cryptos) + ' | ' + Name(garbArmo) + ' | ' + Name(veilArmo));

    Say('Type ' + PLUGIN_HINT + ' in the filename box.');
    f := AddNewFile;
    if not Assigned(f) then begin
      Say('FAIL: no file created (cancelled, or the name already exists in Data?)'); Exit;
    end;
    Say('new file: ' + GetFileName(f));
    AddMasterIfMissing(f, 'Fallout4.esm');
    AddMasterIfMissing(f, GOLD_PLUGIN);
    AddMasterIfMissing(f, GARB_PLUGIN);
    AddMasterIfMissing(f, VEIL_PLUGIN);

    // ---- the Tattered Dress ----
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

    dress := wbCopyElementToFile(srcDress, f, True, True);
    if not Assigned(dress) then begin
      Say('FAIL: copy of the Sequin Dress failed'); Exit;
    end;
    SetEditorID(dress, DRESS_EDID);
    SetElementEditValues(dress, 'FULL', DRESS_NAME);
    SetElementEditValues(dress, 'DESC', DRESS_DESC);
    el := ElementBySignature(dress, 'EITM');
    if Assigned(el) then begin
      Say('  removing enchantment: ' + GetEditValue(el));
      Remove(el);
    end;
    models := ElementByName(dress, 'Models');
    if (not Assigned(models)) or (ElementCount(models) < 1) then begin
      Say('FAIL: the dress copy has no Models (armature) list'); Exit;
    end;
    m0 := ElementByIndex(models, 0);
    SetElementNativeValues(m0, 'MODL - Armor Addon', FormID(arma));
    Say('  armature now: ' + GetElementEditValues(m0, 'MODL - Armor Addon'));
    SetElementNativeValues(dress, 'FNAM\Armor Rating', 0);
    SetElementNativeValues(dress, 'DATA\Value', 5);
    SetElementNativeValues(dress, 'DATA\Weight', 1.0);
    SetElementNativeValues(dress, 'BOD2\First Person Flags', 1992);   // underarmor slots 33, 36 to 40, as the Garb
    dama := ElementBySignature(dress, 'DAMA');
    if Assigned(dama) then begin
      Say('  removing resistances: ' + IntToStr(ElementCount(dama)));
      Remove(dama);
    end;
    ck := ElementBySignature(dress, 'KWDA');
    if not Assigned(ck) then ck := Add(dress, 'KWDA', True);
    el := ElementAssign(ck, HighInteger, nil, False);
    SetNativeValue(el, $001CC46A);   // UnscrappableObject
    Say('  slots ' + GetElementEditValues(dress, 'BOD2\First Person Flags') + ', armor rating ' + GetElementEditValues(dress, 'FNAM\Armor Rating') + ', value ' + GetElementEditValues(dress, 'DATA\Value'));
    Say('dress: ' + Name(dress));

    // ---- the Broken Veil ----
    bveil := wbCopyElementToFile(srcMask, f, True, True);
    if not Assigned(bveil) then begin
      Say('FAIL: copy of the Surgical Mask failed'); Exit;
    end;
    SetEditorID(bveil, VEIL_EDID);
    SetElementEditValues(bveil, 'FULL', VEIL_NAME);
    SetElementEditValues(bveil, 'DESC', VEIL_DESC);
    el := ElementBySignature(bveil, 'EITM');
    if Assigned(el) then begin
      Say('  removing enchantment: ' + GetEditValue(el));
      Remove(el);
    end;
    SetElementNativeValues(bveil, 'FNAM\Armor Rating', 0);
    SetElementNativeValues(bveil, 'DATA\Value', 5);
    ck := ElementBySignature(bveil, 'KWDA');
    if not Assigned(ck) then ck := Add(bveil, 'KWDA', True);
    el := ElementAssign(ck, HighInteger, nil, False);
    SetNativeValue(el, $001CC46A);   // UnscrappableObject
    Say('  slots ' + GetElementEditValues(bveil, 'BOD2\First Person Flags') + ', keywords ' + IntToStr(ElementCount(ck)));
    Say('broken veil: ' + Name(bveil));

    // ---- the repair recipes ----
    cg := MakeRecipe(f, GARBCOBJ_EDID, garbArmo);
    if not Assigned(cg) then Exit;
    cc := ElementBySignature(cg, 'FVPA');
    AddComponent(f, cc, FormID(dress), 1);
    AddComponent(f, cc, $001223C7, 6);   // Cloth
    AddComponent(f, cc, $0001FAA5, 2);   // Adhesive
    AddComponent(f, cc, $0001FABB, 1);   // Silver
    if not AddHasPerkCondition(f, cg, cryptos) then Exit;
    if not AddHasPerkCondition(f, cg, perkArmorer) then Exit;
    Say('recipe: ' + Name(cg));

    cv := MakeRecipe(f, VEILCOBJ_EDID, veilArmo);
    if not Assigned(cv) then Exit;
    cc := ElementBySignature(cv, 'FVPA');
    AddComponent(f, cc, FormID(bveil), 1);
    AddComponent(f, cc, $001223C7, 3);   // Cloth
    AddComponent(f, cc, $0001FAA5, 2);   // Adhesive
    AddComponent(f, cc, $0001FABB, 2);   // Silver
    if not AddHasPerkCondition(f, cv, cryptos) then Exit;
    if not AddHasPerkCondition(f, cv, perkChemist) then Exit;
    Say('recipe: ' + Name(cv));

    log.Add('');
    log.Add('===== dress dump');
    Dump(dress, '');
    log.Add('');
    log.Add('===== broken veil dump');
    Dump(bveil, '');
    log.Add('');
    log.Add('===== garb recipe dump');
    Dump(cg, '');
    log.Add('');
    log.Add('===== veil recipe dump');
    Dump(cv, '');
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
