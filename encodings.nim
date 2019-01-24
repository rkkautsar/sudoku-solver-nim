import cnf
import sequtils
import utils

proc atLeastOne*(literals: seq[Literal]): seq[Clause] = @[literals]

proc atMostOnePairwise*(literals: seq[Literal]): seq[Clause] =
    result = newSeq[Clause]()
    for i in 0..<literals.len:
        for j in i+1..<literals.len:
            result.add(@[-literals[i], -literals[j]])

proc getCommanders(binaries: seq[Literal], index: int): seq[Literal] =
    var power = 1
    result = newSeq[Literal]()
    for i in 0..<binaries.len:
        if (index and power) == power:
            result.add(binaries[i])
        else:
            result.add(-binaries[i])
        power = power shl 1

proc exactlyOne*(cnf: var Cnf, literals: seq[Literal], pairwise: bool = false): seq[Clause]

proc atMostOneCommander*(cnf: var Cnf, literals: seq[Literal]): seq[Clause] =
    # Commander Encoding [Klieber and Kwon]
    if literals.len < 6:
        return atMostOnePairwise(literals)

    let m = literals.len div 3
    let groups = literals.distribute(m)
    let commanders = toSeq(cnf.numLiterals+1..cnf.numLiterals+groups.len)
    cnf.addLiterals(groups.len)
    result = newSeq[Clause]()

    # at most one variable in a group can be true
    for group in groups:
        result.add(atMostOnePairWise(group))

    for zipped in zip(commanders, groups):
        let (commander, group) = zipped
        let commanderAndGroup = @[-commander].concat(group)
        result.add(atLeastOne(commanderAndGroup))
        result.add(atMostOnePairwise(commanderAndGroup))
    
    if commanders.len >= 3:
        result.add(cnf.exactlyOne(commanders))
    else:
        result.add(cnf.exactlyOne(commanders, pairwise=true))


proc getGroupSize(n: int): int =
    let limit = n div 2
    result = 1
    while (result shl 1) - 1 <= limit:
        result = result shl 1
    result -= 1

# Not used for the moment since it's somehow takes too long
# to solve with this encoding
proc atMostOne*(cnf: var Cnf, literals: seq[Literal]): seq[Clause] =
    # Bimander Encoding [Hölldobler and Nguyen, 2013]
    let m = getGroupSize(literals.len)
    let numDigits = log2(m)
    if literals.len <= m:
        return atMostOnePairwise(literals)
    let groups = literals.distribute(m)
    let binaries = toSeq(cnf.numLiterals+1..cnf.numLiterals+numDigits)
    cnf.addLiterals(numDigits)
    result = newSeq[Clause]()

    # at most one variable in a group can be true
    for group in groups:
        result.add(atMostOnePairWise(group))

    # constraints between each variable in a group and commander variables
    for pair in groups.pairs():
        let (index, group) = pair
        let commanders = binaries.getCommanders(index)
        for literal in group:
            for commander in commanders:
                result.add(@[-literal, commander])

proc exactlyOne*(cnf: var Cnf, literals: seq[Literal], pairwise: bool = false): seq[Clause] =
    if literals.len == 0: return @[]
    result = newSeq[Clause]()
    if not pairwise:
        # result.add(cnf.atMostOne(literals))
        result.add(cnf.atMostOneCommander(literals))
    else:
        result.add(atMostOnePairwise(literals))
    result.add(atLeastOne(literals))
