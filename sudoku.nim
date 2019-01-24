import encodings
import cnf
import sequtils
import tables
import streams
import strformat
import strutils
import sugar
import utils
import intsets

type CellValue = tuple
    row: int
    col: int
    num: int


type Sudoku* = object
    size*: Natural
    known*: seq[CellValue]
    cellLookup*: Table[tuple[row, col: int], int]
    rowLookup*: Table[tuple[row, num: int], int]
    colLookup*: Table[tuple[col, num: int], int]
    blockLookup*: Table[tuple[blk, num: int], tuple[row, col: int]]

proc literal(sudoku: Sudoku, cellValue: CellValue, negative: bool = false): Literal =
    let base = sudoku.size * sudoku.size
    result = cellValue.row - 1
    result *= base
    result += cellValue.col - 1
    result *= base
    result += cellValue.num - 1
    result += 1 # 1-based
    if negative:
        result *= -1

proc cellValue(sudoku: Sudoku, literal: Literal): CellValue =
    assert literal > 0
    
    let base = sudoku.size * sudoku.size
    var numLiteral : int = literal
    numLiteral -= 1 # 0-based
    let num = (numLiteral mod base) + 1
    numLiteral = numLiteral div base
    let col = (numLiteral mod base) + 1
    numLiteral = numLiteral div base
    let row = (numLiteral mod base) + 1
    numLiteral = numLiteral div base
    
    assert numLiteral == 0
    
    return (row: row, col: col, num: num)


proc getBlockNum(row: int, col: int, size: Natural): int =
    return ((row - 1) div size) * size + ((col - 1) div size) + 1

proc getBlockNum(sudoku: Sudoku, row: int, col: int): int =
    return getBlockNum(row, col, sudoku.size)

proc getBlockStart(sudoku: Sudoku, row: int, col: int): tuple[row, col: int] =
    let
        blk = sudoku.getBlockNum(row, col) - 1
        col = (blk mod sudoku.size) * sudoku.size + 1
        row = (blk div sudoku.size) * sudoku.size + 1
    return (row, col)
    

proc deserialize*(s: Stream): Sudoku =
    var
        line = ""
        row = 0
        col = 0
        size = -1
        known = newSeq[CellValue]()
        cellLookup = initTable[tuple[row, col: int], int]()
        rowLookup = initTable[tuple[row, num: int], int]()
        colLookup = initTable[tuple[col, num: int], int]()
        blockLookup = initTable[tuple[blk, num: int], tuple[row, col: int]]()
    
    while s.readLine(line):
        if line.startsWith("puzzle size:"):
            size = parseInt(line.split("x")[1])
        if line.startsWith("|"):
            row += 1
            col = 0
            for token in line.split(Whitespace + {'|'}):
                if token.len > 0: col += 1
                if token.isDigit:
                    let num = token.parseInt
                    let blk = getBlockNum(row, col, size)
                    known.add((row, col, num))
                    cellLookup[(row, col)] = num
                    rowLookup[(row, num)] = col
                    colLookup[(col, num)] = row
                    blockLookup[(blk, num)] = (row, col)
    
    assert size > 0
    return Sudoku(
        size: size,
        known: known,
        cellLookup: cellLookup,
        rowLookup: rowLookup,
        colLookup: colLookup,
        blockLookup: blockLookup,
    )


proc log10(x: Natural): Natural =
    result = 0
    var n = x
    while n > 0:
        n = n div 10
        result += 1

proc serialize*(sudoku: Sudoku, input: Stream, output: Stream) =
    var
        line = ""
        n = sudoku.size * sudoku.size
        maxLit = sudoku.literal((n,n,n))
        board = newSeq[seq[int]](n)
    
    for i in 0..<n:
        board[i] = newSeq[int](n)

    while input.readLine(line):
        if line.startsWith("c ") or line.startsWith("s "):
            log line
        if line.startsWith("v "):
            let positives = line
                .substr(1)
                .splitWhitespace()
                .filter(proc (s: string) : bool = not s.startsWith('-') and not s.startsWith('0') and s.len > 0)
                .map(parseInt)
            for positive in positives:
                if positive > maxLit: continue
                let (row, col, num) = sudoku.cellValue(positive)
                board[row - 1][col - 1] = num
    
    for cellValue in sudoku.known:
        let (row, col, num) = cellValue
        board[row - 1][col - 1] = num
    
    output.writeLine(fmt"experiment: {$sudoku.size}x{$sudoku.size}")
    output.writeLine("number of tasks: 1")
    output.writeLine("task: 1")
    output.writeLine(fmt"puzzle size: {$sudoku.size}x{$sudoku.size}")
    
    let digitWidth = log10(n)
    let lineSeparator = ("+" & "-".repeat(1 + (digitWidth + 1) * sudoku.size)).repeat(sudoku.size) & "+"

    for rowStart in countup(1, n, sudoku.size):
        output.writeLine(lineSeparator)
        for row in rowStart..<rowStart+sudoku.size:
            for colStart in countup(1, n, sudoku.size):
                output.write("| ")
                for col in colStart..<colStart+sudoku.size:
                    var padded = ""
                    format(board[row - 1][col - 1], fmt"{digitWidth}", padded)
                    output.write(padded & " ")
            output.writeLine("|")
    output.writeLine(lineSeparator)

proc generateNegatives(sudoku: Sudoku): IntSet =
    let n = sudoku.size * sudoku.size

    result = initIntSet()
    for cellValue in sudoku.known:
        # let (i, cellValue) = pair
        let (row, col, num) = cellValue
        # if i mod 1000 == 1: log fmt"{i}/{sudoku.known.len}"

        # cell
        for lit in lc[sudoku.literal((row, col, i)) | (i <- 1..n, i != num), Literal]:
            result.incl(lit)
        
        # row
        for lit in lc[sudoku.literal((row, i, num)) | (i <- 1..n, i != col), Literal]:
            result.incl(lit)

        # col
        for lit in lc[sudoku.literal((i, col, num)) | (i <- 1..n, i != row), Literal]:
            result.incl(lit)

        # block
        let blk = sudoku.getBlockStart(row, col)
        for lit in lc[
            sudoku.literal((x, y, num)) |
            (
                x <- blk.row..<blk.row+sudoku.size,
                y <- blk.col..<blk.col+sudoku.size,
                x != row,
                y != col,
            ), Literal]:
            result.incl(lit)


proc generateBaseCNF*(sudoku: Sudoku): Cnf =
    let n = sudoku.size * sudoku.size
    let numLiterals = n * n * n
    
    var cnf = initCNF(numLiterals)
    var pruned = 0

    log "Generating negatives..."
    let negatives = sudoku.generateNegatives()

    log "Cell constraints..."
    # cell constraints
    for row in 1..n:
        for col in 1..n:
            if (row, col) in sudoku.cellLookup: continue
            let clauses = cnf.exactlyOne(lc[
                sudoku.literal((row, col, num)) |
                (
                    num <- 1..n, 
                    not negatives.contains(sudoku.literal((row, col, num)))
                ),
                Literal])
            for clause in clauses:
                cnf.add(clause)

    log "Row constraints..."
    # row constraints
    for row in 1..n:
        for num in 1..n:
            if (row, num) in sudoku.rowLookup: continue
            let clauses = cnf.exactlyOne(lc[
                sudoku.literal((row, col, num)) |
                (
                    col <- 1..n,
                    not negatives.contains(sudoku.literal((row, col, num)))
                ), Literal])
            for clause in clauses:
                cnf.add(clause)

    log "Col constraints..."
    # col constraints
    for col in 1..n:
        for num in 1..n:
            if (col, num) in sudoku.colLookup: continue
            let clauses = cnf.exactlyOne(lc[
                sudoku.literal((row, col, num)) |
                (
                    row <- 1..n,
                    not negatives.contains(sudoku.literal((row, col, num)))
                ), Literal])
            for clause in clauses:
                cnf.add(clause)
    
    log "Block constraints..."
    # block constraints
    for rowStart in countup(1, n, sudoku.size):
        for colStart in countup(1, n, sudoku.size):
            for num in 1..n:
                let blk = sudoku.getBlockNum(rowStart, colStart)
                if (blk, num) in sudoku.blockLookup: continue
                let literals = lc[
                    sudoku.literal((row, col, num)) |
                    (
                        row <- rowStart..<(rowStart + sudoku.size),
                        col <- colStart..<(colStart + sudoku.size),
                        not negatives.contains(sudoku.literal((row, col, num)))
                    ),
                    Literal]
                for clause in cnf.exactlyOne(literals):
                    cnf.add(clause)

    return cnf
