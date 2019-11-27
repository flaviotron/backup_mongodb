unit UMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, JvComponentBase, JvTrayIcon, IniFiles,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons, UBackupScript, Vcl.ComCtrls;

type
  TfrmMain = class(TForm)
    TrayIcon: TJvTrayIcon;
    PopupMenu: TPopupMenu;
    menuConfiguracoes: TMenuItem;
    menuSeparador2: TMenuItem;
    menuSair: TMenuItem;
    pnlBotoes: TPanel;
    btnGravar: TSpeedButton;
    btnCancelar: TSpeedButton;
    btnAjuda: TSpeedButton;
    tmrBackupMongo: TTimer;
    tmrBackupPostGreSql: TTimer;
    pgcBackupMongoDB: TPageControl;
    tbsBackupBancoTestes: TTabSheet;
    tbsParametros: TTabSheet;
    GroupBox1: TGroupBox;
    edtPathBINMongoDB: TEdit;
    GroupBox2: TGroupBox;
    edtHostMongoDB: TEdit;
    GroupBox3: TGroupBox;
    edtPort: TEdit;
    GroupBox4: TGroupBox;
    edtPathDestination: TEdit;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    edtBancoDestino: TComboBox;
    btnCopiarBancoOrigemProducaoParaDestinoTestess: TBitBtn;
    GroupBox7: TGroupBox;
    edtUserName: TEdit;
    GroupBox8: TGroupBox;
    edtPassword: TEdit;
    edtBancoOrigem: TComboBox;
    btnAddBancoOrigem: TSpeedButton;
    btnAddBancoDestino: TSpeedButton;
    gpbAdicionarNovoBanco: TGroupBox;
    GroupBox10: TGroupBox;
    GroupBox11: TGroupBox;
    BitBtn1: TBitBtn;
    edtBancoDados: TEdit;
    edtNomeBancoDados: TEdit;
    Panel1: TPanel;
    btnAdicionarNovoBanco: TSpeedButton;
    btnCancelarAdicionarNovoBanco: TSpeedButton;
    tmrBackupMySql: TTimer;
    procedure menuSairClick(Sender: TObject);
    procedure menuConfiguracoesClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tmrBackupMongoTimer(Sender: TObject);
    procedure btnGravarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnAjudaClick(Sender: TObject);
    procedure tmrBackupPostGreSqlTimer(Sender: TObject);
    procedure btnCopiarBancoOrigemProducaoParaDestinoTestessClick(
      Sender: TObject);
    procedure btnCancelarAdicionarNovoBancoClick(Sender: TObject);
    procedure btnAdicionarNovoBancoClick(Sender: TObject);
    procedure btnAddBancoOrigemClick(Sender: TObject);
    procedure btnAddBancoDestinoClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrBackupMySqlTimer(Sender: TObject);
  private
    FIniName: String;
    FAppFolder: String;
    FBaseName: String;
    INI: TIniFile;
    Backup: TBackupScript;
    procedure CopiarBancoOrigemProducaoParaDestinoTestes(Origem,
      Destino: String);
    procedure AdicionarBancoALista(TipoLista: Integer; Banco: String);
    procedure CarregarListaBancos;
    { Private declarations }
  public
    { Public declarations }
  published
    property IniName: String read FIniName;
    property AppFolder: String read FAppFolder;
    property BaseName: String read FBaseName;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btnAddBancoDestinoClick(Sender: TObject);
begin
  gpbAdicionarNovoBanco.Tag := 2;
  gpbAdicionarNovoBanco.Visible := True;
  edtBancoDados.SetFocus;
end;

procedure TfrmMain.btnAddBancoOrigemClick(Sender: TObject);
begin
  gpbAdicionarNovoBanco.Tag := 1;
  gpbAdicionarNovoBanco.Visible := True;
  edtBancoDados.SetFocus;
end;

procedure TfrmMain.btnAdicionarNovoBancoClick(Sender: TObject);
var
  sBanco: String;
begin
  if (Trim(edtBancoDados.Text) <> '') and (Trim(edtNomeBancoDados.Text) <> '') then
   begin
    sBanco := Format('%s_%s', [edtBancoDados.Text, edtNomeBancoDados.Text]);
    case gpbAdicionarNovoBanco.Tag of
     1: begin
         AdicionarBancoALista(1, sBanco);
        end;
     2: begin
         AdicionarBancoALista(2, sBanco);
        end;
    end;

    gpbAdicionarNovoBanco.Tag := 0;
    gpbAdicionarNovoBanco.Visible := False;
   end
  else ShowMessage('Preencha todos os campos!');
end;

procedure TfrmMain.AdicionarBancoALista(TipoLista: Integer; Banco: String);
var
  FileName: String;
begin
  try
   case TipoLista of
    1: begin
        FileName := ChangeFileExt(Application.ExeName, '_BANCOS_PRODUCAO.TXT');
        edtBancoOrigem.Items.Add(Banco);
        edtBancoOrigem.Items.SaveToFile(FileName);
       end;
    2: begin
        FileName := ChangeFileExt(Application.ExeName, '_BANCOS_TESTE.TXT');
        edtBancoDestino.Items.Add(Banco);
        edtBancoDestino.Items.SaveToFile(FileName);
       end;
   end;
  finally
  end;
end;

procedure TfrmMain.btnAjudaClick(Sender: TObject);
begin
  ShowMessage('Ainda não implementado!');
end;

procedure TfrmMain.btnCancelarAdicionarNovoBancoClick(Sender: TObject);
begin
  gpbAdicionarNovoBanco.Visible := False;
end;

procedure TfrmMain.btnCancelarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.btnCopiarBancoOrigemProducaoParaDestinoTestessClick(
  Sender: TObject);
begin
  CopiarBancoOrigemProducaoParaDestinoTestes(edtBancoOrigem.Text, edtBancoDestino.Text);
end;

procedure TfrmMain.CopiarBancoOrigemProducaoParaDestinoTestes(Origem, Destino: String);
var
  iPos: Integer;
begin
  iPos := Pos('_', Origem);
  if iPos > 0 then
   Origem := Copy(Origem, 1, iPos-1);

  iPos := Pos('_', Destino);
  if iPos > 0 then
   Destino := Copy(Destino, 1, iPos-1);

  if (Trim(Origem) <> '') and (Trim(Destino) <> '') then
   begin
    INI.WriteString('Config', 'BancoOrigem', edtBancoOrigem.Text);
    INI.WriteString('Config', 'BancoDestino', edtBancoDestino.Text);

    Backup.PathBINMongoDB  := INI.ReadString('Config', 'PathBINMongoDB', 'C:\Program Files\MongoDB\Server\4.0\bin');
    Backup.HostMongoDB     := INI.ReadString('Config', 'HostMongoDB', '10.20.30.25');
    Backup.Port            := INI.ReadString('Config', 'Port', '27017');
    Backup.Username        := INI.ReadString('Config', 'Username', 'admin');
    Backup.Password        := INI.ReadString('Config', 'Password', 'NuYmR5Y34U');
    Backup.PathDestination := INI.ReadString('Config', 'PathDestination', 'C:\MongoDB_Backup');
    Backup.BaseName        := ChangeFileExt(ExtractFileName(Application.ExeName), '');

    Backup.CopiarBancoOrigemProducaoParaDestinoTestes(Origem, Destino);

    ShowMessage('Copia Realizada!');
   end
  else
   ShowMessage('É necessário informar a origem e o destino!');
end;

procedure TfrmMain.btnGravarClick(Sender: TObject);
begin
  case pgcBackupMongoDB.ActivePageIndex of
   0: begin
       btnCopiarBancoOrigemProducaoParaDestinoTestess.Click;
      end;
   1: begin
       INI.WriteString('Config', 'PathBINMongoDB', edtPathBINMongoDB.Text);
       INI.WriteString('Config', 'HostMongoDB', edtHostMongoDB.Text);
       INI.WriteString('Config', 'Port', edtPort.Text);
       INI.WriteString('Config', 'Username', edtUserName.Text);
       INI.WriteString('Config', 'Password', edtPassword.Text);
       INI.WriteString('Config', 'PathDestination', edtPathDestination.Text);
       Visible := False;
      end;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Backup     := TBackupScript.Create;
  FAppFolder := ExtractFileDir(Application.ExeName);
  FIniName   := ChangeFileExt(Application.ExeName, '.INI');
  FBaseName  := ChangeFileExt(Application.ExeName, '');

  INI := TIniFile.Create(FIniName);
  edtPathBINMongoDB.Text  := INI.ReadString('Config', 'PathBINMongoDB', 'C:\Program Files\MongoDB\Server\4.0\bin');
  edtHostMongoDB.Text     := INI.ReadString('Config', 'HostMongoDB', '10.20.30.25');
  edtPort.Text            := INI.ReadString('Config', 'Port', '27017');
  edtUserName.Text        := INI.ReadString('Config', 'Username', 'admin');
  edtPassword.Text        := INI.ReadString('Config', 'Password', 'NuYmR5Y34U');
  edtPathDestination.Text := INI.ReadString('Config', 'PathDestination', 'C:\MongoDB_Backup');

  edtBancoOrigem.Text    := INI.ReadString('Config', 'BancoOrigem', '');
  edtBancoDestino.Text   := INI.ReadString('Config', 'BancoDestino', '');

  tmrBackupMongo.Enabled := (ParamCount >= 1) and (LowerCase(ParamStr(1)) = '-backupmongo');
  tmrBackupPostGreSql.Enabled := (ParamCount >= 1) and (LowerCase(ParamStr(1)) = '-backuppostgresql');
  tmrBackupMySql.Enabled := (ParamCount >= 1) and (LowerCase(ParamStr(1)) = '-backupmysql');

  if tmrBackupMongo.Enabled or tmrBackupPostGreSql.Enabled or tmrBackupMySql.Enabled then
   begin
    pgcBackupMongoDB.ActivePageIndex := 1;
    Application.ProcessMessages;
   end;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  CarregarListaBancos;
end;

procedure TfrmMain.CarregarListaBancos;
var
  FileNameProducao, FileNameTestes: String;
begin
  FileNameProducao := ChangeFileExt(Application.ExeName, '_BANCOS_PRODUCAO.TXT');
  FileNameTestes := ChangeFileExt(Application.ExeName, '_BANCOS_TESTE.TXT');

  if FileExists(FileNameProducao) then
   edtBancoOrigem.Items.LoadFromFile(FileNameProducao);

  if FileExists(FileNameTestes) then
   edtBancoDestino.Items.LoadFromFile(FileNameTestes);
end;

procedure TfrmMain.menuConfiguracoesClick(Sender: TObject);
begin
  Show;
end;

procedure TfrmMain.menuSairClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.tmrBackupMongoTimer(Sender: TObject);
begin
  tmrBackupMongo.Enabled := False;
  Caption := 'Backup MongoDB';
  TrayIcon.Hint := Caption;

  if Visible then
   Hide;

  Backup.PathBINMongoDB  := INI.ReadString('Config', 'PathBINMongoDB', 'C:\Program Files\MongoDB\Server\4.0\bin');
  Backup.HostMongoDB     := INI.ReadString('Config', 'HostMongoDB', '10.20.30.25');
  Backup.Port            := INI.ReadString('Config', 'Port', '27017');
  Backup.Username        := INI.ReadString('Config', 'Username', 'admin');
  Backup.Password        := INI.ReadString('Config', 'Password', 'NuYmR5Y34U');
  Backup.PathDestination := INI.ReadString('Config', 'PathDestination', 'C:\MongoDB_Backup');
  Backup.BaseName        := ChangeFileExt(ExtractFileName(Application.ExeName), '');

  Backup.RealizarBackupTodosDatabasesMongoDB;
  Application.Terminate;
end;

procedure TfrmMain.tmrBackupMySqlTimer(Sender: TObject);
begin
  tmrBackupMySql.Enabled := False;
  Caption := 'Backup MySql';
  TrayIcon.Hint := Caption;

  if Visible then
   Hide;

  Backup.PathBINMongoDB  := INI.ReadString('Config', 'PathBINMongoDB', 'C:\Program Files\MySQL\MySQL Shell 1.0\bin');
  Backup.HostMongoDB     := INI.ReadString('Config', 'HostMongoDB', '10.20.30.18');
  Backup.Port            := INI.ReadString('Config', 'Port', '3306');
  Backup.Username        := INI.ReadString('Config', 'Username', 'root');
  Backup.Password        := INI.ReadString('Config', 'Password', '5fDXpd8U');
  Backup.PathDestination := INI.ReadString('Config', 'PathDestination', 'F:\MySql_Web_Backup');
  Backup.BaseName        := ChangeFileExt(ExtractFileName(Application.ExeName), '');

  Backup.RealizarBackupTodosDatabasesMySql;
  Application.Terminate;
end;

procedure TfrmMain.tmrBackupPostGreSqlTimer(Sender: TObject);
begin
  tmrBackupPostGreSql.Enabled := False;
  Caption := 'Backup PostGreSql';
  TrayIcon.Hint := Caption;

  if Visible then
   Hide;

  Backup.PathBINMongoDB  := INI.ReadString('Config', 'PathBINMongoDB', 'C:\Program Files (x86)\pgAdmin 4\v4\runtime');
  Backup.HostMongoDB     := INI.ReadString('Config', 'HostMongoDB', '10.20.30.24');
  Backup.Port            := INI.ReadString('Config', 'Port', '5432');
  Backup.Username        := INI.ReadString('Config', 'Username', 'admin');
  Backup.Password        := INI.ReadString('Config', 'Password', 'NuYmR5Y34U');
  Backup.PathDestination := INI.ReadString('Config', 'PathDestination', 'F:\PostGreSql_Web_Backup');
  Backup.BaseName        := ChangeFileExt(ExtractFileName(Application.ExeName), '');

  Backup.RealizarBackupTodosDatabasesPostGreSql;
  Application.Terminate;
end;

end.
