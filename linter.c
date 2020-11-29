// Copyright 2020 Mitchell Kember. Subject to the MIT License.

#include <assert.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Maximum number of columns allowed by the style guide.
#define MAX_COLUMNS 80

// Maximum paren nesting depth.
#define MAX_DEPTH 64

// Skip alignment checks on lines ending with this comment.
static const char NO_ALIGN_COMMENT[] = "; NOALIGN\n";

// Bit flags specifying indentation rules for an operator. The indentation of a
// line is determined by the last unclosed paren's operator.
enum IndentRules {
    // By default, operands must line up with the operator:
    //
    //     (operator
    //      operand1
    //      operand2
    //      ...)
    //
    // Or with the first operand, if it's on the same line as the operator:
    //
    //     (operator operand1
    //               operand2
    //               ...)
    //
    // Multiple operands per line are also allowed, though this should only be
    // used in special cases (e.g. import lists, format arguments):
    //
    //     (operator operand1 operand2
    //               operand3 operand4)
    //
    IR_DEFAULT = 0x00,

    // When the special bit is set, the body (if present) must be indented by
    // two spaces from the open paren:
    //
    //     (operator operand
    //       body
    //       ...)
    //
    // Operands, if any, must be on the same line as the operator.
    IR_SPECIAL = 0x01,

    // When the wrapper bit is set, the contents must be unindented:
    //
    //     (operator operand1
    //               operand2
    //     contents
    //     ...
    //     ) ; operator
    //
    // Contents come after the optional operands and (if the special bit is set)
    // the optional body. Wrapper forms can only occur at the top level or
    // nested inside other wrapper forms.
    IR_WRAPPER = 0x02,

    // When the uniform bit is set in conjunction with the special bit, the body
    // must still be indented by two spaces:
    //
    //     (operator
    //       body
    //       ...)
    //
    // But if there are operands on the same line as the operator, then
    // indentation follows the default case:
    //
    //     (operator body
    //               ...)
    //
    // In other words, all operands are uniform and they comprise the body,
    // rather than being distinct from it.
    IR_UNIFORM = 0x04,
};

// Map from operand names to indentation rules.
static const struct {
    const char *name;
    enum IndentRules rules;
} INDENT_RULES[] = {
    // Exceptional cases.
    { .name = "SICP", .rules = IR_WRAPPER },
    { .name = "begin", .rules = IR_SPECIAL | IR_UNIFORM },
    { .name = "cond", .rules = IR_SPECIAL | IR_UNIFORM },
    { .name = "library", .rules = IR_SPECIAL | IR_WRAPPER },

    // Special forms.
    { .name = "Chapter", .rules = IR_SPECIAL },
    { .name = "Exercise", .rules = IR_SPECIAL },
    { .name = "Section", .rules = IR_SPECIAL },
    { .name = "case", .rules = IR_SPECIAL },
    { .name = "define", .rules = IR_SPECIAL },
    { .name = "define-record-type", .rules = IR_SPECIAL },
    { .name = "define-syntax", .rules = IR_SPECIAL },
    { .name = "lambda", .rules = IR_SPECIAL },
    { .name = "let", .rules = IR_SPECIAL },
    { .name = "let*", .rules = IR_SPECIAL },
    { .name = "let-syntax", .rules = IR_SPECIAL },
    { .name = "let-values", .rules = IR_SPECIAL },
    { .name = "letrec", .rules = IR_SPECIAL },
    { .name = "parameterize", .rules = IR_SPECIAL },
    { .name = "syntax-case", .rules = IR_SPECIAL },
    { .name = "syntax-rules", .rules = IR_SPECIAL },
    { .name = "unless", .rules = IR_SPECIAL },
    { .name = "when", .rules = IR_SPECIAL },
    { .name = "with-mutex", .rules = IR_SPECIAL },
    { .name = "with-syntax", .rules = IR_SPECIAL },
};

// Looks up the indentation rules for the given operator.
static enum IndentRules lookup_indent_rules(
        const char *line, int start, int len) {
    const char *s = line + start;
    const int array_len = sizeof INDENT_RULES / sizeof INDENT_RULES[0];
    for (int i = 0; i < array_len; i++) {
        if (strncmp(s, INDENT_RULES[i].name, len) == 0) {
            enum IndentRules rules = INDENT_RULES[i].rules;
            // We only recognize wrapper forms occurring at the top level
            // (column 1, meaning the open paren is on column 0).
            if (start != 1) {
                rules &= ~IR_WRAPPER;
            }
            return rules;
        }
    }
    return IR_DEFAULT;
}

// Enumeration of the nested blocks used for importing.
enum ImportBlock {
    // Not an import block.
    IB_NONE,
    // Chapter/Section/Exercise block.
    IB_SEC,
    // The (use ...) block inside IB_SEC.
    IB_USE,
    // One of the (ID NAME ...) blocks inside IB_USE.
    IB_ID,
};

// Looks up the import block for the given operator. Never returns IB_ID.
static enum ImportBlock lookup_import_block(
        const char *line, int start, int len) {
    const char *s = line + start;
    if (start == 1 && (
            strncmp(s, "Chapter", len) == 0
            || strncmp(s, "Section", len) == 0
            || strncmp(s, "Exercise", len) == 0)) {
        return IB_SEC;
    }
    if (start == 3 && strncmp(s, "use", len) == 0) {
        return IB_USE;
    }
    return IB_NONE;
}

// Returns true if the Chapter/Section/Exercise ids prev (null-terminated) and
// current (substring of line) are ordered correctly.
static bool correct_id_order(
        const char *prev, const char *line, int start, int len) {
    int i, j, cmp = 0;
    for (i = 0, j = 0; prev[i] != '\0' && j < len; i++, j++) {
        char ci = prev[i], cj = line[start+j];
        if (i == 0 && ci != cj) {
            // The Chapter/Section sigil ':' (0x3a) is numerically less than the
            // Exercise sigil '?' (0x3f).
            return ci < cj;
        }
        if (ci == '.' && cj == '.') {
            if (cmp != 0) {
                return cmp < 0;
            }
            cmp = 0;
        } else if (ci == '.') {
            return false;
        } else if (cj == '.') {
            return true;
        } else if (cmp == 0) {
            cmp = ci - cj;
        }
    }
    // Simulate appending a '.' at the end.
    bool ei = prev[i] == '\0';
    bool ej = j == len;
    char ci = ei ? '.' : prev[i];
    char cj = ej ? '.' : line[start+j];
    if (ci == '.' && cj == '.' && cmp != 0) {
        return cmp < 0;
    }
    // Prefer the shorter (less specific) coming first.
    return ei;
}

// Returns true if the import names prev (null-terminated) and current
// (substring of line) are ordered correctly.
static bool correct_name_order(
        const char *prev, const char *line, int start, int len) {
    return strncmp(prev, line + start, len) < 0;
}

// Linter state for a single file.
struct State {
    // File currently being linted.
    const char *filename;
    // One-based line number.
    int lineno;
    // Cumulative status, set to 1 if there are any errors.
    int status;
    // Number of blank lines in a row seen.
    int prev_blanks;
    // True if we are inside a string.
    bool in_string;
    // Number of wrapper forms encountered.
    int num_wrappers;
    // If the last open paren was quoted, its alignment column (allowed as an
    // alternative to the 1st-operand/2-space alignment). Otherwise, -1.
    int quoted_align;
    // Number of unclosed parens that remain.
    int depth;
    // Stack of alignments, valid from stack[0] to stack[depth] inclusive. A new
    // line is expected to be indented by stack[depth] spaces. The bottom,
    // stack[0], is always 0 because top-level forms should not be indented.
    uint8_t stack[MAX_DEPTH];
    // The import block we are currently inside, or IB_NONE.
    enum ImportBlock import_mode;
    // Null-terminated string containing the last id in the import block.
    char last_import_id[MAX_COLUMNS];
    // Null-terminated string containing the last name in the import block.
    char last_import_name[MAX_COLUMNS];
};

// Emits a failure message for the current line given a zero-based column and
// printf-style format string and arguments.
static void fail(struct State *state, int column, const char *format, ...) {
    va_list args;
    va_start(args, format);
    printf("%s:%d:%d: ", state->filename, state->lineno, column + 1);
    vprintf(format, args);
    putchar('\n');
    state->status = 1;
    va_end(args);
}

// Lints the given line, which must be nonempty and end with a newline.
static void lint_line(struct State *state, const char *line, int line_len) {
    assert(line_len > 0);
    assert(line[line_len-1] == '\n');
    assert(state->depth >= 0);
    assert(state->depth < MAX_DEPTH);

    // Step 1. Check basic line length, whitespace, and comments.
    if (line_len == 1) {
        if (!state->in_string && state->prev_blanks == 1) {
            fail(state, 0, "multiple blank lines");
        }
        state->prev_blanks++;
        return;
    }
    state->prev_blanks = 0;
    if (line_len - 1 > MAX_COLUMNS) {
        fail(state, MAX_COLUMNS - 1,
            "line too long: %d > %d" , line_len, MAX_COLUMNS);
    }
    if (line[line_len-2] == ' ') {
        fail(state, line_len - 2, "trailing whitespace");
    }
    if (line[0] == ';') {
        int i;
        for (i = 1; line[i] == ';'; i++);
        if (i > 3) {
            fail(state, 0, "too many semicolons");
        } else if (i == 3 && state->lineno != 1) {
            fail(state, 0, "';;;' only allowed on first line copyright");
        }
        if (line[i] != '\n' && line[i] != ' ') {
            fail(state, i, "missing space after ';'");
        }
        return;
    }

    // Steps 2. Check spacing, alignment, and import ordering.
    const size_t na_len = sizeof NO_ALIGN_COMMENT - 1;
    const bool no_align = (size_t)line_len >= na_len
        && strncmp(line + line_len - na_len, NO_ALIGN_COMMENT, na_len) == 0;
    char prev = '\0';         // previous character
    bool escaped = false;     // last character was unescaped backslash
    bool two_spaces = false;  // saw two spaces in a row
    int word_start = 0;       // start of the last word
    enum { INDENT, NORMAL, OPERATOR, STRING, COMMENT, COMMENT_SPACE } mode =
        state->in_string ? STRING : INDENT;
    for (int i = 0; i < line_len; i++) {
        char c = line[i];
        if (c == '\t') {
            fail(state, i, "illegal character '\\t'");
        }
        switch (mode) {
        case INDENT:
            if (c == ' ') {
                break;
            }
            if (!no_align && i != state->stack[state->depth]) {
                if (i == 0 && state->depth == state->num_wrappers) {
                    // Returning to zero indentation after wrapper opening.
                    state->stack[state->depth] = 0;
                } else if (i == state->quoted_align) {
                    // Quoted form is data, not code.
                    state->stack[state->depth] = state->quoted_align;
                    state->quoted_align = -1;
                } else {
                    fail(state, i, "incorrect indentation");
                }
            }
            mode = NORMAL;
            // fallthrough
        case NORMAL:
        case OPERATOR:
            if (two_spaces && c != ' ' && c != ';') {
                two_spaces = false;
                fail(state, i, "unexpected two spaces in a row");
            }
            switch (c) {
            case '"':
                mode = STRING;
                state->in_string = true;
                break;          
            case ';':
                mode = COMMENT;
                if (prev != ' ') {
                    fail(state, i, "expected space before ';'");
                }
                break;
            case '(':
            case '[':
                mode = OPERATOR;
                state->stack[++state->depth] = i + 1;
                if (i > 0) {
                    switch (prev) {
                        case ' ': case '#': case '\'': case '(': case ',':
                        case '@': case '[': case '`':
                            break;
                        default:
                            fail(state, i, "expected space before '('");        
                            break;
                    }
                }
                if (prev == '\'' || (state->quoted_align != -1
                        && (prev == '(' || prev == '['))) {
                    state->quoted_align = i + 1;
                } else {
                    state->quoted_align = -1;
                }
                break;
            case ')':
            case ']':
                mode = NORMAL;
                if (i != 0 && state->depth == state->num_wrappers) {
                    fail(state, i, "expected ')' at start of line for wrapper");
                }
                if (prev == ' ') {
                    fail(state, i, "unexpected space before ')'");
                }
                state->depth--;
                if (state->import_mode != IB_NONE) {
                    if (state->import_mode == IB_ID) {
                        int start = word_start;
                        int len = i - start;
                        if (!correct_name_order(
                                state->last_import_name, line, start, len)) {
                            fail(state, start,
                                "incorrect import name ordering: %s > %.*s",
                                state->last_import_name, len, line + start);
                        }
                        state->last_import_name[0] = '\0';
                    } else if (state->import_mode == IB_USE) {
                        state->last_import_id[0] = '\0';
                    }
                    state->import_mode--;
                }
                break;
            case ' ':
                if (prev == ' ') {
                    two_spaces = true;
                }
                // fallthrough
            case '\n':
                if (mode == OPERATOR) {
                    mode = NORMAL;
                    int start = state->stack[state->depth];
                    int len = i - start;
                    enum IndentRules rules =
                        lookup_indent_rules(line, start, len);
                    if ((rules & IR_WRAPPER) != 0) {
                        state->num_wrappers++;
                    }
                    if (c == ' ') {
                        if ((rules & IR_SPECIAL) != 0
                                && (rules & IR_UNIFORM) == 0) {
                            state->stack[state->depth]++;
                        } else {
                            state->stack[state->depth] = i + 1;
                        }
                    } else {
                        if ((rules & IR_SPECIAL) != 0) {
                            state->stack[state->depth]++;
                        }
                    }
                    enum ImportBlock block =
                        lookup_import_block(line, start, len);
                    switch (state->import_mode) {
                    case IB_NONE:
                        if (block == IB_SEC) {
                            state->import_mode++;
                        }
                        break;
                    case IB_SEC:
                        if (block == IB_USE) {
                            state->import_mode++;
                        }
                        break;
                    case IB_USE:
                        state->import_mode++;
                        if (!correct_id_order(
                                state->last_import_id, line, start, len)) {
                            fail(state, start,
                                "incorrect import id ordering: %s > %.*s",
                                state->last_import_id, len, line + start);
                        }
                        strncpy(state->last_import_id, line + start, len);
                        state->last_import_id[len] = '\0';
                        break;
                    case IB_ID:
                        break;
                    }
                } else if (state->import_mode == IB_ID) {
                    int start = word_start;
                    int len = i - start;
                    if (!correct_name_order(
                            state->last_import_name, line, start, len)) {
                        fail(state, start,
                            "incorrect import name ordering: %s > %.*s",
                            state->last_import_name, len, line + start);
                    }
                    strncpy(state->last_import_name, line + start, len);
                    state->last_import_name[len] = '\0';
                }
                break;
            }
            break;
        case STRING:
            if (!escaped && c == '"') {
                mode = NORMAL;
                state->in_string = false;
            }
            break;
        case COMMENT:
            if (c == ';') {
                mode = COMMENT_SPACE;
                break;
            }
            // fallthrough
        case COMMENT_SPACE:
            if (c != ' ') {
                fail(state, i, "expected space after ';'");
            }
            return;
        }
        if (mode == NORMAL && prev == ' ' && c != ' ') {
            word_start = i;
        }
        prev = c;
        escaped = c == '\\' ? !escaped : false;
    }
}

// Reads and lints the given file.
static int lint(const char *filename) {
    FILE *fp = fopen(filename, "r");
    if (!fp) {
        perror(filename);
        return 1;
    }
    struct State state = {
        .filename = filename,
        .lineno = 1,
        .status = 0,
        .prev_blanks = 0,
        .in_string = false,
        .num_wrappers = 0,
        .quoted_align = 0,
        .depth = 0,
        .stack = {0},
        .import_mode = IB_NONE,
        .last_import_id = {0},
        .last_import_name = {0},
    };
    char *line = NULL;
    size_t cap = 0;
    ssize_t len;
    while ((len = getline(&line, &cap, fp)) != -1) {
        lint_line(&state, line, (int)len);
        state.lineno++;
    }
    fclose(fp);
    return state.status;
}

int main(int argc, char **argv) {
    if (argc == 1) {
        printf("usage: %s FILE ...\n", argv[0]);
        return 0;
    }
    int status = 0;
    for (int i = 1; i < argc; i++) {
        status |= lint(argv[i]);
    }
    return status;
}
