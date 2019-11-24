#!/usr/bin/env python3
from typing import List, Dict, Any
import sys
import re
import argparse


def parser_init() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter,
                                     description='Search needle in each file.',
                                     epilog='When file option is not specified, '
                                            'read standard input\n'
                                            '                            Meow.')

    output_format_group = parser.add_mutually_exclusive_group()

    output_format_group.add_argument('-c',
                                     dest='do_count',
                                     action='store_true',
                                     help='print only the count of needle matches')

    output_format_group.add_argument('-l',
                                     dest='do_only_files',
                                     action='store_true',
                                     help='print only names of files where the needle was found')

    output_format_group.add_argument('-L',
                                     dest='do_only_not_files',
                                     action='store_true',
                                     help='print only names of files '
                                          'where the needle was NOT found')

    parser.add_argument('-i',
                        dest='do_ignore_case',
                        action='store_true',
                        help='ingore case')

    parser.add_argument('-v',
                        dest='do_invert',
                        action='store_true',
                        help='select only non-matching lines')

    parser.add_argument('-x',
                        dest='do_whole_line',
                        action='store_true',
                        help='match only whole lines')

    parser.add_argument('-E',
                        dest='regexE',
                        action='store_true',
                        help='needle is a regular expression')

    parser.add_argument('needle',
                        type=str,
                        help='needle to search in files')

    parser.add_argument('files',
                        nargs='*',
                        help='list of files for searching needle')

    return parser


def format_builder(options: Dict[str, Any]) -> str:
    # here format of output can be modified (in case of adding of additional flags)
    output_format = ''

    if options['do_only_files']:
        output_format += options['filename']
    else:
        if len(options['files']) > 1:
            output_format += '{}:'.format(options['filename'])

        if options['do_count']:
            output_format += '{count}'
        else:
            output_format += '{line}'
    return output_format


def options_configure(options: Dict[str, Any]) -> None:
    # here options are configured according to arguments
    if options['regexE']:
        options['regexE_flags'] = []
        if options['do_ignore_case']:
            options['regexE_flags'].append(re.IGNORECASE)
    else:
        if options['do_ignore_case']:
            options['needle'] = options['needle'].casefold()
    if options['do_only_not_files']:
        options['do_invert'] = not options['do_invert']
        options['do_only_files'] = True

    options['late_output'] = options['do_count'] or options['do_only_files']


def finder_inline(options: Dict[str, Any]) -> bool:
    # actually looks for needle in a haystack
    if options['regexE']:
        if options['do_whole_line']:
            return bool(re.fullmatch(options['needle'], options['line'], *options['regexE_flags']))
        else:
            return bool(re.search(options['needle'], options['line'], *options['regexE_flags']))
    else:
        if options['do_ignore_case']:
            options['line'] = options['line'].casefold()

        if options['do_whole_line']:
            return options['needle'] == options['line']
        else:
            return options['needle'] in options['line']


def handler(options: Dict[str, Any], final: bool) -> None:
    # do something in case if match found (e.g. increase count, print, etc)

    if final:
        if options['late_output']:
            # clause variable find if there are any
            # reason (according to arguments) to make final output

            clause = False
            clause = clause or (options['do_count'])
            clause = clause or (
                options['do_only_files'] and options['count'] > 0)

            if clause:
                print(options['format_out'].format_map(options))
    else:
        options['count'] += 1
        if not options['late_output']:
            print(options['format_out'].format_map(options))


def searcher(options: Dict[str, Any]) -> None:
    # search needle
    options['count'] = 0
    options['format_out'] = format_builder(options)

    for line in options['io']:
        line = line.rstrip('\n')
        options['line'] = line
        found = finder_inline(options)

        if options['do_invert']:
            found = not found

        if found:
            handler(options, final=False)

    handler(options, final=True)


def search_in_files(options: Dict[str, Any]):
    # look for needle in all files given
    if len(options['files']) == 0:
        options['filename'] = '(standard input)'
        options['io'] = sys.stdin

        searcher(options)

    else:
        for filename in options['files']:
            with open(filename, 'r') as io:
                options['filename'] = filename
                options['io'] = io

                searcher(options)


def main(args: List[str]):
    parser = parser_init()
    parsed_args = parser.parse_args(args)

    options: Dict[str, Any] = vars(parsed_args)
#    print(options)
    options_configure(options)
#    print(options)

    search_in_files(options)


if __name__ == '__main__':
    main(sys.argv[1:])
