#!/usr/bin/env python3

from typing import List
from typing import Dict

import sys
import re
import argparse

REGEX = 'regex'
IGNORE_CASE = 'ignore_case'
INVERTED = 'invert_result'
FULL_MATCH = 'full_match'


def get_value(flags: Dict[str, bool], name: str) -> bool:
    if flags.get(name) is not None:
        return flags[name]
    return False


def match(needle: str, line: str, flags: Dict[str, bool]) -> bool:
    regex = get_value(flags, REGEX)
    ignoring_case = get_value(flags, IGNORE_CASE)
    full_match = get_value(flags, FULL_MATCH)

    if ignoring_case:
        needle = needle.lower()
        line = line.lower()
    if regex:
        if full_match:
            return re.fullmatch(needle, line) is not None
        return re.search(needle, line) is not None
    return needle in line if not full_match else needle == line


def preproccesing(data: List[str]) -> List[str]:
    return [line.rstrip('\n') for line in data]


def search_needle_in_src(needle: str, source: List[str],
                         flags: Dict[str, bool]) -> List[str]:

    inverted = get_value(flags, INVERTED)
    appearances = []
    for line in source:
        matches = match(needle, line, flags)
        if (matches and not inverted) or (not matches and inverted):
            appearances.append(line)
    return appearances


def print_search_result(res: Dict[str, List[str]],
                        count: bool = False):
    for key, value in res.items():
        source: str = key+':' if len(res) > 1 else ''
        if count:
            print(f'{source}{len(value)}')
            continue
        for line in value:
            print(f'{source}{line}')


def main(arg_str: List[str]):
    parser = argparse.ArgumentParser()
    parser.add_argument('-c',
                        dest='count_mode',
                        action='store_true',
                        help='count the number of appereance of needle')
    parser.add_argument('-E',
                        dest='regex_mode',
                        action='store_true',
                        help='perceive a needle as a regex')
    parser.add_argument('-i',
                        dest='ignore_case',
                        action='store_true',
                        help='ignoring case of a needle')
    parser.add_argument('-v',
                        dest='invert_result',
                        action='store_true',
                        help='invert a result i.e. all found lines turn out not found')
    parser.add_argument('-x',
                        dest='full_match',
                        action='store_true',
                        help='with this flag grep is trying to find only full matches')
    parser.add_argument('needle',
                        type=str,
                        nargs=1,
                        help='a string(or a regex) to search for')
    parser.add_argument('files',
                        nargs='*',
                        help='a sources where to search (default: stdin)')
    args = parser.parse_args(arg_str)
    res: Dict[str, List[str]] = {}
    search_flags: Dict[str, bool] = {
        REGEX: args.regex_mode,
        IGNORE_CASE: args.ignore_case,
        INVERTED: args.invert_result,
        FULL_MATCH: args.full_match
    }
    if args.files:
        for file in args.files:
            with open(file, 'r') as input_stream:
                res[file] = search_needle_in_src(
                    args.needle[0],
                    preproccesing(input_stream.readlines()),
                    search_flags
                )

    else:
        res['stdin'] = search_needle_in_src(
            args.needle[0],
            preproccesing(sys.stdin.readlines()),
            search_flags
        )
    print_search_result(res, args.count_mode)


if __name__ == '__main__':
    main(sys.argv[1:])
