# AWS Lambda custom runtime loop, over the Runtime API on plain TCP.
# Import as `Lambda` and end main with Lambda.run(~handler).
import Base
import ./http.bend as H

def Http.sent(sr: Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>) -> IO(Socket):
  match sr:
    case (sock, Done{u}):
      IO.pure(Socket, sock)
    case (sock, Fail{((code, message), rest)}):
      IO.die(Socket, code, message)

def Http.recv_step(next: Socket -> String -> IO(String), acc: String, sr: Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>) -> IO(String):
  match sr:
    case (sock, Done{None{}}):
      IO.bind(Unit, String, Socket.close(sock), u => IO.pure(String, acc))
    case (sock, Done{Some{text}}):
      next(sock, acc ++ text)
    case (sock, Fail{(code, message)}):
      IO.die(String, code, message)

# Reads until the peer closes, then closes our end.
# shortcut: a multi-byte char split across two reads may be mangled, switch to recv_bytes plus a UTF-8 decoder when events carry non-ASCII.
def Http.recv_all(fuel: Nat, sock: Socket, acc: String) -> IO(String):
  match fuel:
    case 0n:
      IO.die(String, 1, "reply too large")
    case 1n+p:
      IO.bind(Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>, String, TCP.recv(sock, 65536),
        Http.recv_step(s => a => Http.recv_all(p, s, a), acc))

# One request on its own connection; answers the raw reply.
def Http.call(+host: String, port: U32, method: String, path: String, +body: String) -> IO(String):
  do IO<String>:
    sock : Socket <- IO.try(Socket, TCP.connect(host, port))
    sr : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(sock, H.Http.request(method, path, host, body))
    sock2 : Socket <- Http.sent(sr)
    Http.recv_all(100000n, sock2, "")

def Runtime.need(m: Maybe<&2, String>, what: String) -> IO(String):
  match m:
    case None{}:
      IO.die(String, 1, what)
    case Some{value}:
      IO.pure(String, value)

# Fetches an event, answers handler(event), repeats. Lambda restarts us when fuel ends.
def Runtime.loop(~handler: String -> IO(String), fuel: Nat, +host: String, +port: U32) -> IO(Unit):
  match fuel:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+p:
      do IO<Unit>:
        raw : String <- Http.call(host, port, "GET", "/2018-06-01/runtime/invocation/next", "")
        +lines : List<&2, String> = String.split(raw, '\n')
        id : String <- Runtime.need(H.Http.header(lines, "lambda-runtime-aws-request-id:"), "no request id in reply")
        answer : String <- handler(H.Http.body(lines))
        out : String <- Http.call(host, port, "POST", "/2018-06-01/runtime/invocation/" ++ id ++ "/response", answer)
        Runtime.loop(~handler, p, host, port)

def Runtime.port(m: Maybe<&2, U32>) -> IO(U32):
  match m:
    case None{}:
      IO.die(U32, 1, "bad port in AWS_LAMBDA_RUNTIME_API")
    case Some{value}:
      IO.pure(U32, value)

def run(~handler: String -> IO(String)) -> IO(Unit):
  do IO<Unit>:
    api : String <- IO.try(String, IO.get_env("AWS_LAMBDA_RUNTIME_API"))
    +parts : List<&2, String> = String.split(api, ':')
    host : String <- Runtime.need(List.get(&2, String, parts, 0n), "no host in AWS_LAMBDA_RUNTIME_API")
    text : String <- Runtime.need(List.get(&2, String, parts, 1n), "no port in AWS_LAMBDA_RUNTIME_API")
    port : U32 <- Runtime.port(U32.read(text))
    Runtime.loop(~handler, 1000000n, host, port)
