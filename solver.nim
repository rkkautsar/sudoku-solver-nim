import cnf
import os
import osproc
import parseopt
import streams
import sudoku
import times
import utils

proc main() =
    var
        start = cpuTime()
        before = 0
        fileName = ""
        solver = "riss"

    for kind, key, val in getopt():
        case kind
        of cmdArgument:
            fileName = key
        of cmdShortOption, cmdLongOption:
            case key
            of "g", "glucose": solver = "glucose"
            of "r", "riss": solver = "riss"
            of "s", "solver": solver = val
            of "h", "help": printHelpAndExit()
        of cmdEnd: assert(false)
    
    if filename == "": printHelpAndExit()
        

    let inputStream = newFileStream(fileName)
    let sudoku: Sudoku = deserialize(inputStream)
    inputStream.close()
    log "Parsed input in ", cpuTime() - start
    
    start = cpuTime()
    var cnf = sudoku.generateBaseCNF()
    log "Generated ", cnf.clauses.len, " base clauses in ", cpuTime() - start

    const CNF_FILENAME = "sudoku.cnf"
    start = cpuTime()
    let cnfStream = openFileStream(CNF_FILENAME, mode = fmWrite)
    cnf.print(cnfStream)
    cnfStream.close()
    
    log "Writes cnf in ", cpuTime() - start

    var p: Process
    case solver
        of "glucose": p = startProcess("glucose", args=["-model", CNF_FILENAME], options={poUsePath})
        of "riss": p = startProcess("riss", args=[CNF_FILENAME], options={poUsePath})
        else: p = startProcess(solver, args=[CNF_FILENAME], options={poUsePath})

    start = cpuTime()
    sudoku.serialize(p.outputStream, newFileStream(stdout))
    log "Serialized cnf solution in ", cpuTime() - start
    p.close()
    
    discard tryRemoveFile(CNF_FILENAME)

when isMainModule: main()
