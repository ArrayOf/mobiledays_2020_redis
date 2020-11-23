unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Data.DB, Vcl.Grids, Vcl.DBGrids, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.PG,
  FireDAC.Phys.PGDef, FireDAC.VCLUI.Wait, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.Client,

  FireDAC.Stan.StorageJSON,

  Redis.Commons,
  Redis.Client,
  Redis.NetLib.INDY,
  Redis.Values

    ;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Button1: TButton;
    Button2: TButton;
    Panel3: TPanel;
    DBGrid1: TDBGrid;
    FDConnection1: TFDConnection;
    FDQueryListarVenda: TFDQuery;
    DataSource1: TDataSource;
    Label1: TLabel;
    Label2: TLabel;
    Panel4: TPanel;
    Panel5: TPanel;
    FDQueryNovaVenda: TFDQuery;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
    FConn: IRedisClient;
    FCodigoVendedor: Integer;
    FChaveCache: string;
    procedure ListarVendas;
    procedure ExecutarVenda;
    procedure LimparCache;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  Self.ListarVendas();
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Self.ExecutarVenda;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Self.LimparCache();
end;

procedure TForm1.ExecutarVenda;
{
  Ao fazer uma venda os dados são registrados no banco de dados e por isso
  o cache deve ser limpo para evitar inconsistências
}
var
sCodigoProduto: string;
begin
  InputQuery('Nova venda', 'Código do Produto:', sCodigoProduto);

  Self.FDQueryNovaVenda.ParamByName('vendedor').Value := Self.FCodigoVendedor;
  Self.FDQueryNovaVenda.ParamByName('produto').Value := StrToInt(sCodigoProduto);
  Self.FDQueryNovaVenda.ExecSQL;

  Self.LimparCache;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Self.FDConnection1.Open;
  Self.FConn := TRedisClient.Create('localhost', 6379);
  Self.FConn.Connect;

  Self.FCodigoVendedor := 1;
  Self.FChaveCache := Format('MOBILEDAYS:2020:VENDAS:%d', [Self.FCodigoVendedor]);
end;

procedure TForm1.LimparCache;
begin
  Self.FConn.DEL(Self.FChaveCache);
end;

procedure TForm1.ListarVendas;
{
  Aqui exemplificamos um fluxo de cacheamento.

  Obviamente que este código estaria no servidor RESTful eventualmente
  desenvolvido em DataSnap.

  Codificamos aqui para efeitos didáticos.
}
const
  SETE_DIAS = 60 * 60 * 24 * 7;
var
  cInicio: Cardinal;
  sOrigem: string;
  oDados: TRedisString;
  oStream: TStringStream;
begin
  cInicio := GetTickCount;
  oStream := TStringStream.Create;

  Self.FDQueryListarVenda.Close;

  try
    oDados := Self.FConn.GET(Self.FChaveCache);

    if oDados.HasValue then
    begin
      sOrigem := 'REDIS';
      oStream.WriteString(oDados);
      oStream.Seek(0, 0);
      Self.FDQueryListarVenda.LoadFromStream(oStream, sfJSON);
      Self.FConn.EXPIRE(Self.FChaveCache, SETE_DIAS)

    end else begin
      sOrigem := 'SGBD';
      Self.FDQueryListarVenda.Open;
      Self.FDQueryListarVenda.SaveToStream(oStream, sfJSON);
      oStream.Seek(0, 0);
      Self.FConn.&SET(Self.FChaveCache, oStream.DataString, SETE_DIAS);

    end;

  finally
    Self.Panel5.Caption := Format('%s: %g segundos', [sOrigem, (GetTickCount - cInicio) / 1000]);
    oStream.Free;
  end;
end;

end.
