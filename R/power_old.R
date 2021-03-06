# OLD ---------------------------------------------------------------------
# not used

get_power_3lvl_old.list <- function(object, ...) {
    paras <- object
    dots <- list(...)
    n1 <- paras$n1

    if(!is.unequal_clusters(paras$n2) & !is.per_treatment(paras$n2)) {
        paras$n2 <- per_treatment(unlist(paras$n2),
                                  unlist(paras$n2))
    }
    if(!is.per_treatment(paras$n3)) {
        paras$n3 <- per_treatment(unlist(paras$n3),
                                  unlist(paras$n3))
    }
    n2 <- paras$n2
    n3 <- paras$n3
    T_end <- paras$T_end

    error <- paras$sigma_error
    u1 <- paras$sigma_subject_slope
    v1 <- paras$sigma_cluster_slope

    slope_diff <- get_slope_diff(paras)/T_end

    res <- get_power_3lvl.paras(n1 = n1,
                                n2 = n2,
                                n3 = n3,
                                T_end = T_end,
                                error = error,
                                u1 = u1,
                                v1 = v1,
                                slope_diff = slope_diff,
                                partially_nested = paras$partially_nested,
                                allocation_ratio = paras$allocation_ratio,
                                dropout = paras$dropout,
                                paras = paras,
                                ...)


    # show progress in shiny
    if (is.function(dots$updateProgress)) {
        dots$updateProgress()
    }

    res <- list(
        power = res$power,
        dropout_cc = list(as.character(res$dropout_cc)),
        se = res$se,
        df = res$df,
        dropout_tx = list(as.character(res$dropout_tx)),
        n1 = paras$n1,
        n2_cc = res$n2_cc,
        n2_tx = res$n2_tx,
        n3_cc = res$n3_cc,
        n3_tx = res$n3_tx,
        allocation_ratio = paras$allocation_ratio,
        tot_n = res$tot_n,
        var_ratio = get_var_ratio(paras),
        icc_slope = get_ICC_slope(paras),
        icc_pre_subjects = get_ICC_pre_subjects(paras),
        icc_pre_clusters = get_ICC_pre_clusters(paras),
        cohend = paras$cohend,
        T_end = paras$T_end,
        partially_nested = res$partially_nested,
        paras = paras)

    class(res) <- append("plcp_power_3lvl", class(res))

    res

}
get_power_2lvl.list <- function(object, ...) {
    paras <- object
    dots <- list(...)
    n1 <- paras$n1

    tmp <- get_tot_n(paras)
    paras$n2 <- per_treatment(tmp$control, tmp$treatment)
    paras$n3 <- per_treatment(1, 1)
    n2 <- paras$n2

    n3 <- paras$n3
    T_end <- paras$T_end

    error <- paras$sigma_error
    u1 <- paras$sigma_subject_slope
    v1 <- 0

    slope_diff <- get_slope_diff(paras)/T_end

    res <- get_power_3lvl.paras(n1 = n1,
                                n2 = n2,
                                n3 = n3,
                                T_end = T_end,
                                error = error,
                                u1 = u1,
                                v1 = v1,
                                slope_diff = slope_diff,
                                partially_nested = paras$partially_nested,
                                allocation_ratio = paras$allocation_ratio,
                                dropout = paras$dropout,
                                paras = paras,
                                ...)


    # show progress in shiny
    if (is.function(dots$updateProgress)) {
        dots$updateProgress()
    }

    res <- list(power = res$power,
                dropout_cc = list(as.character(res$dropout_cc)),
                se = res$se,
                df = res$df,
                dropout_tx = list(as.character(res$dropout_tx)),
                n1 = paras$n1,
                n2_cc = sum(unlist(res$n2_cc)),
                n2_tx = sum(unlist(res$n2_tx)),
                tot_n = res$tot_n,
                allocation_ratio = paras$allocation_ratio,
                var_ratio = get_var_ratio(paras),
                icc_slope = get_ICC_slope(paras),
                icc_pre_subjects = get_ICC_pre_subjects(paras),
                cohend = paras$cohend,
                T_end = paras$T_end,
                paras = paras)

    class(res) <- append("plcp_power_2lvl", class(res))

    res

}

get_power_3lvl.paras <- function(n1,
                                 n2,
                                 n3,
                                 T_end,
                                 error,
                                 u1,
                                 v1,
                                 slope_diff,
                                 partially_nested,
                                 allocation_ratio = 1,
                                 dropout = NULL,
                                 ...) {
    dots <- list(...)

    sx <- Vectorize(var_T)(n1, T_end)


    if(is.unequal_clusters(n2) | is.list(dropout)) {

        res <- get_se_3lvl_matrix(dots$paras)
        se <- res$se
        var_cc <- res$var_cc
        var_tx <- res$var_tx

        dropout_cc <- format_dropout(get_dropout(dots$paras)$control)
        dropout_tx <- format_dropout(get_dropout(dots$paras)$treatment)
    } else {
        n2_tx <- n2[[1]]$treatment
        n2_cc <- get_n2(dots$paras)$control

        n3_tx <- n3[[1]]$treatment
        n3_cc <- n3[[1]]$control
        if(partially_nested) {
            se <- sqrt( (error^2 + n1*u1^2*sx)/(n1*n2_cc*sx) + (error^2 + n1*u1^2*sx + n1*n2_tx*v1^2*sx) / (n1*n2_tx*n3_tx*sx) )
        } else {
            var_cc <- (error^2 + n1*u1^2*sx + n1*n2_cc*v1^2*sx) / (n1*n2_cc*n3_cc*sx)
            var_tx <- (error^2 + n1*u1^2*sx + n1*n2_tx*v1^2*sx) / (n1*n2_tx*n3_tx*sx)
            se <- sqrt(var_cc + var_tx)
        }
        dropout_cc <- 0
        dropout_tx <- 0

    }
    n2_tx <- get_tot_n(dots$paras)$treatment
    n2_cc <- get_tot_n(dots$paras)$control

    n3_cc <- get_n3(dots$paras)$control
    n3_tx <- get_n3(dots$paras)$treatment


    lambda <- slope_diff / se
    if(v1 == 0) {
        df <-  (n2_tx + n2_cc) - 2
    } else if(!partially_nested) {
        df <- (n3_cc + n3_tx) - 2
    } else {
        df <-(2*n3_tx) - 2

    }
    power <- pt(qt(1-0.05/2, df = df), df = df, ncp = lambda, lower.tail = FALSE) +
        pt(qt(0.05/2, df = df), df = df, ncp = lambda)

    # show progress in shiny
    if (is.function(dots$updateProgress)) {
        dots$updateProgress()
    }

    res <- data.frame(n1 = n1,
                      n3_cc = n3_cc,
                      n3_tx = n3_tx,
                      ratio = get_var_ratio(u1=u1, v1=v1, error=error),
                      icc_slope = get_ICC_slope(u1=u1, v1=v1),
                      tot_n = get_tot_n(dots$paras)$total,
                      se = se,
                      df = df,
                      power = power,
                      dropout_tx = dropout_tx,
                      dropout_cc = dropout_cc,
                      partially_nested = partially_nested)

    res$n2_tx <- list(n2_tx)
    res$n2_cc <- list(n2_cc)



    res
}

get_se_classic <- function(object) {
    UseMethod("get_se_classic")
}

get_se_classic.plcp_nested <- function(object) {

    if(is.null(object$prepared)) {
        p_tx <- prepare_paras(object)
    } else {
        p_tx <- object
        object <- p_tx$treatment
    }

    p_cc <- p_tx$control
    p_tx <- p_tx$treatment

    n1 <- object$n1
    T_end <- object$T_end
    sx <- Vectorize(var_T)(n1, T_end)



    n2_tx <- unique(unlist(p_tx$n2))
    n3_tx <- unlist(p_tx$n3)
    n2_cc <- unique(unlist(p_cc$n2))
    n3_cc <- unlist(p_cc$n3)


    error <- object$sigma_error
    u1 <- object$sigma_subject_slope
    u1[is.na(u1)] <- 0
    v1 <- object$sigma_cluster_slope
    v1[is.na(v1)] <- 0

    if(object$partially_nested) {
        se <- sqrt( (error^2 + n1*u1^2*sx)/(n1*n2_cc*n3_cc*sx) + (error^2 + n1*u1^2*sx + n1*n2_tx*v1^2*sx) / (n1*n2_tx*n3_tx*sx) )
    } else {
        var_cc <- (error^2 + n1*u1^2*sx + n1*n2_cc*v1^2*sx) / (n1*n2_cc*n3_cc*sx)
        var_tx <- (error^2 + n1*u1^2*sx + n1*n2_tx*v1^2*sx) / (n1*n2_tx*n3_tx*sx)
        se <- sqrt(var_cc + var_tx)
    }


    se

}


# Matrix power ------------------------------------------------------------

## Unbalanced
create_Z_block <- function(n2) {
    B <- matrix(c(1, 0, 0, 1), nrow=2, ncol=2)
    A <- array(1, dim = c(n2, 1))
    kronecker(A, B)
}


#' @import Matrix
get_vcov <- function(paras) {
    n1 <- paras$n1
    n2 <- unlist(paras$n2)
    n3 <- paras$n3
    if(length(n2) == 1) {
        n2 <- rep(n2, n3)
    }

    # paras
    u0 <- paras$sigma_subject_intercept
    u1 <- paras$sigma_subject_slope
    u01 <- u0 * u1 * paras$cor_subject
    v0 <- paras$sigma_cluster_intercept
    v1 <- paras$sigma_cluster_slope
    v01 <- v0 * v1 * paras$cor_cluster
    sigma <- paras$sigma_error
    lvl2_re <- matrix(c(u0^2, u01,
                        u01, u1^2), nrow = 2, ncol = 2)
    lvl3_re <- matrix(c(v0^2, v01,
                        v01, v1^2), nrow = 2, ncol = 2)


    ##
    tot_n <- get_tot_n(paras)$control # tx == cc
    A <- Diagonal(tot_n)
    B <- Matrix(c(rep(1, n1), get_time_vector(paras)), ncol = 2, nrow = n1)
    X <- kronecker(A, B)

    # missing
    if(is.list(paras$dropout) | is.function(paras$dropout[[1]])) {
        miss <- dropout_process(unlist(paras$dropout), paras)
        cluster <- create_cluster_index(n2, n3)
        cluster <- rep(cluster, each = n1)
        miss$cluster <- cluster
        miss <- miss[order(miss$id), ]
        X <- X[miss$missing == 0, ]
    }
    Xt <- Matrix::t(X)
    ## random
    I1 <- Diagonal(tot_n)
    lvl2 <- kronecker(I1, lvl2_re)

    I3 <- Diagonal(n3)
    Z <- bdiag(lapply(n2, create_Z_block))

    lvl3 <- Z %*% kronecker(I3, lvl3_re)
    lvl3 <- Matrix::tcrossprod(lvl3, Z)


    # missing data
    if(is.list(paras$dropout) | is.function(paras$dropout[[1]])) {
        ids <- miss[miss$missing == 0, ]

        ids <- lapply(unique(ids$id), function(id) {
            n <- length(ids[ids$id == id, 1])
            data.frame(id = id,
                       n = n)
        })
        ids <- do.call(rbind, ids)
        ids <- ids[ids$n == 1, "id"]

        s_id <- c(2*ids - 1, 2*ids)
        tmp <- Xt %*% X
        if(length(s_id) == 0) {
            tmp <- solve(tmp)
        } else {
            tmp[-s_id, -s_id] <- solve(tmp[-s_id, -s_id])
        }
    } else {
        ids <- NULL
        s_id <- NULL
        tmp <- solve(Xt %*% X)
    }
    XtX_inv <- tmp
    if(length(ids) > 0) {
        lvl2[ids*2, ] <- 0
        lvl2[, ids*2] <- 0

        lvl3[ids*2, ] <- 0
        lvl3[, ids*2] <- 0
    }
    I <- Diagonal(nrow(X))
    A <- sigma^-2 * (I - X %*% XtX_inv %*% Xt)
    B <- sigma^2 * XtX_inv + (lvl2 + lvl3)

    B_inv <- B
    rm(B)

    # deal with subjects with only 1 observations
    if(length(s_id) == 0) {
        B_inv <- solve(B_inv)
    } else {
        tmp <- Matrix::solve(B_inv[-s_id, -s_id])
        tmp <- as.matrix(tmp)
        B_inv <- as.matrix(B_inv)
        B_inv[-s_id, -s_id] <- tmp
        B_inv <- Matrix(B_inv)
        rm(tmp)
        if(length(ids) == 1) {
            B_inv[2*ids-1, 2*ids-1] <-  1/B_inv[2*ids-1, 2*ids-1]
        } else {
            Matrix::diag(B_inv[2*ids-1, 2*ids-1]) <-
                1/Matrix::diag(B_inv[2*ids-1, 2*ids-1])
        }
    }

    C <- X %*% XtX_inv %*% B_inv %*% XtX_inv %*% Xt
    V_inv <- A+C

    W <- create_Z_block(n3)
    var_betas <- solve(Matrix::t(W) %*% Matrix::t(Z) %*% Xt %*%
                           V_inv %*% X %*% Z %*% W)

    var_betas
}


get_se_3lvl_matrix <- function(paras, ...) {
    dots <- list(...)

    unequal_allocation <- is.per_treatment(paras$n2) | is.per_treatment(paras$n3)
    dropout_per_treatment <- is.per_treatment(paras$dropout)

    tmp <- prepare_paras(paras)
    paras <- tmp$control
    paras_tx <- tmp$treatment

    var_grp1 <- get_vcov(paras)

    if(unequal_allocation | dropout_per_treatment | paras$partially_nested) {
        var_grp2 <- get_vcov(paras_tx)
    } else {
        var_grp2 <- var_grp1
    }

    se <- sqrt(var_grp1[2,2] + var_grp2[2,2])

    list(se = se,
         var_cc = var_grp1[2,2],
         var_tx = var_grp2[2,2])
}
