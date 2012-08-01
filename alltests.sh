#!/bin/bash
set -e
make all
./test_sequenced
./test_ra
./test_ordered
./test_heap
./test_hashed
make compatible
make mru
make const
