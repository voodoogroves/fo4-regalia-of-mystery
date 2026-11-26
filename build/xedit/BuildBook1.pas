{
  BuildBook1.pas: TEST build (plugin RegaliaBook1). Our pencil sketch on the Cryptos book (art/make_photo.py, loose files in the
  MO2 mod "Blade of Bastet Art"). Status: RUN and seen in game 2026-11-25 (the picture looked good).

  A small patch on RegaliaGold1.esp:
    MSWP MoM_MSWP_CryptosSketch   the Silver Shroud photo material -> ours
    STAT MoM_STAT_CryptosSketch   copy of HighPoly_PhotoSilverShroud (0020B29A, the inventory preview) with the swap
    BOOK MoM_BOOK_Cryptos         override of OUR book in Gold1: the swap on its model, and the new preview STAT. Text unchanged.

  Masters: Fallout4.esm, DLCNukaWorld.esm, RegaliaGold1.esp. IN THE MODULE LIST tick the game, the six DLC and RegaliaGold1.esp.
  Type RegaliaBook1 in the filename box. Accept the save prompt when xEdit closes. Run it ONCE. Log: our-scripts\build.log.

  Test in game (RegaliaGold1.esp and RegaliaBook1.esp ticked): help "Cryptos" 4, player.additem <ID> 1.
    1. The sketch in the inventory preview.  2. The sketch on the dropped item.  3. No trace of the old signature or figure.
    4. Reading it still adds Cryptos Notes.
}
unit BuildBook1;

const
  PLUGIN_HINT = 'RegaliaBook1';
  GOLD_PLUGIN = 'RegaliaGold1.esp';
  BOOK_EDID = 'MoM_BOOK_Cryptos';
  MAT_ORIGINAL = 'Interface\Note\PhotoHorizLowPolySilverShroud.BGSM';
  MAT_REPLACEMENT = 'RegaliaOfMystery\CryptosSketch.BGSM';
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

// Put the material swap on a record's model.
function SetModelSwap(r: IInterface; swapid: integer): boolean;
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
  if not Assigned(el) then begin
    Say('FAIL: could not add MODS on ' + EditorID(r)); Exit;
  end;
  SetNativeValue(el, swapid);
  Say('  ' + EditorID(r) + ' material swap: ' + GetEditValue(el));
  Result := Pos('MoM_MSWP_CryptosSketch', GetEditValue(el)) > 0;
  if not Result then Say('FAIL: the swap on ' + EditorID(r) + ' is wrong');
end;

function Initialize: integer;
var
  esm, gold, srcStat, srcBook, f, mswp, subs, sub, stat, book: IInterface;
begin
  Result := 0;
  log := TStringList.Create;
  try
    esm := FileByIndex(0);
    srcStat := RecordByFormID(esm, $0020B29A, True);    // HighPoly_PhotoSilverShroud
    if not Assigned(srcStat) then begin
      Say('FAIL: STAT 0020B29A not found'); Exit;
    end;
    gold := FindFile(GOLD_PLUGIN);
    if not Assigned(gold) then begin
      Say('FAIL: tick ' + GOLD_PLUGIN + ' in the module list'); Exit;
    end;
    srcBook := MainRecordByEditorID(GroupBySignature(gold, 'BOOK'), BOOK_EDID);
    if not Assigned(srcBook) then begin
      Say('FAIL: BOOK ' + BOOK_EDID + ' not found in ' + GOLD_PLUGIN); Exit;
    end;
    Say('sources ok: ' + Name(srcStat) + ' | ' + Name(srcBook));
    Say('Type ' + PLUGIN_HINT + ' in the filename box.');
    f := AddNewFile;
    if not Assigned(f) then begin
      Say('FAIL: no file created (cancelled, or the name already exists in Data?)'); Exit;
    end;
    Say('new file: ' + GetFileName(f));
    AddMasterIfMissing(f, 'Fallout4.esm');
    AddMasterIfMissing(f, 'DLCNukaWorld.esm');
    AddMasterIfMissing(f, GOLD_PLUGIN);

    mswp := Add(Add(f, 'MSWP', True), 'MSWP', True);
    if not Assigned(mswp) then begin
      Say('FAIL: could not create the material swap record'); Exit;
    end;
    SetEditorID(mswp, 'MoM_MSWP_CryptosSketch');
    subs := Add(mswp, 'Material Substitutions', True);
    if not Assigned(subs) then begin
      Say('FAIL: could not create Material Substitutions'); Exit;
    end;
    if ElementCount(subs) = 0 then sub := ElementAssign(subs, HighInteger, nil, False)
    else sub := ElementByIndex(subs, 0);
    SetElementEditValues(sub, 'BNAM - Original Material', MAT_ORIGINAL);
    SetElementEditValues(sub, 'SNAM - Replacement Material', MAT_REPLACEMENT);
    Say('  material swap: ' + GetElementEditValues(sub, 'BNAM - Original Material') + '  ->  ' + GetElementEditValues(sub, 'SNAM - Replacement Material'));
    if (ElementCount(subs) <> 1) or (GetElementEditValues(sub, 'SNAM - Replacement Material') <> MAT_REPLACEMENT) then begin
      Say('FAIL: the substitution is wrong'); Exit;
    end;

    stat := wbCopyElementToFile(srcStat, f, True, True);
    if not Assigned(stat) then begin
      Say('FAIL: copy of the preview STAT failed'); Exit;
    end;
    SetEditorID(stat, 'MoM_STAT_CryptosSketch');
    if not SetModelSwap(stat, FormID(mswp)) then Exit;

    book := wbCopyElementToFile(srcBook, f, False, True);   // False: an override of our book, same FormID
    if not Assigned(book) then begin
      Say('FAIL: override of the Cryptos book failed'); Exit;
    end;
    if not SetModelSwap(book, FormID(mswp)) then Exit;
    SetElementNativeValues(book, 'INAM', FormID(stat));
    Say('  book preview: ' + GetElementEditValues(book, 'INAM') + ' | teaches: ' + GetElementEditValues(book, 'DNAM\Teaches') + ' | flags: ' + GetElementEditValues(book, 'DNAM\Flags'));
    if Pos('MoM_STAT_CryptosSketch', GetElementEditValues(book, 'INAM')) = 0 then begin
      Say('FAIL: the book preview is wrong'); Exit;
    end;
    if Pos('MoM_PERK_Cryptos', GetElementEditValues(book, 'DNAM\Teaches')) = 0 then begin
      Say('FAIL: the book no longer teaches the Cryptos perk'); Exit;
    end;

    log.Add('===== swap dump');
    Dump(mswp, '');
    log.Add('===== preview dump');
    Dump(stat, '');
    log.Add('===== book dump');
    Dump(book, '');
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
