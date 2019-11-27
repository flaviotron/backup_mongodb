unit UBackupScript;

interface

uses Windows, Classes, Messages, SysUtils, ShellAPI, Vcl.Forms;

type
  TBackupScript = class
   private
    FPathDestination: String;
    FHostMongoDB: String;
    FPort: String;
    FPathBINMongoDB: String;
    FBaseName: String;
    FListaDataBasesMongoDB: TStringList;
    FPassword: String;
    FUsername: String;
    function GetFileListDataBasesMongoDB: String;
    function GetFileNameBatchListDataBasesMongoDB: String;
    function ExecutareAguardarConcluir(const Prog: string; const WindowType: cardinal = SW_SHOWNORMAL): boolean;
    function GetPathAplicacao: String;
    procedure GeraScriptBackupAllDataBasesMongoDB;
    function FileNameBackup(DataBase: String): String;
    function GetFileNameBatchBackupDataBasesMongoDB: String;
    procedure CarregarListaBancosMongoDB;
    function GetListaDataBasesMongoDB: TStringList;
    procedure ObterListagemBancosPostGreSql;
    procedure CarregarListaBancosPostGreSql;
    procedure GeraScriptBackupAllDataBasesPostGreSql;
    function GetLoginNoBancoComSenha: Boolean;
    function FolderBackup(DataBase: String): String;
    function FileNameCopyDatabase(DataBase: String): String;
    function SepararStringPorDelimitador(const Text: String; Delimiter: char; const bTrim: Boolean = False; const iLimit: Integer = 0): TStringList;
    procedure ObterListagemBancosMysql;
    procedure CarregarListaBancosMysql;
    procedure GeraScriptBackupAllDataBasesMySql;
   public
    procedure ObterListagemBancosMongoDB;
    procedure RealizarBackupTodosDatabasesMongoDB;
    procedure RealizarBackupTodosDatabasesPostGreSql;
    procedure RealizarBackupTodosDatabasesMySql;
    function CopiarBancoOrigemProducaoParaDestinoTestes(Origem, Destino: String): Boolean;
   published
    property BaseName: String read FBaseName write FBaseName;
    property PathBINMongoDB: String read FPathBINMongoDB write FPathBINMongoDB;
    property HostMongoDB: String read FHostMongoDB write FHostMongoDB;
    property Port: String read FPort write FPort;
    property Username: String read FUsername write FUsername;
    property Password: String read FPassword write FPassword;
    property PathDestination: String read FPathDestination write FPathDestination;
    property PathAplicacao: String read GetPathAplicacao;
    property FileListDataBasesMongoDB: String read GetFileListDataBasesMongoDB;
    property FileNameBatchListDataBasesMongoDB: String read GetFileNameBatchListDataBasesMongoDB;
    property FileNameBatchBackupDataBasesMongoDB: String read GetFileNameBatchBackupDataBasesMongoDB;
    property ListaDataBasesMongoDB: TStringList read GetListaDataBasesMongoDB;
    property LoginNoBancoComSenha: Boolean read GetLoginNoBancoComSenha;
  end;

implementation

{ TBackupScript }

uses StrUtils, IOUtils, REST.Response.Adapter, System.JSON;

function TBackupScript.SepararStringPorDelimitador(const Text: String; Delimiter: char; const bTrim: Boolean; const iLimit: Integer): TStringList;
var
  i, limitAux: integer;
  s: String;
begin
  Result   := TStringList.Create;
  s        := '';
  limitAux := 1;

  for i := 1 to Length(Text) do
   if (Text[i] = Delimiter) and (limitAux <> iLimit) then
    begin
     Result.Add(ifThen(bTrim, Trim(s), s));
     s := '';
     limitAux := limitAux + 1;
    end
   else s := s + Text[i];

  if (Trim(s) <> '') then
   Result.Add(ifThen(bTrim, Trim(s), s));
end;

function TBackupScript.ExecutareAguardarConcluir(const Prog: string; const WindowType: cardinal): boolean;
var
  StartupInfo: TStartupinfo;
  ProcessInfo: TProcessInformation;
  sDir: string;
  iCode: cardinal;
begin
  sDir := IfThen(DirectoryExists(ExtractFileDir(Prog)), ExtractFileDir(Prog), PathAplicacao);
  FillChar(Startupinfo, Sizeof(TStartupinfo), 0);
  Startupinfo.cb := Sizeof(TStartupInfo);
  Startupinfo.dwFlags := STARTF_USESHOWWINDOW;
  Startupinfo.wShowWindow := WindowType;
  if CreateProcess(nil, PChar(Prog), nil, nil, false, HIGH_PRIORITY_CLASS, nil,
                   PChar(sDir), Startupinfo, ProcessInfo) then
   begin
    WaitForSingleObject(Processinfo.hProcess, INFINITE);
    GetExitCodeProcess(Processinfo.hProcess, iCode);
    Result := iCode = 0;
    CloseHandle(ProcessInfo.hProcess);
   end
  else Result := false;
end;

function TBackupScript.GetFileListDataBasesMongoDB: String;
begin
  Result := TPath.Combine(PathDestination, Format('%s_ListaDatabases.JSON', [BaseName]));
end;

function TBackupScript.GetFileNameBatchBackupDataBasesMongoDB: String;
begin
  Result := TPath.Combine(PathAplicacao, Format('%s_MongoDBBackupAllDatabases.BAT', [BaseName]));
end;

function TBackupScript.GetFileNameBatchListDataBasesMongoDB: String;
begin
  Result := TPath.Combine(PathAplicacao, Format('%s_MongoDBList.BAT', [BaseName]));
end;

function TBackupScript.GetListaDataBasesMongoDB: TStringList;
begin
  if not Assigned(FListaDataBasesMongoDB) then
   FListaDataBasesMongoDB := TStringList.Create;

  Result := FListaDataBasesMongoDB;
end;

function TBackupScript.GetLoginNoBancoComSenha: Boolean;
begin
  Result := (Self.Username <> '') and (Self.Password <> '');
end;

function TBackupScript.GetPathAplicacao: String;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

function TBackupScript.FileNameBackup(DataBase: String): String;
var
  stl: TStringlist;
begin
  stl := SepararStringPorDelimitador(DataBase, '-');

  try
   if (stl.Count = 3) then
    Result := TPath.Combine(TPath.Combine(PathDestination, stl[1]), Format('%s_%s.gz', [FormatDateTime('yyyy-mm-dd_hh-nn-ss', now), DataBase]))
   else
    Result := TPath.Combine(PathDestination, Format('%s_%s.gz', [FormatDateTime('yyyy-mm-dd_hh-nn-ss', now), DataBase]));
  finally
   stl.Free;
  end;
end;

function TBackupScript.FolderBackup(DataBase: String): String;
begin
  Result := TPath.Combine(PathDestination, DataBase);
end;

function TBackupScript.FileNameCopyDatabase(DataBase: String): String;
begin
  Result := TPath.Combine(PathDestination, DataBase + '.bat');
end;

procedure TBackupScript.ObterListagemBancosMongoDB;
var
  stlFile: TStringList;
begin
  stlFile := TStringList.Create;

  try
   stlFile.Add('@echo off');
   stlFile.Add('echo. Listando os Databases do MongoDB');
   stlFile.Add(Format('%s', [Copy(PathBINMongoDB, 1, 2)]));
   stlFile.Add(Format('cd "%s"', [PathBINMongoDB]));

   if LoginNoBancoComSenha then
    begin
     stlFile.Add(Format('mongo --host %s --port %s --username %s --password %s --authenticationDatabase admin --quiet --eval "printjson(db.getMongo().getDBNames());" > "%s"',
                       [HostMongoDB, Port, Username, Password, FileListDataBasesMongoDB]));
    end
   else
    begin
     stlFile.Add(Format('mongo --host %s --port %s --quiet --eval "printjson(db.getMongo().getDBNames());" > "%s"',
                       [HostMongoDB, Port, FileListDataBasesMongoDB]));
    end;

   stlFile.SaveToFile(FileNameBatchListDataBasesMongoDB);

   ExecutareAguardarConcluir(FileNameBatchListDataBasesMongoDB);
  finally
   stlFile.Free;
  end;
end;

procedure TBackupScript.ObterListagemBancosPostGreSql;
var
  stlFile: TStringList;
begin
  stlFile := TStringList.Create;

  try
   stlFile.Add('@echo off ');
   stlFile.Add('   SET PGPASSWORD=B1r7i9t3a');
   stlFile.Add('echo. Listando os Databases do PostGreSql');
   stlFile.Add(Format('%s', [Copy(PathBINMongoDB, 1, 2)]));
   stlFile.Add(Format('cd "%s"', [PathBINMongoDB]));
   stlFile.Add('   echo on ');
   stlFile.Add(Format('   psql.exe -h %s -p %s -U postgres -l > %s',
                      [HostMongoDB, Port, FileListDataBasesMongoDB]));

   stlFile.SaveToFile(FileNameBatchListDataBasesMongoDB);

   ExecutareAguardarConcluir(FileNameBatchListDataBasesMongoDB);
  finally
   stlFile.Free;
  end;
end;

procedure TBackupScript.ObterListagemBancosMysql;
var
  stlFile: TStringList;
begin
  stlFile := TStringList.Create;

  try
   stlFile.Add('@echo off ');
   stlFile.Add('echo. Listando os Databases do MySql');
   stlFile.Add(Format('%s', [Copy(PathBINMongoDB, 1, 2)]));
   stlFile.Add(Format('cd "%s"', [PathBINMongoDB]));
   stlFile.Add('   echo on ');
   stlFile.Add(Format('   mysqlshow.exe -h %s -P %s -u%s -p%s > %s',
                      [HostMongoDB, Port, UserName, Password, FileListDataBasesMongoDB]));

   stlFile.SaveToFile(FileNameBatchListDataBasesMongoDB);

   ExecutareAguardarConcluir(FileNameBatchListDataBasesMongoDB);
  finally
   stlFile.Free;
  end;
end;

procedure TBackupScript.GeraScriptBackupAllDataBasesMongoDB;
var
  stlFile: TStringList;
  sDataBase: String;
  i: Integer;
begin
  stlFile := TStringList.Create;

  try
   stlFile.Add('@echo off');
   stlFile.Add('echo. Listando os Databases do MongoDB');
   stlFile.Add(Format('%s', [Copy(PathBINMongoDB, 1, 2)]));
   stlFile.Add(Format('cd "%s"', [PathBINMongoDB]));

   for i := 0 to ListaDataBasesMongoDB.Count-1 do
    begin
     sDatabase := ListaDataBasesMongoDB[i];

     if LoginNoBancoComSenha then
      begin
       stlFile.Add(Format('mongodump --host %s --port %s --username %s --password %s --authenticationDatabase admin --db=%s --gzip --out %s',
                          [HostMongoDB, Port, Username, Password, sDataBase, FileNameBackup(sDataBase)]));
      end
     else
      begin
       stlFile.Add(Format('mongodump --host %s --port %s --db %s --gzip --out %s',
                          [HostMongoDB, Port, sDataBase, FileNameBackup(sDataBase)]));
      end;
    end;

   stlFile.SaveToFile(FileNameBatchBackupDataBasesMongoDB);

   ExecutareAguardarConcluir(FileNameBatchBackupDataBasesMongoDB);
  finally
   stlFile.Free;
  end;
end;

procedure TBackupScript.GeraScriptBackupAllDataBasesPostGreSql;
var
  stlFile: TStringList;
  sDataBase: String;
  i: Integer;
begin
  stlFile := TStringList.Create;

  try
   stlFile.Add('@echo off');
   stlFile.Add('   SET PGPASSWORD=B1r7i9t3a');
   stlFile.Add('echo. Listando os Databases do PostGreSql');
   stlFile.Add(Format('%s', [Copy(PathBINMongoDB, 1, 2)]));
   stlFile.Add(Format('cd "%s"', [PathBINMongoDB]));
   stlFile.Add('   echo on');

   for i := 0 to ListaDataBasesMongoDB.Count-1 do
    begin
     sDatabase := ListaDataBasesMongoDB[i];

     stlFile.Add(Format('pg_dump -h %s -p %s -U postgres -F c -b -v -f %s %s',
                        [HostMongoDB, Port, FileNameBackup(sDataBase), sDataBase]));
    end;

   stlFile.SaveToFile(FileNameBatchBackupDataBasesMongoDB);

   ExecutareAguardarConcluir(FileNameBatchBackupDataBasesMongoDB);
  finally
   stlFile.Free;
  end;
end;

procedure TBackupScript.GeraScriptBackupAllDataBasesMySql;
var
  stlFile: TStringList;
  sDataBase: String;
  i: Integer;
begin
  stlFile := TStringList.Create;

  try
   stlFile.Add('@echo off');
   stlFile.Add('echo. Listando os Databases do Mysql');
   stlFile.Add(Format('%s', [Copy(PathBINMongoDB, 1, 2)]));
   stlFile.Add(Format('cd "%s"', [PathBINMongoDB]));
   stlFile.Add('   echo on');

   for i := 0 to ListaDataBasesMongoDB.Count-1 do
    begin
     sDatabase := ListaDataBasesMongoDB[i];

     stlFile.Add(Format('mysqldump.exe -h %s -P %s -u%s -p%s --log-error="%s.log" %s > %s.sql',
                        [HostMongoDB, Port, Username, Password, FileNameBackup(sDataBase), sDataBase, FileNameBackup(sDataBase)]));
    end;

   stlFile.SaveToFile(FileNameBatchBackupDataBasesMongoDB);

   ExecutareAguardarConcluir(FileNameBatchBackupDataBasesMongoDB);
  finally
   stlFile.Free;
  end;
end;

procedure TBackupScript.CarregarListaBancosMongoDB;
var
  stlFile: TStringList;
  sDataBase: String;
  i: Integer;
  ListaBancos: TJSONArray;
begin
  stlFile := TStringList.Create;

  try
   ListaDataBasesMongoDB.Clear;
   if FileExists(FileListDataBasesMongoDB) then
    begin
     stlFile.LoadFromFile(FileListDataBasesMongoDB);
     ListaBancos := TJSONObject.ParseJSONValue(stlFile.Text) as TJSONArray;

     for i := 0 to ListaBancos.Count-1 do
      begin
       sDataBase := '';
       ListaBancos.Items[i].TryGetValue(sDataBase);

       if (sDataBase <> '') then
        ListaDataBasesMongoDB.Add(sDataBase);
      end;
    end;
  finally
   stlFile.Free;
   ListaBancos.Free;
  end;
end;

procedure TBackupScript.CarregarListaBancosPostGreSql;
var
  stlFile: TStringList;
  sDataBase: String;
  i: Integer;
begin
  stlFile := TStringList.Create;

  try
   ListaDataBasesMongoDB.Clear;
   if FileExists(FileListDataBasesMongoDB) then
    begin
     stlFile.LoadFromFile(FileListDataBasesMongoDB);

     for i := 1 to stlFile.Count-1 do
      begin
       sDataBase := '';

       if (Pos('|', stlFile[i]) > 0) then
        begin
         sDataBase := Trim(Copy(stlFile[i], 1, Pos('|', stlFile[i])-1));
        end;

       if (sDataBase <> '') then
        ListaDataBasesMongoDB.Add(sDataBase);
      end;
    end;
  finally
   stlFile.Free;
  end;
end;

procedure TBackupScript.CarregarListaBancosMysql;
var
  stlFile: TStringList;
  sDataBase: String;
  i: Integer;
begin
  stlFile := TStringList.Create;

  try
   ListaDataBasesMongoDB.Clear;
   if FileExists(FileListDataBasesMongoDB) then
    begin
     stlFile.LoadFromFile(FileListDataBasesMongoDB);

     if (stlFile.Count >= 3) then
      begin
       for i := 3 to stlFile.Count-1 do
        begin
         sDataBase := '';

         if (Pos('|', stlFile[i]) > 0) then
          begin
           sDataBase := Trim(ReplaceStr(stlFile[i], '|', ''));
          end;

         if (sDataBase <> '') then
          ListaDataBasesMongoDB.Add(sDataBase);
        end;
      end;
    end;
  finally
   stlFile.Free;
  end;
end;

function TBackupScript.CopiarBancoOrigemProducaoParaDestinoTestes(Origem, Destino: String): Boolean;
var
  stlFile: TStringList;
  sDataBase: String;
begin
  stlFile := TStringList.Create;

  try
   stlFile.Add('@echo off');
   stlFile.Add('echo. Copiando banco de dados de origem  produção para o banco de dados de destino');
   stlFile.Add(Format('%s', [Copy(PathBINMongoDB, 1, 2)]));
   stlFile.Add(Format('cd "%s"', [PathBINMongoDB]));

   if LoginNoBancoComSenha then
    begin
     stlFile.Add(Format('mongodump --host %s --port %s --username %s --password %s --authenticationDatabase admin --db=%s --out %s',
                        [HostMongoDB, Port, Username, Password, Origem, PathDestination]));
    end
   else
    begin
     stlFile.Add(Format('mongodump --host %s --port %s --db %s --out %s',
                        [HostMongoDB, Port, Origem, PathDestination]));
    end;

   stlFile.Add(Format('mongorestore --host 10.20.30.2 --port 27017 --username admin --password Q5ZubU8vTP --authenticationDatabase admin --drop --db=%s %s',
                      [Destino, FolderBackup(Origem)]));

   stlFile.Add('pause');

   stlFile.SaveToFile(FileNameCopyDatabase(Destino));

   ExecutareAguardarConcluir(FileNameCopyDatabase(Destino));
  finally
   stlFile.Free;
  end;
end;

procedure TBackupScript.RealizarBackupTodosDatabasesMongoDB;
begin
  ObterListagemBancosMongoDB;

  Sleep(2000);

  CarregarListaBancosMongoDB;

  GeraScriptBackupAllDataBasesMongoDB;
end;

procedure TBackupScript.RealizarBackupTodosDatabasesPostGreSql;
begin
  ObterListagemBancosPostGreSql;

  Sleep(2000);

  CarregarListaBancosPostGreSql;

  GeraScriptBackupAllDataBasesPostGreSql;
end;

procedure TBackupScript.RealizarBackupTodosDatabasesMySql;
begin
  ObterListagemBancosMysql;

  Sleep(2000);

  CarregarListaBancosMysql;

  GeraScriptBackupAllDataBasesMySql;
end;

end.
