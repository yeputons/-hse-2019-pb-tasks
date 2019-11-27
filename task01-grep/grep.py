#!/usr/bin/env python3
from typing import List
import sys
import re
import argparse
from pathlib import Path


def exists_in_line(pattern: str, line: str, is_regex: bool) -> bool:
    if is_regex:
        return bool(re.search(pattern, line))
    else:
        return pattern in line


def search_in_lines(lines_to_search_from: List[str], is_regex: bool,
                    pattern: str) -> List[str]:
    found_lines: List[str] = []
    for line in lines_to_search_from:
        line = line.rstrip('\n')
        if exists_in_line(pattern, line, is_regex):
            found_lines.append(line)

    return found_lines


def print_line(line: str, prefix: str):
    if len(prefix) > 0:
        print(prefix, end=':')
    print(line)


def print_results(prefix: str, is_count: bool, found_lines: List[str]):
    if is_count:
        print_line(str(len(found_lines)), prefix)
    else:
        for line in found_lines:
            print_line(line, prefix)


def find_pattern(files: List[str], is_count: bool, is_regex: bool,
                 pattern: str):
    prefix = ''
    found_lines: List[str]
    if len(files) > 0:
        for file_name in files:
            p = Path.cwd()
            file = p.joinpath(file_name)
            if file.exists() and file.is_file():
                with file.open() as in_file:
                    found_lines = search_in_lines(in_file.readlines(),
                                                  is_regex, pattern)

                    if len(files) > 1:
                        prefix = file_name
                    print_results(prefix, is_count, found_lines)
            else:
                print(f'Can not open a file:{file_name}. Error has occurred')
    else:
        found_lines = search_in_lines(sys.stdin.readlines(), is_regex, pattern)
        print_results(prefix, is_count, found_lines)


def main(args_str: List[str]):
    parser = argparse.ArgumentParser(description='searches for "needle" and prints it')
    parser.add_argument('needle', type=str, help='regular expression or str to search')
    parser.add_argument('files', nargs='*', help='files to search from')
    parser.add_argument('-E', dest='regex', action='store_true', help='search regular expression')
    parser.add_argument('-c', action='store_true', help='count')
    args = parser.parse_args(args_str)
    find_pattern(args.files, args.c, args.regex, args.needle)


if __name__ == '__main__':
    main(sys.argv[1:])
