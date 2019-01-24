Sudoku Solver
=============

Solves a sudoku input of arbitrary format (see [`./input.sudoku.txt`](./input.sudoku.txt)) by
encoding it as a SAT problem in CNF format, and feeding it to arbitrary
SAT Solver (e.g. `riss`, `glucose`, defaults to `riss`).
Then it parses the satisfiable model and finally outputs the completed
sudoku.

## Compiling
1. Make sure you have installed [nim](https://nim-lang.org/install.html)
2. `nim c solver.nim` or `nim c -d:release solver.nim` for release build

## Running
```sh
./solver --solver glucose input.sudoku.txt
```

---

Encoding is based on the works of [Kwon and Jain](http://www.cs.cmu.edu/~hjain/papers/sudoku-as-SAT.pdf) and at-most-one encoding by [Klieber and Kwon](https://www.cs.cmu.edu/~wklieber/papers/2007_efficient-cnf-encoding-for-selecting-1.pdf).
