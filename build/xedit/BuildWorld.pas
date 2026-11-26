{
  BuildWorld.pas: the last plugin of the test chain (latest: RegaliaWorld10). Full description: docs\build-spec.md.
  Builds the Mysterious Traveler and her two books, four containers, the Cryptos picture and reading page, the "Mystery: ..." names,
  the plain broken Dress and Veil with their recipe overrides, and the Voice and Garb Eye changes.
  Status 2026-11-26: built as RegaliaWorld10; what has and has not been seen in game is in the build spec, section 3.6.

  Masters: Fallout4.esm, DLCNukaWorld.esm, RegaliaGold1, Garb2, Veil1, Broken2, Voice12. IN THE MODULE LIST tick the game, the six DLC
  and those five Regalia plugins only. Type a NEW name (RegaliaWorld11, ...) in the filename box. Close xEdit and accept the save.
  Log: our-scripts\build.log. Test with every other RegaliaWorld, RegaliaBody, RegaliaPose and RegaliaBook plugin unticked.
}
unit BuildWorld;

const
  PLUGIN_HINT = 'RegaliaWorld11';
  GARB_RESIST = 30;                        // damage and energy resistance of the dress itself
  GARB_EYE_RESIST = 40;                    // added to both with the Eye
  GARB_DESC = 'A sequined dress in charcoal, edged in emerald and cream-gold, cut for quiet work. You are harder to notice while sneaking and your steps fall softer. Worn with the Eye of Ra, it turns blows aside and you slip past nearly everyone.';
  BURST_CHANCE = 50;                       // percent, with the Eye
  BOOK_NAME = 'Mystery: Cryptos';
  PAGE_ORIGINAL = 'Interface\Note\Note.BGSM';
  PAGE_REPLACEMENT = 'RegaliaOfMystery\CryptosPage.BGSM';
  CRYPTOS_FILE = 'Z:\home\deck\Repos\fo4-regalia-of-mystery\docs\cryptos-text.md';
  MAT_ORIGINAL = 'Interface\Note\PhotoHorizLowPolySilverShroud.BGSM';
  MAT_REPLACEMENT = 'RegaliaOfMystery\CryptosSketch.BGSM';
  HAIR_ID = $0016CA35;                     // HairFemale08 "No Apologies"
  DIARY_NAME = 'Mystery: Traveler''s Diary';
  NPC_NAME = 'Mysterious Traveler';
  DIARY_FILE = 'Z:\home\deck\Repos\fo4-regalia-of-mystery\docs\diary-text.md';
  LOG_FILE = 'Z:\home\deck\Games\mo2-lint\tools\our-scripts\build.log';
  POS_X = '5514.07';
  POS_Y = '-18598.39';
  POS_Z = '1820.00';                      // player stood at 1804.36
  ROT_Z = '0';

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
  if (Pos('Model Information', n) > 0) or (Pos('Face Morph', n) > 0) or (Pos('Face Tinting', n) > 0) then
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

function FindOurs(plugname, sig, edid: string): IInterface;
var
  plug: IInterface;
begin
  Result := nil;
  plug := FindFile(plugname);
  if not Assigned(plug) then begin
    Say('FAIL: tick ' + plugname + ' in the module list'); Exit;
  end;
  Result := MainRecordByEditorID(GroupBySignature(plug, sig), edid);
  if not Assigned(Result) then Say('FAIL: ' + sig + ' ' + edid + ' not found in ' + plugname);
end;

// The number to write for a record: its own FormID if it lives in the file being built, else the file-local number mapped from its load-order ID.
function Ref(f, rec: IInterface): integer;
begin
  if GetFileName(GetFile(rec)) = GetFileName(f) then Result := FormID(rec)
  else Result := LoadOrderFormIDtoFileFormID(f, GetLoadOrderFormID(rec));
end;

// Write a FormID into an element and check it reads back as the record we meant.
function SetRef(el, f, rec: IInterface): boolean;
begin
  Result := False;
  if not Assigned(el) then begin
    Say('FAIL: missing element for ' + EditorID(rec)); Exit;
  end;
  SetNativeValue(el, Ref(f, rec));
  Say('  reference written: ' + GetEditValue(el));
  Result := Pos(EditorID(rec), GetEditValue(el)) > 0;
  if not Result then Say('FAIL: expected ' + EditorID(rec));
end;

function AddItem(f, npc, item: IInterface): boolean;
var
  items, entry: IInterface;
begin
  items := ElementByName(npc, 'Items');
  if not Assigned(items) then begin
    items := Add(npc, 'Items', True);
    entry := ElementByIndex(items, 0);
  end else
    entry := ElementAssign(items, HighInteger, nil, False);
  Result := SetRef(ElementByPath(entry, 'CNTO\Item'), f, item);
  SetElementNativeValues(entry, 'CNTO\Count', 1);
end;

// Swap the template's hair (and hairlines) for HAIR_ID and its extra parts.
function SetHair(f, npc, hairpart: IInterface): boolean;
var
  parts, extras, el, extra: IInterface;
  i, removed: integer;
begin
  Result := False;
  parts := ElementByName(npc, 'Head Parts');
  if not Assigned(parts) then begin
    Say('FAIL: no Head Parts on the corpse'); Exit;
  end;
  removed := 0;
  for i := ElementCount(parts) - 1 downto 0 do
    if Pos('HairFemale', GetEditValue(ElementByIndex(parts, i))) = 1 then begin
      Remove(ElementByIndex(parts, i));
      removed := removed + 1;
    end;
  Say('  hair parts removed: ' + IntToStr(removed));
  el := ElementAssign(parts, HighInteger, nil, False);
  if not SetRef(el, f, hairpart) then Exit;
  extras := ElementByName(hairpart, 'Extra Parts');
  if Assigned(extras) then
    for i := 0 to ElementCount(extras) - 1 do begin
      extra := LinksTo(ElementByIndex(extras, i));
      el := ElementAssign(parts, HighInteger, nil, False);
      if not SetRef(el, f, extra) then Exit;
    end;
  Result := removed > 0;
  if not Result then Say('FAIL: no template hair was found to replace');
end;

// Place the actor once with the saved pose of a vanilla placement.
function PlaceBody(f, cell, npc: IInterface; poseid: integer; number: integer; hidden: boolean): boolean;
var
  achr, srcPose, pose: IInterface;
  flags: integer;
begin
  Result := False;
  srcPose := RecordByFormID(FileByIndex(0), poseid, True);
  if not Assigned(srcPose) then begin
    Say('FAIL: pose source ' + IntToHex(poseid, 8) + ' not found'); Exit;
  end;
  achr := Add(cell, 'ACHR', True);
  if not Assigned(achr) then begin
    Say('FAIL: could not add the placed actor to the cell'); Exit;
  end;
  if not Assigned(ElementBySignature(achr, 'NAME')) then Add(achr, 'NAME', True);
  if not SetRef(ElementBySignature(achr, 'NAME'), f, npc) then Exit;
  if not Assigned(ElementBySignature(achr, 'DATA')) then Add(achr, 'DATA', True);
  SetElementEditValues(achr, 'DATA\Position\X', POS_X);
  SetElementEditValues(achr, 'DATA\Position\Y', POS_Y);
  SetElementEditValues(achr, 'DATA\Position\Z', POS_Z);
  SetElementEditValues(achr, 'DATA\Rotation\Z', ROT_Z);
  flags := $200;                          // Starts Dead
  if hidden then flags := flags or $800;  // Initially Disabled
  SetElementNativeValues(achr, 'Record Header\Record Flags', GetElementNativeValues(achr, 'Record Header\Record Flags') or flags);
  pose := ElementBySignature(srcPose, 'XRGD');
  if not Assigned(pose) then begin
    Say('FAIL: no saved pose on the source'); Exit;
  end;
  wbCopyElementToRecord(pose, achr, False, True);
  pose := ElementBySignature(srcPose, 'XRGB');
  if Assigned(pose) then wbCopyElementToRecord(pose, achr, False, True);
  if (not Assigned(ElementBySignature(achr, 'XRGD'))) or ((GetElementNativeValues(achr, 'Record Header\Record Flags') and flags) <> flags) then begin
    Say('FAIL: pose ' + IntToStr(number) + ' was not set up'); Exit;
  end;
  Say('POSE ' + IntToStr(number) + ': reference ' + IntToHex(FormID(achr), 8) + ' from ' + IntToHex(poseid, 8) + ' | flags ' + IntToHex(flags, 4));
  Result := True;
end;

// Put the material swap on a record's model.
function SetModelSwap(f, r, mswp: IInterface): boolean;
var
  model, el: IInterface;
begin
  Result := False;
  model := ElementByName(r, 'Model');
  if not Assigned(model) then begin
    Say('FAIL: no Model on ' + EditorID(r)); Exit;
  end;
  el := ElementBySignature(model, 'MODS');
  if not Assigned(el) then el := Add(model, 'MODS', True);
  Result := SetRef(el, f, mswp);
end;

// The Cryptos book: our sketch (swap on the model and on a new inventory preview) and the new text.
function BuildBook(f, srcBook, srcStat: IInterface): boolean;
var
  mswp, subs, sub, stat, book: IInterface;
  text: TStringList;
begin
  Result := False;
  mswp := Add(Add(f, 'MSWP', True), 'MSWP', True);
  if not Assigned(mswp) then begin
    Say('FAIL: could not create the material swap'); Exit;
  end;
  SetEditorID(mswp, 'MoM_MSWP_CryptosSketch');
  subs := Add(mswp, 'Material Substitutions', True);
  if ElementCount(subs) = 0 then sub := ElementAssign(subs, HighInteger, nil, False)
  else sub := ElementByIndex(subs, 0);
  SetElementEditValues(sub, 'BNAM - Original Material', MAT_ORIGINAL);
  SetElementEditValues(sub, 'SNAM - Replacement Material', MAT_REPLACEMENT);
  if (ElementCount(subs) <> 1) or (GetElementEditValues(sub, 'SNAM - Replacement Material') <> MAT_REPLACEMENT) then begin
    Say('FAIL: the substitution is wrong'); Exit;
  end;
  sub := ElementAssign(subs, HighInteger, nil, False);
  SetElementEditValues(sub, 'BNAM - Original Material', PAGE_ORIGINAL);
  SetElementEditValues(sub, 'SNAM - Replacement Material', PAGE_REPLACEMENT);
  if (ElementCount(subs) <> 2) or (GetElementEditValues(sub, 'SNAM - Replacement Material') <> PAGE_REPLACEMENT) then begin
    Say('FAIL: the page substitution is wrong'); Exit;
  end;
  stat := wbCopyElementToFile(srcStat, f, True, True);
  if not Assigned(stat) then begin
    Say('FAIL: copy of the preview STAT failed'); Exit;
  end;
  SetEditorID(stat, 'MoM_STAT_CryptosSketch');
  Say('  preview mesh: ' + GetElementEditValues(stat, 'Model\MODL - Model FileName'));
  if not SetModelSwap(f, stat, mswp) then Exit;
  book := wbCopyElementToFile(srcBook, f, False, True);   // False: an override of our book
  if not Assigned(book) then begin
    Say('FAIL: override of the Cryptos book failed'); Exit;
  end;
  if not SetModelSwap(f, book, mswp) then Exit;
  if not SetRef(ElementBySignature(book, 'INAM'), f, stat) then Exit;
  SetElementEditValues(book, 'FULL', BOOK_NAME);
  Say('  book name: ' + GetElementEditValues(book, 'FULL'));
  text := TStringList.Create;
  text.LoadFromFile(CRYPTOS_FILE);
  SetElementEditValues(book, 'DESC', Trim(text.Text));
  text.Free;
  Say('  book text length ' + IntToStr(Length(GetElementEditValues(book, 'DESC'))) + ' | teaches: ' + GetElementEditValues(book, 'DNAM\Teaches'));
  if (Pos('THE VOICE OF SET', GetElementEditValues(book, 'DESC')) = 0) or (Pos('MoM_PERK_Cryptos', GetElementEditValues(book, 'DNAM\Teaches')) = 0) then begin
    Say('FAIL: the book text or perk is wrong'); Exit;
  end;
  Result := True;
end;

// A container of our own: a vanilla look, no respawn, exactly one item.
function MakeContainer(f: IInterface; srcid: integer; edid, title: string; item: IInterface): IInterface;
var
  src, c, el, flags: IInterface;
begin
  Result := nil;
  src := RecordByFormID(FileByIndex(0), srcid, True);
  if not Assigned(src) then begin
    Say('FAIL: container ' + IntToHex(srcid, 8) + ' not found'); Exit;
  end;
  c := wbCopyElementToFile(src, f, True, True);
  if not Assigned(c) then begin
    Say('FAIL: copy of the container failed for ' + edid); Exit;
  end;
  SetEditorID(c, edid);
  SetElementEditValues(c, 'FULL', title);
  el := ElementBySignature(c, 'VMAD');
  if Assigned(el) then Remove(el);
  el := ElementByName(c, 'Items');
  if Assigned(el) then Remove(el);
  if not AddItem(f, c, item) then Exit;
  flags := ElementByPath(c, 'DATA\Flags');
  if not Assigned(flags) then begin
    Say('FAIL: no container flags on ' + edid); Exit;
  end;
  SetNativeValue(flags, GetNativeValue(flags) and $FD);   // bit 1 = Respawns
  Say('  ' + edid + ': items ' + IntToStr(ElementCount(ElementByName(c, 'Items'))) + ', count field ' + GetElementEditValues(c, 'COCT') + ', flags ' + IntToStr(GetNativeValue(flags)));
  if (ElementCount(ElementByName(c, 'Items')) <> 1) or ((GetNativeValue(flags) and 2) <> 0) then begin
    Say('FAIL: ' + edid + ' still respawns or has the wrong contents'); Exit;
  end;
  Result := c;
end;

// Our skin: a material swap from the mesh's material to ours (art/make_containers.py). model <> '' also changes the mesh.
function Skin(f, c: IInterface; ours, original, model: string): IInterface;
var
  mswp, subs, sub, el: IInterface;
  repl: string;
begin
  Result := nil;
  if not Assigned(c) then Exit;
  if model <> '' then begin
    SetElementEditValues(c, 'Model\MODL - Model FileName', model);
    el := ElementByPath(c, 'Model\MODT - Model Information');
    if Assigned(el) then Remove(el);
    if GetElementEditValues(c, 'Model\MODL - Model FileName') <> model then begin
      Say('FAIL: the model was not changed on ' + EditorID(c)); Exit;
    end;
  end;
  mswp := Add(Add(f, 'MSWP', True), 'MSWP', True);
  if not Assigned(mswp) then begin
    Say('FAIL: could not create the material swap for ' + ours); Exit;
  end;
  SetEditorID(mswp, 'MoM_MSWP_' + ours);
  subs := Add(mswp, 'Material Substitutions', True);
  if ElementCount(subs) = 0 then sub := ElementAssign(subs, HighInteger, nil, False)
  else sub := ElementByIndex(subs, 0);
  repl := 'RegaliaOfMystery\' + ours + '.BGSM';
  SetElementEditValues(sub, 'BNAM - Original Material', original);
  SetElementEditValues(sub, 'SNAM - Replacement Material', repl);
  Say('  skin ' + ours + ': ' + GetElementEditValues(sub, 'BNAM - Original Material') + ' -> ' + GetElementEditValues(sub, 'SNAM - Replacement Material'));
  if (ElementCount(subs) <> 1) or (GetElementEditValues(sub, 'SNAM - Replacement Material') <> repl) then begin
    Say('FAIL: the substitution is wrong for ' + ours); Exit;
  end;
  if not SetModelSwap(f, c, mswp) then Exit;
  Result := c;
end;

// Give one of our items a new display name: an override in this plugin; the record itself keeps its FormID, so recipes are untouched.
function Rename(f, rec: IInterface; title: string): boolean;
var
  o: IInterface;
begin
  Result := False;
  o := wbCopyElementToFile(rec, f, False, True);   // False: an override
  if not Assigned(o) then begin
    Say('FAIL: override failed for ' + EditorID(rec)); Exit;
  end;
  SetElementEditValues(o, 'FULL', title);
  Say('RENAMED ' + EditorID(o) + ' -> ' + GetElementEditValues(o, 'FULL'));
  Result := GetElementEditValues(o, 'FULL') = title;
  if not Result then Say('FAIL: the name was not set on ' + EditorID(rec));
end;

// A broken piece as a plain, non-wearable item: copy of the Silver Locket with our name and world model, never scrappable.
function MakeBroken(f: IInterface; edid, title, model: string): IInterface;
var
  src, m, el, kw: IInterface;
begin
  Result := nil;
  src := RecordByFormID(FileByIndex(0), $00059B34, True);   // SilverLocket (MISC)
  if not Assigned(src) then begin
    Say('FAIL: the Silver Locket was not found'); Exit;
  end;
  m := wbCopyElementToFile(src, f, True, True);
  if not Assigned(m) then begin
    Say('FAIL: copy of the locket failed for ' + edid); Exit;
  end;
  SetEditorID(m, edid);
  SetElementEditValues(m, 'FULL', title);
  SetElementEditValues(m, 'Model\MODL - Model FileName', model);
  el := ElementByPath(m, 'Model\MODT - Model Information');
  if Assigned(el) then Remove(el);
  el := ElementBySignature(m, 'CVPA');
  if Assigned(el) then Remove(el);
  kw := ElementBySignature(m, 'KWDA');
  if not Assigned(kw) then kw := Add(m, 'KWDA', True);
  el := ElementAssign(kw, HighInteger, nil, False);
  SetNativeValue(el, $001CC46A);   // UnscrappableObject
  Say('broken item: ' + Name(m) + ' | model ' + GetElementEditValues(m, 'Model\MODL - Model FileName'));
  if (GetElementEditValues(m, 'FULL') <> title) or (GetElementEditValues(m, 'Model\MODL - Model FileName') <> model) then begin
    Say('FAIL: ' + edid + ' was not set up'); Exit;
  end;
  Result := m;
end;

// Point one of our repair recipes at a new ingredient (an override of the recipe; exactly one component must change).
function SwapIngredient(f, recipe, olditem, newitem: IInterface): boolean;
var
  o, comps, el: IInterface;
  i, changed: integer;
begin
  Result := False;
  o := wbCopyElementToFile(recipe, f, False, True);   // False: an override
  if not Assigned(o) then begin
    Say('FAIL: override of the recipe failed'); Exit;
  end;
  comps := ElementBySignature(o, 'FVPA');
  changed := 0;
  for i := 0 to ElementCount(comps) - 1 do begin
    el := ElementByName(ElementByIndex(comps, i), 'Component');
    if Pos(EditorID(olditem), GetEditValue(el)) > 0 then begin
      if not SetRef(el, f, newitem) then Exit;
      changed := changed + 1;
    end;
  end;
  for i := 0 to ElementCount(comps) - 1 do
    Say('  ' + EditorID(o) + ' ingredient: ' + GetEditValue(ElementByName(ElementByIndex(comps, i), 'Component')) + ' x ' + GetElementEditValues(ElementByIndex(comps, i), 'Count'));
  Say('  ' + EditorID(o) + ' makes: ' + GetElementEditValues(o, 'CNAM'));
  Result := changed = 1;
  if not Result then Say('FAIL: expected exactly one ingredient to change on ' + EditorID(o) + ', changed ' + IntToStr(changed));
end;

// An enchantment on the sonic burst: our copy of the legendary stagger enchantment cut to one effect, whose two conditions become
// "the one caught is not the player" and "the player wears the Eye of Ra". The burst itself keeps its 0 damage.
function BurstStagger(f, srcburst, eyekw: IInterface): boolean;
var
  src, ench, effs, conds, ctda, burst, el: IInterface;
  i: integer;
begin
  Result := False;
  src := RecordByFormID(FileByIndex(0), $0023AD16, True);   // ench_mod_LegendaryChanceToStagger
  if not Assigned(src) then begin
    Say('FAIL: the legendary stagger enchantment was not found'); Exit;
  end;
  ench := wbCopyElementToFile(src, f, True, True);
  if not Assigned(ench) then begin
    Say('FAIL: copy of the stagger enchantment failed'); Exit;
  end;
  SetEditorID(ench, 'MoM_ENCH_BurstStagger');
  effs := ElementByName(ench, 'Effects');
  while ElementCount(effs) > 1 do
    Remove(ElementByIndex(effs, ElementCount(effs) - 1));
  conds := ElementByName(ElementByIndex(effs, 0), 'Conditions');
  if not Assigned(conds) then begin
    Say('FAIL: no condition list on the effect'); Exit;
  end;
  while ElementCount(conds) > 2 do
    Remove(ElementByIndex(conds, ElementCount(conds) - 1));
  while ElementCount(conds) < 3 do ElementAssign(conds, HighInteger, nil, False);
  // 0: the one caught is not the player
  ctda := ElementBySignature(ElementByIndex(conds, 0), 'CTDA');
  SetElementEditValues(ctda, 'Function', 'GetIsID');
  SetElementNativeValues(ctda, 'Type', 0);                 // equal to, no Or
  SetElementNativeValues(ctda, 'Parameter #1', $00000007);  // the Player base record
  SetElementNativeValues(ctda, 'Comparison Value', 0);
  SetElementEditValues(ctda, 'Run On', 'Subject');
  // 1: the player wears the Eye of Ra
  ctda := ElementBySignature(ElementByIndex(conds, 1), 'CTDA');
  SetElementEditValues(ctda, 'Function', 'WornHasKeyword');
  SetElementNativeValues(ctda, 'Type', 0);
  SetElementNativeValues(ctda, 'Parameter #1', Ref(f, eyekw));
  SetElementNativeValues(ctda, 'Comparison Value', 1);
  SetElementEditValues(ctda, 'Run On', 'Reference');
  SetElementNativeValues(ctda, 'Reference', $00000014);     // PlayerRef
  // 2: the chance
  ctda := ElementBySignature(ElementByIndex(conds, 2), 'CTDA');
  SetElementEditValues(ctda, 'Function', 'GetRandomPercent');
  SetElementNativeValues(ctda, 'Type', 160);               // less than or equal
  SetElementNativeValues(ctda, 'Comparison Value', BURST_CHANCE);
  SetElementEditValues(ctda, 'Run On', 'Subject');
  if (GetElementEditValues(ctda, 'Function') <> 'GetRandomPercent') or (GetElementNativeValues(ctda, 'Type') <> 160) then begin
    Say('FAIL: the chance condition is wrong'); Exit;
  end;
  for i := 0 to ElementCount(conds) - 1 do begin
    ctda := ElementBySignature(ElementByIndex(conds, i), 'CTDA');
    Say('  burst condition ' + IntToStr(i) + ': ' + GetElementEditValues(ctda, 'Function') + ' ' + GetElementEditValues(ctda, 'Parameter #1') + ' | type ' + GetElementEditValues(ctda, 'Type') + ' value ' + GetElementEditValues(ctda, 'Comparison Value') + ' | run on ' + GetElementEditValues(ctda, 'Run On') + ' ' + GetElementEditValues(ctda, 'Reference'));
  end;
  Say('  burst enchantment: effects ' + IntToStr(ElementCount(effs)) + ', effect ' + GetElementEditValues(ElementByIndex(effs, 0), 'EFID - Base Effect') + ', magnitude ' + GetElementEditValues(ElementByIndex(effs, 0), 'EFIT\Magnitude'));
  ctda := ElementBySignature(ElementByIndex(conds, 1), 'CTDA');
  if (ElementCount(effs) <> 1) or (ElementCount(conds) <> 3) or (GetElementEditValues(ctda, 'Function') <> 'WornHasKeyword') or
     (Pos('MoM_EyeOfRa_KW', GetElementEditValues(ctda, 'Parameter #1')) = 0) or (GetElementNativeValues(ctda, 'Reference') <> $14) then begin
    Say('FAIL: the burst enchantment was not set up'); Exit;
  end;
  burst := wbCopyElementToFile(srcburst, f, False, True);   // False: an override of our explosion
  if not Assigned(burst) then begin
    Say('FAIL: override of the sonic burst failed'); Exit;
  end;
  el := ElementBySignature(burst, 'EITM');
  if not Assigned(el) then el := Add(burst, 'EITM', True);
  SetNativeValue(el, FormID(ench));
  Say('burst: enchantment ' + GetEditValue(el) + ', damage ' + GetElementEditValues(burst, 'DATA\Damage') + ', stagger ' + GetElementEditValues(burst, 'DATA\Stagger'));
  Result := (Pos('MoM_ENCH_BurstStagger', GetEditValue(el)) > 0) and (GetElementNativeValues(burst, 'DATA\Damage') = 0);
  if not Result then Say('FAIL: the burst override is wrong');
end;

// The Eye's earlier boost (a second 30% stagger roll on a hit) is replaced by the burst: make its chance condition impossible.
function DropSecondRoll(f, srcperk: IInterface): boolean;
var
  o, effs, pcs, conds, ctda: IInterface;
  i, j, k, changed: integer;
begin
  Result := False;
  o := wbCopyElementToFile(srcperk, f, False, True);   // False: an override
  if not Assigned(o) then begin
    Say('FAIL: override of the Voice Eye perk failed'); Exit;
  end;
  changed := 0;
  effs := ElementByName(o, 'Effects');
  for i := 0 to ElementCount(effs) - 1 do begin
    pcs := ElementByName(ElementByIndex(effs, i), 'Perk Conditions');
    for j := 0 to ElementCount(pcs) - 1 do begin
      conds := ElementByName(ElementByIndex(pcs, j), 'Conditions');
      for k := 0 to ElementCount(conds) - 1 do begin
        ctda := ElementBySignature(ElementByIndex(conds, k), 'CTDA');
        if GetElementEditValues(ctda, 'Function') = 'GetRandomPercent' then begin
          SetElementNativeValues(ctda, 'Comparison Value', -1);
          Say('  second roll off: GetRandomPercent type ' + GetElementEditValues(ctda, 'Type') + ' value ' + GetElementEditValues(ctda, 'Comparison Value'));
          changed := changed + 1;
        end;
      end;
    end;
  end;
  Result := changed = 1;
  if not Result then Say('FAIL: expected one chance condition on the Voice Eye perk, found ' + IntToStr(changed));
end;

// One "resistance while the Eye is worn" effect on the Garb's enchantment, built from the Stealth Move effect as the Veil's was.
function AddEyeResist(f, effs, eyekw: IInterface; effectid: integer; who: string): boolean;
var
  src, eff, conds, ctda: IInterface;
begin
  Result := False;
  src := RecordByFormID(FileByIndex(0), $00245BDE, True);   // enchArmorStealthMoveMod
  eff := ElementAssign(effs, HighInteger, ElementByIndex(ElementByName(src, 'Effects'), 0), False);
  if not Assigned(eff) then begin
    Say('FAIL: could not add the ' + who + ' effect'); Exit;
  end;
  SetElementNativeValues(eff, 'EFID - Base Effect', effectid);
  SetElementNativeValues(eff, 'EFIT\Magnitude', GARB_EYE_RESIST);
  conds := ElementByName(eff, 'Conditions');
  while ElementCount(conds) > 1 do
    Remove(ElementByIndex(conds, ElementCount(conds) - 1));
  ctda := ElementBySignature(ElementByIndex(conds, 0), 'CTDA');
  SetElementEditValues(ctda, 'Function', 'WornHasKeyword');
  SetElementNativeValues(ctda, 'Type', 0);
  SetElementNativeValues(ctda, 'Parameter #1', Ref(f, eyekw));
  SetElementNativeValues(ctda, 'Comparison Value', 1);
  Say('  ' + who + ': ' + GetElementEditValues(eff, 'EFID - Base Effect') + ' +' + GetElementEditValues(eff, 'EFIT\Magnitude') + ' if ' + GetElementEditValues(ctda, 'Function') + ' ' + GetElementEditValues(ctda, 'Parameter #1') + ' = ' + GetElementEditValues(ctda, 'Comparison Value') + ' (' + IntToStr(ElementCount(conds)) + ' condition)');
  Result := (GetElementNativeValues(eff, 'EFID - Base Effect') = effectid) and (ElementCount(conds) = 1) and (Pos('MoM_EyeOfRa_KW', GetElementEditValues(ctda, 'Parameter #1')) > 0);
  if not Result then Say('FAIL: the ' + who + ' effect is wrong');
end;

// The Garb: resistance moves partly into the Eye, no ballistic weave, smaller sneak attack boost. All three are overrides of our records.
function GarbEye(f, srcarmo, srcench, srcperk, eyekw: IInterface): boolean;
var
  armo, ench, perk, effs, dama, kwda, el, ee, epfd, val: IInterface;
  i, before, changed: integer;
  v: double;
  repl: string;
begin
  Result := False;
  armo := wbCopyElementToFile(srcarmo, f, False, True);
  ench := wbCopyElementToFile(srcench, f, False, True);
  perk := wbCopyElementToFile(srcperk, f, False, True);
  if (not Assigned(armo)) or (not Assigned(ench)) or (not Assigned(perk)) then begin
    Say('FAIL: override of the Garb records failed'); Exit;
  end;
  SetElementEditValues(armo, 'DESC', GARB_DESC);
  SetElementNativeValues(armo, 'FNAM\Armor Rating', GARB_RESIST);
  dama := ElementBySignature(armo, 'DAMA');
  if (not Assigned(dama)) or (ElementCount(dama) <> 1) then begin
    Say('FAIL: expected one resistance entry on the Garb'); Exit;
  end;
  SetElementNativeValues(ElementByIndex(dama, 0), 'Value', GARB_RESIST);
  // no ballistic weave: drop the attach point and the keyword its mods look for
  el := ElementBySignature(armo, 'APPR');
  if Assigned(el) then Remove(el);
  kwda := ElementBySignature(armo, 'KWDA');
  before := ElementCount(kwda);
  for i := ElementCount(kwda) - 1 downto 0 do
    if Pos('ma_Railroad_ClothingArmor', GetEditValue(ElementByIndex(kwda, i))) = 1 then Remove(ElementByIndex(kwda, i));
  Say('Garb: armor rating ' + GetElementEditValues(armo, 'FNAM\Armor Rating') + ', ' + GetElementEditValues(ElementByIndex(dama, 0), 'Damage Type') + ' ' + GetElementEditValues(ElementByIndex(dama, 0), 'Value') + ', keywords ' + IntToStr(before) + ' -> ' + IntToStr(ElementCount(kwda)));
  if Assigned(ElementBySignature(armo, 'APPR')) or (ElementCount(kwda) <> before - 1) then begin
    Say('FAIL: the weave attach point or keyword is still there'); Exit;
  end;
  effs := ElementByName(ench, 'Effects');
  before := ElementCount(effs);
  if not AddEyeResist(f, effs, eyekw, $0004A0AC, 'damage resistance') then Exit;   // AbFortifyResistDamage
  if not AddEyeResist(f, effs, eyekw, $000559A4, 'energy resistance') then Exit;   // AbFortifyResistEnergy
  if ElementCount(effs) <> before + 2 then begin
    Say('FAIL: expected two more effects on the Garb enchantment'); Exit;
  end;
  changed := 0;
  effs := ElementByName(perk, 'Effects');
  for i := 0 to ElementCount(effs) - 1 do begin
    ee := ElementByName(ElementByIndex(effs, i), 'Function Parameters');
    if Assigned(ee) then begin
      epfd := ElementBySignature(ee, 'EPFD');
      if ElementCount(epfd) > 0 then val := ElementByIndex(epfd, 0) else val := epfd;
      v := GetNativeValue(val);
      repl := '';
      if Abs(v - 0.25) < 0.001 then repl := '0.2';        // melee, no Eye
      if Abs(v - 0.125) < 0.001 then repl := '0.1';       // other, no Eye
      if Abs(v - 0.75) < 0.001 then repl := '0.4';        // melee, added by the Eye (total 0.6)
      if Abs(v - 0.375) < 0.001 then repl := '0.2';       // other, added by the Eye (total 0.3)
      if repl <> '' then begin
        SetEditValue(val, repl); changed := changed + 1;
        Say('  perk: sneak attack entry ' + FloatToStr(v) + ' -> ' + GetEditValue(val));
      end;
    end;
  end;
  Result := changed = 4;
  if not Result then Say('FAIL: expected to change four sneak attack entries, changed ' + IntToStr(changed));
end;

// Place an object once in a cell (rot = heading in degrees).
function PlaceObject(f, cell, base: IInterface; x, y, z, rot: string; flags: integer): boolean;
var
  r: IInterface;
begin
  Result := False;
  if not Assigned(base) then Exit;
  r := Add(cell, 'REFR', True);
  if not Assigned(r) then begin
    Say('FAIL: could not add a reference to the cell'); Exit;
  end;
  if not Assigned(ElementBySignature(r, 'NAME')) then Add(r, 'NAME', True);
  if not SetRef(ElementBySignature(r, 'NAME'), f, base) then Exit;
  if not Assigned(ElementBySignature(r, 'DATA')) then Add(r, 'DATA', True);
  SetElementEditValues(r, 'DATA\Position\X', x);
  SetElementEditValues(r, 'DATA\Position\Y', y);
  SetElementEditValues(r, 'DATA\Position\Z', z);
  SetElementEditValues(r, 'DATA\Rotation\Z', rot);
  if flags <> 0 then begin
    SetElementNativeValues(r, 'Record Header\Record Flags', GetElementNativeValues(r, 'Record Header\Record Flags') or flags);
    if (GetElementNativeValues(r, 'Record Header\Record Flags') and flags) <> flags then begin
      Say('FAIL: the reference flags were not set'); Exit;
    end;
    Say('  reference flags ' + IntToHex(flags, 8) + ' set');
  end;
  Say('PLACED ' + EditorID(base) + ' as ' + IntToHex(FormID(r), 8) + ' at ' + GetElementEditValues(r, 'DATA\Position\X') + ', ' + GetElementEditValues(r, 'DATA\Position\Y') + ', ' + GetElementEditValues(r, 'DATA\Position\Z') + ' rot ' + GetElementEditValues(r, 'DATA\Rotation\Z') + ' in ' + EditorID(cell));
  Result := True;
end;

function Initialize: integer;
var
  esm, srcNote, srcNpc, srcCell, hairpart, hair, dress, eye, f, diary, otft, npc, cell, el: IInterface;
  srcSwanCell, srcHubris, srcStat, srcBook, blade, voice, brokenveil, swancell, hubris: IInterface;
  veilitem, dressitem, seekerdress, cobjveil, cobjgarb, eyearmo, cryptosperk, srcCafeCell, cafecell, srcburst, eyekw, voiceperk, garbarmo, garbench, garbperk: IInterface;
  text: TStringList;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    srcNote := RecordByFormID(esm, $001D5CDC, True);   // DN036MinutemenNote (BOOK)
    srcNpc := RecordByFormID(esm, $0020A578, True);    // Loot_CorpseSettlerFemale_Empty
    srcCell := RecordByFormID(esm, $0000E0BA, True);   // HubrisComicsExt
    hair := RecordByFormID(esm, $0019EE60, True);      // HairColor13JetBlack
    if (not Assigned(srcNote)) or (not Assigned(srcNpc)) or (not Assigned(srcCell)) or (not Assigned(hair)) then begin
      Say('FAIL: a vanilla source record was not found'); Exit;
    end;
    hairpart := RecordByFormID(esm, HAIR_ID, True);
    if not Assigned(hairpart) then begin
      Say('FAIL: the hairstyle was not found'); Exit;
    end;
    Say('hair: ' + Name(hairpart));
    dress := FindOurs('RegaliaBroken2.esp', 'ARMO', 'MoM_ARMO_TatteredDress');
    eye := FindOurs('RegaliaGold1.esp', 'MISC', 'MoM_MISC_BrokenEyeOfRa');
    if (not Assigned(dress)) or (not Assigned(eye)) then Exit;
    blade := FindOurs('RegaliaGold1.esp', 'MISC', 'MoM_MISC_BrokenBladeOfBastet');
    srcBook := FindOurs('RegaliaGold1.esp', 'BOOK', 'MoM_BOOK_Cryptos');
    brokenveil := FindOurs('RegaliaBroken2.esp', 'ARMO', 'MoM_ARMO_BrokenVeil');
    voice := FindOurs('RegaliaVoice12.esp', 'MISC', 'MoM_MISC_BrokenVoice');
    srcStat := RecordByFormID(esm, $001B5EF1, True);       // DONOTUSE_InventoryNote (the standard full reading page)
    srcSwanCell := RecordByFormID(esm, $0000E0B9, True);   // SwansPondExt
    srcHubris := RecordByFormID(esm, $0004542D, True);     // HubrisComics01
    if (not Assigned(blade)) or (not Assigned(srcBook)) or (not Assigned(brokenveil)) or (not Assigned(voice)) or
       (not Assigned(srcStat)) or (not Assigned(srcSwanCell)) or (not Assigned(srcHubris)) then begin
      Say('FAIL: a source record for the containers or the book was not found'); Exit;
    end;
    eyearmo := FindOurs('RegaliaGold1.esp', 'ARMO', 'MoM_ARMO_EyeOfRa');
    cryptosperk := FindOurs('RegaliaGold1.esp', 'PERK', 'MoM_PERK_Cryptos');
    srcburst := FindOurs('RegaliaVoice12.esp', 'EXPL', 'MoM_EXPL_SonicBurst');
    eyekw := FindOurs('RegaliaGold1.esp', 'KYWD', 'MoM_EyeOfRa_KW');
    garbarmo := FindOurs('RegaliaGarb2.esp', 'ARMO', 'MoM_ARMO_Garb');
    garbench := FindOurs('RegaliaGarb2.esp', 'ENCH', 'MoM_ENCH_Garb');
    garbperk := FindOurs('RegaliaGarb2.esp', 'PERK', 'MoM_PERK_Garb');
    if (not Assigned(garbarmo)) or (not Assigned(garbench)) or (not Assigned(garbperk)) then Exit;
    voiceperk := FindOurs('RegaliaVoice12.esp', 'PERK', 'MoM_PERK_VoiceEye');
    if (not Assigned(srcburst)) or (not Assigned(eyekw)) or (not Assigned(voiceperk)) then Exit;
    srcCafeCell := RecordByFormID(esm, $0000E0D9, True);   // exterior cell (1,-6), south of Hubris
    if not Assigned(srcCafeCell) then begin
      Say('FAIL: CELL 0000E0D9 not found'); Exit;
    end;
    if (not Assigned(eyearmo)) or (not Assigned(cryptosperk)) then Exit;
    cobjveil := FindOurs('RegaliaBroken2.esp', 'COBJ', 'MoM_COBJ_RepairVeil');
    cobjgarb := FindOurs('RegaliaBroken2.esp', 'COBJ', 'MoM_COBJ_RepairGarb');
    if (not Assigned(cobjveil)) or (not Assigned(cobjgarb)) then Exit;
    text := TStringList.Create;
    text.LoadFromFile(DIARY_FILE);
    Say('sources ok: ' + Name(srcNote) + ' | ' + Name(srcNpc) + ' | ' + Name(srcCell) + ' | diary lines ' + IntToStr(text.Count));
    Say('Type ' + PLUGIN_HINT + ' in the filename box.');
    f := AddNewFile;
    if not Assigned(f) then begin
      Say('FAIL: no file created (cancelled, or the name already exists in Data?)'); Exit;
    end;
    Say('new file: ' + GetFileName(f));
    AddMasterIfMissing(f, 'Fallout4.esm');
    AddMasterIfMissing(f, 'DLCNukaWorld.esm');
    AddMasterIfMissing(f, 'RegaliaGold1.esp');
    AddMasterIfMissing(f, 'RegaliaGarb2.esp');
    AddMasterIfMissing(f, 'RegaliaVeil1.esp');
    AddMasterIfMissing(f, 'RegaliaBroken2.esp');
    AddMasterIfMissing(f, 'RegaliaVoice12.esp');

    // ---- the two broken wearables become plain items; she keeps a dress that is only for wearing ----
    veilitem := MakeBroken(f, 'MoM_MISC_TatteredVeil', 'Mystery: Worn Veil', 'Armor\Raider02\Mask_GO.nif');
    dressitem := MakeBroken(f, 'MoM_MISC_TatteredDress', 'Mystery: Tattered Dress', 'Clothes\SlinkyDress\GO_SequinDress.nif');
    if (not Assigned(veilitem)) or (not Assigned(dressitem)) then Exit;
    if not SwapIngredient(f, cobjveil, brokenveil, veilitem) then Exit;
    if not SwapIngredient(f, cobjgarb, dress, dressitem) then Exit;
    seekerdress := wbCopyElementToFile(dress, f, True, True);
    if not Assigned(seekerdress) then begin
      Say('FAIL: copy of the Tattered Dress failed'); Exit;
    end;
    SetEditorID(seekerdress, 'MoM_ARMO_SeekerDress');
    SetElementNativeValues(seekerdress, 'Record Header\Record Flags', GetElementNativeValues(seekerdress, 'Record Header\Record Flags') or $4);   // Non-Playable
    if (GetElementNativeValues(seekerdress, 'Record Header\Record Flags') and $4) = 0 then begin
      Say('FAIL: Non-Playable was not set'); Exit;
    end;
    Say('seeker dress: ' + Name(seekerdress) + ' (non-playable)');

    diary := wbCopyElementToFile(srcNote, f, True, True);
    if not Assigned(diary) then begin
      Say('FAIL: copy of the note failed'); Exit;
    end;
    SetEditorID(diary, 'MoM_BOOK_Diary');
    SetElementEditValues(diary, 'FULL', DIARY_NAME);
    SetElementEditValues(diary, 'DESC', Trim(text.Text));
    text.Free;
    SetElementNativeValues(diary, 'INAM', $001B5EF1);   // read on the full note page, not the torn half page
    Say('  diary page: ' + GetElementEditValues(diary, 'INAM'));
    Say('diary: ' + Name(diary) + ' | text length ' + IntToStr(Length(GetElementEditValues(diary, 'DESC'))));
    if Pos('Someone should.', GetElementEditValues(diary, 'DESC')) = 0 then begin
      Say('FAIL: the diary text is incomplete'); Exit;
    end;

    otft := Add(Add(f, 'OTFT', True), 'OTFT', True);
    if not Assigned(otft) then begin
      Say('FAIL: could not create the outfit'); Exit;
    end;
    SetEditorID(otft, 'MoM_OTFT_Seeker');
    el := ElementBySignature(otft, 'INAM');
    if not Assigned(el) then el := Add(otft, 'INAM', True);
    if ElementCount(el) = 0 then ElementAssign(el, HighInteger, nil, False);
    if not SetRef(ElementByIndex(el, 0), f, seekerdress) then Exit;
    if ElementCount(el) <> 1 then begin
      Say('FAIL: expected one outfit item, got ' + IntToStr(ElementCount(el))); Exit;
    end;

    npc := wbCopyElementToFile(srcNpc, f, True, True);
    if not Assigned(npc) then begin
      Say('FAIL: copy of the corpse failed'); Exit;
    end;
    SetEditorID(npc, 'MoM_NPC_Seeker');
    if not Assigned(ElementBySignature(npc, 'FULL')) then Add(npc, 'FULL', True);
    SetElementEditValues(npc, 'FULL', NPC_NAME);
    el := ElementBySignature(npc, 'MWGT');
    if (not Assigned(el)) or (ElementCount(el) <> 3) then begin
      Say('FAIL: no three-value weight on the corpse'); Exit;
    end;
    SetNativeValue(ElementByIndex(el, 0), 1.0);   // thin
    SetNativeValue(ElementByIndex(el, 1), 0.0);   // muscular
    SetNativeValue(ElementByIndex(el, 2), 0.0);   // large
    Say('  weight: ' + Name(ElementByIndex(el, 0)) + ' ' + GetEditValue(ElementByIndex(el, 0)) + ', ' + Name(ElementByIndex(el, 1)) + ' ' + GetEditValue(ElementByIndex(el, 1)) + ', ' + Name(ElementByIndex(el, 2)) + ' ' + GetEditValue(ElementByIndex(el, 2)));
    if not SetHair(f, npc, hairpart) then Exit;
    el := ElementByPath(npc, 'ACBS\Use Template Actors');
    if not Assigned(el) then begin
      Say('FAIL: no template flags on the corpse'); Exit;
    end;
    SetNativeValue(el, GetNativeValue(el) and $FF7F);   // bit 7 = Base Data (the name)
    Say('  template flags now: ' + GetEditValue(el));
    if (GetNativeValue(el) and $80) <> 0 then begin
      Say('FAIL: Base Data is still taken from the template'); Exit;
    end;
    if not SetRef(ElementBySignature(npc, 'HCLF'), f, hair) then Exit;
    if not SetRef(ElementBySignature(npc, 'DOFT'), f, otft) then Exit;
    if not AddItem(f, npc, dressitem) then Exit;
    Say('  items: ' + IntToStr(ElementCount(ElementByName(npc, 'Items'))));

    cell := wbCopyElementToFile(srcCell, f, False, True);   // override of the cell record; its references are not copied
    if not Assigned(cell) then begin
      Say('FAIL: override of the cell failed'); Exit;
    end;
    if not PlaceBody(f, cell, npc, $001289CF, 1, False) then Exit;

    if not BuildBook(f, srcBook, srcStat) then Exit;

    if not Rename(f, voice, 'Mystery: Broken Revolver') then Exit;
    if not Rename(f, eye, 'Mystery: Broken Necklace') then Exit;
    if not Rename(f, blade, 'Mystery: Broken Sword') then Exit;
    if not Rename(f, eyearmo, 'Eye of Ra') then Exit;
    if not Rename(f, cryptosperk, 'Mystery: Cryptos Notes') then Exit;

    // ---- the Voice with the Eye: the burst can stagger everyone it catches; the old second roll goes ----
    if not BurstStagger(f, srcburst, eyekw) then Exit;
    if not DropSecondRoll(f, voiceperk) then Exit;
    if not GarbEye(f, garbarmo, garbench, garbperk, eyekw) then Exit;

    swancell := wbCopyElementToFile(srcSwanCell, f, False, True);
    hubris := wbCopyElementToFile(srcHubris, f, False, True);
    cafecell := wbCopyElementToFile(srcCafeCell, f, False, True);
    if not Assigned(cafecell) then begin
      Say('FAIL: override of the cell for the first aid kit failed'); Exit;
    end;
    if (not Assigned(swancell)) or (not Assigned(hubris)) then begin
      Say('FAIL: override of the swan pond or Hubris cell failed'); Exit;
    end;
    if not PlaceObject(f, cell, Skin(f, MakeContainer(f, $001002A4, 'MoM_CONT_Blade', 'Traveler''s Suitcase', blade),
      'ContSuitcase', 'SetDressing\Suitcase\Suitcase_prewar.BGSM', 'SetDressing\Suitcase\Suitcase_prewar.nif'),
      '7408.37', '-18588.25', '1856.75', '68', 0) then Exit;
    if not PlaceObject(f, swancell, Skin(f, MakeContainer(f, $0008E59E, 'MoM_CONT_Voice', 'Traveler''s Duffle Bag', voice),
      'ContDuffle', 'SetDressing\DuffleBag\DuffleBag.BGSM', ''),
      '11993.90', '-20086.55', '596.40', '35', 0) then Exit;
    if not PlaceObject(f, cafecell, Skin(f, MakeContainer(f, $0020A6FD, 'MoM_CONT_Veil', 'First Aid Kit', veilitem),
      'ContMedKit', 'SetDressing\FirstAidKit\FirstAidKitPharm.BGSM', ''),
      '7267.84', '-20585.32', '1117.20', '180', 0) then Exit;
    if not PlaceObject(f, hubris, Skin(f, MakeContainer(f, $001103E3, 'MoM_CONT_Eye', 'Traveler''s Tool Case', eye),
      'ContToolCase', 'SetDressing\ToolCase\ToolCase1.BGSM', ''),
      '2818.30', '-245.50', '839.50', '135', 0) then Exit;
    // the two books, loose beside her: $40000000 = No Respawn
    if not PlaceObject(f, cell, diary, '5556.00', '-18622.00', '1806.00', '80', $40000000) then Exit;
    if not PlaceObject(f, cell, srcBook, '5560.00', '-18578.00', '1806.00', '110', $40000000) then Exit;

    log.Add('===== outfit dump');
    Dump(otft, '');
    log.Add('===== npc dump');
    Dump(npc, '');
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
