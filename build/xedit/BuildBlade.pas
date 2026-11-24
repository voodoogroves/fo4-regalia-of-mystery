{
  BuildBlade.pas: builds RegaliaOfMystery.esl version 0.1 (Blade of Bastet), UNGATED, in FO4Edit.
  Spec: spec/spec-blade-of-bastet.md (this repo).
  Status (2026-11-23): runs end to end on FO4Edit 4.1.5f under Proton 11.0 and produces
  RegaliaOfMystery.esp (weapon + recipe, master Fallout4.esm, no unresolved references).
  SUPERSEDED: tested in game, the penetration does not apply (the recipe and item do work). The ESL flag is not applied yet (plain .esp).
  The plugin is only written if you accept xEdit's save prompt when you close the window.

  Run from MO2 (Edit executables > a FO4Edit entry) with Arguments:
    -autoload -autoexit -script:"Z:\home\deck\Repos\fo4-regalia-of-mystery\build\xedit\BuildBlade.pas" -R:"Z:\home\deck\Games\mo2-lint\tools\our-scripts\xe.log" Fallout4.esm
  Load only Fallout4.esm in the module list (plus its masters). Click OK/Yes if xEdit asks to save
  the new file when it closes. The file lands in MO2's overwrite folder.
  Before re-running, delete any RegaliaOfMystery.esl from overwrite (or the mod folder it was moved to).

  Writes a step-by-step log, including a dump of the new records, to LOG_FILE. Each step is logged
  so a partial failure shows where it stopped.
}
unit BuildBlade;

const
  PLUGIN_NAME = 'RegaliaOfMystery.esp';   // prototype is a plain .esp; flag ESL later
  // Per-build values (the spec's 0.1 values are 30.0 / 'Blade of Bastet' / MoM_WEAP_BladeOfBastet / MoM_COBJ_BladeOfBastet).
  // These are the STAT-100 TEST values (used 2026-11-23 to check that the chain applies). The spec build used 30.0 / 'Blade of Bastet' /
  // MoM_WEAP_BladeOfBastet / MoM_COBJ_BladeOfBastet. NOTE: this whole approach (EITM + template-level stat) does NOT work in game;
  // it is kept for the record. See spec/spec-blade-of-bastet.md, 'Armor penetration: in-game findings', and BuildBladePerk.pas.
  AP_STAT = '100.0';
  ITEM_NAME = 'Blade of Bastet TEST100';
  WEAP_EDID = 'MoM_WEAP_Test100';
  COBJ_EDID = 'MoM_COBJ_Test100';
  LOG_FILE = 'Z:\home\deck\Games\mo2-lint\tools\our-scripts\build.log';
  DESC_TEXT = 'A Chinese officer''s sword reforged with silver, gold and a crystal-set hilt, in the manner of the Mistress of Mystery''s blade. Ignores 30% of the target''s damage and energy resistance. Craft it from a Chinese Officer Sword at a Chemistry Station.';

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

procedure AddComponent(comps: IInterface; formid: integer; cnt: integer);
var
  c: IInterface;
begin
  c := ElementAssign(comps, HighInteger, nil, False);
  SetElementNativeValues(c, 'Component', formid);
  SetElementNativeValues(c, 'Count', cnt);
end;

function Initialize: integer;
var
  src, f, w, g, r, comps, fnam, kw, tmpl, combs, comb0, obts, props, p, hdr: IInterface;
begin
  Result := 0;
  log := TStringList.Create;
  try
    src := RecordByFormID(FileByIndex(0), $00147BE4, True);
    if not Assigned(src) then begin
      Say('FAIL: source sword 00147BE4 not found'); Exit;
    end;
    Say('source: ' + Name(src));

    // xEdit 4.1.5f: AddNewFile takes no arguments and shows a "Filename without extension" box.
    // (AddNewFileName and the light-flag arguments exist only in the newer unreleased source.)
    // TYPE:  RegaliaOfMystery   in that box. The file is created as .esp; the ESL flag is a later step.
    f := AddNewFile;
    if not Assigned(f) then begin
      Say('FAIL: no file created (box cancelled, or the name already exists in Data?)'); Exit;
    end;
    Say('new file: ' + GetFileName(f));

    // The copy-as-new step does not add masters. Without Fallout4.esm as a master, every
    // reference to a vanilla record is saved against a master that does not exist.
    AddMasterIfMissing(f, 'Fallout4.esm');
    Say('master added: Fallout4.esm');

    // 1. copy the sword as a new record
    w := wbCopyElementToFile(src, f, True, True);
    if not Assigned(w) then begin
      Say('FAIL: copy of the sword failed'); Exit;
    end;
    SetEditorID(w, WEAP_EDID);
    SetElementEditValues(w, 'FULL', ITEM_NAME);
    SetElementEditValues(w, 'DESC', DESC_TEXT);
    Say('weapon: ' + Name(w));

    // 2. base enchantment = vanilla enchModArmorPenetration (ENCH 001F4425)
    Add(w, 'EITM', True);
    SetElementNativeValues(w, 'EITM', $001F4425);
    Say('EITM set: ' + GetElementEditValues(w, 'EITM'));

    // 3. weapon-level ArmorPenetration = 30 on the default template combination
    //    (TO VERIFY: that a template-level ActorValues property applies in game)
    combs := ElementByPath(w, 'Object Template\Combinations');
    if Assigned(combs) then begin
      comb0 := ElementByIndex(combs, 0);
      obts := ElementBySignature(comb0, 'OBTS');
      Say('combination 0 OBTS: ' + Name(obts));
      props := ElementByName(obts, 'Properties');
      if Assigned(props) then begin
        p := ElementAssign(props, HighInteger, nil, False);
        SetElementEditValues(p, 'Value Type', 'FormID,Float');
        SetElementEditValues(p, 'Function Type', 'ADD');
        SetElementEditValues(p, 'Property', 'ActorValues');
        SetElementNativeValues(p, 'Value 1', $00097341);
        SetElementEditValues(p, 'Value 2', AP_STAT);
        SetElementNativeValues(obts, 'Property Count', 1);
        Say('template property added');
      end else
        Say('WARN: no Properties element on the template combination');
    end else
      Say('WARN: no Combinations element');

    // 4. the recipe (UNGATED: no conditions)
    g := Add(f, 'COBJ', True);
    r := Add(g, 'COBJ', True);
    if not Assigned(r) then begin
      Say('FAIL: could not create the COBJ record'); Exit;
    end;
    SetEditorID(r, COBJ_EDID);
    comps := Add(r, 'FVPA', True);
    AddComponent(comps, $00147BE4, 1);   // Chinese Officer Sword
    AddComponent(comps, $0001FABD, 4);   // Steel
    AddComponent(comps, $0001FABB, 3);   // Silver
    AddComponent(comps, $0001FAA6, 2);   // Gold
    AddComponent(comps, $0001FA9F, 2);   // Crystal
    AddComponent(comps, $0001FAA5, 3);   // Adhesive
    SetElementNativeValues(r, 'CNAM', FormID(w));
    Add(r, 'BNAM', True);
    SetElementNativeValues(r, 'BNAM', $00102158);   // WorkbenchChemlab
    fnam := Add(r, 'FNAM', True);
    kw := ElementAssign(fnam, HighInteger, nil, False);
    SetNativeValue(kw, $0006980C);                  // RecipeUtility
    Add(r, 'INTV', True);
    SetElementNativeValues(r, 'INTV\Created Object Count', 1);
    SetElementNativeValues(r, 'INTV\Priority', 0);
    Say('recipe: ' + Name(r));

    log.Add('');
    log.Add('===== weapon dump');
    Dump(w, '');
    log.Add('');
    log.Add('===== recipe dump');
    Dump(r, '');
    Say('done');
  finally
    log.SaveToFile(LOG_FILE);
    log.Free;
  end;
end;

end.
