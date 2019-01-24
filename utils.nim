proc log*[Ty](s: varargs[Ty, `$`]) =
    when not defined(release):
        stderr.writeLine(s)
        stderr.flushFile()

proc printHelpAndExit* =
    echo "usage: ./solver [-s solver_binary] input_file"
    quit(1)

proc log2*(x: Natural): Natural =
    result = 0
    var n = x
    while n > 1:
        n = n shr 1
        result += 1

proc log10*(x: Natural): Natural =
    result = 0
    var n = x
    while n > 0:
        n = n div 10
        result += 1
