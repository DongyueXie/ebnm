ebnm_pl_workhorse <- function(x,
                              s,
                              mode,
                              scale,
                              g_init,
                              fix_g,
                              output,
                              control,
                              call) {
  if (mode != 0) {
    stop("Nonzero modes not yet implemented for 'point_laplace' priors.")
  }

  check_g_init(g_init,
               fix_g,
               mode = mode,
               scale = scale,
               pointmass = TRUE,
               call = call,
               class_name = "laplacemix",
               scale_name = "scale")

  fix_a <- !identical(scale, "estimate")

  if (!is.null(g_init) && length(g_init$pi) == 1) {
    g <- list(pi0 = 0,
              a = 1 / g_init$scale)
  } else if (!is.null(g_init) && length(g_init$pi) == 2) {
    g <- list(pi0 = g_init$pi[1],
              a = 1 / g_init$scale[2])
  } else {
    g <- list()
    if (fix_a) {
      g$a <- 1 / scale
    }
  }

  x_optset <- x
  s_optset <- s
  # Don't use observations with infinite SEs when estimating g.
  if (any(is.infinite(s))) {
    x_optset <- x[is.finite(s)]
    s_optset <- s[is.finite(s)]
  }

  # Estimate g.
  if (!fix_g) {
    if (fix_a) {
      g <- mle_point_laplace_fixa(x_optset, s_optset, g, control)
    } else {
      g <- mle_point_laplace(x_optset, s_optset, g, control)
    }
  }

  pi0 <- g$pi0
  w   <- 1 - g$pi0
  a   <- g$a

  retlist <- list()

  if (posterior_in_output(output)) {
    posterior <- summary_results_point_laplace(x, s, w, a, output)
    retlist   <- add_posterior_to_retlist(retlist, posterior, output)
  }

  if (g_in_output(output)) {
    fitted_g <- laplacemix(pi = c(pi0, w),
                           mean = rep(0, 2),
                           scale = c(0, 1 / a))
    retlist <- add_g_to_retlist(retlist, fitted_g)
  }

  if (llik_in_output(output)) {
    if (fix_g) {
      loglik <- loglik_point_laplace(x_optset, s_optset, w, a)
    } else {
      loglik <- g$val
    }
    retlist <- add_llik_to_retlist(retlist, loglik)
  }

  if (sampler_in_output(output)) {
    post_sampler <- function(nsamp) {
      post_sampler_point_laplace(x, s, w, a, nsamp)
    }
    retlist <- add_sampler_to_retlist(retlist, post_sampler)
  }

  return(retlist)
}

#' Constructor for laplacemix class
#'
#' Creates a finite mixture of Laplace distributions.
#'
#' @param pi A vector of mixture proportions.
#' @param mean A vector of means.
#' @param scale A vector of scale parameters.
#'
#' @export
#'
laplacemix <- function(pi, mean, scale) {
  structure(data.frame(pi, mean, scale), class="laplacemix")
}
