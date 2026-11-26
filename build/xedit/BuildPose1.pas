{
  BuildPose1.pas: pose audition (plugin RegaliaPose1). Four copies of the Mysterious Traveler's placement on the same spot, each with a
  saved pose from a different vanilla corpse placement. Pose 1 starts enabled, 2 to 4 start disabled: switch them with the console.
  Status: audition (RegaliaPose1) seen in game 2026-11-25: pose 1 is good, but clipped the wall and crates.
  FINAL BODY BUILD (plugin RegaliaBody4, VERIFIED in game 2026-11-25): pose 1 only, at the new position x 5514.07, y -18598.39. Type RegaliaBody4; test with RegaliaPose1 unticked.
  Otherwise the same records as BuildBody2.pas.

  Poses: 1 = ACHR 001289CF, 2 = 001289CD, 3 = 001289D1, 4 = 001289DE.  The placed references are the last four records made.
  Masters and module list as BuildBody2. Type RegaliaPose1 in the filename box. Accept the save prompt. Run it ONCE. Log: our-scripts\build.log.
  Test with every RegaliaBody plugin UNTICKED.
}
unit BuildPose1;

const
  PLUGIN_HINT = 'RegaliaBody4';
  HAIR_ID = $0016CA35;                     // HairFemale08 "No Apologies"
  DIARY_NAME = 'Mysterious Traveler''s Diary';
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

function Initialize: integer;
var
  esm, srcNote, srcNpc, srcCell, hairpart, hair, dress, eye, f, diary, otft, npc, cell, el: IInterface;
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

    diary := wbCopyElementToFile(srcNote, f, True, True);
    if not Assigned(diary) then begin
      Say('FAIL: copy of the note failed'); Exit;
    end;
    SetEditorID(diary, 'MoM_BOOK_Diary');
    SetElementEditValues(diary, 'FULL', DIARY_NAME);
    SetElementEditValues(diary, 'DESC', Trim(text.Text));
    text.Free;
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
    if not SetRef(ElementByIndex(el, 0), f, dress) then Exit;
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
    if not AddItem(f, npc, diary) then Exit;
    if not AddItem(f, npc, eye) then Exit;
    Say('  items: ' + IntToStr(ElementCount(ElementByName(npc, 'Items'))));

    cell := wbCopyElementToFile(srcCell, f, False, True);   // override of the cell record; its references are not copied
    if not Assigned(cell) then begin
      Say('FAIL: override of the cell failed'); Exit;
    end;
    if not PlaceBody(f, cell, npc, $001289CF, 1, False) then Exit;

    log.Add('===== outfit dump');
    Dump(otft, '');
    log.Add('===== npc dump');
    Dump(npc, '');
    log.Add('===== cell dump');
    Dump(cell, '');
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
