unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  Redis.Commons,
  Redis.Client,
  Redis.NetLib.INDY,
  Redis.Values, Vcl.ExtCtrls

  ;

type
  TForm5 = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    FRedis: IRedisClient;
  public
    { Public declarations }
  end;

var
  Form5: TForm5;

implementation

{$R *.dfm}

procedure TForm5.FormCreate(Sender: TObject);
begin
  Self.FRedis := TRedisClient.Create('localhost', 6379);
  Self.FRedis.Connect;

  Self.Timer1.Enabled := True;
end;

procedure TForm5.Timer1Timer(Sender: TObject);
var
oRanking: TRedisArray;
begin
  Self.Timer1.Enabled := False;
  try
    Self.FRedis.ZINCRBY('RANKING:JOGO', 1, 'JOGADOR1');
    Self.FRedis.ZINCRBY('RANKING:JOGO', 1, 'JOGADOR2');

    oRanking := Self.FRedis.ZRANGE('RANKING:JOGO', 0, 10, TRedisScoreMode.WithScores);

    Self.FRedis.Z


  finally
    Self.Timer1.Enabled := True;
  end;
end;

end.
