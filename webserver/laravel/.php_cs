<?php

// phive install php-cs-fixer
// .gitignore /.php_cs.cache
// tools/php-cs-fixer fix -v --dry-run

// @see https://styleci.readme.io/docs/presets#section-laravel
// wget -qO- "https://api.styleci.io/presets" | jq --indent 4 -r '.[] | select(.name=="laravel") | .fixers'
$styleciFixers = [
    "align_phpdoc",
    "binary_operator_spaces",
    "blank_line_after_namespace",
    "blank_line_after_opening_tag",
    "blank_line_before_return",
    "braces",
    "cast_spaces",
    "class_definition",
    "concat_without_spaces",
    "declare_equal_normalize",
    "elseif",
    "encoding",
    "full_opening_tag",
    "function_declaration",
    "function_typehint_space",
    "hash_to_slash_comment",
    "heredoc_to_nowdoc",
    "include",
    "indentation",
    "length_ordered_imports",
    "lowercase_cast",
    "lowercase_constants",
    "lowercase_keywords",
    "lowercase_static_reference",
    "magic_constant_casing",
    "magic_method_casing",
    "method_argument_space",
    "method_separation",
    "method_visibility_required",
    "native_function_casing",
    "native_function_type_declaration_casing",
    "no_alias_functions",
    "no_blank_lines_after_class_opening",
    "no_blank_lines_after_phpdoc",
    "no_blank_lines_after_throw",
    "no_blank_lines_between_imports",
    "no_blank_lines_between_traits",
    "no_closing_tag",
    "no_empty_phpdoc",
    "no_empty_statement",
    "no_extra_consecutive_blank_lines",
    "no_leading_import_slash",
    "no_leading_namespace_whitespace",
    "no_multiline_whitespace_around_double_arrow",
    "no_multiline_whitespace_before_semicolons",
    "no_short_bool_cast",
    "no_singleline_whitespace_before_semicolons",
    "no_spaces_after_function_name",
    "no_spaces_inside_offset",
    "no_spaces_inside_parenthesis",
    "no_trailing_comma_in_list_call",
    "no_trailing_comma_in_singleline_array",
    "no_trailing_whitespace",
    "no_trailing_whitespace_in_comment",
    "no_unneeded_control_parentheses",
    "no_unreachable_default_argument_value",
    "no_unused_imports",
    "no_useless_return",
    "no_whitespace_before_comma_in_array",
    "no_whitespace_in_blank_line",
    "normalize_index_brace",
    "not_operator_with_successor_space",
    "object_operator_without_whitespace",
    "phpdoc_indent",
    "phpdoc_inline_tag",
    "phpdoc_no_access",
    "phpdoc_no_package",
    "phpdoc_no_useless_inheritdoc",
    "phpdoc_scalar",
    "phpdoc_single_line_var_spacing",
    "phpdoc_summary",
    "phpdoc_to_comment",
    "phpdoc_trim",
    "phpdoc_type_to_var",
    "phpdoc_types",
    "phpdoc_var_without_name",
    "post_increment",
    "print_to_echo",
    "property_visibility_required",
    "psr4",
    "self_accessor",
    "short_array_syntax",
    "short_list_syntax",
    "short_scalar_cast",
    "simplified_null_return",
    "single_blank_line_at_eof",
    "single_blank_line_before_namespace",
    "single_class_element_per_statement",
    "single_import_per_statement",
    "single_line_after_imports",
    "single_quote",
    "space_after_semicolon",
    "standardize_not_equals",
    "switch_case_semicolon_to_colon",
    "switch_case_space",
    "ternary_operator_spaces",
    "trailing_comma_in_multiline_array",
    "trim_array_spaces",
    "unalign_equals",
    "unary_operator_spaces",
    "unix_line_endings",
    "whitespace_after_comma_in_array",
];

// wget -qO- "https://github.com/FriendsOfPHP/PHP-CS-Fixer/raw/2.15/UPGRADE.md" \
//   | sed -n -e '/^Renamed rules/,/^Changes to Fixers/s/^\([a-z]\S\+\)\s\+|\s\+\(\S\+\)\b.*$/    "\1" => "\2",/p'
$rulesUpgrade = [
    "align_double_arrow" => "binary_operator_spaces",
    "align_equals" => "binary_operator_spaces",
    "array_element_no_space_before_comma" => "no_whitespace_before_comma_in_array",
    "array_element_white_space_after_comma" => "whitespace_after_comma_in_array",
    "blankline_after_open_tag" => "blank_line_after_opening_tag",
    "concat_with_spaces" => "concat_space",
    "concat_without_spaces" => "concat_space",
    "double_arrow_multiline_whitespaces" => "no_multiline_whitespace_around_double_arrow",
    "duplicate_semicolon" => "no_empty_statement",
    "empty_return" => "simplified_null_return",
    "echo_to_print" => "no_mixed_echo_print",
    "eof_ending" => "single_blank_line_at_eof",
    "extra_empty_lines" => "no_extra_consecutive_blank_lines",
    "function_call_space" => "no_spaces_after_function_name",
    "general_phpdoc_annotation_rename" => "phpdoc_no_alias_tag",
    "indentation" => "indentation_type",
    "join_function" => "no_alias_functions",
    "line_after_namespace" => "blank_line_after_namespace",
    "linefeed" => "line_ending",
    "list_commas" => "no_trailing_comma_in_list_call",
    "logical_not_operators_with_spaces" => "not_operator_with_space",
    "logical_not_operators_with_successor_space" => "not_operator_with_successor_space",
    "long_array_syntax" => "array_syntax",
    "method_argument_default_value" => "no_unreachable_default_argument_value",
    "multiline_array_trailing_comma" => "trailing_comma_in_multiline_array",
    "multiline_spaces_before_semicolon" => "no_multiline_whitespace_before_semicolons",
    "multiple_use" => "single_import_per_statement",
    "namespace_no_leading_whitespace" => "no_leading_namespace_whitespace",
    "newline_after_open_tag" => "linebreak_after_opening_tag",
    "no_empty_lines_after_phpdocs" => "no_blank_lines_after_phpdoc",
    "object_operator" => "object_operator_without_whitespace",
    "operators_spaces" => "binary_operator_spaces",
    "ordered_use" => "ordered_imports",
    "parenthesis" => "no_spaces_inside_parenthesis",
    "php4_constructor" => "no_php4_constructor",
    "php_closing_tag" => "no_closing_tag",
    "phpdoc_params" => "phpdoc_align",
    "phpdoc_property" => "phpdoc_no_alias_tag",
    "phpdoc_short_description" => "phpdoc_summary",
    "phpdoc_type_to_var" => "phpdoc_no_alias_tag",
    "phpdoc_var_to_type" => "phpdoc_no_alias_tag",
    "print_to_echo" => "no_mixed_echo_print",
    "remove_leading_slash_use" => "no_leading_import_slash",
    "remove_lines_between_uses" => "no_extra_consecutive_blank_lines",
    "return" => "blank_line_before_return",
    "short_array_syntax" => "array_syntax",
    "short_bool_cast" => "no_short_bool_cast",
    "short_echo_tag" => "no_short_echo_tag",
    "short_tag" => "full_opening_tag",
    "single_array_no_trailing_comma" => "no_trailing_comma_in_singleline_array",
    "spaces_after_semicolon" => "space_after_semicolon",
    "spaces_before_semicolon" => "no_singleline_whitespace_before_semicolons",
    "spaces_cast" => "cast_spaces",
    "standardize_not_equal" => "standardize_not_equals",
    "strict" => "strict_comparison",
    "ternary_spaces" => "ternary_operator_spaces",
    "trailing_spaces" => "no_trailing_whitespace",
    "unalign_double_arrow" => "binary_operator_spaces",
    "unalign_equals" => "binary_operator_spaces",
    "unary_operators_spaces" => "unary_operator_spaces",
    "unneeded_control_parentheses" => "no_unneeded_control_parentheses",
    "unused_use" => "no_unused_imports",
    "visibility" => "visibility_required",
    "whitespacy_lines" => "no_whitespace_in_blank_line",
];

$styleciToPhpcs = [
    'align_phpdoc' => ['phpdoc_align' => ['align' => 'vertical']],
    'length_ordered_imports' => ['ordered_imports' => ['sort_algorithm' => 'length']],
    'method_visibility_required' => 'visibility_required',
    'no_blank_lines_after_throw' => 'no_blank_lines_after_phpdoc',
    'no_blank_lines_between_imports' => false, // FIXME single_line_after_imports?
    'no_blank_lines_between_traits' => false, // FIXME
    'no_spaces_inside_offset' => 'no_spaces_around_offset',
    'post_increment' => 'pre_increment',
    'property_visibility_required' => 'visibility_required',
    'short_list_syntax' => false, // FIXME
    'unix_line_endings' => 'line_ending',
    'long_array_syntax' => ['array_syntax' => ['syntax' => 'long']],
    'short_array_syntax' => ['array_syntax' => ['syntax' => 'short']],
];

$fixers = [];
$upgrades = array_merge($rulesUpgrade, $styleciToPhpcs);

// Convert rule names to $rule => true
array_map(function ($rule) use (&$fixers) {
    $fixers[$rule] = true;
}, $styleciFixers);

// Upgrade old rules
array_walk($upgrades, function ($new, $old) use (&$fixers) {
    if (isset($fixers[$old])) {
        unset($fixers[$old]);
        if ($new === false) return;
        if (is_array($new)) {
            $newKey = key($new);
            $fixers[$newKey] = $new[$newKey];
        } else {
            $fixers[$new] = true;
        }
    }
});

$finder = PhpCsFixer\Finder::create()
    ->in(__DIR__ . '/app')
;

return PhpCsFixer\Config::create()
    ->setRules($fixers)
    ->setFinder($finder)
    ->setRiskyAllowed(true)
;
