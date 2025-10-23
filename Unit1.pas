unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.Generics.Collections,
  Xml.XMLDoc, Xml.XMLIntf, Xml.Win.msxmldom;

type
  TForm1 = class(TForm)
    MemoInput: TMemo;
    ButtonCheck: TButton;
    MemoOutput: TMemo;
    procedure ButtonCheckClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
  TRecValidationInfo = class
    FoundOne: Boolean;
    FoundGreaterThanOne: Boolean;
    NamesFound: TStringList; // To store all names for this prefix
    constructor Create;
    destructor Destroy; override;
  end;



var
  Form1: TForm1;

// Helper function to recursively find nodes (moved from DPR)
procedure CollectNodes(const ANode: IXMLNode; const NodeNames: array of string; AList: TList<IXMLNode>);

// Function to find duplicates (modified from FindDuplicatesInFile)
function FindDuplicates(const AXMLContent: string): string;

implementation

constructor TRecValidationInfo.Create;
begin
  inherited Create;
  FoundOne := False;
  FoundGreaterThanOne := False;
  NamesFound := TStringList.Create;
end;

destructor TRecValidationInfo.Destroy;
begin
  NamesFound.Free;
  inherited Destroy;
end;

{$R *.dfm}

// Helper function to recursively find nodes (moved from DPR)
procedure CollectNodes(const ANode: IXMLNode; const NodeNames: array of string; AList: TList<IXMLNode>);
var
  Child: IXMLNode;
  NodeName: string;
  I, J: Integer; // Added J for the ChildNodes loop
begin
  if ANode = nil then Exit;

  NodeName := LowerCase(ANode.NodeName);
  for I := Low(NodeNames) to High(NodeNames) do
  begin
    if NodeName = LowerCase(NodeNames[I]) then
    begin
      AList.Add(ANode);
      Break;
    end;
  end;

  for J := 0 to ANode.ChildNodes.Count - 1 do // Changed to traditional for loop
  begin
    Child := ANode.ChildNodes[J];
    CollectNodes(Child, NodeNames, AList);
  end;
end;

// Function to find duplicates (modified from FindDuplicatesInFile)
function FindDuplicates(const AXMLContent: string): string;
var
  XMLDoc: IXMLDocument;
  RecToNames: TDictionary<string, TStringList>;
  NameCounts: TDictionary<string, Integer>;
  Node: IXMLNode;
  RecAttr, NameAttr: string;
  Names: TStringList;
  FoundRecDuplicates, FoundNameDuplicates: Boolean;
  ResultList: TStringList; // To collect output
  // New variables for rec prefix validation
  RecPrefixValidation: TDictionary<string, TRecValidationInfo>;
  Prefix, ValueStr: string;
  ValueInt: Integer;
  Info: TRecValidationInfo;
begin
  ResultList := TStringList.Create;
  RecPrefixValidation := TDictionary<string, TRecValidationInfo>.Create; // Initialize new dictionary
  try
    RecToNames := TDictionary<string, TStringList>.Create;
    NameCounts := TDictionary<string, Integer>.Create;
    try
      // Carrega o documento XML a partir do conteúdo da string
      XMLDoc := TXMLDocument.Create(nil);
      (XMLDoc as TXMLDocument).LoadFromXML(AXMLContent);

      // Coleta os nós <campo> e <campo1> manualmente
      var
        CollectedNodes: TList<IXMLNode>;
      begin
        CollectedNodes := TList<IXMLNode>.Create;
        try
          CollectNodes(XMLDoc.DocumentElement, ['campo', 'campo1'], CollectedNodes);

          // 1. Itera sobre os nós coletados para popular os dicionários
          for Node in CollectedNodes do
          begin
            RecAttr := VarToStrDef(Node.Attributes['rec'], '');
            NameAttr := VarToStrDef(Node.Attributes['nome'], '');

            // --- Existing: Add 'rec' and 'nome' to dictionary for 'rec' duplicates ---
            if (RecAttr <> '') and (NameAttr <> '') then
            begin
              if not RecToNames.TryGetValue(RecAttr, Names) then
              begin
                Names := TStringList.Create;
                RecToNames.Add(RecAttr, Names);
              end;
              Names.Add(NameAttr);
            end;

            // --- Existing: Count occurrences of each 'nome' for 'nome' duplicates ---
            if (NameAttr <> '') and not NameAttr.StartsWith('Handle') then
            begin
              if NameCounts.ContainsKey(NameAttr) then
                NameCounts[NameAttr] := NameCounts[NameAttr] + 1
              else
                NameCounts.Add(NameAttr, 1);
            end;

            // --- NEW: Populate RecPrefixValidation for the new rule ---
            if (RecAttr <> '') and (Pos('=', RecAttr) > 0) then
            begin
              Prefix := Copy(RecAttr, 1, Pos('=', RecAttr) - 1);
              ValueStr := Copy(RecAttr, Pos('=', RecAttr) + 1, Length(RecAttr));

              if TryStrToInt(ValueStr, ValueInt) then
              begin
                if not RecPrefixValidation.TryGetValue(Prefix, Info) then
                begin
                  Info := TRecValidationInfo.Create;
                  RecPrefixValidation.Add(Prefix, Info);
                end;

                Info.NamesFound.Add(NameAttr + '=' + ValueStr); // Store for reporting context

                if ValueInt = 1 then
                  Info.FoundOne := True
                else if ValueInt > 1 then
                  Info.FoundGreaterThanOne := True;
              end;
            end;
          end; // for Node in CollectedNodes
        finally
          CollectedNodes.Free;
        end;
      end; // var CollectedNodes

      // --- Existing: Report 'rec' duplicates ---
      ResultList.Add('--- Verificando XML ---');
      ResultList.Add('');
      ResultList.Add('--- ''rec'' duplicados e ''nomes'' associados ---');

      FoundRecDuplicates := False;
      for RecAttr in RecToNames.Keys do
      begin
        Names := RecToNames[RecAttr];
        if Names.Count > 1 then
        begin
          FoundRecDuplicates := True;
          ResultList.Add('');
          ResultList.Add('Atributo ''rec'' duplicado: ''' + RecAttr + '''');
          ResultList.Add('  -> Encontrado nos seguintes campos (''nome''):');
          for NameAttr in Names do
          begin
            ResultList.Add('    - ' + NameAttr);
          end;
        end;
      end;

      if not FoundRecDuplicates then
      begin
        ResultList.Add('Nenhuma duplicata do atributo ''rec'' foi encontrada.');
      end;

      // --- Existing: Report 'nome' duplicates ---
      ResultList.Add('');
      ResultList.Add('');
      ResultList.Add('--- Duplicatas no atributo ''nome'' (ignorando ''Handle*'') ---');
      FoundNameDuplicates := False;
      for NameAttr in NameCounts.Keys do
      begin
        if NameCounts[NameAttr] > 1 then
        begin
          FoundNameDuplicates := True;
          ResultList.Add('Atributo ''nome'' duplicado encontrado: ''' + NameAttr + ''' (ocorrências: ' + IntToStr(NameCounts[NameAttr]) + ')');
        end;
      end;

      if not FoundNameDuplicates then
      begin
        ResultList.Add('Nenhum atributo ''nome'' duplicado encontrado.');
      end;

      // --- NEW: Report violations of the rec prefix rule ---
      ResultList.Add('');
      ResultList.Add('');
      ResultList.Add('--- Validação de Atributos ''rec'' (prefixo=N, N>1 não pode ter prefixo=1) ---');
      var
        FoundRecRuleViolation: Boolean;
      begin
        FoundRecRuleViolation := False;
        for Prefix in RecPrefixValidation.Keys do
        begin
          Info := RecPrefixValidation[Prefix];
          if Info.FoundGreaterThanOne and Info.FoundOne then
          begin
            FoundRecRuleViolation := True;
            ResultList.Add('');
            ResultList.Add('VIOLAÇÃO: O prefixo ''' + Prefix + ''' possui ''rec=' + Prefix + '=1'' e também ''rec=' + Prefix + '=N'' (N>1).');
            ResultList.Add('  Campos envolvidos:');
            for ValueStr in Info.NamesFound do
            begin
              ResultList.Add('    - ' + ValueStr);
            end;
          end;
        end;

        if not FoundRecRuleViolation then
        begin
          ResultList.Add('Nenhuma violação da regra de prefixo ''rec'' encontrada.');
        end;
      end;

    finally
      // Libera a memória dos TStringLists dentro do dicionário RecToNames
      for Names in RecToNames.Values do
        Names.Free;
      RecToNames.Free;
      NameCounts.Free;
      // Libera a memória dos TRecValidationInfo objetos e seus TStringLists
      for Info in RecPrefixValidation.Values do
        Info.Free;
      RecPrefixValidation.Free;
    end;
    Result := ResultList.Text;
  finally
    ResultList.Free;
  end;
end;

procedure TForm1.ButtonCheckClick(Sender: TObject);
var
  XMLContent: string;
  ResultString: string;
begin
  XMLContent := MemoInput.Text;
  if Trim(XMLContent) = '' then
  begin
    ShowMessage('Por favor, insira o XML no campo acima.');
    Exit;
  end;

  MemoOutput.Clear;
  try
    ResultString := FindDuplicates(XMLContent);
    MemoOutput.Text := ResultString;
  except
    on E: Exception do
      MemoOutput.Text := 'Erro: ' + E.Message;
  end;
end;

end.