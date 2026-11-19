# Proofs of LAWS.bend. `bend PROOF.bend` is the gate.
import Base
import ./LAWS.bend as Laws
import ./http.bend as H

def Laws.request():
  {==}

def Laws.header():
  {==}

def Laws.body():
  {==}

def Laws.length_of_parts(a, b, acc):
  match a:
    case SNil{}:
      {==}
    case SCon{h, t}:
      Laws.length_of_parts(t, b, (acc + H.Utf8.char_len(h) : U32))

def Laws.body_after_blank(rest):
  {==}

def Laws.body_skips_header(rest):
  {==}

def Laws.header_absent(name):
  {==}
