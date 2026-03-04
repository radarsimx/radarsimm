% generate_docs.m - Generate Markdown documentation for RadarSimM package
%
% Usage:
%   generate_docs()           % Generate docs in 'docs' folder
%   generate_docs('output')   % Generate docs in 'output' folder

function generate_docs(output_dir)
    if nargin < 1
        output_dir = 'docs';
    end

    fprintf('RadarSimM Documentation Generator\n');
    fprintf('==================================\n\n');

    script_dir = fileparts(mfilename('fullpath'));
    package_dir = fullfile(script_dir, 'src', '+RadarSim');

    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    m_files = dir(fullfile(package_dir, '*.m'));

    class_names = cell(1, length(m_files));
    for i = 1:length(m_files)
        [~, class_names{i}] = fileparts(m_files(i).name);
    end

    fprintf('Found %d classes to document\n\n', length(class_names));

    % Generate index page
    write_index(output_dir, class_names);

    % Generate individual class pages
    for i = 1:length(class_names)
        fprintf('  %s.m\n', class_names{i});
        src_path = fullfile(package_dir, m_files(i).name);
        write_class_doc(output_dir, class_names{i}, src_path);
    end

    fprintf('\nDocs generated in: %s\n', fullfile(pwd, output_dir));
end

% ------------------------------------------------------------------
function write_index(output_dir, class_names)
    current_year = num2str(year(datetime('now')));
    fid = fopen(fullfile(output_dir, 'index.md'), 'w');
    w(fid, '---');
    w(fid, 'layout: default');
    w(fid, 'title: Home');
    w(fid, 'logo: https://github.com/radarsimx/radarsimm/blob/main/assets/radarsimm.svg');
    w(fid, '---');
    w(fid, '');
    w(fid, '# RadarSimM Documentation');
    w(fid, '');
    w(fid, 'Radar Simulator for MATLAB &mdash; [radarsimx.com](https://radarsimx.com)');
    w(fid, '');
    w(fid, '## Classes');
    w(fid, '');
    for i = 1:length(class_names)
        w(fid, '- [RadarSim.%s](%s.md)', class_names{i}, class_names{i});
    end
    w(fid, '');
    w(fid, '## Quick Start');
    w(fid, '');
    w(fid, '```matlab');
    w(fid, '%% Create channels');
    w(fid, 'tx_ch = RadarSim.TxChannel([0 0 0]);');
    w(fid, 'rx_ch = RadarSim.RxChannel([0 0 0]);');
    w(fid, '');
    w(fid, '%% Create transmitter and receiver');
    w(fid, 'tx = RadarSim.Transmitter([10e9, 11e9], 0.1, ''channels'', {tx_ch});');
    w(fid, 'rx = RadarSim.Receiver(40000, 20, 1000, 50, ''channels'', {rx_ch});');
    w(fid, '');
    w(fid, '%% Create radar and targets');
    w(fid, 'radar = RadarSim.Radar(tx, rx);');
    w(fid, 'targets = {RadarSim.PointTarget([100 0 0], [0 0 0], 10)};');
    w(fid, '');
    w(fid, '%% Run simulation');
    w(fid, 'simc = RadarSim.RadarSimulator();');
    w(fid, 'simc.Run(radar, targets);');
    w(fid, 'baseband = simc.baseband_;  %% Get simulated data');
    w(fid, '```');
    w(fid, '');
    w(fid, '---');
    w(fid, sprintf('*Copyright (C) 2023 - %s RadarSimX LLC*', current_year));
    fclose(fid);
end

% ------------------------------------------------------------------
function write_class_doc(output_dir, class_name, src_path)
    current_year = num2str(year(datetime('now')));
    lines = read_lines(src_path);
    doc = parse_class(lines);

    fid = fopen(fullfile(output_dir, [class_name '.md']), 'w');
    w(fid, '---');
    w(fid, 'layout: default');
    w(fid, 'title: %s', class_name);
    w(fid, '---');
    w(fid, '');
    w(fid, '# RadarSim.%s', class_name);
    w(fid, '');
    w(fid, '[&larr; Back to index](index.md)');
    w(fid, '');

    if ~isempty(doc.description)
        w(fid, '%s', doc.description);
        w(fid, '');
    end

    if ~isempty(doc.properties)
        w(fid, '## Properties');
        w(fid, '');
        w(fid, '| Name | Default |');
        w(fid, '|------|---------|');
        for i = 1:length(doc.properties)
            w(fid, '| `%s` | %s |', doc.properties{i}.name, doc.properties{i}.default);
        end
        w(fid, '');
    end

    if ~isempty(doc.methods)
        w(fid, '## Methods');
        w(fid, '');
        for i = 1:length(doc.methods)
            m = doc.methods{i};
            w(fid, '### `%s`', m.signature);
            w(fid, '');
            if ~isempty(m.description)
                w(fid, '%s', m.description);
                w(fid, '');
            end
            if ~isempty(m.params)
                w(fid, '**Parameters:**');
                w(fid, '');
                for j = 1:length(m.params)
                    w(fid, '- %s', m.params{j});
                end
                w(fid, '');
            end
            if ~isempty(m.returns)
                w(fid, '**Returns:** %s', m.returns);
                w(fid, '');
            end
            if ~isempty(m.example)
                w(fid, '**Example:**');
                w(fid, '');
                w(fid, '```matlab');
                for j = 1:length(m.example)
                    w(fid, '%s', m.example{j});
                end
                w(fid, '```');
                w(fid, '');
            end
        end
    end

    w(fid, '---');
    w(fid, sprintf('*Copyright (C) 2023 - %s RadarSimX LLC*', current_year));
    fclose(fid);
end

% ------------------------------------------------------------------
function doc = parse_class(lines)
    doc.description = '';
    doc.properties = {};
    doc.methods = {};

    % ---- class-level description (comments after classdef) ---------
    desc_lines = {};
    classdef_found = false;
    for i = 1:length(lines)
        ln = strtrim(lines{i});
        if ~classdef_found
            if strncmp(ln, 'classdef', 8)
                classdef_found = true;
            end
            continue;
        end
        % after classdef, collect comment lines until first non-comment
        if ~isempty(ln) && ln(1) == '%'
            txt = strtrim(ln(2:end));
            if ~isempty(txt)
                desc_lines{end+1} = txt; %#ok<AGROW>
            end
        elseif ~isempty(ln)
            break;
        end
    end
    doc.description = strjoin(desc_lines, ' ');

    % ---- properties ------------------------------------------------
    in_props = false;
    for i = 1:length(lines)
        ln = strtrim(lines{i});
        if strncmp(ln, 'properties', 10)
            in_props = true;
            continue;
        end
        if in_props && strcmp(ln, 'end')
            in_props = false;
            continue;
        end
        if in_props
            % skip comments and blank lines
            if isempty(ln) || ln(1) == '%'
                continue;
            end
            tok = regexp(ln, '^(\w+)\s*=\s*(.+);?$', 'tokens');
            if ~isempty(tok)
                p.name = tok{1}{1};
                p.default = strtrim(regexprep(tok{1}{2}, ';$', ''));
            else
                tok2 = regexp(ln, '^(\w+)', 'tokens');
                if ~isempty(tok2)
                    p.name = tok2{1}{1};
                    p.default = '';
                else
                    continue;
                end
            end
            doc.properties{end+1} = p; %#ok<AGROW>
        end
    end

    % ---- methods ----------------------------------------------------
    comment_buf = {};
    for i = 1:length(lines)
        ln = strtrim(lines{i});

        % accumulate comment lines preceding a function
        if ~isempty(ln) && ln(1) == '%'
            comment_buf{end+1} = strtrim(ln(2:end)); %#ok<AGROW>
            continue;
        end

        if strncmp(ln, 'function', 8)
            m = parse_one_method(ln, comment_buf);
            if ~isempty(m.name)
                doc.methods{end+1} = m; %#ok<AGROW>
            end
            comment_buf = {};
        else
            % non-comment, non-function line -> reset buffer
            comment_buf = {};
        end
    end
end

% ------------------------------------------------------------------
function m = parse_one_method(func_line, comment_lines)
    m.name = '';
    m.signature = '';
    m.description = '';
    m.params = {};
    m.returns = '';
    m.example = {};

    % extract signature
    m.signature = strtrim(regexprep(func_line, '^function\s*', ''));

    % extract name
    tok = regexp(func_line, 'function\s+(?:\[?[\w,\s]*\]?\s*=\s*)?(\w+)', 'tokens');
    if ~isempty(tok)
        m.name = tok{1}{1};
    end

    % parse comment block
    section = 'description';
    desc = {};
    params = {};
    ret = {};
    ex = {};

    for i = 1:length(comment_lines)
        ln = comment_lines{i};
        if isempty(ln)
            continue;
        end
        low = lower(ln);
        if strncmp(low, 'parameters:', 11) || strncmp(low, 'parameters', 10)
            section = 'params';
            continue;
        elseif strncmp(low, 'returns:', 8) || strncmp(low, 'returns', 7)
            section = 'returns';
            continue;
        elseif strncmp(low, 'example:', 8) || strncmp(low, 'example', 7)
            section = 'example';
            continue;
        end

        switch section
            case 'description'
                desc{end+1} = ln; %#ok<AGROW>
            case 'params'
                params{end+1} = ln; %#ok<AGROW>
            case 'returns'
                ret{end+1} = ln; %#ok<AGROW>
            case 'example'
                ex{end+1} = ln; %#ok<AGROW>
        end
    end

    m.description = strjoin(desc, ' ');
    m.params = params;
    m.returns = strjoin(ret, ' ');
    m.example = ex;
end

% ------------------------------------------------------------------
function lines = read_lines(filepath)
    fid = fopen(filepath, 'r');
    raw = fread(fid, '*char')';
    fclose(fid);
    lines = strsplit(raw, {'\r\n', '\n', '\r'});
end

% ------------------------------------------------------------------
function w(fid, varargin)
    % Write one line to file (with newline)
    if nargin == 2
        fprintf(fid, '%s\n', varargin{1});
    else
        fprintf(fid, [varargin{1} '\n'], varargin{2:end});
    end
end
