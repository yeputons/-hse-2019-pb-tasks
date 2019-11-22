#!/usr/bin/env python3
import random

ITERS = 1000
FLIPS = 100


def main():
    random.seed(123456)
    s = 0
    total = 0
    for _ in range(ITERS):
        total += 1
        cur_run = 0
        max_run = 0
        flips = [random.choice([0, 1]) for _ in range(FLIPS)]
        for flip in flips:
            if flip:
                cur_run += 1
                if cur_run > max_run:
                    max_run += 1
            else:
                cur_run = 0
        s += max_run
    print(s, total, s / total)


if __name__ == '__main__':
    main()
