function tests = test_check_brief_numbers_rev1
%TEST_CHECK_BRIEF_NUMBERS_REV1 Tests for check_brief_numbers_rev1 with planted errors.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
w = tempname;
mkdir(w);
tc.TestData.folder = w;
T1 = table([1234567; 89012], [0.1234; 0.0567], 'VariableNames', {'pop_impacted', 'frac_pop'});
T2 = table([45.678; 120.4], 'VariableNames', {'coord_dist_km'});
xf = fullfile(w, 'PEA_zone.xlsx');
writetable(T1, xf, 'Sheet', 'Pop');
writetable(T2, xf, 'Sheet', 'Dist');
move_list_size = 37;
agg_in_db = [-6.04; -9.71];
mf = fullfile(w, 'movelist_out.mat');
save(mf, 'move_list_size', 'agg_in_db');
tc.TestData.refs = [string(xf), string(mf)];
tc.TestData.pptx = make_office(w, 'deck.pptx', 'ppt/slides/slide1.xml', 'a', ...
    {'Population: 1,234,567 (1.2M)', 'Share: 12.3%', 'Radius: 121 km', 'Move list: 38'});
tc.TestData.docx = make_office(w, 'memo.docx', 'word/document.xml', 'w', ...
    {'Population: 89,012', 'I/N: -6.0 dB in 7125-7400 MHz, 2026'});
end

function teardownOnce(tc)
rmdir(tc.TestData.folder, 's');
end

function test_pptx_flags_planted_errors(tc)
[ok, R] = check_brief_numbers_rev1([], tc.TestData.pptx, tc.TestData.refs);
verifyFalse(tc, ok);
verifyEqual(tc, sort(R.token(R.status == 'mismatch'))', sort(["121", "38"]));
verifyEqual(tc, R.status(R.token == "1.2M"), "match");
verifyEqual(tc, R.status(R.token == "12.3%"), "match");
end

function test_docx_passes_with_ignores(tc)
[ok, R] = check_brief_numbers_rev1([], tc.TestData.docx, tc.TestData.refs, ignore_values = [7125 7400]);
verifyTrue(tc, ok);
verifyEqual(tc, R.status(R.token == "2026"), "ignored");
verifyEqual(tc, R.matched_source(R.token == "-6.0"), "movelist_out.mat");
end

function test_error_on_fail(tc)
verifyError(tc, @() check_brief_numbers_rev1([], tc.TestData.pptx, tc.TestData.refs, tf_error_on_fail = true), ...
    'check_brief_numbers:mismatch');
end

function test_no_numbers_errors(tc)
f = fullfile(tc.TestData.folder, 'empty.txt');
writelines("No figures here.", f);
verifyError(tc, @() check_brief_numbers_rev1([], f, tc.TestData.refs), 'check_brief_numbers:noNumbers');
end

function file = make_office(w, name, part, ns, paras)
% Builds a minimal Office zip that holds one text part.
root = tempname(w);
[part_dir, part_name, part_ext] = fileparts(part);
mkdir(fullfile(root, part_dir));
body = strjoin(cellfun(@(s) ['<' ns ':p><' ns ':r><' ns ':t>' s '</' ns ':t></' ns ':r></' ns ':p>'], paras, 'UniformOutput', false), '');
writelines(['<?xml version="1.0"?><root xmlns:' ns '="x">' body '</root>'], fullfile(root, part_dir, [part_name part_ext]));
zip_file = fullfile(w, [name '.zip']);
zip(zip_file, extractBefore(part, '/'), root);
file = fullfile(w, name);
movefile(zip_file, file);
end
