import Base
import ./http.bend as H

def reply() -> List<&2, String>:
  String.split("HTTP/1.0 200 OK\r\nLambda-Runtime-Aws-Request-Id: abc-1\r\n\r\n{\"a\":\n1}", '\n')

law request:
  {H.Http.request("POST", "/x", "h:1", "æ1") == "POST /x HTTP/1.0\r\nHost: h:1\r\nContent-Length: 3\r\n\r\næ1" : String}

def request():
  {==}

law header:
  {H.Http.header(reply(), "lambda-runtime-aws-request-id:") == Some{"abc-1"} : Maybe<&2, String>}

def header():
  {==}

law body:
  {H.Http.body(reply()) == "{\"a\":\n1}" : String}

def body():
  {==}
