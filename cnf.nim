import strutils
import streams
import intsets

type Literal* = int
type Clause* = seq[Literal]
type Cnf* = object
    numLiterals*: int
    clauses*: seq[Clause]


proc addLiterals*(cnf: var Cnf, n: int) =
    cnf.numLiterals += n

proc initCNF*(numLiterals: int): Cnf =
    let clauses = newSeq[Clause]()

    return Cnf(
        numLiterals: numLiterals,
        clauses: clauses,
    )

proc add*(cnf: var Cnf, clause: Clause) =
    cnf.clauses.add(clause)
    

proc print*(cnf: Cnf, stream: Stream) =
    stream.writeLine("p cnf " & $cnf.numLiterals & " " & $cnf.clauses.len)
    for clause in cnf.clauses:
        for item in clause:
            stream.write($item & " ")
        stream.writeLine("0")
