# Minimal HTTP/1.0 over text: enough for the Lambda Runtime API.
import Base

# Bytes a char takes in UTF-8.
def Utf8.char_len(c: Char) -> U32:
  +n = Char.to_u32(c)
  a = Bool.to_u32(U32.is_ge(n, 128))
  b = Bool.to_u32(U32.is_ge(n, 2048))
  d = Bool.to_u32(U32.is_ge(n, 65536))
  (1 + a + b + d : U32)

def Utf8.length(s: String, acc: U32) -> U32:
  match s:
    case SNil{}:
      acc
    case SCon{h, t}:
      Utf8.length(t, (acc + Utf8.char_len(h) : U32))

# HTTP/1.0 so the server answers unchunked and closes: the reply ends at EOF.
def Http.request(method: String, path: String, host: String, +body: String) -> String:
  len = U32.show(Utf8.length(body, 0))
  method ++ " " ++ path ++ " HTTP/1.0\r\nHost: " ++ host ++ "\r\nContent-Length: " ++ len ++ "\r\n\r\n" ++ body

def Http.pick(-A: Type, yes: Unit -> A, no: Unit -> A, hit: Bool) -> A:
  match hit:
    case False{}:
      no(Unit{})
    case True{}:
      yes(Unit{})

# The lines after the first blank one.
def Http.body(lines: List<&2, String>) -> String:
  match lines:
    case Nil{}:
      ""
    case h <> +t:
      Http.pick(String, u => String.join(t, "\n"), u => Http.body(t), String.is_empty(String.trim(h)))

# The value of header `name` (lowercase, with its colon), if present.
def Http.header(lines: List<&2, String>, +name: String) -> Maybe<&2, String>:
  match lines:
    case Nil{}:
      None{}
    case +h <> t:
      Http.pick(Maybe<&2, String>, u => Some{String.trim(String.drop(h, String.length(name)))}, u => Http.header(t, name), String.starts_with(String.to_lower(h), name))
