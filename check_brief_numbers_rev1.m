function [tf_pass, report] = check_brief_numbers_rev1(app, brief_file, reference_files, opts)
%CHECK_BRIEF_NUMBERS_REV1 Check that every number in a brief matches model output.
%   [tf_pass, report] = check_brief_numbers_rev1(app, brief_file, reference_files)
%   reads the text of BRIEF_FILE (.pptx, .docx, .txt, or .md), extracts each
%   number, and checks that it equals a value in REFERENCE_FILES (.xlsx, .xls,
%   .csv, or .mat) after rounding that value to the decimals the brief shows.
%
%   A percent matches a reference value as written or times 100. A number with
%   K, M, B, thousand, million, or billion is scaled before matching.
%
%   Options:
%     ignore_values     Values to skip, such as band edges (default: none).
%     tf_ignore_years   Skip whole numbers from 1900 to 2100 (default: true).
%     tf_error_on_fail  Raise an error when any number fails (default: false).
%
%   Limits: numbers inside native PowerPoint charts and speaker notes are not
%   read. A number passes if it matches any reference value, so a small number
%   can match by chance; check the matched_source column for figures that matter.

arguments
    app %#ok<INUSA> unused; first argument by Movelist convention
    brief_file (1,1) string {mustBeFile}
    reference_files (1,:) string {mustBeFile}
    opts.ignore_values (1,:) double = []
    opts.tf_ignore_years (1,1) logical = true
    opts.tf_error_on_fail (1,1) logical = false
end

[block_text, block_loc] = extract_text_blocks(brief_file);
[ref_values, ref_source] = read_reference_values(reference_files);
if isempty(ref_values)
    error('check_brief_numbers:noReference', 'No numeric values found in the reference files.');
end

num = extract_numbers(block_text, block_loc);
if isempty(num.value)
    error('check_brief_numbers:noNumbers', 'No numbers found in %s.', brief_file);
end

n = numel(num.value);
status = strings(n, 1);
matched_ref = NaN(n, 1);
matched_source = strings(n, 1);
nearest_ref = NaN(n, 1);
nearest_source = strings(n, 1);
for i = 1:n
    d = num.displayed(i);
    k = num.decimals(i);
    tf_year = opts.tf_ignore_years && k == 0 && num.scale(i) == 1 && ~num.tf_percent(i) ...
        && ~num.tf_comma(i) && d >= 1900 && d <= 2100;
    if tf_year || (~isempty(opts.ignore_values) && ismembertol(num.value(i), opts.ignore_values, 1e-12))
        status(i) = 'ignored';
        continue
    end
    % Put each reference value in the units the brief shows.
    if num.tf_percent(i)
        cand = [ref_values; 100 * ref_values];
        cand_source = [ref_source; ref_source];
    else
        cand = ref_values / num.scale(i);
        cand_source = ref_source;
    end
    % round() here reproduces the display rounding; it is not part of a calculation.
    shown = round(cand, k);
    hit = find(abs(shown - d) <= 1e-9 * max(1, abs(d)), 1);
    [~, j] = min(abs(cand - d));
    nearest_ref(i) = cand(j);
    nearest_source(i) = cand_source(j);
    if isempty(hit)
        status(i) = 'mismatch';
    else
        status(i) = 'match';
        matched_ref(i) = cand(hit);
        matched_source(i) = cand_source(hit);
    end
end

report = table(num.location, num.token, num.displayed, num.decimals, num.value, status, ...
    matched_ref, matched_source, nearest_ref, nearest_source, num.context, ...
    'VariableNames', {'location', 'token', 'displayed', 'decimals', 'value', 'status', ...
    'matched_ref', 'matched_source', 'nearest_ref', 'nearest_source', 'context'});
tf_pass = ~any(status == 'mismatch');

if opts.tf_error_on_fail && ~tf_pass
    disp(report(status == 'mismatch', {'location', 'token', 'nearest_ref', 'nearest_source'}))
    error('check_brief_numbers:mismatch', '%d number(s) in %s do not match the reference output.', ...
        sum(status == 'mismatch'), brief_file);
end
end


function [block_text, block_loc] = extract_text_blocks(brief_file)
% Returns one text block per paragraph (slides and documents) or line (text).
% Considered: extractFileText (Text Analytics Toolbox, not installed) and
% mlreportgen.ppt (Report Generator, not installed); unzip plus xmlread is base MATLAB.
[~, ~, ext] = fileparts(brief_file);
switch lower(ext)
    case '.pptx'
        [block_text, block_loc] = read_office_xml(brief_file, 'ppt/slides/slide(\d+)\.xml$', 'a:p', 'a:t', 'slide');
    case '.docx'
        [block_text, block_loc] = read_office_xml(brief_file, 'word/document\.xml$', 'w:p', 'w:t', '');
    case {'.txt', '.md'}
        block_text = readlines(brief_file);
        block_loc = compose('line %d', (1:numel(block_text))');
    otherwise
        error('check_brief_numbers:fileType', 'Unsupported brief file type: %s', ext);
end
keep = strlength(strtrim(block_text)) > 0;
block_text = block_text(keep);
block_loc = string(block_loc(keep));
end


function [block_text, block_loc] = read_office_xml(file, part_pattern, para_tag, text_tag, part_label)
tmp = tempname;
mkdir(tmp);
cleanup = onCleanup(@() rmdir(tmp, 's'));
files = string(unzip(file, tmp));
rel = erase(replace(files, filesep, '/'), replace(string(tmp), filesep, '/') + '/');
tok = regexp(cellstr(rel), part_pattern, 'tokens', 'once'); % cellstr keeps a cell output for one file
is_part = ~cellfun(@isempty, regexp(cellstr(rel), part_pattern, 'match', 'once'));
if ~any(is_part)
    error('check_brief_numbers:noParts', 'No text parts found in %s.', file);
end
files = files(is_part);
tok = tok(is_part);
if isempty(part_label)
    part_num = ones(numel(files), 1);
else
    part_num = cellfun(@(t) str2double(t{1}), tok(:));
end
[part_num, order] = sort(part_num);
files = files(order);
text_parts = cell(numel(files), 1);
loc_parts = cell(numel(files), 1);
for f = 1:numel(files)
    doc = xmlread(files(f));
    paras = doc.getElementsByTagName(para_tag);
    n_para = paras.getLength;
    t = strings(n_para, 1);
    for p = 1:n_para
        runs = paras.item(p - 1).getElementsByTagName(text_tag);
        pieces = strings(runs.getLength, 1);
        for r = 1:runs.getLength
            pieces(r) = string(runs.item(r - 1).getTextContent);
        end
        t(p) = join(pieces, '');
    end
    text_parts{f} = t;
    if isempty(part_label)
        loc_parts{f} = compose('paragraph %d', (1:n_para)');
    else
        loc_parts{f} = compose('%s %d, paragraph %d', part_label, part_num(f), (1:n_para)');
    end
end
block_text = vertcat(text_parts{:});
block_loc = string(vertcat(loc_parts{:}));
clear cleanup
end


function num = extract_numbers(block_text, block_loc)
% No built-in finds numbers in prose, so this uses regexp. The lookarounds skip
% numbers inside words and IDs (5G, P.452, R2025b) and accept 1,234.5 forms.
% Named tokens inside a non-capturing group are dropped by regexp, so unit is its own optional group.
pattern = ['(?<![\w.,])(?<sign>[-\x{2212}]?)\$?(?<num>\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?)' ...
    '(?<unit>(?:\s*(?:%|percent\>|thousand\>|million\>|billion\>|[KMB](?![A-Za-z])))?)(?![A-Za-z\d]|\.\d)'];
[tok, match, start] = regexp(cellstr(block_text), pattern, 'names', 'match', 'start'); % cellstr keeps a cell output for one block
counts = cellfun(@numel, match);
total = sum(counts);
num.displayed = NaN(total, 1);
num.decimals = zeros(total, 1);
num.scale = ones(total, 1);
num.tf_percent = false(total, 1);
num.tf_comma = false(total, 1);
num.token = strings(total, 1);
num.location = strings(total, 1);
num.context = strings(total, 1);
row = 0;
for b = 1:numel(block_text)
    for m = 1:counts(b)
        row = row + 1;
        s = tok{b}(m);
        digits = string(s.num);
        value = str2double(erase(digits, ','));
        if strlength(s.sign) > 0
            value = -value;
        end
        dot = strfind(digits, '.');
        if ~isempty(dot)
            num.decimals(row) = strlength(digits) - dot;
        end
        unit = lower(strtrim(string(s.unit)));
        switch unit
            case {'%', 'percent'}
                num.tf_percent(row) = true;
            case {'k', 'thousand'}
                num.scale(row) = 1e3;
            case {'m', 'million'}
                num.scale(row) = 1e6;
            case {'b', 'billion'}
                num.scale(row) = 1e9;
        end
        num.displayed(row) = value;
        num.tf_comma(row) = contains(digits, ',');
        num.token(row) = string(match{b}{m});
        num.location(row) = block_loc(b);
        first = max(1, start{b}(m) - 30);
        last = min(strlength(block_text(b)), start{b}(m) + 40);
        num.context(row) = extractBetween(block_text(b), first, last);
    end
end
num.value = num.displayed .* num.scale;
end


function [values, source] = read_reference_values(reference_files)
vals = cell(numel(reference_files), 1);
srcs = cell(numel(reference_files), 1);
for f = 1:numel(reference_files)
    file = reference_files(f);
    [~, name, ext] = fileparts(file);
    switch lower(ext)
        case {'.xlsx', '.xls'}
            sheets = sheetnames(file);
            sheet_vals = cell(numel(sheets), 1);
            sheet_srcs = cell(numel(sheets), 1);
            for s = 1:numel(sheets)
                % readcell, not readtable: readtable turns unparseable text into NaN.
                v = numeric_from_cell(readcell(file, 'Sheet', sheets(s)));
                sheet_vals{s} = v;
                sheet_srcs{s} = repmat(name + ext + ' [' + sheets(s) + ']', numel(v), 1);
            end
            vals{f} = vertcat(sheet_vals{:});
            srcs{f} = vertcat(sheet_srcs{:});
        case '.csv'
            vals{f} = numeric_from_cell(readcell(file));
            srcs{f} = repmat(name + ext, numel(vals{f}), 1);
        case '.mat'
            vals{f} = collect_numeric(load(file));
            srcs{f} = repmat(name + ext, numel(vals{f}), 1);
        otherwise
            error('check_brief_numbers:fileType', 'Unsupported reference file type: %s', ext);
    end
end
values = vertcat(vals{:});
source = string(vertcat(srcs{:}));
keep = isfinite(values);
values = values(keep);
source = source(keep);
end


function v = numeric_from_cell(c)
is_num = cellfun(@(x) isnumeric(x) && isscalar(x), c);
v = double(cell2mat(c(is_num)));
v = v(:);
end


function v = collect_numeric(x)
% Gathers every numeric value from arrays, tables, structs, and cells.
if isnumeric(x)
    v = double(x(:));
elseif istable(x)
    v = collect_numeric(table2cell(x));
elseif isstruct(x)
    names = fieldnames(x);
    parts = cell(numel(x) * numel(names), 1);
    k = 0;
    for e = 1:numel(x)
        for q = 1:numel(names)
            k = k + 1;
            parts{k} = collect_numeric(x(e).(names{q}));
        end
    end
    v = vertcat(zeros(0, 1), parts{:});
elseif iscell(x)
    parts = cell(numel(x), 1);
    for e = 1:numel(x)
        parts{e} = collect_numeric(x{e});
    end
    v = vertcat(zeros(0, 1), parts{:});
else
    v = zeros(0, 1);
end
end
