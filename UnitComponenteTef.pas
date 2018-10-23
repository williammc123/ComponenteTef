unit UnitComponenteTef;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,Cappta_Gp_Api_Com_TLB, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,System.StrUtils,System.VarUtils, ActiveX, Vcl.ExtCtrls,
  Vcl.Mask;

type
  TComponenteTef = class(TForm)
    Resultado: TRichEdit;
    RichEdit1: TRichEdit;
    RichEdit2: TRichEdit;
    LabelValor: TLabel;
    valorTxt: TEdit;
    LabelParcelas: TLabel;
    LabelTipoParcelamento: TLabel;
    LabelTipoPagamento: TLabel;
    ComboBoxExParcelas: TComboBoxEx;
    ComboBoxExTiopParcelamento: TComboBoxEx;
    LabelEscolhaOperacao: TLabel;
    ComboBoxExEscolhaOperacao: TComboBoxEx;
    LabelEscolhaVia: TLabel;
    ComboBoxExEscolhaVia: TComboBoxEx;
    EditNumeroControle: TEdit;
    LabelNumeroControle: TLabel;
    ComboBoxExTipoPagamento: TComboBoxEx;
    function ConcatenarCupons(mensagemAprovada: string; cupom: string) : string;
    procedure AutenticarPdv(cliente: IClienteCappta);
    procedure AtualizarResultado(mensagem: string);
    procedure ConfigurarModoIntegracao(exibirInterface: boolean);
    procedure CriarMensagemErro(mensagem:PChar);

    procedure ExibirMensagem(mensagem:IMensagem);
    procedure ComponenteTefCreate(Sender: TObject);
    procedure ComboBoxExTipoPagamentoChange(Sender: TObject);

    procedure PagamentoDebito();

    procedure PagamentoCredito();

    function Parcelamento(): Integer;

    function IsTransacaoParcelada(): boolean;

    procedure IterarOperacaoTef();

    procedure FinalizarPagamento();

    procedure  TornarVisivelReimpressao();

    procedure Cancelamento();

    function TipoViaCliente():Integer;

    function TipoViaLojista(): Integer;

    function TipoViaTodas(): Integer;

    procedure Reimpressao();

    function GerarMensagemTransacaoAprovada : string;

    function OperacaoNaoFinalizada(iteracaoTef: IIteracaoTef): boolean;

    procedure RequisitarParametros(requisicaoParametros: IRequisicaoParametro);

    procedure ResolverTransacaoPendente(respostaTransacaoPendente: IRespostaTransacaoPendente);

    procedure ExibirDadosOperacaoAprovada(resposta: IRespostaOperacaoAprovada);

    procedure ExibirDadosOperacaoRecusada(resposta: IRespostaOperacaoRecusada);
    procedure ComboBoxExEscolhaOperacaoChange(Sender: TObject);
    procedure ComboBoxExEscolhaViaSelect(Sender: TObject);



  private
    chaveAutenticacao: string;
    cliente: IClienteCappta;
    cnpj: string;
    pdv: Int32;
    processandoPagamento: boolean;
    quantidadeCartoes: Int32;
    sessaoMultiTefEmAndamento: boolean;
    tipoVia: Integer;

  public
    { Public declarations }
  end;

var
  ComponenteTef: TComponenteTef;

const
  INTERVALO_MILISEGUNDOS: Integer = 500;

implementation

{$R *.dfm}


procedure TComponenteTef.ComboBoxExTipoPagamentoChange(Sender: TObject);
var
  indexTipoPagamento: integer;
begin
  indexTipoPagamento:= ComboBoxExTipoPagamento.ItemIndex;
    if indexTipoPagamento = 0 then
    begin
      PagamentoDebito();
    end;
     if indexTipoPagamento = 1 then
    begin
      PagamentoCredito();
    end;

end;

procedure TComponenteTef.PagamentoDebito();
  var resultado : Integer ;
  var valor: integer;
begin
   cliente.PagamentoDebito(100) ;
   IterarOperacaoTef();
end;
procedure TComponenteTef.ComponenteTefCreate(Sender:TObject);

begin
  cliente:= CoClienteCappta.Create;
  AutenticarPdv(cliente);
  ConfigurarModoIntegracao(false);
  ComponenteTef.Position := poScreenCenter;
  tipoVia :=1;
end;

procedure TComponenteTef.PagamentoCredito();

var
  detalhes: DetalhesCredito;
  quantidadeParcelas: integer;
  tipoParcelamento: integer;
  transacaoParcelada: boolean;
  valor: double;
begin
  quantidadeParcelas := ComboBoxExParcelas.ItemIndex +1;
  transacaoParcelada := IsTransacaoParcelada();
  tipoParcelamento   := Parcelamento();

  detalhes := CoDetalhesCredito.Create;
  detalhes.QuantidadeParcelas := quantidadeParcelas;
  detalhes.TransacaoParcelada := transacaoParcelada;
  detalhes.TipoParcelamento := tipoParcelamento;

  cliente.PagamentoCredito(100, detalhes);

  IterarOperacaoTef();

end;

function TcomponenteTef.Parcelamento(): Integer;
   var index,tipo : integer;

begin

  index := ComboBoxExTiopParcelamento.ItemIndex + 1;

  if index <= 1  then  Result:= 2;
  if index =  2  then  Result:= 1;

end;


function TComponenteTef.IsTransacaoParcelada():boolean;
var
  parcelas : integer;
begin
  parcelas := ComboBoxExParcelas.ItemIndex + 1;

  if parcelas >= 2 then result:= true ;
  if parcelas <  2 then  result:=False;

end;

procedure  TComponenteTef.AutenticarPdv(cliente: IClienteCappta);
var

  ChaveAutenticacao: String ;
  Cnpj: String;
  Pdv: Integer;
  erro: string;
  resultadoAutenticacao: integer;
  valorNumericoCnpj: Int64;
begin
     ChaveAutenticacao := '795180024C04479982560F61B3C2C06E';
     Pdv:= 154;
     Cnpj := '34555898000186';

    resultadoAutenticacao:= cliente.AutenticarPdv(cnpj, pdv, chaveAutenticacao);

     Case resultadoAutenticacao of
       0 : exit;
       1 : ShowMessage('Não autorizado. Por favor, realize a autenticação para utilizar o CapptaGpPlus.');
       2 : ShowMessage('O CapptaGpPlus esta sendo inicializado, tente novamente em alguns instantes.');
       3 : ShowMessage('O formato da requisição recebida pelo CapptaGpPlus é inválido.');
       4 : ShowMessage('Operação cancelada pelo operador.');
       7 : ShowMessage('Ocorreu um erro interno no CapptaGpPlus.');
       8 : ShowMessage('Ocorreu um erro na comunicação entre a CappAPI e o CapptaGpPlus.');

     end;
     Application.Terminate;
end;

procedure TComponenteTef.IterarOperacaoTef();

var
 iteracaoTef: IIteracaoTef;
begin
   Repeat

   iteracaoTef := cliente.IterarOperacaoTef();

    if Supports(iteracaoTef, IMensagem) then
    begin
       ExibirMensagem(iteracaoTef as IMensagem);
       Sleep(INTERVALO_MILISEGUNDOS);
    end;

    if Supports(iteracaoTef, IRequisicaoParametro) then RequisitarParametros(iteracaoTef as IRequisicaoParametro);
    if Supports(iteracaoTef, IRespostaTransacaoPendente) then ResolverTransacaoPendente(iteracaoTef as IRespostaTransacaoPendente);

    if Supports(iteracaoTef, IRespostaOperacaoRecusada) then ExibirDadosOperacaoRecusada(iteracaoTef as IRespostaOperacaoRecusada);
    if Supports(iteracaoTef, IRespostaOperacaoAprovada) then
    begin
       ExibirDadosOperacaoAprovada(iteracaoTef as IRespostaOperacaoAprovada);
       FinalizarPagamento();
    end;


   Until OperacaoNaoFinalizada(iteracaoTef) = false;
end;

function TComponenteTef.OperacaoNaoFinalizada(iteracaoTef:IIteracaoTef):boolean;
var tipoIteracao: integer;
begin
  tipoIteracao := iteracaoTef.TipoIteracao;
  Result:= (tipoIteracao <> 1) and (tipoIteracao <> 2);
end;

procedure TComponenteTef.ResolverTransacaoPendente(respostaTransacaoPendente: IRespostaTransacaoPendente);
var
  parametro: string;
  mensagemConvertida: string;
  acao: Int32;
  lowerBound, upperBound, contador: LongInt;
  listaTransacoes: PSafeArray;
  transacaoPendente: ITransacaoPendente;
begin
     mensagemConvertida := AnsiToUtf8(respostaTransacaoPendente.Mensagem);
     listaTransacoes := respostaTransacaoPendente.ListaTransacoesPendentes;

     SafeArrayGetLBound(listaTransacoes, 1, lowerBound);
     SafeArrayGetUBound(listaTransacoes, 1, upperBound);
     for contador := lowerBound to upperBound do
      begin
           SafeArrayGetElement(listaTransacoes, contador, transacaoPendente);
           mensagemConvertida := Concat(mensagemConvertida, sLineBreak, 'Número de Controle: ', transacaoPendente.numeroControle);
           mensagemConvertida := Concat(mensagemConvertida, sLineBreak, 'Bandeira: ', transacaoPendente.NomeBandeiraCartao);
           mensagemConvertida := Concat(mensagemConvertida, sLineBreak, 'Adquirente: ', transacaoPendente.NomeAdquirente);
           mensagemConvertida := Concat(mensagemConvertida, sLineBreak, 'Valor: ', FloatToStr(transacaoPendente.valor));
           mensagemConvertida := Concat(mensagemConvertida, sLineBreak, 'Data: ', DateTimeToStr(transacaoPendente.DataHoraAutorizacao));
      end;

     parametro := InputBox('Sample API COM', mensagemConvertida, '');

     if Length(parametro) = 0 then
     begin
       acao := 2;
       parametro := ' ';
     end
     else begin acao := 1; end;

    cliente.EnviarParametro(parametro, acao);
end;

procedure TComponenteTef.RequisitarParametros(requisicaoParametros: IRequisicaoParametro);
var
  parametro: string;
  mensagemConvertida: string;
  acao: Int32;
begin
    mensagemConvertida := AnsiToUtf8(requisicaoParametros.Mensagem);
    parametro := InputBox('Sample API COM', mensagemConvertida, '');

    if Length(parametro) = 0 then
    begin
       acao := 2;
       parametro := ' ';
    end
    else begin acao := 1; end;

    cliente.EnviarParametro(parametro, acao);

end;

procedure TComponenteTef.ExibirDadosOperacaoRecusada(resposta: IRespostaOperacaoRecusada);
var textoCodigoAnsi: string;
begin
  textoCodigoAnsi := Utf8ToAnsi('Código');
  AtualizarResultado(Format('%s: %d%s%s', [textoCodigoAnsi, resposta.CodigoMotivo, sLineBreak, resposta.Motivo])) ;
end;

procedure TComponenteTef.ExibirDadosOperacaoAprovada(resposta: IRespostaOperacaoAprovada);
var mensagemAprovada: string;
begin
    mensagemAprovada := String.Empty;

   if (resposta.CupomCliente <> null) then mensagemAprovada := Format('%s%s',[ConcatenarCupons(mensagemAprovada, resposta.CupomCliente), sLineBreak]);
   if (resposta.CupomLojista <> null) then mensagemAprovada := ConcatenarCupons(mensagemAprovada, resposta.CupomLojista);
   if (resposta.CupomReduzido <> null) then mensagemAprovada := ConcatenarCupons(mensagemAprovada, resposta.CupomReduzido);

   AtualizarResultado(mensagemAprovada);
end;

function TComponenteTef.ConcatenarCupons(mensagemAprovada: string; cupom: string) : string;
begin
  Result:= Format('%s%s%s', [mensagemAprovada, ReplaceStr(cupom, '"', ''), sLineBreak]);
end;

procedure TComponenteTef.ConfigurarModoIntegracao(exibirInterface:boolean);

var
configs: Configuracoes;
begin
    configs:= CoConfiguracoes.Create;
    configs.ExibirInterface := False;
    cliente.Configurar(configs);
end;

function TComponenteTef.GerarMensagemTransacaoAprovada : string;
var
  trecho1: string;
  trecho2: string;
  mensagem: string;
begin
  trecho1 := 'ão';
  trecho2 := '';
  mensagem := 'Transaç%s Aprovada%s!!! %s Clique em "OK" para confirmar a%s transaç%s e "Cancelar" para desfazê-la%s.';

  if sessaoMultiTefEmAndamento = true then
  begin
     trecho1 := 'ões';
     trecho2 := 's'
  end;

  Result := Format(mensagem, [trecho1, trecho2, sLineBreak, trecho2, trecho1, trecho2]);
end;

procedure TComponenteTef.CriarMensagemErro(mensagem: PChar);

begin
    Application.MessageBox(mensagem, 'Erro', MB_OK);
end;

procedure TComponenteTef.FinalizarPagamento();
var botaoSelecionado: Integer;
var mensagem: string;
begin

  mensagem := GerarMensagemTransacaoAprovada;

  cliente.ConfirmarPagamentos()

end;

procedure TComponenteTef.ComboBoxExEscolhaOperacaoChange(Sender: TObject);

var   index : integer;
begin
    index := ComboBoxExEscolhaOperacao.ItemIndex + 1;

    if index <= 1  then TornarVisivelReimpressao();
    if index >  1  then Cancelamento();

end;

procedure TComponenteTef.TornarVisivelReimpressao();
begin
    LabelEscolhaVia.Visible := true;
    ComboBoxExEscolhaVia.Visible := true;
end;

procedure TComponenteTef.ComboBoxExEscolhaViaSelect(Sender: TObject);

var index : integer;
begin

  index := ComboBoxExEscolhaVia.ItemIndex + 1;

  if index <= 1  then TipoViaTodas() ;
  if index  = 2  then TipoViaCliente();
  if index  = 2  then TipoViaLojista();

  Reimpressao();
end;

function TComponenteTef.TipoViaTodas():Integer;
begin
    tipoVia:= 1 ;
end;

function TComponenteTef.TipoViaCliente():Integer;
begin
    tipoVia:= 2 ;
end;

function TComponenteTef.TipoViaLojista():Integer;
begin
    tipoVia:= 3 ;
end;

procedure TComponenteTef.Reimpressao();

var numeroControle : string;
begin
    numeroControle := EditNumeroControle.Text;
    if numeroControle = ''  then
    begin
       cliente.ReimprimirUltimoCupom(tipoVia);
       IterarOperacaoTef();
       exit
    end;

    cliente.ReimprimirCupom(numeroControle,tipoVia);

    IterarOperacaoTef();
end;

procedure TComponenteTef.Cancelamento;

var
  numeroControle: string;
  senhaAdministrativa: string;
begin

  numeroControle := EditNumeroControle.Text;
  senhaAdministrativa:= 'cappta';

  if Length(EditNumeroControle.Text) = 0  then
  begin
     CriarMensagemErro('Forneça o número de controle');
     EditNumeroControle.Focused;
     exit;
  end;

  cliente.CancelarPagamento(senhaAdministrativa, numeroControle);

  IterarOperacaoTef();
end;

procedure  TComponenteTef.ExibirMensagem(mensagem : IMensagem);

begin
    AtualizarResultado(mensagem.Descricao);
end;

procedure TComponenteTef.AtualizarResultado(mensagem: string);
begin
   Resultado.Text:= AnsiToUtf8(mensagem);
   Resultado.Update;
end;

end.


