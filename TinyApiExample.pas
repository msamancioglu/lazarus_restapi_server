program TinyApiExample;

{
  Copyright 2018, Marcus Fernstrom
  License MIT
}

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}cthreads,
  cmem, {$ENDIF}
  SysUtils,
  fphttpapp,
  httpdefs,
  httproute,
  fpjson,
  sqldb,
  sqlite3conn,
  DB;

  procedure jsonEndpoint(aRequest: TRequest; aResponse: TResponse);
  var
    jObject: TJSONObject;
  begin
    writeln(aRequest.RemoteAddress);
    writeln(aRequest.QueryString);
    jObject := TJSONObject.Create;
    try
      jObject.Booleans['success'] := True;
      jObject.Strings['data'] := 'This is a JSON object';
      jObject.Integers['numbers'] := 12345;
      aResponse.Content := jObject.AsJSON;
      aResponse.ContentType := 'application/json';
      aResponse.SendContent;
    finally
      jObject.Free;
    end;
  end;

  procedure textEndpoint(aRequest: TRequest; aResponse: TResponse);
  begin
    aResponse.Content := 'This is the default response if no other routes match.';
    aResponse.ContentType := 'text/plain';
    aResponse.SendContent;
  end;

  procedure rootEndpoint(aRequest: TRequest; aResponse: TResponse);

  var
    AConnection: TSQLite3Connection;
    ATransaction: TSQLTransaction;
    Query: TSQLQuery;
    content, line: string;

  begin
    AConnection := TSQLite3Connection.Create(nil);
    ATransaction := TSQLTransaction.Create(AConnection);
    AConnection.Transaction := ATransaction;
    AConnection.DatabaseName := './staff.sqlite';
    AConnection.Open;
    Query := TSQLQuery.Create(nil);
    Query.SQL.Text := 'select * from person';
    Query.Database := AConnection;
    Query.Open;
    content := '<html><body><table><tr><th>ID</th><th>Name</th></tr>';
    while not Query.EOF do
    begin
      Writeln('satir');
      line := '<tr><td>' + Query.FieldByName('ID').AsString + '</td><td>' +
        Query.FieldByName('full_name').AsString + '</td> </tr>';
      Writeln('ID: ', Query.FieldByName('ID').AsInteger, 'Name: ' +
        Query.FieldByName('full_name').AsString);

      content := content + line;
      Query.Next;
    end;
    Query.Close;
    AConnection.Close;
    Query.Free;
    ATransaction.Free;
    AConnection.Free;
    content := content + '<table></body></html>';
    aResponse.Content := content;
    aResponse.ContentType := 'text/html';
    aResponse.SendContent;

  end;

begin
  Application.Port := 8080;
  HTTPRouter.RegisterRoute('/json', @jsonEndpoint);
  HTTPRouter.RegisterRoute('/text', @textEndpoint);
  HTTPRouter.RegisterRoute('/data', @rootEndpoint, True);
  Application.Threaded := True;
  Application.Initialize;
  Application.Run;
end.
