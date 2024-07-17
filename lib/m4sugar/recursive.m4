#                                                  -*- Autoconf -*-
# Recursive implementations of M4sugar functions that iterate over $@.
# Copyright (C) 2008-2017, 2020-2026 Free Software Foundation, Inc.
#
# This file is part of Autoconf.  This program is free
# software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Under Section 7 of GPL version 3, you are granted additional
# permissions described in the Autoconf Configure Script Exception,
# version 3.0, as published by the Free Software Foundation.
#
# You should have received a copy of the GNU General Public License
# and a copy of the Autoconf Configure Script Exception along with
# this program; see the files COPYINGv3 and COPYING.EXCEPTION
# respectively.  If not, see <https://www.gnu.org/licenses/>.

# The macros in this file are efficient in GNU M4 1.6 but quadratically
# expensive in GNU M4 1.4.  See foreach.m4 for a detailed explanation.
#
# Every macro in this file is also defined in foreach.m4.
# Please take care to keep the implementations in sync.
#
# m4sugar.m4 selects which implementation to use based on the presence
# or absence of the macro __m4_version__, which was introduced in M4 1.6.x.


# _m4_foreach(PRE, POST, IGNORED, ARG...)
# ---------------------------------------
# Form the common basis of the m4_foreach and m4_map macros.  For each
# ARG, expand PRE[ARG]POST[].  The IGNORED argument makes recursion
# easier, and must be supplied rather than implicit.
m4_define([_m4_foreach],
[m4_if([$#], [3], [],
       [$1[$4]$2[]$0([$1], [$2], m4_shift3($@))])])


# m4_case(SWITCH, VAL1, IF-VAL1, VAL2, IF-VAL2, ..., DEFAULT)
# -----------------------------------------------------------
# Shorthand for m4_if(SWITCH, VAL1, IF-VAL1,
#                     SWITCH, VAL2, IF-VAL2, ..., DEFAULT).
m4_define([m4_case],
[m4_if([$#], 0, [],
       [$#], 1, [],
       [$#], 2, [$2],
       [$1], [$2], [$3],
       [$0([$1], m4_shift3($@))])])


# m4_bmatch(SWITCH, RE1, VAL1, RE2, VAL2, ..., DEFAULT)
# -----------------------------------------------------
# Match SWITCH against each of the REs.  Expand to the VAL
# corresponding to the first RE that matched.  (Stops evaluating
# when a match is found.)
m4_define([m4_bmatch],
[m4_if([$#], 0, [m4_fatal([$0: too few arguments: $#])],
       [$#], 1, [m4_fatal([$0: too few arguments: $#: $1])],
       [$#], 2, [$2],
       [m4_if(m4_bregexp([$1], [$2]), -1, [$0([$1], m4_shift3($@))],
       [$3])])])

# _m4_cond(TEST1, VAL1, IF-VAL1, TEST2, VAL2, IF-VAL2, ..., [DEFAULT])
# -------------------------------------------------------------------
# Similar to m4_if, except that each TEST is expanded only if no previous
# TESTs matched.  This is more efficient when the TESTs are expensive.
#
# Caller guarantees 3*n or 3*n + 1 arguments, 1 <= n.
m4_define([_m4_cond],
[m4_if(($1), [($2)], [$3],
       [$#], [3], [],
       [$#], [4], [$4],
       [$0(m4_shift3($@))])])

# _m4_bpatsubsts(STRING, RE1, SUBST1, RE2, SUBST2, ...)
# ----------------------------------------------------
# m4 equivalent of
#
#   $_ = "[$STRING]";
#   s/RE1/SUBST1/g;
#   s/RE2/SUBST2/g;
#   ...
#   $_ = substr $_, 1, -1;
#
# m4_bpatsubsts already validated an odd number of arguments.
m4_define([_m4_bpatsubsts],
[m4_if([$#], 2, [$1],
       [$0(m4_builtin([patsubst], [[$1]], [$2], [$3]),
           m4_shift3($@))])])


# _m4_shiftn(N, ...)
# ------------------
# Returns ... shifted N times.  Does not do any validation of N.
#
# Autoconf does not use this macro, because it is inherently slower than
# calling the common cases of m4_shift2 or m4_shift3 directly.  But it
# might as well be fast for other clients, such as Libtool.  One way to
# do this is to expand $@ only once in _m4_shiftn (otherwise, for long
# lists, the expansion of m4_if takes twice as much memory as what the
# list itself occupies, only to throw away the unused branch).  The end
# result is strictly equivalent to
#   m4_if([$1], 1, [m4_shift(,m4_shift(m4_shift($@)))],
#         [_m4_shiftn(m4_decr([$1]), m4_shift(m4_shift($@)))])
# but with the final 'm4_shift(m4_shift($@)))' shared between the two
# paths.  The first leg uses a no-op m4_shift(,$@) to balance out the ().
m4_define([_m4_shiftn],
[m4_if([$1], 1, [m4_shift(],
       [$0(m4_decr([$1])]), m4_shift(m4_shift($@)))])


# m4_do(...)
# ----------
# Expands to the expansion of each argument, in sequence, expanding an
# empty quoted string after each one (thus, m4_do([m4_], [fatal([oops])])
# will *not* invoke m4_fatal).  Useful for splitting macro definitions
# across many lines for readability.
m4_define([m4_do],
[m4_if([$#], 0, [],
       [$#], 1, [$1[]],
       [$1[]$0(m4_shift($@))])])


# m4_dquote_elt(ARGS)
# ------------------
# Return ARGS as an unquoted list of double-quoted arguments.
m4_define([m4_dquote_elt],
[m4_if([$#], [0], [],
       [$#], [1], [[[$1]]],
       [[[$1]],$0(m4_shift($@))])])


# m4_reverse(ARGS)
# ----------------
# Output ARGS in reverse order.
m4_define([m4_reverse],
[m4_if([$#], [0], [], [$#], [1], [[$1]],
       [$0(m4_shift($@)), [$1]])])


# m4_map_args_pair(EXPRESSION, [END-EXPR = EXPRESSION], ARG...)
# -------------------------------------------------------------
# Perform a pairwise grouping of consecutive ARGs, by expanding
# EXPRESSION([ARG1], [ARG2]).  If there are an odd number of ARGs, the
# final argument is expanded with END-EXPR([ARGn]).
m4_define([m4_map_args_pair],
[m4_if([$#], [0], [m4_fatal([$0: too few arguments: $#])],
       [$#], [1], [m4_fatal([$0: too few arguments: $#: $1])],
       [$#], [2], [],
       [$#], [3], [m4_default([$2], [$1])([$3])[]],
       [$#], [4], [$1([$3], [$4])[]],
       [$1([$3], [$4])[]$0([$1], [$2], m4_shift(m4_shift3($@)))])])


# m4_join(SEP, ARG1, ARG2...)
# ---------------------------
# Produce ARG1SEPARG2...SEPARGn.  Avoid back-to-back SEP when a given ARG
# is the empty string.  No expansion is performed on SEP or ARGs.
#
#
# Since the number of arguments to join can be arbitrarily long, we
# want to avoid having more than one $@ in the macro definition;
# otherwise, the expansion would require twice the memory of the already
# long list.  Hence, m4_join merely looks for the first non-empty element,
# and outputs just that element; while _m4_join looks for all non-empty
# elements, and outputs them following a separator.  The final trick to
# note is that we decide between recursing with $0 or _$0 based on the
# nested m4_if ending with '_'.
m4_define([m4_join],
[m4_if([$#], [1], [],
       [$#], [2], [[$2]],
       [m4_if([$2], [], [], [[$2]_])$0([$1], m4_shift2($@))])])

m4_define([_m4_join],
[m4_if([$#$2], [2], [],
       [m4_if([$2], [], [], [[$1$2]])$0([$1], m4_shift2($@))])])


# m4_joinall(SEP, ARG1, ARG2...)
# ------------------------------
# Produce ARG1SEPARG2...SEPARGn.  An empty ARG results in back-to-back SEP.
# No expansion is performed on SEP or ARGs.
m4_define([m4_joinall],
[[$2]_$0([$1], m4_shift($@))])

m4_define([_m4_joinall],
[m4_if([$#], [2], [], [[$1$3]$0([$1], m4_shift2($@))])])


# _m4_list_cmp_raw(A, B)
# ----------------------
# Compare the two lists of integer expressions A and B, which are
# safe to expand multiple times.
#
# Rather than face the overhead of m4_case, we use a helper function whose
# expansion includes the name of the macro to invoke on the tail, either
# m4_ignore or m4_unquote.  This is particularly useful when comparing
# long lists, since less text is being expanded for deciding when to end
# recursion.  The recursion is between a pair of macros that alternate
# which list is trimmed by one element; this is more efficient than
# calling m4_cdr on both lists from a single macro.
m4_define([_m4_list_cmp_raw],
[m4_if([$1], [$2], [0], [_m4_list_cmp_1([$1], $2)])])

m4_define([_m4_list_cmp],
[m4_if([$1], [], [0m4_ignore], [$2], [0], [m4_unquote], [$2m4_ignore])])

m4_define([_m4_list_cmp_1],
[_m4_list_cmp_2([$2], [m4_shift2($@)], $1)])

m4_define([_m4_list_cmp_2],
[_m4_list_cmp([$1$3], m4_cmp([$3+0], [$1+0]))(
  [_m4_list_cmp_1(m4_dquote(m4_shift3($@)), $2)])])


# _m4_minmax(METHOD, ARG1, ARG2...)
# ---------------------------------
# Common recursion code for m4_max and m4_min.  METHOD must be _m4_max
# or _m4_min, and there must be at least two arguments to combine.
#
# Please keep foreach.m4 in sync with any adjustments made here.
m4_define([_m4_minmax],
[m4_if([$#], [3], [$1([$2], [$3])],
       [$0([$1], $1([$2], [$3]), m4_shift3($@))])])


# _m4_set_add_all_clean(SET, VALUE...)
# _m4_set_add_all_check(SET, VALUE...)
# -----------------------------
# Recursion helpers for m4_set_add_all; the check variant is slower
# but handles the case where an element has previously been removed
# but not pruned.
m4_define([_m4_set_add_all_clean],
[m4_if([$#], [2], [],
  [_m4_set_add_clean([$1], [$3], [-], [])$0([$1], m4_shift2($@))])])

m4_define([_m4_set_add_all_check],
[m4_if([$#], [2], [],
  [_m4_set_add([$1], [$3], [-], [])$0([$1], m4_shift2($@))])])
