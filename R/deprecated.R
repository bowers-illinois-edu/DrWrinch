# Deprecation notices for the hypergeometric urn model.
#
# The paper began with two probability models and now has one, so
# bf_urn() and sens_urn() describe something no version of the paper
# still claims. They are not removed: the first arXiv version cites them
# and its replication code calls them, and a deprecation that broke that
# code would defeat its own purpose.
#
# The notice fires once per session per function rather than on every
# call. sens_coding(model = "urn") recomputes the urn Bayes factor at
# every re-coding, so warning on each call would emit a handful of
# notices from one call the researcher made, and a notice that arrives
# in bulk teaches readers to ignore notices.

.drwrinch_deprecated <- new.env(parent = emptyenv())

.deprecate_once <- function(what, msg) {
  if (isTRUE(.drwrinch_deprecated[[what]])) {
    return(invisible(FALSE))
  }
  # Record before warning, so that a caller who converts warnings to
  # errors still leaves the flag set and does not see it again.
  assign(what, TRUE, envir = .drwrinch_deprecated)
  # Report against the call the user actually made. .Deprecated() would
  # blame this helper, which is an implementation detail they never
  # named, so build the condition here and take the caller's call. The
  # class is the one .Deprecated() uses, so handlers written for base R
  # deprecations still catch it.
  warning(warningCondition(msg, class = "deprecatedWarning",
                           call = sys.call(-1L)))
  invisible(TRUE)
}

# Used by tests, which reset the flags and then check that the notice
# fires. Not exported: a session that has seen the notice has seen it.
.reset_deprecation_warnings <- function() {
  rm(list = ls(.drwrinch_deprecated, all.names = TRUE),
     envir = .drwrinch_deprecated)
  invisible(NULL)
}
