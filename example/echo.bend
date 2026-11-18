# Example function: answers each event wrapped in {"echo": ...}.
import Base
import ../runtime.bend as Lambda

def echo(event: String) -> IO(String):
  IO.pure(String, "{\"echo\":" ++ event ++ "}")

def main() -> IO(Unit):
  Lambda.run(~echo)
