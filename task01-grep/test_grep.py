#!/usr/bin/env python3
import grep
from grep import has_needle
from grep import find_in_file
from grep import print_res
from grep import parse_arguments
 
 
def test_integrate_all_keys_print_files_grep(tmp_path, monkeypatch, capsys):
    (tmp_path / 'a.txt').write_text('fO\nFO\nFoO\n')
    (tmp_path / 'b.txt').write_text('hello fo?o world\nxfooyfoz\nfooo\n')
    monkeypatch.chdir(tmp_path)
    grep.main(['-livx', '-E', 'fo?o', 'b.txt', 'a.txt'])
    out, err = capsys.readouterr()
    assert err == ''
    assert out == 'b.txt\n'
 
 
def test_integrate_all_keys_print_not_files_grep(tmp_path, monkeypatch, capsys):
    (tmp_path / 'a.txt').write_text('fO\nFO\nFoO\n')
    (tmp_path / 'b.txt').write_text('hello fo?o world\nxfooyfoz\nfooo\n')
    monkeypatch.chdir(tmp_path)
    grep.main(['-Livx', '-E', 'fo?o', 'b.txt', 'a.txt'])
    out, err = capsys.readouterr()
    assert err == ''
    assert out == 'a.txt\n'
 
 
def test_integrate_all_keys_count_files_grep(tmp_path, monkeypatch, capsys):
    (tmp_path / 'a.txt').write_text('fO\nFO\nFoO\n')
    (tmp_path / 'b.txt').write_text('hello fo?o world\nxfooyfoz\nfooo\n')
    monkeypatch.chdir(tmp_path)
    grep.main(['-civx', '-E', 'fo?o', 'b.txt', 'a.txt'])
    out, err = capsys.readouterr()
    assert err == ''
    assert out == 'b.txt:3\na.txt:0\n'
 
 
def test_unit_has_needle_ignore():
    s = 'aBCDEf'
    needles_in = ['A', 'a', 'aBCdef', 'de', 'eF', '']
    needles_not_in = ['AC', 'fa', 'abcdf', 'ACF']
    for needle in needles_in:
        assert has_needle(s, needle, False, True, False, False)
    for needle in needles_not_in:
        assert not has_needle(s, needle, False, True, False, False)
 
 
def test_unit_has_needle_inverted():
    s = 'abcdef'
    needles_in = ['a', 'abcdef', 'ef', '']
    needles_not_in = ['ac', 'fa', 'abcdf']
    for needle in needles_in:
        assert not has_needle(s, needle, False, False, True, False)
    for needle in needles_not_in:
        assert has_needle(s, needle, False, False, True, False)
 
 
def test_unit_has_needle_full():
    strings = ['abcdef', 'dabdabda', '1 234 5,:![qw]', '', '/']
    needles_in = ['abcdef', 'dabdabda', '1 234 5,:![qw]', '', '/']
    needles_not_in = ['abcdf', 'dabdabdab', '12345,:![qw]', ' ', '']
    for i, s in enumerate(strings):
        assert has_needle(s, needles_in[i], False, False, False, True)
        assert not has_needle(s, needles_not_in[i], False, False, False, True)
 
 
def test_unit_has_needle_ignore_full():
    strings = ['abcdEf', 'dabdAbda', '1 234 5,:![qw]', '', '/']
    needles_in = ['ABCDEF', 'DaBdAbDa', '1 234 5,:![QW]', '', '/']
    needles_not_in = ['AbcdF', 'DABDABDAB', '12345,:![qw]', ' ', '']
    for i, s in enumerate(strings):
        assert has_needle(s, needles_in[i], False, True, False, True)
        assert not has_needle(s, needles_not_in[i], False, True, False, True)
 
 
def test_unit_has_needle_regex_full():
    s = 'abacaba'
    needles_in = ['abacaba', 'aba?1?2?caba', '.......', 'aba[a-z].[a-z][a-z]']
    needles_not_in = ['', 'abacaba.', '[adc]', 'abac{2}', 'a{5,}']
    for needle in needles_in:
        assert has_needle(s, needle, True, False, False, True)
    for needle in needles_not_in:
        assert not has_needle(s, needle, True, False, False, True)
 
 
def test_unit_has_needle_regex_ignore():
    s = 'aBAcaba123adACabaaaa'
    needles_in = ['[ADC]', '.', 'D?', '', 'aBaCaBa', 'ABACABA...adacaba', 'acaba{4,}']
    needles_not_in = ['e+', 'abac{2}', 'abacaba...abacabaaaa', 'a{5,}']
    for needle in needles_in:
        assert has_needle(s, needle, True, True, False, False)
    for needle in needles_not_in:
        assert not has_needle(s, needle, True, True, False, False)
 
 
def test_unit_has_needle_all_flags():
    s = 'abACaba'
    needles_in = ['abACAba', 'ABA?1?2?CABA', '.......', 'ABA[a-z].[A-Z][A-Z]']
    needles_not_in = ['', 'ABACABA.', '[adc]', 'ABAC{2}', 'a{5,}']
    for needle in needles_in:
        assert not has_needle(s, needle, True, True, True, True)
    for needle in needles_not_in:
        assert has_needle(s, needle, True, True, True, True)
 
 
 
def test_unit_find_in_file_all_flags():
    lines = ['aOa', 'cobr', 'MaSlO', 'kavOOO', 'ms']
    needles = ['[Ao][Ao][Ao]', 'mA?sl?O?', 'c?o{1,}b?r?']
    results = [['cobr', 'MaSlO', 'kavOOO', 'ms'],
               ['aOa', 'cobr', 'kavOOO'],
               ['aOa', 'MaSlO', 'kavOOO', 'ms']]
    for i, needle in enumerate(needles):
        out = find_in_file(lines, needle, True, True, True, True)
        assert out == results[i]
 
 
 
def test_unit_print_res(capsys):
    result = [('a.txt', ['1', '2']), ('b.txt', ['1 in b', '2 in b'])]
    print_res(result, False, False, False)
    out, err = capsys.readouterr()
    assert err == ''
    assert out == 'a.txt:1\na.txt:2\nb.txt:1 in b\nb.txt:2 in b\n'
 
 
def test_unit_print_res_count(capsys):
    result = [('a.txt', ['odin', 'dva']), ('b.txt', ['odin b', 'dva b'])]
    print_res(result, True, False, False)
    out, err = capsys.readouterr()
    assert err == ''
    assert out == 'a.txt:2\nb.txt:2\n'
 
 
def test_unit_print_res_only_files(capsys):
    result = [('a.txt', ['1']), ('b.txt', ['1b']), ('kavo.txt', ['1c', '2c'])]
    print_res(result, False, True, False)
    out, err = capsys.readouterr()
    assert err == ''
    assert out == 'a.txt\nb.txt\nkavo.txt\n'
 
 
def test_unit_print_res_stdin(capsys):
    result = [('', ['1', 'dva', 'three two two,..,'])]
    print_res(result, False, False, True)
    out, err = capsys.readouterr()
    assert err == ''
    assert out == '1\ndva\nthree two two,..,\n'
 
 
 
def test_unit_parse_arguments():
    args_str = ['-livx', '-E', 'tri?s', 'b.txt', 'a.txt']
    args = parse_arguments(args_str)
    assert not args.count
    assert args.files == ['b.txt', 'a.txt']
    assert args.full_match
    assert args.ignore_case
    assert args.inverted
    assert args.needle == 'tri?s'
    assert args.only_files
    assert not args.only_not_files
    assert args.regex