// Copyright 2021 Mitchell Kember. Subject to the MIT License.

#include <assert.h>
#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

@import AppKit.NSSpellChecker;
@import Foundation.NSOrthography;
@import Foundation.NSSpellServer;
@import Foundation.NSString;
@import Foundation.NSTextCheckingResult;

// Hash of a string.
typedef uint64_t Hash;

// Sorted vector of hashes.
struct SortedHashVec {
    // Pointer to the array of hashes.
    Hash *hashes;
    // Length of the array.
    int len;
    // Capacity of the array.
    int cap;
};

// An empty SortedHashVec.
#define EMPTY_VEC ((struct SortedHashVec){NULL, 0, 0})

// Information parsed from spell-ignore.txt.
struct Ignore {
    // We ignore grammatical errors whose descriptions contain any of these
    // substrings.
    NSMutableArray<NSString *> *errors;
    // We ignore spelling errors for these words.
    NSMutableArray<NSString *> *words;
    // We ignore errors about blocks hashing to any of these values. A block is
    // an input to check_string: single lines for Markdown files and several
    // lines combined together for Scheme files.
    struct SortedHashVec blocks;
    // We ignore errors about phrases hashing to any of these values. A phrase
    // is the full range for an error, usually a single word for a spelling
    // error and a full sentence for a grammatical error.
    struct SortedHashVec phrases;
    // We ignore errors about subphrases hashing to any of these values. A
    // subphrase is a part of a phrase that a grammatical error singles out.
    struct SortedHashVec subphrases;
};

// The djb2 hashing algorithm.
static Hash hash_string(const char *s, int n) {
    Hash h = 5381;
    for (int i = 0; i < n; i++) {
        h = ((h << 5) + h) + s[i];
    }
    return h;
}

// Parser for spell-ignore.txt.
struct Parser {
    // Used only for error messages.
    const char *path;
    // Input stream.
    FILE *in;
    // Line buffer.
    char buf[128];
    // Current 1-based line number.
    int lineno;
    // Set to true at the end of a section.
    bool eos;
    // Set to true at the end of a file.
    bool eof;
};

// Initializes the parser. Returns true on success.
static bool init_parser(struct Parser *p, const char *path) {
    FILE *in = fopen(path, "r");
    if (!in) {
        perror(path);
        return false;
    }
    p->path = path;
    p->in = in;
    p->lineno = 0;
    p->eos = false;
    p->eof = false;
    return true;
}

// Closes the parser.
static void close_parser(struct Parser *p) {
    fclose(p->in);
    p->in = NULL;
}

// Prints a parsing error given a printf-style format string and arguments.
static void parse_error(struct Parser *p, const char *format, ...) {
    va_list args;
    va_start(args, format);
    fprintf(stderr, "%s:%d: ", p->path, p->lineno);
    vfprintf(stderr, format, args);
    putc('\n', stderr);
    va_end(args);
}

// Helper function for when getc(p->in) returns EOF.
static bool check_eof(struct Parser *p) {
    if (ferror(p->in)) {
        perror(p->path);
        return false;
    }
    p->eos = true;
    p->eof = true;
    return true;
}

// Parses a line (terminated by '\n' or by EOF) into p->buf and null terminates.
// Returns true on success. Prints an error and returns false on failure.
static bool parse_line(struct Parser *p) {
    p->lineno++;
    char c;
    size_t i = 0;
    while ((c = getc(p->in)) != '\n') {
        if (c == EOF) {
            if (!check_eof(p)) return false;
            break;
        }
        if (i >= sizeof p->buf - 1) {
            parse_error(p, "buffer too small");
            return false;
        }
        p->buf[i++] = c;
    }
    p->buf[i++] = '\0';
    return true;
}

// Like parse_line, but requires a four-space indent and does not store it.
static bool parse_entry(struct Parser *p) {
    for (int i = 0; i < 4; i++) {
        char c = getc(p->in);
        if (c == EOF) {
            if (!check_eof(p)) return false;
            if (i == 0) return true;
        }
        if (c != ' ') {
            if (i == 0) {
                ungetc(c, p->in);
                p->eos = true;
                return true;
            }
            parse_error(p, "expected 4 space indent");
            return false;
        }
    }
    return parse_line(p);
}

// Parses an array of string entries.
static bool parse_array(struct Parser *p, NSMutableArray<NSString *> *strings) {
    for (;;) {
        if (!parse_entry(p)) return false;
        if (p->eos) break;
        [strings addObject:@(p->buf)];
    }
    return true;
}

// Parses a single hex digit.
static bool parse_hex(struct Parser *p, char hex, int *out) {
    if (hex >= '0' && hex <= '9') {
        *out = hex - '0';
        return true;
    }
    if (hex >= 'a' && hex <= 'f') {
        *out = hex - 'a' + 10;
        return true;
    }
    parse_error(p, "%c: invalid hex digit", hex);
    return false;
}

// Parses an array of hash entries.
static bool parse_hashes(struct Parser *p, struct SortedHashVec *out) {
    int len = 0;
    int cap = 32;
    Hash *hashes = malloc(cap * sizeof(Hash));
    Hash prev = 0;
    for (;;) {
        if (!parse_entry(p)) return false;
        if (p->eos) break;
        if (len >= cap) {
            cap *= 2;
            hashes = realloc(hashes, cap * sizeof(Hash));
        }
        Hash hash = 0;
        char *ptr = p->buf;
        while (*ptr) {
            int bin;
            if (!parse_hex(p, *ptr++, &bin)) return false;
            hash = (hash << 4) | bin;
        }
        if (hash <= prev) {
            parse_error(p, "hashes are not sorted");
            return false;
        }
        prev = hash;
        hashes[len++] = hash;
    }
    out->hashes = hashes;
    out->len = len;
    out->cap = cap;
    return true;
}

// Parses spell-ignore.txt. Returns true on success.
static bool parse_file(struct Parser *p, struct Ignore *out) {
    out->errors = [[NSMutableArray alloc] init];
    out->words = [[NSMutableArray alloc] init];
    out->blocks = EMPTY_VEC;
    out->phrases = EMPTY_VEC;
    out->subphrases = EMPTY_VEC;
    for (;;) {
        if (!parse_line(p)) return false;
        if (p->eof) break;
        p->eos = false;
        if (strcmp(p->buf, "errors") == 0) {
            if (!parse_array(p, out->errors)) return false;
        } else if (strcmp(p->buf, "words") == 0) {
            if (!parse_array(p, out->words)) return false;
        } else if (strcmp(p->buf, "blocks") == 0) {
            if (!parse_hashes(p, &out->blocks)) return false;
        } else if (strcmp(p->buf, "phrases") == 0) {
            if (!parse_hashes(p, &out->phrases)) return false;
        } else if (strcmp(p->buf, "subphrases") == 0) {
            if (!parse_hashes(p, &out->subphrases)) return false;
        } else {
            parse_error(p, "%s: invalid section", p->buf);
            return false;
        }
    }
    return true;
}

// Inverse of parse_array.
static void write_array(FILE *out, NSArray<NSString *> *array) {
    for (NSString *string in array) {
        fprintf(out, "    %s\n", [string UTF8String]);
    }
}

// Inverse of parse_hex.
static void write_hex(FILE *out, int bin) {
    assert(bin >= 0 && bin <= 15);
    if (bin < 10) {
        putc('0' + bin, out);
    } else {
        putc('a' + bin - 10, out);
    }
}

// Inverse of parse_hashes.
static void write_hashes(FILE *out, struct SortedHashVec vec) {
    for (int i = 0; i < vec.len; i++) {
        fputs("    ", out);
        for (int j = sizeof(Hash) * 8 - 4; j >= 0; j -= 4) {
            write_hex(out, (vec.hashes[i] >> j) & 0xf);
        }
        putc('\n', out);
    }
}

// Inverse of parse_file.
static bool write_ignore_file(const struct Ignore *ignore, const char *path) {
    FILE *file = fopen(path, "w");
    if (!file) {
        perror(path);
        return false;
    }
    fprintf(file, "errors\n");
    write_array(file, ignore->errors);
    fprintf(file, "words\n");
    write_array(file, ignore->words);
    fprintf(file, "blocks\n");
    write_hashes(file, ignore->blocks);
    fprintf(file, "phrases\n");
    write_hashes(file, ignore->phrases);
    fprintf(file, "subphrases\n");
    write_hashes(file, ignore->subphrases);
    return true;
}

// Hashes the given range in the string.
static Hash hash_range(const char *str, NSRange range) {
    return hash_string(str + range.location, range.length);
}

// Returns -1 if hash occurs in vec, otherwise returns the index where hash
// should be inserted into vec.
static int find_hash(struct SortedHashVec vec, Hash hash) {
    // Binary search.
    int lo = 0;
    int hi = vec.len;
    while (lo < hi) {
        int mid = (lo + hi) / 2;
        Hash h = vec.hashes[mid];
        if (hash == h) return -1;
        if (hash < h)
            hi = mid;
        else
            lo = mid + 1;
    }
    return lo;
}

// Returns true if vec contains hash h.
static bool contains_hash(struct SortedHashVec vec, Hash hash) {
    return find_hash(vec, hash) == -1;
}

// Adds a hash to a SortedHashVec in the correct position.
static void add_hash(struct SortedHashVec *vec, Hash hash) {
    if (vec->len >= vec->cap) {
        vec->cap *= 2;
        vec->hashes = realloc(vec->hashes, vec->cap * sizeof(Hash));
    }
    int dst = find_hash(*vec, hash);
    if (dst == -1) {
        return;
    }
    for (int i = vec->len; i > dst; i--) {
        vec->hashes[i] = vec->hashes[i - 1];
    }
    vec->len++;
    vec->hashes[dst] = hash;
}

// Returns true if we should skip all errors for the given block.
static bool should_skip_block(const struct Ignore *ignore, const char *str,
                              NSRange range) {
    return contains_hash(ignore->blocks, hash_range(str, range));
}

// Returns true if we should skip all errors for the given phrase.
static bool should_skip_phrase(const struct Ignore *ignore, const char *str,
                               NSRange range) {
    return contains_hash(ignore->phrases, hash_range(str, range));
}

// Given a range r2 relative to r1, returns r2 as an absolute range.
static NSRange add_ranges(NSRange r1, NSRange r2) {
    r2.location += r1.location;
    return r2;
}

// Returns true if we should skip a particular grammatical error about the given
// subphrase (subrange_value) within a phrase (range).
static bool should_skip_subphrase(const struct Ignore *ignore, const char *str,
                                  NSRange range, NSValue *subrange_value,
                                  NSString *description) {
    for (NSString *error in ignore->errors) {
        if ([description containsString:error]) {
            return true;
        }
    }
    if (!subrange_value) {
        return false;
    }
    NSRange subrange = add_ranges(range, subrange_value.rangeValue);
    return contains_hash(ignore->subphrases, hash_range(str, subrange));
}

// Wrapper around NSSpellChecker that stores the document tag.
struct SpellChecker {
    NSSpellChecker *checker;
    int tag;
};

// Updates the spell checker's ignored words.
static void update_ignored_words(struct SpellChecker spell,
                                 const struct Ignore *ignore) {
    [spell.checker setIgnoredWords:ignore->words
            inSpellDocumentWithTag:spell.tag];
}

// Options to the program.
struct Options {
    // Instead of spellchecking, print the result of converting Markdown to
    // plain text (the spellchecking input).
    bool print_plain;
    // Print hashes after spellchecker errors, used in spell-ignore.txt.
    bool print_hashes;
    // Prompt on each error for adding an entry to spell-ignore.txt.
    bool interactive;
};

// State for spell checking.
struct State {
    struct SpellChecker spell;
    struct Options options;
    struct Ignore *ignore;
    // True if there were any errors.
    bool failed;
    // The file being scanned.
    const char *path;
    FILE *file;
    // Current line with its length and capacity.
    int lineno;
    char *line;
    ssize_t len;
    size_t cap;
};

// Initializes spell checker state for the given file. Returns true on success.
static bool init_state(struct State *state, struct SpellChecker spell,
                       struct Options options, struct Ignore *ignore,
                       const char *path) {
    FILE *file = fopen(path, "r");
    if (!file) {
        perror(path);
        return false;
    }
    state->spell = spell;
    state->options = options;
    state->ignore = ignore;
    state->failed = false;
    state->path = path;
    state->file = file;
    state->lineno = 0;
    state->line = NULL;
    state->len = 0;
    state->cap = 0;
    return true;
}

// Closes the state's file.
static void close_state(struct State *state) {
    if (state->file) {
        fclose(state->file);
        state->file = NULL;
    }
}

// Scans a line from the file. Returns false on error or EOF.
static bool scan(struct State *state) {
    if (!state->file) {
        return false;
    }
    state->len = getline(&state->line, &state->cap, state->file);
    state->lineno++;
    return state->len != -1;
}

// An inclusive range of lines, for reporting in error messages.
struct Source {
    int first;
    int last;
};

// Prints the source location of an error.
static void print_location(const struct State *state, struct Source src) {
    fputs(state->path, stdout);
    if (src.first == src.last) {
        printf(":%d: ", src.first);
    } else {
        printf(":%d-%d: ", src.first, src.last);
    }
}

// Prints a range of str surrounded by curly quotes.
static void print_text_range(const char *str, NSRange range) {
    printf("“%.*s”", (int)range.length, str + range.location);
}

// Prints a list of words separated by commas, each enclosed in curly quotes.
static void print_comma_separated(NSArray<NSString *> *words) {
    bool comma = false;
    for (NSString *word in words) {
        if (comma) printf(", ");
        printf("“%s”", word.UTF8String);
        comma = true;
    }
}

// Prompts the user to enter a single charcter, and eats the newline.
static int get_reply() {
    int ch = getchar();
    if (ch != EOF && ch != '\n') {
        for (;;) {
            char next = getchar();
            if (next == EOF || next == '\n') break;
        }
    }
    return ch;
}

// Checks spelling and grammar in a string, printing error messages to stdout.
// Returns false to quit.
static bool check_block(struct State *state, struct Source src,
                        const char *str) {
    NSString *ns_str = @(str);
    NSRange full_range = NSMakeRange(0, ns_str.length);
    if (should_skip_block(state->ignore, str, full_range)) {
        return true;
    }
    NSArray<NSTextCheckingResult *> *results =
        [state->spell.checker checkString:ns_str
                                    range:full_range
                                    types:NSTextCheckingTypeSpelling
                                          | NSTextCheckingTypeGrammar
                                  options:NULL
                   inSpellDocumentWithTag:state->spell.tag
                              orthography:NULL
                                wordCount:NULL];
    for (NSTextCheckingResult *result in results) {
        NSRange range = result.range;
        if (should_skip_phrase(state->ignore, str, range)) {
            continue;
        }
        NSArray<NSString *> *guesses = NULL;
        NSArray<NSDictionary<NSString *, id> *> *grammarDetails = NULL;
        uint64_t grammarSkip = 0;
        switch (result.resultType) {
        case NSTextCheckingTypeSpelling:
            guesses = [state->spell.checker
                   guessesForWordRange:range
                              inString:ns_str
                              language:state->spell.checker.language
                inSpellDocumentWithTag:state->spell.tag];
            break;
        case NSTextCheckingTypeGrammar:
            grammarDetails = result.grammarDetails;
            assert(grammarDetails.count <= 64);
            int index = -1, skips = 0;
            for (NSDictionary<NSString *, id> *detail in grammarDetails) {
                index++;
                NSValue *subrange = detail[NSGrammarRange];
                NSString *description = detail[NSGrammarUserDescription];
                if (should_skip_subphrase(state->ignore, str, range, subrange,
                                          description)) {
                    skips++;
                    grammarSkip |= UINT64_C(1) << index;
                }
            }
            if (skips == (int)grammarDetails.count) {
                continue;
            }
            break;
        default:
            assert(false);
        }
        state->failed = true;
        print_location(state, src);
        print_text_range(str, range);
        if (guesses) {
            printf(" (guesses: ");
            print_comma_separated(guesses);
            printf(")");
        }
        if (state->options.print_hashes) {
            printf(" [block = %016llx]", hash_range(str, full_range));
        }
        if (grammarDetails) {
            if (state->options.print_hashes) {
                printf(" [phrase = %016llx]", hash_range(str, range));
            }
            int index = -1;
            for (NSDictionary<NSString *, id> *detail in grammarDetails) {
                index++;
                if ((grammarSkip & (UINT64_C(1) << index)) != 0) continue;
                printf("\n    ");
                NSValue *value = detail[NSGrammarRange];
                NSRange subrange;
                if (value) {
                    subrange = add_ranges(range, value.rangeValue);
                    print_text_range(str, subrange);
                }
                NSString *description = detail[NSGrammarUserDescription];
                if (value) printf(": ");
                fputs(description.UTF8String, stdout);
                if (value && state->options.print_hashes) {
                    printf(" [subphrase = %016llx]", hash_range(str, subrange));
                }
            }
        }
        putchar('\n');
        if (!state->options.interactive) {
            continue;
        }
        printf("==> ignore (b)lock, (p)hrase, ");
        switch (result.resultType) {
        case NSTextCheckingTypeSpelling:
            printf("(w)ord, ");
            break;
        case NSTextCheckingTypeGrammar:
            printf("(s)ubphrase, (e)rror, ");
            break;
        default:
            assert(false);
        }
        printf("(N)ext, or (q)uit? ");
        for (;;) {
            int reply = get_reply();
            if (reply == EOF || reply == 'q') return false;
            if (reply == 'n' || reply == '\n') break;
            if (reply == 'b') {
                add_hash(&state->ignore->blocks, hash_range(str, full_range));
                // Return early since all errors in the block are ignored.
                putchar('\n');
                return true;
            }
            if (reply == 'p') {
                add_hash(&state->ignore->phrases, hash_range(str, range));
                break;
            }
            if (result.resultType == NSTextCheckingTypeSpelling
                && reply == 'w') {
                [state->ignore->words
                    addObject:[ns_str substringWithRange:result.range]];
                update_ignored_words(state->spell, state->ignore);
                break;
            }
            if (result.resultType == NSTextCheckingTypeGrammar
                && (reply == 's' || reply == 'e')) {
                int index = -1;
                for (NSDictionary<NSString *, id> *detail in grammarDetails) {
                    index++;
                    if ((grammarSkip & (UINT64_C(1) << index)) != 0) continue;
                    NSRange subrange;
                    NSString *description;
                    if (reply == 's') {
                        NSValue *value = detail[NSGrammarRange];
                        if (!value) continue;
                        printf("... ignore ");
                        subrange = add_ranges(range, value.rangeValue);
                        print_text_range(str, subrange);
                    } else if (reply == 'e') {
                        printf("... ignore [");
                        description = detail[NSGrammarUserDescription];
                        fputs(description.UTF8String, stdout);
                        printf("]");
                    }
                    printf("? ");
                    int yes = get_reply();
                    if (yes == EOF || yes == 'q') return false;
                    if (tolower(yes) != 'y') continue;
                    if (reply == 's') {
                        add_hash(&state->ignore->subphrases,
                                 hash_range(str, subrange));
                    } else if (reply == 'e') {
                        [state->ignore->errors addObject:description];
                    }
                }
                break;
            }
            printf("==> invalid choice, try again: ");
        }
        putchar('\n');
    }
    return true;
}

// Current mode within a Markdown file.
enum Mode {
    // Normal mode.
    M_NORMAL,
    // A fenced code block, surrounded by "```".
    M_CODE_BLOCK_START,
    M_CODE_BLOCK,
    M_CODE_BLOCK_END,
    // A block of display math, surrounded by "$$".
    M_DISPLAY_MATH_START,
    M_DISPLAY_MATH,
    M_DISPLAY_MATH_END,
    // An exercise div, surrounded by "::: exercises" and ":::".
    M_EXERCISE_DIV_START,
    M_EXERCISE_DIV,
    M_EXERCISE_DIV_END,
    // An HTML <pre> block.
    M_HTML_PRE_START,
    M_HTML_PRE,
    M_HTML_PRE_END,
};

// Returns true if s starts with the given prefix.
static bool startswith(const char *s, const char *prefix) {
    return strncmp(s, prefix, strlen(prefix)) == 0;
}

// Returns the new mode for the given line of Markdown.
static enum Mode next_mode(enum Mode old, const char *line) {
    switch (old) {
    case M_NORMAL:
    case M_CODE_BLOCK_END:
    case M_DISPLAY_MATH_END:
    case M_EXERCISE_DIV_END:
    case M_HTML_PRE_END:
        if (startswith(line, "```")) {
            return M_CODE_BLOCK_START;
        };
        if (strcmp(line, "$$\n") == 0) {
            return M_DISPLAY_MATH_START;
        }
        if (strcmp(line, "::: exercises\n") == 0) {
            return M_EXERCISE_DIV_START;
        }
        if (startswith(line, "<pre>")) {
            return M_HTML_PRE_START;
        }
        return M_NORMAL;
    case M_CODE_BLOCK_START:
    case M_CODE_BLOCK:
        if (strcmp(line, "```\n") == 0) {
            return M_CODE_BLOCK_END;
        };
        return M_CODE_BLOCK;
    case M_DISPLAY_MATH_START:
    case M_DISPLAY_MATH:
        if (strcmp(line, "$$\n") == 0) {
            return M_DISPLAY_MATH_END;
        };
        return M_DISPLAY_MATH;
    case M_EXERCISE_DIV_START:
    case M_EXERCISE_DIV:
        if (strcmp(line, ":::\n") == 0) {
            return M_EXERCISE_DIV_END;
        };
        return M_EXERCISE_DIV;
    case M_HTML_PRE_START:
    case M_HTML_PRE:
        if (strcmp(line, "</code></pre>\n") == 0) {
            return M_HTML_PRE_END;
        };
        return M_HTML_PRE;
    }
}

// Converts a line of Markdown to plain text, inline. Returns a pointer into
// s indicating the beginning (e.g. would go past the hashes in headings),
// or NULL if this line has no content that should be spellchecked.
static char *strip_markdown(char *s) {
    // Skip link definitions, display math, and divs.
    if (s[0] == '[' || (s[0] == '$' && s[1] == '$') || startswith(s, ":::")) {
        return NULL;
    }
    if (*s == '#') {
        // Headings.
        while (*s == '#') s++;
        while (*s == ' ') s++;
    } else if (*s == '>') {
        // Block quotes.
        s++;
        while (*s == ' ') s++;
    } else {
        while (*s == ' ') s++;
        // Lists.
        if (*s == '-') {
            s++;
            while (*s == ' ') s++;
        } else if (*s > '1' && *s < '9') {
            char *p = s;
            while (*p > '1' && *p < '9') p++;
            if (*p == '.') {
                p++;
                if (*p == ' ') {
                    while (*p == ' ') p++;
                    s = p;
                }
            }
        }
    }
    char *const start = s;
    char *p = s;
    char delim;
    while (*p) {
        switch (*p) {
        // Escaped backticks, dollar signs, etc.
        case '\\':
            p++;
            if (!*p) goto end;
            *s++ = *p++;
            break;
        // Inline code/math.
        case '`':
        case '$':
            delim = *p;
            p++;
            while (*p && *p != delim) p++;
            if (!*p) goto end;
            p++;
            *s++ = 'C';
            *s++ = 'C';
            if (p[0] == 't' && p[1] == 'h' && p[3] == ' ') {
                s[-2] = '1';
                s[-1] = 's';
                *s++ = 't';
                p += 2;
            }
            break;
        // HTML tags and URLs.
        case '<':
            p++;
            if (startswith(p, "http")) {
                *s++ = 'U';
                *s++ = 'R';
                *s++ = 'L';
            }
            while (*p && *p != '>') p++;
            if (!*p) goto end;
            p++;
            break;
        // Links and citations.
        case '[':
            if (p[1] == '@') {
                while (*p && *p != ']') p++;
                if (!*p) goto end;
                p++;
                break;
            }
            // fallthrough
        // Emphasis.
        case '_':
        case '*':
            p++;
            break;
        // Link targets.
        case ']':
            if (p[1] == ' ') {
                *s++ = *p++;
                break;
            }
            p++;
            if (*p == '[')
                delim = ']';
            else if (*p == '(')
                delim = ')';
            else if (*p == '{')
                delim = '}';
            else
                assert(false);
            while (*p && *p != delim) p++;
            if (!*p) goto end;
            p++;
            break;
        // HTML entities.
        case '&':
            if (p > start && (p[-1] == ' ' || p[-1] == '`' || p[-1] == 'r')
                && islower(p[1])) {
                while (*p && *p != ';') p++;
                if (!*p) goto end;
                p++;
                if (startswith(p, "ed ")) {
                    p += 2;
                }
            } else {
                *s++ = *p++;
            }
            break;
        // Lambda (λ).
        case '\xce':
            if (p[1] == '\xbb') {
                *s++ = 'L';
                p += 2;
            } else {
                *s++ = *p++;
            }
            break;
        // Filenames.
        case '.':
            if (p > start && isalnum(p[-1]) && islower(p[1])) {
                while (s > start && *s != ' ') s--;
                if (*s == ' ') s++;
                *s++ = 'F';
                *s++ = 'I';
                *s++ = 'L';
                while (*p && *p != ' ' && *p != '\n') p++;
                if (!*p) goto end;
            } else {
                *s++ = *p++;
            }
            break;
        // Directories.
        case '/':
            if (p > start && isalnum(p[-1])
                && (p[1] == ' ' || p[1] == '\n' || p[1] == ']')) {
                while (s > start && *s != ' ') s--;
                if (*s == ' ') s++;
                *s++ = 'D';
                *s++ = 'I';
                *s++ = 'R';
                while (*p && *p != ' ' && *p != '\n' && *p != ']') p++;
                if (!*p) goto end;
            } else {
                *s++ = *p++;
            }
            break;
        default:
            *s++ = *p++;
            break;
        }
    }
end:
    *s = '\0';
    return start;
}

// Spellchecks a Markdown file. Returns false to quit.
static bool check_markdown(struct State *state) {
    enum Mode mode = M_NORMAL;
    while (scan(state)) {
        mode = next_mode(mode, state->line);
        if (mode != M_NORMAL) {
            continue;
        }
        char *plain = strip_markdown(state->line);
        if (!plain) continue;
        if (state->options.print_plain) {
            fputs(plain, stdout);
        } else {
            struct Source src = {.first = state->lineno, .last = state->lineno};
            if (!check_block(state, src, plain)) {
                return false;
            }
        }
    }
    return true;
}

// Spellchecks the comments in a Scheme file. Returns false to quit.
static bool check_scheme(struct State *state) {
    // TODO!
    assert(false);
}

// Supported file types.
enum FileType {
    FT_NONE,
    FT_MARKDOWN,
    FT_SCHEME,
};

// Returns the file type based on the path's extension, or FT_NONE on
// failure.
static enum FileType detect_filetype(const char *path) {
    const char *dot = strrchr(path, '.');
    if (!(dot && dot[1] && dot[2])) {
        return FT_NONE;
    }
    if (strcmp(dot, ".md") == 0) {
        return FT_MARKDOWN;
    }
    if (strcmp(dot, ".ss") == 0) {
        return FT_SCHEME;
    }
    return FT_NONE;
}

// Bitfield for the check function.
typedef int CheckResult;
#define CHECK_FAIL 0x1
#define CHECK_QUIT 0x2

// Spellchecks a single file.
static CheckResult check(struct SpellChecker spell, struct Options options,
                         struct Ignore *ignore, const char *path) {
    enum FileType ft = detect_filetype(path);
    if (ft == FT_NONE) {
        fprintf(stderr, "%s: invalid file type\n", path);
        return CHECK_FAIL;
    }
    struct State state;
    if (!init_state(&state, spell, options, ignore, path)) {
        return CHECK_FAIL;
    }
    int result = 0;
    switch (ft) {
    case FT_MARKDOWN:
        if (!check_markdown(&state)) result |= CHECK_QUIT;
        break;
    case FT_SCHEME:
        if (!check_scheme(&state)) result |= CHECK_QUIT;
        break;
    case FT_NONE:
        assert(false);
    }
    close_state(&state);
    if (state.failed) result |= CHECK_FAIL;
    return result;
}

static const char IGNORE_PATH[] = "spell-ignore.txt";

int main(int argc, char **argv) {
    if (argc == 1) {
        fprintf(stderr, "\
usage: %s [-p | -d | -x | -i] FILE ...\n\
\n\
Spellchecks Markdown (.md) or Scheme (.ss) files using NSSpellChecker.\n\
Pass the -p flag to print the file as plain text without spellchecking,\n\
or the -d flag to show a diff from the input to the plain text.\n\
Pass the -x flag to print hashes that can be used for ignoring errors.\n\
Pass the -i flag to interactively add to spell-ignore.txt.\n\
",
                argv[0]);
        return 1;
    }
    if (strcmp(argv[1], "-d") == 0) {
        if (argc != 3) {
            fprintf(stderr, "%s: -d only works with one file\n", argv[0]);
            return 1;
        }
        char cmd[256];
        // Note: git diff does not work with process substitution or
        // /dev/stdin, but it does work with "-" to mean stdin.
        snprintf(cmd, sizeof cmd, "%s -p '%s' | git diff --no-index '%s' -",
                 argv[0], argv[2], argv[2]);
        // Repeat /bin/bash for argv[0].
        if (execl("/bin/bash", "/bin/bash", "-c", cmd, NULL) == -1) {
            perror("execl");
            return 1;
        }
        assert(false);
    }
    struct Options options = {.print_plain = false, .print_hashes = false};
    int idx = 1;
    if (strcmp(argv[1], "-p") == 0) {
        options.print_plain = true;
        idx++;
    } else if (strcmp(argv[1], "-x") == 0) {
        options.print_hashes = true;
        idx++;
    } else if (strcmp(argv[1], "-i") == 0) {
        options.interactive = true;
        idx++;
    }
    struct Parser parser;
    if (!init_parser(&parser, IGNORE_PATH)) return 1;
    struct Ignore ignore;
    if (!parse_file(&parser, &ignore)) return 1;
    close_parser(&parser);
    struct SpellChecker spell = {
        .checker = [NSSpellChecker sharedSpellChecker],
        .tag = [NSSpellChecker uniqueSpellDocumentTag],
    };
    spell.checker.language = @"en_US";
    spell.checker.automaticallyIdentifiesLanguages = NO;
    update_ignored_words(spell, &ignore);
    int status = 0;
    for (; idx < argc; idx++) {
        CheckResult result = check(spell, options, &ignore, argv[idx]);
        if (result & CHECK_FAIL) status = 1;
        if (result & CHECK_QUIT) break;
    }
    if (options.interactive) {
        if (!write_ignore_file(&ignore, IGNORE_PATH)) return 1;
        // Don't return 1 for spelling errors in interactive mode, since it's
        // expected to see them and the user successfully modified the file.
        return 0;
    }
    return status;
}
