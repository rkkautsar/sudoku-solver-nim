Sudoku Solver
=============

Solves a sudoku input of some format (see [`./input.sudoku.txt`](./input.sudoku.txt)) by encoding it as a SAT problem in CNF format, and feeding it to arbitrary SAT Solver (e.g. `riss`, `glucose`, defaults to `riss`). Then it parses the satisfiable model and finally outputs the completed sudoku.

## Compiling
1. Make sure you have installed [nim](https://nim-lang.org/install.html)
2. `nim c solver.nim` or `nim c -d:release solver.nim` for release build

## Running
Make sure you have installed a SAT solver such as [riss](https://github.com/nmanthey/riss-solver) or [glucose](http://www.labri.fr/perso/lsimon/glucose/), and it's available on your `PATH` environment variable.

```sh
./solver --solver glucose input.sudoku.txt
```

---

Encoding is based on the works of [Kwon and Jain][1] and at-most-one encoding by [Klieber and Kwon][2].

The possible values of each cell is encoded as 3-tuple `(row, col, num)` boolean literal (can be **true** or **false**), that states the truth value of "the cell at `(row, col)` is filled with the number `num`".

Then the rules is described as follows:

1. Each cell `(row, col)` has *exactly one* `num`.
2. For each row `row`, `num` has to be in *exactly one* column `col`.
3. For each column `col`, `num` has to be in *exactly one* row `row`.
4. For each block (or mini-square), `num` has to be in *exactly one* `(row, col)` in that block.

Instead of putting the prefilled numbers from the input as a unit clause `(row, col, num)`, we instead generates a set of **false** literals that is filtered when generating the rules. As reported by [Kwon and Jain][1], this results in smaller number of variables and clauses, which helps when the input size is huge. The *exactly one* encoding is encoded as *at least one* and *at most one* encodings, in which the *at most one* encoding uses commander encoding by [Klieber and Kwon][2] that results in lesser clauses and thus faster solving by SAT Solver.

[1]: http://www.cs.cmu.edu/~hjain/papers/sudoku-as-SAT.pdf
[2]: https://www.cs.cmu.edu/~wklieber/papers/2007_efficient-cnf-encoding-for-selecting-1.pdf
