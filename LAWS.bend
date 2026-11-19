# The laws of this project: each is an open claim here, proven in PROOF.bend.
import Base
import ./http.bend as H

def reply() -> List<&2, String>:
  String.split("HTTP/1.0 200 OK\r\nLambda-Runtime-Aws-Request-Id: abc-1\r\n\r\n{\"a\":\n1}", '\n')

law request:
  {H.Http.request("POST", "/x", "h:1", "æ1") == "POST /x HTTP/1.0\r\nHost: h:1\r\nContent-Length: 3\r\n\r\næ1" : String}

law header:
  {H.Http.header(reply(), "lambda-runtime-aws-request-id:") == Some{"abc-1"} : Maybe<&2, String>}

law body:
  {H.Http.body(reply()) == "{\"a\":\n1}" : String}

# The length of a joined text is the lengths of its parts, counted in turn:
# Content-Length does not depend on how the body was put together.
law length_of_parts:
  for a: String
  for b: String
  for acc: U32
  {H.Utf8.length(String.append(a, b), acc) == H.Utf8.length(b, H.Utf8.length(a, acc)) : U32}

# The body is everything after the first blank line, with later blank lines kept.
law body_after_blank:
  for rest: List<&2, String>
  {H.Http.body("\r" <> rest) == String.join(rest, "\n") : String}

# A status line or header before the blank line is never part of the body.
law body_skips_header:
  for rest: List<&2, String>
  {H.Http.body("Content-Type: text/plain\r" <> rest) == H.Http.body(rest) : String}

law header_absent:
  for name: String
  {H.Http.header([], name) == None{} : Maybe<&2, String>}
